import 'dart:async';

import 'package:jp_auction_arena/features/team/domain/errors/team_exceptions.dart';
import 'package:jp_auction_arena/features/team/domain/models/team.dart';
import 'package:jp_auction_arena/features/team/domain/models/team_status.dart';
import 'package:jp_auction_arena/features/team/domain/repositories/team_repository.dart';
import 'package:jp_auction_arena/features/auction/domain/repositories/auction_repository.dart';
import 'package:jp_auction_arena/features/tournament/domain/repositories/tournament_repository.dart';

class InMemoryTeamRepository implements TeamRepository {
  InMemoryTeamRepository({
    this.auctionRepository,
    this.tournamentRepository,
    this.simulatedDelay = const Duration(milliseconds: 100),
    List<Team>? initialTeams,
  }) : _teams = List.of(initialTeams ?? const []);

  final AuctionRepository? auctionRepository;
  final TournamentRepository? tournamentRepository;
  final Duration simulatedDelay;
  final List<Team> _teams;
  Future<void> _writeTail = Future<void>.value();
  int _nextId = 1;

  @override
  Future<List<Team>> getTeams({
    String? auctionId,
    String? tournamentId,
    TeamStatus? status,
    String? query,
  }) async {
    await _wait();
    final normalizedQuery = query?.trim().toLowerCase() ?? '';
    return List.unmodifiable(
      _teams.where((team) {
        final matchesAuction = auctionId == null || team.auctionId == auctionId;
        final matchesTournament =
            tournamentId == null || team.tournamentId == tournamentId;
        final matchesStatus = status == null || team.status == status;
        final searchable =
            '${team.name} ${team.shortName} ${team.ownerName} '
                    '${team.managerName} ${team.contactEmail} ${team.contactPhone}'
                .toLowerCase();
        return matchesAuction &&
            matchesTournament &&
            matchesStatus &&
            (normalizedQuery.isEmpty || searchable.contains(normalizedQuery));
      }),
    );
  }

  @override
  Future<Team?> getTeamById(String id) async {
    await _wait();
    for (final team in _teams) {
      if (team.id == id) return team;
    }
    return null;
  }

  @override
  Future<Team> createTeam(Team team) => _exclusive(() async {
    await _wait();
    _validate(team);
    await _validateCapacity(team, 1);
    final created = team.copyWith(
      id: team.id.isEmpty ? 'team_${_nextId++}' : team.id,
    );
    _teams.add(created);
    return created;
  });

  @override
  Future<Team> updateTeam(Team team) => _exclusive(() async {
    await _wait();
    final index = _teams.indexWhere((item) => item.id == team.id);
    if (index < 0) throw TeamValidationException('Team ${team.id} not found.');
    final existing = _teams[index];
    if (existing.auctionId != team.auctionId) {
      throw const TeamValidationException(
        'A team cannot be moved to a different auction.',
      );
    }
    _validate(team, excludingId: team.id);
    if (existing.status == TeamStatus.archived &&
        team.status != TeamStatus.archived) {
      await _validateCapacity(team, 1);
    }
    _teams[index] = team;
    return team;
  });

  @override
  Future<Team> updateTeamStatus(String id, TeamStatus status) =>
      _exclusive(() async {
        await _wait();
        final index = _teams.indexWhere((item) => item.id == id);
        if (index < 0) throw TeamValidationException('Team $id not found.');
        final current = _teams[index];
        final updated = current.copyWith(
          status: status,
          updatedAt: DateTime.now(),
        );
        if (current.status == TeamStatus.archived &&
            status != TeamStatus.archived) {
          await _validateCapacity(updated, 1);
        }
        _teams[index] = updated;
        return updated;
      });

  @override
  Future<bool> deleteTeam(String id) => _exclusive(() async {
    await _wait();
    final index = _teams.indexWhere((team) => team.id == id);
    if (index < 0) return false;
    final team = _teams[index];
    if (team.hasAuctionActivity || team.hasPlayerAssignments) {
      throw TeamDeletionBlockedException(
        'Teams with auction or player history cannot be deleted.',
      );
    }
    _teams.removeAt(index);
    return true;
  });

  @override
  Future<List<Team>> importTeams(List<Team> teams) => _exclusive(() async {
    await _wait();
    final pending = <Team>[];
    for (final team in teams) {
      _validate(team, candidates: [..._teams, ...pending]);
      pending.add(team);
    }
    final grouped = <String, List<Team>>{};
    for (final team in pending) {
      final scope = team.auctionId.isNotEmpty
          ? team.auctionId
          : 'legacy:${team.tournamentId}';
      grouped.putIfAbsent(scope, () => <Team>[]).add(team);
    }
    for (final group in grouped.values) {
      if (group.isNotEmpty) {
        await _validateCapacity(group.first, group.length);
      }
    }
    final created = [
      for (final team in pending)
        team.copyWith(id: team.id.isEmpty ? 'team_${_nextId++}' : team.id),
    ];
    _teams.addAll(created);
    return List.unmodifiable(created);
  });

  void _validate(Team team, {String? excludingId, List<Team>? candidates}) {
    if (team.auctionId.trim().isEmpty && team.tournamentId.trim().isEmpty) {
      throw const TeamValidationException('An auction is required.');
    }
    if (team.name.trim().isEmpty || team.shortName.trim().isEmpty) {
      throw const TeamValidationException(
        'Team name and short name are required.',
      );
    }
    if (team.ownerName.trim().isEmpty || team.managerName.trim().isEmpty) {
      throw const TeamValidationException(
        'Team owner and manager names are required.',
      );
    }
    if (team.contactEmail.trim().isNotEmpty &&
        !RegExp(
          r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
        ).hasMatch(team.contactEmail.trim())) {
      throw const TeamValidationException('Enter a valid team email address.');
    }
    for (final other in candidates ?? _teams) {
      if (other.id == excludingId || !_sameScope(other, team)) {
        continue;
      }
      if (other.name.trim().toLowerCase() == team.name.trim().toLowerCase()) {
        throw const TeamValidationException(
          'Team name must be unique within the auction.',
        );
      }
      if (other.shortName.trim().toLowerCase() ==
          team.shortName.trim().toLowerCase()) {
        throw const TeamValidationException(
          'Team short name must be unique within the auction.',
        );
      }
    }
  }

  bool _sameScope(Team first, Team second) => first.auctionId.isNotEmpty
      ? first.auctionId == second.auctionId
      : first.auctionId.isEmpty &&
            second.auctionId.isEmpty &&
            first.tournamentId == second.tournamentId;

  Future<void> _validateCapacity(Team team, int count) async {
    if (team.auctionId.isNotEmpty) {
      final auction = await auctionRepository?.getAuctionById(team.auctionId);
      if (auction == null) {
        throw TeamValidationException(
          'Auction ${team.auctionId} was not found.',
        );
      }
      final registered = _teams
          .where(
            (item) =>
                item.auctionId == team.auctionId &&
                item.status != TeamStatus.archived,
          )
          .length;
      if (registered + count > auction.maxTeams) {
        throw TeamCapacityExceededException(
          'Auction team limit of ${auction.maxTeams} would be exceeded.',
        );
      }
      return;
    }

    final tournament = await tournamentRepository?.getTournamentById(
      team.tournamentId,
    );
    if (tournament != null &&
        _teams
                    .where(
                      (item) =>
                          item.tournamentId == team.tournamentId &&
                          item.status != TeamStatus.archived,
                    )
                    .length +
                count >
            tournament.maxTeams) {
      throw TeamCapacityExceededException(
        'Tournament team limit of ${tournament.maxTeams} would be exceeded.',
      );
    }
  }

  Future<void> _wait() async {
    if (simulatedDelay > Duration.zero) {
      await Future<void>.delayed(simulatedDelay);
    }
  }

  Future<T> _exclusive<T>(Future<T> Function() action) async {
    final previous = _writeTail;
    final finished = Completer<void>();
    _writeTail = finished.future;
    await previous;
    try {
      return await action();
    } finally {
      finished.complete();
    }
  }
}

final demoTeams = <Team>[
  Team(
    id: 'team_001',
    tournamentId: 'tourn_001',
    name: 'Ahmedabad Strikers',
    shortName: 'AST',
    primaryColorValue: 0xFF418BFF,
    secondaryColorValue: 0xFFAA8BFF,
    ownerName: 'Aarav Shah',
    managerName: 'Kiran Mehta',
    contactEmail: 'strikers@example.com',
    contactPhone: '+91 98765 43210',
    status: TeamStatus.active,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  ),
  Team(
    id: 'team_002',
    tournamentId: 'tourn_001',
    name: 'Vadodara Warriors',
    shortName: 'VWR',
    primaryColorValue: 0xFFF13BBF,
    secondaryColorValue: 0xFFFFC45C,
    ownerName: 'Rohan Desai',
    managerName: 'Mihir Patel',
    contactEmail: 'warriors@example.com',
    contactPhone: '+91 98765 12345',
    status: TeamStatus.active,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  ),
];

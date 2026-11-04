import 'package:jp_auction_arena/features/tournament/domain/models/tournament.dart';
import 'package:jp_auction_arena/features/tournament/domain/models/tournament_status.dart';
import 'package:jp_auction_arena/features/tournament/domain/errors/tournament_exceptions.dart';
import 'package:jp_auction_arena/features/tournament/domain/repositories/tournament_repository.dart';
import 'package:jp_auction_arena/features/tournament/domain/services/tournament_management_service.dart';

class InMemoryTournamentRepository implements TournamentRepository {
  InMemoryTournamentRepository({
    this.simulatedDelay = const Duration(milliseconds: 100),
    List<Tournament>? initialTournaments,
  }) : _tournaments = List.of(initialTournaments ?? demoTournaments);

  final Duration simulatedDelay;
  final List<Tournament> _tournaments;
  int _nextId = 1;

  @override
  Future<List<Tournament>> getTournaments({
    TournamentStatus? status,
    String? query,
  }) async {
    await _wait();
    final normalizedQuery = query?.trim().toLowerCase() ?? '';
    return List.unmodifiable(
      _tournaments.where((tournament) {
        final matchesStatus = status == null || tournament.status == status;
        final searchable =
            '${tournament.name} ${tournament.shortName} ${tournament.city} '
                    '${tournament.venue} ${tournament.seasonYear}'
                .toLowerCase();
        return matchesStatus &&
            (normalizedQuery.isEmpty || searchable.contains(normalizedQuery));
      }),
    );
  }

  @override
  Future<Tournament?> getTournamentById(String id) async {
    await _wait();
    for (final tournament in _tournaments) {
      if (tournament.id == id) return tournament;
    }
    return null;
  }

  @override
  Future<Tournament> createTournament(Tournament tournament) async {
    await _wait();
    if (tournament.status != TournamentStatus.draft &&
        tournament.status != TournamentStatus.upcoming) {
      throw const TournamentTransitionException(
        'New tournaments must start as Draft or Upcoming.',
      );
    }
    if (tournament.name.trim().isEmpty) {
      throw const TournamentValidationException('Tournament name is required.');
    }
    if (tournament.status == TournamentStatus.active &&
        _tournaments.any((item) => item.status == TournamentStatus.active)) {
      throw StateError('Only one tournament can be active at a time.');
    }
    final created = tournament.copyWith(
      id: tournament.id.isEmpty ? 'tourn_${_nextId++}' : tournament.id,
    );
    _tournaments.add(created);
    return created;
  }

  @override
  Future<Tournament> updateTournament(Tournament tournament) async {
    await _wait();
    final index = _tournaments.indexWhere((item) => item.id == tournament.id);
    if (index < 0) throw StateError('Tournament ${tournament.id} not found.');
    final existing = _tournaments[index];
    if (existing.status == TournamentStatus.archived) {
      throw const TournamentTransitionException(
        'Archived tournaments are read-only. Restore before editing.',
      );
    }
    if (existing.status != tournament.status &&
        !TournamentManagementService.canTransition(
          existing.status,
          tournament.status,
        )) {
      throw TournamentTransitionException(
        'Cannot change status from ${existing.status.label} to '
        '${tournament.status.label}.',
      );
    }
    if (tournament.status == TournamentStatus.active &&
        _tournaments.any(
          (item) =>
              item.id != tournament.id &&
              item.status == TournamentStatus.active,
        )) {
      throw StateError('Only one tournament can be active at a time.');
    }
    _tournaments[index] = tournament;
    return tournament;
  }

  @override
  Future<Tournament> updateTournamentStatus(
    String id,
    TournamentStatus status,
  ) async {
    await _wait();
    final index = _tournaments.indexWhere((item) => item.id == id);
    if (index < 0) throw StateError('Tournament $id not found.');
    final current = _tournaments[index];
    if (!TournamentManagementService.canTransition(current.status, status)) {
      throw TournamentTransitionException(
        'Cannot change status from ${current.status.label} to ${status.label}.',
      );
    }
    if (status == TournamentStatus.active &&
        _tournaments.any(
          (item) => item.id != id && item.status == TournamentStatus.active,
        )) {
      throw StateError('Only one tournament can be active at a time.');
    }
    final updated = current.copyWith(status: status, updatedAt: DateTime.now());
    _tournaments[index] = updated;
    return updated;
  }

  @override
  Future<bool> deleteTournament(String id) async {
    await _wait();
    final index = _tournaments.indexWhere((item) => item.id == id);
    if (index < 0) return false;
    final tournament = _tournaments[index];
    if (tournament.hasAuctionTransactions) {
      throw const TournamentArchiveRequiredException(
        'Tournament transactions must be preserved through archival.',
      );
    }
    if (tournament.status == TournamentStatus.active ||
        tournament.status == TournamentStatus.completed ||
        tournament.status == TournamentStatus.archived) {
      throw const TournamentArchiveRequiredException(
        'Active, completed, and archived tournaments cannot be deleted.',
      );
    }
    _tournaments.removeAt(index);
    return true;
  }

  Future<void> _wait() async {
    if (simulatedDelay > Duration.zero) {
      await Future<void>.delayed(simulatedDelay);
    }
  }
}

final demoTournaments = <Tournament>[
  Tournament(
    id: 'tourn_001',
    name: 'Gujarat Premier Auction Arena 2026',
    shortName: 'GPAA 2026',
    seasonYear: '2026',
    startDate: DateTime(2026, 12, 1),
    endDate: DateTime(2026, 12, 15),
    city: 'Ahmedabad',
    venue: 'Narendra Modi Stadium',
    maxTeams: 8,
    status: TournamentStatus.active,
    registrationStartDate: DateTime(2026, 9, 1),
    registrationClosingDate: DateTime(2026, 11, 20),
    format: 'T20',
    organizerName: 'JP AUCTION ARENA Demo',
    contactDetails: 'demo@jp-auction-arena.invalid',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  ),
  Tournament(
    id: 'tourn_002',
    name: 'Western Cricket League 2026',
    shortName: 'WCL 2026',
    seasonYear: '2026',
    startDate: DateTime(2026, 8, 1),
    endDate: DateTime(2026, 8, 10),
    city: 'Vadodara',
    venue: 'Kotambi Stadium',
    maxTeams: 10,
    status: TournamentStatus.upcoming,
    registrationStartDate: DateTime(2026, 6, 1),
    registrationClosingDate: DateTime(2026, 7, 25),
    format: 'T20',
    organizerName: 'Western Cricket League Demo',
    contactDetails: 'wcl@jp-auction-arena.invalid',
    createdAt: DateTime(2026, 2, 1),
    updatedAt: DateTime(2026, 2, 1),
  ),
  Tournament(
    id: 'tourn_003',
    name: 'Ahmedabad T20 Cup 2025',
    shortName: 'ATC 2025',
    seasonYear: '2025',
    startDate: DateTime(2025, 11, 1),
    endDate: DateTime(2025, 11, 12),
    city: 'Ahmedabad',
    venue: 'Adani Sportsline',
    maxTeams: 8,
    status: TournamentStatus.completed,
    registrationStartDate: DateTime(2025, 7, 1),
    registrationClosingDate: DateTime(2025, 10, 25),
    format: 'T20',
    organizerName: 'Ahmedabad T20 Cup Demo',
    contactDetails: 'atc@jp-auction-arena.invalid',
    createdAt: DateTime(2025, 4, 1),
    updatedAt: DateTime(2025, 11, 12),
  ),
];

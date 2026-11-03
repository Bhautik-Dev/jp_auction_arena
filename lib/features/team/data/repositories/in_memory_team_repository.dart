import 'package:jp_auction_arena/features/team/domain/errors/team_exceptions.dart';
import 'package:jp_auction_arena/features/team/domain/models/team.dart';
import 'package:jp_auction_arena/features/team/domain/models/team_status.dart';
import 'package:jp_auction_arena/features/team/domain/repositories/team_repository.dart';
import 'package:jp_auction_arena/features/tournament/domain/repositories/tournament_repository.dart';

class InMemoryTeamRepository implements TeamRepository {
  InMemoryTeamRepository({
    required TournamentRepository tournamentRepository,
    List<Team> initialTeams = const [],
    this.simulatedDelay = const Duration(milliseconds: 150),
  }) : _tournamentRepository = tournamentRepository,
       _teams = List<Team>.of(initialTeams);

  final TournamentRepository _tournamentRepository;
  final List<Team> _teams;
  final Duration simulatedDelay;

  Future<void> _wait() async {
    if (simulatedDelay > Duration.zero) {
      await Future<void>.delayed(simulatedDelay);
    }
  }

  @override
  Future<List<Team>> getTeams({
    String? tournamentId,
    TeamStatus? status,
    String? query,
  }) async {
    await _wait();
    final normalizedQuery = query?.trim().toLowerCase() ?? '';
    final result =
        _teams.where((team) {
          if (tournamentId != null && team.tournamentId != tournamentId) {
            return false;
          }
          if (status != null && team.status != status) {
            return false;
          }
          if (normalizedQuery.isEmpty) return true;

          return team.name.toLowerCase().contains(normalizedQuery) ||
              team.shortName.toLowerCase().contains(normalizedQuery) ||
              team.ownerName.toLowerCase().contains(normalizedQuery) ||
              team.managerName.toLowerCase().contains(normalizedQuery) ||
              team.contactEmail.toLowerCase().contains(normalizedQuery) ||
              team.contactPhone.toLowerCase().contains(normalizedQuery);
        }).toList()..sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
    return result;
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
  Future<Team> createTeam(Team team) async {
    await _wait();
    final tournament = await _tournamentRepository.getTournamentById(
      team.tournamentId,
    );
    if (tournament == null) {
      throw TeamValidationException('Select an existing tournament.');
    }

    _validateUniqueNames(team);
    final tournamentTeamCount = _teams
        .where((existing) => existing.tournamentId == team.tournamentId)
        .length;
    if (tournamentTeamCount >= tournament.maxTeams) {
      throw TeamCapacityExceededException(
        maxTeams: tournament.maxTeams,
        tournamentName: tournament.name,
      );
    }

    final now = DateTime.now();
    final created = team.copyWith(
      id: team.id.isEmpty
          ? 'team_${DateTime.now().microsecondsSinceEpoch}'
          : team.id,
      createdAt: now,
      updatedAt: now,
    );
    _teams.add(created);
    return created;
  }

  @override
  Future<Team> updateTeam(Team team) async {
    await _wait();
    final index = _teams.indexWhere((existing) => existing.id == team.id);
    if (index == -1) throw TeamNotFoundException(team.id);

    final tournament = await _tournamentRepository.getTournamentById(
      team.tournamentId,
    );
    if (tournament == null) {
      throw TeamValidationException('Select an existing tournament.');
    }

    _validateUniqueNames(team, excludingId: team.id);
    if (_teams[index].tournamentId != team.tournamentId) {
      final tournamentTeamCount = _teams
          .where((existing) => existing.tournamentId == team.tournamentId)
          .length;
      if (tournamentTeamCount >= tournament.maxTeams) {
        throw TeamCapacityExceededException(
          maxTeams: tournament.maxTeams,
          tournamentName: tournament.name,
        );
      }
    }

    final updated = team.copyWith(updatedAt: DateTime.now());
    _teams[index] = updated;
    return updated;
  }

  @override
  Future<Team> updateTeamStatus(String id, TeamStatus status) async {
    await _wait();
    final index = _teams.indexWhere((team) => team.id == id);
    if (index == -1) throw TeamNotFoundException(id);

    final updated = _teams[index].copyWith(
      status: status,
      updatedAt: DateTime.now(),
    );
    _teams[index] = updated;
    return updated;
  }

  @override
  Future<bool> deleteTeam(String id) async {
    await _wait();
    final index = _teams.indexWhere((team) => team.id == id);
    if (index == -1) return false;

    final team = _teams[index];
    if (!team.canDelete) {
      throw TeamDeletionBlockedException(
        team.deletionBlockReason ?? 'This team cannot be deleted.',
      );
    }
    _teams.removeAt(index);
    return true;
  }

  void _validateUniqueNames(Team candidate, {String? excludingId}) {
    final normalizedName = _normalize(candidate.name);
    final normalizedShortName = _normalize(candidate.shortName);

    for (final existing in _teams) {
      if (existing.id == excludingId ||
          existing.tournamentId != candidate.tournamentId) {
        continue;
      }
      if (_normalize(existing.name) == normalizedName) {
        throw TeamValidationException(
          'A team with this name already exists in the selected tournament.',
        );
      }
      if (_normalize(existing.shortName) == normalizedShortName) {
        throw TeamValidationException(
          'A team with this short name already exists in the selected tournament.',
        );
      }
    }
  }

  String _normalize(String value) => value.trim().toLowerCase();
}

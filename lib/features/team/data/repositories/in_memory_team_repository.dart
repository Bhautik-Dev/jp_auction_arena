import 'package:jp_auction_arena/features/team/domain/errors/team_exceptions.dart';
import 'package:jp_auction_arena/features/team/domain/models/team.dart';
import 'package:jp_auction_arena/features/team/domain/models/team_status.dart';
import 'package:jp_auction_arena/features/team/domain/repositories/team_repository.dart';
import 'package:jp_auction_arena/features/tournament/domain/repositories/tournament_repository.dart';

class InMemoryTeamRepository implements TeamRepository {
  InMemoryTeamRepository({
    required TournamentRepository tournamentRepository,
    this.simulatedDelay = const Duration(milliseconds: 100),
    List<Team>? initialTeams,
  }) : _tournamentRepository = tournamentRepository,
       _teams = List.of(initialTeams ?? const []);

  final TournamentRepository _tournamentRepository;
  final Duration simulatedDelay;
  final List<Team> _teams;
  int _nextId = 1;

  @override
  Future<List<Team>> getTeams({
    String? tournamentId,
    TeamStatus? status,
    String? query,
  }) async {
    await _wait();
    final normalizedQuery = query?.trim().toLowerCase() ?? '';
    return List.unmodifiable(
      _teams.where((team) {
        final matchesTournament =
            tournamentId == null || team.tournamentId == tournamentId;
        final matchesStatus = status == null || team.status == status;
        final searchable =
            '${team.name} ${team.shortName} ${team.ownerName} '
                    '${team.managerName} ${team.contactEmail} ${team.contactPhone}'
                .toLowerCase();
        return matchesTournament &&
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
  Future<Team> createTeam(Team team) async {
    await _wait();
    _validate(team);
    final tournament = await _tournamentRepository.getTournamentById(
      team.tournamentId,
    );
    if (tournament != null &&
        _teams.where((item) => item.tournamentId == team.tournamentId).length >=
            tournament.maxTeams) {
      throw TeamCapacityExceededException(
        'Tournament team limit of ${tournament.maxTeams} has been reached.',
      );
    }
    final created = team.copyWith(
      id: team.id.isEmpty ? 'team_${_nextId++}' : team.id,
    );
    _teams.add(created);
    return created;
  }

  @override
  Future<Team> updateTeam(Team team) async {
    await _wait();
    final index = _teams.indexWhere((item) => item.id == team.id);
    if (index < 0) throw TeamValidationException('Team ${team.id} not found.');
    _validate(team, excludingId: team.id);
    _teams[index] = team;
    return team;
  }

  @override
  Future<Team> updateTeamStatus(String id, TeamStatus status) async {
    final team = await getTeamById(id);
    if (team == null) throw TeamValidationException('Team $id not found.');
    return updateTeam(team.copyWith(status: status, updatedAt: DateTime.now()));
  }

  @override
  Future<bool> deleteTeam(String id) async {
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
  }

  void _validate(Team team, {String? excludingId}) {
    if (team.name.trim().isEmpty || team.shortName.trim().isEmpty) {
      throw const TeamValidationException(
        'Team name and short name are required.',
      );
    }
    for (final other in _teams) {
      if (other.id == excludingId || other.tournamentId != team.tournamentId) {
        continue;
      }
      if (other.name.trim().toLowerCase() == team.name.trim().toLowerCase()) {
        throw const TeamValidationException(
          'Team name must be unique within a tournament.',
        );
      }
      if (other.shortName.trim().toLowerCase() ==
          team.shortName.trim().toLowerCase()) {
        throw const TeamValidationException(
          'Team short name must be unique within a tournament.',
        );
      }
    }
  }

  Future<void> _wait() async {
    if (simulatedDelay > Duration.zero) {
      await Future<void>.delayed(simulatedDelay);
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

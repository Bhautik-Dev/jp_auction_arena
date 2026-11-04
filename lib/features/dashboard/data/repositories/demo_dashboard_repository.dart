import 'package:jp_auction_arena/features/auth/domain/models/app_role.dart';
import 'package:jp_auction_arena/features/auth/domain/models/auth_user.dart';
import 'package:jp_auction_arena/features/dashboard/domain/models/dashboard_snapshot.dart';
import 'package:jp_auction_arena/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:jp_auction_arena/features/player/domain/models/player.dart';
import 'package:jp_auction_arena/features/player/domain/models/player_status.dart';
import 'package:jp_auction_arena/features/player/domain/repositories/player_repository.dart';
import 'package:jp_auction_arena/features/team/domain/models/team.dart';
import 'package:jp_auction_arena/features/team/domain/repositories/team_repository.dart';
import 'package:jp_auction_arena/features/tournament/domain/models/tournament.dart';
import 'package:jp_auction_arena/features/tournament/domain/models/tournament_status.dart';
import 'package:jp_auction_arena/features/tournament/domain/repositories/tournament_repository.dart';

class DemoDashboardRepository implements DashboardRepository {
  const DemoDashboardRepository({
    required TournamentRepository tournamentRepository,
    required TeamRepository teamRepository,
    required PlayerRepository playerRepository,
  }) : _tournamentRepository = tournamentRepository,
       _teamRepository = teamRepository,
       _playerRepository = playerRepository;

  final TournamentRepository _tournamentRepository;
  final TeamRepository _teamRepository;
  final PlayerRepository _playerRepository;

  @override
  Future<DashboardSnapshot> loadForUser(AuthUser user) async {
    final allTournaments = await _tournamentRepository.getTournaments();
    final allTeams = await _teamRepository.getTeams();
    final allPlayers = await _playerRepository.getPlayers();

    final accessibleTeams = switch (user.role) {
      AppRole.superAdmin => allTeams,
      AppRole.tournamentAdmin =>
        allTeams
            .where((team) => user.tournamentIds.contains(team.tournamentId))
            .toList(),
      AppRole.teamManager =>
        allTeams.where((team) => user.teamIds.contains(team.id)).toList(),
      AppRole.publicViewer =>
        allTeams
            .where(
              (team) => allTournaments.any(
                (tournament) =>
                    tournament.id == team.tournamentId &&
                    tournament.status == TournamentStatus.active,
              ),
            )
            .toList(),
    };

    final accessibleTournamentIds = switch (user.role) {
      AppRole.superAdmin => allTournaments.map((item) => item.id).toSet(),
      AppRole.tournamentAdmin => user.tournamentIds,
      AppRole.teamManager =>
        accessibleTeams.map((item) => item.tournamentId).toSet(),
      AppRole.publicViewer =>
        allTournaments
            .where((item) => item.status == TournamentStatus.active)
            .map((item) => item.id)
            .toSet(),
    };
    final accessibleTournaments = allTournaments
        .where((item) => accessibleTournamentIds.contains(item.id))
        .toList();

    final scopedPlayers = user.role == AppRole.teamManager
        ? allPlayers
              .where((player) => user.teamIds.contains(player.assignedTeamId))
              .toList()
        : allPlayers;

    final teamSummaries = accessibleTeams
        .map((team) => _teamSummary(team, allPlayers))
        .toList();
    final tournamentSummaries = accessibleTournaments
        .map((tournament) => _tournamentSummary(tournament, allTeams))
        .toList();

    DashboardTournamentSummary? activeTournament;
    for (final tournament in tournamentSummaries) {
      if (tournament.status == TournamentStatus.active) {
        activeTournament = tournament;
        break;
      }
    }
    final progressTournamentSummary =
        activeTournament ??
        (tournamentSummaries.isEmpty ? null : tournamentSummaries.first);
    final playerDescription = user.role == AppRole.teamManager
        ? 'Players assigned to your team in the local demo catalog.'
        : 'Synthetic catalog entries; players are not linked to tournaments yet.';

    return DashboardSnapshot(
      role: user.role,
      tournaments: List.unmodifiable(tournamentSummaries),
      teams: List.unmodifiable(teamSummaries),
      registeredPlayerCount: scopedPlayers.length,
      soldPlayerCount: scopedPlayers
          .where((player) => player.status == PlayerStatus.sold)
          .length,
      playerCountDescription: playerDescription,
      auctionStatus: 'Not started · demo placeholder',
      teamRegistrationProgress: progressTournamentSummary == null
          ? 'No assigned tournament'
          : '${progressTournamentSummary.registeredTeamCount} of ${progressTournamentSummary.teamLimit} demo team places',
      playerRegistrationProgress:
          '${scopedPlayers.length} demo catalog entries · tournament links unavailable',
      auctionConfigurationStatus: 'Not configured',
      recentActivity: _activityFor(user.role),
      notifications: _notificationsFor(user.role),
    );
  }

  DashboardTeamSummary _teamSummary(Team team, List<Player> players) {
    final teamPlayers = players.where(
      (player) => player.assignedTeamId == team.id,
    );
    return DashboardTeamSummary(
      id: team.id,
      name: team.name,
      shortName: team.shortName,
      primaryColorValue: team.primaryColorValue,
      status: team.status,
      registeredPlayerCount: teamPlayers.length,
      soldPlayerCount: teamPlayers
          .where((player) => player.status == PlayerStatus.sold)
          .length,
    );
  }

  DashboardTournamentSummary _tournamentSummary(
    Tournament tournament,
    List<Team> allTeams,
  ) => DashboardTournamentSummary(
    id: tournament.id,
    name: tournament.name,
    seasonYear: tournament.seasonYear,
    status: tournament.status,
    registeredTeamCount: allTeams
        .where((team) => team.tournamentId == tournament.id)
        .length,
    teamLimit: tournament.maxTeams,
  );

  List<DashboardActivity> _activityFor(AppRole role) => [
    DashboardActivity(
      title: 'Demo activity feed',
      description: switch (role) {
        AppRole.superAdmin => 'Sample tournament and roster activity.',
        AppRole.tournamentAdmin => 'Sample activity for assigned tournaments.',
        AppRole.teamManager => 'Sample updates for your assigned team.',
        AppRole.publicViewer => 'Only public demo updates are shown.',
      },
    ),
  ];

  List<String> _notificationsFor(AppRole role) => switch (role) {
    AppRole.superAdmin => const [
      'System notifications are sample content in this local demo.',
      'Connect a backend later to receive real system events.',
    ],
    AppRole.tournamentAdmin => const [
      'Tournament activity is demo-only; no auction is configured.',
    ],
    AppRole.teamManager => const [
      'Team purse and squad controls are not configured in this demo.',
    ],
    AppRole.publicViewer => const [
      'Public auction updates are unavailable until a live service exists.',
    ],
  };
}

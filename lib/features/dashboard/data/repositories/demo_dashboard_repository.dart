import 'package:jp_auction_arena/features/auth/domain/models/app_role.dart';
import 'package:jp_auction_arena/features/auth/domain/models/auth_user.dart';
import 'package:jp_auction_arena/features/auction/domain/models/auction_status.dart'
    as auction_status;
import 'package:jp_auction_arena/features/auction/domain/repositories/auction_repository.dart';
import 'package:jp_auction_arena/features/dashboard/domain/models/dashboard_snapshot.dart';
import 'package:jp_auction_arena/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:jp_auction_arena/features/player/domain/models/player.dart';
import 'package:jp_auction_arena/features/player/domain/models/player_status.dart';
import 'package:jp_auction_arena/features/player/domain/repositories/player_repository.dart';
import 'package:jp_auction_arena/features/team/domain/models/team.dart';
import 'package:jp_auction_arena/features/team/domain/repositories/team_repository.dart';

class DemoDashboardRepository implements DashboardRepository {
  const DemoDashboardRepository({
    required TeamRepository teamRepository,
    required PlayerRepository playerRepository,
    required AuctionRepository auctionRepository,
  }) : _teamRepository = teamRepository,
       _playerRepository = playerRepository,
       _auctionRepository = auctionRepository;

  final TeamRepository _teamRepository;
  final PlayerRepository _playerRepository;
  final AuctionRepository _auctionRepository;

  @override
  Future<DashboardSnapshot> loadForUser(AuthUser user) async {
    final allTeams = await _teamRepository.getTeams();
    final allPlayers = await _playerRepository.getPlayers();
    final allAuctions = await _auctionRepository.getAuctions();
    final accessibleAuctions = switch (user.role) {
      AppRole.superAdmin => allAuctions,
      AppRole.tournamentAdmin =>
        allAuctions.where((item) => user.auctionIds.contains(item.id)).toList(),
      AppRole.teamManager || AppRole.publicViewer =>
        allAuctions
            .where((item) => item.status == auction_status.AuctionStatus.live)
            .toList(),
    };
    final auctionIds = accessibleAuctions.map((auction) => auction.id).toSet();
    final accessibleTeams = switch (user.role) {
      AppRole.superAdmin =>
        allTeams.where((team) => auctionIds.contains(team.auctionId)).toList(),
      AppRole.tournamentAdmin =>
        allTeams.where((team) => auctionIds.contains(team.auctionId)).toList(),
      AppRole.teamManager =>
        allTeams.where((team) => user.teamIds.contains(team.id)).toList(),
      AppRole.publicViewer => <Team>[],
    };

    final scopedPlayers = user.role == AppRole.teamManager
        ? allPlayers
              .where((player) => user.teamIds.contains(player.assignedTeamId))
              .toList()
        : allPlayers;

    final teamSummaries = accessibleTeams
        .map((team) => _teamSummary(team, allPlayers))
        .toList();

    final playerDescription = user.role == AppRole.teamManager
        ? 'Players assigned to your team in the local demo catalog.'
        : 'Player catalog entries are not linked to auctions yet.';

    return DashboardSnapshot(
      role: user.role,
      auctions: List.unmodifiable(
        accessibleAuctions.map(
          (auction) => DashboardAuctionSummary(
            id: auction.id,
            name: auction.name,
            auctionDate: auction.auctionDate,
            startTimeMinutes: auction.startTimeMinutes,
            status: auction.status,
            cricketFormat: auction.cricketFormat,
            customFormat: auction.customFormat,
            maxTeams: auction.maxTeams,
            maxPlayersPerTeam: auction.maxPlayersPerTeam,
            minPlayersPerTeam: auction.minPlayersPerTeam,
            totalPursePerTeam: auction.totalPursePerTeam,
            baseCurrency: auction.baseCurrency,
          ),
        ),
      ),
      teams: List.unmodifiable(teamSummaries),
      registeredPlayerCount: scopedPlayers.length,
      soldPlayerCount: scopedPlayers
          .where((player) => player.status == PlayerStatus.sold)
          .length,
      playerCountDescription: playerDescription,
      auctionStatus:
          accessibleAuctions.any(
            (item) => item.status == auction_status.AuctionStatus.live,
          )
          ? 'Live · bidding controls not implemented'
          : 'No live auction',
      teamRegistrationProgress: switch (user.role) {
        AppRole.superAdmin || AppRole.tournamentAdmin =>
          '${accessibleTeams.length} teams registered across ${accessibleAuctions.length} accessible auctions.',
        AppRole.teamManager =>
          accessibleTeams.isEmpty
              ? 'No assigned team registration is available.'
              : 'Showing your assigned team only.',
        AppRole.publicViewer => 'Team registration is not public.',
      },
      playerRegistrationProgress:
          '${scopedPlayers.length} demo catalog entries · auction links unavailable',
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

  List<DashboardActivity> _activityFor(AppRole role) => [
    DashboardActivity(
      title: 'Demo activity feed',
      description: switch (role) {
        AppRole.superAdmin => 'Sample auction records and setup activity.',
        AppRole.tournamentAdmin => 'Sample activity for assigned auctions.',
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
      'Auction and roster information is demo-only; bidding is unavailable.',
    ],
    AppRole.teamManager => const [
      'Team purse and squad controls are not configured in this demo.',
    ],
    AppRole.publicViewer => const [
      'Public auction updates are unavailable until a live service exists.',
    ],
  };
}

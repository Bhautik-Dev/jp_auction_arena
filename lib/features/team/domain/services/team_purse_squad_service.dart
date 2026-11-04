import 'package:jp_auction_arena/features/auction/domain/errors/auction_exceptions.dart';
import 'package:jp_auction_arena/features/auction/domain/models/auction.dart';
import 'package:jp_auction_arena/features/auction/domain/models/auction_status.dart';
import 'package:jp_auction_arena/features/auction/domain/models/auction_rule_set.dart';
import 'package:jp_auction_arena/features/auction/domain/repositories/auction_repository.dart';
import 'package:jp_auction_arena/features/auction/domain/repositories/auction_rule_set_repository.dart';
import 'package:jp_auction_arena/features/auth/domain/models/app_permission.dart';
import 'package:jp_auction_arena/features/auth/domain/models/app_role.dart';
import 'package:jp_auction_arena/features/auth/domain/models/auth_user.dart';
import 'package:jp_auction_arena/features/auth/domain/models/role_permissions.dart';
import 'package:jp_auction_arena/features/player/domain/models/player.dart';
import 'package:jp_auction_arena/features/player/domain/models/player_category.dart';
import 'package:jp_auction_arena/features/player/domain/models/player_status.dart';
import 'package:jp_auction_arena/features/player/domain/repositories/player_repository.dart';
import 'package:jp_auction_arena/features/team/domain/errors/team_exceptions.dart';
import 'package:jp_auction_arena/features/team/domain/models/purse_adjustment.dart';
import 'package:jp_auction_arena/features/team/domain/models/team.dart';
import 'package:jp_auction_arena/features/team/domain/models/team_purse_account.dart';
import 'package:jp_auction_arena/features/team/domain/models/team_squad_snapshot.dart';
import 'package:jp_auction_arena/features/team/domain/repositories/team_purse_repository.dart';
import 'package:jp_auction_arena/features/team/domain/repositories/team_repository.dart';

class TeamPurseSquadService {
  const TeamPurseSquadService({
    required TeamPurseRepository purseRepository,
    required TeamRepository teamRepository,
    required PlayerRepository playerRepository,
    required AuctionRepository auctionRepository,
    required AuctionRuleSetRepository ruleRepository,
    DateTime Function()? clock,
  }) : _purseRepository = purseRepository,
       _teamRepository = teamRepository,
       _playerRepository = playerRepository,
       _auctionRepository = auctionRepository,
       _ruleRepository = ruleRepository,
       _clock = clock ?? DateTime.now;

  final TeamPurseRepository _purseRepository;
  final TeamRepository _teamRepository;
  final PlayerRepository _playerRepository;
  final AuctionRepository _auctionRepository;
  final AuctionRuleSetRepository _ruleRepository;
  final DateTime Function() _clock;

  Future<TeamSquadSnapshot> getSnapshot(
    AuthUser actor, {
    required String auctionId,
    required String teamId,
  }) async {
    final team = await _authorizeView(
      actor,
      auctionId: auctionId,
      teamId: teamId,
    );
    final auction = await _auction(auctionId);
    final rules =
        await _ruleRepository.getByAuctionId(auctionId) ??
        AuctionRuleSet(
          auctionId: auctionId,
          bidIncrementTiers: const [],
          allowUnsoldPlayerReentry: false,
        );
    final allPlayers = await _playerRepository.getPlayers(auctionId: auctionId);
    final squad = allPlayers
        .where(
          (player) =>
              player.status == PlayerStatus.sold &&
              player.assignedTeamId == teamId,
        )
        .toList();
    final categoryCounts = {
      for (final category in PlayerCategory.values)
        category: squad.where((player) => player.category == category).length,
    };
    final adjustments = await _purseRepository.getAdjustments(
      auctionId: auctionId,
      teamId: teamId,
    );
    final initial = await _purseRepository.getInitialPurse(
      auctionId: auctionId,
      teamId: teamId,
      defaultAmount: auction.totalPursePerTeam.round(),
    );
    final totalSpent = squad.fold<int>(
      0,
      (total, player) =>
          total +
          (player.purchasePrice != null && player.purchasePrice! > 0
              ? player.purchasePrice!
              : 0),
    );
    final lastUpdated = [
      team.updatedAt,
      ...adjustments.map((entry) => entry.createdAt),
      ...squad.map((player) => player.updatedAt),
    ].reduce((first, second) => first.isAfter(second) ? first : second);
    final purse = TeamPurseAccount(
      auctionId: auctionId,
      teamId: teamId,
      initialPurse: initial,
      adjustments: adjustments,
      totalSpent: totalSpent,
      purchasedPlayerCount: squad.length,
      lastUpdatedAt: lastUpdated,
      hasUnpricedPurchase: squad.any(
        (player) => player.purchasePrice == null || player.purchasePrice! <= 0,
      ),
    );
    final warnings = _warnings(
      auction: auction,
      rules: rules,
      purse: purse,
      squad: squad,
      categoryCounts: categoryCounts,
    );
    return TeamSquadSnapshot(
      auction: auction,
      team: team,
      purse: purse,
      purchasedPlayers: List.unmodifiable(squad),
      categoryCounts: Map.unmodifiable(categoryCounts),
      warnings: List.unmodifiable(warnings),
      lastUpdatedAt: lastUpdated,
    );
  }

  Future<List<TeamSquadSnapshot>> getAssignedSnapshots(AuthUser actor) async {
    if (actor.role != AppRole.teamManager &&
        actor.role != AppRole.superAdmin &&
        actor.role != AppRole.tournamentAdmin) {
      throw const TeamAccessDeniedException(
        'You do not have permission to view team purse and squad information.',
      );
    }
    if (actor.role == AppRole.teamManager &&
        !RolePermissions.allows(actor.role, AppPermission.viewAssignedTeam)) {
      throw const TeamAccessDeniedException(
        'You do not have permission to view an assigned team.',
      );
    }
    final snapshots = <TeamSquadSnapshot>[];
    for (final teamId in actor.teamIds) {
      final team = await _teamRepository.getTeamById(teamId);
      if (team == null || team.auctionId.isEmpty) continue;
      snapshots.add(
        await getSnapshot(actor, auctionId: team.auctionId, teamId: teamId),
      );
    }
    return List.unmodifiable(snapshots);
  }

  Future<List<TeamSquadSnapshot>> getAuctionSnapshots(
    AuthUser actor, {
    required String auctionId,
  }) async {
    if ((actor.role != AppRole.superAdmin &&
            actor.role != AppRole.tournamentAdmin) ||
        !RolePermissions.allows(actor.role, AppPermission.manageTeams) ||
        !RolePermissions.canAccessAuction(
          actor.role,
          actor.auctionIds,
          auctionId,
        )) {
      throw const TeamAccessDeniedException(
        'You do not have permission to view this auction’s team purses and squads.',
      );
    }
    final teams = await _teamRepository.getTeams(auctionId: auctionId);
    final snapshots = <TeamSquadSnapshot>[];
    for (final team in teams) {
      snapshots.add(
        await getSnapshot(actor, auctionId: auctionId, teamId: team.id),
      );
    }
    return List.unmodifiable(snapshots);
  }

  Future<PurseAdjustment> adjustInitialPurse(
    AuthUser actor, {
    required String auctionId,
    required String teamId,
    required int amount,
    required String reason,
  }) async {
    final team = await _authorizeManage(
      actor,
      auctionId: auctionId,
      teamId: teamId,
    );
    if (amount == 0) {
      throw const TeamValidationException('Purse adjustment must not be zero.');
    }
    if (reason.trim().isEmpty) {
      throw const TeamValidationException(
        'A reason is required for every purse adjustment.',
      );
    }
    final snapshot = await getSnapshot(
      actor,
      auctionId: auctionId,
      teamId: team.id,
    );
    if (snapshot.purse.adjustedInitialPurse + amount <
        snapshot.purse.totalSpent) {
      throw const TeamValidationException(
        'The adjustment cannot reduce the initial purse below the amount spent.',
      );
    }
    return _purseRepository.addAdjustment(
      PurseAdjustment(
        auctionId: auctionId,
        teamId: teamId,
        amount: amount,
        reason: reason.trim(),
        actorId: actor.id,
        createdAt: _clock(),
      ),
      minimumEffectiveInitialPurse: snapshot.purse.totalSpent,
    );
  }

  Future<void> validatePurchase({
    required AuthUser actor,
    required String auctionId,
    required String teamId,
    required Player player,
    required int purchasePrice,
  }) async {
    await _authorizeOperator(actor, auctionId: auctionId, teamId: teamId);
    final auction = await _auction(auctionId);
    if (auction.status == AuctionStatus.completed ||
        auction.status == AuctionStatus.archived) {
      throw const TeamAuctionLockedException(
        'Player purchase validation is unavailable for a closed auction.',
      );
    }
    if (purchasePrice <= 0) {
      throw const TeamValidationException(
        'Purchase price must be greater than zero.',
      );
    }
    final registeredPlayer = await _playerRepository.getPlayerById(player.id);
    if (registeredPlayer == null ||
        registeredPlayer.auctionId != auctionId ||
        registeredPlayer.status != PlayerStatus.available ||
        registeredPlayer.assignedTeamId != null) {
      throw const TeamValidationException(
        'Only an available, unassigned player from this auction can be validated.',
      );
    }
    final players = await _playerRepository.getPlayers(auctionId: auctionId);
    if (players.where((entry) => entry.id == registeredPlayer.id).length != 1) {
      throw const TeamValidationException(
        'Player assignment is duplicated or the player is not registered in this auction.',
      );
    }
    final snapshot = await getSnapshot(
      actor,
      auctionId: auctionId,
      teamId: teamId,
    );
    final nextSquadSize = snapshot.squadSize + 1;
    if (nextSquadSize > snapshot.auction.maxPlayersPerTeam) {
      throw const TeamValidationException(
        'The team has reached the maximum squad size.',
      );
    }
    if (snapshot.purse.remainingPurse < purchasePrice) {
      throw const TeamValidationException(
        'The team does not have enough remaining purse.',
      );
    }
    final rules =
        await _ruleRepository.getByAuctionId(auctionId) ??
        AuctionRuleSet(
          auctionId: auctionId,
          bidIncrementTiers: const [],
          allowUnsoldPlayerReentry: false,
        );
    final categoryLimit = rules.categoryMaximums[registeredPlayer.category];
    if (categoryLimit != null &&
        snapshot.categoryCounts[registeredPlayer.category]! >= categoryLimit) {
      throw TeamValidationException(
        'The team has reached its ${registeredPlayer.category.label} limit.',
      );
    }
    if (registeredPlayer.category == PlayerCategory.wicketKeeper &&
        rules.maximumWicketkeepers != null &&
        snapshot.categoryCounts[PlayerCategory.wicketKeeper]! >=
            rules.maximumWicketkeepers!) {
      throw const TeamValidationException(
        'The team has reached its wicketkeeper limit.',
      );
    }
    if (registeredPlayer.isOverseas &&
        rules.maximumOverseasPlayers != null &&
        snapshot.purchasedPlayers.where((entry) => entry.isOverseas).length >=
            rules.maximumOverseasPlayers!) {
      throw const TeamValidationException(
        'The team has reached its overseas-player limit.',
      );
    }
  }

  Future<Team> _authorizeView(
    AuthUser actor, {
    required String auctionId,
    required String teamId,
  }) async {
    final team = await _team(auctionId, teamId);
    final isTeamOwner =
        actor.role == AppRole.teamManager && actor.teamIds.contains(teamId);
    final canViewAssigned =
        isTeamOwner &&
        RolePermissions.allows(actor.role, AppPermission.viewAssignedTeam);
    final isAdmin =
        (actor.role == AppRole.superAdmin ||
            actor.role == AppRole.tournamentAdmin) &&
        RolePermissions.allows(actor.role, AppPermission.manageTeams) &&
        RolePermissions.canAccessAuction(
          actor.role,
          actor.auctionIds,
          auctionId,
        );
    if (!canViewAssigned && !isAdmin) {
      throw const TeamAccessDeniedException(
        'You cannot view this team’s private purse or squad information.',
      );
    }
    return team;
  }

  Future<Team> _authorizeManage(
    AuthUser actor, {
    required String auctionId,
    required String teamId,
  }) async {
    final team = await _authorizeView(
      actor,
      auctionId: auctionId,
      teamId: teamId,
    );
    await _authorizeOperator(actor, auctionId: auctionId, teamId: teamId);
    final auction = await _auction(auctionId);
    if (auction.status != AuctionStatus.draft &&
        auction.status != AuctionStatus.ready) {
      throw const TeamAuctionLockedException(
        'Purse settings are read-only after the auction becomes Live.',
      );
    }
    return team;
  }

  Future<Team> _authorizeOperator(
    AuthUser actor, {
    required String auctionId,
    required String teamId,
  }) async {
    final team = await _team(auctionId, teamId);
    if ((actor.role != AppRole.superAdmin &&
            actor.role != AppRole.tournamentAdmin) ||
        !RolePermissions.allows(actor.role, AppPermission.manageTeams) ||
        !RolePermissions.canAccessAuction(
          actor.role,
          actor.auctionIds,
          auctionId,
        )) {
      throw const TeamAccessDeniedException(
        'Only authorized admins/operators can manage team purse and squad information.',
      );
    }
    return team;
  }

  Future<Team> _team(String auctionId, String teamId) async {
    final team = await _teamRepository.getTeamById(teamId);
    if (team == null || team.auctionId != auctionId) {
      throw TeamValidationException(
        'Team $teamId was not found in auction $auctionId.',
      );
    }
    return team;
  }

  Future<Auction> _auction(String auctionId) async {
    final auction = await _auctionRepository.getAuctionById(auctionId);
    if (auction == null) {
      throw AuctionValidationException('Auction $auctionId was not found.');
    }
    return auction;
  }

  List<String> _warnings({
    required Auction auction,
    required AuctionRuleSet rules,
    required TeamPurseAccount purse,
    required List<Player> squad,
    required Map<PlayerCategory, int> categoryCounts,
  }) {
    final warnings = <String>[];
    if (purse.remainingPurse < 0) {
      warnings.add('Purse balance is negative and requires admin review.');
    } else if (purse.adjustedInitialPurse > 0 &&
        purse.remainingPurse <= purse.adjustedInitialPurse * 0.1) {
      warnings.add('Low purse: 10% or less remains.');
    }
    if (squad.length > auction.maxPlayersPerTeam) {
      warnings.add('Squad exceeds the configured maximum.');
    }
    if (squad.length < auction.minPlayersPerTeam) {
      warnings.add(
        'Minimum squad requirement not yet met (${auction.minPlayersPerTeam - squad.length} player(s) short).',
      );
    }
    if (purse.hasUnpricedPurchase) {
      warnings.add(
        'Some assigned sold players have no recorded purchase price; total spent may be incomplete.',
      );
    }
    for (final entry in rules.categoryMaximums.entries) {
      if ((categoryCounts[entry.key] ?? 0) > entry.value) {
        warnings.add('${entry.key.label} maximum has been exceeded.');
      }
    }
    if (rules.maximumWicketkeepers != null &&
        (categoryCounts[PlayerCategory.wicketKeeper] ?? 0) >
            rules.maximumWicketkeepers!) {
      warnings.add('Wicketkeeper maximum has been exceeded.');
    }
    if (rules.maximumOverseasPlayers != null &&
        squad.where((player) => player.isOverseas).length >
            rules.maximumOverseasPlayers!) {
      warnings.add('Overseas-player maximum has been exceeded.');
    }
    return warnings;
  }
}

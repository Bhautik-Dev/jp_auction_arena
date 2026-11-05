import 'dart:math';

import 'package:jp_auction_arena/features/auction/domain/errors/auction_exceptions.dart';
import 'package:jp_auction_arena/features/auction/domain/models/auction.dart';
import 'package:jp_auction_arena/features/auction/domain/models/auction_player_queue.dart';
import 'package:jp_auction_arena/features/auction/domain/models/auction_preparation_snapshot.dart';
import 'package:jp_auction_arena/features/auction/domain/models/auction_readiness_item.dart';
import 'package:jp_auction_arena/features/auction/domain/models/auction_rule_set.dart';
import 'package:jp_auction_arena/features/auction/domain/models/auction_status.dart';
import 'package:jp_auction_arena/features/auction/domain/models/player_order_mode.dart';
import 'package:jp_auction_arena/features/auction/domain/repositories/auction_player_queue_repository.dart';
import 'package:jp_auction_arena/features/auction/domain/repositories/auction_repository.dart';
import 'package:jp_auction_arena/features/auction/domain/repositories/auction_rule_set_repository.dart';
import 'package:jp_auction_arena/features/auction/domain/services/auction_rule_engine.dart';
import 'package:jp_auction_arena/features/auth/domain/models/app_role.dart';
import 'package:jp_auction_arena/features/auth/domain/models/auth_user.dart';
import 'package:jp_auction_arena/features/player/domain/models/player.dart';
import 'package:jp_auction_arena/features/player/domain/models/player_category.dart';
import 'package:jp_auction_arena/features/player/domain/models/player_status.dart';
import 'package:jp_auction_arena/features/player/domain/repositories/player_repository.dart';
import 'package:jp_auction_arena/features/team/domain/models/team_status.dart';
import 'package:jp_auction_arena/features/team/domain/repositories/team_repository.dart';

class AuctionPreparationService {
  const AuctionPreparationService({
    required AuctionRepository auctionRepository,
    required AuctionRuleSetRepository ruleRepository,
    required AuctionPlayerQueueRepository queueRepository,
    required PlayerRepository playerRepository,
    required TeamRepository teamRepository,
    AuctionRuleEngine ruleEngine = const AuctionRuleEngine(),
    DateTime Function()? clock,
    Random? random,
  }) : _auctionRepository = auctionRepository,
       _ruleRepository = ruleRepository,
       _queueRepository = queueRepository,
       _playerRepository = playerRepository,
       _teamRepository = teamRepository,
       _ruleEngine = ruleEngine,
       _clock = clock ?? DateTime.now,
       _random = random;

  final AuctionRepository _auctionRepository;
  final AuctionRuleSetRepository _ruleRepository;
  final AuctionPlayerQueueRepository _queueRepository;
  final PlayerRepository _playerRepository;
  final TeamRepository _teamRepository;
  final AuctionRuleEngine _ruleEngine;
  final DateTime Function() _clock;
  final Random? _random;

  Future<AuctionPreparationSnapshot> getPreparation(
    AuthUser actor,
    String auctionId,
  ) async {
    final auction = await _authorize(actor, auctionId);
    final rules = await _rules(auction);
    final players = await _playerRepository.getPlayers(auctionId: auctionId);
    final teams = await _teamRepository.getTeams(
      auctionId: auctionId,
      status: TeamStatus.active,
    );
    final queue = await _queueRepository.getQueue(auctionId);
    final byId = {for (final player in players) player.id: player};
    final queuedPlayers = <Player>[];
    var invalidQueuedCount = 0;
    for (final playerId in queue.playerIds) {
      final player = byId[playerId];
      if (player == null) {
        invalidQueuedCount++;
        continue;
      }
      if (eligibilityReason(player, auction) != null) {
        invalidQueuedCount++;
      }
      queuedPlayers.add(player);
    }

    final profileIssues = players
        .where(
          (player) =>
              player.status == PlayerStatus.available &&
              eligibilityReason(player, auction) != null,
        )
        .length;
    String? rulesError;
    try {
      _ruleEngine.validate(rules, auction: auction);
    } on AuctionValidationException catch (error) {
      rulesError = error.message;
    }
    final rulesValid = rulesError == null;
    final readiness = [
      AuctionReadinessItem(
        label: 'Auction configuration',
        details: rulesValid
            ? 'Auction purse, squad limits, and configured rules are valid.'
            : 'Review auction settings: $rulesError',
        isComplete: rulesValid,
      ),
      AuctionReadinessItem(
        label: 'Registered teams',
        details: teams.length >= 2
            ? '${teams.length} active teams registered.'
            : 'At least two active teams must be registered; ${teams.length} currently available.',
        isComplete: teams.length >= 2,
      ),
      AuctionReadinessItem(
        label: 'Auction queue',
        details: queue.playerIds.isNotEmpty && invalidQueuedCount == 0
            ? '${queue.playerIds.length} eligible player(s) queued.'
            : queue.playerIds.isEmpty
            ? 'Add at least one eligible player to the queue.'
            : '$invalidQueuedCount queued player record(s) are missing or ineligible.',
        isComplete: queue.playerIds.isNotEmpty && invalidQueuedCount == 0,
      ),
      AuctionReadinessItem(
        label: 'Player profile review',
        details: profileIssues == 0
            ? 'No incomplete eligible player profiles found.'
            : '$profileIssues available player profile(s) need review.',
        isComplete: profileIssues == 0,
        isBlocking: false,
      ),
    ];

    final reasons = <String, String>{
      for (final player in players)
        if (eligibilityReason(player, auction) != null)
          player.id: eligibilityReason(player, auction)!,
    };
    return AuctionPreparationSnapshot(
      auction: auction,
      registeredPlayers: List.unmodifiable(players),
      queuedPlayers: List.unmodifiable(queuedPlayers),
      queuedPlayerIds: List.unmodifiable(queue.playerIds),
      playerOrderMode: rules.playerOrderMode,
      ineligibleReasons: Map.unmodifiable(reasons),
      readinessItems: List.unmodifiable(readiness),
    );
  }

  Future<Auction> markReady(AuthUser actor, String auctionId) async {
    final snapshot = await getPreparation(actor, auctionId);
    if (!snapshot.isReady) {
      final blockers = snapshot.readinessItems
          .where((item) => item.isBlocking && !item.isComplete)
          .map((item) => item.label)
          .join(', ');
      throw AuctionTransitionException(
        'Auction is not ready. Complete these checks: $blockers.',
      );
    }
    if (snapshot.auction.status != AuctionStatus.draft) {
      throw const AuctionTransitionException(
        'Only a Draft auction can be marked Ready.',
      );
    }
    return _auctionRepository.updateAuctionStatus(
      auctionId,
      AuctionStatus.ready,
    );
  }

  Future<void> requireReady(AuthUser actor, String auctionId) async {
    final snapshot = await getPreparation(actor, auctionId);
    if (!snapshot.isReady) {
      final blockers = snapshot.readinessItems
          .where((item) => item.isBlocking && !item.isComplete)
          .map((item) => item.label)
          .join(', ');
      throw AuctionTransitionException(
        'Auction is not ready. Complete these checks: $blockers.',
      );
    }
  }

  Future<AuctionPlayerQueue> addToQueue(
    AuthUser actor, {
    required String auctionId,
    required String playerId,
  }) async {
    final auction = await _authorizeForMutation(actor, auctionId);
    final player = await _registeredPlayer(auctionId, playerId);
    final reason = eligibilityReason(player, auction);
    if (reason != null) {
      throw AuctionValidationException('Player is not eligible: $reason');
    }
    final rules = await _rules(auction);
    final categoryById = rules.playerOrderMode == PlayerOrderMode.category
        ? await _categoryById(auctionId)
        : const <String, PlayerCategory>{};
    return _queueRepository.updateQueue(auctionId, (current) {
      if (current.contains(playerId)) {
        throw const AuctionValidationException(
          'This player is already in the auction queue.',
        );
      }
      final ids = [...current, playerId];
      if (rules.playerOrderMode == PlayerOrderMode.category) {
        _sortByCategory(ids, categoryById);
      }
      return ids;
    }, _clock());
  }

  Future<AuctionPlayerQueue> removeFromQueue(
    AuthUser actor, {
    required String auctionId,
    required String playerId,
  }) async {
    await _authorizeForMutation(actor, auctionId);
    return _queueRepository.updateQueue(auctionId, (current) {
      if (!current.contains(playerId)) {
        throw const AuctionValidationException(
          'This player is not in the auction queue.',
        );
      }
      return [...current]..remove(playerId);
    }, _clock());
  }

  Future<AuctionPlayerQueue> movePlayer(
    AuthUser actor, {
    required String auctionId,
    required String playerId,
    required int offset,
  }) async {
    final auction = await _authorizeForMutation(actor, auctionId);
    final rules = await _rules(auction);
    if (rules.playerOrderMode != PlayerOrderMode.manual) {
      throw const AuctionTransitionException(
        'Move controls are available only in Manual order mode.',
      );
    }
    return _queueRepository.updateQueue(auctionId, (current) {
      final from = current.indexOf(playerId);
      final to = from + offset;
      if (from < 0 || offset.abs() != 1 || to < 0 || to >= current.length) {
        throw const AuctionValidationException(
          'Player cannot be moved to the requested queue position.',
        );
      }
      final ids = [...current];
      final moved = ids.removeAt(from);
      ids.insert(to, moved);
      return ids;
    }, _clock());
  }

  Future<AuctionPlayerQueue> reorderQueue(
    AuthUser actor, {
    required String auctionId,
    required List<String> orderedPlayerIds,
  }) async {
    final auction = await _authorizeForMutation(actor, auctionId);
    final rules = await _rules(auction);
    if (rules.playerOrderMode != PlayerOrderMode.manual) {
      throw const AuctionTransitionException(
        'Drag-and-drop ordering is available only in Manual order mode.',
      );
    }
    return _queueRepository.updateQueue(auctionId, (current) {
      if (orderedPlayerIds.length != current.length ||
          orderedPlayerIds.toSet().length != current.length ||
          !orderedPlayerIds.toSet().containsAll(current)) {
        throw const AuctionValidationException(
          'Reordering must preserve every queued player exactly once.',
        );
      }
      return orderedPlayerIds;
    }, _clock());
  }

  Future<AuctionPlayerQueue> applyConfiguredOrder(
    AuthUser actor,
    String auctionId,
  ) async {
    final auction = await _authorizeForMutation(actor, auctionId);
    final rules = await _rules(auction);
    switch (rules.playerOrderMode) {
      case PlayerOrderMode.manual:
        return _queueRepository.getQueue(auctionId);
      case PlayerOrderMode.random:
        return _queueRepository.updateQueue(auctionId, (current) {
          final ids = [...current]..shuffle(_random ?? Random());
          return ids;
        }, _clock());
      case PlayerOrderMode.category:
        final categoryById = await _categoryById(auctionId);
        return _queueRepository.updateQueue(auctionId, (current) {
          final ids = [...current];
          _sortByCategory(ids, categoryById);
          return ids;
        }, _clock());
    }
  }

  String? eligibilityReason(Player player, Auction auction) {
    if (player.auctionId != auction.id) {
      return 'Player is not registered to this auction.';
    }
    if (player.status != PlayerStatus.available) {
      return 'Registration status is ${player.status.label}.';
    }
    if (player.assignedTeamId != null) {
      return 'Player already has a team assignment.';
    }
    if (player.name.trim().isEmpty) return 'Player name is missing.';
    if (player.basePrice <= 0) return 'Base price must be greater than zero.';
    if (player.basePrice > auction.totalPursePerTeam) {
      return 'Base price exceeds the team purse.';
    }
    return null;
  }

  Future<Map<String, PlayerCategory>> _categoryById(String auctionId) async {
    final players = await _playerRepository.getPlayers(auctionId: auctionId);
    return {for (final player in players) player.id: player.category};
  }

  void _sortByCategory(
    List<String> playerIds,
    Map<String, PlayerCategory> categoryById,
  ) {
    final originalOrder = {
      for (var index = 0; index < playerIds.length; index++)
        playerIds[index]: index,
    };
    playerIds.sort((first, second) {
      final firstCategory = categoryById[first];
      final secondCategory = categoryById[second];
      final categoryOrder =
          (firstCategory?.index ?? PlayerCategory.values.length).compareTo(
            secondCategory?.index ?? PlayerCategory.values.length,
          );
      return categoryOrder != 0
          ? categoryOrder
          : originalOrder[first]!.compareTo(originalOrder[second]!);
    });
  }

  Future<Player> _registeredPlayer(String auctionId, String playerId) async {
    final player = await _playerRepository.getPlayerById(playerId);
    if (player == null || player.auctionId != auctionId) {
      throw const AuctionValidationException(
        'Player is not registered in the selected auction.',
      );
    }
    return player;
  }

  Future<Auction> _authorizeForMutation(
    AuthUser actor,
    String auctionId,
  ) async {
    final auction = await _authorize(actor, auctionId);
    if (auction.status != AuctionStatus.draft &&
        auction.status != AuctionStatus.ready) {
      throw const AuctionTransitionException(
        'The player queue is read-only after the auction starts.',
      );
    }
    return auction;
  }

  Future<Auction> _authorize(AuthUser actor, String auctionId) async {
    if (actor.role != AppRole.superAdmin &&
        actor.role != AppRole.tournamentAdmin) {
      throw const AuctionAuthorizationException(
        'Only authorized admins and auction operators can prepare an auction.',
      );
    }
    if (actor.role == AppRole.tournamentAdmin &&
        !actor.auctionIds.contains(auctionId)) {
      throw const AuctionAuthorizationException(
        'You are not assigned to prepare this auction.',
      );
    }
    final auction = await _auctionRepository.getAuctionById(auctionId);
    if (auction == null) {
      throw AuctionValidationException('Auction $auctionId was not found.');
    }
    return auction;
  }

  Future<AuctionRuleSet> _rules(Auction auction) async {
    final rules =
        await _ruleRepository.getByAuctionId(auction.id) ??
        AuctionRuleSet(
          auctionId: auction.id,
          bidIncrementTiers: AuctionRuleEngine.defaultRules,
          allowUnsoldPlayerReentry: false,
        );
    return rules;
  }
}

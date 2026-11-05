import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:jp_auction_arena/features/auction/data/repositories/in_memory_auction_player_queue_repository.dart';
import 'package:jp_auction_arena/features/auction/data/repositories/in_memory_auction_repository.dart';
import 'package:jp_auction_arena/features/auction/data/repositories/in_memory_auction_rule_set_repository.dart';
import 'package:jp_auction_arena/features/auction/domain/errors/auction_exceptions.dart';
import 'package:jp_auction_arena/features/auction/domain/models/auction.dart';
import 'package:jp_auction_arena/features/auction/domain/models/auction_player_queue.dart';
import 'package:jp_auction_arena/features/auction/domain/models/auction_rule_set.dart';
import 'package:jp_auction_arena/features/auction/domain/models/auction_status.dart';
import 'package:jp_auction_arena/features/auction/domain/models/auction_type.dart';
import 'package:jp_auction_arena/features/auction/domain/models/cricket_format.dart';
import 'package:jp_auction_arena/features/auction/domain/models/player_order_mode.dart';
import 'package:jp_auction_arena/features/auction/domain/services/auction_preparation_service.dart';
import 'package:jp_auction_arena/features/auction/domain/services/auction_rule_engine.dart';
import 'package:jp_auction_arena/features/auth/domain/models/app_role.dart';
import 'package:jp_auction_arena/features/auth/domain/models/auth_user.dart';
import 'package:jp_auction_arena/features/player/data/repositories/in_memory_player_repository.dart';
import 'package:jp_auction_arena/features/player/domain/models/player.dart';
import 'package:jp_auction_arena/features/player/domain/models/player_category.dart';
import 'package:jp_auction_arena/features/player/domain/models/player_status.dart';
import 'package:jp_auction_arena/features/team/data/repositories/in_memory_team_repository.dart';
import 'package:jp_auction_arena/features/team/domain/models/team.dart';
import 'package:jp_auction_arena/features/team/domain/models/team_status.dart';

void main() {
  late InMemoryAuctionRepository auctions;
  late InMemoryAuctionRuleSetRepository ruleRepository;
  late InMemoryAuctionPlayerQueueRepository queueRepository;
  late InMemoryTeamRepository teamRepository;
  late InMemoryPlayerRepository playerRepository;
  late AuctionPreparationService service;

  AuctionPreparationService createService({
    InMemoryTeamRepository? teamRepo,
    Random? random,
  }) => AuctionPreparationService(
    auctionRepository: auctions,
    ruleRepository: ruleRepository,
    queueRepository: queueRepository,
    playerRepository: playerRepository,
    teamRepository: teamRepo ?? teamRepository,
    clock: () => DateTime(2026, 11, 5),
    random: random,
  );

  Future<void> addBoth() async {
    await service.addToQueue(_admin, auctionId: 'one', playerId: 'one_bowler');
    await service.addToQueue(_admin, auctionId: 'one', playerId: 'one_batsman');
  }

  setUp(() {
    auctions = InMemoryAuctionRepository(
      initialAuctions: [_auction('one'), _auction('two')],
    );
    ruleRepository = InMemoryAuctionRuleSetRepository(
      auctionRepository: auctions,
      initialRules: {'one': _rules('one'), 'two': _rules('two')},
    );
    queueRepository = InMemoryAuctionPlayerQueueRepository();
    teamRepository = InMemoryTeamRepository(
      auctionRepository: auctions,
      simulatedDelay: Duration.zero,
      initialTeams: [
        _team('one_team_a', 'one'),
        _team('one_team_b', 'one'),
        _team('two_team_a', 'two'),
      ],
    );
    playerRepository = InMemoryPlayerRepository(
      auctionRepository: auctions,
      teamRepository: teamRepository,
      simulatedDelay: Duration.zero,
      initialPlayers: [
        _player('one_bowler', auctionId: 'one', basePrice: 300),
        _player(
          'one_batsman',
          auctionId: 'one',
          category: PlayerCategory.batsman,
          basePrice: 500,
        ),
        _player(
          'one_unavailable',
          auctionId: 'one',
          status: PlayerStatus.unavailable,
        ),
        _player('two_player', auctionId: 'two'),
      ],
    );
    service = createService(random: Random(7));
  });

  test(
    'queue contains only explicitly selected players from its auction',
    () async {
      await service.addToQueue(
        _admin,
        auctionId: 'one',
        playerId: 'one_bowler',
      );
      final one = await service.getPreparation(_admin, 'one');
      final two = await service.getPreparation(_admin, 'two');

      expect(one.registeredPlayers.map((player) => player.id), [
        'one_bowler',
        'one_batsman',
        'one_unavailable',
      ]);
      expect(one.queuedPlayerIds, ['one_bowler']);
      expect(two.queuedPlayerIds, isEmpty);
      await expectLater(
        service.addToQueue(_admin, auctionId: 'one', playerId: 'two_player'),
        throwsA(isA<AuctionValidationException>()),
      );
    },
  );

  test('rejects ineligible and duplicate players', () async {
    await expectLater(
      service.addToQueue(_admin, auctionId: 'one', playerId: 'one_unavailable'),
      throwsA(isA<AuctionValidationException>()),
    );
    await service.addToQueue(_admin, auctionId: 'one', playerId: 'one_bowler');
    await expectLater(
      service.addToQueue(_admin, auctionId: 'one', playerId: 'one_bowler'),
      throwsA(isA<AuctionValidationException>()),
    );
  });

  test(
    'serializes concurrent additions without losing queue entries',
    () async {
      await Future.wait([
        service.addToQueue(_admin, auctionId: 'one', playerId: 'one_bowler'),
        service.addToQueue(_admin, auctionId: 'one', playerId: 'one_batsman'),
      ]);

      expect(
        (await service.getPreparation(_admin, 'one')).queuedPlayerIds.toSet(),
        {'one_bowler', 'one_batsman'},
      );
    },
  );

  test('supports manual move, drag reorder, and queue removal', () async {
    await addBoth();
    await service.movePlayer(
      _admin,
      auctionId: 'one',
      playerId: 'one_batsman',
      offset: -1,
    );
    expect((await service.getPreparation(_admin, 'one')).queuedPlayerIds, [
      'one_batsman',
      'one_bowler',
    ]);
    await service.reorderQueue(
      _admin,
      auctionId: 'one',
      orderedPlayerIds: ['one_bowler', 'one_batsman'],
    );
    await expectLater(
      service.reorderQueue(
        _admin,
        auctionId: 'one',
        orderedPlayerIds: ['one_bowler', 'one_bowler'],
      ),
      throwsA(isA<AuctionValidationException>()),
    );
    await service.removeFromQueue(
      _admin,
      auctionId: 'one',
      playerId: 'one_bowler',
    );
    expect((await service.getPreparation(_admin, 'one')).queuedPlayerIds, [
      'one_batsman',
    ]);
  });

  test(
    'category ordering applies consistently when queueing players',
    () async {
      await ruleRepository.save(
        _rules('one').copyWith(playerOrderMode: PlayerOrderMode.category),
      );
      await addBoth();
      expect((await service.getPreparation(_admin, 'one')).queuedPlayerIds, [
        'one_batsman',
        'one_bowler',
      ]);
      await expectLater(
        service.movePlayer(
          _admin,
          auctionId: 'one',
          playerId: 'one_batsman',
          offset: 1,
        ),
        throwsA(isA<AuctionTransitionException>()),
      );
    },
  );

  test('random ordering retains all queued player registrations', () async {
    await ruleRepository.save(
      _rules('one').copyWith(playerOrderMode: PlayerOrderMode.random),
    );
    await addBoth();
    final ordered = await service.applyConfiguredOrder(_admin, 'one');

    expect(ordered.playerIds.toSet(), {'one_bowler', 'one_batsman'});
    await expectLater(
      service.reorderQueue(
        _admin,
        auctionId: 'one',
        orderedPlayerIds: ordered.playerIds.reversed.toList(),
      ),
      throwsA(isA<AuctionTransitionException>()),
    );
  });

  test('readiness blocks activation until teams and queue are ready', () async {
    final oneTeamRepository = InMemoryTeamRepository(
      auctionRepository: auctions,
      simulatedDelay: Duration.zero,
      initialTeams: [_team('only_team', 'one')],
    );
    final preparation = createService(teamRepo: oneTeamRepository);
    await preparation.addToQueue(
      _admin,
      auctionId: 'one',
      playerId: 'one_bowler',
    );
    final blocked = await preparation.getPreparation(_admin, 'one');
    expect(blocked.isReady, isFalse);
    expect(
      blocked.readinessItems
          .where((item) => item.isBlocking && !item.isComplete)
          .map((item) => item.label),
      contains('Registered teams'),
    );
    await expectLater(
      preparation.markReady(_admin, 'one'),
      throwsA(isA<AuctionTransitionException>()),
    );

    await oneTeamRepository.createTeam(_team('second_team', 'one'));
    expect((await preparation.getPreparation(_admin, 'one')).isReady, isTrue);
    expect(
      (await preparation.markReady(_admin, 'one')).status,
      AuctionStatus.ready,
    );
  });

  test('queue is immutable after auction starts', () async {
    await addBoth();
    await auctions.updateAuctionStatus('one', AuctionStatus.ready);
    await auctions.updateAuctionStatus('one', AuctionStatus.live);
    await expectLater(
      service.removeFromQueue(_admin, auctionId: 'one', playerId: 'one_bowler'),
      throwsA(isA<AuctionTransitionException>()),
    );
    expect((await service.getPreparation(_admin, 'one')).queuedPlayerIds, [
      'one_bowler',
      'one_batsman',
    ]);
  });

  test('restricts queue access to authorized operators', () async {
    final assignedOperator = _user(
      AppRole.tournamentAdmin,
      auctionIds: {'one'},
    );
    await service.addToQueue(
      assignedOperator,
      auctionId: 'one',
      playerId: 'one_bowler',
    );
    await expectLater(
      service.getPreparation(
        _user(AppRole.tournamentAdmin, auctionIds: {'two'}),
        'one',
      ),
      throwsA(isA<AuctionAuthorizationException>()),
    );
    await expectLater(
      service.getPreparation(
        _user(AppRole.teamManager, auctionIds: {'one'}),
        'one',
      ),
      throwsA(isA<AuctionAuthorizationException>()),
    );
    await expectLater(
      service.getPreparation(
        _user(AppRole.publicViewer, auctionIds: {'one'}),
        'one',
      ),
      throwsA(isA<AuctionAuthorizationException>()),
    );
  });

  test('detects stale queue entries as a readiness blocker', () async {
    await queueRepository.saveQueue(
      AuctionPlayerQueue(
        auctionId: 'one',
        playerIds: const ['missing-player'],
        updatedAt: DateTime(2026),
      ),
    );
    final snapshot = await service.getPreparation(_admin, 'one');
    expect(snapshot.isReady, isFalse);
    expect(
      snapshot.readinessItems
          .singleWhere((item) => item.label == 'Auction queue')
          .details,
      contains('missing or ineligible'),
    );
  });
}

const _admin = AuthUser(
  id: 'admin',
  email: 'admin@example.invalid',
  displayName: 'Admin',
  role: AppRole.superAdmin,
);

AuthUser _user(AppRole role, {Set<String> auctionIds = const {}}) => AuthUser(
  id: role.name,
  email: '${role.name}@example.invalid',
  displayName: role.label,
  role: role,
  auctionIds: auctionIds,
);

Auction _auction(String id) => Auction(
  id: id,
  name: 'Auction $id',
  auctionDate: DateTime(2027),
  startTimeMinutes: 600,
  auctionType: AuctionType.liveAuction,
  cricketFormat: CricketFormat.t20,
  maxTeams: 4,
  maxPlayersPerTeam: 12,
  minPlayersPerTeam: 2,
  totalPursePerTeam: 10000,
  baseCurrency: 'INR',
  status: AuctionStatus.draft,
  organizerName: 'Organizer',
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

AuctionRuleSet _rules(String auctionId) => AuctionRuleSet(
  auctionId: auctionId,
  bidIncrementTiers: AuctionRuleEngine.defaultRules,
  allowUnsoldPlayerReentry: false,
);

Team _team(String id, String auctionId) => Team(
  id: id,
  auctionId: auctionId,
  name: 'Team $id',
  shortName: id.toUpperCase(),
  primaryColorValue: 0xFF418BFF,
  secondaryColorValue: 0xFFAA8BFF,
  ownerName: 'Owner',
  managerName: 'Manager',
  contactEmail: '',
  contactPhone: '',
  status: TeamStatus.active,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

Player _player(
  String id, {
  required String auctionId,
  PlayerCategory category = PlayerCategory.allRounder,
  PlayerStatus status = PlayerStatus.available,
  int basePrice = 1000,
}) => Player(
  id: id,
  auctionId: auctionId,
  name: 'Player $id',
  category: category,
  battingStyle: 'Right-hand bat',
  bowlingStyle: 'Right-arm medium',
  basePrice: basePrice,
  contactNumber: null,
  status: status,
  assignedTeamId: null,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

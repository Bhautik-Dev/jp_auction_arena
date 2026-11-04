import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jp_auction_arena/features/auction/data/repositories/in_memory_auction_repository.dart';
import 'package:jp_auction_arena/features/auction/data/repositories/in_memory_auction_rule_set_repository.dart';
import 'package:jp_auction_arena/features/auction/domain/errors/auction_exceptions.dart';
import 'package:jp_auction_arena/features/auction/domain/models/auction.dart';
import 'package:jp_auction_arena/features/auction/domain/models/auction_rule_set.dart';
import 'package:jp_auction_arena/features/auction/domain/models/auction_status.dart';
import 'package:jp_auction_arena/features/auction/domain/models/auction_type.dart';
import 'package:jp_auction_arena/features/auction/domain/models/bid_increment_mode.dart';
import 'package:jp_auction_arena/features/auction/domain/models/bid_increment_tier.dart';
import 'package:jp_auction_arena/features/auction/domain/models/cricket_format.dart';
import 'package:jp_auction_arena/features/auction/domain/services/auction_rule_engine.dart';
import 'package:jp_auction_arena/features/auction/domain/services/auction_rule_management_service.dart';
import 'package:jp_auction_arena/features/auction/presentation/providers/auction_providers.dart';
import 'package:jp_auction_arena/features/auction/presentation/screens/auction_settings_screen.dart';
import 'package:jp_auction_arena/features/auth/application/auth_providers.dart';
import 'package:jp_auction_arena/features/auth/data/repositories/demo_auth_repository.dart';
import 'package:jp_auction_arena/features/auth/domain/models/app_role.dart';
import 'package:jp_auction_arena/features/auth/domain/models/auth_user.dart';
import 'package:jp_auction_arena/features/player/domain/models/player_category.dart';

void main() {
  const engine = AuctionRuleEngine();
  const rules = AuctionRuleSet(
    auctionId: 'one',
    bidIncrementTiers: [
      BidIncrementTier(minimumBid: 0, increment: 500),
      BidIncrementTier(minimumBid: 10000, increment: 1000),
      BidIncrementTier(minimumBid: 50000, increment: 2500),
    ],
    allowUnsoldPlayerReentry: false,
  );
  const admin = AuthUser(
    id: 'admin',
    email: 'admin@example.invalid',
    displayName: 'Admin',
    role: AppRole.superAdmin,
  );
  const manager = AuthUser(
    id: 'manager',
    email: 'manager@example.invalid',
    displayName: 'Manager',
    role: AppRole.teamManager,
  );
  const assignedOperator = AuthUser(
    id: 'operator',
    email: 'operator@example.invalid',
    displayName: 'Operator',
    role: AppRole.tournamentAdmin,
    auctionIds: {'one'},
  );
  const unassignedOperator = AuthUser(
    id: 'other-operator',
    email: 'other@example.invalid',
    displayName: 'Other Operator',
    role: AppRole.tournamentAdmin,
  );

  group('AuctionRuleEngine', () {
    test('calculates fixed increments', () {
      const fixed = AuctionRuleSet(
        auctionId: 'one',
        bidIncrementMode: BidIncrementMode.fixed,
        fixedBidIncrement: 750,
        bidIncrementTiers: [],
        allowUnsoldPlayerReentry: false,
      );
      expect(engine.incrementFor(fixed, 12000), 750);
      expect(engine.nextBid(fixed, 12000), 12750);
    });

    test('selects tiered increments at inclusive boundaries', () {
      expect(engine.incrementFor(rules, 0), 500);
      expect(engine.incrementFor(rules, 9999), 500);
      expect(engine.incrementFor(rules, 10000), 1000);
      expect(engine.incrementFor(rules, 50000), 2500);
      expect(engine.nextBid(rules, 12000), 13000);
    });

    test('rejects overlapping or invalid bid ranges and negative bids', () {
      expect(
        () => engine.validate(
          const AuctionRuleSet(
            auctionId: 'one',
            bidIncrementTiers: [],
            allowUnsoldPlayerReentry: false,
          ),
        ),
        throwsA(isA<AuctionValidationException>()),
      );
      expect(
        () => engine.validate(
          const AuctionRuleSet(
            auctionId: 'one',
            bidIncrementTiers: [
              BidIncrementTier(minimumBid: 0, increment: 500),
              BidIncrementTier(minimumBid: 0, increment: 1000),
            ],
            allowUnsoldPlayerReentry: false,
          ),
        ),
        throwsA(isA<AuctionValidationException>()),
      );
      expect(
        () => engine.validate(
          rules.copyWith(
            bidIncrementTiers: const [
              BidIncrementTier(
                minimumBid: 0,
                maximumBid: 10000,
                increment: 500,
              ),
              BidIncrementTier(minimumBid: 9000, increment: 1000),
            ],
          ),
        ),
        throwsA(isA<AuctionValidationException>()),
      );
      expect(
        () => engine.validate(
          rules.copyWith(
            bidIncrementTiers: const [
              BidIncrementTier(minimumBid: 0, maximumBid: -1, increment: 500),
            ],
          ),
        ),
        throwsA(isA<AuctionValidationException>()),
      );
      expect(
        () => engine.incrementFor(rules, -1),
        throwsA(isA<AuctionValidationException>()),
      );
    });

    test('validates base prices, purse, squad, and category limits', () {
      expect(
        () => engine.validate(
          rules.copyWith(defaultPlayerBasePrice: 0),
          auction: _auction(id: 'one'),
        ),
        throwsA(isA<AuctionValidationException>()),
      );
      expect(
        () => engine.validate(
          rules.copyWith(defaultPlayerBasePrice: 10000001),
          auction: _auction(id: 'one'),
        ),
        throwsA(isA<AuctionValidationException>()),
      );
      expect(
        () => engine.validate(
          rules,
          auction: _auction(id: 'one').copyWith(totalPursePerTeam: 0),
        ),
        throwsA(isA<AuctionValidationException>()),
      );
      expect(
        () => engine.validate(
          rules,
          auction: _auction(id: 'one').copyWith(maxPlayersPerTeam: 5),
        ),
        throwsA(isA<AuctionValidationException>()),
      );
      expect(
        () => engine.validate(
          rules.copyWith(
            categoryMaximums: {
              for (final category in PlayerCategory.values) category: 1,
            },
          ),
          auction: _auction(id: 'one'),
        ),
        throwsA(isA<AuctionValidationException>()),
      );
      expect(
        () => engine.validate(
          rules.copyWith(categoryMaximums: {PlayerCategory.batsman: 19}),
          auction: _auction(id: 'one'),
        ),
        throwsA(isA<AuctionValidationException>()),
      );
    });

    test(
      'validates timer thresholds, extension limits, and optional limits',
      () {
        expect(
          () => engine.validate(rules.copyWith(bidTimerSeconds: 4)),
          throwsA(isA<AuctionValidationException>()),
        );
        expect(
          () => engine.validate(rules.copyWith(warningThresholdSeconds: 30)),
          throwsA(isA<AuctionValidationException>()),
        );
        expect(
          () => engine.validate(
            rules.copyWith(
              bidTimerExtensionEnabled: true,
              bidTimerExtensionSeconds: 121,
              maximumBidTimerExtensions: 1,
            ),
          ),
          throwsA(isA<AuctionValidationException>()),
        );
        expect(
          () => engine.validate(
            rules.copyWith(maximumOverseasPlayers: 19, maximumWicketkeepers: 1),
            auction: _auction(id: 'one'),
          ),
          throwsA(isA<AuctionValidationException>()),
        );
      },
    );
  });

  group('AuctionRuleManagementService', () {
    test('authorizes admins and assigned operators only', () async {
      final service = _service();
      expect((await service.getRules(admin, 'one')).bidIncrementTiers, [
        const BidIncrementTier(minimumBid: 0, increment: 1000),
      ]);
      expect(
        (await service.getRules(assignedOperator, 'one')).auctionId,
        'one',
      );
      await expectLater(
        service.getRules(manager, 'one'),
        throwsA(isA<AuctionAuthorizationException>()),
      );
      await expectLater(
        service.getRules(unassignedOperator, 'one'),
        throwsA(isA<AuctionAuthorizationException>()),
      );
      await expectLater(
        service.saveRules(manager, rules),
        throwsA(isA<AuctionAuthorizationException>()),
      );
      await expectLater(
        service.saveRules(unassignedOperator, rules),
        throwsA(isA<AuctionAuthorizationException>()),
      );
    });

    test('stores rules independently for each auction', () async {
      final service = _service(
        auctions: [
          _auction(id: 'one'),
          _auction(id: 'two'),
        ],
      );
      await service.saveRules(admin, rules);
      final second = rules.copyWith(
        auctionId: 'two',
        bidIncrementTiers: const [
          BidIncrementTier(minimumBid: 0, increment: 200),
        ],
      );
      await service.saveRules(admin, second);

      expect(
        (await service.getRules(
          admin,
          'one',
        )).bidIncrementTiers.first.increment,
        500,
      );
      expect(
        (await service.getRules(
          admin,
          'two',
        )).bidIncrementTiers.first.increment,
        200,
      );
    });

    test('rejects rule updates after an auction becomes live', () async {
      final liveAuction = _auction(id: 'one', status: AuctionStatus.live);
      final service = _service(auctions: [liveAuction]);

      await expectLater(
        service.saveRules(admin, rules.copyWith(bidTimerSeconds: 45)),
        throwsA(isA<AuctionTransitionException>()),
      );
    });
  });

  testWidgets('settings screen edits and saves per-auction bid tiers', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final authRepository = DemoAuthRepository();
    await authRepository.signIn(
      email: 'admin@demo.jp',
      password: 'DemoAdmin!2026',
      rememberMe: false,
    );
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepository),
        auctionRepositoryProvider.overrideWithValue(
          InMemoryAuctionRepository(initialAuctions: [_auction(id: 'one')]),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(authSessionProvider.future);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: AuctionSettingsScreen(auctionId: 'one')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Auction Rules & Configuration'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Bid increment rules'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('tier-0-increment')), findsOneWidget);

    await tester.tap(find.text('Add increment tier'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('tier-1-minimum')),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(
      find.byKey(const ValueKey('tier-1-minimum')),
      '10000',
    );
    await tester.enterText(
      find.byKey(const ValueKey('tier-1-increment')),
      '1500',
    );
    await tester.scrollUntilVisible(
      find.text('Save Rules'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Save Rules'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save Rules'));
    await tester.pumpAndSettle();

    final saved = await container
        .read(auctionRuleSetRepositoryProvider)
        .getByAuctionId('one');
    expect(
      saved?.bidIncrementTiers
          .map((tier) => (tier.minimumBid, tier.increment))
          .toList(),
      [(0, 1000), (10000, 1500)],
    );
    expect(find.text('Auction rules saved.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

AuctionRuleManagementService _service({List<Auction>? auctions}) {
  final repository = InMemoryAuctionRepository(
    initialAuctions: auctions ?? [_auction(id: 'one')],
  );
  return AuctionRuleManagementService(
    repository: InMemoryAuctionRuleSetRepository(auctionRepository: repository),
    auctionRepository: repository,
  );
}

Auction _auction({
  required String id,
  AuctionStatus status = AuctionStatus.ready,
}) {
  final now = DateTime(2026, 1, 1);
  return Auction(
    id: id,
    name: 'Auction $id',
    auctionDate: DateTime(2026, 12, 12),
    startTimeMinutes: 600,
    auctionType: AuctionType.liveAuction,
    cricketFormat: CricketFormat.t20,
    maxTeams: 8,
    maxPlayersPerTeam: 18,
    minPlayersPerTeam: 11,
    totalPursePerTeam: 10000000,
    baseCurrency: 'INR',
    status: status,
    organizerName: 'Organizer',
    createdAt: now,
    updatedAt: now,
  );
}

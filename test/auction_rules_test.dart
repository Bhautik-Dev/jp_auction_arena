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
    test('selects thresholds and calculates the next bid', () {
      expect(engine.incrementFor(rules, 0), 500);
      expect(engine.incrementFor(rules, 9999), 500);
      expect(engine.incrementFor(rules, 10000), 1000);
      expect(engine.incrementFor(rules, 50000), 2500);
      expect(engine.nextBid(rules, 12000), 13000);
    });

    test('rejects invalid auction rules and negative bids', () {
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
        () => engine.incrementFor(rules, -1),
        throwsA(isA<AuctionValidationException>()),
      );
    });
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
        service.saveRules(admin, rules),
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
    expect(find.text('Auction Settings & Rules'), findsOneWidget);
    await tester.ensureVisible(find.text('Bid increments'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).at(1))
          .controller
          ?.text,
      '1000',
    );

    await tester.tap(find.text('Add increment tier'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(2), '10000');
    await tester.enterText(fields.at(3), '1500');
    await tester.ensureVisible(find.text('Save Auction Rules'));
    await tester.tap(find.text('Save Auction Rules'));
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

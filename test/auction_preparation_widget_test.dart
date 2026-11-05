import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jp_auction_arena/features/auction/data/repositories/in_memory_auction_player_queue_repository.dart';
import 'package:jp_auction_arena/features/auction/data/repositories/in_memory_auction_repository.dart';
import 'package:jp_auction_arena/features/auction/data/repositories/in_memory_auction_rule_set_repository.dart';
import 'package:jp_auction_arena/features/auction/domain/models/auction.dart';
import 'package:jp_auction_arena/features/auction/domain/models/auction_rule_set.dart';
import 'package:jp_auction_arena/features/auction/domain/models/auction_status.dart';
import 'package:jp_auction_arena/features/auction/domain/models/auction_type.dart';
import 'package:jp_auction_arena/features/auction/domain/models/cricket_format.dart';
import 'package:jp_auction_arena/features/auction/domain/services/auction_rule_engine.dart';
import 'package:jp_auction_arena/features/auction/presentation/providers/auction_preparation_providers.dart';
import 'package:jp_auction_arena/features/auction/presentation/providers/auction_providers.dart';
import 'package:jp_auction_arena/features/auction/presentation/screens/auction_preparation_screen.dart';
import 'package:jp_auction_arena/features/auth/application/auth_providers.dart';
import 'package:jp_auction_arena/features/auth/domain/models/app_role.dart';
import 'package:jp_auction_arena/features/auth/domain/models/auth_user.dart';
import 'package:jp_auction_arena/features/player/data/repositories/in_memory_player_repository.dart';
import 'package:jp_auction_arena/features/player/domain/models/player.dart';
import 'package:jp_auction_arena/features/player/domain/models/player_category.dart';
import 'package:jp_auction_arena/features/player/domain/models/player_status.dart';
import 'package:jp_auction_arena/features/player/presentation/providers/player_providers.dart';
import 'package:jp_auction_arena/features/team/data/repositories/in_memory_team_repository.dart';
import 'package:jp_auction_arena/features/team/domain/models/team.dart';
import 'package:jp_auction_arena/features/team/domain/models/team_status.dart';
import 'package:jp_auction_arena/features/team/presentation/providers/team_providers.dart';

void main() {
  testWidgets('preparation screen queues an eligible registered player', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final auction = _auction();
    final auctions = InMemoryAuctionRepository(initialAuctions: [auction]);
    final teams = InMemoryTeamRepository(
      auctionRepository: auctions,
      simulatedDelay: Duration.zero,
      initialTeams: [_team('team_one'), _team('team_two')],
    );
    final players = InMemoryPlayerRepository(
      auctionRepository: auctions,
      teamRepository: teams,
      simulatedDelay: Duration.zero,
      initialPlayers: [
        _player('eligible'),
        _player('unavailable', status: PlayerStatus.unavailable),
      ],
    );
    final queue = InMemoryAuctionPlayerQueueRepository();
    final ruleRepository = InMemoryAuctionRuleSetRepository(
      auctionRepository: auctions,
      initialRules: {
        auction.id: AuctionRuleSet(
          auctionId: auction.id,
          bidIncrementTiers: AuctionRuleEngine.defaultRules,
          allowUnsoldPlayerReentry: false,
        ),
      },
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authSessionProvider.overrideWith(_TestAuthController.new),
          auctionRepositoryProvider.overrideWithValue(auctions),
          auctionRuleSetRepositoryProvider.overrideWithValue(ruleRepository),
          auctionPlayerQueueRepositoryProvider.overrideWithValue(queue),
          teamRepositoryProvider.overrideWithValue(teams),
          playerRepositoryProvider.overrideWithValue(players),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: AuctionPreparationScreen(auctionId: 'auction_one'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Auction readiness checklist'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Player eligible'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Player eligible'), findsOneWidget);
    await tester.ensureVisible(find.text('Add to queue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add to queue'));
    await tester.pumpAndSettle();
    expect((await queue.getQueue(auction.id)).playerIds, ['eligible']);

    await tester.scrollUntilVisible(
      find.text('Player unavailable'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Player unavailable'), findsOneWidget);
    expect(
      find.textContaining('Ineligible: Registration status is Unavailable.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

class _TestAuthController extends AuthSessionController {
  @override
  Future<UserSession?> build() async => UserSession(
    user: const AuthUser(
      id: 'admin',
      email: 'admin@example.invalid',
      displayName: 'Admin',
      role: AppRole.superAdmin,
    ),
    rememberMe: false,
    signedInAt: DateTime(2026),
  );
}

Auction _auction() => Auction(
  id: 'auction_one',
  name: 'Test Auction',
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

Team _team(String id) => Team(
  id: id,
  auctionId: 'auction_one',
  name: id,
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

Player _player(String id, {PlayerStatus status = PlayerStatus.available}) =>
    Player(
      id: id,
      auctionId: 'auction_one',
      name: 'Player $id',
      category: PlayerCategory.batsman,
      battingStyle: 'Right-hand bat',
      bowlingStyle: '',
      basePrice: 1000,
      contactNumber: null,
      status: status,
      assignedTeamId: null,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

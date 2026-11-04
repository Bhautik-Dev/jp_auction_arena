import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:jp_auction_arena/core/theme/app_theme.dart';
import 'package:jp_auction_arena/features/auction/data/repositories/in_memory_auction_repository.dart';
import 'package:jp_auction_arena/features/auction/domain/models/auction_status.dart';
import 'package:jp_auction_arena/features/auction/presentation/providers/auction_providers.dart';
import 'package:jp_auction_arena/features/auth/application/auth_providers.dart';
import 'package:jp_auction_arena/features/auth/data/repositories/demo_auth_repository.dart';
import 'package:jp_auction_arena/features/player/data/repositories/in_memory_player_repository.dart';
import 'package:jp_auction_arena/features/player/domain/models/player_category.dart';
import 'package:jp_auction_arena/features/player/presentation/providers/player_providers.dart';
import 'package:jp_auction_arena/features/player/presentation/screens/player_form_screen.dart';
import 'package:jp_auction_arena/features/player/presentation/screens/player_list_screen.dart';
import 'package:jp_auction_arena/features/team/data/repositories/in_memory_team_repository.dart';
import 'package:jp_auction_arena/features/team/presentation/providers/team_providers.dart';
import 'package:jp_auction_arena/features/tournament/data/repositories/in_memory_tournament_repository.dart';

void main() {
  testWidgets('auction player list displays and filters registrations', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fixture = await _fixture(withPlayers: true);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(fixture.auth),
          auctionRepositoryProvider.overrideWithValue(fixture.auctions),
          teamRepositoryProvider.overrideWithValue(fixture.teams),
          playerRepositoryProvider.overrideWithValue(fixture.players),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const PlayerListScreen(auctionId: 'auction_one'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Players'), findsOneWidget);
    expect(find.text('Aarav Patel'), findsOneWidget);
    expect(find.textContaining('Batsman'), findsOneWidget);
    expect(find.text('Available'), findsWidgets);
    expect(find.text('Gujarat Premier Auction Arena 2026'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.enterText(find.byType(TextField).first, 'Kabir');
    await tester.pumpAndSettle();
    expect(find.text('Kabir Desai'), findsOneWidget);
    expect(find.text('Aarav Patel'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('player form validates and registers in the selected auction', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fixture = await _fixture();
    final router = GoRouter(
      initialLocation: '/app/auctions/auction_one/players',
      routes: [
        GoRoute(
          path: '/app/auctions/:auctionId/players',
          builder: (context, state) =>
              PlayerListScreen(auctionId: state.pathParameters['auctionId']!),
          routes: [
            GoRoute(
              path: 'create',
              builder: (context, state) => PlayerFormScreen(
                auctionId: state.pathParameters['auctionId']!,
              ),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(fixture.auth),
          auctionRepositoryProvider.overrideWithValue(fixture.auctions),
          teamRepositoryProvider.overrideWithValue(fixture.teams),
          playerRepositoryProvider.overrideWithValue(fixture.players),
        ],
        child: MaterialApp.router(
          theme: AppTheme.darkTheme,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add Player'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add player'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a player name'), findsOneWidget);
    expect(find.text('Choose a category'), findsOneWidget);
    expect(find.text('Enter a valid base price'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Player name'),
      'New Player',
    );
    final categoryField = find.byType(DropdownButtonFormField<PlayerCategory>);
    final categoryWidget = tester
        .widget<DropdownButtonFormField<PlayerCategory>>(categoryField);
    categoryWidget.onChanged!(PlayerCategory.allRounder);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Batting style'),
      'Right-hand bat',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Bowling style'),
      'Right-arm spin',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Base price'),
      '25000',
    );
    await tester.ensureVisible(find.text('Add player'));
    await tester.tap(find.text('Add player'));
    await tester.pumpAndSettle();

    expect(find.text('New Player'), findsWidgets);
    expect(find.textContaining('All-rounder'), findsOneWidget);
    expect(
      (await fixture.players.getPlayers(
        auctionId: 'auction_one',
        query: 'New Player',
      )).single.name,
      'New Player',
    );
    expect(tester.takeException(), isNull);
  });
}

Future<_Fixture> _fixture({bool withPlayers = false}) async {
  final auction = demoAuctions.first.copyWith(
    id: 'auction_one',
    status: AuctionStatus.draft,
  );
  final auctions = InMemoryAuctionRepository(initialAuctions: [auction]);
  final tournaments = InMemoryTournamentRepository(
    simulatedDelay: Duration.zero,
  );
  final teams = InMemoryTeamRepository(
    auctionRepository: auctions,
    tournamentRepository: tournaments,
    simulatedDelay: Duration.zero,
  );
  final players = InMemoryPlayerRepository(
    auctionRepository: auctions,
    teamRepository: teams,
    initialPlayers: withPlayers
        ? [
            for (final player in demoPlayers)
              player.copyWith(auctionId: 'auction_one'),
          ]
        : const [],
    simulatedDelay: Duration.zero,
  );
  final auth = DemoAuthRepository();
  await auth.signIn(
    email: 'admin@demo.jp',
    password: 'DemoAdmin!2026',
    rememberMe: false,
  );
  return _Fixture(
    auctions: auctions,
    teams: teams,
    players: players,
    auth: auth,
  );
}

class _Fixture {
  const _Fixture({
    required this.auctions,
    required this.teams,
    required this.players,
    required this.auth,
  });

  final InMemoryAuctionRepository auctions;
  final InMemoryTeamRepository teams;
  final InMemoryPlayerRepository players;
  final DemoAuthRepository auth;
}

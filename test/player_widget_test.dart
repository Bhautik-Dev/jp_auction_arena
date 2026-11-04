import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:jp_auction_arena/core/theme/app_theme.dart';
import 'package:jp_auction_arena/features/player/data/repositories/in_memory_player_repository.dart';
import 'package:jp_auction_arena/features/player/domain/models/player_category.dart';
import 'package:jp_auction_arena/features/player/presentation/providers/player_providers.dart';
import 'package:jp_auction_arena/features/player/presentation/screens/player_form_screen.dart';
import 'package:jp_auction_arena/features/player/presentation/screens/player_list_screen.dart';
import 'package:jp_auction_arena/features/team/data/repositories/in_memory_team_repository.dart';
import 'package:jp_auction_arena/features/team/presentation/providers/team_providers.dart';
import 'package:jp_auction_arena/features/tournament/data/repositories/in_memory_tournament_repository.dart';

void main() {
  testWidgets('player list displays player information and filters', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final tournamentRepository = InMemoryTournamentRepository(
      simulatedDelay: Duration.zero,
    );
    final teamRepository = InMemoryTeamRepository(
      tournamentRepository: tournamentRepository,
      initialTeams: demoTeams,
      simulatedDelay: Duration.zero,
    );
    final playerRepository = InMemoryPlayerRepository(
      teamRepository: teamRepository,
      initialPlayers: demoPlayers,
      simulatedDelay: Duration.zero,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          teamRepositoryProvider.overrideWithValue(teamRepository),
          playerRepositoryProvider.overrideWithValue(playerRepository),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const PlayerListScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Players'), findsOneWidget);
    expect(find.text('Aarav Patel'), findsOneWidget);
    expect(find.text('Batsman'), findsOneWidget);
    expect(find.text('Available'), findsWidgets);
    expect(find.text('Gujarat Premier Auction Arena 2026'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.enterText(find.byType(TextField).first, 'Kabir');
    await tester.pumpAndSettle();
    expect(find.text('Kabir Desai'), findsOneWidget);
    expect(find.text('Aarav Patel'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('player form validates and creates a player', (tester) async {
    tester.view.physicalSize = const Size(900, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final tournaments = InMemoryTournamentRepository(
      simulatedDelay: Duration.zero,
    );
    final teams = InMemoryTeamRepository(
      tournamentRepository: tournaments,
      initialTeams: demoTeams,
      simulatedDelay: Duration.zero,
    );
    final players = InMemoryPlayerRepository(
      teamRepository: teams,
      initialPlayers: const [],
      simulatedDelay: Duration.zero,
    );
    final router = GoRouter(
      initialLocation: '/players',
      routes: [
        GoRoute(
          path: '/players',
          builder: (context, state) => const PlayerListScreen(),
          routes: [
            GoRoute(
              path: 'create',
              builder: (context, state) => const PlayerFormScreen(),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          teamRepositoryProvider.overrideWithValue(teams),
          playerRepositoryProvider.overrideWithValue(players),
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

    await tester.enterText(find.byType(TextFormField).at(0), 'New Player');
    await tester.tap(find.byType(DropdownButtonFormField<PlayerCategory>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('All-rounder').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(1), 'Right-hand bat');
    await tester.enterText(find.byType(TextFormField).at(2), 'Right-arm spin');
    await tester.enterText(find.byType(TextFormField).at(3), '25000');
    await tester.ensureVisible(find.text('Add player'));
    await tester.tap(find.text('Add player'));
    await tester.pumpAndSettle();

    expect(find.text('New Player'), findsWidgets);
    expect(find.text('All-rounder'), findsOneWidget);
    expect(
      (await players.getPlayers(query: 'New Player')).single.name,
      'New Player',
    );
    expect(tester.takeException(), isNull);
  });
}

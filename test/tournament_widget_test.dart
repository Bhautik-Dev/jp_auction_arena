import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jp_auction_arena/core/theme/app_theme.dart';
import 'package:jp_auction_arena/features/tournament/data/repositories/in_memory_tournament_repository.dart';
import 'package:jp_auction_arena/features/tournament/presentation/providers/tournament_providers.dart';
import 'package:jp_auction_arena/features/tournament/presentation/screens/tournament_list_screen.dart';

void main() {
  testWidgets('TournamentListScreen renders filter bar and tournament cards',
      (WidgetTester tester) async {
    // Override repository with zero delay for instant testing
    final testRepo = InMemoryTournamentRepository(simulatedDelay: Duration.zero);

    // Use a large surface size to avoid overflow in test viewport
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tournamentRepositoryProvider.overrideWithValue(testRepo),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const TournamentListScreen(),
        ),
      ),
    );

    // Initial pump & settle
    await tester.pumpAndSettle();

    // Verify Title & Actions
    expect(find.text('Tournaments'), findsOneWidget);
    expect(find.text('New Tournament'), findsOneWidget);

    // Verify Filter Chips
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Active'), findsWidgets);
    expect(find.text('Draft'), findsWidgets);

    // Verify seeded tournament cards appear
    expect(find.text('Gujarat Premier Auction Arena 2026'), findsOneWidget);
  });
}

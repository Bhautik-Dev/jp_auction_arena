import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jp_auction_arena/app.dart';
import 'package:jp_auction_arena/core/config/app_config.dart';

void main() {
  testWidgets('App smoke test - mounts successfully and renders home screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: JpAuctionArenaApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify app title appears in app bar and header
    expect(find.text(AppConfig.appName), findsWidgets);

    // Verify theme toggle button exists
    expect(find.byTooltip('Toggle Theme'), findsOneWidget);

    // Tap theme toggle
    await tester.tap(find.byTooltip('Toggle Theme'));
    await tester.pumpAndSettle();

    // Verify core sections render
    expect(find.text('Architecture Overview'), findsOneWidget);
    expect(find.text('Core Foundation'), findsOneWidget);
    expect(find.text('Shared Component Library'), findsOneWidget);
    expect(find.text('Feature-Driven Modules'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jp_auction_arena/app.dart';
import 'package:jp_auction_arena/core/constants/app_colors.dart';
import 'package:jp_auction_arena/core/constants/app_strings.dart';
import 'package:jp_auction_arena/core/responsive/app_breakpoints.dart';

void main() {
  test('responsive breakpoints separate compact and desktop navigation', () {
    expect(AppBreakpoints.usesBottomNavigation(599), isTrue);
    expect(AppBreakpoints.usesBottomNavigation(600), isFalse);
    expect(AppBreakpoints.usesExtendedNavigation(1279), isFalse);
    expect(AppBreakpoints.usesExtendedNavigation(1280), isTrue);
  });

  testWidgets('dashboard uses the branded Material 3 dark theme', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: JpAuctionArenaApp()));
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));

    expect(find.text(AppStrings.welcomeTitle), findsOneWidget);
    expect(app.theme?.useMaterial3, isTrue);
    expect(app.darkTheme?.colorScheme.primary, AppColors.electricBlue);
    expect(app.themeMode, ThemeMode.dark);

    await tester.tap(find.byTooltip(AppStrings.lightMode));
    await tester.pumpAndSettle();

    final lightModeApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(lightModeApp.themeMode, ThemeMode.light);
  });

  testWidgets('compact layout shows bottom navigation and opens tournaments', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: JpAuctionArenaApp()));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text(AppStrings.welcomeTitle), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text(AppStrings.tournaments));
    await tester.pumpAndSettle();

    expect(find.text('Create Tournament'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text(AppStrings.teams));
    await tester.pumpAndSettle();

    expect(find.text('Teams').first, findsOneWidget);
    expect(find.text('Create Team'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text(AppStrings.players));
    await tester.pumpAndSettle();

    expect(find.text('Players').first, findsOneWidget);
    expect(find.text('Add Player'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Aarav Patel'));
    await tester.pumpAndSettle();

    expect(find.text('Player details'), findsOneWidget);
    expect(find.text('Base price'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('wide layout shows the navigation rail', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: JpAuctionArenaApp()));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.text(AppStrings.welcomeTitle), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

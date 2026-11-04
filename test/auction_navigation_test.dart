import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:jp_auction_arena/app.dart';
import 'package:jp_auction_arena/core/routing/route_names.dart';
import 'package:jp_auction_arena/features/auction/presentation/screens/auction_detail_screen.dart';
import 'package:jp_auction_arena/features/auction/presentation/screens/auction_form_screen.dart';
import 'package:jp_auction_arena/features/auth/application/auth_providers.dart';
import 'package:jp_auction_arena/features/auth/data/repositories/demo_auth_repository.dart';
import 'package:jp_auction_arena/features/dashboard/presentation/screens/dashboard_screen.dart';

void main() {
  testWidgets('Super Admin creates an auction and manages its lifecycle', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = DemoAuthRepository();
    await repository.signIn(
      email: 'admin@demo.jp',
      password: 'DemoAdmin!2026',
      rememberMe: false,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: const JpAuctionArenaApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('CREATE NEW AUCTION'), findsOneWidget);
    final router = GoRouter.of(tester.element(find.byType(DashboardScreen)));
    router.go(RouteNames.auctionCreate);
    await tester.pumpAndSettle();
    expect(find.byType(AuctionFormScreen), findsOneWidget);
    expect(tester.takeException(), isNull);

    await _tap(tester, 'Create Auction');
    await tester.pumpAndSettle();
    expect(find.text('Auction Name is required.'), findsOneWidget);

    await _enterField(tester, 'Auction Name', 'Test Cricket Auction');
    await _enterField(tester, 'Organizer Name', 'Arena Organizers');
    await _tap(tester, 'Create Auction');
    await tester.pumpAndSettle();
    expect(find.byType(AuctionDetailScreen), findsOneWidget);
    expect(find.text('Test Cricket Auction'), findsOneWidget);

    await _tap(tester, 'Mark Ready');
    await tester.pumpAndSettle();
    await _tap(tester, 'Confirm');
    await tester.pumpAndSettle();
    expect(find.text('Ready'), findsOneWidget);

    await _tap(tester, 'Activate Auction');
    await tester.pumpAndSettle();
    await _tap(tester, 'Confirm');
    await tester.pumpAndSettle();
    expect(find.text('Live'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _tap(WidgetTester tester, String label) async {
  final finder = find.text(label).last;
  await tester.ensureVisible(finder);
  await tester.tap(finder);
}

Future<void> _enterField(
  WidgetTester tester,
  String label,
  String value,
) async {
  final field = find.widgetWithText(TextFormField, label);
  await tester.ensureVisible(field);
  await tester.enterText(field, value);
  await tester.pump();
}

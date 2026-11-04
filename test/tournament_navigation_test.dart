import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:jp_auction_arena/app.dart';
import 'package:jp_auction_arena/core/routing/route_names.dart';
import 'package:jp_auction_arena/features/auth/application/auth_providers.dart';
import 'package:jp_auction_arena/features/auth/data/repositories/demo_auth_repository.dart';
import 'package:jp_auction_arena/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:jp_auction_arena/features/tournament/presentation/screens/tournament_detail_screen.dart';
import 'package:jp_auction_arena/features/tournament/presentation/screens/tournament_form_screen.dart';

void main() {
  testWidgets('Super Admin creates, edits, and changes tournament status', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final authRepository = DemoAuthRepository();
    await authRepository.signIn(
      email: 'admin@demo.jp',
      password: 'DemoAdmin!2026',
      rememberMe: false,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(authRepository)],
        child: const JpAuctionArenaApp(),
      ),
    );
    await tester.pumpAndSettle();

    final router = GoRouter.of(tester.element(find.byType(DashboardScreen)));
    router.go(RouteNames.tournaments);
    await tester.pumpAndSettle();
    await tester.tap(find.text('New Tournament'));
    await tester.pumpAndSettle();
    expect(find.byType(TournamentFormScreen), findsOneWidget);

    await _tap(tester, 'Save Tournament');
    await tester.pumpAndSettle();
    expect(find.text('Tournament name is required.'), findsOneWidget);

    await _enterField(tester, 'Tournament name *', 'Fresh Cricket Cup');
    await _enterField(tester, 'Tournament location *', 'Surat');
    await _enterField(tester, 'Organizer name *', 'Arena Organizers');
    await _enterField(tester, 'Contact details *', 'organizer@demo.invalid');
    await _tap(tester, 'Save Tournament');
    await tester.pumpAndSettle();

    expect(find.byType(TournamentDetailScreen), findsOneWidget);
    expect(find.text('Fresh Cricket Cup'), findsWidgets);
    expect(find.text('Draft'), findsWidgets);

    await tester.tap(find.text('Edit tournament'));
    await tester.pumpAndSettle();
    await _enterField(tester, 'Tournament name *', 'Fresh Cricket Cup Updated');
    await _tap(tester, 'Save Tournament');
    await tester.pumpAndSettle();
    expect(find.text('Fresh Cricket Cup Updated'), findsWidgets);

    await _tap(tester, 'Manage status');
    await tester.pumpAndSettle();
    await _tap(tester, 'Change to Upcoming');
    await tester.pumpAndSettle();
    await _tap(tester, 'Change status');
    await tester.pumpAndSettle();
    expect(find.text('Upcoming'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _tap(WidgetTester tester, String label) async {
  final finder = find.text(label);
  await tester.scrollUntilVisible(
    finder,
    400,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.tap(finder);
}

Future<void> _enterField(
  WidgetTester tester,
  String label,
  String value,
) async {
  final field = find.widgetWithText(TextFormField, label);
  await tester.scrollUntilVisible(
    field,
    400,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.enterText(field, value);
  await tester.pump();
}

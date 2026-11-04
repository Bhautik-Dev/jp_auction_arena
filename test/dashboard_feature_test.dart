import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jp_auction_arena/app.dart';
import 'package:jp_auction_arena/features/auth/application/auth_providers.dart';
import 'package:jp_auction_arena/features/auth/data/repositories/demo_auth_repository.dart';
import 'package:jp_auction_arena/features/auth/domain/models/app_role.dart';
import 'package:jp_auction_arena/features/auth/domain/models/auth_user.dart';
import 'package:jp_auction_arena/features/dashboard/application/dashboard_providers.dart';
import 'package:jp_auction_arena/features/dashboard/presentation/screens/dashboard_screen.dart';

void main() {
  testWidgets('Super Admin sees application-wide demo overview', (
    tester,
  ) async {
    final repository = await _signedInRepository('admin@demo.jp');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: const JpAuctionArenaApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(DashboardScreen), findsOneWidget);
    expect(find.text('Application overview'), findsOneWidget);
    expect(find.text('DEMO DATA · NOT LIVE'), findsOneWidget);
    expect(find.text('Total tournaments'), findsOneWidget);
    expect(find.text('Completed tournaments'), findsOneWidget);
    expect(find.text('Quick actions'), findsOneWidget);
    expect(find.text('System notifications'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Tournament Admin sees assigned tournament summary', (
    tester,
  ) async {
    final repository = await _signedInRepository('operator@demo.jp');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: const JpAuctionArenaApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tournament control center'), findsOneWidget);
    expect(find.text('Assigned tournament'), findsOneWidget);
    expect(find.text('Gujarat Premier Auction Arena 2026'), findsOneWidget);
    expect(find.text('Auction readiness'), findsOneWidget);
    expect(find.text('Not configured'), findsOneWidget);
    expect(find.text('Western Cricket League 2026'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Team Manager sees only assigned-team details and no bidding', (
    tester,
  ) async {
    final repository = await _signedInRepository('team@demo.jp');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: const JpAuctionArenaApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Your team dashboard'), findsOneWidget);
    expect(find.text('Ahmedabad Strikers'), findsOneWidget);
    expect(find.text('Vadodara Warriors'), findsNothing);
    expect(find.textContaining('Illustrative demo purse'), findsOneWidget);
    expect(find.textContaining('Remaining demo purse'), findsOneWidget);
    expect(find.text('Tournaments'), findsNothing);
    expect(find.text('Players'), findsNothing);
    expect(find.textContaining('Place bid'), findsNothing);
    expect(find.textContaining('Bid'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Public Viewer sees read-only public content and navigation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = await _signedInRepository('viewer@demo.jp');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: const JpAuctionArenaApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tournament overview'), findsOneWidget);
    expect(find.text('Participating teams'), findsOneWidget);
    expect(find.text('Gujarat Premier Auction Arena 2026'), findsOneWidget);
    expect(find.text('Public live view'), findsOneWidget);
    expect(find.text('Create Team'), findsNothing);
    expect(find.text('Tournaments'), findsNothing);
    expect(find.text('Players'), findsNothing);
    expect(find.text('Settings'), findsNothing);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Public Live'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Public Live Auction'), findsOneWidget);
    await tester.tap(find.byTooltip('Back to dashboard'));
    await tester.pumpAndSettle();
    expect(find.text('Tournament overview'), findsOneWidget);
  });

  test('dashboard data repository scopes teams by role assignment', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final repository = container.read(dashboardRepositoryProvider);

    const teamManager = AuthUser(
      id: 'manager',
      email: 'team@demo.jp',
      displayName: 'Demo Manager',
      role: AppRole.teamManager,
      teamIds: {'team_001'},
    );
    const publicViewer = AuthUser(
      id: 'viewer',
      email: 'viewer@demo.jp',
      displayName: 'Demo Viewer',
      role: AppRole.publicViewer,
    );

    final teamSnapshot = await repository.loadForUser(teamManager);
    final publicSnapshot = await repository.loadForUser(publicViewer);

    expect(teamSnapshot.teams.map((team) => team.id), ['team_001']);
    expect(publicSnapshot.teams.map((team) => team.name), [
      'Ahmedabad Strikers',
      'Vadodara Warriors',
    ]);
    expect(teamSnapshot.role, AppRole.teamManager);
    expect(publicSnapshot.isDemoData, isTrue);
  });
}

Future<DemoAuthRepository> _signedInRepository(String email) async {
  final repository = DemoAuthRepository();
  final credentials = switch (email) {
    'admin@demo.jp' => 'DemoAdmin!2026',
    'operator@demo.jp' => 'DemoOperator!2026',
    'team@demo.jp' => 'DemoTeam!2026',
    _ => 'DemoViewer!2026',
  };
  await repository.signIn(
    email: email,
    password: credentials,
    rememberMe: false,
  );
  return repository;
}

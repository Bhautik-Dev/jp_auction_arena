import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:jp_auction_arena/app.dart';
import 'package:jp_auction_arena/core/routing/route_names.dart';
import 'package:jp_auction_arena/features/auth/application/auth_providers.dart';
import 'package:jp_auction_arena/features/auth/application/route_access_policy.dart';
import 'package:jp_auction_arena/features/auth/data/repositories/demo_auth_repository.dart';
import 'package:jp_auction_arena/features/auth/domain/errors/auth_exception.dart';
import 'package:jp_auction_arena/features/auth/domain/models/app_permission.dart';
import 'package:jp_auction_arena/features/auth/domain/models/app_role.dart';
import 'package:jp_auction_arena/features/auth/domain/models/auth_user.dart';
import 'package:jp_auction_arena/features/auth/domain/models/role_permissions.dart';

void main() {
  group('DemoAuthRepository', () {
    test(
      'authenticates demo roles and retains only an in-memory session',
      () async {
        final repository = DemoAuthRepository(
          clock: () => DateTime(2026, 11, 4),
        );
        final cases = [
          ('admin@demo.jp', 'DemoAdmin!2026', AppRole.superAdmin),
          ('operator@demo.jp', 'DemoOperator!2026', AppRole.tournamentAdmin),
          ('team@demo.jp', 'DemoTeam!2026', AppRole.teamManager),
          ('viewer@demo.jp', 'DemoViewer!2026', AppRole.publicViewer),
        ];

        for (final (email, password, role) in cases) {
          final session = await repository.signIn(
            email: email,
            password: password,
            rememberMe: true,
          );
          expect(session.user.role, role);
          expect(session.rememberMe, isTrue);
          expect(await repository.currentSession(), same(session));
        }
      },
    );

    test('rejects invalid credentials and supports logout', () async {
      final repository = DemoAuthRepository();

      await expectLater(
        repository.signIn(
          email: 'admin@demo.jp',
          password: 'wrong-password',
          rememberMe: false,
        ),
        throwsA(isA<InvalidCredentialsException>()),
      );
      expect(await repository.currentSession(), isNull);

      await repository.signIn(
        email: 'admin@demo.jp',
        password: 'DemoAdmin!2026',
        rememberMe: false,
      );
      await repository.signOut();
      expect(await repository.currentSession(), isNull);
    });

    test('does not imply a reset email was sent for demo accounts', () async {
      final repository = DemoAuthRepository();
      await expectLater(
        repository.requestPasswordReset('admin@demo.jp'),
        throwsA(isA<AuthException>()),
      );
    });
  });

  group('RolePermissions', () {
    test('keeps team and public roles read-only', () {
      expect(
        RolePermissions.allows(
          AppRole.teamManager,
          AppPermission.viewAssignedTeam,
        ),
        isTrue,
      );
      expect(
        RolePermissions.allows(
          AppRole.teamManager,
          AppPermission.operateAuction,
        ),
        isFalse,
      );
      expect(
        RolePermissions.allows(
          AppRole.teamManager,
          AppPermission.configureAuction,
        ),
        isFalse,
      );
      expect(
        RolePermissions.allows(
          AppRole.publicViewer,
          AppPermission.viewPublicLive,
        ),
        isTrue,
      );
      expect(
        RolePermissions.allows(
          AppRole.publicViewer,
          AppPermission.viewAssignedTeam,
        ),
        isFalse,
      );
      expect(
        RolePermissions.allows(AppRole.publicViewer, AppPermission.manageUsers),
        isFalse,
      );
    });

    test('scopes tournament and team access to assignments', () {
      expect(
        RolePermissions.canAccessTournament(AppRole.tournamentAdmin, {
          'tourn_001',
        }, 'tourn_001'),
        isTrue,
      );
      expect(
        RolePermissions.canAccessTournament(AppRole.tournamentAdmin, {
          'tourn_001',
        }, 'tourn_002'),
        isFalse,
      );
      expect(
        RolePermissions.canAccessTeam(AppRole.teamManager, {
          'team_001',
        }, 'team_002'),
        isFalse,
      );
      expect(
        RolePermissions.canAccessTeam(AppRole.superAdmin, const {}, 'team_002'),
        isTrue,
      );
    });
  });

  test('auth provider exposes session changes and logout', () async {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(DemoAuthRepository()),
      ],
    );
    addTearDown(container.dispose);

    expect(await container.read(authSessionProvider.future), isNull);
    await container
        .read(authSessionProvider.notifier)
        .signIn(
          email: 'team@demo.jp',
          password: 'DemoTeam!2026',
          rememberMe: false,
        );
    expect(
      container.read(authSessionProvider).value?.user.role,
      AppRole.teamManager,
    );

    await container.read(authSessionProvider.notifier).signOut();
    expect(container.read(authSessionProvider).value, isNull);
  });

  testWidgets('unauthenticated deep links redirect to login', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: JpAuctionArenaApp()));
    await tester.pumpAndSettle();

    final router = GoRouter.of(tester.element(find.byKey(const Key('login'))));
    router.go(RouteNames.settings);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('login')), findsOneWidget);
    expect(find.text('Sign in to your account'), findsOneWidget);
  });

  testWidgets('team manager is confined to assigned-team access', (
    tester,
  ) async {
    final repository = DemoAuthRepository();
    await repository.signIn(
      email: 'team@demo.jp',
      password: 'DemoTeam!2026',
      rememberMe: false,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: const JpAuctionArenaApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Team Mobile View'), findsOneWidget);
    expect(find.text('Your team workspace'), findsOneWidget);

    GoRouter.of(
      tester.element(find.text('Your team workspace')),
    ).go(RouteNames.teams);
    await tester.pumpAndSettle();

    expect(find.text('Access not allowed'), findsOneWidget);
    expect(find.text('Create Team'), findsNothing);
  });

  testWidgets('public viewer can only open public destinations', (
    tester,
  ) async {
    final repository = DemoAuthRepository();
    await repository.signIn(
      email: 'viewer@demo.jp',
      password: 'DemoViewer!2026',
      rememberMe: false,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: const JpAuctionArenaApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Public view'), findsOneWidget);
    GoRouter.of(
      tester.element(find.text('Public view')),
    ).go(RouteNames.dashboard);
    await tester.pumpAndSettle();

    expect(find.text('Access not allowed'), findsOneWidget);
  });

  testWidgets('login validates and reports invalid credentials', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: JpAuctionArenaApp()));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'nobody@demo.jp',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'WrongPassword1!',
    );
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    expect(find.text('Email or password is incorrect.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('login/logout confirmation returns to login', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: JpAuctionArenaApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('Super Admin -'));
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome to JP AUCTION ARENA'), findsOneWidget);

    await tester.tap(find.byTooltip('Log out'));
    await tester.pumpAndSettle();
    expect(find.text('Log out?'), findsOneWidget);
    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();

    expect(find.text('Sign in to your account'), findsOneWidget);
  });

  testWidgets('forgot password clearly reports demo limitation', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: JpAuctionArenaApp()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining(
        'Password reset is not available for local demo accounts.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.textContaining('No reset email was sent.'), findsOneWidget);
  });

  test('role landing routes preserve role-specific entry flow', () {
    expect(
      RouteAccessPolicy.landingFor(AppRole.superAdmin),
      RouteNames.dashboard,
    );
    expect(
      RouteAccessPolicy.landingFor(AppRole.tournamentAdmin),
      RouteNames.dashboard,
    );
    expect(
      RouteAccessPolicy.landingFor(AppRole.teamManager),
      RouteAccessPolicy.teamPortal,
    );
    expect(
      RouteAccessPolicy.landingFor(AppRole.publicViewer),
      RouteAccessPolicy.publicLive,
    );

    const viewer = AuthUser(
      id: 'viewer',
      email: 'viewer@demo.jp',
      displayName: 'Viewer',
      role: AppRole.publicViewer,
    );
    expect(
      RouteAccessPolicy.canAccessPath(viewer, RouteAccessPolicy.publicLive),
      isTrue,
    );
    expect(
      RouteAccessPolicy.canAccessPath(viewer, RouteNames.settings),
      isFalse,
    );
  });
}

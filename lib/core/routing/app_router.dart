import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jp_auction_arena/core/routing/route_names.dart';
import 'package:jp_auction_arena/data/repositories/auth_provider.dart';
import 'package:jp_auction_arena/features/access/access_screen.dart';
import 'package:jp_auction_arena/features/analytics/analytics_screen.dart';
import 'package:jp_auction_arena/features/auctions/auctions_screen.dart';
import 'package:jp_auction_arena/features/create_auction/create_auction_screen.dart';
import 'package:jp_auction_arena/features/dashboard/dashboard_screen.dart';
import 'package:jp_auction_arena/features/live/live_screen.dart';
import 'package:jp_auction_arena/features/login/login_screen.dart';
import 'package:jp_auction_arena/features/players/players_screen.dart';
import 'package:jp_auction_arena/features/projector/projector_screen.dart';
import 'package:jp_auction_arena/features/registration/registration_screen.dart';
import 'package:jp_auction_arena/features/results/results_screen.dart';
import 'package:jp_auction_arena/features/settings/settings_screen.dart';
import 'package:jp_auction_arena/features/splash/splash_screen.dart';
import 'package:jp_auction_arena/features/teams/teams_screen.dart';
import 'package:jp_auction_arena/shared/widgets/not_found_screen.dart';
import 'package:jp_auction_arena/shared/widgets/responsive_scaffold_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: RouteNames.splashPath,
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final isSplash = loc == RouteNames.splashPath;
      final isLogin = loc == RouteNames.loginPath;

      // Allow splash to run freely
      if (isSplash) return null;

      // If not logged in and not on login screen, redirect to login
      if (!authState.isAuthenticated && !isLogin) {
        return RouteNames.loginPath;
      }

      // If logged in and on login screen, redirect to dashboard
      if (authState.isAuthenticated && isLogin) {
        return RouteNames.dashboardPath;
      }

      // Role-based route enforcement
      final role = authState.currentRole;
      if (authState.isAuthenticated) {
        // Viewer can ONLY access results, projector, analytics, and dashboard
        if (role.isReadOnly) {
          final allowedForViewer = [
            RouteNames.dashboardPath,
            RouteNames.resultsPath,
            RouteNames.projectorPath,
            RouteNames.analyticsPath,
          ];
          if (!allowedForViewer.any((p) => loc.startsWith(p))) {
            return RouteNames.resultsPath;
          }
        }

        // Operator can access live auction, projector, results, and dashboard
        if (role.canRunLiveAuction && !role.canManageEverything) {
          final allowedForOperator = [
            RouteNames.dashboardPath,
            RouteNames.livePath,
            RouteNames.projectorPath,
            RouteNames.resultsPath,
            RouteNames.teamsPath,
            RouteNames.playersPath,
            RouteNames.analyticsPath,
          ];
          if (!allowedForOperator.any((p) => loc.startsWith(p))) {
            return RouteNames.livePath;
          }
        }
      }

      return null;
    },
    routes: [
      // 1. Splash Screen (Full Screen outside Shell)
      GoRoute(
        path: RouteNames.splashPath,
        name: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),

      // 2. Login & Profile Creation Screen (Full Screen outside Shell)
      GoRoute(
        path: RouteNames.loginPath,
        name: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),

      // 3. Shell Route for Main App Scaffolding
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return ResponsiveScaffoldShell(
            state: state,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/',
            redirect: (_, __) => RouteNames.dashboardPath,
          ),
          GoRoute(
            path: RouteNames.dashboardPath,
            name: RouteNames.dashboard,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DashboardScreen(),
            ),
          ),
          GoRoute(
            path: RouteNames.auctionsPath,
            name: RouteNames.auctions,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AuctionsScreen(),
            ),
          ),
          GoRoute(
            path: RouteNames.createAuctionPath,
            name: RouteNames.createAuction,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: CreateAuctionScreen(),
            ),
          ),
          GoRoute(
            path: RouteNames.teamsPath,
            name: RouteNames.teams,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: TeamsScreen(),
            ),
          ),
          GoRoute(
            path: RouteNames.playersPath,
            name: RouteNames.players,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: PlayersScreen(),
            ),
          ),
          GoRoute(
            path: RouteNames.livePath,
            name: RouteNames.live,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: LiveScreen(),
            ),
          ),
          GoRoute(
            path: RouteNames.projectorPath,
            name: RouteNames.projector,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProjectorScreen(),
            ),
          ),
          GoRoute(
            path: RouteNames.resultsPath,
            name: RouteNames.results,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ResultsScreen(),
            ),
          ),
          GoRoute(
            path: RouteNames.registrationPath,
            name: RouteNames.registration,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: RegistrationScreen(),
            ),
          ),
          GoRoute(
            path: RouteNames.accessPath,
            name: RouteNames.access,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AccessScreen(),
            ),
          ),
          GoRoute(
            path: RouteNames.analyticsPath,
            name: RouteNames.analytics,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AnalyticsScreen(),
            ),
          ),
          GoRoute(
            path: RouteNames.settingsPath,
            name: RouteNames.settings,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsScreen(),
            ),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => const NotFoundScreen(),
  );
});

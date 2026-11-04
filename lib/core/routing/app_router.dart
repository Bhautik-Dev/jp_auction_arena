import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jp_auction_arena/core/routing/route_names.dart';
import 'package:jp_auction_arena/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:jp_auction_arena/features/settings/presentation/screens/settings_screen.dart';
import 'package:jp_auction_arena/shared/widgets/coming_soon_screen.dart';
import 'package:jp_auction_arena/shared/widgets/not_found_screen.dart';
import 'package:jp_auction_arena/shared/widgets/responsive_app_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: RouteNames.dashboard,
    routes: [
      GoRoute(path: '/', redirect: (context, state) => RouteNames.dashboard),
      ShellRoute(
        builder: (context, state, child) => ResponsiveAppShell(child: child),
        routes: [
          GoRoute(
            path: RouteNames.dashboard,
            name: 'dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: RouteNames.tournaments,
            name: 'tournaments',
            builder: (context, state) =>
                const ComingSoonScreen(title: 'Tournament Management'),
          ),
          GoRoute(
            path: RouteNames.teams,
            name: 'teams',
            builder: (context, state) => const ComingSoonScreen(title: 'Teams'),
          ),
          GoRoute(
            path: RouteNames.players,
            name: 'players',
            builder: (context, state) =>
                const ComingSoonScreen(title: 'Players'),
          ),
          GoRoute(
            path: RouteNames.auctionSetup,
            name: 'auction-setup',
            builder: (context, state) =>
                const ComingSoonScreen(title: 'Auction Setup'),
          ),
          GoRoute(
            path: RouteNames.liveAuction,
            name: 'live-auction',
            builder: (context, state) =>
                const ComingSoonScreen(title: 'Live Auction'),
          ),
          GoRoute(
            path: RouteNames.results,
            name: 'results',
            builder: (context, state) =>
                const ComingSoonScreen(title: 'Auction Results'),
          ),
          GoRoute(
            path: RouteNames.reports,
            name: 'reports',
            builder: (context, state) =>
                const ComingSoonScreen(title: 'Reports and Statistics'),
          ),
          GoRoute(
            path: RouteNames.history,
            name: 'history',
            builder: (context, state) =>
                const ComingSoonScreen(title: 'Tournament History'),
          ),
          GoRoute(
            path: RouteNames.settings,
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) =>
        NotFoundScreen(location: state.uri.toString()),
  );
  ref.onDispose(router.dispose);
  return router;
});

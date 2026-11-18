import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jp_auction_arena/core/routing/route_names.dart';
import 'package:jp_auction_arena/features/auctions/auctions_screen.dart';
import 'package:jp_auction_arena/features/create_auction/create_auction_screen.dart';
import 'package:jp_auction_arena/features/operators/operators_screen.dart';
import 'package:jp_auction_arena/features/players/players_screen.dart';
import 'package:jp_auction_arena/features/projector/projector_screen.dart';
import 'package:jp_auction_arena/features/results/results_screen.dart';
import 'package:jp_auction_arena/features/settings/settings_screen.dart';
import 'package:jp_auction_arena/features/teams/teams_screen.dart';
import 'package:jp_auction_arena/shared/widgets/not_found_screen.dart';
import 'package:jp_auction_arena/shared/widgets/responsive_scaffold_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: RouteNames.auctionsPath,
    debugLogDiagnostics: false,
    routes: [
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
            redirect: (_, __) => RouteNames.auctionsPath,
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
            path: RouteNames.resultsPath,
            name: RouteNames.results,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ResultsScreen(),
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
            path: RouteNames.settingsPath,
            name: RouteNames.settings,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsScreen(),
            ),
          ),
          GoRoute(
            path: RouteNames.operatorsPath,
            name: RouteNames.operators,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: OperatorsScreen(),
            ),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => const NotFoundScreen(),
  );
});

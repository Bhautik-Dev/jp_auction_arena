import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jp_auction_arena/features/auth/application/auth_providers.dart';
import 'package:jp_auction_arena/features/auth/application/route_access_policy.dart';
import 'package:jp_auction_arena/features/auth/presentation/screens/auth_loading_screen.dart';
import 'package:jp_auction_arena/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:jp_auction_arena/features/auth/presentation/screens/login_screen.dart';
import 'package:jp_auction_arena/features/auth/presentation/screens/public_live_screen.dart';
import 'package:jp_auction_arena/features/auth/presentation/screens/team_portal_screen.dart';
import 'package:jp_auction_arena/features/auth/presentation/screens/unauthorized_screen.dart';
import 'package:jp_auction_arena/core/routing/route_names.dart';
import 'package:jp_auction_arena/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:jp_auction_arena/features/auction/presentation/screens/auction_detail_screen.dart';
import 'package:jp_auction_arena/features/auction/presentation/screens/auction_form_screen.dart';
import 'package:jp_auction_arena/features/auction/presentation/screens/auction_list_screen.dart';
import 'package:jp_auction_arena/features/auction/presentation/screens/auction_settings_screen.dart';
import 'package:jp_auction_arena/features/auction/presentation/screens/auction_preparation_screen.dart';
import 'package:jp_auction_arena/features/player/presentation/screens/player_detail_screen.dart';
import 'package:jp_auction_arena/features/player/presentation/screens/player_form_screen.dart';
import 'package:jp_auction_arena/features/player/presentation/screens/player_list_screen.dart';
import 'package:jp_auction_arena/features/settings/presentation/screens/settings_screen.dart';
import 'package:jp_auction_arena/features/team/presentation/screens/team_list_screen.dart';
import 'package:jp_auction_arena/features/team/presentation/screens/team_detail_screen.dart';
import 'package:jp_auction_arena/features/team/presentation/screens/team_form_screen.dart';
import 'package:jp_auction_arena/shared/widgets/coming_soon_screen.dart';
import 'package:jp_auction_arena/shared/widgets/not_found_screen.dart';
import 'package:jp_auction_arena/shared/widgets/responsive_app_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _RouterRefreshNotifier();
  ref.listen(authSessionProvider, (previous, next) {
    refreshNotifier.refresh();
  });
  ref.onDispose(refreshNotifier.dispose);

  final router = GoRouter(
    initialLocation: RouteNames.splash,
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final path = state.uri.path;
      final authState = ref.read(authSessionProvider);

      if (authState.isLoading) {
        return path == RouteNames.splash ? null : RouteNames.splash;
      }

      final session = authState.whenOrNull(data: (value) => value);
      if (path == RouteNames.splash) {
        return session == null
            ? RouteNames.login
            : RouteAccessPolicy.landingFor(session.user.role);
      }

      final isPublicRoute = path.startsWith('/live/');
      if (session == null) {
        if (path == RouteNames.login ||
            path == RouteNames.forgotPassword ||
            path == RouteNames.unauthorized ||
            isPublicRoute) {
          return null;
        }
        return RouteNames.login;
      }

      if (path == RouteNames.login || path == RouteNames.forgotPassword) {
        return RouteAccessPolicy.landingFor(session.user.role);
      }

      if (path == RouteNames.tournaments ||
          path.startsWith('${RouteNames.tournaments}/')) {
        return RouteNames.auctions;
      }

      if (!_isOpenRoute(path) &&
          !RouteAccessPolicy.canAccessPath(session.user, path)) {
        return RouteNames.unauthorized;
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', redirect: (context, state) => RouteNames.splash),
      GoRoute(
        path: RouteNames.splash,
        builder: (context, state) => const AuthLoadingScreen(),
      ),
      GoRoute(
        path: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteNames.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: RouteNames.unauthorized,
        builder: (context, state) => const UnauthorizedScreen(),
      ),
      GoRoute(
        path: RouteNames.publicLive,
        builder: (context, state) => const PublicLiveScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => ResponsiveAppShell(child: child),
        routes: [
          GoRoute(
            path: RouteNames.dashboard,
            name: 'dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: RouteNames.teamPortal,
            name: 'team-portal',
            builder: (context, state) => const TeamPortalScreen(),
          ),
          GoRoute(
            path: RouteNames.auctions,
            name: 'auctions',
            builder: (context, state) => const AuctionListScreen(),
            routes: [
              GoRoute(
                path: 'create',
                name: 'auction-create',
                builder: (context, state) => const AuctionFormScreen(),
              ),
              GoRoute(
                path: ':auctionId',
                name: 'auction-detail',
                builder: (context, state) => AuctionDetailScreen(
                  auctionId: state.pathParameters['auctionId']!,
                ),
                routes: [
                  GoRoute(
                    path: 'edit',
                    name: 'auction-edit',
                    builder: (context, state) => AuctionFormScreen(
                      auctionId: state.pathParameters['auctionId']!,
                    ),
                  ),
                  GoRoute(
                    path: 'settings',
                    name: 'auction-settings',
                    builder: (context, state) => AuctionSettingsScreen(
                      auctionId: state.pathParameters['auctionId']!,
                    ),
                  ),
                  GoRoute(
                    path: 'preparation',
                    name: 'auction-preparation',
                    builder: (context, state) => AuctionPreparationScreen(
                      auctionId: state.pathParameters['auctionId']!,
                    ),
                  ),
                  GoRoute(
                    path: 'teams',
                    name: 'auction-teams',
                    builder: (context, state) => TeamListScreen(
                      auctionId: state.pathParameters['auctionId']!,
                    ),
                    routes: [
                      GoRoute(
                        path: 'create',
                        name: 'auction-team-create',
                        builder: (context, state) => TeamFormScreen(
                          auctionId: state.pathParameters['auctionId']!,
                        ),
                      ),
                      GoRoute(
                        path: ':teamId',
                        name: 'auction-team-detail',
                        builder: (context, state) => TeamDetailScreen(
                          auctionId: state.pathParameters['auctionId']!,
                          teamId: state.pathParameters['teamId']!,
                        ),
                        routes: [
                          GoRoute(
                            path: 'edit',
                            name: 'auction-team-edit',
                            builder: (context, state) => TeamFormScreen(
                              auctionId: state.pathParameters['auctionId']!,
                              teamId: state.pathParameters['teamId']!,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'players',
                    name: 'auction-players',
                    builder: (context, state) => PlayerListScreen(
                      auctionId: state.pathParameters['auctionId']!,
                    ),
                    routes: [
                      GoRoute(
                        path: 'create',
                        name: 'auction-player-create',
                        builder: (context, state) => PlayerFormScreen(
                          auctionId: state.pathParameters['auctionId']!,
                        ),
                      ),
                      GoRoute(
                        path: ':playerId',
                        name: 'auction-player-detail',
                        builder: (context, state) => PlayerDetailScreen(
                          auctionId: state.pathParameters['auctionId']!,
                          playerId: state.pathParameters['playerId']!,
                        ),
                        routes: [
                          GoRoute(
                            path: 'edit',
                            name: 'auction-player-edit',
                            builder: (context, state) => PlayerFormScreen(
                              auctionId: state.pathParameters['auctionId']!,
                              playerId: state.pathParameters['playerId']!,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: RouteNames.teams,
            name: 'teams',
            builder: (context, state) => const TeamListScreen(),
          ),
          GoRoute(
            path: RouteNames.players,
            name: 'players',
            builder: (context, state) => const PlayerListScreen(),
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
                const AuctionListScreen(historyOnly: true),
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

bool _isOpenRoute(String path) => path == RouteNames.unauthorized;

class _RouterRefreshNotifier extends ChangeNotifier {
  void refresh() => notifyListeners();
}

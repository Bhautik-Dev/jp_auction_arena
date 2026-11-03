import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jp_auction_arena/core/router/route_names.dart';
import 'package:jp_auction_arena/features/home/presentation/screens/home_screen.dart';
import 'package:jp_auction_arena/features/tournament/presentation/screens/tournament_detail_screen.dart';
import 'package:jp_auction_arena/features/tournament/presentation/screens/tournament_form_screen.dart';
import 'package:jp_auction_arena/features/tournament/presentation/screens/tournament_list_screen.dart';

/// Riverpod provider for GoRouter configuration.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: RouteNames.homePath,
    debugLogDiagnostics: kDebugMode,
    routes: [
      GoRoute(
        path: RouteNames.homePath,
        name: RouteNames.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: RouteNames.tournamentsPath,
        name: RouteNames.tournaments,
        builder: (context, state) => const TournamentListScreen(),
        routes: [
          GoRoute(
            path: 'create',
            name: RouteNames.createTournament,
            builder: (context, state) => const TournamentFormScreen(),
          ),
          GoRoute(
            path: ':id',
            name: RouteNames.tournamentDetail,
            builder: (context, state) {
              final id = state.pathParameters['id'] ?? '';
              return TournamentDetailScreen(tournamentId: id);
            },
            routes: [
              GoRoute(
                path: 'edit',
                name: RouteNames.editTournament,
                builder: (context, state) {
                  final id = state.pathParameters['id'] ?? '';
                  return TournamentFormScreen(tournamentId: id);
                },
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/index.html',
        redirect: (context, state) => RouteNames.homePath,
      ),
    ],
    // Smoothly route any unmatched or fallback routes directly to the Home Screen
    errorBuilder: (context, state) => const HomeScreen(),
  );
});

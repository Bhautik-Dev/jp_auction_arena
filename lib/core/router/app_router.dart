import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jp_auction_arena/core/router/route_names.dart';
import 'package:jp_auction_arena/features/home/presentation/screens/home_screen.dart';

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
        path: '/index.html',
        redirect: (context, state) => RouteNames.homePath,
      ),
    ],
    // Smoothly route any unmatched or fallback routes directly to the Home Screen
    errorBuilder: (context, state) => const HomeScreen(),
  );
});

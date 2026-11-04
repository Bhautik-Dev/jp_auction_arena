import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jp_auction_arena/features/auth/application/auth_providers.dart';
import 'package:jp_auction_arena/features/dashboard/data/repositories/demo_dashboard_repository.dart';
import 'package:jp_auction_arena/features/dashboard/domain/models/dashboard_snapshot.dart';
import 'package:jp_auction_arena/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:jp_auction_arena/features/player/presentation/providers/player_providers.dart';
import 'package:jp_auction_arena/features/team/presentation/providers/team_providers.dart';
import 'package:jp_auction_arena/features/tournament/presentation/providers/tournament_providers.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => DemoDashboardRepository(
    tournamentRepository: ref.watch(tournamentRepositoryProvider),
    teamRepository: ref.watch(teamRepositoryProvider),
    playerRepository: ref.watch(playerRepositoryProvider),
  ),
);

final dashboardSnapshotProvider = FutureProvider<DashboardSnapshot>((
  ref,
) async {
  final authState = ref.watch(authSessionProvider);
  final session = authState.when(
    data: (value) => value,
    error: (error, stackTrace) => Error.throwWithStackTrace(error, stackTrace),
    loading: () => throw StateError('Dashboard requested before session load.'),
  );
  if (session == null) {
    throw StateError('Dashboard requires an authenticated session.');
  }
  return ref.watch(dashboardRepositoryProvider).loadForUser(session.user);
});

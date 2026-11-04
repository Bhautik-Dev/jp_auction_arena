import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jp_auction_arena/features/team/data/repositories/in_memory_team_repository.dart';
import 'package:jp_auction_arena/features/team/domain/models/team.dart';
import 'package:jp_auction_arena/features/team/domain/repositories/team_repository.dart';
import 'package:jp_auction_arena/features/team/domain/services/team_management_service.dart';
import 'package:jp_auction_arena/features/auth/application/auth_providers.dart';
import 'package:jp_auction_arena/features/auction/presentation/providers/auction_providers.dart';

final teamRepositoryProvider = Provider<TeamRepository>(
  (ref) => InMemoryTeamRepository(
    auctionRepository: ref.watch(auctionRepositoryProvider),
    initialTeams: demoTeams,
  ),
);

final teamManagementServiceProvider = Provider<TeamManagementService>(
  (ref) => TeamManagementService(
    teamRepository: ref.watch(teamRepositoryProvider),
    auctionRepository: ref.watch(auctionRepositoryProvider),
  ),
);

final teamsForAuctionProvider = FutureProvider.family<List<Team>, String>((
  ref,
  auctionId,
) async {
  final session = await ref.watch(authSessionProvider.future);
  if (session == null) throw StateError('Team management requires a session.');
  return ref.watch(teamManagementServiceProvider).list(session.user, auctionId);
});

final teamByIdProvider =
    FutureProvider.family<Team, ({String auctionId, String teamId})>((
      ref,
      params,
    ) async {
      final session = await ref.watch(authSessionProvider.future);
      if (session == null) {
        throw StateError('Team details require a session.');
      }
      return ref
          .watch(teamManagementServiceProvider)
          .getById(session.user, params.auctionId, params.teamId);
    });

final teamForEditProvider =
    FutureProvider.family<Team, ({String auctionId, String teamId})>((
      ref,
      params,
    ) async {
      final session = await ref.watch(authSessionProvider.future);
      if (session == null) {
        throw StateError('Team editing requires a session.');
      }
      return ref
          .watch(teamManagementServiceProvider)
          .getById(session.user, params.auctionId, params.teamId);
    });

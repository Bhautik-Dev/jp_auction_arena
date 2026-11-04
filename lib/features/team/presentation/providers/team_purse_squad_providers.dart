import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jp_auction_arena/features/auction/presentation/providers/auction_providers.dart';
import 'package:jp_auction_arena/features/auth/application/auth_providers.dart';
import 'package:jp_auction_arena/features/player/presentation/providers/player_providers.dart';
import 'package:jp_auction_arena/features/team/data/repositories/in_memory_team_purse_repository.dart';
import 'package:jp_auction_arena/features/team/domain/models/team_squad_snapshot.dart';
import 'package:jp_auction_arena/features/team/domain/repositories/team_purse_repository.dart';
import 'package:jp_auction_arena/features/team/domain/services/team_purse_squad_service.dart';
import 'package:jp_auction_arena/features/team/presentation/providers/team_providers.dart';

final teamPurseRepositoryProvider = Provider<TeamPurseRepository>(
  (ref) => InMemoryTeamPurseRepository(),
);

final teamPurseSquadServiceProvider = Provider<TeamPurseSquadService>(
  (ref) => TeamPurseSquadService(
    purseRepository: ref.watch(teamPurseRepositoryProvider),
    teamRepository: ref.watch(teamRepositoryProvider),
    playerRepository: ref.watch(playerRepositoryProvider),
    auctionRepository: ref.watch(auctionRepositoryProvider),
    ruleRepository: ref.watch(auctionRuleSetRepositoryProvider),
  ),
);

final teamPurseSquadProvider =
    FutureProvider.family<
      TeamSquadSnapshot,
      ({String auctionId, String teamId})
    >((ref, params) async {
      final session = await ref.watch(authSessionProvider.future);
      if (session == null) {
        throw StateError(
          'Team purse and squad information requires a session.',
        );
      }
      return ref
          .watch(teamPurseSquadServiceProvider)
          .getSnapshot(
            session.user,
            auctionId: params.auctionId,
            teamId: params.teamId,
          );
    });

final assignedTeamPurseSquadsProvider = FutureProvider<List<TeamSquadSnapshot>>(
  (ref) async {
    final session = await ref.watch(authSessionProvider.future);
    if (session == null) {
      throw StateError('Assigned team information requires a session.');
    }
    return ref
        .watch(teamPurseSquadServiceProvider)
        .getAssignedSnapshots(session.user);
  },
);

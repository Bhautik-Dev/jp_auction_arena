import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jp_auction_arena/features/player/data/repositories/in_memory_player_repository.dart';
import 'package:jp_auction_arena/features/player/domain/models/player.dart';
import 'package:jp_auction_arena/features/player/domain/models/player_category.dart';
import 'package:jp_auction_arena/features/player/domain/models/player_status.dart';
import 'package:jp_auction_arena/features/player/domain/repositories/player_repository.dart';
import 'package:jp_auction_arena/features/player/domain/services/player_management_service.dart';
import 'package:jp_auction_arena/features/team/presentation/providers/team_providers.dart';
import 'package:jp_auction_arena/features/auction/presentation/providers/auction_providers.dart';
import 'package:jp_auction_arena/features/auth/application/auth_providers.dart';

final playerRepositoryProvider = Provider<PlayerRepository>(
  (ref) => InMemoryPlayerRepository(
    teamRepository: ref.watch(teamRepositoryProvider),
    auctionRepository: ref.watch(auctionRepositoryProvider),
    initialPlayers: demoPlayers,
  ),
);

final playerManagementServiceProvider = Provider<PlayerManagementService>(
  (ref) => PlayerManagementService(
    playerRepository: ref.watch(playerRepositoryProvider),
    auctionRepository: ref.watch(auctionRepositoryProvider),
  ),
);

typedef AuctionPlayerFilter = ({
  String auctionId,
  String query,
  PlayerCategory? category,
  PlayerStatus? status,
});

final playersForAuctionProvider =
    FutureProvider.family<List<Player>, AuctionPlayerFilter>((
      ref,
      filter,
    ) async {
      final session = await ref.watch(authSessionProvider.future);
      if (session == null) {
        throw StateError('Player management requires a session.');
      }
      return ref
          .watch(playerManagementServiceProvider)
          .list(
            session.user,
            filter.auctionId,
            query: filter.query,
            category: filter.category,
            status: filter.status,
          );
    });

final playerForAuctionProvider =
    FutureProvider.family<Player, ({String auctionId, String playerId})>((
      ref,
      params,
    ) async {
      final session = await ref.watch(authSessionProvider.future);
      if (session == null) {
        throw StateError('Player details require a session.');
      }
      return ref
          .watch(playerManagementServiceProvider)
          .getById(session.user, params.auctionId, params.playerId);
    });

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jp_auction_arena/features/auction/data/repositories/in_memory_auction_player_queue_repository.dart';
import 'package:jp_auction_arena/features/auction/domain/models/auction_preparation_snapshot.dart';
import 'package:jp_auction_arena/features/auction/domain/repositories/auction_player_queue_repository.dart';
import 'package:jp_auction_arena/features/auction/domain/services/auction_preparation_service.dart';
import 'package:jp_auction_arena/features/auction/presentation/providers/auction_providers.dart';
import 'package:jp_auction_arena/features/auth/application/auth_providers.dart';
import 'package:jp_auction_arena/features/player/presentation/providers/player_providers.dart';
import 'package:jp_auction_arena/features/team/presentation/providers/team_providers.dart';

final auctionPlayerQueueRepositoryProvider =
    Provider<AuctionPlayerQueueRepository>(
      (ref) => InMemoryAuctionPlayerQueueRepository(),
    );

final auctionPreparationServiceProvider = Provider<AuctionPreparationService>(
  (ref) => AuctionPreparationService(
    auctionRepository: ref.watch(auctionRepositoryProvider),
    ruleRepository: ref.watch(auctionRuleSetRepositoryProvider),
    queueRepository: ref.watch(auctionPlayerQueueRepositoryProvider),
    playerRepository: ref.watch(playerRepositoryProvider),
    teamRepository: ref.watch(teamRepositoryProvider),
  ),
);

final auctionPreparationProvider =
    FutureProvider.family<AuctionPreparationSnapshot, String>((
      ref,
      auctionId,
    ) async {
      final session = await ref.watch(authSessionProvider.future);
      if (session == null) {
        throw StateError('Auction preparation requires a session.');
      }
      return ref
          .watch(auctionPreparationServiceProvider)
          .getPreparation(session.user, auctionId);
    });

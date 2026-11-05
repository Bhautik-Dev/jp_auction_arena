import 'package:jp_auction_arena/features/auction/domain/models/auction_player_queue.dart';

abstract interface class AuctionPlayerQueueRepository {
  Future<AuctionPlayerQueue> getQueue(String auctionId);

  Future<AuctionPlayerQueue> saveQueue(AuctionPlayerQueue queue);

  Future<AuctionPlayerQueue> updateQueue(
    String auctionId,
    List<String> Function(List<String> currentPlayerIds) update,
    DateTime updatedAt,
  );
}

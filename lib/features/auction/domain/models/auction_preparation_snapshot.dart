import 'package:jp_auction_arena/features/auction/domain/models/auction.dart';
import 'package:jp_auction_arena/features/auction/domain/models/auction_readiness_item.dart';
import 'package:jp_auction_arena/features/auction/domain/models/player_order_mode.dart';
import 'package:jp_auction_arena/features/player/domain/models/player.dart';

class AuctionPreparationSnapshot {
  const AuctionPreparationSnapshot({
    required this.auction,
    required this.registeredPlayers,
    required this.queuedPlayers,
    required this.queuedPlayerIds,
    required this.playerOrderMode,
    required this.ineligibleReasons,
    required this.readinessItems,
  });

  final Auction auction;
  final List<Player> registeredPlayers;
  final List<Player> queuedPlayers;
  final List<String> queuedPlayerIds;
  final PlayerOrderMode playerOrderMode;
  final Map<String, String> ineligibleReasons;
  final List<AuctionReadinessItem> readinessItems;

  bool get isReady => readinessItems
      .where((item) => item.isBlocking)
      .every((item) => item.isComplete);
}

import 'package:jp_auction_arena/features/auction/domain/models/bid_increment_tier.dart';

class AuctionRuleSet {
  const AuctionRuleSet({
    required this.auctionId,
    required this.bidIncrementTiers,
    required this.allowUnsoldPlayerReentry,
  });

  final String auctionId;
  final List<BidIncrementTier> bidIncrementTiers;
  final bool allowUnsoldPlayerReentry;

  AuctionRuleSet copyWith({
    String? auctionId,
    List<BidIncrementTier>? bidIncrementTiers,
    bool? allowUnsoldPlayerReentry,
  }) => AuctionRuleSet(
    auctionId: auctionId ?? this.auctionId,
    bidIncrementTiers: bidIncrementTiers ?? this.bidIncrementTiers,
    allowUnsoldPlayerReentry:
        allowUnsoldPlayerReentry ?? this.allowUnsoldPlayerReentry,
  );
}

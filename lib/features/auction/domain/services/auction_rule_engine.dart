import 'package:jp_auction_arena/features/auction/domain/errors/auction_exceptions.dart';
import 'package:jp_auction_arena/features/auction/domain/models/auction_rule_set.dart';
import 'package:jp_auction_arena/features/auction/domain/models/bid_increment_tier.dart';

class AuctionRuleEngine {
  const AuctionRuleEngine();

  static const defaultRules = [
    BidIncrementTier(minimumBid: 0, increment: 1000),
  ];

  void validate(AuctionRuleSet rules) {
    if (rules.auctionId.trim().isEmpty) {
      throw const AuctionValidationException('An auction is required.');
    }
    if (rules.bidIncrementTiers.isEmpty) {
      throw const AuctionValidationException(
        'At least one bid increment tier is required.',
      );
    }
    if (rules.bidIncrementTiers.first.minimumBid != 0) {
      throw const AuctionValidationException(
        'The first bid increment tier must start at zero.',
      );
    }
    var previousMinimum = -1;
    for (final tier in rules.bidIncrementTiers) {
      if (tier.minimumBid < 0 ||
          tier.minimumBid <= previousMinimum ||
          tier.increment <= 0) {
        throw const AuctionValidationException(
          'Bid thresholds must increase and all increments must be positive.',
        );
      }
      previousMinimum = tier.minimumBid;
    }
  }

  int incrementFor(AuctionRuleSet rules, int currentBid) {
    if (currentBid < 0) {
      throw const AuctionValidationException(
        'Current bid cannot be negative.',
      );
    }
    validate(rules);
    var increment = rules.bidIncrementTiers.first.increment;
    for (final tier in rules.bidIncrementTiers.skip(1)) {
      if (currentBid < tier.minimumBid) break;
      increment = tier.increment;
    }
    return increment;
  }

  int nextBid(AuctionRuleSet rules, int currentBid) {
    final increment = incrementFor(rules, currentBid);
    final nextBid = currentBid + increment;
    if (nextBid <= currentBid) {
      throw const AuctionValidationException(
        'The next bid exceeds the supported price range.',
      );
    }
    return nextBid;
  }
}

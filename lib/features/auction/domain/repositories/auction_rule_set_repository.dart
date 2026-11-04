import 'package:jp_auction_arena/features/auction/domain/models/auction_rule_set.dart';

abstract interface class AuctionRuleSetRepository {
  Future<AuctionRuleSet?> getByAuctionId(String auctionId);

  Future<AuctionRuleSet> save(AuctionRuleSet rules);
}

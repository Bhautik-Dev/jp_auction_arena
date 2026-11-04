import 'package:jp_auction_arena/features/auction/domain/errors/auction_exceptions.dart';
import 'package:jp_auction_arena/features/auction/domain/models/auction_rule_set.dart';
import 'package:jp_auction_arena/features/auction/domain/repositories/auction_rule_set_repository.dart';
import 'package:jp_auction_arena/features/auction/domain/repositories/auction_repository.dart';

class InMemoryAuctionRuleSetRepository implements AuctionRuleSetRepository {
  InMemoryAuctionRuleSetRepository({
    required AuctionRepository auctionRepository,
    Map<String, AuctionRuleSet>? initialRules,
  }) : _auctionRepository = auctionRepository,
       _rules = Map.of(initialRules ?? const {});

  final AuctionRepository _auctionRepository;
  final Map<String, AuctionRuleSet> _rules;

  @override
  Future<AuctionRuleSet?> getByAuctionId(String auctionId) async =>
      _rules[auctionId];

  @override
  Future<AuctionRuleSet> save(AuctionRuleSet rules) async {
    if (await _auctionRepository.getAuctionById(rules.auctionId) == null) {
      throw AuctionValidationException(
        'Auction ${rules.auctionId} was not found.',
      );
    }
    _rules[rules.auctionId] = rules;
    return rules;
  }
}

import 'package:jp_auction_arena/features/auction/domain/errors/auction_exceptions.dart';
import 'package:jp_auction_arena/features/auction/domain/models/auction.dart';
import 'package:jp_auction_arena/features/auction/domain/models/auction_rule_set.dart';
import 'package:jp_auction_arena/features/auction/domain/models/auction_status.dart';
import 'package:jp_auction_arena/features/auction/domain/repositories/auction_repository.dart';
import 'package:jp_auction_arena/features/auction/domain/repositories/auction_rule_set_repository.dart';
import 'package:jp_auction_arena/features/auction/domain/services/auction_rule_engine.dart';
import 'package:jp_auction_arena/features/auth/domain/models/app_role.dart';
import 'package:jp_auction_arena/features/auth/domain/models/auth_user.dart';

class AuctionRuleManagementService {
  const AuctionRuleManagementService({
    required AuctionRuleSetRepository repository,
    required AuctionRepository auctionRepository,
    AuctionRuleEngine engine = const AuctionRuleEngine(),
  }) : _repository = repository,
       _auctionRepository = auctionRepository,
       _engine = engine;

  final AuctionRuleSetRepository _repository;
  final AuctionRepository _auctionRepository;
  final AuctionRuleEngine _engine;

  Future<AuctionRuleSet> getRules(AuthUser actor, String auctionId) async {
    final auction = await _authorize(actor, auctionId, requireEditable: false);
    final rules =
        await _repository.getByAuctionId(auctionId) ??
        AuctionRuleSet(
          auctionId: auctionId,
          bidIncrementTiers: AuctionRuleEngine.defaultRules,
          allowUnsoldPlayerReentry: false,
        );
    _engine.validate(rules, auction: auction);
    return rules;
  }

  Future<AuctionRuleSet> saveRules(AuthUser actor, AuctionRuleSet rules) async {
    final auction = await _authorize(
      actor,
      rules.auctionId,
      requireEditable: true,
    );
    _engine.validate(rules, auction: auction);
    return _repository.save(rules);
  }

  Future<Auction> _authorize(
    AuthUser actor,
    String auctionId, {
    required bool requireEditable,
  }) async {
    if (actor.role != AppRole.superAdmin &&
        actor.role != AppRole.tournamentAdmin) {
      throw const AuctionAuthorizationException(
        'Only admins and auction operators can manage auction rules.',
      );
    }
    if (actor.role == AppRole.tournamentAdmin &&
        !actor.auctionIds.contains(auctionId)) {
      throw const AuctionAuthorizationException(
        'You are not assigned to manage this auction.',
      );
    }
    final auction = await _auctionRepository.getAuctionById(auctionId);
    if (auction == null) {
      throw AuctionValidationException('Auction $auctionId was not found.');
    }
    if (requireEditable &&
        auction.status != AuctionStatus.draft &&
        auction.status != AuctionStatus.ready) {
      throw const AuctionTransitionException(
        'Auction rules are read-only after the auction becomes Live.',
      );
    }
    return auction;
  }
}

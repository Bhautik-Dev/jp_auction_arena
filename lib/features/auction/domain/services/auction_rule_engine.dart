import 'package:jp_auction_arena/features/auction/domain/models/auction.dart';
import 'package:jp_auction_arena/features/auction/domain/models/bid_increment_mode.dart';
import 'package:jp_auction_arena/features/auction/domain/errors/auction_exceptions.dart';
import 'package:jp_auction_arena/features/auction/domain/models/auction_rule_set.dart';
import 'package:jp_auction_arena/features/auction/domain/models/bid_increment_tier.dart';
import 'package:jp_auction_arena/features/player/domain/models/player_category.dart';

class AuctionRuleEngine {
  const AuctionRuleEngine();

  static const _maximumSafeInteger = 9007199254740991;
  static const _categories = PlayerCategory.values;

  static const defaultRules = [
    BidIncrementTier(minimumBid: 0, increment: 1000),
  ];

  void validate(AuctionRuleSet rules, {Auction? auction}) {
    if (rules.auctionId.trim().isEmpty) {
      throw const AuctionValidationException('An auction is required.');
    }
    if (rules.fixedBidIncrement <= 0) {
      throw const AuctionValidationException(
        'Configured fixed bid increment must be greater than zero.',
      );
    }
    if (rules.bidIncrementMode == BidIncrementMode.tiered &&
        rules.bidIncrementTiers.isEmpty) {
      throw const AuctionValidationException(
        'At least one bid increment tier is required.',
      );
    }
    if (rules.bidIncrementMode == BidIncrementMode.tiered &&
        rules.bidIncrementTiers.first.minimumBid != 0) {
      throw const AuctionValidationException(
        'The first bid increment tier must start at zero.',
      );
    }
    var previousMinimum = -1;
    if (rules.bidIncrementMode == BidIncrementMode.tiered) {
      for (var index = 0; index < rules.bidIncrementTiers.length; index++) {
        final tier = rules.bidIncrementTiers[index];
        if (tier.minimumBid < 0 ||
            tier.minimumBid <= previousMinimum ||
            tier.increment <= 0 ||
            (tier.maximumBid != null && tier.maximumBid! < tier.minimumBid)) {
          throw const AuctionValidationException(
            'Bid tiers must have valid increasing ranges and positive increments.',
          );
        }
        if (index > 0) {
          final previousTier = rules.bidIncrementTiers[index - 1];
          if (previousTier.maximumBid != null &&
              tier.minimumBid <= previousTier.maximumBid!) {
            throw const AuctionValidationException(
              'Bid increment tiers cannot overlap.',
            );
          }
        }
        previousMinimum = tier.minimumBid;
      }
    }
    _validatePrices(rules, auction);
    _validateSquadRules(rules, auction);
    _validateTimer(rules);
    if (rules.maximumUnsoldReentries != null &&
        (rules.maximumUnsoldReentries! < 1 ||
            rules.maximumUnsoldReentries! > 10)) {
      throw const AuctionValidationException(
        'Maximum unsold re-entries must be from 1 to 10.',
      );
    }
    if (auction != null) {
      if (auction.id != rules.auctionId) {
        throw const AuctionValidationException(
          'Auction rules must belong to the selected auction.',
        );
      }
      if (!auction.totalPursePerTeam.isFinite ||
          auction.totalPursePerTeam <= 0) {
        throw const AuctionValidationException(
          'Team purse must be valid and greater than zero.',
        );
      }
      if (auction.minPlayersPerTeam < 1 ||
          auction.maxPlayersPerTeam < auction.minPlayersPerTeam) {
        throw const AuctionValidationException(
          'Minimum squad size cannot exceed maximum squad size.',
        );
      }
    }
  }

  int incrementFor(AuctionRuleSet rules, int currentBid) {
    if (currentBid < 0) {
      throw const AuctionValidationException('Current bid cannot be negative.');
    }
    validate(rules);
    if (rules.bidIncrementMode == BidIncrementMode.fixed) {
      return rules.fixedBidIncrement;
    }
    var increment = rules.bidIncrementTiers.first.increment;
    for (var index = 0; index < rules.bidIncrementTiers.length; index++) {
      final tier = rules.bidIncrementTiers[index];
      final implicitMaximum = index + 1 < rules.bidIncrementTiers.length
          ? rules.bidIncrementTiers[index + 1].minimumBid - 1
          : _maximumSafeInteger;
      final maximum = tier.maximumBid ?? implicitMaximum;
      if (currentBid >= tier.minimumBid && currentBid <= maximum) {
        increment = tier.increment;
        return increment;
      }
    }
    throw const AuctionValidationException(
      'Current bid does not fall within a configured increment tier.',
    );
  }

  int nextBid(AuctionRuleSet rules, int currentBid) {
    final increment = incrementFor(rules, currentBid);
    final nextBid = currentBid + increment;
    if (nextBid <= currentBid || nextBid > _maximumSafeInteger) {
      throw const AuctionValidationException(
        'The next bid exceeds the supported price range.',
      );
    }
    return nextBid;
  }

  void _validatePrices(AuctionRuleSet rules, Auction? auction) {
    final prices = [
      if (rules.defaultPlayerBasePrice != null) rules.defaultPlayerBasePrice!,
      ...rules.categoryBasePrices.values,
    ];
    if (prices.any((price) => price <= 0)) {
      throw const AuctionValidationException(
        'Configured player base prices must be greater than zero.',
      );
    }
    if (auction != null &&
        prices.any((price) => price > auction.totalPursePerTeam)) {
      throw const AuctionValidationException(
        'A configured player base price cannot exceed the team purse.',
      );
    }
  }

  void _validateSquadRules(AuctionRuleSet rules, Auction? auction) {
    for (final entry in rules.categoryMaximums.entries) {
      if (!_categories.contains(entry.key) ||
          entry.value < 1 ||
          (auction != null && entry.value > auction.maxPlayersPerTeam)) {
        throw const AuctionValidationException(
          'Category player limits must be positive and within the squad size.',
        );
      }
    }
    for (final limit in [
      rules.maximumOverseasPlayers,
      rules.maximumWicketkeepers,
    ]) {
      if (limit != null &&
          (limit < 1 ||
              (auction != null && limit > auction.maxPlayersPerTeam))) {
        throw const AuctionValidationException(
          'Optional player limits must be within the squad size.',
        );
      }
    }
    if (auction != null &&
        rules.categoryMaximums.length == _categories.length &&
        rules.categoryMaximums.values.reduce(
              (first, second) => first + second,
            ) <
            auction.minPlayersPerTeam) {
      throw const AuctionValidationException(
        'Category limits cannot accommodate the minimum squad size.',
      );
    }
  }

  void _validateTimer(AuctionRuleSet rules) {
    if (rules.bidTimerSeconds < 5 || rules.bidTimerSeconds > 600) {
      throw const AuctionValidationException(
        'Bid timer must be from 5 to 600 seconds.',
      );
    }
    if (rules.warningThresholdSeconds < 1 ||
        rules.warningThresholdSeconds >= rules.bidTimerSeconds) {
      throw const AuctionValidationException(
        'Warning threshold must be positive and less than the bid timer.',
      );
    }
    if (rules.bidTimerExtensionEnabled) {
      if (rules.bidTimerExtensionSeconds < 1 ||
          rules.bidTimerExtensionSeconds > 120 ||
          rules.maximumBidTimerExtensions < 1 ||
          rules.maximumBidTimerExtensions > 10) {
        throw const AuctionValidationException(
          'Timer extensions must be 1–120 seconds and limited to 1–10 uses.',
        );
      }
    } else if (rules.bidTimerExtensionSeconds != 0 ||
        rules.maximumBidTimerExtensions != 0) {
      throw const AuctionValidationException(
        'Disable timer extensions by setting extension duration and count to zero.',
      );
    }
  }
}

import 'package:jp_auction_arena/features/auction/domain/models/bid_increment_tier.dart';
import 'package:jp_auction_arena/features/auction/domain/models/bid_increment_mode.dart';
import 'package:jp_auction_arena/features/auction/domain/models/player_order_mode.dart';
import 'package:jp_auction_arena/features/player/domain/models/player_category.dart';

class AuctionRuleSet {
  const AuctionRuleSet({
    required this.auctionId,
    required this.bidIncrementTiers,
    required this.allowUnsoldPlayerReentry,
    this.bidIncrementMode = BidIncrementMode.tiered,
    this.fixedBidIncrement = 1000,
    this.defaultPlayerBasePrice,
    this.categoryBasePrices = const {},
    this.categoryMaximums = const {},
    this.maximumOverseasPlayers,
    this.maximumWicketkeepers,
    this.bidTimerSeconds = 30,
    this.warningThresholdSeconds = 10,
    this.bidTimerExtensionEnabled = false,
    this.bidTimerExtensionSeconds = 0,
    this.maximumBidTimerExtensions = 0,
    this.playerOrderMode = PlayerOrderMode.manual,
    this.maximumUnsoldReentries,
  });

  final String auctionId;
  final BidIncrementMode bidIncrementMode;
  final int fixedBidIncrement;
  final List<BidIncrementTier> bidIncrementTiers;
  final int? defaultPlayerBasePrice;
  final Map<PlayerCategory, int> categoryBasePrices;
  final Map<PlayerCategory, int> categoryMaximums;
  final int? maximumOverseasPlayers;
  final int? maximumWicketkeepers;
  final int bidTimerSeconds;
  final int warningThresholdSeconds;
  final bool bidTimerExtensionEnabled;
  final int bidTimerExtensionSeconds;
  final int maximumBidTimerExtensions;
  final PlayerOrderMode playerOrderMode;
  final bool allowUnsoldPlayerReentry;
  final int? maximumUnsoldReentries;

  AuctionRuleSet copyWith({
    String? auctionId,
    BidIncrementMode? bidIncrementMode,
    int? fixedBidIncrement,
    List<BidIncrementTier>? bidIncrementTiers,
    int? defaultPlayerBasePrice,
    Map<PlayerCategory, int>? categoryBasePrices,
    Map<PlayerCategory, int>? categoryMaximums,
    int? maximumOverseasPlayers,
    bool clearMaximumOverseasPlayers = false,
    int? maximumWicketkeepers,
    bool clearMaximumWicketkeepers = false,
    int? bidTimerSeconds,
    int? warningThresholdSeconds,
    bool? bidTimerExtensionEnabled,
    int? bidTimerExtensionSeconds,
    int? maximumBidTimerExtensions,
    PlayerOrderMode? playerOrderMode,
    bool? allowUnsoldPlayerReentry,
    int? maximumUnsoldReentries,
    bool clearMaximumUnsoldReentries = false,
  }) => AuctionRuleSet(
    auctionId: auctionId ?? this.auctionId,
    bidIncrementMode: bidIncrementMode ?? this.bidIncrementMode,
    fixedBidIncrement: fixedBidIncrement ?? this.fixedBidIncrement,
    bidIncrementTiers: bidIncrementTiers ?? this.bidIncrementTiers,
    defaultPlayerBasePrice:
        defaultPlayerBasePrice ?? this.defaultPlayerBasePrice,
    categoryBasePrices: categoryBasePrices ?? this.categoryBasePrices,
    categoryMaximums: categoryMaximums ?? this.categoryMaximums,
    maximumOverseasPlayers: clearMaximumOverseasPlayers
        ? null
        : maximumOverseasPlayers ?? this.maximumOverseasPlayers,
    maximumWicketkeepers: clearMaximumWicketkeepers
        ? null
        : maximumWicketkeepers ?? this.maximumWicketkeepers,
    bidTimerSeconds: bidTimerSeconds ?? this.bidTimerSeconds,
    warningThresholdSeconds:
        warningThresholdSeconds ?? this.warningThresholdSeconds,
    bidTimerExtensionEnabled:
        bidTimerExtensionEnabled ?? this.bidTimerExtensionEnabled,
    bidTimerExtensionSeconds:
        bidTimerExtensionSeconds ?? this.bidTimerExtensionSeconds,
    maximumBidTimerExtensions:
        maximumBidTimerExtensions ?? this.maximumBidTimerExtensions,
    playerOrderMode: playerOrderMode ?? this.playerOrderMode,
    allowUnsoldPlayerReentry:
        allowUnsoldPlayerReentry ?? this.allowUnsoldPlayerReentry,
    maximumUnsoldReentries: clearMaximumUnsoldReentries
        ? null
        : maximumUnsoldReentries ?? this.maximumUnsoldReentries,
  );
}

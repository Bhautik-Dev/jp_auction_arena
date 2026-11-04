import 'package:jp_auction_arena/features/team/domain/models/purse_adjustment.dart';

class TeamPurseAccount {
  const TeamPurseAccount({
    required this.auctionId,
    required this.teamId,
    required this.initialPurse,
    required this.adjustments,
    required this.totalSpent,
    required this.purchasedPlayerCount,
    required this.lastUpdatedAt,
    required this.hasUnpricedPurchase,
  });

  final String auctionId;
  final String teamId;
  final int initialPurse;
  final List<PurseAdjustment> adjustments;
  final int totalSpent;
  final int purchasedPlayerCount;
  final DateTime lastUpdatedAt;
  final bool hasUnpricedPurchase;

  int get adjustedInitialPurse => initialPurse + adjustments.fold<int>(
    0,
    (total, adjustment) => total + adjustment.amount,
  );

  int get remainingPurse => adjustedInitialPurse - totalSpent;
}

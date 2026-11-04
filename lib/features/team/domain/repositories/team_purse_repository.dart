import 'package:jp_auction_arena/features/team/domain/models/purse_adjustment.dart';

abstract interface class TeamPurseRepository {
  Future<int> getInitialPurse({
    required String auctionId,
    required String teamId,
    required int defaultAmount,
  });

  Future<List<PurseAdjustment>> getAdjustments({
    required String auctionId,
    required String teamId,
  });

  Future<PurseAdjustment> addAdjustment(
    PurseAdjustment adjustment, {
    required int minimumEffectiveInitialPurse,
  });
}

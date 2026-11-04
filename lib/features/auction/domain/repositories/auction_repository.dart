import 'package:jp_auction_arena/features/auction/domain/models/auction.dart';
import 'package:jp_auction_arena/features/auction/domain/models/auction_status.dart';

abstract interface class AuctionRepository {
  Future<List<Auction>> getAuctions({AuctionStatus? status, String? query});

  Future<Auction?> getAuctionById(String id);

  Future<Auction> createAuction(Auction auction);

  Future<Auction> updateAuction(Auction auction);

  Future<Auction> updateAuctionStatus(String id, AuctionStatus status);
}

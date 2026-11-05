import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/models.dart';
import 'hive_service.dart';
import 'auction_repository.dart';

abstract class BidRepository {
  List<Bid> getAll();
  List<Bid> getByAuctionId(String auctionId);
  List<Bid> getByPlayerId(String playerId);
  Bid? getById(String id);
  Future<void> save(Bid bid);
  Future<void> delete(String id);
  Future<void> deleteByAuction(String auctionId);
  Stream<List<Bid>> watchByAuction(String auctionId);
}

class HiveBidRepository implements BidRepository {
  Box<Bid> get _box => Hive.box<Bid>(HiveBoxes.bids);

  @override
  List<Bid> getAll() => _box.values.toList();

  @override
  List<Bid> getByAuctionId(String auctionId) {
    return _box.values
        .where((b) => b.auctionId == auctionId)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  @override
  List<Bid> getByPlayerId(String playerId) {
    return _box.values
        .where((b) => b.playerId == playerId)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  @override
  Bid? getById(String id) {
    try {
      return _box.values.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> save(Bid bid) async {
    await _box.put(bid.id, bid);
  }

  @override
  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  @override
  Future<void> deleteByAuction(String auctionId) async {
    final keysToDelete = _box.values
        .where((b) => b.auctionId == auctionId)
        .map((b) => b.id)
        .toList();
    await _box.deleteAll(keysToDelete);
  }

  @override
  Stream<List<Bid>> watchByAuction(String auctionId) {
    return _box.watch().map((_) => getByAuctionId(auctionId));
  }
}

final bidRepositoryProvider = Provider<BidRepository>((ref) {
  return HiveBidRepository();
});

final currentAuctionBidsProvider = StreamProvider<List<Bid>>((ref) async* {
  final repo = ref.watch(bidRepositoryProvider);
  final activeAuction = ref.watch(activeAuctionProvider);
  if (activeAuction == null) {
    yield [];
    return;
  }
  yield repo.getByAuctionId(activeAuction.id);
  yield* repo.watchByAuction(activeAuction.id);
});

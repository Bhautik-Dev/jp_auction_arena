import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/models.dart';
import 'hive_service.dart';

abstract class AuctionRepository {
  List<Auction> getAll();
  Auction? getById(String id);
  Future<void> save(Auction auction);
  Future<void> delete(String id);
  Stream<List<Auction>> watchAll();
}

class HiveAuctionRepository implements AuctionRepository {
  Box<Auction> get _box => Hive.box<Auction>(HiveBoxes.auctions);

  @override
  List<Auction> getAll() {
    return _box.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Auction? getById(String id) {
    try {
      return _box.values.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> save(Auction auction) async {
    await _box.put(auction.id, auction);
  }

  @override
  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  @override
  Stream<List<Auction>> watchAll() {
    return _box.watch().map((_) => getAll());
  }
}

final auctionRepositoryProvider = Provider<AuctionRepository>((ref) {
  return HiveAuctionRepository();
});

final auctionsListProvider = StreamProvider<List<Auction>>((ref) async* {
  final repo = ref.watch(auctionRepositoryProvider);
  yield repo.getAll();
  yield* repo.watchAll();
});

class ActiveAuctionIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setAuctionId(String? id) {
    state = id;
  }
}

final activeAuctionIdProvider = NotifierProvider<ActiveAuctionIdNotifier, String?>(
  ActiveAuctionIdNotifier.new,
);

final activeAuctionProvider = Provider<Auction?>((ref) {
  final activeId = ref.watch(activeAuctionIdProvider);
  final auctions = ref.watch(auctionsListProvider).value ?? [];
  if (activeId == null) {
    return auctions.isNotEmpty ? auctions.first : null;
  }
  try {
    return auctions.firstWhere((a) => a.id == activeId);
  } catch (_) {
    return auctions.isNotEmpty ? auctions.first : null;
  }
});

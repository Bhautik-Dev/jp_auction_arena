import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/models.dart';
import 'hive_service.dart';
import 'auction_repository.dart';

abstract class PlayerRepository {
  List<Player> getAll();
  List<Player> getByAuctionId(String auctionId);
  Player? getById(String id);
  Future<void> save(Player player);
  Future<void> saveAll(List<Player> players);
  Future<void> delete(String id);
  Future<void> deleteByAuction(String auctionId);
  Stream<List<Player>> watchByAuction(String auctionId);
}

class HivePlayerRepository implements PlayerRepository {
  Box<Player> get _box => Hive.box<Player>(HiveBoxes.players);

  @override
  List<Player> getAll() => _box.values.toList();

  @override
  List<Player> getByAuctionId(String auctionId) {
    return _box.values
        .where((p) => p.auctionId == auctionId)
        .toList()
      ..sort((a, b) => a.playerNo.compareTo(b.playerNo));
  }

  @override
  Player? getById(String id) {
    try {
      return _box.values.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> save(Player player) async {
    await _box.put(player.id, player);
  }

  @override
  Future<void> saveAll(List<Player> players) async {
    final map = {for (final p in players) p.id: p};
    await _box.putAll(map);
  }

  @override
  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  @override
  Future<void> deleteByAuction(String auctionId) async {
    final keysToDelete = _box.values
        .where((p) => p.auctionId == auctionId)
        .map((p) => p.id)
        .toList();
    await _box.deleteAll(keysToDelete);
  }

  @override
  Stream<List<Player>> watchByAuction(String auctionId) {
    return _box.watch().map((_) => getByAuctionId(auctionId));
  }
}

final playerRepositoryProvider = Provider<PlayerRepository>((ref) {
  return HivePlayerRepository();
});

final currentAuctionPlayersProvider = StreamProvider<List<Player>>((ref) async* {
  final repo = ref.watch(playerRepositoryProvider);
  final activeAuction = ref.watch(activeAuctionProvider);
  if (activeAuction == null) {
    yield [];
    return;
  }
  yield repo.getByAuctionId(activeAuction.id);
  yield* repo.watchByAuction(activeAuction.id);
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/models.dart';
import 'hive_service.dart';
import 'auction_repository.dart';

abstract class TeamRepository {
  List<Team> getAll();
  List<Team> getByAuctionId(String auctionId);
  Team? getById(String id);
  Future<void> save(Team team);
  Future<void> delete(String id);
  Future<void> deleteByAuction(String auctionId);
  Stream<List<Team>> watchByAuction(String auctionId);
}

class HiveTeamRepository implements TeamRepository {
  Box<Team> get _box => Hive.box<Team>(HiveBoxes.teams);

  @override
  List<Team> getAll() => _box.values.toList();

  @override
  List<Team> getByAuctionId(String auctionId) {
    return _box.values.where((t) => t.auctionId == auctionId).toList();
  }

  @override
  Team? getById(String id) {
    try {
      return _box.values.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> save(Team team) async {
    await _box.put(team.id, team);
  }

  @override
  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  @override
  Future<void> deleteByAuction(String auctionId) async {
    final keysToDelete = _box.values
        .where((t) => t.auctionId == auctionId)
        .map((t) => t.id)
        .toList();
    await _box.deleteAll(keysToDelete);
  }

  @override
  Stream<List<Team>> watchByAuction(String auctionId) {
    return _box.watch().map((_) => getByAuctionId(auctionId));
  }
}

final teamRepositoryProvider = Provider<TeamRepository>((ref) {
  return HiveTeamRepository();
});

final currentAuctionTeamsProvider = StreamProvider<List<Team>>((ref) async* {
  final repo = ref.watch(teamRepositoryProvider);
  final activeAuction = ref.watch(activeAuctionProvider);
  if (activeAuction == null) {
    yield [];
    return;
  }
  yield repo.getByAuctionId(activeAuction.id);
  yield* repo.watchByAuction(activeAuction.id);
});

final allTeamsListProvider = StreamProvider<List<Team>>((ref) async* {
  final repo = ref.watch(teamRepositoryProvider);
  yield repo.getAll();
  yield* repo.watchByAuction('');
});

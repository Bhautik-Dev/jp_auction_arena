import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/models.dart';
import 'hive_service.dart';
import 'auction_repository.dart';
import 'repository_factory.dart';

abstract class TeamRepository {
  Future<List<Team>> getAll();
  Future<List<Team>> getByAuctionId(String auctionId);
  Future<Team?> getById(String id);
  Future<void> save(Team team);
  Future<void> delete(String id);
  Future<void> deleteByAuction(String auctionId);
  Stream<List<Team>> watchByAuction(String auctionId);
}

class HiveTeamRepository implements TeamRepository {
  Box<Team> get _box => Hive.box<Team>(HiveBoxes.teams);

  @override
  Future<List<Team>> getAll() async => _box.values.toList();

  @override
  Future<List<Team>> getByAuctionId(String auctionId) async {
    return _box.values.where((t) => t.auctionId == auctionId).toList();
  }

  @override
  Future<Team?> getById(String id) async {
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
    return _box.watch().asyncMap((_) => getByAuctionId(auctionId));
  }
}

final teamRepositoryProvider = Provider<TeamRepository>((ref) {
  return ref.watch(repositoryFactoryProvider).team;
});

final currentAuctionTeamsProvider = StreamProvider<List<Team>>((ref) async* {
  final repo = ref.watch(teamRepositoryProvider);
  final activeAuction = ref.watch(activeAuctionProvider);
  
  if (activeAuction == null) {
    // Show ALL teams when no auction is active
    yield await repo.getAll();
    return;
  }
  yield await repo.getByAuctionId(activeAuction.id);
  yield* repo.watchByAuction(activeAuction.id);
});

final allTeamsListProvider = StreamProvider<List<Team>>((ref) async* {
  final repo = ref.watch(teamRepositoryProvider);
  yield await repo.getAll();
});
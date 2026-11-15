import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:jp_auction_arena/core/supabase/supabase_client.dart';
import 'package:jp_auction_arena/core/supabase/supabase_models.dart';
import '../../models/player.dart';
import '../hive_service.dart';
import '../player_repository.dart';
import 'supabase_sync_service.dart';

/// Supabase-backed implementation of [PlayerRepository].
///
/// Reads come from the local Hive box (single source of truth for the UI).
/// Writes are mirrored to the local box first, then pushed to Supabase
/// best-effort so the app remains fully functional offline.
class SupabasePlayerRepository implements PlayerRepository {
  SupabasePlayerRepository();

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
    unawaited(SupabaseSyncService.instance.pushPlayer(
      SupabasePlayer(
        id: player.id,
        auctionId: player.auctionId,
        playerNo: player.playerNo,
        name: player.name,
        photoBase64: player.photoBase64,
        age: player.age,
        village: player.village,
        category: player.category,
        battingStyle: player.battingStyle,
        bowlingStyle: player.bowlingStyle,
        matches: player.matches,
        runs: player.runs,
        wickets: player.wickets,
        highScore: player.highScore,
        strikeRate: player.strikeRate,
        economy: player.economy,
        basePrice: player.basePrice,
        isIcon: player.isIcon,
        isOwner: player.isOwner,
        isRetained: player.isRetained,
        retainedTeamId: player.retainedTeamId,
        status: player.status.name,
        soldPrice: player.soldPrice,
        soldTeamId: player.soldTeamId,
      ),
    ));
  }

  @override
  Future<void> saveAll(List<Player> players) async {
    final map = {for (final p in players) p.id: p};
    await _box.putAll(map);
    for (final player in players) {
      unawaited(SupabaseSyncService.instance.pushPlayer(
        SupabasePlayer(
          id: player.id,
          auctionId: player.auctionId,
          playerNo: player.playerNo,
          name: player.name,
          photoBase64: player.photoBase64,
          age: player.age,
          village: player.village,
          category: player.category,
          battingStyle: player.battingStyle,
          bowlingStyle: player.bowlingStyle,
          matches: player.matches,
          runs: player.runs,
          wickets: player.wickets,
          highScore: player.highScore,
          strikeRate: player.strikeRate,
          economy: player.economy,
          basePrice: player.basePrice,
          isIcon: player.isIcon,
          isOwner: player.isOwner,
          isRetained: player.isRetained,
          retainedTeamId: player.retainedTeamId,
          status: player.status.name,
          soldPrice: player.soldPrice,
          soldTeamId: player.soldTeamId,
        ),
      ));
    }
  }

  @override
  Future<void> delete(String id) async {
    final player = getById(id);
    await _box.delete(id);
    if (player != null) {
      unawaited(SupabaseSyncService.instance.deletePlayer(
        SupabasePlayer(
          id: player.id,
          auctionId: player.auctionId,
          playerNo: player.playerNo,
          name: player.name,
        ),
      ));
    }
  }

  @override
  Future<void> deleteByAuction(String auctionId) async {
    final players = getByAuctionId(auctionId);
    await _box.deleteAll(players.map((p) => p.id).toList());
    for (final player in players) {
      unawaited(SupabaseSyncService.instance.deletePlayer(
        SupabasePlayer(
          id: player.id,
          auctionId: player.auctionId,
          playerNo: player.playerNo,
          name: player.name,
        ),
      ));
    }
  }

  @override
  Stream<List<Player>> watchByAuction(String auctionId) {
    return _box.watch().map((_) => getByAuctionId(auctionId));
  }
}

/// Riverpod provider for the Supabase-backed player repository.
final supabasePlayerRepositoryProvider =
    Provider<PlayerRepository>((ref) {
  final client = SupabaseClientService.instance.client;
  if (client == null) {
    return HivePlayerRepository();
  }
  return SupabasePlayerRepository();
});
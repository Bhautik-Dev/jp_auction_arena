import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_client.dart';
import '../../models/models.dart';
import '../hive_service.dart';
import '../team_repository.dart';
import 'supabase_sync_service.dart';

/// Supabase-backed implementation of [TeamRepository].
///
/// Reads come from the local Hive box (single source of truth for the UI).
/// Writes are mirrored to the local box first, then pushed to Supabase
/// best-effort so the app remains fully functional offline.
class SupabaseTeamRepository implements TeamRepository {
  SupabaseTeamRepository(this._client);

  final SupabaseClient _client;

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
    unawaited(SupabaseSyncService.instance.pushTeam(
      SupabaseTeam(
        id: team.id,
        auctionId: team.auctionId,
        name: team.name,
        logoBase64: team.logoBase64,
        ownerName: team.ownerName,
        purseTotal: team.purseTotal,
        purseSpent: team.purseSpent,
        playerIds: team.playerIds,
      ),
    ));
  }

  @override
  Future<void> delete(String id) async {
    final team = getById(id);
    await _box.delete(id);
    if (team != null) {
      unawaited(SupabaseSyncService.instance.deleteTeam(
        SupabaseTeam(
          id: team.id,
          auctionId: team.auctionId,
          name: team.name,
        ),
      ));
    }
  }

  @override
  Future<void> deleteByAuction(String auctionId) async {
    final teams = getByAuctionId(auctionId);
    await _box.deleteAll(teams.map((t) => t.id).toList());
    for (final team in teams) {
      unawaited(SupabaseSyncService.instance.deleteTeam(
        SupabaseTeam(
          id: team.id,
          auctionId: team.auctionId,
          name: team.name,
        ),
      ));
    }
  }

  @override
  Stream<List<Team>> watchByAuction(String auctionId) {
    return _box.watch().map((_) => getByAuctionId(auctionId));
  }
}

/// Riverpod provider for the Supabase-backed team repository.
final supabaseTeamRepositoryProvider =
    Provider<TeamRepository>((ref) {
  final client = SupabaseClientService.instance.client;
  if (client == null) {
    return HiveTeamRepository();
  }
  return SupabaseTeamRepository(client);
});
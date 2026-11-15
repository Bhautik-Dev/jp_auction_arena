import 'dart:async';

import 'package:jp_auction_arena/core/supabase/supabase_client.dart';
import 'package:jp_auction_arena/core/supabase/supabase_models.dart';

/// Best-effort cloud sync helper.
///
/// All methods are fire-and-forget: failures are swallowed so the local Hive
/// repository remains the single source of truth for the UI. The service
/// guards against unconfigured clients and silent failures.
class SupabaseSyncService {
  SupabaseSyncService._();

  static final SupabaseSyncService _instance = SupabaseSyncService._();

  /// Singleton accessor.
  static SupabaseSyncService get instance => _instance;

  /// Push a single auction row to Supabase (upsert).
  Future<void> pushAuction(SupabaseAuction auction) async {
    final client = SupabaseClientService.instance.client;
    if (client == null) return;
    try {
      await client.from('auctions').upsert(auction.toJson());
    } catch (_) {
      // Best-effort: never block the UI on cloud failures.
    }
  }

  /// Delete an auction row from Supabase.
  Future<void> deleteAuction(SupabaseAuction auction) async {
    final client = SupabaseClientService.instance.client;
    if (client == null) return;
    try {
      await client.from('auctions').delete().eq('id', auction.id);
    } catch (_) {
      // Best-effort.
    }
  }

  /// Push a player row to Supabase (upsert).
  Future<void> pushPlayer(SupabasePlayer player) async {
    final client = SupabaseClientService.instance.client;
    if (client == null) return;
    try {
      await client.from('players').upsert(player.toJson());
    } catch (_) {
      // Best-effort.
    }
  }

  /// Delete a player row from Supabase.
  Future<void> deletePlayer(SupabasePlayer player) async {
    final client = SupabaseClientService.instance.client;
    if (client == null) return;
    try {
      await client.from('players').delete().eq('id', player.id);
    } catch (_) {
      // Best-effort.
    }
  }

  /// Push a team row to Supabase (upsert).
  Future<void> pushTeam(SupabaseTeam team) async {
    final client = SupabaseClientService.instance.client;
    if (client == null) return;
    try {
      await client.from('teams').upsert(team.toJson());
    } catch (_) {
      // Best-effort.
    }
  }

  /// Delete a team row from Supabase.
  Future<void> deleteTeam(SupabaseTeam team) async {
    final client = SupabaseClientService.instance.client;
    if (client == null) return;
    try {
      await client.from('teams').delete().eq('id', team.id);
    } catch (_) {
      // Best-effort.
    }
  }

  /// Push a bid row to Supabase (insert).
  Future<void> pushBid(SupabaseBid bid) async {
    final client = SupabaseClientService.instance.client;
    if (client == null) return;
    try {
      await client.from('bids').insert(bid.toJson());
    } catch (_) {
      // Best-effort.
    }
  }

  /// Push a live auction-state row to Supabase (upsert).
  Future<void> pushAuctionState(SupabaseAuctionState state) async {
    final client = SupabaseClientService.instance.client;
    if (client == null) return;
    try {
      await client.from('auction_state').upsert(state.toJson());
    } catch (_) {
      // Best-effort.
    }
  }

  /// Push an activity-log row to Supabase (insert).
  Future<void> pushActivityLog(SupabaseActivityLog log) async {
    final client = SupabaseClientService.instance.client;
    if (client == null) return;
    try {
      await client.from('activity_log').insert(log.toJson());
    } catch (_) {
      // Best-effort.
    }
  }
}
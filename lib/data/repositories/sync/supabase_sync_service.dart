import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jp_auction_arena/core/supabase/supabase_client.dart';
import 'package:jp_auction_arena/core/supabase/supabase_models.dart';
import 'package:jp_auction_arena/core/utils/app_logger.dart';

/// Best-effort cloud sync helper.
///
/// All methods return [bool] indicating whether the cloud write succeeded.
/// Failures are logged via [AppLogger] so they are visible in the debug console
/// and can be reported to the user. The local Hive repository remains the
/// single source of truth for the UI regardless of cloud sync outcome.
class SupabaseSyncService {
  SupabaseSyncService._();

  static final SupabaseSyncService _instance = SupabaseSyncService._();

  /// Singleton accessor.
  static SupabaseSyncService get instance => _instance;

  SupabaseClient? get _client => SupabaseClientService.instance.client;

  /// Whether a Supabase client is available for cloud writes.
  bool get isConnected => _client != null;

  /// Optional callback invoked after every cloud write attempt.
  /// Signature: (table, operation, success, errorMessageOrNull)
  static void Function(String table, String op, bool success, String? error)?
      onSyncResult;

  /// Push a single auction row to Supabase (upsert).
  /// Returns `true` if the write succeeded, `false` otherwise.
  Future<bool> pushAuction(SupabaseAuction auction) async {
    return _write(
      operation: () async {
        await _client!.from('auctions').upsert(auction.toJson());
      },
      table: 'auctions',
      op: 'upsert',
      recordId: auction.id,
    );
  }

  /// Delete an auction row from Supabase.
  /// Returns `true` if the write succeeded, `false` otherwise.
  Future<bool> deleteAuction(SupabaseAuction auction) async {
    return _write(
      operation: () async {
        await _client!.from('auctions').delete().eq('id', auction.id);
      },
      table: 'auctions',
      op: 'delete',
      recordId: auction.id,
    );
  }

  /// Push a player row to Supabase (upsert).
  /// Returns `true` if the write succeeded, `false` otherwise.
  Future<bool> pushPlayer(SupabasePlayer player) async {
    return _write(
      operation: () async {
        await _client!.from('players').upsert(player.toJson());
      },
      table: 'players',
      op: 'upsert',
      recordId: player.id,
    );
  }

  /// Delete a player row from Supabase.
  /// Returns `true` if the write succeeded, `false` otherwise.
  Future<bool> deletePlayer(SupabasePlayer player) async {
    return _write(
      operation: () async {
        await _client!.from('players').delete().eq('id', player.id);
      },
      table: 'players',
      op: 'delete',
      recordId: player.id,
    );
  }

  /// Push a team row to Supabase (upsert).
  /// Returns `true` if the write succeeded, `false` otherwise.
  Future<bool> pushTeam(SupabaseTeam team) async {
    return _write(
      operation: () async {
        await _client!.from('teams').upsert(team.toJson());
      },
      table: 'teams',
      op: 'upsert',
      recordId: team.id,
    );
  }

  /// Delete a team row from Supabase.
  /// Returns `true` if the write succeeded, `false` otherwise.
  Future<bool> deleteTeam(SupabaseTeam team) async {
    return _write(
      operation: () async {
        await _client!.from('teams').delete().eq('id', team.id);
      },
      table: 'teams',
      op: 'delete',
      recordId: team.id,
    );
  }

  /// Push a bid row to Supabase (insert).
  /// Returns `true` if the write succeeded, `false` otherwise.
  Future<bool> pushBid(SupabaseBid bid) async {
    return _write(
      operation: () async {
        await _client!.from('bids').insert(bid.toJson());
      },
      table: 'bids',
      op: 'insert',
      recordId: bid.id,
    );
  }

  /// Delete a bid row from Supabase.
  /// Returns `true` if the write succeeded, `false` otherwise.
  Future<bool> deleteBid(SupabaseBid bid) async {
    return _write(
      operation: () async {
        await _client!.from('bids').delete().eq('id', bid.id);
      },
      table: 'bids',
      op: 'delete',
      recordId: bid.id,
    );
  }

  /// Push a live auction-state row to Supabase (upsert).
  /// Returns `true` if the write succeeded, `false` otherwise.
  Future<bool> pushAuctionState(SupabaseAuctionState state) async {
    return _write(
      operation: () async {
        await _client!.from('auction_state').upsert(state.toJson());
      },
      table: 'auction_state',
      op: 'upsert',
      recordId: state.id,
    );
  }

  /// Push an activity-log row to Supabase (insert).
  /// Returns `true` if the write succeeded, `false` otherwise.
  Future<bool> pushActivityLog(SupabaseActivityLog log) async {
    return _write(
      operation: () async {
        await _client!.from('activity_log').insert(log.toJson());
      },
      table: 'activity_log',
      op: 'insert',
      recordId: log.id,
    );
  }

  /// Internal helper that executes a Supabase write, logs errors, and returns
  /// whether it succeeded.
  Future<bool> _write({
    required Future<void> Function() operation,
    required String table,
    required String op,
    required String recordId,
  }) async {
    final client = _client;
    if (client == null) {
      AppLogger.warning(
        'Supabase client not initialized — skipping $op on $table/$recordId',
        tag: 'SupabaseSync',
      );
      return false;
    }
    try {
      await operation();
      AppLogger.debug(
        'Supabase $op on $table/$recordId succeeded',
        tag: 'SupabaseSync',
      );
      onSyncResult?.call(table, op, true, null);
      return true;
    } catch (e, st) {
      AppLogger.error(
        'Supabase $op on $table/$recordId failed: $e',
        tag: 'SupabaseSync',
        error: e,
        stackTrace: st,
      );
      onSyncResult?.call(table, op, false, e.toString());
      return false;
    }
  }
}
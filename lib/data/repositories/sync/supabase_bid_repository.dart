import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_client.dart';
import '../../models/models.dart';
import '../hive_service.dart';
import '../bid_repository.dart';
import 'supabase_sync_service.dart';

/// Supabase-backed implementation of [BidRepository].
///
/// Reads come from the local Hive box (single source of truth for the UI).
/// Writes are mirrored to the local box first, then pushed to Supabase
/// best-effort so the app remains fully functional offline.
class SupabaseBidRepository implements BidRepository {
  SupabaseBidRepository(this._client);

  final SupabaseClient _client;

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
    unawaited(SupabaseSyncService.instance.pushBid(
      SupabaseBid(
        id: bid.id,
        auctionId: bid.auctionId,
        playerId: bid.playerId,
        teamId: bid.teamId,
        amount: bid.amount,
        timestamp: bid.timestamp,
      ),
    ));
  }

  @override
  Future<void> delete(String id) async {
    final bid = getById(id);
    await _box.delete(id);
    if (bid != null) {
      unawaited(SupabaseSyncService.instance.pushBid(
        SupabaseBid(
          id: bid.id,
          auctionId: bid.auctionId,
          playerId: bid.playerId,
          teamId: bid.teamId,
          amount: bid.amount,
          timestamp: bid.timestamp,
        ),
      ));
    }
  }

  @override
  Future<void> deleteByAuction(String auctionId) async {
    final bids = getByAuctionId(auctionId);
    await _box.deleteAll(bids.map((b) => b.id).toList());
  }

  @override
  Stream<List<Bid>> watchByAuction(String auctionId) {
    return _box.watch().map((_) => getByAuctionId(auctionId));
  }
}

/// Riverpod provider for the Supabase-backed bid repository.
final supabaseBidRepositoryProvider =
    Provider<BidRepository>((ref) {
  final client = SupabaseClientService.instance.client;
  if (client == null) {
    return HiveBidRepository();
  }
  return SupabaseBidRepository(client);
});
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:jp_auction_arena/core/supabase/supabase_client.dart';
import 'package:jp_auction_arena/core/supabase/supabase_models.dart';
import 'package:jp_auction_arena/core/utils/app_logger.dart';
import '../../models/bid.dart';
import '../hive_service.dart';
import '../bid_repository.dart';
import 'supabase_sync_service.dart';

/// Supabase-backed implementation of [BidRepository].
///
/// Reads come from the local Hive box (single source of truth for the UI).
/// Writes are mirrored to the local box first, then pushed to Supabase.
/// Cloud sync failures are logged but never block the UI or roll back
/// the local write.
class SupabaseBidRepository implements BidRepository {
  SupabaseBidRepository();

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
    final ok = await SupabaseSyncService.instance.pushBid(
      SupabaseBid(
        id: bid.id,
        auctionId: bid.auctionId,
        playerId: bid.playerId,
        teamId: bid.teamId,
        amount: bid.amount,
        timestamp: bid.timestamp,
      ),
    );
    if (!ok) {
      AppLogger.warning(
        'Bid ${bid.id} saved locally but cloud sync failed',
        tag: 'SupabaseSync',
      );
    }
  }

  @override
  Future<void> delete(String id) async {
    final bid = getById(id);
    await _box.delete(id);
    if (bid != null) {
      final ok = await SupabaseSyncService.instance.deleteBid(
        SupabaseBid(
          id: bid.id,
          auctionId: bid.auctionId,
          playerId: bid.playerId,
          teamId: bid.teamId,
          amount: bid.amount,
          timestamp: bid.timestamp,
        ),
      );
      if (!ok) {
        AppLogger.warning(
          'Bid $id deleted locally but cloud sync failed',
          tag: 'SupabaseSync',
        );
      }
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
  return SupabaseBidRepository();
});
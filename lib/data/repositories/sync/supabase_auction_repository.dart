import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:jp_auction_arena/core/supabase/supabase_client.dart';
import 'package:jp_auction_arena/core/supabase/supabase_models.dart';
import 'package:jp_auction_arena/core/utils/app_logger.dart';
import '../../models/auction.dart';
import '../hive_service.dart';
import '../auction_repository.dart';
import 'supabase_sync_service.dart';

/// Supabase-backed implementation of [AuctionRepository].
///
/// Reads/writes are mirrored to the local Hive box so the app stays fully
/// functional offline. Cloud writes are best-effort — failures are logged
/// but never block the UI or roll back the local write.
class SupabaseAuctionRepository implements AuctionRepository {
  SupabaseAuctionRepository();

  Box<Auction> get _box => Hive.box<Auction>(HiveBoxes.auctions);

  @override
  List<Auction> getAll() => _box.values.toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

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
    final ok = await SupabaseSyncService.instance.pushAuction(
      SupabaseAuction(
        id: auction.id,
        name: auction.name,
        logoBase64: auction.logoBase64,
        venue: auction.venue,
        description: auction.description,
        startDateTime: auction.startDateTime,
        status: auction.status.name,
        categories: auction.categories,
        numberOfTeams: auction.numberOfTeams,
        minSquad: auction.minSquad,
        maxSquad: auction.maxSquad,
        basePriceDefault: auction.basePriceDefault,
        bidIncrement: auction.bidIncrement,
        teamPurse: auction.teamPurse,
        countdownSeconds: auction.countdownSeconds,
        mode: auction.mode.name,
        createdAt: auction.createdAt,
        contactPhone: auction.contactPhone,
        contactEmail: auction.contactEmail,
        categoryBasePrices: auction.categoryBasePrices,
        reservePurseRule: auction.reservePurseRule,
        smartBidSlabs: auction.smartBidSlabs,
      ),
    );
    if (!ok) {
      AppLogger.warning(
        'Auction ${auction.id} saved locally but cloud sync failed',
        tag: 'SupabaseSync',
      );
    }
  }

  @override
  Future<void> delete(String id) async {
    final auction = getById(id);
    await _box.delete(id);
    if (auction != null) {
      final ok = await SupabaseSyncService.instance.deleteAuction(
        SupabaseAuction(
          id: auction.id,
          name: auction.name,
          startDateTime: auction.startDateTime,
          createdAt: auction.createdAt,
        ),
      );
      if (!ok) {
        AppLogger.warning(
          'Auction $id deleted locally but cloud sync failed',
          tag: 'SupabaseSync',
        );
      }
    }
  }

  @override
  Stream<List<Auction>> watchAll() {
    return _box.watch().map((_) => getAll());
  }
}

/// Riverpod provider for the Supabase-backed auction repository.
final supabaseAuctionRepositoryProvider =
    Provider<AuctionRepository>((ref) {
  final client = SupabaseClientService.instance.client;
  if (client == null) {
    return HiveAuctionRepository();
  }
  return SupabaseAuctionRepository();
});
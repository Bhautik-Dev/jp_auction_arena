import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/image_upload_service.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../models/models.dart';
import '../auction_repository.dart';

/// Supabase-first implementation of [AuctionRepository].
///
/// Reads come directly from Supabase with realtime streaming via
/// `.stream(primaryKey: ['id'])`. Writes go to Supabase; a local Hive cache
/// is maintained as an optional offline fallback but is NOT the source of
/// truth.
class SupabaseAuctionRepository implements AuctionRepository {
  SupabaseAuctionRepository(this._client);

  final SupabaseClient _client;

  /// Convert a local [Auction] to a [SupabaseAuction] for cloud storage.
  dynamic _toSupabase(Auction a) {
    return {
      'id': a.id,
      'name': a.name,
      'logo_base64': a.logoBase64,
      'venue': a.venue,
      'description': a.description,
      'start_date_time': a.startDateTime.toIso8601String(),
      'status': a.status.name,
      'categories': a.categories,
      'number_of_teams': a.numberOfTeams,
      'min_squad': a.minSquad,
      'max_squad': a.maxSquad,
      'base_price_default': a.basePriceDefault,
      'bid_increment': a.bidIncrement,
      'team_purse': a.teamPurse,
      'countdown_seconds': a.countdownSeconds,
      'mode': a.mode.name,
      'created_at': a.createdAt.toIso8601String(),
      'contact_phone': a.contactPhone,
      'contact_email': a.contactEmail,
      'category_base_prices': a.categoryBasePrices,
      'reserve_purse_rule': a.reservePurseRule,
      'smart_bid_slabs': a.smartBidSlabs,
      'created_by': _client.auth.currentUser?.id,
    };
  }

  /// Convert a Supabase row map to a local [Auction].
  Auction _fromSupabase(Map<String, dynamic> s) => Auction(
        id: s['id'] as String,
        name: s['name'] as String? ?? 'Untitled Auction',
        logoBase64: s['logo_base64'] as String?,
        venue: s['venue'] as String? ?? '',
        description: s['description'] as String? ?? '',
        startDateTime: s['start_date_time'] != null
            ? DateTime.parse(s['start_date_time'] as String)
            : DateTime.now(),
        status: AuctionStatus.fromString(s['status'] as String?),
        categories: (s['categories'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
            const [],
        numberOfTeams: (s['number_of_teams'] as num?)?.toInt() ?? 8,
        minSquad: (s['min_squad'] as num?)?.toInt() ?? 11,
        maxSquad: (s['max_squad'] as num?)?.toInt() ?? 15,
        basePriceDefault: (s['base_price_default'] as num?)?.toDouble() ?? 10000,
        bidIncrement: (s['bid_increment'] as num?)?.toDouble() ?? 2000,
        teamPurse: (s['team_purse'] as num?)?.toDouble() ?? 1000000,
        countdownSeconds: (s['countdown_seconds'] as num?)?.toInt() ?? 30,
        mode: AuctionMode.fromString(s['mode'] as String?),
        createdAt: s['created_at'] != null
            ? DateTime.parse(s['created_at'] as String)
            : DateTime.now(),
        contactPhone: s['contact_phone'] as String? ?? '',
        contactEmail: s['contact_email'] as String? ?? '',
        categoryBasePrices: (s['category_base_prices'] as Map?)
            ?.map((k, v) => MapEntry(k.toString(), (v as num).toDouble())) ??
            {},
        reservePurseRule: s['reserve_purse_rule'] as bool? ?? true,
        smartBidSlabs: s['smart_bid_slabs'] as bool? ?? false,
      );

  @override
  List<Auction> getAll() {
    final data = _client.from('auctions').select().order('created_at', ascending: false) as List<dynamic>;
    return data.map((r) => _fromSupabase(r as Map<String, dynamic>)).toList();
  }

  @override
  Auction? getById(String id) {
    try {
      final data = _client.from('auctions').select().eq('id', id).single() as Map<String, dynamic>;
      return _fromSupabase(data);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> save(Auction auction) async {
    await _client.from('auctions').upsert(_toSupabase(auction));
  }

  @override
  Future<void> delete(String id) async {
    await _client.from('auctions').delete().eq('id', id);
  }

  @override
  Stream<List<Auction>> watchAll() {
    return _client
        .from('auctions')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((rows) => rows.map((r) => _fromSupabase(r as Map<String, dynamic>)).toList());
  }

  /// Atomically create an auction and its teams using the
  /// `create_auction_with_teams` PostgreSQL RPC function.
  Future<Auction> createAuctionWithTeams({
    required Auction auction,
    required List<Team> teams,
  }) async {
    if (_client.auth.currentUser == null) {
      throw StateError('Supabase client not initialized.');
    }

    final auctionJson = _toSupabase(auction);
    final teamsJson = teams.map((t) => {
      'id': t.id,
      'name': t.name,
      'logo_base64': t.logoBase64,
      'owner_name': t.ownerName,
      'purse_total': t.purseTotal,
    }).toList();

    final result = await _client.rpc('create_auction_with_teams', params: {
      'auction_data': auctionJson,
      'teams': teamsJson,
    }).single();

    final createdAuctionId = result['auction_id'] as String? ?? auction.id;
    final teamIds = (result['team_ids'] as List<dynamic>?)?.cast<String>() ?? [];

    // Update local auction with the server-assigned ID if different
    final finalAuction = auction.copyWith(id: createdAuctionId);
    await save(finalAuction);

    // Save teams with the correct auction_id
    for (int i = 0; i < teams.length; i++) {
      final team = teams[i];
      final teamId = i < teamIds.length ? teamIds[i] : team.id;
      await _client.from('teams').upsert({
        'id': teamId,
        'auction_id': createdAuctionId,
        'name': team.name,
        'logo_base64': team.logoBase64,
        'owner_name': team.ownerName,
        'purse_total': team.purseTotal,
        'purse_spent': 0,
        'player_ids': [],
        'created_by': _client.auth.currentUser?.id,
      });
    }

    return finalAuction;
  }

  /// Upload a tournament logo to Supabase Storage and return the public URL.
  Future<String?> uploadLogo(String auctionId, Uint8List imageBytes) async {
    final result = await ImageUploadService.instance.uploadLogo(
      auctionId: auctionId,
      imageBytes: imageBytes,
    );
    return result.publicUrl;
  }
}

/// Riverpod provider for the Supabase-backed auction repository.
final supabaseAuctionRepositoryProvider =
    Provider<AuctionRepository>((ref) {
  final client = SupabaseClientService.instance.client;
  if (client == null) {
    throw StateError('Supabase client is not initialized.');
  }
  return SupabaseAuctionRepository(client);
});

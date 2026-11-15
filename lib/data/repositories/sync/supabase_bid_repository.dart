import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client.dart';
import '../../models/bid.dart';
import '../../models/models.dart';
import '../bid_repository.dart';

/// Supabase-first implementation of [BidRepository].
class SupabaseBidRepository implements BidRepository {
  SupabaseBidRepository(this._client);

  final SupabaseClient _client;

  dynamic _toSupabase(Bid b) {
    return {
      'id': b.id,
      'auction_id': b.auctionId,
      'player_id': b.playerId,
      'team_id': b.teamId,
      'amount': b.amount,
      'timestamp': b.timestamp.toIso8601String(),
      'created_by': _client.auth.currentUser?.id,
    };
  }

  Bid _fromSupabase(Map<String, dynamic> s) => Bid(
        id: s['id'] as String,
        auctionId: s['auction_id'] as String,
        playerId: s['player_id'] as String,
        teamId: s['team_id'] as String,
        amount: (s['amount'] as num?)?.toDouble() ?? 0.0,
        timestamp: s['timestamp'] != null
            ? DateTime.parse(s['timestamp'] as String)
            : DateTime.now(),
      );

  @override
  List<Bid> getAll() {
    final data = _client.from('bids').select().order('timestamp', ascending: false) as List<Map<String, dynamic>>;
    return data.map((r) => _fromSupabase(r)).toList();
  }

  @override
  List<Bid> getByAuctionId(String auctionId) {
    final data = _client.from('bids').select().eq('auction_id', auctionId).order('timestamp', ascending: false) as List<Map<String, dynamic>>;
    return data.map((r) => _fromSupabase(r)).toList();
  }

  @override
  List<Bid> getByPlayerId(String playerId) {
    final data = _client.from('bids').select().eq('player_id', playerId).order('timestamp', ascending: false) as List<Map<String, dynamic>>;
    return data.map((r) => _fromSupabase(r)).toList();
  }

  @override
  Bid? getById(String id) {
    try {
      final data = _client.from('bids').select().eq('id', id).single() as Map<String, dynamic>;
      return _fromSupabase(data);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> save(Bid bid) async {
    await _client.from('bids').insert(_toSupabase(bid));
  }

  @override
  Future<void> delete(String id) async {
    await _client.from('bids').delete().eq('id', id);
  }

  @override
  Future<void> deleteByAuction(String auctionId) async {
    await _client.from('bids').delete().eq('auction_id', auctionId);
  }

  @override
  Stream<List<Bid>> watchByAuction(String auctionId) {
    return _client
        .from('bids')
        .stream(primaryKey: ['id'])
        .eq('auction_id', auctionId)
        .order('timestamp', ascending: false)
        .map((rows) => rows.map((r) => _fromSupabase(r as Map<String, dynamic>)).toList());
  }
}

/// Riverpod provider for the Supabase-backed bid repository.
final supabaseBidRepositoryProvider =
    Provider<BidRepository>((ref) {
  final client = SupabaseClientService.instance.client;
  if (client == null) {
    throw StateError('Supabase client is not initialized.');
  }
  return SupabaseBidRepository(client);
});

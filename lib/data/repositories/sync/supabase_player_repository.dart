import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/image_upload_service.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../models/models.dart';
import '../player_repository.dart';

/// Supabase-first implementation of [PlayerRepository].
class SupabasePlayerRepository implements PlayerRepository {
  SupabasePlayerRepository(this._client);

  final SupabaseClient _client;

  dynamic _toSupabase(Player p) {
    return {
      'id': p.id,
      'auction_id': p.auctionId,
      'player_no': p.playerNo,
      'name': p.name,
      'mobile': p.mobile,
      'photo_base64': p.photoBase64,
      'age': p.age,
      'village': p.village,
      'category': p.category,
      'batting_style': p.battingStyle,
      'bowling_style': p.bowlingStyle,
      'cric_heroes_url': p.cricHeroesUrl,
      'matches': p.matches,
      'runs': p.runs,
      'wickets': p.wickets,
      'high_score': p.highScore,
      'strike_rate': p.strikeRate,
      'batting_average': p.battingAverage,
      'economy': p.economy,
      'base_price': p.basePrice,
      'is_icon': p.isIcon,
      'is_owner': p.isOwner,
      'is_retained': p.isRetained,
      'retained_team_id': p.retainedTeamId,
      'status': p.status.name,
      'sold_price': p.soldPrice,
      'sold_team_id': p.soldTeamId,
      'created_by': '',
    };
  }

  Player _fromSupabase(Map<String, dynamic> s) => Player(
        id: s['id'] as String,
        auctionId: s['auction_id'] as String,
        playerNo: (s['player_no'] as num?)?.toInt() ?? 1,
        name: s['name'] as String? ?? 'Player',
        mobile: s['mobile'] as String?,
        photoBase64: s['photo_base64'] as String?,
        age: (s['age'] as num?)?.toInt() ?? 20,
        village: s['village'] as String? ?? '',
        category: s['category'] as String? ?? 'All-Rounder',
        battingStyle: s['batting_style'] as String? ?? 'Right Hand Bat',
        bowlingStyle: s['bowling_style'] as String? ?? 'Right Arm Medium',
        cricHeroesUrl: s['cric_heroes_url'] as String?,
        matches: (s['matches'] as num?)?.toInt() ?? 0,
        runs: (s['runs'] as num?)?.toInt() ?? 0,
        wickets: (s['wickets'] as num?)?.toInt() ?? 0,
        highScore: (s['high_score'] as num?)?.toInt() ?? 0,
        strikeRate: (s['strike_rate'] as num?)?.toDouble() ?? 0.0,
        battingAverage: (s['batting_average'] as num?)?.toDouble() ?? 0.0,
        economy: (s['economy'] as num?)?.toDouble() ?? 0.0,
        basePrice: (s['base_price'] as num?)?.toDouble() ?? 10000.0,
        isIcon: s['is_icon'] as bool? ?? false,
        isOwner: s['is_owner'] as bool? ?? false,
        isRetained: s['is_retained'] as bool? ?? false,
        retainedTeamId: s['retained_team_id'] as String?,
        status: PlayerStatus.fromString(s['status'] as String?),
        soldPrice: (s['sold_price'] as num?)?.toDouble(),
        soldTeamId: s['sold_team_id'] as String?,
      );

  @override
  Future<List<Player>> getAll() async {
    final data = await _client.from('players').select().order('player_no');
    return data.map((r) => _fromSupabase(r)).toList();
  }

  @override
  Future<List<Player>> getByAuctionId(String auctionId) async {
    final data = await _client.from('players').select().eq('auction_id', auctionId).order('player_no');
    return data.map((r) => _fromSupabase(r)).toList();
  }

  @override
  Future<Player?> getById(String id) async {
    try {
      final data = await _client.from('players').select().eq('id', id).single();
      return _fromSupabase(data);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> save(Player player) async {
    await _client.from('players').upsert(_toSupabase(player));
  }

  @override
  Future<void> saveAll(List<Player> players) async {
    if (players.isEmpty) return;
    const chunkSize = 200;
    for (int i = 0; i < players.length; i += chunkSize) {
      final chunk = players.skip(i).take(chunkSize).toList();
      final rows = chunk.map((p) => _toSupabase(p)).toList();
      await _client.from('players').upsert(rows);
    }
  }

  @override
  Future<void> delete(String id) async {
    await _client.from('players').delete().eq('id', id);
  }

  @override
  Future<void> deleteByAuction(String auctionId) async {
    await _client.from('players').delete().eq('auction_id', auctionId);
  }

  @override
  Stream<List<Player>> watchByAuction(String auctionId) {
    return _client
        .from('players')
        .stream(primaryKey: ['id'])
        .eq('auction_id', auctionId)
        .order('player_no')
        .map((rows) => rows.map((r) => _fromSupabase(r)).toList());
  }

  Future<int> importPlayers(List<Player> players) async {
    await saveAll(players);
    return players.length;
  }

  @override
  Future<String?> uploadPhoto(String auctionId, String playerId, Uint8List imageBytes) async {
    final result = await ImageUploadService.instance.uploadPlayerPhoto(
      auctionId: auctionId,
      playerId: playerId,
      imageBytes: imageBytes,
    );
    return result.publicUrl;
  }
}

/// Riverpod provider for the Supabase-backed player repository.
final supabasePlayerRepositoryProvider =
    Provider<PlayerRepository>((ref) {
  final client = SupabaseClientService.instance.client;
  if (client == null) {
    throw StateError('Supabase client is not initialized.');
  }
  return SupabasePlayerRepository(client);
});
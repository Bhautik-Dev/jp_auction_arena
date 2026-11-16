import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/image_upload_service.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../models/team.dart';
import '../../models/models.dart';
import '../team_repository.dart';

/// Supabase-first implementation of [TeamRepository].
class SupabaseTeamRepository implements TeamRepository {
  SupabaseTeamRepository(this._client);

  final SupabaseClient _client;

  dynamic _toSupabase(Team t) {
    return {
      'id': t.id,
      'auction_id': t.auctionId,
      'name': t.name,
      'logo_base64': t.logoBase64,
      'owner_name': t.ownerName,
      'purse_total': t.purseTotal,
      'purse_spent': t.purseSpent,
      'player_ids': t.playerIds,
      'created_by': _client.auth.currentUser?.id,
    };
  }

  Team _fromSupabase(Map<String, dynamic> s) => Team(
        id: s['id'] as String,
        auctionId: s['auction_id'] as String,
        name: s['name'] as String? ?? 'Team',
        logoBase64: s['logo_base64'] as String?,
        ownerName: s['owner_name'] as String? ?? '',
        purseTotal: (s['purse_total'] as num?)?.toDouble() ?? 1000000,
        purseSpent: (s['purse_spent'] as num?)?.toDouble() ?? 0.0,
        playerIds: (s['player_ids'] as List?)?.map((e) => e.toString()).toList() ?? [],
      );

  @override
  List<Team> getAll() {
    final data = _client.from('teams').select().order('name') as List<dynamic>;
    return data.map((r) => _fromSupabase(r as Map<String, dynamic>)).toList();
  }

  @override
  List<Team> getByAuctionId(String auctionId) {
    final data = _client.from('teams').select().eq('auction_id', auctionId).order('name') as List<dynamic>;
    return data.map((r) => _fromSupabase(r as Map<String, dynamic>)).toList();
  }

  @override
  Team? getById(String id) {
    try {
      final data = _client.from('teams').select().eq('id', id).single() as Map<String, dynamic>;
      return _fromSupabase(data);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> save(Team team) async {
    await _client.from('teams').upsert(_toSupabase(team));
  }

  @override
  Future<void> delete(String id) async {
    await _client.from('teams').delete().eq('id', id);
  }

  @override
  Future<void> deleteByAuction(String auctionId) async {
    await _client.from('teams').delete().eq('auction_id', auctionId);
  }

  @override
  Stream<List<Team>> watchByAuction(String auctionId) {
    return _client
        .from('teams')
        .stream(primaryKey: ['id'])
        .eq('auction_id', auctionId)
        .order('name')
        .map((rows) => rows.map((r) => _fromSupabase(r as Map<String, dynamic>)).toList());
  }

  Future<String?> uploadLogo(String teamId, Uint8List imageBytes) async {
    final result = await ImageUploadService.instance.uploadLogo(
      auctionId: teamId,
      imageBytes: imageBytes,
    );
    return result.publicUrl;
  }
}

/// Riverpod provider for the Supabase-backed team repository.
final supabaseTeamRepositoryProvider =
    Provider<TeamRepository>((ref) {
  final client = SupabaseClientService.instance.client;
  if (client == null) {
    throw StateError('Supabase client is not initialized.');
  }
  return SupabaseTeamRepository(client);
});

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jp_auction_arena/core/supabase/supabase_client.dart';

/// Result of a live auction RPC call.
class LiveAuctionResult {
  const LiveAuctionResult({
    required this.success,
    this.errorCode,
    this.errorMessage,
    this.data,
  });

  final bool success;
  final String? errorCode;
  final String? errorMessage;
  final Map<String, dynamic>? data;

  void assertSuccess() {
    if (!success) {
      throw LiveAuctionException(errorCode ?? 'unknown', errorMessage ?? 'Request failed');
    }
  }
}

/// Exception thrown when a live auction RPC call fails.
class LiveAuctionException implements Exception {
  final String code;
  final String message;

  LiveAuctionException(this.code, this.message);

  @override
  String toString() => 'LiveAuctionException($code: $message)';
}

/// Friendly error messages for each rejection code.
class LiveAuctionErrorMessages {
  static String forCode(String? code, String? fallback) {
    switch (code) {
      case 'auction_not_found':
        return 'Auction not found.';
      case 'player_not_found':
        return 'Player not found.';
      case 'player_not_in_auction':
        return 'Player does not belong to this auction.';
      case 'no_player_live':
        return 'No player is currently live.';
      case 'auction_not_live':
        return 'Auction is not live.';
      case 'auction_paused':
        return 'Auction is paused. Resume before bidding.';
      case 'already_leader':
        return 'This team is already the leading bidder.';
      case 'bid_too_low':
        return fallback ?? 'Bid is too low.';
      case 'not_enough_purse':
        return 'Team does not have enough purse remaining.';
      case 'reserve_rule_violated':
        return 'Reserve purse rule violated: keep enough purse for remaining squad slots.';
      case 'squad_full':
        return 'Team squad is full.';
      case 'no_bid_to_undo':
        return 'No bid to undo.';
      case 'already_paused':
        return 'Auction is already paused.';
      case 'not_paused':
        return 'Auction is not paused.';
      case 'player_not_sold':
        return 'Player is not sold.';
      case 'manual_mode':
        return 'Manual mode does not auto-pick players.';
      case 'no_players_available':
        return 'No available players to pick.';
      case 'invalid_mode':
        return 'Invalid auction mode.';
      case 'unknown':
        return fallback ?? 'An unknown error occurred.';
      default:
        return fallback ?? 'Operation failed.';
    }
  }
}

class LiveAuctionClient {
  LiveAuctionClient._();
  static final LiveAuctionClient _instance = LiveAuctionClient._();
  static LiveAuctionClient get instance => _instance;

  SupabaseClient? get _client => SupabaseClientService.instance.client;

  bool get isConnected => _client != null;

  Future<LiveAuctionResult> startPlayer({
    required String auctionId,
    required String playerId,
  }) async {
    final client = _client;
    if (client == null) {
      return const LiveAuctionResult(success: false, errorCode: 'not_connected', errorMessage: 'Supabase client not initialized');
    }

    try {
      final result = await client.rpc('start_player', params: {
        'p_auction_id': auctionId,
        'p_player_id': playerId,
      }).single();

      return LiveAuctionResult(
        success: result['success'] as bool? ?? false,
        errorCode: result['error_code'] as String?,
        errorMessage: result['error_message'] as String?,
        data: result as Map<String, dynamic>?,
      );
    } on PostgrestException catch (e) {
      return LiveAuctionResult(
        success: false,
        errorCode: 'postgrest_error',
        errorMessage: e.message,
      );
    } catch (e) {
      return LiveAuctionResult(
        success: false,
        errorCode: 'unexpected_error',
        errorMessage: e.toString(),
      );
    }
  }

  Future<LiveAuctionResult> placeBid({
    required String auctionId,
    required String teamId,
    required double amount,
  }) async {
    final client = _client;
    if (client == null) {
      return const LiveAuctionResult(success: false, errorCode: 'not_connected', errorMessage: 'Supabase client not initialized');
    }

    try {
      final result = await client.rpc('place_bid', params: {
        'p_auction_id': auctionId,
        'p_team_id': teamId,
        'p_amount': amount,
      }).single();

      return LiveAuctionResult(
        success: result['success'] as bool? ?? false,
        errorCode: result['error_code'] as String?,
        errorMessage: result['error_message'] as String?,
        data: result as Map<String, dynamic>?,
      );
    } on PostgrestException catch (e) {
      return LiveAuctionResult(
        success: false,
        errorCode: 'postgrest_error',
        errorMessage: e.message,
      );
    } catch (e) {
      return LiveAuctionResult(
        success: false,
        errorCode: 'unexpected_error',
        errorMessage: e.toString(),
      );
    }
  }

  Future<LiveAuctionResult> undoLastBid({
    required String auctionId,
  }) async {
    final client = _client;
    if (client == null) {
      return const LiveAuctionResult(success: false, errorCode: 'not_connected', errorMessage: 'Supabase client not initialized');
    }

    try {
      final result = await client.rpc('undo_last_bid', params: {
        'p_auction_id': auctionId,
      }).single();

      return LiveAuctionResult(
        success: result['success'] as bool? ?? false,
        errorCode: result['error_code'] as String?,
        errorMessage: result['error_message'] as String?,
        data: result as Map<String, dynamic>?,
      );
    } on PostgrestException catch (e) {
      return LiveAuctionResult(
        success: false,
        errorCode: 'postgrest_error',
        errorMessage: e.message,
      );
    } catch (e) {
      return LiveAuctionResult(
        success: false,
        errorCode: 'unexpected_error',
        errorMessage: e.toString(),
      );
    }
  }

  Future<LiveAuctionResult> pauseAuction({
    required String auctionId,
  }) async {
    final client = _client;
    if (client == null) {
      return const LiveAuctionResult(success: false, errorCode: 'not_connected', errorMessage: 'Supabase client not initialized');
    }

    try {
      final result = await client.rpc('pause_auction', params: {
        'p_auction_id': auctionId,
      }).single();

      return LiveAuctionResult(
        success: result['success'] as bool? ?? false,
        errorCode: result['error_code'] as String?,
        errorMessage: result['error_message'] as String?,
        data: result as Map<String, dynamic>?,
      );
    } on PostgrestException catch (e) {
      return LiveAuctionResult(
        success: false,
        errorCode: 'postgrest_error',
        errorMessage: e.message,
      );
    } catch (e) {
      return LiveAuctionResult(
        success: false,
        errorCode: 'unexpected_error',
        errorMessage: e.toString(),
      );
    }
  }

  Future<LiveAuctionResult> resumeAuction({
    required String auctionId,
  }) async {
    final client = _client;
    if (client == null) {
      return const LiveAuctionResult(success: false, errorCode: 'not_connected', errorMessage: 'Supabase client not initialized');
    }

    try {
      final result = await client.rpc('resume_auction', params: {
        'p_auction_id': auctionId,
      }).single();

      return LiveAuctionResult(
        success: result['success'] as bool? ?? false,
        errorCode: result['error_code'] as String?,
        errorMessage: result['error_message'] as String?,
        data: result as Map<String, dynamic>?,
      );
    } on PostgrestException catch (e) {
      return LiveAuctionResult(
        success: false,
        errorCode: 'postgrest_error',
        errorMessage: e.message,
      );
    } catch (e) {
      return LiveAuctionResult(
        success: false,
        errorCode: 'unexpected_error',
        errorMessage: e.toString(),
      );
    }
  }

  Future<LiveAuctionResult> sellPlayer({
    required String auctionId,
  }) async {
    final client = _client;
    if (client == null) {
      return const LiveAuctionResult(success: false, errorCode: 'not_connected', errorMessage: 'Supabase client not initialized');
    }

    try {
      final result = await client.rpc('sell_player', params: {
        'p_auction_id': auctionId,
      }).single();

      return LiveAuctionResult(
        success: result['success'] as bool? ?? false,
        errorCode: result['error_code'] as String?,
        errorMessage: result['error_message'] as String?,
        data: result as Map<String, dynamic>?,
      );
    } on PostgrestException catch (e) {
      return LiveAuctionResult(
        success: false,
        errorCode: 'postgrest_error',
        errorMessage: e.message,
      );
    } catch (e) {
      return LiveAuctionResult(
        success: false,
        errorCode: 'unexpected_error',
        errorMessage: e.toString(),
      );
    }
  }

  Future<LiveAuctionResult> markUnsold({
    required String auctionId,
  }) async {
    final client = _client;
    if (client == null) {
      return const LiveAuctionResult(success: false, errorCode: 'not_connected', errorMessage: 'Supabase client not initialized');
    }

    try {
      final result = await client.rpc('mark_unsold', params: {
        'p_auction_id': auctionId,
      }).single();

      return LiveAuctionResult(
        success: result['success'] as bool? ?? false,
        errorCode: result['error_code'] as String?,
        errorMessage: result['error_message'] as String?,
        data: result as Map<String, dynamic>?,
      );
    } on PostgrestException catch (e) {
      return LiveAuctionResult(
        success: false,
        errorCode: 'postgrest_error',
        errorMessage: e.message,
      );
    } catch (e) {
      return LiveAuctionResult(
        success: false,
        errorCode: 'unexpected_error',
        errorMessage: e.toString(),
      );
    }
  }

  Future<LiveAuctionResult> resetPlayer({
    required String auctionId,
  }) async {
    final client = _client;
    if (client == null) {
      return const LiveAuctionResult(success: false, errorCode: 'not_connected', errorMessage: 'Supabase client not initialized');
    }

    try {
      final result = await client.rpc('reset_player', params: {
        'p_auction_id': auctionId,
      }).single();

      return LiveAuctionResult(
        success: result['success'] as bool? ?? false,
        errorCode: result['error_code'] as String?,
        errorMessage: result['error_message'] as String?,
        data: result as Map<String, dynamic>?,
      );
    } on PostgrestException catch (e) {
      return LiveAuctionResult(
        success: false,
        errorCode: 'postgrest_error',
        errorMessage: e.message,
      );
    } catch (e) {
      return LiveAuctionResult(
        success: false,
        errorCode: 'unexpected_error',
        errorMessage: e.toString(),
      );
    }
  }

  Future<LiveAuctionResult> reauctionUnsold({
    required String auctionId,
  }) async {
    final client = _client;
    if (client == null) {
      return const LiveAuctionResult(success: false, errorCode: 'not_connected', errorMessage: 'Supabase client not initialized');
    }

    try {
      final result = await client.rpc('reauction_unsold', params: {
        'p_auction_id': auctionId,
      }).single();

      return LiveAuctionResult(
        success: result['success'] as bool? ?? false,
        errorCode: result['error_code'] as String?,
        errorMessage: result['error_message'] as String?,
        data: result as Map<String, dynamic>?,
      );
    } on PostgrestException catch (e) {
      return LiveAuctionResult(
        success: false,
        errorCode: 'postgrest_error',
        errorMessage: e.message,
      );
    } catch (e) {
      return LiveAuctionResult(
        success: false,
        errorCode: 'unexpected_error',
        errorMessage: e.toString(),
      );
    }
  }

  Future<LiveAuctionResult> releasePlayer({
    required String playerId,
  }) async {
    final client = _client;
    if (client == null) {
      return const LiveAuctionResult(success: false, errorCode: 'not_connected', errorMessage: 'Supabase client not initialized');
    }

    try {
      final result = await client.rpc('release_player', params: {
        'p_player_id': playerId,
      }).single();

      return LiveAuctionResult(
        success: result['success'] as bool? ?? false,
        errorCode: result['error_code'] as String?,
        errorMessage: result['error_message'] as String?,
        data: result as Map<String, dynamic>?,
      );
    } on PostgrestException catch (e) {
      return LiveAuctionResult(
        success: false,
        errorCode: 'postgrest_error',
        errorMessage: e.message,
      );
    } catch (e) {
      return LiveAuctionResult(
        success: false,
        errorCode: 'unexpected_error',
        errorMessage: e.toString(),
      );
    }
  }

  Future<LiveAuctionResult> completeAuction({
    required String auctionId,
  }) async {
    final client = _client;
    if (client == null) {
      return const LiveAuctionResult(success: false, errorCode: 'not_connected', errorMessage: 'Supabase client not initialized');
    }

    try {
      final result = await client.rpc('complete_auction', params: {
        'p_auction_id': auctionId,
      }).single();

      return LiveAuctionResult(
        success: result['success'] as bool? ?? false,
        errorCode: result['error_code'] as String?,
        errorMessage: result['error_message'] as String?,
        data: result as Map<String, dynamic>?,
      );
    } on PostgrestException catch (e) {
      return LiveAuctionResult(
        success: false,
        errorCode: 'postgrest_error',
        errorMessage: e.message,
      );
    } catch (e) {
      return LiveAuctionResult(
        success: false,
        errorCode: 'unexpected_error',
        errorMessage: e.toString(),
      );
    }
  }

  Future<LiveAuctionResult> pickNextPlayer({
    required String auctionId,
    String mode = 'auto',
    String? category,
  }) async {
    final client = _client;
    if (client == null) {
      return const LiveAuctionResult(success: false, errorCode: 'not_connected', errorMessage: 'Supabase client not initialized');
    }

    try {
      final result = await client.rpc('pick_next_player', params: {
        'p_auction_id': auctionId,
        'p_mode': mode,
        'p_category': category,
      }).single();

      return LiveAuctionResult(
        success: result['success'] as bool? ?? false,
        errorCode: result['error_code'] as String?,
        errorMessage: result['error_message'] as String?,
        data: result as Map<String, dynamic>?,
      );
    } on PostgrestException catch (e) {
      return LiveAuctionResult(
        success: false,
        errorCode: 'postgrest_error',
        errorMessage: e.message,
      );
    } catch (e) {
      return LiveAuctionResult(
        success: false,
        errorCode: 'unexpected_error',
        errorMessage: e.toString(),
      );
    }
  }
}

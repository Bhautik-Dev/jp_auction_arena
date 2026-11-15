/// Represents the `auction_state` table in Supabase.
///
/// Tracks the live operational state of an auction during a live session.
class SupabaseAuctionState {
  const SupabaseAuctionState({
    required this.id,
    required this.auctionId,
    this.currentPlayerId,
    this.currentBidAmount,
    this.currentTeamId,
    this.timerSecondsRemaining,
    this.isPaused,
    this.isLive,
    this.lastHammeredPlayerId,
    this.lastSoldTeamId,
    this.lastSoldPrice,
    this.bidCount,
    this.updatedAt,
    this.updatedBy,
  });

  /// Deserialize from a Supabase row map.
  factory SupabaseAuctionState.fromJson(Map<String, dynamic> json) {
    return SupabaseAuctionState(
      id: json['id'] as String,
      auctionId: json['auction_id'] as String,
      currentPlayerId: json['current_player_id'] as String?,
      currentBidAmount: (json['current_bid_amount'] as num?)?.toDouble(),
      currentTeamId: json['current_team_id'] as String?,
      timerSecondsRemaining: (json['timer_seconds_remaining'] as num?)?.toInt(),
      isPaused: json['is_paused'] as bool?,
      isLive: json['is_live'] as bool?,
      lastHammeredPlayerId: json['last_hammered_player_id'] as String?,
      lastSoldTeamId: json['last_sold_team_id'] as String?,
      lastSoldPrice: (json['last_sold_price'] as num?)?.toDouble(),
      bidCount: (json['bid_count'] as num?)?.toInt(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      updatedBy: json['updated_by'] as String?,
    );
  }

  final String id;
  final String auctionId;
  final String? currentPlayerId;
  final double? currentBidAmount;
  final String? currentTeamId;
  final int? timerSecondsRemaining;
  final bool? isPaused;
  final bool? isLive;
  final String? lastHammeredPlayerId;
  final String? lastSoldTeamId;
  final double? lastSoldPrice;
  final int? bidCount;
  final DateTime? updatedAt;
  final String? updatedBy;

  /// Serialize to a JSON map for upsert operations.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'auction_id': auctionId,
      'current_player_id': currentPlayerId,
      'current_bid_amount': currentBidAmount,
      'current_team_id': currentTeamId,
      'timer_seconds_remaining': timerSecondsRemaining,
      'is_paused': isPaused,
      'is_live': isLive,
      'last_hammered_player_id': lastHammeredPlayerId,
      'last_sold_team_id': lastSoldTeamId,
      'last_sold_price': lastSoldPrice,
      'bid_count': bidCount,
      'updated_at': updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'updated_by': updatedBy,
    };
  }

  SupabaseAuctionState copyWith({
    String? id,
    String? auctionId,
    String? currentPlayerId,
    double? currentBidAmount,
    String? currentTeamId,
    int? timerSecondsRemaining,
    bool? isPaused,
    bool? isLive,
    String? lastHammeredPlayerId,
    String? lastSoldTeamId,
    double? lastSoldPrice,
    int? bidCount,
    DateTime? updatedAt,
    String? updatedBy,
  }) {
    return SupabaseAuctionState(
      id: id ?? this.id,
      auctionId: auctionId ?? this.auctionId,
      currentPlayerId: currentPlayerId ?? this.currentPlayerId,
      currentBidAmount: currentBidAmount ?? this.currentBidAmount,
      currentTeamId: currentTeamId ?? this.currentTeamId,
      timerSecondsRemaining: timerSecondsRemaining ?? this.timerSecondsRemaining,
      isPaused: isPaused ?? this.isPaused,
      isLive: isLive ?? this.isLive,
      lastHammeredPlayerId: lastHammeredPlayerId ?? this.lastHammeredPlayerId,
      lastSoldTeamId: lastSoldTeamId ?? this.lastSoldTeamId,
      lastSoldPrice: lastSoldPrice ?? this.lastSoldPrice,
      bidCount: bidCount ?? this.bidCount,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }
}
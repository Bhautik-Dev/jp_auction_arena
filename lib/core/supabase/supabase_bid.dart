/// Represents the `bids` table in Supabase.
class SupabaseBid {
  const SupabaseBid({
    required this.id,
    required this.auctionId,
    required this.playerId,
    required this.teamId,
    required this.amount,
    this.timestamp,
    this.createdBy,
  });

  /// Deserialize from a Supabase row map.
  factory SupabaseBid.fromJson(Map<String, dynamic> json) {
    return SupabaseBid(
      id: json['id'] as String,
      auctionId: json['auction_id'] as String,
      playerId: json['player_id'] as String,
      teamId: json['team_id'] as String,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : null,
      createdBy: json['created_by'] as String?,
    );
  }

  final String id;
  final String auctionId;
  final String playerId;
  final String teamId;
  final double amount;
  final DateTime? timestamp;
  final String? createdBy;

  /// Serialize to a JSON map for upsert operations.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'auction_id': auctionId,
      'player_id': playerId,
      'team_id': teamId,
      'amount': amount,
      'timestamp': timestamp?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'created_by': createdBy,
    };
  }

  SupabaseBid copyWith({
    String? id,
    String? auctionId,
    String? playerId,
    String? teamId,
    double? amount,
    DateTime? timestamp,
    String? createdBy,
  }) {
    return SupabaseBid(
      id: id ?? this.id,
      auctionId: auctionId ?? this.auctionId,
      playerId: playerId ?? this.playerId,
      teamId: teamId ?? this.teamId,
      amount: amount ?? this.amount,
      timestamp: timestamp ?? this.timestamp,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}
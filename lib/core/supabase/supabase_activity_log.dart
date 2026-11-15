/// Represents the `activity_log` table in Supabase.
///
/// Records system events such as auction start, player sale, unsold, etc.
class SupabaseActivityLog {
  const SupabaseActivityLog({
    required this.id,
    required this.auctionId,
    this.eventType,
    this.entityType,
    this.entityId,
    this.entityName,
    this.teamId,
    this.teamName,
    this.playerId,
    this.playerName,
    this.amount,
    this.metadata,
    this.timestamp,
    this.createdBy,
  });

  /// Deserialize from a Supabase row map.
  factory SupabaseActivityLog.fromJson(Map<String, dynamic> json) {
    return SupabaseActivityLog(
      id: json['id'] as String,
      auctionId: json['auction_id'] as String,
      eventType: json['event_type'] as String?,
      entityType: json['entity_type'] as String?,
      entityId: json['entity_id'] as String?,
      entityName: json['entity_name'] as String?,
      teamId: json['team_id'] as String?,
      teamName: json['team_name'] as String?,
      playerId: json['player_id'] as String?,
      playerName: json['player_name'] as String?,
      amount: (json['amount'] as num?)?.toDouble(),
      metadata: json['metadata'] as Map<String, dynamic>?,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : null,
      createdBy: json['created_by'] as String?,
    );
  }

  final String id;
  final String auctionId;
  final String? eventType;
  final String? entityType;
  final String? entityId;
  final String? entityName;
  final String? teamId;
  final String? teamName;
  final String? playerId;
  final String? playerName;
  final double? amount;
  final Map<String, dynamic>? metadata;
  final DateTime? timestamp;
  final String? createdBy;

  /// Serialize to a JSON map for insert operations.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'auction_id': auctionId,
      'event_type': eventType,
      'entity_type': entityType,
      'entity_id': entityId,
      'entity_name': entityName,
      'team_id': teamId,
      'team_name': teamName,
      'player_id': playerId,
      'player_name': playerName,
      'amount': amount,
      'metadata': metadata,
      'timestamp': timestamp?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'created_by': createdBy,
    };
  }

  SupabaseActivityLog copyWith({
    String? id,
    String? auctionId,
    String? eventType,
    String? entityType,
    String? entityId,
    String? entityName,
    String? teamId,
    String? teamName,
    String? playerId,
    String? playerName,
    double? amount,
    Map<String, dynamic>? metadata,
    DateTime? timestamp,
    String? createdBy,
  }) {
    return SupabaseActivityLog(
      id: id ?? this.id,
      auctionId: auctionId ?? this.auctionId,
      eventType: eventType ?? this.eventType,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      entityName: entityName ?? this.entityName,
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      playerId: playerId ?? this.playerId,
      playerName: playerName ?? this.playerName,
      amount: amount ?? this.amount,
      metadata: metadata ?? this.metadata,
      timestamp: timestamp ?? this.timestamp,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}
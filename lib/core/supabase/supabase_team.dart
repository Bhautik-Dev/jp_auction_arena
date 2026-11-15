/// Represents the `teams` table in Supabase.
class SupabaseTeam {
  const SupabaseTeam({
    required this.id,
    required this.auctionId,
    required this.name,
    this.logoBase64,
    this.ownerName,
    this.purseTotal,
    this.purseSpent,
    this.playerIds,
    this.createdAt,
    this.createdBy,
  });

  /// Deserialize from a Supabase row map.
  factory SupabaseTeam.fromJson(Map<String, dynamic> json) {
    return SupabaseTeam(
      id: json['id'] as String,
      auctionId: json['auction_id'] as String,
      name: json['name'] as String? ?? 'Team',
      logoBase64: json['logo_base64'] as String?,
      ownerName: json['owner_name'] as String?,
      purseTotal: (json['purse_total'] as num?)?.toDouble(),
      purseSpent: (json['purse_spent'] as num?)?.toDouble(),
      playerIds: (json['player_ids'] as List?)
          ?.map((e) => e.toString())
          .toList(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      createdBy: json['created_by'] as String?,
    );
  }

  final String id;
  final String auctionId;
  final String name;
  final String? logoBase64;
  final String? ownerName;
  final double? purseTotal;
  final double? purseSpent;
  final List<String>? playerIds;
  final DateTime? createdAt;
  final String? createdBy;

  double get purseRemaining => (purseTotal ?? 0) - (purseSpent ?? 0);

  /// Serialize to a JSON map for upsert operations.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'auction_id': auctionId,
      'name': name,
      'logo_base64': logoBase64,
      'owner_name': ownerName,
      'purse_total': purseTotal,
      'purse_spent': purseSpent,
      'player_ids': playerIds,
      'created_at': createdAt?.toIso8601String(),
      'created_by': createdBy,
    };
  }

  SupabaseTeam copyWith({
    String? id,
    String? auctionId,
    String? name,
    String? logoBase64,
    String? ownerName,
    double? purseTotal,
    double? purseSpent,
    List<String>? playerIds,
    DateTime? createdAt,
    String? createdBy,
  }) {
    return SupabaseTeam(
      id: id ?? this.id,
      auctionId: auctionId ?? this.auctionId,
      name: name ?? this.name,
      logoBase64: logoBase64 ?? this.logoBase64,
      ownerName: ownerName ?? this.ownerName,
      purseTotal: purseTotal ?? this.purseTotal,
      purseSpent: purseSpent ?? this.purseSpent,
      playerIds: playerIds ?? this.playerIds,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}
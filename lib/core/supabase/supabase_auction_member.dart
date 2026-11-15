/// Represents the `auction_members` table in Supabase.
class SupabaseAuctionMember {
  const SupabaseAuctionMember({
    required this.id,
    required this.auctionId,
    required this.profileId,
    this.role,
    this.joinedAt,
  });

  /// Deserialize from a Supabase row map.
  factory SupabaseAuctionMember.fromJson(Map<String, dynamic> json) {
    return SupabaseAuctionMember(
      id: json['id'] as String,
      auctionId: json['auction_id'] as String,
      profileId: json['profile_id'] as String,
      role: json['role'] as String?,
      joinedAt: json['joined_at'] != null
          ? DateTime.parse(json['joined_at'] as String)
          : null,
    );
  }

  final String id;
  final String auctionId;
  final String profileId;
  final String? role;
  final DateTime? joinedAt;

  /// Serialize to a JSON map for upsert operations.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'auction_id': auctionId,
      'profile_id': profileId,
      'role': role,
      'joined_at': joinedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }

  SupabaseAuctionMember copyWith({
    String? id,
    String? auctionId,
    String? profileId,
    String? role,
    DateTime? joinedAt,
  }) {
    return SupabaseAuctionMember(
      id: id ?? this.id,
      auctionId: auctionId ?? this.auctionId,
      profileId: profileId ?? this.profileId,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }
}
/// Represents the `profiles` table in Supabase.
class SupabaseProfile {
  const SupabaseProfile({
    required this.id,
    this.email,
    this.fullName,
    this.avatarUrl,
    this.role,
    this.orgName,
    this.phone,
    this.createdAt,
    this.updatedAt,
  });

  /// Deserialize from a Supabase row map.
  factory SupabaseProfile.fromJson(Map<String, dynamic> json) {
    return SupabaseProfile(
      id: json['id'] as String,
      email: json['email'] as String?,
      fullName: json['full_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      role: json['role'] as String?,
      orgName: json['org_name'] as String?,
      phone: json['phone'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  final String id;
  final String? email;
  final String? fullName;
  final String? avatarUrl;
  final String? role;
  final String? orgName;
  final String? phone;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Serialize to a JSON map for upsert operations.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'role': role,
      'org_name': orgName,
      'phone': phone,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }

  SupabaseProfile copyWith({
    String? id,
    String? email,
    String? fullName,
    String? avatarUrl,
    String? role,
    String? orgName,
    String? phone,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SupabaseProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      orgName: orgName ?? this.orgName,
      phone: phone ?? this.phone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
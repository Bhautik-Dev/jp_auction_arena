/// Represents the `players` table in Supabase.
class SupabasePlayer {
  const SupabasePlayer({
    required this.id,
    required this.auctionId,
    this.playerNo,
    this.name,
    this.photoBase64,
    this.age,
    this.village,
    this.category,
    this.battingStyle,
    this.bowlingStyle,
    this.matches,
    this.runs,
    this.wickets,
    this.highScore,
    this.strikeRate,
    this.economy,
    this.basePrice,
    this.isIcon,
    this.isOwner,
    this.isRetained,
    this.retainedTeamId,
    this.status,
    this.soldPrice,
    this.soldTeamId,
    this.createdAt,
    this.createdBy,
  });

  /// Deserialize from a Supabase row map.
  factory SupabasePlayer.fromJson(Map<String, dynamic> json) {
    return SupabasePlayer(
      id: json['id'] as String,
      auctionId: json['auction_id'] as String,
      playerNo: (json['player_no'] as num?)?.toInt(),
      name: json['name'] as String?,
      photoBase64: json['photo_base64'] as String?,
      age: (json['age'] as num?)?.toInt(),
      village: json['village'] as String?,
      category: json['category'] as String?,
      battingStyle: json['batting_style'] as String?,
      bowlingStyle: json['bowling_style'] as String?,
      matches: (json['matches'] as num?)?.toInt(),
      runs: (json['runs'] as num?)?.toInt(),
      wickets: (json['wickets'] as num?)?.toInt(),
      highScore: (json['high_score'] as num?)?.toInt(),
      strikeRate: (json['strike_rate'] as num?)?.toDouble(),
      economy: (json['economy'] as num?)?.toDouble(),
      basePrice: (json['base_price'] as num?)?.toDouble(),
      isIcon: json['is_icon'] as bool?,
      isOwner: json['is_owner'] as bool?,
      isRetained: json['is_retained'] as bool?,
      retainedTeamId: json['retained_team_id'] as String?,
      status: json['status'] as String?,
      soldPrice: (json['sold_price'] as num?)?.toDouble(),
      soldTeamId: json['sold_team_id'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      createdBy: json['created_by'] as String?,
    );
  }

  final String id;
  final String auctionId;
  final int? playerNo;
  final String? name;
  final String? photoBase64;
  final int? age;
  final String? village;
  final String? category;
  final String? battingStyle;
  final String? bowlingStyle;
  final int? matches;
  final int? runs;
  final int? wickets;
  final int? highScore;
  final double? strikeRate;
  final double? economy;
  final double? basePrice;
  final bool? isIcon;
  final bool? isOwner;
  final bool? isRetained;
  final String? retainedTeamId;
  final String? status;
  final double? soldPrice;
  final String? soldTeamId;
  final DateTime? createdAt;
  final String? createdBy;

  /// Serialize to a JSON map for upsert operations.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'auction_id': auctionId,
      'player_no': playerNo,
      'name': name,
      'photo_base64': photoBase64,
      'age': age,
      'village': village,
      'category': category,
      'batting_style': battingStyle,
      'bowling_style': bowlingStyle,
      'matches': matches,
      'runs': runs,
      'wickets': wickets,
      'high_score': highScore,
      'strike_rate': strikeRate,
      'economy': economy,
      'base_price': basePrice,
      'is_icon': isIcon,
      'is_owner': isOwner,
      'is_retained': isRetained,
      'retained_team_id': retainedTeamId,
      'status': status,
      'sold_price': soldPrice,
      'sold_team_id': soldTeamId,
      'created_at': createdAt?.toIso8601String(),
      'created_by': createdBy,
    };
  }

  SupabasePlayer copyWith({
    String? id,
    String? auctionId,
    int? playerNo,
    String? name,
    String? photoBase64,
    int? age,
    String? village,
    String? category,
    String? battingStyle,
    String? bowlingStyle,
    int? matches,
    int? runs,
    int? wickets,
    int? highScore,
    double? strikeRate,
    double? economy,
    double? basePrice,
    bool? isIcon,
    bool? isOwner,
    bool? isRetained,
    String? retainedTeamId,
    String? status,
    double? soldPrice,
    String? soldTeamId,
    DateTime? createdAt,
    String? createdBy,
  }) {
    return SupabasePlayer(
      id: id ?? this.id,
      auctionId: auctionId ?? this.auctionId,
      playerNo: playerNo ?? this.playerNo,
      name: name ?? this.name,
      photoBase64: photoBase64 ?? this.photoBase64,
      age: age ?? this.age,
      village: village ?? this.village,
      category: category ?? this.category,
      battingStyle: battingStyle ?? this.battingStyle,
      bowlingStyle: bowlingStyle ?? this.bowlingStyle,
      matches: matches ?? this.matches,
      runs: runs ?? this.runs,
      wickets: wickets ?? this.wickets,
      highScore: highScore ?? this.highScore,
      strikeRate: strikeRate ?? this.strikeRate,
      economy: economy ?? this.economy,
      basePrice: basePrice ?? this.basePrice,
      isIcon: isIcon ?? this.isIcon,
      isOwner: isOwner ?? this.isOwner,
      isRetained: isRetained ?? this.isRetained,
      retainedTeamId: retainedTeamId ?? this.retainedTeamId,
      status: status ?? this.status,
      soldPrice: soldPrice ?? this.soldPrice,
      soldTeamId: soldTeamId ?? this.soldTeamId,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}
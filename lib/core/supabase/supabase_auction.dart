/// Represents the `auctions` table in Supabase.
class SupabaseAuction {
  const SupabaseAuction({
    required this.id,
    required this.name,
    this.logoBase64,
    this.venue,
    this.description,
    this.startDateTime,
    this.status,
    this.categories,
    this.numberOfTeams,
    this.minSquad,
    this.maxSquad,
    this.basePriceDefault,
    this.bidIncrement,
    this.teamPurse,
    this.countdownSeconds,
    this.mode,
    this.createdAt,
    this.contactPhone,
    this.contactEmail,
    this.categoryBasePrices,
    this.reservePurseRule,
    this.smartBidSlabs,
    this.createdBy,
  });

  /// Deserialize from a Supabase row map.
  factory SupabaseAuction.fromJson(Map<String, dynamic> json) {
    return SupabaseAuction(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Untitled Auction',
      logoBase64: json['logo_base64'] as String?,
      venue: json['venue'] as String?,
      description: json['description'] as String?,
      startDateTime: json['start_date_time'] != null
          ? DateTime.parse(json['start_date_time'] as String)
          : null,
      status: json['status'] as String?,
      categories: (json['categories'] as List?)
          ?.map((e) => e.toString())
          .toList(),
      numberOfTeams: (json['number_of_teams'] as num?)?.toInt(),
      minSquad: (json['min_squad'] as num?)?.toInt(),
      maxSquad: (json['max_squad'] as num?)?.toInt(),
      basePriceDefault: (json['base_price_default'] as num?)?.toDouble(),
      bidIncrement: (json['bid_increment'] as num?)?.toDouble(),
      teamPurse: (json['team_purse'] as num?)?.toDouble(),
      countdownSeconds: (json['countdown_seconds'] as num?)?.toInt(),
      mode: json['mode'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      contactPhone: json['contact_phone'] as String?,
      contactEmail: json['contact_email'] as String?,
      categoryBasePrices: (json['category_base_prices'] as Map?)?.map(
            (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
          ),
      reservePurseRule: json['reserve_purse_rule'] as bool?,
      smartBidSlabs: json['smart_bid_slabs'] as bool?,
      createdBy: json['created_by'] as String?,
    );
  }

  final String id;
  final String name;
  final String? logoBase64;
  final String? venue;
  final String? description;
  final DateTime? startDateTime;
  final String? status;
  final List<String>? categories;
  final int? numberOfTeams;
  final int? minSquad;
  final int? maxSquad;
  final double? basePriceDefault;
  final double? bidIncrement;
  final double? teamPurse;
  final int? countdownSeconds;
  final String? mode;
  final DateTime? createdAt;
  final String? contactPhone;
  final String? contactEmail;
  final Map<String, double>? categoryBasePrices;
  final bool? reservePurseRule;
  final bool? smartBidSlabs;
  final String? createdBy;

  /// Serialize to a JSON map for upsert operations.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'logo_base64': logoBase64,
      'venue': venue,
      'description': description,
      'start_date_time': startDateTime?.toIso8601String(),
      'status': status,
      'categories': categories,
      'number_of_teams': numberOfTeams,
      'min_squad': minSquad,
      'max_squad': maxSquad,
      'base_price_default': basePriceDefault,
      'bid_increment': bidIncrement,
      'team_purse': teamPurse,
      'countdown_seconds': countdownSeconds,
      'mode': mode,
      'created_at': createdAt?.toIso8601String(),
      'contact_phone': contactPhone,
      'contact_email': contactEmail,
      'category_base_prices': categoryBasePrices,
      'reserve_purse_rule': reservePurseRule,
      'smart_bid_slabs': smartBidSlabs,
      'created_by': createdBy,
    };
  }

  SupabaseAuction copyWith({
    String? id,
    String? name,
    String? logoBase64,
    String? venue,
    String? description,
    DateTime? startDateTime,
    String? status,
    List<String>? categories,
    int? numberOfTeams,
    int? minSquad,
    int? maxSquad,
    double? basePriceDefault,
    double? bidIncrement,
    double? teamPurse,
    int? countdownSeconds,
    String? mode,
    DateTime? createdAt,
    String? contactPhone,
    String? contactEmail,
    Map<String, double>? categoryBasePrices,
    bool? reservePurseRule,
    bool? smartBidSlabs,
    String? createdBy,
  }) {
    return SupabaseAuction(
      id: id ?? this.id,
      name: name ?? this.name,
      logoBase64: logoBase64 ?? this.logoBase64,
      venue: venue ?? this.venue,
      description: description ?? this.description,
      startDateTime: startDateTime ?? this.startDateTime,
      status: status ?? this.status,
      categories: categories ?? this.categories,
      numberOfTeams: numberOfTeams ?? this.numberOfTeams,
      minSquad: minSquad ?? this.minSquad,
      maxSquad: maxSquad ?? this.maxSquad,
      basePriceDefault: basePriceDefault ?? this.basePriceDefault,
      bidIncrement: bidIncrement ?? this.bidIncrement,
      teamPurse: teamPurse ?? this.teamPurse,
      countdownSeconds: countdownSeconds ?? this.countdownSeconds,
      mode: mode ?? this.mode,
      createdAt: createdAt ?? this.createdAt,
      contactPhone: contactPhone ?? this.contactPhone,
      contactEmail: contactEmail ?? this.contactEmail,
      categoryBasePrices: categoryBasePrices ?? this.categoryBasePrices,
      reservePurseRule: reservePurseRule ?? this.reservePurseRule,
      smartBidSlabs: smartBidSlabs ?? this.smartBidSlabs,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}
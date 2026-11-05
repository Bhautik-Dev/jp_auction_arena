import 'package:hive/hive.dart';
import 'enums.dart';

class Auction extends HiveObject {
  String id;
  String name;
  String? logoBase64;
  String venue;
  String description;
  DateTime startDateTime;
  AuctionStatus status;
  List<String> categories;
  int numberOfTeams;
  int minSquad;
  int maxSquad;
  double basePriceDefault;
  double bidIncrement;
  double teamPurse;
  int countdownSeconds;
  AuctionMode mode;
  DateTime createdAt;

  // New Wizard Fields
  String contactPhone;
  String contactEmail;
  Map<String, double> categoryBasePrices;
  bool reservePurseRule;
  bool smartBidSlabs;

  Auction({
    required this.id,
    required this.name,
    this.logoBase64,
    this.venue = '',
    this.description = '',
    required this.startDateTime,
    this.status = AuctionStatus.draft,
    List<String>? categories,
    this.numberOfTeams = 8,
    this.minSquad = 11,
    this.maxSquad = 15,
    this.basePriceDefault = 10000,
    this.bidIncrement = 2000,
    this.teamPurse = 1000000,
    this.countdownSeconds = 30,
    this.mode = AuctionMode.manual,
    DateTime? createdAt,
    this.contactPhone = '',
    this.contactEmail = '',
    Map<String, double>? categoryBasePrices,
    this.reservePurseRule = true,
    this.smartBidSlabs = false,
  })  : categories = categories ?? const ['Batsman', 'Bowler', 'All-Rounder', 'Wicket-Keeper'],
        categoryBasePrices = categoryBasePrices ?? {},
        createdAt = createdAt ?? DateTime.now();

  Auction copyWith({
    String? id,
    String? name,
    String? logoBase64,
    String? venue,
    String? description,
    DateTime? startDateTime,
    AuctionStatus? status,
    List<String>? categories,
    int? numberOfTeams,
    int? minSquad,
    int? maxSquad,
    double? basePriceDefault,
    double? bidIncrement,
    double? teamPurse,
    int? countdownSeconds,
    AuctionMode? mode,
    DateTime? createdAt,
    String? contactPhone,
    String? contactEmail,
    Map<String, double>? categoryBasePrices,
    bool? reservePurseRule,
    bool? smartBidSlabs,
  }) {
    return Auction(
      id: id ?? this.id,
      name: name ?? this.name,
      logoBase64: logoBase64 ?? this.logoBase64,
      venue: venue ?? this.venue,
      description: description ?? this.description,
      startDateTime: startDateTime ?? this.startDateTime,
      status: status ?? this.status,
      categories: categories ?? List<String>.from(this.categories),
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
      categoryBasePrices: categoryBasePrices ?? Map<String, double>.from(this.categoryBasePrices),
      reservePurseRule: reservePurseRule ?? this.reservePurseRule,
      smartBidSlabs: smartBidSlabs ?? this.smartBidSlabs,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'logoBase64': logoBase64,
      'venue': venue,
      'description': description,
      'startDateTime': startDateTime.toIso8601String(),
      'status': status.name,
      'categories': categories,
      'numberOfTeams': numberOfTeams,
      'minSquad': minSquad,
      'maxSquad': maxSquad,
      'basePriceDefault': basePriceDefault,
      'bidIncrement': bidIncrement,
      'teamPurse': teamPurse,
      'countdownSeconds': countdownSeconds,
      'mode': mode.name,
      'createdAt': createdAt.toIso8601String(),
      'contactPhone': contactPhone,
      'contactEmail': contactEmail,
      'categoryBasePrices': categoryBasePrices,
      'reservePurseRule': reservePurseRule,
      'smartBidSlabs': smartBidSlabs,
    };
  }

  factory Auction.fromMap(Map<String, dynamic> map) {
    return Auction(
      id: map['id'] as String,
      name: map['name'] as String? ?? 'Untitled Auction',
      logoBase64: map['logoBase64'] as String?,
      venue: map['venue'] as String? ?? '',
      description: map['description'] as String? ?? '',
      startDateTime: map['startDateTime'] != null
          ? DateTime.parse(map['startDateTime'] as String)
          : DateTime.now(),
      status: AuctionStatus.fromString(map['status'] as String?),
      categories: (map['categories'] as List?)?.map((e) => e.toString()).toList() ??
          ['Batsman', 'Bowler', 'All-Rounder', 'Wicket-Keeper'],
      numberOfTeams: (map['numberOfTeams'] as num?)?.toInt() ?? 8,
      minSquad: (map['minSquad'] as num?)?.toInt() ?? 11,
      maxSquad: (map['maxSquad'] as num?)?.toInt() ?? 15,
      basePriceDefault: (map['basePriceDefault'] as num?)?.toDouble() ?? 10000,
      bidIncrement: (map['bidIncrement'] as num?)?.toDouble() ?? 2000,
      teamPurse: (map['teamPurse'] as num?)?.toDouble() ?? 1000000,
      countdownSeconds: (map['countdownSeconds'] as num?)?.toInt() ?? 30,
      mode: AuctionMode.fromString(map['mode'] as String?),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      contactPhone: map['contactPhone'] as String? ?? '',
      contactEmail: map['contactEmail'] as String? ?? '',
      categoryBasePrices: (map['categoryBasePrices'] as Map?)?.map(
            (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
          ) ??
          {},
      reservePurseRule: map['reservePurseRule'] as bool? ?? true,
      smartBidSlabs: map['smartBidSlabs'] as bool? ?? false,
    );
  }
}

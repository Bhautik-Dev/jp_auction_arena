import 'package:jp_auction_arena/features/tournament/domain/models/tournament_status.dart';

class Tournament {
  const Tournament({
    required this.id,
    required this.name,
    required this.shortName,
    required this.seasonYear,
    required this.startDate,
    required this.endDate,
    required this.city,
    required this.venue,
    required this.maxTeams,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.description = '',
    this.logoReference,
    this.registrationStartDate,
    this.registrationClosingDate,
    this.format = 'Limited overs',
    this.minSquadSize = 11,
    this.maxSquadSize = 15,
    this.organizerName = '',
    this.contactDetails = '',
    this.additionalNotes = '',
    this.hasAuctionTransactions = false,
  });

  final String id;
  final String name;
  final String shortName;
  final String seasonYear;
  final DateTime startDate;
  final DateTime endDate;
  final String city;
  final String venue;
  final int maxTeams;
  final TournamentStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String description;
  final String? logoReference;
  final DateTime? registrationStartDate;
  final DateTime? registrationClosingDate;
  final String format;
  final int minSquadSize;
  final int maxSquadSize;
  final String organizerName;
  final String contactDetails;
  final String additionalNotes;
  final bool hasAuctionTransactions;

  int get numberOfParticipatingTeams => maxTeams;

  int get durationInDays => endDate.difference(startDate).inDays + 1;

  Tournament copyWith({
    String? id,
    String? name,
    String? shortName,
    String? seasonYear,
    DateTime? startDate,
    DateTime? endDate,
    String? city,
    String? venue,
    int? maxTeams,
    TournamentStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? description,
    String? logoReference,
    bool clearLogoReference = false,
    DateTime? registrationStartDate,
    DateTime? registrationClosingDate,
    String? format,
    int? minSquadSize,
    int? maxSquadSize,
    String? organizerName,
    String? contactDetails,
    String? additionalNotes,
    bool? hasAuctionTransactions,
  }) => Tournament(
    id: id ?? this.id,
    name: name ?? this.name,
    shortName: shortName ?? this.shortName,
    seasonYear: seasonYear ?? this.seasonYear,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    city: city ?? this.city,
    venue: venue ?? this.venue,
    maxTeams: maxTeams ?? this.maxTeams,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    description: description ?? this.description,
    logoReference: clearLogoReference
        ? null
        : logoReference ?? this.logoReference,
    registrationStartDate: registrationStartDate ?? this.registrationStartDate,
    registrationClosingDate:
        registrationClosingDate ?? this.registrationClosingDate,
    format: format ?? this.format,
    minSquadSize: minSquadSize ?? this.minSquadSize,
    maxSquadSize: maxSquadSize ?? this.maxSquadSize,
    organizerName: organizerName ?? this.organizerName,
    contactDetails: contactDetails ?? this.contactDetails,
    additionalNotes: additionalNotes ?? this.additionalNotes,
    hasAuctionTransactions:
        hasAuctionTransactions ?? this.hasAuctionTransactions,
  );

  Map<String, Object> toMap() => {
    'id': id,
    'name': name,
    'shortName': shortName,
    'seasonYear': seasonYear,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'city': city,
    'venue': venue,
    'maxTeams': maxTeams,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'description': description,
    'logoReference': logoReference ?? '',
    'registrationStartDate': registrationStartDate?.toIso8601String() ?? '',
    'registrationClosingDate': registrationClosingDate?.toIso8601String() ?? '',
    'format': format,
    'minSquadSize': minSquadSize,
    'maxSquadSize': maxSquadSize,
    'organizerName': organizerName,
    'contactDetails': contactDetails,
    'additionalNotes': additionalNotes,
    'hasAuctionTransactions': hasAuctionTransactions,
  };

  factory Tournament.fromMap(Map<String, Object?> map) => Tournament(
    id: map['id']! as String,
    name: map['name']! as String,
    shortName: map['shortName']! as String,
    seasonYear: map['seasonYear']! as String,
    startDate: DateTime.parse(map['startDate']! as String),
    endDate: DateTime.parse(map['endDate']! as String),
    city: map['city']! as String,
    venue: map['venue']! as String,
    maxTeams: (map['maxTeams']! as num).toInt(),
    status: TournamentStatus.values.byName(map['status']! as String),
    createdAt: DateTime.parse(map['createdAt']! as String),
    updatedAt: DateTime.parse(map['updatedAt']! as String),
    description: map['description'] as String? ?? '',
    logoReference: (map['logoReference'] as String?)?.isEmpty ?? true
        ? null
        : map['logoReference'] as String?,
    registrationStartDate:
        (map['registrationStartDate'] as String?)?.isEmpty ?? true
        ? null
        : DateTime.parse(map['registrationStartDate']! as String),
    registrationClosingDate:
        (map['registrationClosingDate'] as String?)?.isEmpty ?? true
        ? null
        : DateTime.parse(map['registrationClosingDate']! as String),
    format: map['format'] as String? ?? 'Limited overs',
    minSquadSize: (map['minSquadSize'] as num?)?.toInt() ?? 11,
    maxSquadSize: (map['maxSquadSize'] as num?)?.toInt() ?? 15,
    organizerName: map['organizerName'] as String? ?? '',
    contactDetails: map['contactDetails'] as String? ?? '',
    additionalNotes: map['additionalNotes'] as String? ?? '',
    hasAuctionTransactions: map['hasAuctionTransactions'] as bool? ?? false,
  );
}

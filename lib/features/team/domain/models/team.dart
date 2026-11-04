import 'package:jp_auction_arena/features/team/domain/models/team_status.dart';

class Team {
  const Team({
    required this.id,
    String? auctionId,
    String? tournamentId,
    required this.name,
    required this.shortName,
    required this.primaryColorValue,
    required this.secondaryColorValue,
    required this.ownerName,
    required this.managerName,
    required this.contactEmail,
    required this.contactPhone,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.logoReference,
    this.city = '',
    this.description = '',
    this.hasAuctionActivity = false,
    this.hasPlayerAssignments = false,
  }) : auctionId = auctionId ?? '',
       tournamentId = tournamentId ?? '';

  final String id;
  final String auctionId;
  // Retained for compatibility with the earlier tournament demo records.
  final String tournamentId;
  final String name;
  final String shortName;
  final int primaryColorValue;
  final int secondaryColorValue;
  final String ownerName;
  final String managerName;
  final String contactEmail;
  final String contactPhone;
  final TeamStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? logoReference;
  final String city;
  final String description;
  final bool hasAuctionActivity;
  final bool hasPlayerAssignments;

  Team copyWith({
    String? id,
    String? auctionId,
    String? tournamentId,
    String? name,
    String? shortName,
    int? primaryColorValue,
    int? secondaryColorValue,
    String? ownerName,
    String? managerName,
    String? contactEmail,
    String? contactPhone,
    TeamStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? logoReference,
    bool clearLogoReference = false,
    String? city,
    String? description,
    bool? hasAuctionActivity,
    bool? hasPlayerAssignments,
  }) => Team(
    id: id ?? this.id,
    auctionId: auctionId ?? this.auctionId,
    tournamentId: tournamentId ?? this.tournamentId,
    name: name ?? this.name,
    shortName: shortName ?? this.shortName,
    primaryColorValue: primaryColorValue ?? this.primaryColorValue,
    secondaryColorValue: secondaryColorValue ?? this.secondaryColorValue,
    ownerName: ownerName ?? this.ownerName,
    managerName: managerName ?? this.managerName,
    contactEmail: contactEmail ?? this.contactEmail,
    contactPhone: contactPhone ?? this.contactPhone,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    logoReference: clearLogoReference
        ? null
        : logoReference ?? this.logoReference,
    city: city ?? this.city,
    description: description ?? this.description,
    hasAuctionActivity: hasAuctionActivity ?? this.hasAuctionActivity,
    hasPlayerAssignments: hasPlayerAssignments ?? this.hasPlayerAssignments,
  );
}

import 'package:jp_auction_arena/features/team/domain/models/team_status.dart';

class Team {
  const Team({
    required this.id,
    required this.tournamentId,
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
    this.hasAuctionActivity = false,
    this.hasPlayerAssignments = false,
  });

  final String id;
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
  final bool hasAuctionActivity;
  final bool hasPlayerAssignments;

  Team copyWith({
    String? id,
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
    bool? hasAuctionActivity,
    bool? hasPlayerAssignments,
  }) => Team(
    id: id ?? this.id,
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
    hasAuctionActivity: hasAuctionActivity ?? this.hasAuctionActivity,
    hasPlayerAssignments: hasPlayerAssignments ?? this.hasPlayerAssignments,
  );
}

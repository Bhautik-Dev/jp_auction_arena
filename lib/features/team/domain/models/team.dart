import 'dart:typed_data';

import 'package:jp_auction_arena/features/team/domain/models/team_status.dart';

/// Image bytes selected for a team logo; data repositories can later upload it.
class TeamLogo {
  const TeamLogo({
    required this.fileName,
    required this.bytes,
    this.contentType,
  });

  final String fileName;
  final Uint8List bytes;
  final String? contentType;
}

/// A tournament-scoped team and its administrative contact information.
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
    this.logo,
    this.hasAuctionActivity = false,
    this.hasPlayerAssignments = false,
  });

  final String id;
  final String tournamentId;
  final String name;
  final String shortName;
  final TeamLogo? logo;
  final int primaryColorValue;
  final int secondaryColorValue;
  final String ownerName;
  final String managerName;
  final String contactEmail;
  final String contactPhone;
  final TeamStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// References to future auction/player modules used to protect deletion.
  final bool hasAuctionActivity;
  final bool hasPlayerAssignments;

  bool get canDelete => !hasAuctionActivity && !hasPlayerAssignments;

  String? get deletionBlockReason {
    if (hasAuctionActivity && hasPlayerAssignments) {
      return 'This team has auction activity and player assignments.';
    }
    if (hasAuctionActivity) {
      return 'This team has auction activity.';
    }
    if (hasPlayerAssignments) {
      return 'This team has player assignments.';
    }
    return null;
  }

  Team copyWith({
    String? id,
    String? tournamentId,
    String? name,
    String? shortName,
    TeamLogo? logo,
    bool clearLogo = false,
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
  }) {
    return Team(
      id: id ?? this.id,
      tournamentId: tournamentId ?? this.tournamentId,
      name: name ?? this.name,
      shortName: shortName ?? this.shortName,
      logo: clearLogo ? null : logo ?? this.logo,
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
}

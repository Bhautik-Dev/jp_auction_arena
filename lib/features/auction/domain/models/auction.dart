import 'package:jp_auction_arena/features/auction/domain/models/auction_status.dart';
import 'package:jp_auction_arena/features/auction/domain/models/auction_type.dart';
import 'package:jp_auction_arena/features/auction/domain/models/cricket_format.dart';

class Auction {
  const Auction({
    required this.id,
    required this.name,
    required this.auctionDate,
    required this.startTimeMinutes,
    required this.auctionType,
    required this.cricketFormat,
    required this.maxTeams,
    required this.maxPlayersPerTeam,
    required this.minPlayersPerTeam,
    required this.totalPursePerTeam,
    required this.baseCurrency,
    required this.status,
    required this.organizerName,
    required this.createdAt,
    required this.updatedAt,
    this.logoReference,
    this.description = '',
    this.location = '',
    this.customFormat,
    this.contactDetails = '',
  });

  final String id;
  final String name;
  final String? logoReference;
  final String description;
  final DateTime auctionDate;
  final int startTimeMinutes;
  final String location;
  final AuctionType auctionType;
  final CricketFormat cricketFormat;
  final String? customFormat;
  final int maxTeams;
  final int maxPlayersPerTeam;
  final int minPlayersPerTeam;
  final double totalPursePerTeam;
  final String baseCurrency;
  final AuctionStatus status;
  final String organizerName;
  final String contactDetails;
  final DateTime createdAt;
  final DateTime updatedAt;

  Auction copyWith({
    String? id,
    String? name,
    String? logoReference,
    bool clearLogoReference = false,
    String? description,
    DateTime? auctionDate,
    int? startTimeMinutes,
    String? location,
    AuctionType? auctionType,
    CricketFormat? cricketFormat,
    String? customFormat,
    bool clearCustomFormat = false,
    int? maxTeams,
    int? maxPlayersPerTeam,
    int? minPlayersPerTeam,
    double? totalPursePerTeam,
    String? baseCurrency,
    AuctionStatus? status,
    String? organizerName,
    String? contactDetails,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Auction(
    id: id ?? this.id,
    name: name ?? this.name,
    logoReference: clearLogoReference
        ? null
        : logoReference ?? this.logoReference,
    description: description ?? this.description,
    auctionDate: auctionDate ?? this.auctionDate,
    startTimeMinutes: startTimeMinutes ?? this.startTimeMinutes,
    location: location ?? this.location,
    auctionType: auctionType ?? this.auctionType,
    cricketFormat: cricketFormat ?? this.cricketFormat,
    customFormat: clearCustomFormat ? null : customFormat ?? this.customFormat,
    maxTeams: maxTeams ?? this.maxTeams,
    maxPlayersPerTeam: maxPlayersPerTeam ?? this.maxPlayersPerTeam,
    minPlayersPerTeam: minPlayersPerTeam ?? this.minPlayersPerTeam,
    totalPursePerTeam: totalPursePerTeam ?? this.totalPursePerTeam,
    baseCurrency: baseCurrency ?? this.baseCurrency,
    status: status ?? this.status,
    organizerName: organizerName ?? this.organizerName,
    contactDetails: contactDetails ?? this.contactDetails,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

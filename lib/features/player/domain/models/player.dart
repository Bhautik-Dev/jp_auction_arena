import 'package:jp_auction_arena/features/player/domain/models/player_category.dart';
import 'package:jp_auction_arena/features/player/domain/models/player_status.dart';

class Player {
  const Player({
    required this.id,
    required this.name,
    required this.category,
    required this.battingStyle,
    required this.bowlingStyle,
    required this.basePrice,
    required this.contactNumber,
    required this.status,
    required this.assignedTeamId,
    required this.createdAt,
    required this.updatedAt,
    this.auctionId = '',
    this.imageReference,
    this.age,
    this.matchesPlayed = 0,
    this.runsScored = 0,
    this.wicketsTaken = 0,
  });

  final String id;
  final String auctionId;
  final String name;
  final String? imageReference;
  final PlayerCategory category;
  final String battingStyle;
  final String bowlingStyle;
  final int basePrice;
  final String? contactNumber;
  final PlayerStatus status;
  final String? assignedTeamId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? age;
  final int matchesPlayed;
  final int runsScored;
  final int wicketsTaken;

  Player copyWith({
    String? id,
    String? auctionId,
    String? name,
    String? imageReference,
    PlayerCategory? category,
    String? battingStyle,
    String? bowlingStyle,
    int? basePrice,
    String? contactNumber,
    PlayerStatus? status,
    String? assignedTeamId,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? age,
    int? matchesPlayed,
    int? runsScored,
    int? wicketsTaken,
    bool clearContactNumber = false,
    bool clearAssignedTeam = false,
    bool clearImageReference = false,
  }) => Player(
    id: id ?? this.id,
    auctionId: auctionId ?? this.auctionId,
    name: name ?? this.name,
    imageReference: clearImageReference
        ? null
        : imageReference ?? this.imageReference,
    category: category ?? this.category,
    battingStyle: battingStyle ?? this.battingStyle,
    bowlingStyle: bowlingStyle ?? this.bowlingStyle,
    basePrice: basePrice ?? this.basePrice,
    contactNumber: clearContactNumber
        ? null
        : contactNumber ?? this.contactNumber,
    status: status ?? this.status,
    assignedTeamId: clearAssignedTeam
        ? null
        : assignedTeamId ?? this.assignedTeamId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    age: age ?? this.age,
    matchesPlayed: matchesPlayed ?? this.matchesPlayed,
    runsScored: runsScored ?? this.runsScored,
    wicketsTaken: wicketsTaken ?? this.wicketsTaken,
  );
}

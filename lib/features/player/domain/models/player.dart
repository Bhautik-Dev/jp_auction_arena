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
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.contactNumber,
    this.assignedTeamId,
  });

  final String id;
  final String name;
  final PlayerCategory category;
  final String battingStyle;
  final String bowlingStyle;
  final int basePrice;
  final String? contactNumber;
  final PlayerStatus status;
  final String? assignedTeamId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Player copyWith({
    String? id,
    String? name,
    PlayerCategory? category,
    String? battingStyle,
    String? bowlingStyle,
    int? basePrice,
    String? contactNumber,
    bool clearContactNumber = false,
    PlayerStatus? status,
    String? assignedTeamId,
    bool clearAssignedTeam = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
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
    );
  }
}

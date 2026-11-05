import 'package:hive/hive.dart';

class Team extends HiveObject {
  String id;
  String auctionId;
  String name;
  String? logoBase64;
  String ownerName;
  double purseTotal;
  double purseSpent;
  List<String> playerIds;

  Team({
    required this.id,
    required this.auctionId,
    required this.name,
    this.logoBase64,
    this.ownerName = '',
    required this.purseTotal,
    this.purseSpent = 0.0,
    List<String>? playerIds,
  }) : playerIds = playerIds ?? [];

  double get purseRemaining => (purseTotal - purseSpent).clamp(0.0, double.infinity);
  int get squadCount => playerIds.length;

  Team copyWith({
    String? id,
    String? auctionId,
    String? name,
    String? logoBase64,
    String? ownerName,
    double? purseTotal,
    double? purseSpent,
    List<String>? playerIds,
  }) {
    return Team(
      id: id ?? this.id,
      auctionId: auctionId ?? this.auctionId,
      name: name ?? this.name,
      logoBase64: logoBase64 ?? this.logoBase64,
      ownerName: ownerName ?? this.ownerName,
      purseTotal: purseTotal ?? this.purseTotal,
      purseSpent: purseSpent ?? this.purseSpent,
      playerIds: playerIds ?? List<String>.from(this.playerIds),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'auctionId': auctionId,
      'name': name,
      'logoBase64': logoBase64,
      'ownerName': ownerName,
      'purseTotal': purseTotal,
      'purseSpent': purseSpent,
      'playerIds': playerIds,
    };
  }

  factory Team.fromMap(Map<String, dynamic> map) {
    return Team(
      id: map['id'] as String,
      auctionId: map['auctionId'] as String? ?? '',
      name: map['name'] as String? ?? 'Team',
      logoBase64: map['logoBase64'] as String?,
      ownerName: map['ownerName'] as String? ?? '',
      purseTotal: (map['purseTotal'] as num?)?.toDouble() ?? 1000000,
      purseSpent: (map['purseSpent'] as num?)?.toDouble() ?? 0.0,
      playerIds: (map['playerIds'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

import 'package:hive/hive.dart';

class Bid extends HiveObject {
  String id;
  String auctionId;
  String playerId;
  String teamId;
  double amount;
  DateTime timestamp;

  Bid({
    required this.id,
    required this.auctionId,
    required this.playerId,
    required this.teamId,
    required this.amount,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Bid copyWith({
    String? id,
    String? auctionId,
    String? playerId,
    String? teamId,
    double? amount,
    DateTime? timestamp,
  }) {
    return Bid(
      id: id ?? this.id,
      auctionId: auctionId ?? this.auctionId,
      playerId: playerId ?? this.playerId,
      teamId: teamId ?? this.teamId,
      amount: amount ?? this.amount,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'auctionId': auctionId,
      'playerId': playerId,
      'teamId': teamId,
      'amount': amount,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory Bid.fromMap(Map<String, dynamic> map) {
    return Bid(
      id: map['id'] as String,
      auctionId: map['auctionId'] as String? ?? '',
      playerId: map['playerId'] as String? ?? '',
      teamId: map['teamId'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'] as String)
          : DateTime.now(),
    );
  }
}

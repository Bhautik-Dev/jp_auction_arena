import 'package:hive/hive.dart';
import 'enums.dart';

class Player extends HiveObject {
  String id;
  String auctionId;
  int playerNo;
  String name;
  String? photoBase64;
  int age;
  String village;
  String category;
  String battingStyle;
  String bowlingStyle;
  int matches;
  int runs;
  int wickets;
  int highScore;
  double strikeRate;
  double economy;
  double basePrice;
  bool isIcon;
  bool isOwner;
  bool isRetained;
  String? retainedTeamId;
  PlayerStatus status;
  double? soldPrice;
  String? soldTeamId;

  Player({
    required this.id,
    required this.auctionId,
    required this.playerNo,
    required this.name,
    this.photoBase64,
    this.age = 20,
    this.village = '',
    this.category = 'All-Rounder',
    this.battingStyle = 'Right Hand Bat',
    this.bowlingStyle = 'Right Arm Medium',
    this.matches = 0,
    this.runs = 0,
    this.wickets = 0,
    this.highScore = 0,
    this.strikeRate = 0.0,
    this.economy = 0.0,
    this.basePrice = 10000.0,
    this.isIcon = false,
    this.isOwner = false,
    this.isRetained = false,
    this.retainedTeamId,
    this.status = PlayerStatus.available,
    this.soldPrice,
    this.soldTeamId,
  });

  Player copyWith({
    String? id,
    String? auctionId,
    int? playerNo,
    String? name,
    String? photoBase64,
    int? age,
    String? village,
    String? category,
    String? battingStyle,
    String? bowlingStyle,
    int? matches,
    int? runs,
    int? wickets,
    int? highScore,
    double? strikeRate,
    double? economy,
    double? basePrice,
    bool? isIcon,
    bool? isOwner,
    bool? isRetained,
    String? retainedTeamId,
    PlayerStatus? status,
    double? soldPrice,
    String? soldTeamId,
  }) {
    return Player(
      id: id ?? this.id,
      auctionId: auctionId ?? this.auctionId,
      playerNo: playerNo ?? this.playerNo,
      name: name ?? this.name,
      photoBase64: photoBase64 ?? this.photoBase64,
      age: age ?? this.age,
      village: village ?? this.village,
      category: category ?? this.category,
      battingStyle: battingStyle ?? this.battingStyle,
      bowlingStyle: bowlingStyle ?? this.bowlingStyle,
      matches: matches ?? this.matches,
      runs: runs ?? this.runs,
      wickets: wickets ?? this.wickets,
      highScore: highScore ?? this.highScore,
      strikeRate: strikeRate ?? this.strikeRate,
      economy: economy ?? this.economy,
      basePrice: basePrice ?? this.basePrice,
      isIcon: isIcon ?? this.isIcon,
      isOwner: isOwner ?? this.isOwner,
      isRetained: isRetained ?? this.isRetained,
      retainedTeamId: retainedTeamId ?? this.retainedTeamId,
      status: status ?? this.status,
      soldPrice: soldPrice ?? this.soldPrice,
      soldTeamId: soldTeamId ?? this.soldTeamId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'auctionId': auctionId,
      'playerNo': playerNo,
      'name': name,
      'photoBase64': photoBase64,
      'age': age,
      'village': village,
      'category': category,
      'battingStyle': battingStyle,
      'bowlingStyle': bowlingStyle,
      'matches': matches,
      'runs': runs,
      'wickets': wickets,
      'highScore': highScore,
      'strikeRate': strikeRate,
      'economy': economy,
      'basePrice': basePrice,
      'isIcon': isIcon,
      'isOwner': isOwner,
      'isRetained': isRetained,
      'retainedTeamId': retainedTeamId,
      'status': status.name,
      'soldPrice': soldPrice,
      'soldTeamId': soldTeamId,
    };
  }

  factory Player.fromMap(Map<String, dynamic> map) {
    return Player(
      id: map['id'] as String,
      auctionId: map['auctionId'] as String? ?? '',
      playerNo: (map['playerNo'] as num?)?.toInt() ?? 1,
      name: map['name'] as String? ?? 'Player',
      photoBase64: map['photoBase64'] as String?,
      age: (map['age'] as num?)?.toInt() ?? 20,
      village: map['village'] as String? ?? '',
      category: map['category'] as String? ?? 'All-Rounder',
      battingStyle: map['battingStyle'] as String? ?? 'Right Hand Bat',
      bowlingStyle: map['bowlingStyle'] as String? ?? 'Right Arm Medium',
      matches: (map['matches'] as num?)?.toInt() ?? 0,
      runs: (map['runs'] as num?)?.toInt() ?? 0,
      wickets: (map['wickets'] as num?)?.toInt() ?? 0,
      highScore: (map['highScore'] as num?)?.toInt() ?? 0,
      strikeRate: (map['strikeRate'] as num?)?.toDouble() ?? 0.0,
      economy: (map['economy'] as num?)?.toDouble() ?? 0.0,
      basePrice: (map['basePrice'] as num?)?.toDouble() ?? 10000.0,
      isIcon: map['isIcon'] as bool? ?? false,
      isOwner: map['isOwner'] as bool? ?? false,
      isRetained: map['isRetained'] as bool? ?? false,
      retainedTeamId: map['retainedTeamId'] as String?,
      status: PlayerStatus.fromString(map['status'] as String?),
      soldPrice: (map['soldPrice'] as num?)?.toDouble(),
      soldTeamId: map['soldTeamId'] as String?,
    );
  }
}

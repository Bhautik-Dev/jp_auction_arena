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
  );
}

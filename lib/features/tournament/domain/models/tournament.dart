import 'package:jp_auction_arena/features/tournament/domain/models/tournament_status.dart';

/// Domain entity representing a Cricket Tournament in JP AUCTION ARENA.
class Tournament {
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
    this.status = TournamentStatus.draft,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Duration of the tournament in days.
  int get durationInDays => endDate.difference(startDate).inDays + 1;

  /// Creates a copy with optionally updated fields.
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
  }) {
    return Tournament(
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
  }

  /// Converts entity to Map for database persistence/JSON serialization.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'short_name': shortName,
      'season_year': seasonYear,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'city': city,
      'venue': venue,
      'max_teams': maxTeams,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Factory constructor to deserialize from Map.
  factory Tournament.fromMap(Map<String, dynamic> map) {
    return Tournament(
      id: map['id'] as String,
      name: map['name'] as String,
      shortName: map['short_name'] as String,
      seasonYear: map['season_year'] as String,
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: DateTime.parse(map['end_date'] as String),
      city: map['city'] as String,
      venue: map['venue'] as String,
      maxTeams: (map['max_teams'] as num).toInt(),
      status: TournamentStatus.fromString(map['status'] as String?),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Tournament &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          shortName == other.shortName &&
          seasonYear == other.seasonYear &&
          startDate == other.startDate &&
          endDate == other.endDate &&
          city == other.city &&
          venue == other.venue &&
          maxTeams == other.maxTeams &&
          status == other.status;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      shortName.hashCode ^
      seasonYear.hashCode ^
      startDate.hashCode ^
      endDate.hashCode ^
      city.hashCode ^
      venue.hashCode ^
      maxTeams.hashCode ^
      status.hashCode;
}

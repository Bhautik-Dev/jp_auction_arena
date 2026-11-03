import 'package:flutter_test/flutter_test.dart';
import 'package:jp_auction_arena/features/tournament/domain/models/tournament.dart';
import 'package:jp_auction_arena/features/tournament/domain/models/tournament_status.dart';

void main() {
  group('Tournament Model Tests', () {
    final now = DateTime(2026, 3, 1);
    final startDate = DateTime(2026, 4, 1);
    final endDate = DateTime(2026, 4, 15);

    final testTournament = Tournament(
      id: 'tourn_test_1',
      name: 'Premier Cricket League 2026',
      shortName: 'PCL 2026',
      seasonYear: '2026',
      startDate: startDate,
      endDate: endDate,
      city: 'Ahmedabad',
      venue: 'Narendra Modi Stadium',
      maxTeams: 8,
      status: TournamentStatus.draft,
      createdAt: now,
      updatedAt: now,
    );

    test('should calculate correct duration in days', () {
      expect(testTournament.durationInDays, 15);
    });

    test('should support copyWith', () {
      final updated = testTournament.copyWith(
        status: TournamentStatus.active,
        name: 'Updated PCL',
      );
      expect(updated.status, TournamentStatus.active);
      expect(updated.name, 'Updated PCL');
      expect(updated.id, testTournament.id);
    });

    test('should serialize to and deserialize from map', () {
      final map = testTournament.toMap();
      final fromMap = Tournament.fromMap(map);

      expect(fromMap.id, testTournament.id);
      expect(fromMap.name, testTournament.name);
      expect(fromMap.shortName, testTournament.shortName);
      expect(fromMap.seasonYear, testTournament.seasonYear);
      expect(fromMap.city, testTournament.city);
      expect(fromMap.venue, testTournament.venue);
      expect(fromMap.maxTeams, testTournament.maxTeams);
      expect(fromMap.status, testTournament.status);
    });

    test('TournamentStatus helpers work properly', () {
      expect(TournamentStatus.draft.canActivate, isTrue);
      expect(TournamentStatus.draft.canDeactivate, isFalse);

      expect(TournamentStatus.active.canDeactivate, isTrue);
      expect(TournamentStatus.active.canActivate, isFalse);

      expect(TournamentStatus.completed.canArchive, isTrue);
      expect(TournamentStatus.archived.canArchive, isFalse);
    });
  });
}

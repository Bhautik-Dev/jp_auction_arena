import 'package:flutter_test/flutter_test.dart';
import 'package:jp_auction_arena/features/tournament/data/repositories/in_memory_tournament_repository.dart';
import 'package:jp_auction_arena/features/tournament/domain/models/tournament.dart';
import 'package:jp_auction_arena/features/tournament/domain/models/tournament_status.dart';

void main() {
  group('InMemoryTournamentRepository Tests', () {
    late InMemoryTournamentRepository repository;

    setUp(() {
      repository = InMemoryTournamentRepository(simulatedDelay: Duration.zero);
    });

    test('should fetch initial pre-seeded tournaments', () async {
      final list = await repository.getTournaments();
      expect(list.isNotEmpty, isTrue);
      expect(list.length, greaterThanOrEqualTo(3));
    });

    test('should filter tournaments by status', () async {
      final activeList = await repository.getTournaments(
        status: TournamentStatus.active,
      );
      for (final t in activeList) {
        expect(t.status, TournamentStatus.active);
      }
    });

    test('should filter tournaments by search query', () async {
      final searched = await repository.getTournaments(query: 'Ahmedabad');
      expect(searched.any((t) => t.city == 'Ahmedabad'), isTrue);
    });

    test('should create a new tournament', () async {
      final created = await repository.createTournament(
        Tournament(
          id: '',
          name: 'Super T20 Championship',
          shortName: 'ST20',
          seasonYear: '2026',
          startDate: DateTime(2026, 5, 1),
          endDate: DateTime(2026, 5, 15),
          city: 'Mumbai',
          venue: 'Wankhede Stadium',
          maxTeams: 10,
          status: TournamentStatus.draft,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      expect(created.id, isNotEmpty);
      expect(created.name, 'Super T20 Championship');

      final found = await repository.getTournamentById(created.id);
      expect(found, isNotNull);
      expect(found!.id, created.id);
    });

    test('should update tournament status', () async {
      final list = await repository.getTournaments();
      final target = list.first;

      final updated = await repository.updateTournamentStatus(
        target.id,
        TournamentStatus.completed,
      );

      expect(updated.status, TournamentStatus.completed);

      final retrieved = await repository.getTournamentById(target.id);
      expect(retrieved!.status, TournamentStatus.completed);
    });

    test('should delete tournament', () async {
      final target = await repository.createTournament(
        Tournament(
          id: '',
          name: 'Temporary Draft Tournament',
          shortName: 'TDT',
          seasonYear: '2026',
          startDate: DateTime(2026, 8, 1),
          endDate: DateTime(2026, 8, 5),
          city: 'Mumbai',
          venue: '',
          maxTeams: 8,
          status: TournamentStatus.draft,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      final targetId = target.id;

      final success = await repository.deleteTournament(targetId);
      expect(success, isTrue);

      final retrieved = await repository.getTournamentById(targetId);
      expect(retrieved, isNull);
    });
  });
}

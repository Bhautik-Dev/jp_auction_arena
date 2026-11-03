import 'package:flutter_test/flutter_test.dart';
import 'package:jp_auction_arena/features/team/data/repositories/in_memory_team_repository.dart';
import 'package:jp_auction_arena/features/team/domain/errors/team_exceptions.dart';
import 'package:jp_auction_arena/features/team/domain/models/team.dart';
import 'package:jp_auction_arena/features/team/domain/models/team_status.dart';
import 'package:jp_auction_arena/features/tournament/data/repositories/in_memory_tournament_repository.dart';

void main() {
  late InMemoryTeamRepository repository;

  setUp(() {
    repository = InMemoryTeamRepository(
      tournamentRepository: InMemoryTournamentRepository(
        simulatedDelay: Duration.zero,
      ),
      simulatedDelay: Duration.zero,
    );
  });

  test('creates and updates a team', () async {
    final created = await repository.createTeam(_team());
    expect(created.id, isNotEmpty);
    expect(created.name, 'Falcons');

    final updated = await repository.updateTeam(
      created.copyWith(name: 'Thunder Falcons'),
    );
    expect(updated.name, 'Thunder Falcons');
    expect((await repository.getTeamById(created.id))?.name, 'Thunder Falcons');
  });

  test('enforces unique names and short names within a tournament', () async {
    await repository.createTeam(_team());

    await expectLater(
      repository.createTeam(_team(id: '', name: ' falcons ')),
      throwsA(isA<TeamValidationException>()),
    );
    await expectLater(
      repository.createTeam(_team(id: '', name: 'Raptors', shortName: 'FAL')),
      throwsA(isA<TeamValidationException>()),
    );

    expect(
      (await repository.createTeam(
        _team(
          id: '',
          name: 'Falcons',
          shortName: 'FAL',
          tournamentId: 'tourn_002',
        ),
      )).name,
      'Falcons',
    );
  });

  test('enforces tournament maximum team count', () async {
    for (var index = 0; index < 8; index++) {
      await repository.createTeam(
        _team(id: '', name: 'Team $index', shortName: 'T$index'),
      );
    }

    await expectLater(
      repository.createTeam(_team(id: '', name: 'Overflow', shortName: 'OF')),
      throwsA(isA<TeamCapacityExceededException>()),
    );
  });

  test('filters by tournament, status, and search query', () async {
    final falcons = await repository.createTeam(_team());
    await repository.createTeam(
      _team(
        id: '',
        name: 'Raptors',
        shortName: 'RAP',
        tournamentId: 'tourn_002',
        ownerName: 'Raptors Owner',
      ),
    );
    await repository.updateTeamStatus(falcons.id, TeamStatus.inactive);

    expect(
      (await repository.getTeams(tournamentId: 'tourn_001')).single.name,
      'Falcons',
    );
    expect(
      (await repository.getTeams(status: TeamStatus.inactive)).single.name,
      'Falcons',
    );
    expect(
      (await repository.getTeams(query: 'falcons owner')).single.name,
      'Falcons',
    );
  });

  test('blocks deletion when team has auction or player history', () async {
    final team = await repository.createTeam(_team(hasPlayerAssignments: true));

    await expectLater(
      repository.deleteTeam(team.id),
      throwsA(isA<TeamDeletionBlockedException>()),
    );
    expect(await repository.getTeamById(team.id), isNotNull);
  });
}

Team _team({
  String id = 'team_falcons',
  String tournamentId = 'tourn_001',
  String name = 'Falcons',
  String shortName = 'FAL',
  String ownerName = 'Falcons Owner',
  bool hasAuctionActivity = false,
  bool hasPlayerAssignments = false,
}) {
  final now = DateTime(2026);
  return Team(
    id: id,
    tournamentId: tournamentId,
    name: name,
    shortName: shortName,
    primaryColorValue: 0xFF123456,
    secondaryColorValue: 0xFF654321,
    ownerName: ownerName,
    managerName: 'Manager',
    contactEmail: 'owner@example.com',
    contactPhone: '5550100',
    status: TeamStatus.active,
    createdAt: now,
    updatedAt: now,
    hasAuctionActivity: hasAuctionActivity,
    hasPlayerAssignments: hasPlayerAssignments,
  );
}

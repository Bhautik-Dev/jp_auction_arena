import 'package:flutter_test/flutter_test.dart';
import 'package:jp_auction_arena/features/player/data/repositories/in_memory_player_repository.dart';
import 'package:jp_auction_arena/features/player/domain/errors/player_exceptions.dart';
import 'package:jp_auction_arena/features/player/domain/models/player.dart';
import 'package:jp_auction_arena/features/player/domain/models/player_category.dart';
import 'package:jp_auction_arena/features/player/domain/models/player_status.dart';
import 'package:jp_auction_arena/features/team/data/repositories/in_memory_team_repository.dart';
import 'package:jp_auction_arena/features/tournament/data/repositories/in_memory_tournament_repository.dart';

void main() {
  late InMemoryPlayerRepository repository;

  setUp(() {
    final tournaments = InMemoryTournamentRepository(
      simulatedDelay: Duration.zero,
    );
    final teams = InMemoryTeamRepository(
      tournamentRepository: tournaments,
      initialTeams: demoTeams,
      simulatedDelay: Duration.zero,
    );
    repository = InMemoryPlayerRepository(
      teamRepository: teams,
      simulatedDelay: Duration.zero,
    );
  });

  test('creates, retrieves, updates, and deletes a player', () async {
    final created = await repository.createPlayer(_player());
    expect(created.id, isNotEmpty);
    expect((await repository.getPlayerById(created.id))?.name, 'Riya Patel');

    final updated = await repository.updatePlayer(
      created.copyWith(
        name: 'Riya Shah',
        status: PlayerStatus.sold,
        assignedTeamId: 'team_001',
      ),
    );
    expect(updated.name, 'Riya Shah');
    expect(updated.status, PlayerStatus.sold);
    expect(updated.assignedTeamId, 'team_001');

    await expectLater(
      repository.deletePlayer(created.id),
      throwsA(isA<PlayerDeletionBlockedException>()),
    );
    await repository.updatePlayer(
      updated.copyWith(status: PlayerStatus.available, clearAssignedTeam: true),
    );
    expect(await repository.deletePlayer(created.id), isTrue);
    expect(await repository.getPlayerById(created.id), isNull);
  });

  test('filters players by name, category, and status', () async {
    await repository.createPlayer(_player());
    await repository.createPlayer(
      _player(
        name: 'Kabir Desai',
        category: PlayerCategory.bowler,
        status: PlayerStatus.unsold,
      ),
    );

    expect(
      (await repository.getPlayers(query: 'riya')).single.name,
      'Riya Patel',
    );
    expect(
      (await repository.getPlayers(
        category: PlayerCategory.bowler,
      )).single.name,
      'Kabir Desai',
    );
    expect(
      (await repository.getPlayers(status: PlayerStatus.unsold)).single.name,
      'Kabir Desai',
    );
  });

  test('rejects missing names and non-positive base prices', () async {
    await expectLater(
      repository.createPlayer(_player(name: '  ')),
      throwsA(isA<PlayerValidationException>()),
    );
    await expectLater(
      repository.createPlayer(_player(basePrice: 0)),
      throwsA(isA<PlayerValidationException>()),
    );
    await expectLater(
      repository.createPlayer(_player(basePrice: -1)),
      throwsA(isA<PlayerValidationException>()),
    );
  });

  test('accepts optional contact and team assignment', () async {
    final player = await repository.createPlayer(
      _player(contactNumber: null, assignedTeamId: null),
    );
    expect(player.contactNumber, isNull);
    expect(player.assignedTeamId, isNull);
  });

  test('rejects an assignment to an unknown team', () async {
    await expectLater(
      repository.createPlayer(_player(assignedTeamId: 'missing_team')),
      throwsA(isA<PlayerValidationException>()),
    );
  });
}

Player _player({
  String name = 'Riya Patel',
  PlayerCategory category = PlayerCategory.batsman,
  PlayerStatus status = PlayerStatus.available,
  int basePrice = 25000,
  String? contactNumber = '+91 98765 43210',
  String? assignedTeamId,
}) {
  final now = DateTime(2026, 11, 4);
  return Player(
    id: '',
    name: name,
    category: category,
    battingStyle: 'Right-hand bat',
    bowlingStyle: '',
    basePrice: basePrice,
    contactNumber: contactNumber,
    status: status,
    assignedTeamId: assignedTeamId,
    createdAt: now,
    updatedAt: now,
  );
}

import 'package:flutter_test/flutter_test.dart';
import 'package:jp_auction_arena/features/auth/domain/models/app_role.dart';
import 'package:jp_auction_arena/features/auth/domain/models/auth_user.dart';
import 'package:jp_auction_arena/features/tournament/data/repositories/in_memory_tournament_repository.dart';
import 'package:jp_auction_arena/features/tournament/domain/errors/tournament_exceptions.dart';
import 'package:jp_auction_arena/features/tournament/domain/models/tournament.dart';
import 'package:jp_auction_arena/features/tournament/domain/models/tournament_status.dart';
import 'package:jp_auction_arena/features/tournament/domain/services/tournament_management_service.dart';

void main() {
  late InMemoryTournamentRepository repository;
  late TournamentManagementService service;

  setUp(() {
    repository = InMemoryTournamentRepository(simulatedDelay: Duration.zero);
    service = TournamentManagementService(
      repository: repository,
      clock: () => DateTime(2026, 11, 4),
    );
  });

  test('creates and edits a fully configured tournament', () async {
    final created = await service.create(_admin, _tournament());
    expect(created.id, isNotEmpty);
    expect(created.createdAt, DateTime(2026, 11, 4));
    expect(created.status, TournamentStatus.draft);

    final edited = await service.update(
      _admin,
      created.copyWith(
        name: 'Updated Cup',
        description: 'Updated tournament information',
      ),
    );
    expect(edited.name, 'Updated Cup');
    expect(edited.description, 'Updated tournament information');

    final persisted = await repository.getTournamentById(created.id);
    expect(persisted?.name, 'Updated Cup');
  });

  test('validates required data, tournament dates, and squad limits', () async {
    await expectLater(
      service.create(_admin, _tournament(name: ' ')),
      throwsA(isA<TournamentValidationException>()),
    );
    await expectLater(
      service.create(_admin, _tournament(endDate: DateTime(2026, 9, 1))),
      throwsA(isA<TournamentValidationException>()),
    );
    await expectLater(
      service.create(
        _admin,
        _tournament(registrationClosingDate: DateTime(2027, 1, 2)),
      ),
      throwsA(isA<TournamentValidationException>()),
    );
    await expectLater(
      service.create(_admin, _tournament(minSquadSize: 16, maxSquadSize: 15)),
      throwsA(isA<TournamentValidationException>()),
    );
  });

  test(
    'allows one active tournament and rejects activating a second',
    () async {
      await expectLater(
        service.changeStatus(_admin, 'tourn_002', TournamentStatus.active),
        throwsA(isA<StateError>()),
      );
      expect(
        (await repository.getTournamentById('tourn_002'))?.status,
        TournamentStatus.upcoming,
      );
    },
  );

  test(
    'completes, archives, and restores a tournament with valid transitions',
    () async {
      final completed = await service.changeStatus(
        _admin,
        'tourn_001',
        TournamentStatus.completed,
      );
      expect(completed.status, TournamentStatus.completed);

      final archived = await service.changeStatus(
        _admin,
        'tourn_001',
        TournamentStatus.archived,
      );
      expect(archived.status, TournamentStatus.archived);

      await expectLater(
        service.update(_admin, archived.copyWith(name: 'Should not change')),
        throwsA(isA<TournamentTransitionException>()),
      );

      final restored = await service.changeStatus(
        _admin,
        'tourn_001',
        TournamentStatus.completed,
      );
      expect(restored.status, TournamentStatus.completed);
    },
  );

  test('rejects invalid status transitions', () async {
    await expectLater(
      service.changeStatus(_admin, 'tourn_002', TournamentStatus.completed),
      throwsA(isA<TournamentTransitionException>()),
    );
  });

  test('restricts tournament operations to assigned admin roles', () async {
    const assignedAdmin = AuthUser(
      id: 'operator',
      email: 'operator@demo.jp',
      displayName: 'Operator',
      role: AppRole.tournamentAdmin,
      tournamentIds: {'tourn_001'},
    );
    const viewer = AuthUser(
      id: 'viewer',
      email: 'viewer@demo.jp',
      displayName: 'Viewer',
      role: AppRole.publicViewer,
    );

    expect((await service.list(assignedAdmin)).map((item) => item.id), [
      'tourn_001',
    ]);
    await expectLater(
      service.getById(assignedAdmin, 'tourn_002'),
      throwsA(isA<TournamentAuthorizationException>()),
    );
    await expectLater(
      service.list(viewer),
      throwsA(isA<TournamentAuthorizationException>()),
    );
    await expectLater(
      service.create(viewer, _tournament()),
      throwsA(isA<TournamentAuthorizationException>()),
    );
  });

  test('requires archival instead of deletion for protected records', () async {
    await expectLater(
      service.delete(_admin, 'tourn_001'),
      throwsA(isA<TournamentArchiveRequiredException>()),
    );
    final transactionTournament = await repository.createTournament(
      _tournament(name: 'History-bearing event', hasAuctionTransactions: true),
    );
    await expectLater(
      service.delete(_admin, transactionTournament.id),
      throwsA(isA<TournamentArchiveRequiredException>()),
    );
  });

  test('searches and filters tournaments by status', () async {
    final found = await repository.getTournaments(query: 'Western Cricket');
    expect(found.map((item) => item.id), ['tourn_002']);
    final upcoming = await repository.getTournaments(
      status: TournamentStatus.upcoming,
    );
    expect(upcoming.map((item) => item.id), ['tourn_002']);
  });
}

const _admin = AuthUser(
  id: 'admin',
  email: 'admin@demo.jp',
  displayName: 'Admin',
  role: AppRole.superAdmin,
);

Tournament _tournament({
  String name = 'New Cricket Cup',
  DateTime? startDate,
  DateTime? endDate,
  DateTime? registrationStartDate,
  DateTime? registrationClosingDate,
  int minSquadSize = 11,
  int maxSquadSize = 15,
  bool hasAuctionTransactions = false,
}) {
  final start = startDate ?? DateTime(2027, 1, 1);
  return Tournament(
    id: '',
    name: name,
    shortName: 'NCC',
    seasonYear: '2027',
    startDate: start,
    endDate: endDate ?? DateTime(2027, 1, 10),
    city: 'Ahmedabad',
    venue: '',
    maxTeams: 8,
    status: TournamentStatus.draft,
    createdAt: DateTime(2026, 10, 1),
    updatedAt: DateTime(2026, 10, 1),
    registrationStartDate: registrationStartDate ?? DateTime(2026, 10, 1),
    registrationClosingDate: registrationClosingDate ?? DateTime(2026, 12, 15),
    format: 'T20',
    minSquadSize: minSquadSize,
    maxSquadSize: maxSquadSize,
    organizerName: 'JP Demo Organizer',
    contactDetails: 'organizer@demo.invalid',
    hasAuctionTransactions: hasAuctionTransactions,
  );
}

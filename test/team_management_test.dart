import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:jp_auction_arena/app.dart';
import 'package:jp_auction_arena/features/auction/data/repositories/in_memory_auction_repository.dart';
import 'package:jp_auction_arena/features/auction/domain/models/auction.dart';
import 'package:jp_auction_arena/features/auction/domain/models/auction_status.dart';
import 'package:jp_auction_arena/features/auction/domain/models/auction_type.dart';
import 'package:jp_auction_arena/features/auction/domain/models/cricket_format.dart';
import 'package:jp_auction_arena/features/auth/application/route_access_policy.dart';
import 'package:jp_auction_arena/features/auth/application/auth_providers.dart';
import 'package:jp_auction_arena/features/auth/data/repositories/demo_auth_repository.dart';
import 'package:jp_auction_arena/features/auth/domain/models/app_role.dart';
import 'package:jp_auction_arena/features/auth/domain/models/auth_user.dart';
import 'package:jp_auction_arena/core/routing/route_names.dart';
import 'package:jp_auction_arena/features/team/data/repositories/in_memory_team_repository.dart';
import 'package:jp_auction_arena/features/team/domain/errors/team_exceptions.dart';
import 'package:jp_auction_arena/features/team/domain/models/team.dart';
import 'package:jp_auction_arena/features/team/domain/models/team_status.dart';
import 'package:jp_auction_arena/features/team/domain/services/team_management_service.dart';
import 'package:jp_auction_arena/features/team/presentation/screens/team_detail_screen.dart';
import 'package:jp_auction_arena/features/team/presentation/screens/team_form_screen.dart';
import 'package:jp_auction_arena/features/dashboard/presentation/screens/dashboard_screen.dart';

void main() {
  late InMemoryAuctionRepository auctions;
  late InMemoryTeamRepository teams;
  late TeamManagementService service;

  setUp(() {
    auctions = InMemoryAuctionRepository(
      initialAuctions: [
        _auction('auction_one', maxTeams: 2),
        _auction('auction_two', maxTeams: 4),
      ],
    );
    teams = InMemoryTeamRepository(
      auctionRepository: auctions,
      simulatedDelay: Duration.zero,
    );
    service = TeamManagementService(
      teamRepository: teams,
      auctionRepository: auctions,
    );
  });

  test(
    'registers teams within the assigned auction and isolates duplicates',
    () async {
      final first = await service.create(_admin, _team('Falcons'));
      expect(first.auctionId, 'auction_one');

      await expectLater(
        service.create(_admin, _team(' falcons ')),
        throwsA(isA<TeamValidationException>()),
      );

      final sameNameInAnotherAuction = await service.create(
        _admin,
        _team('Falcons', auctionId: 'auction_two'),
      );
      expect(sameNameInAnotherAuction.auctionId, 'auction_two');
      expect(
        (await service.list(_admin, 'auction_one')).map((item) => item.id),
        [first.id],
      );
    },
  );

  test('enforces auction team capacity', () async {
    await service.create(_admin, _team('Falcons'));
    await service.create(_admin, _team('Raptors'));

    await expectLater(
      service.create(_admin, _team('Warriors')),
      throwsA(isA<TeamCapacityExceededException>()),
    );
  });

  test(
    'concurrent registrations cannot exceed auction team capacity',
    () async {
      final registrations = await Future.wait([
        for (var index = 0; index < 3; index++)
          () async {
            try {
              await service.create(_admin, _team('$index Team'));
              return true;
            } on TeamCapacityExceededException {
              return false;
            }
          }(),
      ]);

      expect(registrations.where((registered) => registered), hasLength(2));
      expect(await teams.getTeams(auctionId: 'auction_one'), hasLength(2));
    },
  );

  test(
    'blocks non-admin roles and operators outside assigned auctions',
    () async {
      final teamManager = _user(AppRole.teamManager, teamIds: {'team_1'});
      final publicViewer = _user(AppRole.publicViewer);
      final assignedOperator = _user(
        AppRole.tournamentAdmin,
        auctionIds: {'auction_one'},
      );
      final unassignedOperator = _user(
        AppRole.tournamentAdmin,
        auctionIds: {'auction_two'},
      );

      await expectLater(
        service.create(teamManager, _team('Falcons')),
        throwsA(isA<TeamAccessDeniedException>()),
      );
      await expectLater(
        service.create(publicViewer, _team('Falcons')),
        throwsA(isA<TeamAccessDeniedException>()),
      );
      expect(
        (await service.create(assignedOperator, _team('Falcons'))).name,
        'Falcons',
      );
      await expectLater(
        service.create(
          unassignedOperator,
          _team('Raptors', auctionId: 'auction_one'),
        ),
        throwsA(isA<TeamAccessDeniedException>()),
      );
    },
  );

  test('locks registration after auction goes live', () async {
    await auctions.updateAuctionStatus('auction_one', AuctionStatus.ready);
    await auctions.updateAuctionStatus('auction_one', AuctionStatus.live);

    await expectLater(
      service.create(_admin, _team('Falcons')),
      throwsA(isA<TeamAuctionLockedException>()),
    );
  });

  test(
    'archives and restores a team without deleting auction history',
    () async {
      final registered = await service.create(
        _admin,
        _team('Falcons', hasAuctionActivity: true),
      );
      final archived = await service.updateStatus(
        _admin,
        'auction_one',
        registered.id,
        TeamStatus.archived,
      );
      expect(archived.status, TeamStatus.archived);
      expect(
        (await service.list(_admin, 'auction_one')).single.id,
        registered.id,
      );

      await expectLater(
        teams.deleteTeam(registered.id),
        throwsA(isA<TeamDeletionBlockedException>()),
      );
      final restored = await service.updateStatus(
        _admin,
        'auction_one',
        registered.id,
        TeamStatus.inactive,
      );
      expect(restored.status, TeamStatus.inactive);
    },
  );

  test('imports and exports quoted CSV records', () async {
    const csv =
        'team_name,short_name,owner_name,manager_name,email,city,description\r\n'
        '"North, ""Stars""",NST,A Owner,A Manager,a@example.com,Surat,"Fast, bold"';
    final imported = await service.importCsv(_admin, 'auction_one', csv);

    expect(imported, hasLength(1));
    expect(imported.single.name, 'North, "Stars"');
    expect(imported.single.description, 'Fast, bold');
    final exported = await service.exportCsv(_admin, 'auction_one');
    expect(exported, contains('"North, ""Stars"""'));
  });

  test('CSV import rejects invalid batches without partial writes', () async {
    const csv =
        'team_name,short_name,owner_name,manager_name\n'
        'Falcons,FAL,Owner,Manager\n'
        'falcons,FAL2,Owner,Manager';
    await expectLater(
      service.importCsv(_admin, 'auction_one', csv),
      throwsA(isA<TeamValidationException>()),
    );
    expect(await teams.getTeams(auctionId: 'auction_one'), isEmpty);
  });

  test('team management routes enforce permissions and auction assignment', () {
    final operator = _user(
      AppRole.tournamentAdmin,
      auctionIds: {'auction_one'},
    );
    final manager = _user(AppRole.teamManager, teamIds: {'team_1'});

    expect(
      RouteAccessPolicy.canAccessPath(
        operator,
        '/app/auctions/auction_one/teams/team_1/edit',
      ),
      isTrue,
    );
    expect(
      RouteAccessPolicy.canAccessPath(
        operator,
        '/app/auctions/auction_two/teams',
      ),
      isFalse,
    );
    expect(
      RouteAccessPolicy.canAccessPath(
        manager,
        '/app/auctions/auction_one/teams',
      ),
      isFalse,
    );
  });

  testWidgets('Super Admin registers an auction team from its detail route', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final authRepository = DemoAuthRepository();
    await authRepository.signIn(
      email: 'admin@demo.jp',
      password: 'DemoAdmin!2026',
      rememberMe: false,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(authRepository)],
        child: const JpAuctionArenaApp(),
      ),
    );
    await tester.pumpAndSettle();

    final router = GoRouter.of(tester.element(find.byType(DashboardScreen)));
    router.go(RouteNames.auctionTeamCreatePath('auction_001'));
    await tester.pumpAndSettle();
    expect(find.byType(TeamFormScreen), findsOneWidget);
    expect(tester.takeException(), isNull);

    await _enter(tester, 'Team Name', 'Test Falcons');
    await _enter(tester, 'Team Short Name', 'TFL');
    await _enter(tester, 'Team Owner Name', 'Owner Example');
    await _enter(tester, 'Team Manager Name', 'Manager Example');
    await tester.tap(find.text('Save Team'));
    await tester.pumpAndSettle();

    expect(find.byType(TeamDetailScreen), findsOneWidget);
    expect(find.text('Test Falcons'), findsOneWidget);
    expect(find.text('Owner Example'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

final _admin = _user(AppRole.superAdmin);

AuthUser _user(
  AppRole role, {
  Set<String> auctionIds = const {},
  Set<String> teamIds = const {},
}) => AuthUser(
  id: 'user_${role.name}',
  email: 'demo@example.invalid',
  displayName: role.name,
  role: role,
  auctionIds: auctionIds,
  teamIds: teamIds,
);

Auction _auction(String id, {int maxTeams = 8}) {
  return _baseAuction.copyWith(id: id, maxTeams: maxTeams);
}

final _baseAuction = Auction(
  id: 'auction',
  name: 'Test Auction',
  auctionDate: DateTime(2027),
  startTimeMinutes: 600,
  auctionType: AuctionType.liveAuction,
  cricketFormat: CricketFormat.t20,
  maxTeams: 8,
  maxPlayersPerTeam: 18,
  minPlayersPerTeam: 11,
  totalPursePerTeam: 10000000,
  baseCurrency: 'INR',
  status: AuctionStatus.draft,
  organizerName: 'Test Organizer',
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

Team _team(
  String name, {
  String auctionId = 'auction_one',
  bool hasAuctionActivity = false,
}) {
  final now = DateTime(2026);
  return Team(
    id: '',
    auctionId: auctionId,
    name: name,
    shortName: name.substring(0, 3).toUpperCase(),
    primaryColorValue: 0xFF418BFF,
    secondaryColorValue: 0xFFAA8BFF,
    ownerName: 'Owner',
    managerName: 'Manager',
    contactEmail: 'owner@example.invalid',
    contactPhone: '',
    status: TeamStatus.active,
    createdAt: now,
    updatedAt: now,
    hasAuctionActivity: hasAuctionActivity,
  );
}

Future<void> _enter(WidgetTester tester, String label, String value) async {
  final field = find.widgetWithText(TextFormField, label);
  await tester.ensureVisible(field);
  await tester.enterText(field, value);
  await tester.pump();
}

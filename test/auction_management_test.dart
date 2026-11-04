import 'package:flutter_test/flutter_test.dart';
import 'package:jp_auction_arena/features/auth/application/route_access_policy.dart';
import 'package:jp_auction_arena/features/auction/data/repositories/in_memory_auction_repository.dart';
import 'package:jp_auction_arena/features/auction/domain/errors/auction_exceptions.dart';
import 'package:jp_auction_arena/features/auction/domain/models/auction.dart';
import 'package:jp_auction_arena/features/auction/domain/models/auction_status.dart';
import 'package:jp_auction_arena/features/auction/domain/models/auction_type.dart';
import 'package:jp_auction_arena/features/auction/domain/models/cricket_format.dart';
import 'package:jp_auction_arena/features/auction/domain/services/auction_management_service.dart';
import 'package:jp_auction_arena/features/auth/domain/models/app_role.dart';
import 'package:jp_auction_arena/features/auth/domain/models/auth_user.dart';

void main() {
  final admin = AuthUser(
    id: 'admin',
    email: 'admin@example.invalid',
    displayName: 'Admin',
    role: AppRole.superAdmin,
  );
  const operator = AuthUser(
    id: 'operator',
    email: 'operator@example.invalid',
    displayName: 'Operator',
    role: AppRole.tournamentAdmin,
    auctionIds: {'assigned'},
  );
  const teamManager = AuthUser(
    id: 'manager',
    email: 'team@example.invalid',
    displayName: 'Manager',
    role: AppRole.teamManager,
  );

  test(
    'creates an independent draft auction and edits its configuration',
    () async {
      final service = _service();
      final created = await service.create(admin, _auction());
      expect(created.id, isNotEmpty);
      expect(created.status, AuctionStatus.draft);
      expect(created.totalPursePerTeam, 10000000);

      final updated = await service.update(
        admin,
        created.copyWith(name: 'Updated Cup', maxTeams: 12),
      );
      expect(updated.name, 'Updated Cup');
      expect(updated.maxTeams, 12);
    },
  );

  test(
    'validates required fields, date, time, purse and squad limits',
    () async {
      final service = _service();
      await expectLater(
        service.create(admin, _auction(name: '  ')),
        throwsA(isA<AuctionValidationException>()),
      );
      await expectLater(
        service.create(admin, _auction(auctionDate: DateTime(2025, 1, 1))),
        throwsA(isA<AuctionValidationException>()),
      );
      await expectLater(
        service.create(admin, _auction(startTimeMinutes: 1440)),
        throwsA(isA<AuctionValidationException>()),
      );
      await expectLater(
        service.create(admin, _auction(totalPursePerTeam: 0)),
        throwsA(isA<AuctionValidationException>()),
      );
      await expectLater(
        service.create(admin, _auction(minPlayersPerTeam: 19)),
        throwsA(isA<AuctionValidationException>()),
      );
      await expectLater(
        service.create(admin, _auction(baseCurrency: 'dollars')),
        throwsA(isA<AuctionValidationException>()),
      );
      await expectLater(
        service.create(
          admin,
          _auction(cricketFormat: CricketFormat.custom, customFormat: ''),
        ),
        throwsA(isA<AuctionValidationException>()),
      );
    },
  );

  test(
    'only authorized admins and assigned operators can manage auctions',
    () async {
      final service = _service(
        auctions: [_auction(id: 'assigned', status: AuctionStatus.draft)],
      );
      await expectLater(
        service.create(teamManager, _auction()),
        throwsA(isA<AuctionAuthorizationException>()),
      );
      await expectLater(
        service.getById(teamManager, 'assigned'),
        throwsA(isA<AuctionAuthorizationException>()),
      );
      await expectLater(
        service.update(
          const AuthUser(
            id: 'other',
            email: 'other@example.invalid',
            displayName: 'Other Operator',
            role: AppRole.tournamentAdmin,
          ),
          _auction(id: 'assigned'),
        ),
        throwsA(isA<AuctionAuthorizationException>()),
      );
      expect((await service.list(operator)).map((item) => item.id), [
        'assigned',
      ]);
    },
  );

  test('auction routes are restricted to admins and assigned operators', () {
    expect(RouteAccessPolicy.canAccessPath(admin, '/app/auctions'), isTrue);
    expect(
      RouteAccessPolicy.canAccessPath(operator, '/app/auctions/create'),
      isTrue,
    );
    expect(
      RouteAccessPolicy.canAccessPath(operator, '/app/auctions/assigned/edit'),
      isTrue,
    );
    expect(
      RouteAccessPolicy.canAccessPath(
        operator,
        '/app/auctions/not-assigned/edit',
      ),
      isFalse,
    );
    expect(
      RouteAccessPolicy.canAccessPath(teamManager, '/app/auctions'),
      isFalse,
    );
    expect(
      RouteAccessPolicy.canAccessPath(
        const AuthUser(
          id: 'public',
          email: 'public@example.invalid',
          displayName: 'Public',
          role: AppRole.publicViewer,
        ),
        '/app/auctions',
      ),
      isFalse,
    );
    expect(RouteAccessPolicy.canAccessPath(admin, '/app/tournaments'), isFalse);
  });

  test('searches and filters independent auction records', () async {
    final repository = InMemoryAuctionRepository(
      initialAuctions: [
        _auction(id: 'one', name: 'Premier Cup', status: AuctionStatus.ready),
        _auction(
          id: 'two',
          name: 'Practice Night',
          status: AuctionStatus.draft,
          totalPursePerTeam: 5000000,
        ),
      ],
    );
    expect(
      (await repository.getAuctions(query: 'premier')).map((item) => item.id),
      ['one'],
    );
    expect(
      (await repository.getAuctions(
        status: AuctionStatus.draft,
      )).map((item) => item.id),
      ['two'],
    );
    expect(
      (await repository.getAuctionById('one'))?.totalPursePerTeam,
      isNot((await repository.getAuctionById('two'))?.totalPursePerTeam),
    );
    final first = (await repository.getAuctionById('one'))!;
    await repository.updateAuction(first.copyWith(name: 'Changed Auction'));
    expect((await repository.getAuctionById('one'))?.name, 'Changed Auction');
    expect((await repository.getAuctionById('two'))?.name, 'Practice Night');
  });

  test(
    'enforces a single Live auction and supports pause, completion, archive and restore',
    () async {
      final service = _service(
        auctions: [
          _auction(id: 'first', status: AuctionStatus.ready),
          _auction(id: 'second', status: AuctionStatus.ready),
        ],
      );
      await service.changeStatus(admin, 'first', AuctionStatus.live);
      await expectLater(
        service.changeStatus(admin, 'second', AuctionStatus.live),
        throwsA(isA<AuctionTransitionException>()),
      );
      await service.changeStatus(admin, 'first', AuctionStatus.paused);
      await service.changeStatus(admin, 'first', AuctionStatus.live);
      await service.changeStatus(admin, 'first', AuctionStatus.completed);
      await service.changeStatus(admin, 'first', AuctionStatus.archived);
      await expectLater(
        service.update(
          admin,
          _auction(id: 'first', status: AuctionStatus.archived),
        ),
        throwsA(isA<AuctionTransitionException>()),
      );
      final restored = await service.changeStatus(
        admin,
        'first',
        AuctionStatus.completed,
      );
      expect(restored.status, AuctionStatus.completed);
    },
  );

  test('does not allow editing Live auctions', () async {
    final service = _service(
      auctions: [_auction(id: 'live', status: AuctionStatus.live)],
    );
    await expectLater(
      service.update(admin, _auction(id: 'live', status: AuctionStatus.live)),
      throwsA(isA<AuctionTransitionException>()),
    );
  });
}

AuctionManagementService _service({List<Auction>? auctions}) =>
    AuctionManagementService(
      repository: InMemoryAuctionRepository(initialAuctions: auctions ?? []),
      clock: () => DateTime(2026, 11, 4, 12),
    );

Auction _auction({
  String id = '',
  String name = 'Test Auction',
  AuctionStatus status = AuctionStatus.draft,
  DateTime? auctionDate,
  int startTimeMinutes = 600,
  int maxTeams = 8,
  int maxPlayersPerTeam = 18,
  int minPlayersPerTeam = 11,
  double totalPursePerTeam = 10000000,
  String baseCurrency = 'INR',
  CricketFormat cricketFormat = CricketFormat.t20,
  String? customFormat,
}) {
  final now = DateTime(2026, 11, 4);
  return Auction(
    id: id,
    name: name,
    auctionDate: auctionDate ?? DateTime(2026, 12, 1),
    startTimeMinutes: startTimeMinutes,
    auctionType: AuctionType.liveAuction,
    cricketFormat: cricketFormat,
    customFormat: customFormat,
    maxTeams: maxTeams,
    maxPlayersPerTeam: maxPlayersPerTeam,
    minPlayersPerTeam: minPlayersPerTeam,
    totalPursePerTeam: totalPursePerTeam,
    baseCurrency: baseCurrency,
    status: status,
    organizerName: 'Test Organizer',
    createdAt: now,
    updatedAt: now,
  );
}

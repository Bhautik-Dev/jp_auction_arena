import 'package:flutter_test/flutter_test.dart';
import 'package:jp_auction_arena/features/auction/data/repositories/in_memory_auction_repository.dart';
import 'package:jp_auction_arena/features/auction/domain/models/auction.dart';
import 'package:jp_auction_arena/features/auction/domain/models/auction_status.dart';
import 'package:jp_auction_arena/features/auth/application/route_access_policy.dart';
import 'package:jp_auction_arena/features/auth/domain/models/app_role.dart';
import 'package:jp_auction_arena/features/auth/domain/models/auth_user.dart';
import 'package:jp_auction_arena/features/player/data/repositories/in_memory_player_repository.dart';
import 'package:jp_auction_arena/features/player/domain/errors/player_exceptions.dart';
import 'package:jp_auction_arena/features/player/domain/models/player.dart';
import 'package:jp_auction_arena/features/player/domain/models/player_category.dart';
import 'package:jp_auction_arena/features/player/domain/models/player_status.dart';
import 'package:jp_auction_arena/features/player/domain/services/player_management_service.dart';
import 'package:jp_auction_arena/features/team/data/repositories/in_memory_team_repository.dart';
import 'package:jp_auction_arena/features/team/domain/models/team.dart';
import 'package:jp_auction_arena/features/team/domain/models/team_status.dart';

void main() {
  late InMemoryAuctionRepository auctions;
  late InMemoryTeamRepository teams;
  late InMemoryPlayerRepository players;
  late PlayerManagementService service;

  setUp(() {
    auctions = InMemoryAuctionRepository(
      initialAuctions: [_auction('auction_one'), _auction('auction_two')],
    );
    teams = InMemoryTeamRepository(
      auctionRepository: auctions,
      simulatedDelay: Duration.zero,
    );
    players = InMemoryPlayerRepository(
      auctionRepository: auctions,
      teamRepository: teams,
      simulatedDelay: Duration.zero,
    );
    service = PlayerManagementService(
      playerRepository: players,
      auctionRepository: auctions,
    );
  });

  test('creates and isolates same-name players between auctions', () async {
    final first = await service.create(_admin, _player('Riya Patel'));
    final second = await service.create(
      _admin,
      _player('Riya Patel', auctionId: 'auction_two'),
    );

    expect(first.auctionId, 'auction_one');
    expect(second.auctionId, 'auction_two');
    expect((await service.list(_admin, 'auction_one')).map((item) => item.id), [
      first.id,
    ]);
    expect((await service.list(_admin, 'auction_two')).map((item) => item.id), [
      second.id,
    ]);
    await expectLater(
      service.create(_admin, _player(' riya patel ')),
      throwsA(isA<PlayerValidationException>()),
    );
  });

  test(
    'validates player base prices against the selected auction purse',
    () async {
      await expectLater(
        service.create(_admin, _player('Invalid price').copyWith(basePrice: 0)),
        throwsA(isA<PlayerValidationException>()),
      );
      await expectLater(
        service.create(
          _admin,
          _player('Over purse').copyWith(basePrice: 10000001),
        ),
        throwsA(isA<PlayerValidationException>()),
      );
    },
  );

  test('filters scoped registrations by query, category, and status', () async {
    final batsman = await service.create(_admin, _player('Riya Patel'));
    final bowler = await service.create(
      _admin,
      _player('Kabir Desai').copyWith(category: PlayerCategory.bowler),
    );
    await service.updateAvailability(
      _admin,
      'auction_one',
      bowler.id,
      PlayerStatus.unavailable,
    );

    expect(
      (await service.list(_admin, 'auction_one', query: 'riya')).single.id,
      batsman.id,
    );
    expect(
      (await service.list(
        _admin,
        'auction_one',
        category: PlayerCategory.bowler,
      )).single.id,
      bowler.id,
    );
    expect(
      (await service.list(
        _admin,
        'auction_one',
        status: PlayerStatus.unavailable,
      )).single.id,
      bowler.id,
    );
  });

  test(
    'imports and exports overseas classification as an optional CSV field',
    () async {
      final imported = await service.importCsv(
        _admin,
        'auction_one',
        'player_name,category,base_price,is_overseas\r\n'
            '"Overseas Star",batsman,25000,true',
      );

      expect(imported.single.isOverseas, isTrue);
      final exported = await service.exportCsv(_admin, 'auction_one');
      expect(exported, contains('is_overseas'));
      expect(exported, contains('"true"'));
    },
  );

  test('player management cannot edit a purchase price', () async {
    final player = await service.create(_admin, _player('Price Protected'));

    await expectLater(
      service.update(_admin, player.copyWith(purchasePrice: 1000)),
      throwsA(isA<PlayerValidationException>()),
    );
  });

  test('restricts player management by role and auction assignment', () async {
    final operator = _user(AppRole.tournamentAdmin, {'auction_one'});
    final unassignedOperator = _user(AppRole.tournamentAdmin, {'auction_two'});
    final teamManager = _user(AppRole.teamManager, {'auction_one'});
    final viewer = _user(AppRole.publicViewer, {'auction_one'});

    expect(
      (await service.create(operator, _player('Assigned Player'))).name,
      'Assigned Player',
    );
    await expectLater(
      service.create(unassignedOperator, _player('No Access')),
      throwsA(isA<PlayerAccessDeniedException>()),
    );
    await expectLater(
      service.create(teamManager, _player('Team Manager')),
      throwsA(isA<PlayerAccessDeniedException>()),
    );
    await expectLater(
      service.create(viewer, _player('Viewer')),
      throwsA(isA<PlayerAccessDeniedException>()),
    );
    expect(
      RouteAccessPolicy.canAccessPath(
        operator,
        '/app/auctions/auction_one/players/player_1/edit',
      ),
      isTrue,
    );
    expect(
      RouteAccessPolicy.canAccessPath(
        operator,
        '/app/auctions/auction_two/players',
      ),
      isFalse,
    );
    expect(
      RouteAccessPolicy.canAccessPath(teamManager, '/app/players'),
      isFalse,
    );
  });

  test('locks registration and edits once an auction is live', () async {
    final player = await service.create(_admin, _player('Live Lock'));
    await auctions.updateAuctionStatus('auction_one', AuctionStatus.ready);
    await auctions.updateAuctionStatus('auction_one', AuctionStatus.live);

    await expectLater(
      service.create(_admin, _player('New During Live')),
      throwsA(isA<PlayerAuctionLockedException>()),
    );
    await expectLater(
      service.updateAvailability(
        _admin,
        'auction_one',
        player.id,
        PlayerStatus.unavailable,
      ),
      throwsA(isA<PlayerAuctionLockedException>()),
    );
  });

  test(
    'availability changes are allowed but auction outcomes are protected',
    () async {
      final player = await service.create(_admin, _player('Availability'));
      final unavailable = await service.updateAvailability(
        _admin,
        'auction_one',
        player.id,
        PlayerStatus.unavailable,
      );
      expect(unavailable.status, PlayerStatus.unavailable);
      final available = await service.updateAvailability(
        _admin,
        'auction_one',
        player.id,
        PlayerStatus.available,
      );
      expect(available.status, PlayerStatus.available);
      await expectLater(
        service.updateAvailability(
          _admin,
          'auction_one',
          player.id,
          PlayerStatus.sold,
        ),
        throwsA(isA<PlayerValidationException>()),
      );
    },
  );

  test('imports quoted CSV atomically and exports auction players', () async {
    const csv =
        'player_name,category,base_price,age,batting_style\r\n'
        '"North, ""Star""",batsman,25000,24,"Right-hand, top order"';
    final imported = await service.importCsv(_admin, 'auction_one', csv);

    expect(imported, hasLength(1));
    expect(imported.single.name, 'North, "Star"');
    expect(imported.single.battingStyle, 'Right-hand, top order');
    final exported = await service.exportCsv(_admin, 'auction_one');
    expect(exported, contains('"North, ""Star"""'));

    await expectLater(
      service.importCsv(
        _admin,
        'auction_one',
        'player_name,category,base_price\nFalcons,batsman,100\nfalcons,bowler,200',
      ),
      throwsA(isA<PlayerValidationException>()),
    );
    expect(await players.getPlayers(auctionId: 'auction_one'), hasLength(1));
  });

  test('rejects team assignment from a different auction', () async {
    teams = InMemoryTeamRepository(
      auctionRepository: auctions,
      initialTeams: [_team('Foreign Team', 'auction_two')],
      simulatedDelay: Duration.zero,
    );
    players = InMemoryPlayerRepository(
      auctionRepository: auctions,
      teamRepository: teams,
      simulatedDelay: Duration.zero,
    );
    service = PlayerManagementService(
      playerRepository: players,
      auctionRepository: auctions,
    );
    await expectLater(
      players.createPlayer(
        _player(
          'Cross Auction Assignment',
        ).copyWith(assignedTeamId: 'team_foreign'),
      ),
      throwsA(isA<PlayerValidationException>()),
    );
  });

  test('retains players with auction results from deletion', () async {
    final resultRepository = InMemoryPlayerRepository(
      auctionRepository: auctions,
      teamRepository: teams,
      initialPlayers: [
        _player(
          'Sold Player',
        ).copyWith(id: 'player_sold', status: PlayerStatus.sold),
      ],
      simulatedDelay: Duration.zero,
    );
    final resultService = PlayerManagementService(
      playerRepository: resultRepository,
      auctionRepository: auctions,
    );
    await expectLater(
      resultService.delete(_admin, 'auction_one', 'player_sold'),
      throwsA(isA<PlayerDeletionBlockedException>()),
    );
  });
}

AuthUser _user(AppRole role, Set<String> auctionIds) => AuthUser(
  id: 'user_${role.name}',
  email: 'demo@example.invalid',
  displayName: role.name,
  role: role,
  auctionIds: auctionIds,
);

final _admin = _user(AppRole.superAdmin, const {});

Auction _auction(String id) =>
    demoAuctions.first.copyWith(id: id, status: AuctionStatus.draft);

Player _player(String name, {String auctionId = 'auction_one'}) {
  final now = DateTime(2026, 11, 4);
  return Player(
    id: '',
    auctionId: auctionId,
    name: name,
    category: PlayerCategory.batsman,
    battingStyle: 'Right-hand bat',
    bowlingStyle: '',
    basePrice: 25000,
    contactNumber: null,
    status: PlayerStatus.available,
    assignedTeamId: null,
    createdAt: now,
    updatedAt: now,
  );
}

Team _team(String name, String auctionId) => Team(
  id: 'team_foreign',
  auctionId: auctionId,
  name: name,
  shortName: 'FRT',
  primaryColorValue: 0xFF418BFF,
  secondaryColorValue: 0xFFAA8BFF,
  ownerName: 'Owner',
  managerName: 'Manager',
  contactEmail: '',
  contactPhone: '',
  status: TeamStatus.active,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

import 'package:flutter_test/flutter_test.dart';
import 'package:jp_auction_arena/features/auction/data/repositories/in_memory_auction_repository.dart';
import 'package:jp_auction_arena/features/auction/data/repositories/in_memory_auction_rule_set_repository.dart';
import 'package:jp_auction_arena/features/auction/domain/models/auction.dart';
import 'package:jp_auction_arena/features/auction/domain/models/auction_rule_set.dart';
import 'package:jp_auction_arena/features/auction/domain/models/auction_status.dart';
import 'package:jp_auction_arena/features/auction/domain/models/auction_type.dart';
import 'package:jp_auction_arena/features/auction/domain/models/cricket_format.dart';
import 'package:jp_auction_arena/features/auth/domain/models/app_role.dart';
import 'package:jp_auction_arena/features/auth/domain/models/auth_user.dart';
import 'package:jp_auction_arena/features/player/data/repositories/in_memory_player_repository.dart';
import 'package:jp_auction_arena/features/player/domain/models/player.dart';
import 'package:jp_auction_arena/features/player/domain/models/player_category.dart';
import 'package:jp_auction_arena/features/player/domain/models/player_status.dart';
import 'package:jp_auction_arena/features/team/data/repositories/in_memory_team_purse_repository.dart';
import 'package:jp_auction_arena/features/team/data/repositories/in_memory_team_repository.dart';
import 'package:jp_auction_arena/features/team/domain/errors/team_exceptions.dart';
import 'package:jp_auction_arena/features/team/domain/models/purse_adjustment.dart';
import 'package:jp_auction_arena/features/team/domain/models/team.dart';
import 'package:jp_auction_arena/features/team/domain/models/team_status.dart';
import 'package:jp_auction_arena/features/team/domain/services/team_purse_squad_service.dart';

void main() {
  late InMemoryAuctionRepository auctions;
  late InMemoryAuctionRuleSetRepository rules;
  late InMemoryTeamRepository teams;
  late InMemoryPlayerRepository players;
  late InMemoryTeamPurseRepository purses;
  late TeamPurseSquadService service;

  setUp(() {
    auctions = InMemoryAuctionRepository(
      initialAuctions: [
        _auction('auction_one', purse: 10000, maxPlayers: 3),
        _auction('auction_two', purse: 30000, maxPlayers: 4),
      ],
    );
    rules = InMemoryAuctionRuleSetRepository(
      auctionRepository: auctions,
      initialRules: {
        'auction_one': const AuctionRuleSet(
          auctionId: 'auction_one',
          bidIncrementTiers: [],
          allowUnsoldPlayerReentry: false,
          categoryMaximums: {PlayerCategory.batsman: 1},
          maximumOverseasPlayers: 1,
          maximumWicketkeepers: 0,
        ),
      },
    );
    teams = InMemoryTeamRepository(
      auctionRepository: auctions,
      simulatedDelay: Duration.zero,
      initialTeams: [
        _team('team_one', 'auction_one'),
        _team('team_two', 'auction_two'),
      ],
    );
    players = InMemoryPlayerRepository(
      auctionRepository: auctions,
      teamRepository: teams,
      simulatedDelay: Duration.zero,
      initialPlayers: [
        _player(
          'purchased_one',
          auctionId: 'auction_one',
          teamId: 'team_one',
          status: PlayerStatus.sold,
          category: PlayerCategory.batsman,
          purchasePrice: 3000,
          isOverseas: true,
        ),
        _player(
          'purchased_two',
          auctionId: 'auction_two',
          teamId: 'team_two',
          status: PlayerStatus.sold,
          purchasePrice: 5000,
        ),
        _player('available', auctionId: 'auction_one'),
        _player(
          'available_overseas',
          auctionId: 'auction_one',
          isOverseas: true,
          category: PlayerCategory.allRounder,
        ),
        _player(
          'available_batsman',
          auctionId: 'auction_one',
          category: PlayerCategory.batsman,
        ),
        _player(
          'available_wicketkeeper',
          auctionId: 'auction_one',
          category: PlayerCategory.wicketKeeper,
        ),
      ],
    );
    purses = InMemoryTeamPurseRepository();
    service = TeamPurseSquadService(
      purseRepository: purses,
      teamRepository: teams,
      playerRepository: players,
      auctionRepository: auctions,
      ruleRepository: rules,
      clock: () => DateTime(2026, 11, 1, 12),
    );
  });

  test(
    'calculates the initial, spent, and remaining purse per auction',
    () async {
      final first = await service.getSnapshot(
        _admin,
        auctionId: 'auction_one',
        teamId: 'team_one',
      );
      final second = await service.getSnapshot(
        _admin,
        auctionId: 'auction_two',
        teamId: 'team_two',
      );

      expect(first.purse.initialPurse, 10000);
      expect(first.purse.totalSpent, 3000);
      expect(first.purse.remainingPurse, 7000);
      expect(first.purse.purchasedPlayerCount, 1);
      expect(second.purse.initialPurse, 30000);
      expect(second.purse.totalSpent, 5000);
      expect(second.purse.remainingPurse, 25000);
    },
  );

  test('records purse adjustments with reason, actor, and timestamp', () async {
    final adjustment = await service.adjustInitialPurse(
      _admin,
      auctionId: 'auction_one',
      teamId: 'team_one',
      amount: 1000,
      reason: 'Approved sponsor increase',
    );
    final first = await service.getSnapshot(
      _admin,
      auctionId: 'auction_one',
      teamId: 'team_one',
    );
    final second = await service.getSnapshot(
      _admin,
      auctionId: 'auction_two',
      teamId: 'team_two',
    );

    expect(adjustment.actorId, _admin.id);
    expect(adjustment.createdAt, DateTime(2026, 11, 1, 12));
    expect(first.purse.adjustedInitialPurse, 11000);
    expect(first.purse.remainingPurse, 8000);
    expect(first.purse.adjustments, hasLength(1));
    expect(second.purse.remainingPurse, 25000);
    expect(second.purse.adjustments, isEmpty);
  });

  test('does not allow adjustments below recorded spend', () async {
    await expectLater(
      service.adjustInitialPurse(
        _admin,
        auctionId: 'auction_one',
        teamId: 'team_one',
        amount: -8000,
        reason: 'Invalid reduction',
      ),
      throwsA(isA<TeamValidationException>()),
    );
    await expectLater(
      service.adjustInitialPurse(
        _admin,
        auctionId: 'auction_one',
        teamId: 'team_one',
        amount: 0,
        reason: 'Zero',
      ),
      throwsA(isA<TeamValidationException>()),
    );
    await expectLater(
      service.adjustInitialPurse(
        _admin,
        auctionId: 'auction_one',
        teamId: 'team_one',
        amount: 1,
        reason: ' ',
      ),
      throwsA(isA<TeamValidationException>()),
    );
  });

  test('serializes purse changes against the minimum balance', () async {
    await purses.getInitialPurse(
      auctionId: 'concurrent',
      teamId: 'team',
      defaultAmount: 1000,
    );
    final writes = await Future.wait([
      for (var index = 0; index < 2; index++)
        () async {
          try {
            await purses.addAdjustment(
              _adjustment(-200, 'concurrent', 'team'),
              minimumEffectiveInitialPurse: 700,
            );
            return true;
          } on TeamValidationException {
            return false;
          }
        }(),
    ]);

    expect(writes.where((written) => written), hasLength(1));
    expect(
      (await purses.getAdjustments(
        auctionId: 'concurrent',
        teamId: 'team',
      )).length,
      1,
    );
  });

  test(
    'authorizes team owners only for assigned read-only team data',
    () async {
      const manager = AuthUser(
        id: 'manager',
        email: 'manager@example.invalid',
        displayName: 'Manager',
        role: AppRole.teamManager,
        teamIds: {'team_one'},
      );
      final own = await service.getSnapshot(
        manager,
        auctionId: 'auction_one',
        teamId: 'team_one',
      );
      expect(own.team.id, 'team_one');

      await expectLater(
        service.getSnapshot(
          manager,
          auctionId: 'auction_two',
          teamId: 'team_two',
        ),
        throwsA(isA<TeamAccessDeniedException>()),
      );
      await expectLater(
        service.adjustInitialPurse(
          manager,
          auctionId: 'auction_one',
          teamId: 'team_one',
          amount: 100,
          reason: 'Unauthorized',
        ),
        throwsA(isA<TeamAccessDeniedException>()),
      );
      await expectLater(
        service.adjustInitialPurse(
          _user(AppRole.tournamentAdmin, auctionIds: {'auction_two'}),
          auctionId: 'auction_one',
          teamId: 'team_one',
          amount: 100,
          reason: 'Wrong auction',
        ),
        throwsA(isA<TeamAccessDeniedException>()),
      );
      await expectLater(
        service.getSnapshot(
          _user(AppRole.publicViewer),
          auctionId: 'auction_one',
          teamId: 'team_one',
        ),
        throwsA(isA<TeamAccessDeniedException>()),
      );
    },
  );

  test('validates purse, squad, and configured category limits', () async {
    final batsman = await players.getPlayerById('available_batsman');
    final overseas = await players.getPlayerById('available_overseas');
    final wicketkeeper = await players.getPlayerById('available_wicketkeeper');
    final allRounder = await players.getPlayerById('available');

    await expectLater(
      service.validatePurchase(
        actor: _admin,
        auctionId: 'auction_one',
        teamId: 'team_one',
        player: allRounder!,
        purchasePrice: 8000,
      ),
      throwsA(isA<TeamValidationException>()),
    );
    await expectLater(
      service.validatePurchase(
        actor: _admin,
        auctionId: 'auction_one',
        teamId: 'team_one',
        player: batsman!,
        purchasePrice: 1000,
      ),
      throwsA(isA<TeamValidationException>()),
    );
    await expectLater(
      service.validatePurchase(
        actor: _admin,
        auctionId: 'auction_one',
        teamId: 'team_one',
        player: overseas!,
        purchasePrice: 1000,
      ),
      throwsA(isA<TeamValidationException>()),
    );
    await expectLater(
      service.validatePurchase(
        actor: _admin,
        auctionId: 'auction_one',
        teamId: 'team_one',
        player: wicketkeeper!,
        purchasePrice: 1000,
      ),
      throwsA(isA<TeamValidationException>()),
    );
    await expectLater(
      service.validatePurchase(
        actor: _admin,
        auctionId: 'auction_one',
        teamId: 'team_one',
        player: allRounder,
        purchasePrice: 0,
      ),
      throwsA(isA<TeamValidationException>()),
    );
    await expectLater(
      service.validatePurchase(
        actor: _user(AppRole.teamManager, teamIds: {'team_one'}),
        auctionId: 'auction_one',
        teamId: 'team_one',
        player: allRounder,
        purchasePrice: 1000,
      ),
      throwsA(isA<TeamAccessDeniedException>()),
    );
  });

  test('enforces max squad size and duplicate player registration', () async {
    await players.createPlayer(
      _player(
        'extra_one',
        auctionId: 'auction_one',
        teamId: 'team_one',
        status: PlayerStatus.sold,
        purchasePrice: 1000,
      ),
    );
    await players.createPlayer(
      _player(
        'extra_two',
        auctionId: 'auction_one',
        teamId: 'team_one',
        status: PlayerStatus.sold,
        purchasePrice: 1000,
      ),
    );
    final available = (await players.getPlayerById('available'))!;
    await expectLater(
      service.validatePurchase(
        actor: _admin,
        auctionId: 'auction_one',
        teamId: 'team_one',
        player: available,
        purchasePrice: 1000,
      ),
      throwsA(isA<TeamValidationException>()),
    );

    final duplicateService = TeamPurseSquadService(
      purseRepository: InMemoryTeamPurseRepository(),
      teamRepository: teams,
      playerRepository: InMemoryPlayerRepository(
        auctionRepository: auctions,
        teamRepository: teams,
        simulatedDelay: Duration.zero,
        initialPlayers: [
          available,
          available.copyWith(name: 'Duplicate Record'),
        ],
      ),
      auctionRepository: auctions,
      ruleRepository: rules,
    );
    await expectLater(
      duplicateService.validatePurchase(
        actor: _admin,
        auctionId: 'auction_one',
        teamId: 'team_one',
        player: available,
        purchasePrice: 1000,
      ),
      throwsA(isA<TeamValidationException>()),
    );
  });

  test(
    'locks purse edits after Live but allows validation during Live',
    () async {
      await auctions.updateAuctionStatus('auction_one', AuctionStatus.live);
      await expectLater(
        service.adjustInitialPurse(
          _admin,
          auctionId: 'auction_one',
          teamId: 'team_one',
          amount: 100,
          reason: 'Live change',
        ),
        throwsA(isA<TeamAuctionLockedException>()),
      );
      await service.validatePurchase(
        actor: _admin,
        auctionId: 'auction_one',
        teamId: 'team_one',
        player: (await players.getPlayerById('available'))!,
        purchasePrice: 1000,
      );
    },
  );

  test(
    'lists all teams only to operators with access to that auction',
    () async {
      final snapshots = await service.getAuctionSnapshots(
        _user(AppRole.tournamentAdmin, auctionIds: {'auction_one'}),
        auctionId: 'auction_one',
      );
      expect(snapshots.map((snapshot) => snapshot.team.id), ['team_one']);
      await expectLater(
        service.getAuctionSnapshots(
          _user(AppRole.tournamentAdmin, auctionIds: {'auction_two'}),
          auctionId: 'auction_one',
        ),
        throwsA(isA<TeamAccessDeniedException>()),
      );
    },
  );
}

AuthUser get _admin => const AuthUser(
  id: 'admin',
  email: 'admin@example.invalid',
  displayName: 'Admin',
  role: AppRole.superAdmin,
);

AuthUser _user(
  AppRole role, {
  Set<String> auctionIds = const {},
  Set<String> teamIds = const {},
}) => AuthUser(
  id: '${role.name}_user',
  email: '${role.name}@example.invalid',
  displayName: role.name,
  role: role,
  auctionIds: auctionIds,
  teamIds: teamIds,
);

Auction _auction(String id, {required int purse, required int maxPlayers}) =>
    Auction(
      id: id,
      name: 'Auction $id',
      auctionDate: DateTime(2027),
      startTimeMinutes: 600,
      auctionType: AuctionType.liveAuction,
      cricketFormat: CricketFormat.t20,
      maxTeams: 8,
      maxPlayersPerTeam: maxPlayers,
      minPlayersPerTeam: 1,
      totalPursePerTeam: purse.toDouble(),
      baseCurrency: 'INR',
      status: AuctionStatus.ready,
      organizerName: 'Organizer',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

Team _team(String id, String auctionId) => Team(
  id: id,
  auctionId: auctionId,
  name: 'Team $id',
  shortName: id.toUpperCase(),
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

Player _player(
  String id, {
  String auctionId = 'auction_one',
  String? teamId,
  PlayerStatus status = PlayerStatus.available,
  PlayerCategory category = PlayerCategory.allRounder,
  int? purchasePrice,
  bool isOverseas = false,
}) => Player(
  id: id,
  auctionId: auctionId,
  name: 'Player $id',
  category: category,
  battingStyle: 'Right-hand bat',
  bowlingStyle: 'Right-arm medium',
  basePrice: 1000,
  contactNumber: null,
  status: status,
  assignedTeamId: teamId,
  purchasePrice: purchasePrice,
  isOverseas: isOverseas,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

PurseAdjustment _adjustment(int amount, String auctionId, String teamId) =>
    PurseAdjustment(
      auctionId: auctionId,
      teamId: teamId,
      amount: amount,
      reason: 'Concurrent test adjustment',
      actorId: 'admin',
      createdAt: DateTime(2026),
    );

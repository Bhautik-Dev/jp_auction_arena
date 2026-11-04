import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jp_auction_arena/features/auction/domain/models/auction.dart';
import 'package:jp_auction_arena/features/auction/domain/models/auction_status.dart';
import 'package:jp_auction_arena/features/auction/domain/models/auction_type.dart';
import 'package:jp_auction_arena/features/auction/domain/models/cricket_format.dart';
import 'package:jp_auction_arena/features/player/domain/models/player_category.dart';
import 'package:jp_auction_arena/features/team/domain/models/team.dart';
import 'package:jp_auction_arena/features/team/domain/models/team_purse_account.dart';
import 'package:jp_auction_arena/features/team/domain/models/team_squad_snapshot.dart';
import 'package:jp_auction_arena/features/team/domain/models/team_status.dart';
import 'package:jp_auction_arena/features/team/presentation/widgets/team_purse_squad_panel.dart';

void main() {
  testWidgets('renders a read-only purse and squad dashboard on mobile width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: TeamPurseSquadPanel(
              snapshot: _snapshot(),
              canAdjustPurse: false,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Initial purse'), findsOneWidget);
    expect(find.text('Spent'), findsOneWidget);
    expect(find.text('Remaining'), findsOneWidget);
    expect(find.text('Squad composition'), findsOneWidget);
    expect(find.text('Purchased players'), findsOneWidget);
    expect(
      find.text('No sold player assignments are recorded for this team.'),
      findsOneWidget,
    );
    expect(find.byTooltip('Record purse adjustment'), findsNothing);
    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(1280, 800);
    await tester.pumpAndSettle();
    expect(find.text('Remaining'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

TeamSquadSnapshot _snapshot() {
  final now = DateTime(2026, 11, 1);
  final auction = Auction(
    id: 'auction_one',
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
    status: AuctionStatus.ready,
    organizerName: 'Organizer',
    createdAt: now,
    updatedAt: now,
  );
  final team = Team(
    id: 'team_one',
    auctionId: auction.id,
    name: 'Test Falcons',
    shortName: 'TF',
    primaryColorValue: 0xFF418BFF,
    secondaryColorValue: 0xFFAA8BFF,
    ownerName: 'Owner',
    managerName: 'Manager',
    contactEmail: '',
    contactPhone: '',
    status: TeamStatus.active,
    createdAt: now,
    updatedAt: now,
  );
  return TeamSquadSnapshot(
    auction: auction,
    team: team,
    purse: TeamPurseAccount(
      auctionId: auction.id,
      teamId: team.id,
      initialPurse: 10000000,
      adjustments: const [],
      totalSpent: 0,
      purchasedPlayerCount: 0,
      lastUpdatedAt: now,
      hasUnpricedPurchase: false,
    ),
    purchasedPlayers: const [],
    categoryCounts: {for (final category in PlayerCategory.values) category: 0},
    warnings: const ['Minimum squad requirement not yet met.'],
    lastUpdatedAt: now,
  );
}

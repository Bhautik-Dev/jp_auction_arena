import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jp_auction_arena/data/models/models.dart';
import 'package:jp_auction_arena/data/repositories/repositories.dart';
import 'package:jp_auction_arena/features/analytics/analytics_screen.dart';

void main() {
  testWidgets('AnalyticsScreen renders all key metric cards and charts', (tester) async {
    final testAuction = Auction(
      id: 'auc_test_1',
      name: 'Premier T20 League 2026',
      status: AuctionStatus.live,
      startDateTime: DateTime.now(),
      teamPurse: 10000000,
      bidIncrement: 50000,
      minSquad: 11,
      maxSquad: 18,
      createdAt: DateTime.now(),
    );

    final testTeams = [
      Team(
        id: 'team_1',
        auctionId: 'auc_test_1',
        name: 'Mumbai Titans',
        purseTotal: 10000000,
        purseSpent: 3500000,
      ),
      Team(
        id: 'team_2',
        auctionId: 'auc_test_1',
        name: 'Gujarat Gladiators',
        purseTotal: 10000000,
        purseSpent: 4200000,
      ),
    ];

    final testPlayers = [
      Player(
        id: 'p_1',
        auctionId: 'auc_test_1',
        playerNo: 1,
        name: 'Virat Sharma',
        category: 'Batsman',
        village: 'Ahmedabad',
        strikeRate: 145.5,
        basePrice: 200000,
        soldPrice: 1500000,
        status: PlayerStatus.sold,
        soldTeamId: 'team_1',
      ),
      Player(
        id: 'p_2',
        auctionId: 'auc_test_1',
        playerNo: 2,
        name: 'Jasprit Bumrah',
        category: 'Bowler',
        village: 'Surat',
        strikeRate: 85.0,
        basePrice: 200000,
        soldPrice: 2000000,
        status: PlayerStatus.sold,
        soldTeamId: 'team_2',
      ),
      Player(
        id: 'p_3',
        auctionId: 'auc_test_1',
        playerNo: 3,
        name: 'Hardik Patel',
        category: 'All-Rounder',
        village: 'Baroda',
        strikeRate: 155.0,
        basePrice: 150000,
        status: PlayerStatus.available,
      ),
    ];

    final testBids = [
      Bid(
        id: 'b_1',
        auctionId: 'auc_test_1',
        playerId: 'p_1',
        teamId: 'team_1',
        amount: 500000,
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      Bid(
        id: 'b_2',
        auctionId: 'auc_test_1',
        playerId: 'p_1',
        teamId: 'team_2',
        amount: 1000000,
        timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
      ),
      Bid(
        id: 'b_3',
        auctionId: 'auc_test_1',
        playerId: 'p_1',
        teamId: 'team_1',
        amount: 1500000,
        timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
      ),
    ];

    await tester.binding.setSurfaceSize(const Size(1280, 1024));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          auctionsListProvider.overrideWith((ref) => Stream.value([testAuction])),
          activeAuctionProvider.overrideWithValue(testAuction),
          currentAuctionTeamsProvider.overrideWith((ref) => Stream.value(testTeams)),
          currentAuctionPlayersProvider.overrideWith((ref) => Stream.value(testPlayers)),
          currentAuctionBidsProvider.overrideWith((ref) => Stream.value(testBids)),
        ],
        child: const MaterialApp(
          home: AnalyticsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Title & Top controls
    expect(find.text('Auction Analytics & Insights'), findsOneWidget);
    expect(find.text('Export Analytics'), findsOneWidget);

    // Verify Cards
    expect(find.text('Total Auction Value'), findsOneWidget);
    expect(find.text('Average Player Price'), findsOneWidget);
    expect(find.text('Highest Bid'), findsOneWidget);
    expect(find.text('Lowest Bid'), findsOneWidget);
    expect(find.text('Total Bids Placed'), findsOneWidget);
    expect(find.text('Players Sold'), findsOneWidget);
    expect(find.text('2/3'), findsOneWidget); // 2 of 3 sold

    // Verify Charts
    expect(find.text('Team Spending Comparison'), findsOneWidget);
    expect(find.text('Category Spending & Count'), findsOneWidget);
    expect(find.text('Bid Activity Timeline'), findsOneWidget);
    expect(find.text('Purse Left vs Spent Donut'), findsOneWidget);

    // Verify New features
    expect(find.text('Bidding War Meter & Speed Records'), findsOneWidget);
    expect(find.text('Most Bids on Player'), findsOneWidget);
    expect(find.text('Fastest Sold'), findsOneWidget);
    expect(find.text('Squad Balance & Village Demographics'), findsOneWidget);
    expect(find.text('Price vs Strike Rate Scatter Chart'), findsOneWidget);
  });
}

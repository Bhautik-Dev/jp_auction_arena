import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:jp_auction_arena/app.dart';
import 'package:jp_auction_arena/data/models/models.dart';
import 'package:jp_auction_arena/data/repositories/repositories.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Use path URL strategy for Flutter Web so GoRouter navigation matches cleanly
  if (kIsWeb) {
    usePathUrlStrategy();
  }

  // Initialize local offline Hive database (Web and Android support)
  await HiveBoxes.init();

  // Seed sample initial tournament if empty
  await _seedInitialDataIfEmpty();

  runApp(const ProviderScope(child: JpAuctionArenaApp()));
}

Future<void> _seedInitialDataIfEmpty() async {
  final auctionRepo = HiveAuctionRepository();
  final existing = auctionRepo.getAll();
  if (existing.isNotEmpty) return;

  final sampleAuction = Auction(
    id: 'auc_demo_2026',
    name: 'JP Premier Cricket League 2026',
    venue: 'Arena Cricket Ground',
    description: 'Premier regional tournament auction with 8 franchise teams.',
    startDateTime: DateTime.now().add(const Duration(days: 2)),
    status: AuctionStatus.live,
    numberOfTeams: 8,
    minSquad: 11,
    maxSquad: 15,
    basePriceDefault: 10000,
    bidIncrement: 2000,
    teamPurse: 1000000,
    countdownSeconds: 30,
    mode: AuctionMode.manual,
  );
  await auctionRepo.save(sampleAuction);

  final teamRepo = HiveTeamRepository();
  final teams = [
    Team(id: 'tm_1', auctionId: sampleAuction.id, name: 'Royal Strikers', ownerName: 'Jay Patel', purseTotal: 1000000),
    Team(id: 'tm_2', auctionId: sampleAuction.id, name: 'Thunderbolts XI', ownerName: 'Priya Sharma', purseTotal: 1000000),
    Team(id: 'tm_3', auctionId: sampleAuction.id, name: 'Gujarat Gladiators', ownerName: 'Karan Shah', purseTotal: 1000000),
    Team(id: 'tm_4', auctionId: sampleAuction.id, name: 'Mumbai Blasters', ownerName: 'Amit Verma', purseTotal: 1000000),
  ];
  for (final t in teams) {
    await teamRepo.save(t);
  }

  final playerRepo = HivePlayerRepository();
  final players = [
    Player(
      id: 'pl_1',
      auctionId: sampleAuction.id,
      playerNo: 1,
      name: 'Hardik Raval',
      village: 'Ahmedabad',
      category: 'All-Rounder',
      battingStyle: 'Right Hand Bat',
      bowlingStyle: 'Right Arm Medium Fast',
      matches: 45,
      runs: 1250,
      wickets: 38,
      strikeRate: 148.5,
      basePrice: 20000,
      isIcon: true,
      status: PlayerStatus.available,
    ),
    Player(
      id: 'pl_2',
      auctionId: sampleAuction.id,
      playerNo: 2,
      name: 'Rohit Parmar',
      village: 'Vadodara',
      category: 'Batsman',
      battingStyle: 'Right Hand Bat',
      bowlingStyle: 'Right Arm Off Break',
      matches: 52,
      runs: 1820,
      wickets: 4,
      strikeRate: 139.2,
      basePrice: 15000,
      isIcon: false,
      status: PlayerStatus.available,
    ),
    Player(
      id: 'pl_3',
      auctionId: sampleAuction.id,
      playerNo: 3,
      name: 'Jaspreet Solanki',
      village: 'Rajkot',
      category: 'Bowler',
      battingStyle: 'Right Hand Bat',
      bowlingStyle: 'Right Arm Fast',
      matches: 40,
      runs: 210,
      wickets: 56,
      strikeRate: 105.0,
      basePrice: 15000,
      isIcon: false,
      status: PlayerStatus.available,
    ),
    Player(
      id: 'pl_4',
      auctionId: sampleAuction.id,
      playerNo: 4,
      name: 'Virendra Dave',
      village: 'Surat',
      category: 'Wicket-Keeper',
      battingStyle: 'Left Hand Bat',
      bowlingStyle: 'None',
      matches: 38,
      runs: 980,
      wickets: 0,
      strikeRate: 132.8,
      basePrice: 12000,
      isIcon: false,
      status: PlayerStatus.available,
    ),
  ];
  await playerRepo.saveAll(players);
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jp_auction_arena/data/models/models.dart';
import 'package:jp_auction_arena/data/repositories/repositories.dart';
import 'package:jp_auction_arena/features/analytics/analytics_screen.dart';
import 'package:jp_auction_arena/features/auctions/auctions_screen.dart';
import 'package:jp_auction_arena/features/live/live_screen.dart';
import 'package:jp_auction_arena/features/players/players_screen.dart';
import 'package:jp_auction_arena/features/registration/registration_screen.dart';
import 'package:jp_auction_arena/features/results/results_screen.dart';
import 'package:jp_auction_arena/features/settings/settings_screen.dart';
import 'package:jp_auction_arena/features/teams/teams_screen.dart';

class FakeSettingsRepository implements SettingsRepository {
  AppSettings _settings = AppSettings(
    profileName: 'Jay Patel',
    phone: '9876543210',
    orgName: 'Gujarat Cricket Board',
    orgDescription: 'Official regional cricket tournament',
    pin: '1234',
    language: 'en',
    soundOn: true,
    voiceOn: true,
    auctionReminders: true,
    soldAnimation: true,
    themeAccent: 'blue',
    fontSize: 'normal',
    autoBackupAfterSale: false,
  );

  @override
  AppSettings getSettings() => _settings;

  @override
  Future<void> saveSettings(AppSettings settings) async {
    _settings = settings;
  }

  @override
  Stream<AppSettings> watchSettings() => Stream.value(_settings);
}

class FakeDataBackupService implements DataBackupService {
  @override
  Future<String> createBackupJson() async => '{"version":"1.0","auctions":[],"teams":[],"players":[],"bids":[]}';

  @override
  Future<Map<String, int>> restoreFromJson(String jsonString) async => {
    'auctions': 1,
    'teams': 2,
    'players': 10,
    'bids': 5,
  };

  @override
  Future<void> clearAllData() async {}
}

void main() {
  final sampleAuction = Auction(
    id: 'auc_test',
    name: 'Premier T20 League 2026',
    status: AuctionStatus.live,
    startDateTime: DateTime.now(),
    teamPurse: 10000000,
    bidIncrement: 50000,
    minSquad: 11,
    maxSquad: 18,
    createdAt: DateTime.now(),
  );

  final sampleTeams = [
    Team(
      id: 'team_1',
      auctionId: 'auc_test',
      name: 'Mumbai Titans',
      purseTotal: 10000000,
      purseSpent: 3500000,
    ),
  ];

  final samplePlayers = [
    Player(
      id: 'p_1',
      auctionId: 'auc_test',
      playerNo: 1,
      name: 'Virat Sharma',
      category: 'Batsman',
      village: 'Ahmedabad',
      strikeRate: 145.5,
      basePrice: 200000,
      status: PlayerStatus.available,
    ),
  ];

  final sampleBids = [
    Bid(
      id: 'b_1',
      auctionId: 'auc_test',
      playerId: 'p_1',
      teamId: 'team_1',
      amount: 500000,
    ),
  ];

  final overrides = [
    settingsRepositoryProvider.overrideWithValue(FakeSettingsRepository()),
    dataBackupServiceProvider.overrideWithValue(FakeDataBackupService()),
    auctionsListProvider.overrideWith((ref) => Stream.value([sampleAuction])),
    activeAuctionProvider.overrideWithValue(sampleAuction),
    currentAuctionTeamsProvider.overrideWith((ref) => Stream.value(sampleTeams)),
    currentAuctionPlayersProvider.overrideWith((ref) => Stream.value(samplePlayers)),
    currentAuctionBidsProvider.overrideWith((ref) => Stream.value(sampleBids)),
    allTeamsListProvider.overrideWith((ref) => Stream.value(sampleTeams)),
    allPlayersListProvider.overrideWith((ref) => Stream.value(samplePlayers)),
  ];

  const testViewports = [
    Size(360, 640),   // Compact Phone
    Size(768, 1024),  // Tablet
    Size(1280, 800),  // Desktop
  ];

  for (final size in testViewports) {
    group('Viewport ${size.width.toInt()}x${size.height.toInt()} Responsive Tests', () {
      testWidgets('AuctionsScreen renders without overflow', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          ProviderScope(
            overrides: overrides,
            child: const MaterialApp(home: AuctionsScreen()),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });

      testWidgets('LiveScreen renders without overflow', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          ProviderScope(
            overrides: overrides,
            child: const MaterialApp(home: LiveScreen()),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });

      testWidgets('PlayersScreen renders without overflow', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          ProviderScope(
            overrides: overrides,
            child: const MaterialApp(home: PlayersScreen()),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });

      testWidgets('TeamsScreen renders without overflow', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          ProviderScope(
            overrides: overrides,
            child: const MaterialApp(home: TeamsScreen()),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });

      testWidgets('RegistrationScreen renders without overflow', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          ProviderScope(
            overrides: overrides,
            child: const MaterialApp(home: RegistrationScreen()),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });

      testWidgets('ResultsScreen renders without overflow', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          ProviderScope(
            overrides: overrides,
            child: const MaterialApp(home: ResultsScreen()),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });

      testWidgets('AnalyticsScreen renders without overflow', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          ProviderScope(
            overrides: overrides,
            child: const MaterialApp(home: AnalyticsScreen()),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });

      testWidgets('SettingsScreen renders without overflow', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          ProviderScope(
            overrides: overrides,
            child: const MaterialApp(home: SettingsScreen()),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    });
  }
}

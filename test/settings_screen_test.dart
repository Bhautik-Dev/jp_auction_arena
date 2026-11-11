import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:jp_auction_arena/data/models/models.dart';
import 'package:jp_auction_arena/data/repositories/repositories.dart';
import 'package:jp_auction_arena/features/settings/settings_screen.dart';

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

void main() {
  Directory? tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_settings_test_');
    Hive.init(tempDir!.path);

    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(AuctionStatusAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(AuctionModeAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(PlayerStatusAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(AuctionAdapter());
    if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(TeamAdapter());
    if (!Hive.isAdapterRegistered(5)) Hive.registerAdapter(PlayerAdapter());
    if (!Hive.isAdapterRegistered(6)) Hive.registerAdapter(BidAdapter());
    if (!Hive.isAdapterRegistered(7)) Hive.registerAdapter(AppSettingsAdapter());
    if (!Hive.isAdapterRegistered(8)) Hive.registerAdapter(UserRoleAdapter());

    await Hive.openBox<Auction>(HiveBoxes.auctions);
    await Hive.openBox<Team>(HiveBoxes.teams);
    await Hive.openBox<Player>(HiveBoxes.players);
    await Hive.openBox<Bid>(HiveBoxes.bids);
    await Hive.openBox<AppSettings>(HiveBoxes.settings);
  });

  tearDownAll(() async {
    await Hive.close();
    try {
      await tempDir?.delete(recursive: true);
    } catch (_) {}
  });

  testWidgets('SettingsScreen renders all sections, options and handles save', (tester) async {
    final fakeRepo = FakeSettingsRepository();

    await tester.binding.setSurfaceSize(const Size(1280, 1200));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: const MaterialApp(
          home: SettingsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Title & Headers
    expect(find.text('Application Settings'), findsOneWidget);
    expect(find.text('Profile & Organization'), findsOneWidget);
    expect(find.text('Security & PIN Access'), findsOneWidget);
    expect(find.text('Notifications & Live Auction Audio'), findsOneWidget);
    expect(find.text('Appearance, Language & Display'), findsOneWidget);
    expect(find.text('Data Management & Offline Sync'), findsOneWidget);

    // Verify Profile inputs have loaded initial values
    expect(find.text('Jay Patel'), findsOneWidget);
    expect(find.text('9876543210'), findsOneWidget);
    expect(find.text('Gujarat Cricket Board'), findsOneWidget);

    // Verify Notification toggles
    expect(find.text('Auction Reminders'), findsOneWidget);
    expect(find.text('Bid & Gavel Sound Effects'), findsOneWidget);
    expect(find.text('Voice Announcer'), findsOneWidget);
    expect(find.text('SOLD Celebration Animation'), findsOneWidget);

    // Verify Appearance options
    expect(find.text('English (Default)'), findsOneWidget);
    expect(find.text('Electric Blue'), findsOneWidget);
    expect(find.text('Deep Purple'), findsOneWidget);
    expect(find.text('Neon Pink'), findsOneWidget);
    expect(find.text('Normal (Recommended)'), findsOneWidget);

    // Verify Data actions
    expect(find.text('Auto-backup after every sale'), findsOneWidget);
    expect(find.text('Backup (Download JSON)'), findsOneWidget);
    expect(find.text('Restore from JSON'), findsOneWidget);
    expect(find.text('Clear All Data'), findsOneWidget);

    // Test Save Changes Button click
    final saveButton = find.text('Save Changes').first;
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    // Verify Toast appears
    expect(find.text('Settings saved successfully!'), findsOneWidget);
  });

  testWidgets('Backup action generates backup and opens dialog', (tester) async {
    final fakeRepo = FakeSettingsRepository();
    await tester.binding.setSurfaceSize(const Size(1280, 1200));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: const MaterialApp(
          home: SettingsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final backupButton = find.text('Backup (Download JSON)');
    expect(backupButton, findsOneWidget);
    await tester.ensureVisible(backupButton);
    await tester.pumpAndSettle();
    await tester.tap(backupButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Backup Generated'), findsOneWidget);
    expect(find.text('Copy Again'), findsOneWidget);

    final closeButton = find.text('Close');
    await tester.tap(closeButton);
    await tester.pumpAndSettle();
  });

  testWidgets('Clear all data opens double confirmation dialogs', (tester) async {
    final fakeRepo = FakeSettingsRepository();
    await tester.binding.setSurfaceSize(const Size(1280, 1200));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: const MaterialApp(
          home: SettingsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final clearButton = find.text('Clear All Data');
    expect(clearButton, findsOneWidget);
    await tester.ensureVisible(clearButton);
    await tester.pumpAndSettle();
    await tester.tap(clearButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // First confirmation dialog
    expect(find.text('Clear All Data?'), findsOneWidget);
    final continueButton = find.text('Continue to Final Confirmation');
    expect(continueButton, findsOneWidget);
    await tester.tap(continueButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Second double-confirmation dialog
    expect(find.text('Double Confirmation'), findsOneWidget);
    expect(find.text('To finalize total reset, type "CLEAR ALL" below:'), findsOneWidget);

    final abortButton = find.text('Abort');
    await tester.tap(abortButton);
    await tester.pumpAndSettle();
  });
}

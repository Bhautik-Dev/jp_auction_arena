import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
  testWidgets('SettingsScreen renders all sections, options and handles save', (tester) async {
    final fakeSettings = FakeSettingsRepository();
    final fakeBackup = FakeDataBackupService();

    tester.view.physicalSize = const Size(1280, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(fakeSettings),
          dataBackupServiceProvider.overrideWithValue(fakeBackup),
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

    // Scroll and verify Data actions
    final autoBackupFinder = find.text('Auto-backup after every sale');
    await tester.ensureVisible(autoBackupFinder);
    await tester.pumpAndSettle();
    expect(autoBackupFinder, findsOneWidget);

    final backupFinder = find.text('Backup (Download JSON)');
    await tester.ensureVisible(backupFinder);
    await tester.pumpAndSettle();
    expect(backupFinder, findsOneWidget);

    final restoreFinder = find.text('Restore from JSON');
    await tester.ensureVisible(restoreFinder);
    await tester.pumpAndSettle();
    expect(restoreFinder, findsOneWidget);

    final clearFinder = find.text('Clear All Data');
    await tester.ensureVisible(clearFinder);
    await tester.pumpAndSettle();
    expect(clearFinder, findsOneWidget);

    // Test Save Changes Button click (header button)
    final saveButton = find.text('Save Changes').first;
    await tester.ensureVisible(saveButton);
    await tester.pumpAndSettle();
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    // Verify Toast appears
    expect(find.text('Settings saved successfully!'), findsOneWidget);
  });

  testWidgets('Backup action generates backup and opens dialog', (tester) async {
    final fakeSettings = FakeSettingsRepository();
    final fakeBackup = FakeDataBackupService();

    tester.view.physicalSize = const Size(1280, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(fakeSettings),
          dataBackupServiceProvider.overrideWithValue(fakeBackup),
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
    final fakeSettings = FakeSettingsRepository();
    final fakeBackup = FakeDataBackupService();

    tester.view.physicalSize = const Size(1280, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(fakeSettings),
          dataBackupServiceProvider.overrideWithValue(fakeBackup),
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

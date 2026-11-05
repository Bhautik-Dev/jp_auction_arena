import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jp_auction_arena/core/utils/currency_formatter.dart';
import 'package:jp_auction_arena/core/widgets/count_up_text.dart';
import 'package:jp_auction_arena/data/models/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CurrencyFormatter Indian Formatting', () {
    test('formats full Indian Rupees with commas', () {
      expect(CurrencyFormatter.formatInr(100000), '₹1,00,000');
      expect(CurrencyFormatter.formatInr(50000), '₹50,000');
      expect(CurrencyFormatter.formatInr(10000000), '₹1,00,00,000');
    });

    test('formats short form with K, L, Cr', () {
      expect(CurrencyFormatter.formatShort(14000), '₹14K');
      expect(CurrencyFormatter.formatShort(290000), '₹2.9L');
      expect(CurrencyFormatter.formatShort(15000000), '₹1.5Cr');
      expect(CurrencyFormatter.formatShort(500), '₹500');
    });
  });

  group('Data Models & Enums', () {
    test('Auction model creation and serialization', () {
      final auction = Auction(
        id: 'auc_1',
        name: 'IPL Auction',
        venue: 'Mumbai',
        startDateTime: DateTime(2026, 11, 5),
        status: AuctionStatus.live,
        teamPurse: 10000000,
        mode: AuctionMode.manual,
      );

      final map = auction.toMap();
      final fromMap = Auction.fromMap(map);

      expect(fromMap.id, 'auc_1');
      expect(fromMap.name, 'IPL Auction');
      expect(fromMap.status, AuctionStatus.live);
      expect(fromMap.teamPurse, 10000000);
      expect(fromMap.mode, AuctionMode.manual);
    });

    test('Team purse calculation', () {
      final team = Team(
        id: 't1',
        auctionId: 'auc_1',
        name: 'Super Kings',
        purseTotal: 1000000,
        purseSpent: 350000,
      );

      expect(team.purseRemaining, 650000);
      expect(team.squadCount, 0);
    });

    test('Player model creation', () {
      final player = Player(
        id: 'p1',
        auctionId: 'auc_1',
        playerNo: 7,
        name: 'M. S. Dhoni',
        category: 'Wicket-Keeper',
        basePrice: 200000,
        isIcon: true,
        status: PlayerStatus.available,
      );

      expect(player.name, 'M. S. Dhoni');
      expect(player.isIcon, isTrue);
      expect(player.status, PlayerStatus.available);
    });
  });

  group('Hive Adapters Verification', () {
    test('adapter typeIds are distinct and ordered 0 to 8', () {
      expect(AuctionStatusAdapter().typeId, 0);
      expect(AuctionModeAdapter().typeId, 1);
      expect(PlayerStatusAdapter().typeId, 2);
      expect(AuctionAdapter().typeId, 3);
      expect(TeamAdapter().typeId, 4);
      expect(PlayerAdapter().typeId, 5);
      expect(BidAdapter().typeId, 6);
      expect(AppSettingsAdapter().typeId, 7);
      expect(UserRoleAdapter().typeId, 8);
    });

    test('AppSettings defaults', () {
      final settings = AppSettings();
      expect(settings.profileName, '');
      expect(settings.pin, '');
      expect(settings.soundOn, isTrue);
      expect(settings.voiceOn, isTrue);
      expect(settings.role, UserRole.admin);
      expect(settings.isSetupComplete, isFalse);
    });
  });

  group('UserRole Permissions', () {
    test('Admin permissions', () {
      const role = UserRole.admin;
      expect(role.canManageEverything, isTrue);
      expect(role.canRunLiveAuction, isTrue);
      expect(role.isReadOnly, isFalse);
    });

    test('Operator permissions', () {
      const role = UserRole.operator;
      expect(role.canManageEverything, isFalse);
      expect(role.canRunLiveAuction, isTrue);
      expect(role.isReadOnly, isFalse);
    });

    test('Viewer permissions', () {
      const role = UserRole.viewer;
      expect(role.canManageEverything, isFalse);
      expect(role.canRunLiveAuction, isFalse);
      expect(role.isReadOnly, isTrue);
    });
  });

  group('CountUpText and ShimmerLoading Tests', () {
    testWidgets('CountUpText renders number with prefix and suffix', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CountUpText(
              value: 125,
              prefix: 'Total: ',
              suffix: ' items',
            ),
          ),
        ),
      );

      // Initial pump
      await tester.pump();
      expect(find.byType(CountUpText), findsOneWidget);

      // Settle animation
      await tester.pumpAndSettle();
      expect(find.text('Total: 125 items'), findsOneWidget);
    });
  });

  group('Auction Status and Duplication Logic', () {
    test('AuctionStatus includes draft, live, paused, completed, and archived', () {
      expect(AuctionStatus.values.length, 5);
      expect(AuctionStatus.archived.displayName, 'Archived');
      expect(AuctionStatus.fromString('archived'), AuctionStatus.archived);
      expect(AuctionStatus.fromString('completed'), AuctionStatus.completed);
    });

    test('Auction copyWith creates correct copy with new status or name', () {
      final original = Auction(
        id: 'orig_1',
        name: 'Winter League',
        venue: 'Eden Gardens',
        startDateTime: DateTime(2026, 12, 1),
        status: AuctionStatus.draft,
        numberOfTeams: 8,
      );

      final copy = original.copyWith(
        id: 'copy_1',
        name: 'Winter League (Copy)',
        status: AuctionStatus.archived,
      );

      expect(copy.id, 'copy_1');
      expect(copy.name, 'Winter League (Copy)');
      expect(copy.venue, 'Eden Gardens');
      expect(copy.status, AuctionStatus.archived);
      expect(copy.numberOfTeams, 8);
    });
  });

  group('Auction Wizard Extended Fields', () {
    test('Auction model supports reservePurseRule, smartBidSlabs, and categoryBasePrices', () {
      final auction = Auction(
        id: 'auc_wizard_1',
        name: 'Super Cup',
        startDateTime: DateTime(2026, 12, 10),
        contactPhone: '9876543210',
        contactEmail: 'admin@cricket.org',
        reservePurseRule: true,
        smartBidSlabs: true,
        categoryBasePrices: {
          'Batsman': 15000,
          'Bowler': 12000,
          'Icon Player': 50000,
        },
      );

      expect(auction.contactPhone, '9876543210');
      expect(auction.contactEmail, 'admin@cricket.org');
      expect(auction.reservePurseRule, isTrue);
      expect(auction.smartBidSlabs, isTrue);
      expect(auction.categoryBasePrices['Icon Player'], 50000);

      final map = auction.toMap();
      final restored = Auction.fromMap(map);
      expect(restored.contactPhone, '9876543210');
      expect(restored.contactEmail, 'admin@cricket.org');
      expect(restored.reservePurseRule, isTrue);
      expect(restored.smartBidSlabs, isTrue);
      expect(restored.categoryBasePrices['Icon Player'], 50000);
    });
  });
}

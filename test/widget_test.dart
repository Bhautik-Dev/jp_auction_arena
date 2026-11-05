import 'package:flutter_test/flutter_test.dart';
import 'package:jp_auction_arena/core/utils/currency_formatter.dart';
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
    test('adapter typeIds are distinct and ordered 0 to 7', () {
      expect(AuctionStatusAdapter().typeId, 0);
      expect(AuctionModeAdapter().typeId, 1);
      expect(PlayerStatusAdapter().typeId, 2);
      expect(AuctionAdapter().typeId, 3);
      expect(TeamAdapter().typeId, 4);
      expect(PlayerAdapter().typeId, 5);
      expect(BidAdapter().typeId, 6);
      expect(AppSettingsAdapter().typeId, 7);
    });

    test('AppSettings defaults', () {
      final settings = AppSettings();
      expect(settings.profileName, 'JP Arena Admin');
      expect(settings.pin, '1234');
      expect(settings.soundOn, isTrue);
      expect(settings.voiceOn, isTrue);
    });
  });
}

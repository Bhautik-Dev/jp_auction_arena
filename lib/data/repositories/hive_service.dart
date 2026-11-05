import 'package:hive_flutter/hive_flutter.dart';
import '../models/models.dart';

class HiveBoxes {
  static const String auctions = 'auctions_box';
  static const String teams = 'teams_box';
  static const String players = 'players_box';
  static const String bids = 'bids_box';
  static const String settings = 'settings_box';

  static Future<void> init() async {
    await Hive.initFlutter();

    // Register Hive Adapters
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(AuctionStatusAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(AuctionModeAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(PlayerStatusAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(AuctionAdapter());
    if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(TeamAdapter());
    if (!Hive.isAdapterRegistered(5)) Hive.registerAdapter(PlayerAdapter());
    if (!Hive.isAdapterRegistered(6)) Hive.registerAdapter(BidAdapter());
    if (!Hive.isAdapterRegistered(7)) Hive.registerAdapter(AppSettingsAdapter());
    if (!Hive.isAdapterRegistered(8)) Hive.registerAdapter(UserRoleAdapter());

    // Open boxes
    await Hive.openBox<Auction>(auctions);
    await Hive.openBox<Team>(teams);
    await Hive.openBox<Player>(players);
    await Hive.openBox<Bid>(bids);
    await Hive.openBox<AppSettings>(settings);
  }
}

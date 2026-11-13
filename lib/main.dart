import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:jp_auction_arena/app.dart';
import 'package:jp_auction_arena/data/repositories/repositories.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Use path URL strategy for Flutter Web so GoRouter navigation matches cleanly
  if (kIsWeb) {
    usePathUrlStrategy();
  } 

  // Initialize local offline Hive database (Web and Android support)
  await HiveBoxes.init();

  runApp(const ProviderScope(child: JpAuctionArenaApp()));
}

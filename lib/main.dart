import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:jp_auction_arena/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Use path URL strategy for Flutter Web so GoRouter navigation
  // matches cleanly without '#' fragment issues.
  if (kIsWeb) {
    usePathUrlStrategy();
  }

  runApp(
    const ProviderScope(
      child: JpAuctionArenaApp(),
    ),
  );
}

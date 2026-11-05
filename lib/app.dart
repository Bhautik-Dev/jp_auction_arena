import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jp_auction_arena/core/config/app_config.dart';
import 'package:jp_auction_arena/core/routing/app_router.dart';
import 'package:jp_auction_arena/core/theme/app_theme.dart';
import 'package:jp_auction_arena/core/theme/theme_mode_provider.dart';

class JpAuctionArenaApp extends ConsumerWidget {
  const JpAuctionArenaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GoRouter router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: AppConfig.isDebugBannerEnabled,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}

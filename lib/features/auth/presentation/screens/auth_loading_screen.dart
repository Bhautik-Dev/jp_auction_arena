import 'package:flutter/material.dart';
import 'package:jp_auction_arena/core/config/app_config.dart';
import 'package:jp_auction_arena/core/theme/app_spacing.dart';

class AuthLoadingScreen extends StatelessWidget {
  const AuthLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.sports_cricket,
            size: 52,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            AppConfig.appName,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.lg),
          const CircularProgressIndicator(),
        ],
      ),
    ),
  );
}

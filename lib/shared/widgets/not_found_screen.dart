import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jp_auction_arena/core/routing/route_names.dart';
import 'package:jp_auction_arena/shared/widgets/app_button.dart';

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({required this.location, super.key});

  final String location;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Page not found', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(location),
          const SizedBox(height: 16),
          AppPrimaryButton(
            label: 'Go to dashboard',
            onPressed: () => context.go(RouteNames.dashboard),
          ),
        ],
      ),
    ),
  );
}

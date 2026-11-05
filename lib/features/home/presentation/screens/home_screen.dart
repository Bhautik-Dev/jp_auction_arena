import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jp_auction_arena/core/config/app_config.dart';
import 'package:jp_auction_arena/core/constants/app_dimensions.dart';
import 'package:jp_auction_arena/core/theme/theme_mode_provider.dart';
import 'package:jp_auction_arena/features/home/presentation/widgets/architecture_card.dart';
import 'package:jp_auction_arena/features/home/presentation/widgets/home_header.dart';
import 'package:jp_auction_arena/shared/widgets/app_button.dart';
import 'package:jp_auction_arena/shared/widgets/responsive_layout.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.gavel_rounded,
              color: theme.colorScheme.primary,
              size: 26,
            ),
            const SizedBox(width: AppDimensions.spaceSm),
            const Text(AppConfig.appName),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Toggle Theme',
            icon: Icon(
              themeMode == ThemeMode.dark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
            ),
            onPressed: () {
              ref.read(themeModeProvider.notifier).toggleTheme();
            },
          ),
          const SizedBox(width: AppDimensions.spaceSm),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppDimensions.maxContentWidth,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spaceLg,
              vertical: AppDimensions.spaceLg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const HomeHeader(),
                const SizedBox(height: AppDimensions.spaceXl),
                Text(
                  'Architecture Overview',
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: AppDimensions.spaceSm),
                Text(
                  'A modular, feature-first foundation prepared for production scaling.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: AppDimensions.spaceLg),
                ResponsiveLayout(
                  mobile: _buildCardGrid(crossAxisCount: 1),
                  tablet: _buildCardGrid(crossAxisCount: 2),
                  desktop: _buildCardGrid(crossAxisCount: 2),
                ),
                const SizedBox(height: AppDimensions.space2xl),
                _buildActionSection(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardGrid({required int crossAxisCount}) {
    const cards = [
      ArchitectureCard(
        title: 'Core Foundation',
        description:
            'Centralized configuration, Material 3 theming, GoRouter navigation, design tokens, error models, and logging.',
        icon: Icons.layers_rounded,
        tag: 'lib/core',
      ),
      ArchitectureCard(
        title: 'Shared Component Library',
        description:
            'Reusable design system components: buttons, text fields, cards, responsive layouts, and state indicators.',
        icon: Icons.widgets_rounded,
        tag: 'lib/shared',
      ),
      ArchitectureCard(
        title: 'Feature-Driven Modules',
        description:
            'Domain, data, and presentation boundaries for clean isolation and parallel team development.',
        icon: Icons.dashboard_customize_rounded,
        tag: 'lib/features',
      ),
      ArchitectureCard(
        title: 'Production Readiness',
        description:
            'Zero legacy code, modern Dart 3 null-safety, strict linting rules, and cross-platform build support.',
        icon: Icons.verified_rounded,
        tag: 'Build Ready',
      ),
    ];

    if (crossAxisCount == 1) {
      return Column(
        children: [
          for (final card in cards) ...[
            card,
            const SizedBox(height: AppDimensions.spaceMd),
          ],
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - AppDimensions.spaceMd) / 2;
        return Wrap(
          spacing: AppDimensions.spaceMd,
          runSpacing: AppDimensions.spaceMd,
          children: [
            for (final card in cards)
              SizedBox(
                width: itemWidth,
                child: card,
              ),
          ],
        );
      },
    );
  }

  Widget _buildActionSection(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spaceLg),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(
          color: theme.dividerTheme.color ?? Colors.transparent,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ready for New Feature Development',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: AppDimensions.spaceXs),
          Text(
            'All legacy components and outdated mock code have been cleaned. You can now build new features cleanly on top of this structure.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppDimensions.spaceLg),
          Row(
            children: [
              SizedBox(
                width: 160,
                child: AppButton(
                  label: 'Get Started',
                  variant: AppButtonVariant.primary,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Clean workspace is active and ready.'),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: AppDimensions.spaceMd),
              SizedBox(
                width: 160,
                child: AppButton(
                  label: 'Documentation',
                  variant: AppButtonVariant.outlined,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('See README.md for project architecture details.'),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

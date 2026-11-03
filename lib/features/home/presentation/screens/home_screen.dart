import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jp_auction_arena/core/constants/app_colors.dart';
import 'package:jp_auction_arena/core/constants/app_strings.dart';
import 'package:jp_auction_arena/core/theme/theme_mode_provider.dart';

/// Clean and modern Home Screen for JP AUCTION ARENA.
/// Showcases the Dark Blue and White visual style, responsive layout,
/// and Material 3 design with light/dark theme toggle.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.primaryNavy
                    : Colors.white.withAlpha(38),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.sports_cricket,
                color: AppColors.goldAccent,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              AppStrings.appTitle,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              ref.read(themeModeProvider.notifier).toggleTheme();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Hero Banner
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryBlueAccent.withAlpha(38),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Phase 2 • Tournament Management',
                                style: TextStyle(
                                  color: AppColors.lightBlueAccent,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.success.withAlpha(38),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle_outline,
                                    color: AppColors.success,
                                    size: 16,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Online & Active',
                                    style: TextStyle(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppStrings.appTitle,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppStrings.appTagline,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.textTheme.bodyMedium?.color?.withAlpha(178),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Wrap(
                          spacing: 12,
                          runSpacing: 10,
                          children: [
                            FilledButton.icon(
                              onPressed: () => context.push('/tournaments'),
                              icon: const Icon(Icons.emoji_events_outlined, size: 20),
                              label: const Text('Manage Tournaments'),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primaryNavy,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => context.push('/tournaments/create'),
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Create Tournament'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 12),
                        const Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            _TechChip(label: 'Flutter & Dart'),
                            _TechChip(label: 'Riverpod'),
                            _TechChip(label: 'GoRouter'),
                            _TechChip(label: 'Material 3'),
                            _TechChip(label: 'Clean Architecture'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Modules Section
                Text(
                  'Arena Modules',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 650;
                    return GridView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isWide ? 3 : 1,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        mainAxisExtent: 130,
                      ),
                      children: [
                        _FeaturePreviewCard(
                          icon: Icons.emoji_events_outlined,
                          title: 'Tournaments',
                          subtitle: 'Create, edit & manage seasons, dates & venues',
                          badgeText: 'Active',
                          badgeColor: AppColors.success,
                          onTap: () => context.push('/tournaments'),
                        ),
                        const _FeaturePreviewCard(
                          icon: Icons.groups_outlined,
                          title: 'Teams & Squads',
                          subtitle: 'Team rosters and remaining purse monitor',
                          badgeText: 'Phase 3',
                        ),
                        const _FeaturePreviewCard(
                          icon: Icons.person_outline,
                          title: 'Player Registry',
                          subtitle: 'Player categories, stats & base prices',
                          badgeText: 'Phase 3',
                        ),
                        const _FeaturePreviewCard(
                          icon: Icons.gavel,
                          title: 'Live Auction',
                          subtitle: 'Real-time bidding console & gavel strikes',
                          badgeText: 'Phase 4',
                        ),
                        const _FeaturePreviewCard(
                          icon: Icons.tv,
                          title: 'Projector Arena',
                          subtitle: '16:9 full-screen presentation display',
                          badgeText: 'Phase 4',
                        ),
                        const _FeaturePreviewCard(
                          icon: Icons.assessment_outlined,
                          title: 'Reports & Logs',
                          subtitle: 'Audit trail and exportable summaries',
                          badgeText: 'Phase 5',
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TechChip extends StatelessWidget {
  final String label;
  const _TechChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _FeaturePreviewCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? badgeText;
  final Color? badgeColor;
  final VoidCallback? onTap;

  const _FeaturePreviewCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.badgeText,
    this.badgeColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Icon(icon, color: AppColors.lightBlueAccent, size: 24),
                  const Spacer(),
                  if (badgeText != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: (badgeColor ?? AppColors.primaryBlueAccent).withAlpha(30),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: (badgeColor ?? AppColors.primaryBlueAccent).withAlpha(90),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        badgeText!,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: badgeColor ?? AppColors.lightBlueAccent,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Flexible(
                child: Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withAlpha(178),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

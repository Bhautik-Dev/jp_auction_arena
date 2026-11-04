import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jp_auction_arena/core/constants/app_colors.dart';
import 'package:jp_auction_arena/core/theme/app_spacing.dart';
import 'package:jp_auction_arena/features/dashboard/domain/models/dashboard_snapshot.dart';
import 'package:jp_auction_arena/features/auction/domain/models/cricket_format.dart';
import 'package:jp_auction_arena/shared/widgets/app_card.dart';

class DashboardDemoNotice extends StatelessWidget {
  const DashboardDemoNotice({super.key});

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(AppSpacing.md),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline, color: AppColors.warning),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DEMO DATA · NOT LIVE',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.warning,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                'Dashboard figures use synthetic, in-memory sample records. '
                'They are not real auction activity.',
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class DashboardStatCard extends StatelessWidget {
  const DashboardStatCard({
    required this.title,
    required this.value,
    required this.icon,
    this.subtitle,
    this.accent = AppColors.electricBlue,
    super.key,
  });

  final String title;
  final String value;
  final IconData icon;
  final String? subtitle;
  final Color accent;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(AppSpacing.md),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: accent),
        const SizedBox(height: AppSpacing.md),
        Text(value, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.xs),
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    ),
  );
}

class DashboardQuickActionCard extends StatelessWidget {
  const DashboardQuickActionCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
    super.key,
  });

  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AppCard(
    onTap: onTap,
    padding: const EdgeInsets.all(AppSpacing.md),
    child: Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppSpacing.xs),
              Text(description, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        const Icon(Icons.arrow_forward_rounded, size: 18),
      ],
    ),
  );
}

class DashboardRecentActivity extends StatelessWidget {
  const DashboardRecentActivity({required this.items, super.key});

  final List<DashboardActivity> items;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(AppSpacing.md),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < items.length; index++) ...[
          if (index > 0) const Divider(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.history, color: AppColors.softPurple, size: 20),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      items[index].title,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(items[index].description),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    ),
  );
}

class DashboardNotificationPanel extends StatelessWidget {
  const DashboardNotificationPanel({required this.messages, super.key});

  final List<String> messages;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(AppSpacing.md),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < messages.length; index++) ...[
          if (index > 0) const Divider(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.notifications_none_rounded,
                color: AppColors.neonPink,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text(messages[index])),
            ],
          ),
        ],
      ],
    ),
  );
}

class DashboardAuctionOverviewCard extends StatelessWidget {
  const DashboardAuctionOverviewCard({required this.auction, super.key});

  final DashboardAuctionSummary auction;

  @override
  Widget build(BuildContext context) {
    final time = TimeOfDay(
      hour: auction.startTimeMinutes ~/ 60,
      minute: auction.startTimeMinutes % 60,
    ).format(context);
    final format = auction.cricketFormat == CricketFormat.custom
        ? auction.customFormat ?? 'Custom'
        : auction.cricketFormat.label;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.gavel_rounded,
                color: AppColors.softPurple,
                size: 28,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  auction.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Chip(label: Text(auction.status.label)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${DateFormat.yMMMd().format(auction.auctionDate)} · $time · $format',
          ),
          Text(
            '${auction.maxTeams} max teams · '
            '${auction.minPlayersPerTeam}–${auction.maxPlayersPerTeam} players/team',
          ),
        ],
      ),
    );
  }
}

class DashboardTeamOverviewCard extends StatelessWidget {
  const DashboardTeamOverviewCard({required this.team, super.key});

  final DashboardTeamSummary team;

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Color(team.primaryColorValue),
                child: Text(
                  team.shortName,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.primaryText,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      team.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(team.status.label),
                  ],
                ),
              ),
              const Icon(Icons.shield_outlined, color: AppColors.softPurple),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Team purse overview',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Illustrative demo purse · ${formatter.format(team.illustrativePurse)}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            'Remaining demo purse · '
            '${formatter.format(team.illustrativeRemainingPurse)}',
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            children: [
              _TeamMetric(
                label: 'Squad size',
                value: '${team.registeredPlayerCount}',
              ),
              _TeamMetric(
                label: 'Registered players',
                value: '${team.registeredPlayerCount}',
              ),
              _TeamMetric(
                label: 'Sold players',
                value: '${team.soldPlayerCount}',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Purse values are illustrative only. Purse limits and auction '
            'transactions are not configured.',
          ),
        ],
      ),
    );
  }
}

class DashboardProgressCard extends StatelessWidget {
  const DashboardProgressCard({
    required this.title,
    required this.value,
    required this.detail,
    required this.icon,
    super.key,
  });

  final String title;
  final String value;
  final String detail;
  final IconData icon;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(AppSpacing.md),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.softPurple),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppSpacing.xs),
              Text(value),
              const SizedBox(height: AppSpacing.xs),
              Text(detail, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    ),
  );
}

class _TeamMetric extends StatelessWidget {
  const _TeamMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(value, style: Theme.of(context).textTheme.titleMedium),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}

class DashboardTeamList extends StatelessWidget {
  const DashboardTeamList({required this.teams, super.key});

  final List<DashboardTeamSummary> teams;

  @override
  Widget build(BuildContext context) {
    if (teams.isEmpty) {
      return const AppCard(
        child: Text('No participating teams are available in this demo.'),
      );
    }
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          for (final team in teams)
            Chip(
              avatar: CircleAvatar(
                backgroundColor: Color(team.primaryColorValue),
              ),
              label: Text(team.name),
            ),
        ],
      ),
    );
  }
}

class DashboardEmptySection extends StatelessWidget {
  const DashboardEmptySection({
    required this.title,
    required this.message,
    super.key,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        Text(message),
      ],
    ),
  );
}

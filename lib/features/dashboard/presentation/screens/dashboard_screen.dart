import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jp_auction_arena/core/constants/app_strings.dart';
import 'package:jp_auction_arena/core/routing/route_names.dart';
import 'package:jp_auction_arena/core/theme/app_spacing.dart';
import 'package:jp_auction_arena/features/auth/application/auth_providers.dart';
import 'package:jp_auction_arena/features/auth/application/route_access_policy.dart';
import 'package:jp_auction_arena/features/auth/domain/models/app_role.dart';
import 'package:jp_auction_arena/features/auth/domain/models/auth_user.dart';
import 'package:jp_auction_arena/features/dashboard/application/dashboard_providers.dart';
import 'package:jp_auction_arena/features/dashboard/domain/models/dashboard_snapshot.dart';
import 'package:jp_auction_arena/features/dashboard/presentation/widgets/dashboard_widgets.dart';
import 'package:jp_auction_arena/shared/widgets/app_states.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(dashboardSnapshotProvider);
    final user = ref
        .watch(authSessionProvider)
        .whenOrNull(data: (session) => session?.user);

    return snapshot.when(
      loading: () => const AppLoadingIndicator(label: 'Loading dashboard...'),
      error: (error, stackTrace) => AppErrorState(
        error: error,
        onRetry: () => ref.invalidate(dashboardSnapshotProvider),
      ),
      data: (data) => _DashboardContent(
        snapshot: data,
        user: user,
        onRefresh: () => ref.invalidate(dashboardSnapshotProvider),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.snapshot,
    required this.user,
    required this.onRefresh,
  });

  final DashboardSnapshot snapshot;
  final AuthUser? user;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) => ListView(
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.appName,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _heading(snapshot.role),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Welcome${user == null ? '' : ', ${user!.displayName}'}. '
                  '${snapshot.role.label} workspace.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Refresh dashboard',
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.lg),
      if (snapshot.isDemoData) ...[
        const DashboardDemoNotice(),
        const SizedBox(height: AppSpacing.lg),
      ],
      switch (snapshot.role) {
        AppRole.superAdmin => _SuperAdminDashboard(
          snapshot: snapshot,
          user: user,
        ),
        AppRole.tournamentAdmin => _TournamentAdminDashboard(
          snapshot: snapshot,
          user: user,
        ),
        AppRole.teamManager => _TeamManagerDashboard(
          snapshot: snapshot,
          user: user,
        ),
        AppRole.publicViewer => _PublicViewerDashboard(
          snapshot: snapshot,
          user: user,
        ),
      },
    ],
  );

  String _heading(AppRole role) => switch (role) {
    AppRole.superAdmin => 'Application overview',
    AppRole.tournamentAdmin => 'Tournament control center',
    AppRole.teamManager => 'Your team dashboard',
    AppRole.publicViewer => 'Tournament overview',
  };
}

class _SuperAdminDashboard extends StatelessWidget {
  const _SuperAdminDashboard({required this.snapshot, required this.user});

  final DashboardSnapshot snapshot;
  final AuthUser? user;

  @override
  Widget build(BuildContext context) {
    final stats = [
      _StatData(
        'Total tournaments',
        '${snapshot.tournaments.length}',
        Icons.emoji_events_outlined,
      ),
      _StatData(
        'Active tournaments',
        '${snapshot.activeTournamentCount}',
        Icons.play_circle_outline,
      ),
      _StatData(
        'Completed tournaments',
        '${snapshot.completedTournamentCount}',
        Icons.task_alt,
      ),
      _StatData('Registered teams', '${snapshot.teams.length}', Icons.groups),
      _StatData(
        'Registered players',
        '${snapshot.registeredPlayerCount}',
        Icons.sports_cricket_outlined,
        subtitle: 'Demo catalogue',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DashboardSection(title: 'Platform totals'),
        _StatCards(items: stats),
        const SizedBox(height: AppSpacing.lg),
        _DashboardSection(title: 'Active tournament'),
        if (snapshot.activeTournament case final tournament?)
          DashboardTournamentOverviewCard(tournament: tournament)
        else
          const DashboardEmptySection(
            title: 'No active tournament',
            message: 'No active tournament is present in the demo records.',
          ),
        const SizedBox(height: AppSpacing.lg),
        _DashboardSection(title: 'Quick actions'),
        _QuickActions(user: user),
        const SizedBox(height: AppSpacing.lg),
        _TwoColumnSections(
          left: _SectionContent(
            title: 'Recent activity',
            child: DashboardRecentActivity(items: snapshot.recentActivity),
          ),
          right: _SectionContent(
            title: 'System notifications',
            child: DashboardNotificationPanel(messages: snapshot.notifications),
          ),
        ),
      ],
    );
  }
}

class _TournamentAdminDashboard extends StatelessWidget {
  const _TournamentAdminDashboard({required this.snapshot, required this.user});

  final DashboardSnapshot snapshot;
  final AuthUser? user;

  @override
  Widget build(BuildContext context) {
    final tournament =
        snapshot.activeTournament ??
        (snapshot.tournaments.isEmpty ? null : snapshot.tournaments.first);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DashboardSection(title: 'Assigned tournament'),
        if (tournament == null)
          const AppEmptyState(
            title: 'No assigned tournament',
            message: 'No tournament is assigned to this operator demo account.',
          )
        else
          DashboardTournamentOverviewCard(tournament: tournament),
        const SizedBox(height: AppSpacing.lg),
        _DashboardSection(title: 'Tournament status'),
        _StatCards(
          items: [
            _StatData(
              'Tournament',
              tournament?.status.label ?? 'Unassigned',
              Icons.flag_outlined,
            ),
            _StatData(
              'Registered teams',
              '${tournament?.registeredTeamCount ?? 0}',
              Icons.groups_outlined,
            ),
            _StatData(
              'Registered players',
              '${snapshot.registeredPlayerCount}',
              Icons.sports_cricket_outlined,
              subtitle: 'Demo catalogue; no tournament link yet',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _DashboardSection(title: 'Setup progress'),
        _ResponsiveCardGrid(
          children: [
            DashboardProgressCard(
              title: 'Team registration',
              value: snapshot.teamRegistrationProgress,
              detail: 'Counts come from synthetic local records.',
              icon: Icons.groups_outlined,
            ),
            DashboardProgressCard(
              title: 'Player registration',
              value: snapshot.playerRegistrationProgress,
              detail: snapshot.playerCountDescription,
              icon: Icons.sports_cricket_outlined,
            ),
            DashboardProgressCard(
              title: 'Auction readiness',
              value: snapshot.auctionConfigurationStatus,
              detail: 'Auction operations are not implemented.',
              icon: Icons.checklist_outlined,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _DashboardSection(title: 'Quick actions'),
        _QuickActions(user: user),
        const SizedBox(height: AppSpacing.lg),
        _DashboardSection(title: 'Recent tournament activity'),
        DashboardRecentActivity(items: snapshot.recentActivity),
      ],
    );
  }
}

class _TeamManagerDashboard extends StatelessWidget {
  const _TeamManagerDashboard({required this.snapshot, required this.user});

  final DashboardSnapshot snapshot;
  final AuthUser? user;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _DashboardSection(title: 'Assigned team'),
      if (snapshot.teams.isEmpty)
        const AppEmptyState(
          title: 'No assigned team found',
          message: 'This account has no team available in the local demo data.',
        )
      else
        for (final team in snapshot.teams) ...[
          DashboardTeamOverviewCard(team: team),
          const SizedBox(height: AppSpacing.md),
        ],
      _DashboardSection(title: 'Auction progress'),
      DashboardProgressCard(
        title: 'Public auction status',
        value: snapshot.auctionStatus,
        detail: 'Read-only overview. Team accounts cannot place bids.',
        icon: Icons.visibility_outlined,
      ),
      const SizedBox(height: AppSpacing.lg),
      _DashboardSection(title: 'Team updates'),
      DashboardNotificationPanel(messages: snapshot.notifications),
      const SizedBox(height: AppSpacing.lg),
      _DashboardSection(title: 'Quick navigation'),
      _QuickActions(user: user),
    ],
  );
}

class _PublicViewerDashboard extends StatelessWidget {
  const _PublicViewerDashboard({required this.snapshot, required this.user});

  final DashboardSnapshot snapshot;
  final AuthUser? user;

  @override
  Widget build(BuildContext context) {
    final tournament = snapshot.activeTournament;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DashboardSection(title: 'Current active tournament'),
        if (tournament == null)
          const DashboardEmptySection(
            title: 'No public active tournament',
            message: 'There is no active tournament in the public demo data.',
          )
        else
          DashboardTournamentOverviewCard(tournament: tournament),
        const SizedBox(height: AppSpacing.lg),
        _DashboardSection(title: 'Public overview'),
        _StatCards(
          items: [
            _StatData(
              'Participating teams',
              '${snapshot.teams.length}',
              Icons.groups_outlined,
            ),
            _StatData(
              'Registered players',
              '${snapshot.registeredPlayerCount}',
              Icons.sports_cricket_outlined,
              subtitle: 'Synthetic catalogue only',
            ),
            _StatData(
              'Sold players',
              '${snapshot.soldPlayerCount}',
              Icons.verified_outlined,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _DashboardSection(title: 'Teams in active tournament'),
        DashboardTeamList(teams: snapshot.teams),
        const SizedBox(height: AppSpacing.lg),
        _DashboardSection(title: 'Public auction status'),
        DashboardProgressCard(
          title: 'Auction status',
          value: snapshot.auctionStatus,
          detail: 'No live auction feed is connected.',
          icon: Icons.public_outlined,
        ),
        const SizedBox(height: AppSpacing.md),
        const DashboardEmptySection(
          title: 'Public results',
          message: 'No public auction results have been published.',
        ),
        const SizedBox(height: AppSpacing.lg),
        _DashboardSection(title: 'Quick navigation'),
        _QuickActions(user: user),
      ],
    );
  }
}

class _DashboardSection extends StatelessWidget {
  const _DashboardSection({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Text(title, style: Theme.of(context).textTheme.titleLarge),
  );
}

class _StatData {
  const _StatData(this.title, this.value, this.icon, {this.subtitle});

  final String title;
  final String value;
  final IconData icon;
  final String? subtitle;
}

class _StatCards extends StatelessWidget {
  const _StatCards({required this.items});

  final List<_StatData> items;

  @override
  Widget build(BuildContext context) => _ResponsiveCardGrid(
    children: [
      for (final item in items)
        DashboardStatCard(
          title: item.title,
          value: item.value,
          icon: item.icon,
          subtitle: item.subtitle,
        ),
    ],
  );
}

class _ResponsiveCardGrid extends StatelessWidget {
  const _ResponsiveCardGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 1000
          ? 3
          : constraints.maxWidth >= 560
          ? 2
          : 1;
      final spacing = AppSpacing.md;
      final width = (constraints.maxWidth - spacing * (columns - 1)) / columns;
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: [
          for (final child in children) SizedBox(width: width, child: child),
        ],
      );
    },
  );
}

class _SectionContent {
  const _SectionContent({required this.title, required this.child});

  final String title;
  final Widget child;
}

class _TwoColumnSections extends StatelessWidget {
  const _TwoColumnSections({required this.left, required this.right});

  final _SectionContent left;
  final _SectionContent right;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth < 760) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DashboardSection(title: left.title),
            left.child,
            const SizedBox(height: AppSpacing.lg),
            _DashboardSection(title: right.title),
            right.child,
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DashboardSection(title: left.title),
                left.child,
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DashboardSection(title: right.title),
                right.child,
              ],
            ),
          ),
        ],
      );
    },
  );
}

class _QuickAction {
  const _QuickAction(this.title, this.description, this.icon, this.path);

  final String title;
  final String description;
  final IconData icon;
  final String path;
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.user});

  final AuthUser? user;

  @override
  Widget build(BuildContext context) {
    if (user == null) return const SizedBox.shrink();
    final available = switch (user!.role) {
      AppRole.superAdmin => const [
        _QuickAction(
          'Tournaments',
          'Review tournament records',
          Icons.emoji_events_outlined,
          RouteNames.tournaments,
        ),
        _QuickAction(
          'Teams',
          'Open team records',
          Icons.groups_outlined,
          RouteNames.teams,
        ),
        _QuickAction(
          'Players',
          'Review player records',
          Icons.sports_cricket_outlined,
          RouteNames.players,
        ),
        _QuickAction(
          'Settings',
          'Application preferences',
          Icons.settings_outlined,
          RouteNames.settings,
        ),
        _QuickAction(
          'Tournament history',
          'Completed and archived records',
          Icons.history,
          RouteNames.history,
        ),
      ],
      AppRole.tournamentAdmin => const [
        _QuickAction(
          'Tournaments',
          'Open assigned tournament records',
          Icons.emoji_events_outlined,
          RouteNames.tournaments,
        ),
        _QuickAction(
          'Teams',
          'Review assigned tournament teams',
          Icons.groups_outlined,
          RouteNames.teams,
        ),
        _QuickAction(
          'Players',
          'Review player records',
          Icons.sports_cricket_outlined,
          RouteNames.players,
        ),
        _QuickAction(
          'Tournament history',
          'Completed and archived assigned records',
          Icons.history,
          RouteNames.history,
        ),
      ],
      AppRole.teamManager => const [
        _QuickAction(
          'My team',
          'Open your assigned team view',
          Icons.shield_outlined,
          RouteAccessPolicy.teamPortal,
        ),
      ],
      AppRole.publicViewer => const [
        _QuickAction(
          'Public live view',
          'Read-only public auction display',
          Icons.visibility_outlined,
          RouteAccessPolicy.publicLive,
        ),
      ],
    };
    final allowed = available
        .where((action) => RouteAccessPolicy.canAccessPath(user!, action.path))
        .toList();
    if (allowed.isEmpty) return const SizedBox.shrink();
    return _ResponsiveCardGrid(
      children: [
        for (final action in allowed)
          DashboardQuickActionCard(
            title: action.title,
            description: action.description,
            icon: action.icon,
            onTap: () => context.go(action.path),
          ),
      ],
    );
  }
}

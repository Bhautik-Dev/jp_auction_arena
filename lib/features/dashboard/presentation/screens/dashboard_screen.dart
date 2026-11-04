import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jp_auction_arena/core/constants/app_strings.dart';
import 'package:jp_auction_arena/core/routing/route_names.dart';
import 'package:jp_auction_arena/core/theme/app_spacing.dart';
import 'package:jp_auction_arena/features/auction/domain/models/auction_status.dart';
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
    padding: const EdgeInsets.all(AppSpacing.md),
    children: [
      Row(
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
        AppRole.superAdmin => _AdminDashboard(
          snapshot: snapshot,
          user: user,
          operator: false,
        ),
        AppRole.tournamentAdmin => _AdminDashboard(
          snapshot: snapshot,
          user: user,
          operator: true,
        ),
        AppRole.teamManager => _TeamDashboard(snapshot: snapshot, user: user),
        AppRole.publicViewer => _PublicDashboard(
          snapshot: snapshot,
          user: user,
        ),
      },
    ],
  );

  String _heading(AppRole role) => switch (role) {
    AppRole.superAdmin => 'Auction Management Dashboard',
    AppRole.tournamentAdmin => 'Auction Operator Workspace',
    AppRole.teamManager => 'Your Team Dashboard',
    AppRole.publicViewer => 'Public Auction Dashboard',
  };
}

class _AdminDashboard extends StatelessWidget {
  const _AdminDashboard({
    required this.snapshot,
    required this.user,
    required this.operator,
  });

  final DashboardSnapshot snapshot;
  final AuthUser? user;
  final bool operator;

  @override
  Widget build(BuildContext context) {
    final upcoming = snapshot.auctions
        .where((auction) => auction.status == AuctionStatus.ready)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 58,
          child: FilledButton.icon(
            onPressed: user == null
                ? null
                : () => context.go(RouteNames.auctionCreate),
            icon: const Icon(Icons.add_circle_outline),
            label: const Text(
              'CREATE NEW AUCTION',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.6),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _DashboardSection(title: 'Auction overview'),
        _StatCards(
          items: [
            _StatData(
              'Total Auctions',
              '${snapshot.auctions.length}',
              Icons.gavel,
            ),
            _StatData(
              'Draft Auctions',
              '${snapshot.draftAuctionCount}',
              Icons.edit_note,
            ),
            _StatData(
              'Upcoming Auctions',
              '${snapshot.upcomingAuctionCount}',
              Icons.event,
            ),
            _StatData(
              'Live Auctions',
              '${snapshot.liveAuctionCount}',
              Icons.play_circle_outline,
            ),
            _StatData(
              'Completed Auctions',
              '${snapshot.completedAuctionCount}',
              Icons.task_alt,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _DashboardSection(
          title: operator ? 'Assigned auctions' : 'Live auction',
        ),
        if (snapshot.liveAuction case final liveAuction?)
          DashboardAuctionOverviewCard(auction: liveAuction)
        else if (operator && snapshot.auctions.isNotEmpty)
          DashboardAuctionOverviewCard(auction: snapshot.auctions.first)
        else
          const AppEmptyState(
            title: 'No live auction',
            message: 'Create or prepare an auction to see it here.',
            icon: Icons.gavel_outlined,
          ),
        if (upcoming.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          _DashboardSection(title: 'Upcoming auctions'),
          for (final auction in upcoming)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: DashboardAuctionOverviewCard(auction: auction),
            ),
        ],
        const SizedBox(height: AppSpacing.lg),
        _DashboardSection(title: 'Quick actions'),
        _QuickActions(user: user),
        const SizedBox(height: AppSpacing.lg),
        _TwoColumnSections(
          left: _SectionContent(
            title: 'Recent auction activity',
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

class _TeamDashboard extends StatelessWidget {
  const _TeamDashboard({required this.snapshot, required this.user});

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
          message: 'This account has no team in the local demo data.',
        )
      else
        for (final team in snapshot.teams) ...[
          DashboardTeamOverviewCard(team: team),
          const SizedBox(height: AppSpacing.md),
        ],
      const Text(
        'The sample team roster is not yet associated with a specific auction.',
      ),
      const SizedBox(height: AppSpacing.lg),
      _DashboardSection(title: 'Public auction progress'),
      if (snapshot.auctions.isEmpty)
        const AppEmptyState(
          title: 'No public live auction',
          message: 'There is no public live auction in the demo.',
        )
      else
        for (final auction in snapshot.auctions)
          DashboardAuctionOverviewCard(auction: auction),
      const SizedBox(height: AppSpacing.lg),
      DashboardProgressCard(
        title: 'Auction access',
        value: snapshot.auctionStatus,
        detail: 'Read-only. Team accounts cannot create auctions or bid.',
        icon: Icons.visibility_outlined,
      ),
      const SizedBox(height: AppSpacing.lg),
      DashboardNotificationPanel(messages: snapshot.notifications),
      const SizedBox(height: AppSpacing.lg),
      _QuickActions(user: user),
    ],
  );
}

class _PublicDashboard extends StatelessWidget {
  const _PublicDashboard({required this.snapshot, required this.user});

  final DashboardSnapshot snapshot;
  final AuthUser? user;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _DashboardSection(title: 'Public live auction'),
      if (snapshot.auctions.isEmpty)
        const AppEmptyState(
          title: 'No public live auction',
          message: 'There is no public live auction in the demo.',
        )
      else
        for (final auction in snapshot.auctions)
          DashboardAuctionOverviewCard(auction: auction),
      const SizedBox(height: AppSpacing.lg),
      _DashboardSection(title: 'Public auction status'),
      DashboardProgressCard(
        title: 'Auction status',
        value: snapshot.auctionStatus,
        detail: 'Read-only public information. Bidding is not available here.',
        icon: Icons.public_outlined,
      ),
      const SizedBox(height: AppSpacing.md),
      const DashboardEmptySection(
        title: 'Public results',
        message: 'No public auction results have been published.',
      ),
      const SizedBox(height: AppSpacing.lg),
      _QuickActions(user: user),
    ],
  );
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
  const _StatData(this.title, this.value, this.icon);

  final String title;
  final String value;
  final IconData icon;
}

class _StatCards extends StatelessWidget {
  const _StatCards({required this.items});

  final List<_StatData> items;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 1100
          ? 5
          : constraints.maxWidth >= 700
          ? 3
          : 2;
      final spacing = AppSpacing.sm;
      final width = (constraints.maxWidth - spacing * (columns - 1)) / columns;
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: [
          for (final item in items)
            SizedBox(
              width: width,
              child: DashboardStatCard(
                title: item.title,
                value: item.value,
                icon: item.icon,
              ),
            ),
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

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.user});

  final AuthUser? user;

  @override
  Widget build(BuildContext context) {
    if (user == null) return const SizedBox.shrink();
    final available = switch (user!.role) {
      AppRole.superAdmin => const [
        _QuickAction(
          'Create New Auction',
          'Set up an auction',
          Icons.add,
          RouteNames.auctionCreate,
        ),
        _QuickAction(
          'Manage Auctions',
          'Search and manage auctions',
          Icons.gavel,
          RouteNames.auctions,
        ),
        _QuickAction(
          'Auction History',
          'Completed and archived auctions',
          Icons.history,
          RouteNames.history,
        ),
        _QuickAction(
          'Settings',
          'Application preferences',
          Icons.settings_outlined,
          RouteNames.settings,
        ),
      ],
      AppRole.tournamentAdmin => const [
        _QuickAction(
          'Create New Auction',
          'Set up an auction',
          Icons.add,
          RouteNames.auctionCreate,
        ),
        _QuickAction(
          'Manage Auctions',
          'View assigned auctions',
          Icons.gavel,
          RouteNames.auctions,
        ),
        _QuickAction(
          'Auction History',
          'Completed auction records',
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
          'Read-only auction display',
          Icons.visibility_outlined,
          RouteAccessPolicy.publicLive,
        ),
      ],
    };
    final allowed = available
        .where((action) => RouteAccessPolicy.canAccessPath(user!, action.path))
        .toList();
    if (allowed.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900 ? 2 : 1;
        final gap = AppSpacing.md;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final action in allowed)
              SizedBox(
                width: width,
                child: DashboardQuickActionCard(
                  title: action.title,
                  description: action.description,
                  icon: action.icon,
                  onTap: () => context.go(action.path),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _QuickAction {
  const _QuickAction(this.title, this.description, this.icon, this.path);

  final String title;
  final String description;
  final IconData icon;
  final String path;
}

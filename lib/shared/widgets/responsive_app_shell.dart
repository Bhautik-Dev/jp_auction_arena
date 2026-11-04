import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jp_auction_arena/core/constants/app_colors.dart';
import 'package:jp_auction_arena/core/constants/app_strings.dart';
import 'package:jp_auction_arena/core/responsive/app_breakpoints.dart';
import 'package:jp_auction_arena/core/routing/route_names.dart';
import 'package:jp_auction_arena/core/theme/app_spacing.dart';
import 'package:jp_auction_arena/core/theme/theme_mode_provider.dart';
import 'package:jp_auction_arena/features/auth/application/auth_providers.dart';
import 'package:jp_auction_arena/features/auth/application/route_access_policy.dart';
import 'package:jp_auction_arena/features/auth/domain/models/auth_user.dart';
import 'package:jp_auction_arena/shared/widgets/app_confirmation_dialog.dart';
import 'package:jp_auction_arena/shared/widgets/responsive_page_container.dart';

class ResponsiveAppShell extends ConsumerWidget {
  const ResponsiveAppShell({required this.child, super.key});

  final Widget child;

  static const _implemented = [
    _Destination(
      AppStrings.dashboard,
      Icons.dashboard_outlined,
      RouteNames.dashboard,
      true,
    ),
    _Destination(
      AppStrings.tournaments,
      Icons.emoji_events_outlined,
      RouteNames.tournaments,
      true,
    ),
    _Destination(
      AppStrings.teams,
      Icons.groups_outlined,
      RouteNames.teams,
      true,
    ),
    _Destination(
      AppStrings.players,
      Icons.sports_cricket_outlined,
      RouteNames.players,
      true,
    ),
    _Destination(
      'My Team',
      Icons.shield_outlined,
      RouteAccessPolicy.teamPortal,
      true,
    ),
    _Destination(
      'Public Live',
      Icons.visibility_outlined,
      RouteAccessPolicy.publicLive,
      true,
    ),
    _Destination(
      AppStrings.settings,
      Icons.settings_outlined,
      RouteNames.settings,
      true,
    ),
  ];

  static List<_Destination> get _all => [..._implemented, ..._planned];

  static const _planned = [
    _Destination(
      AppStrings.auctionSetup,
      Icons.tune_rounded,
      RouteNames.auctionSetup,
      false,
    ),
    _Destination(
      AppStrings.liveAuction,
      Icons.campaign_outlined,
      RouteNames.liveAuction,
      false,
    ),
    _Destination(
      AppStrings.results,
      Icons.emoji_events,
      RouteNames.results,
      false,
    ),
    _Destination(
      AppStrings.reports,
      Icons.bar_chart_outlined,
      RouteNames.reports,
      false,
    ),
    _Destination(AppStrings.history, Icons.history, RouteNames.history, false),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = AppBreakpoints.usesBottomNavigation(width);
    final isWide = AppBreakpoints.usesExtendedNavigation(width);
    final path = GoRouterState.of(context).uri.path;
    final user = ref
        .watch(authSessionProvider)
        .whenOrNull(data: (session) => session?.user);
    final destinations = _visibleDestinations(user);
    final selectedIndex = _selectedIndex(path, destinations);

    return Scaffold(
      appBar: AppBar(
        leading: isCompact
            ? Builder(
                builder: (context) => IconButton(
                  tooltip: 'Open navigation menu',
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  icon: const Icon(Icons.menu),
                ),
              )
            : null,
        title: Text(_titleForLocation(path)),
        actions: [
          IconButton(
            tooltip: ref.watch(themeModeProvider) == ThemeMode.dark
                ? AppStrings.lightMode
                : AppStrings.darkMode,
            onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
            icon: Icon(
              ref.watch(themeModeProvider) == ThemeMode.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
          ),
          IconButton(
            tooltip: 'Log out',
            onPressed: () => _confirmLogout(context, ref),
            icon: const Icon(Icons.logout),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      drawer: isCompact && destinations.isNotEmpty
          ? _MobileDrawer(currentPath: path, destinations: destinations)
          : null,
      body: Row(
        children: [
          if (!isCompact && isWide)
            _DesktopSidebar(currentPath: path, destinations: destinations),
          if (!isCompact && !isWide && destinations.isNotEmpty)
            _CompactRail(
              selectedIndex: selectedIndex,
              destinations: destinations,
            ),
          Expanded(child: ResponsivePageContainer(child: child)),
        ],
      ),
      bottomNavigationBar: isCompact && destinations.isNotEmpty
          ? NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) =>
                  context.go(destinations[index].path),
              destinations: destinations
                  .map(
                    (item) => NavigationDestination(
                      icon: Icon(item.icon),
                      label: item.label,
                    ),
                  )
                  .toList(),
            )
          : null,
    );
  }

  static List<_Destination> _visibleDestinations(AuthUser? user) {
    if (user == null) return const [];
    return _implemented
        .where(
          (destination) =>
              RouteAccessPolicy.canAccessPath(user, destination.path),
        )
        .toList();
  }

  static int _selectedIndex(String path, List<_Destination> destinations) {
    if (destinations.isEmpty) return 0;
    return destinations
        .indexWhere(
          (destination) =>
              path == destination.path ||
              (destination.path == RouteNames.players &&
                  path.startsWith('${RouteNames.players}/')),
        )
        .clamp(0, destinations.length - 1)
        .toInt();
  }

  static String _titleForLocation(String path) {
    for (final destination in _all) {
      if (destination.path == path) return destination.label;
    }
    return AppStrings.appName;
  }

  static Future<void> _confirmLogout(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await AppConfirmationDialog.show(
      context,
      title: 'Log out?',
      message: 'You will return to the login screen.',
      confirmLabel: 'Log out',
    );
    if (!confirmed || !context.mounted) return;
    await ref.read(authSessionProvider.notifier).signOut();
    if (context.mounted) context.go(RouteAccessPolicy.login);
  }
}

class _Destination {
  const _Destination(this.label, this.icon, this.path, this.enabled);

  final String label;
  final IconData icon;
  final String path;
  final bool enabled;
}

class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({
    required this.currentPath,
    required this.destinations,
  });

  final String currentPath;
  final List<_Destination> destinations;

  @override
  Widget build(BuildContext context) => Container(
    width: 272,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      border: Border(right: BorderSide(color: Theme.of(context).dividerColor)),
    ),
    child: SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: _BrandHeader(),
          ),
          Expanded(
            child: NavigationRail(
              extended: true,
              selectedIndex: ResponsiveAppShell._selectedIndex(
                currentPath,
                destinations,
              ),
              onDestinationSelected: (index) {
                final destination = destinations[index];
                if (destination.enabled) {
                  context.go(destination.path);
                }
              },
              leading: const Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.md),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'JP AUCTION ARENA',
                    style: TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
              destinations: [...destinations, ...ResponsiveAppShell._planned]
                  .map(
                    (destination) => NavigationRailDestination(
                      icon: Icon(destination.icon),
                      label: Text(
                        destination.enabled
                            ? destination.label
                            : '${destination.label} - Soon',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      disabled: !destination.enabled,
                    ),
                  )
                  .toList(),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Text(
              'A unified cricket auction platform',
              style: TextStyle(color: AppColors.secondaryText),
            ),
          ),
        ],
      ),
    ),
  );
}

class _CompactRail extends StatelessWidget {
  const _CompactRail({required this.selectedIndex, required this.destinations});

  final int selectedIndex;
  final List<_Destination> destinations;

  @override
  Widget build(BuildContext context) => NavigationRail(
    selectedIndex: selectedIndex,
    destinations: destinations
        .map(
          (item) => NavigationRailDestination(
            icon: Icon(item.icon),
            label: item.enabled
                ? Text(item.label)
                : Tooltip(
                    message: AppStrings.comingSoon,
                    child: Text('${item.label} - Soon'),
                  ),
            disabled: !item.enabled,
          ),
        )
        .toList(),
    onDestinationSelected: (index) {
      final destination = destinations[index];
      if (destination.enabled) context.go(destination.path);
    },
  );
}

class _MobileDrawer extends StatelessWidget {
  const _MobileDrawer({required this.currentPath, required this.destinations});

  final String currentPath;
  final List<_Destination> destinations;

  @override
  Widget build(BuildContext context) => Drawer(
    child: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          const Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: _BrandHeader(),
          ),
          for (final destination in destinations)
            _NavigationTile(
              destination: destination,
              selected: currentPath == destination.path,
              onSelected: () {
                Navigator.of(context).pop();
                context.go(destination.path);
              },
            ),
          const Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Text(
              'PLANNED MODULES',
              style: TextStyle(
                color: AppColors.secondaryText,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ),
          for (final destination in ResponsiveAppShell._planned)
            _NavigationTile(destination: destination),
        ],
      ),
    ),
  );
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Icon(Icons.sports_cricket, color: AppColors.electricBlue),
      const SizedBox(width: AppSpacing.sm),
      Expanded(
        child: Text(
          AppStrings.appName,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    ],
  );
}

class _NavigationTile extends StatelessWidget {
  const _NavigationTile({
    required this.destination,
    this.selected = false,
    this.onSelected,
  });

  final _Destination destination;
  final bool selected;
  final VoidCallback? onSelected;

  @override
  Widget build(BuildContext context) {
    final enabled = destination.enabled;
    return Tooltip(
      message: enabled ? destination.label : AppStrings.comingSoon,
      child: ListTile(
        enabled: enabled,
        selected: selected,
        leading: Icon(destination.icon),
        title: Text(destination.label),
        trailing: enabled
            ? null
            : const Text(
                'Soon',
                style: TextStyle(color: AppColors.secondaryText, fontSize: 11),
              ),
        onTap: enabled
            ? onSelected ?? () => context.go(destination.path)
            : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
    );
  }
}

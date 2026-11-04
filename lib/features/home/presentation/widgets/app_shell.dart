import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jp_auction_arena/core/constants/app_colors.dart';
import 'package:jp_auction_arena/core/constants/app_strings.dart';
import 'package:jp_auction_arena/core/responsive/app_breakpoints.dart';
import 'package:jp_auction_arena/core/router/route_names.dart';

/// Responsive navigation shell shared by the dashboard and existing routes.
class AppShell extends StatelessWidget {
  const AppShell({required this.location, required this.child, super.key});

  final String location;
  final Widget child;

  int get _selectedIndex => location.startsWith(RouteNames.playersPath)
      ? 3
      : location.startsWith(RouteNames.teamsPath)
      ? 2
      : location.startsWith(RouteNames.tournamentsPath)
      ? 1
      : 0;

  static const _destinations = [
    _AppDestination(
      label: AppStrings.dashboard,
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      path: RouteNames.homePath,
    ),
    _AppDestination(
      label: AppStrings.tournaments,
      icon: Icons.emoji_events_outlined,
      selectedIcon: Icons.emoji_events,
      path: RouteNames.tournamentsPath,
    ),
    _AppDestination(
      label: AppStrings.teams,
      icon: Icons.groups_outlined,
      selectedIcon: Icons.groups,
      path: RouteNames.teamsPath,
    ),
    _AppDestination(
      label: AppStrings.players,
      icon: Icons.people_alt_outlined,
      selectedIcon: Icons.people_alt,
      path: RouteNames.playersPath,
    ),
  ];

  void _navigate(BuildContext context, int index) {
    context.go(_destinations[index].path);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (AppBreakpoints.usesBottomNavigation(constraints.maxWidth)) {
          return Scaffold(
            body: child,
            bottomNavigationBar: NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) => _navigate(context, index),
              destinations: [
                for (final destination in _destinations)
                  NavigationDestination(
                    icon: Icon(destination.icon),
                    selectedIcon: Icon(destination.selectedIcon),
                    label: destination.label,
                  ),
              ],
            ),
          );
        }

        final extended = AppBreakpoints.usesExtendedNavigation(
          constraints.maxWidth,
        );

        return Scaffold(
          body: SafeArea(
            child: Row(
              children: [
                NavigationRail(
                  extended: extended,
                  minWidth: 80,
                  minExtendedWidth: 240,
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (index) => _navigate(context, index),
                  leading: Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: extended ? 20 : 16,
                    ),
                    child: extended ? const _BrandHeader() : const _BrandMark(),
                  ),
                  destinations: [
                    for (final destination in _destinations)
                      NavigationRailDestination(
                        icon: Icon(destination.icon),
                        selectedIcon: Icon(destination.selectedIcon),
                        label: Text(destination.label),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: child),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        _BrandMark(),
        SizedBox(width: 12),
        SizedBox(
          width: 145,
          child: Text(
            AppStrings.appTitle,
            maxLines: 2,
            style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.4),
          ),
        ),
      ],
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.softPurple,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.sports_cricket,
        color: AppColors.neonPink,
        size: 23,
      ),
    );
  }
}

class _AppDestination {
  const _AppDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.path,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String path;
}

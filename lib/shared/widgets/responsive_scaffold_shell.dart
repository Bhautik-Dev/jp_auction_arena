import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/enums.dart';
import 'app_sidebar.dart';
import 'connection_indicator.dart';
import 'nav_items.dart';

class ResponsiveScaffoldShell extends ConsumerWidget {
  final Widget child;
  final GoRouterState state;

  const ResponsiveScaffoldShell({
    super.key,
    required this.child,
    required this.state,
  });

  void _showMoreMenu(BuildContext context, WidgetRef ref, String currentPath) {
    final secondaryItems = getFilteredSecondaryNavItems(UserRole.admin);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: AppColors.cardBorder, width: 1.2),
      ),
      builder: (ctx) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'More Auction Tools',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'JP Arena User',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: secondaryItems.map((item) {
                    final isSelected = currentPath.startsWith(item.path);
                    return SizedBox(
                      width: 160,
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(ctx);
                          context.go(item.path);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.surfaceLight
                                : AppColors.surfaceLight.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? AppColors.accentPink : AppColors.cardBorder,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                item.icon,
                                color: isSelected ? AppColors.accentPink : AppColors.primaryBlue,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item.label,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : AppColors.textSecondary,
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPath = state.matchedLocation;
    final primaryItems = getFilteredPrimaryNavItems(UserRole.admin);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;

        if (isDesktop) {
          // Desktop & Tablet Landscape: Left Sidebar + Content
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Row(
              children: [
                AppSidebar(currentPath: currentPath),
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.background,
                          Color(0xFF0D1432),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: child,
                  ),
                ),
              ],
            ),
          );
        }

        // Mobile & Tablet Portrait: App Bar + Content + Bottom Nav with More
        final activeIndex = primaryItems.indexWhere((item) => currentPath.startsWith(item.path));
        final isSecondaryActive = activeIndex == -1;

        final visibleTabs = primaryItems.take(4).toList();

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.card,
            elevation: 0,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: AppColors.buttonGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.sports_cricket_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                const Text(
                  'JP AUCTION ARENA',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
              ],
            ),
            actions: [
              const ConnectionIndicator(compact: true),
            ],
          ),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.background,
                  Color(0xFF0D1432),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: child,
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: isSecondaryActive
                ? visibleTabs.length
                : (activeIndex >= 0 && activeIndex < visibleTabs.length ? activeIndex : 0),
            onTap: (index) {
              if (index < visibleTabs.length) {
                context.go(visibleTabs[index].path);
              } else {
                _showMoreMenu(context, ref, currentPath);
              }
            },
            items: [
              ...visibleTabs.map(
                (item) => BottomNavigationBarItem(
                  icon: Icon(item.icon),
                  activeIcon: Icon(item.activeIcon),
                  label: item.label,
                ),
              ),
              BottomNavigationBarItem(
                icon: Icon(
                  isSecondaryActive ? Icons.grid_view_rounded : Icons.more_horiz_rounded,
                  color: isSecondaryActive ? AppColors.accentPink : null,
                ),
                label: isSecondaryActive ? 'Active' : 'More',
              ),
            ],
          ),
        );
      },
    );
  }
}

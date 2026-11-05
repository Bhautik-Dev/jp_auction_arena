import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routing/route_names.dart';
import '../../core/widgets/gradient_button.dart';
import '../../data/models/enums.dart';
import '../../data/repositories/auth_provider.dart';
import 'nav_items.dart';

class AppSidebar extends ConsumerWidget {
  final String currentPath;

  const AppSidebar({
    super.key,
    required this.currentPath,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final userRole = authState.currentRole;
    final primaryItems = getFilteredPrimaryNavItems(userRole);
    final secondaryItems = getFilteredSecondaryNavItems(userRole);

    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(
          right: BorderSide(
            color: AppColors.cardBorder,
            width: 1.2,
          ),
        ),
      ),
      child: Column(
        children: [
          // App Logo & Brand header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: AppColors.buttonGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryBlue.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.sports_cricket_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'JP AUCTION',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'ARENA',
                        style: TextStyle(
                          color: AppColors.accentPink,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // User Profile & Role badge pill
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.accentPink.withValues(alpha: 0.2),
                    child: Text(
                      authState.settings.profileName.isNotEmpty
                          ? authState.settings.profileName[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        color: AppColors.accentPink,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authState.settings.profileName.isNotEmpty
                              ? authState.settings.profileName
                              : 'JP Arena User',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Role: ${userRole.displayName.toUpperCase()}',
                          style: TextStyle(
                            color: userRole == UserRole.admin
                                ? AppColors.gold
                                : (userRole == UserRole.operator
                                    ? AppColors.primaryBlue
                                    : AppColors.success),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Logout icon
                  IconButton(
                    icon: const Icon(Icons.logout_rounded, size: 18, color: AppColors.textMuted),
                    tooltip: 'Logout',
                    onPressed: () {
                      ref.read(authProvider.notifier).logout();
                      context.go(RouteNames.loginPath);
                    },
                  ),
                ],
              ),
            ),
          ),

          // Live Arena Action Button (if allowed)
          if (userRole.canRunLiveAuction)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: GradientButton(
                onPressed: () => context.go(RouteNames.livePath),
                icon: Icons.play_arrow_rounded,
                label: 'Live Hammer Desk',
              ),
            ),

          // Scrollable Nav List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Text(
                    'MAIN MENU',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                ...primaryItems.map((item) => _buildNavItem(context, item)),
                if (secondaryItems.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Text(
                      'TOURNAMENT TOOLS',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  ...secondaryItems.map((item) => _buildNavItem(context, item)),
                ],
              ],
            ),
          ),

          // Bottom offline badge
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: const Row(
                children: [
                  CircleAvatar(radius: 4, backgroundColor: AppColors.success),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Hive Local Storage • Offline',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, NavItem item) {
    final isSelected = currentPath.startsWith(item.path);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: isSelected ? AppColors.surfaceLight : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.go(item.path),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: AppColors.accentPink.withValues(alpha: 0.5))
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? item.activeIcon : item.icon,
                  size: 20,
                  color: isSelected ? AppColors.accentPink : AppColors.textSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.accentPink,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

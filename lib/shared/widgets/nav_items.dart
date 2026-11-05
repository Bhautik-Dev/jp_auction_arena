import 'package:flutter/material.dart';
import '../../data/models/enums.dart';

class NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String path;
  final List<UserRole> allowedRoles;

  const NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.path,
    this.allowedRoles = const [UserRole.admin, UserRole.operator, UserRole.viewer],
  });
}

const List<NavItem> primaryNavItems = [
  NavItem(
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    activeIcon: Icons.dashboard_rounded,
    path: '/dashboard',
    allowedRoles: [UserRole.admin, UserRole.operator, UserRole.viewer],
  ),
  NavItem(
    label: 'Live Arena',
    icon: Icons.gavel_outlined,
    activeIcon: Icons.gavel_rounded,
    path: '/live',
    allowedRoles: [UserRole.admin, UserRole.operator],
  ),
  NavItem(
    label: 'Results',
    icon: Icons.checklist_outlined,
    activeIcon: Icons.checklist_rounded,
    path: '/results',
    allowedRoles: [UserRole.admin, UserRole.operator, UserRole.viewer],
  ),
  NavItem(
    label: 'Auctions',
    icon: Icons.emoji_events_outlined,
    activeIcon: Icons.emoji_events_rounded,
    path: '/auctions',
    allowedRoles: [UserRole.admin],
  ),
  NavItem(
    label: 'Teams',
    icon: Icons.groups_outlined,
    activeIcon: Icons.groups_rounded,
    path: '/teams',
    allowedRoles: [UserRole.admin, UserRole.operator],
  ),
  NavItem(
    label: 'Players',
    icon: Icons.person_search_outlined,
    activeIcon: Icons.person_search_rounded,
    path: '/players',
    allowedRoles: [UserRole.admin, UserRole.operator],
  ),
];

const List<NavItem> secondaryNavItems = [
  NavItem(
    label: 'Projector Stage',
    icon: Icons.tv_outlined,
    activeIcon: Icons.tv_rounded,
    path: '/projector',
    allowedRoles: [UserRole.admin, UserRole.operator, UserRole.viewer],
  ),
  NavItem(
    label: 'Analytics',
    icon: Icons.analytics_outlined,
    activeIcon: Icons.analytics_rounded,
    path: '/analytics',
    allowedRoles: [UserRole.admin, UserRole.operator, UserRole.viewer],
  ),
  NavItem(
    label: 'Create Auction',
    icon: Icons.add_circle_outline_rounded,
    activeIcon: Icons.add_circle_rounded,
    path: '/create-auction',
    allowedRoles: [UserRole.admin],
  ),
  NavItem(
    label: 'Player Register',
    icon: Icons.app_registration_outlined,
    activeIcon: Icons.app_registration_rounded,
    path: '/registration',
    allowedRoles: [UserRole.admin],
  ),
  NavItem(
    label: 'Access Controls',
    icon: Icons.lock_outline_rounded,
    activeIcon: Icons.lock_rounded,
    path: '/access',
    allowedRoles: [UserRole.admin],
  ),
  NavItem(
    label: 'Settings',
    icon: Icons.settings_outlined,
    activeIcon: Icons.settings_rounded,
    path: '/settings',
    allowedRoles: [UserRole.admin],
  ),
];

List<NavItem> getFilteredPrimaryNavItems(UserRole role) {
  return primaryNavItems.where((i) => i.allowedRoles.contains(role)).toList();
}

List<NavItem> getFilteredSecondaryNavItems(UserRole role) {
  return secondaryNavItems.where((i) => i.allowedRoles.contains(role)).toList();
}

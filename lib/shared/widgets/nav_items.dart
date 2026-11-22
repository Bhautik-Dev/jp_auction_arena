import 'package:flutter/material.dart';
import '../../data/models/enums.dart';

class NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String path;

  const NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.path,
  });
}

const List<NavItem> primaryNavItems = [
  NavItem(
    label: 'Results',
    icon: Icons.checklist_outlined,
    activeIcon: Icons.checklist_rounded,
    path: '/results',
  ),
  NavItem(
    label: 'Operator Dashboard',
    icon: Icons.dashboard_outlined,
    activeIcon: Icons.dashboard_rounded,
    path: '/operator-dashboard',
  ),
  NavItem(
    label: 'Auctions',
    icon: Icons.emoji_events_outlined,
    activeIcon: Icons.emoji_events_rounded,
    path: '/auctions',
  ),
  NavItem(
    label: 'Teams',
    icon: Icons.groups_outlined,
    activeIcon: Icons.groups_rounded,
    path: '/teams',
  ),
  NavItem(
    label: 'Players',
    icon: Icons.person_search_outlined,
    activeIcon: Icons.person_search_rounded,
    path: '/players',
  ),
];

const List<NavItem> secondaryNavItems = [
  NavItem(
    label: 'Projector Stage',
    icon: Icons.tv_outlined,
    activeIcon: Icons.tv_rounded,
    path: '/projector',
  ),
  NavItem(
    label: 'Player Register',
    icon: Icons.app_registration_outlined,
    activeIcon: Icons.app_registration_rounded,
    path: '/players',
  ),
  NavItem(
    label: 'Settings',
    icon: Icons.settings_outlined,
    activeIcon: Icons.settings_rounded,
    path: '/settings',
  ),
  NavItem(
    label: 'Operators',
    icon: Icons.supervised_user_circle_outlined,
    activeIcon: Icons.supervised_user_circle_rounded,
    path: '/operators',
  ),
];

List<NavItem> getFilteredPrimaryNavItems(UserRole role) {
  return primaryNavItems;
}

List<NavItem> getFilteredSecondaryNavItems(UserRole role) {
  return secondaryNavItems;
}

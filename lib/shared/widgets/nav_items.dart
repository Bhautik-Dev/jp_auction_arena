import 'package:flutter/material.dart';

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
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    activeIcon: Icons.dashboard_rounded,
    path: '/dashboard',
  ),
  NavItem(
    label: 'Auctions',
    icon: Icons.emoji_events_outlined,
    activeIcon: Icons.emoji_events_rounded,
    path: '/auctions',
  ),
  NavItem(
    label: 'Live Arena',
    icon: Icons.gavel_outlined,
    activeIcon: Icons.gavel_rounded,
    path: '/live',
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
    label: 'Create Auction',
    icon: Icons.add_circle_outline_rounded,
    activeIcon: Icons.add_circle_rounded,
    path: '/create-auction',
  ),
  NavItem(
    label: 'Projector',
    icon: Icons.tv_outlined,
    activeIcon: Icons.tv_rounded,
    path: '/projector',
  ),
  NavItem(
    label: 'Results',
    icon: Icons.checklist_outlined,
    activeIcon: Icons.checklist_rounded,
    path: '/results',
  ),
  NavItem(
    label: 'Registration',
    icon: Icons.app_registration_outlined,
    activeIcon: Icons.app_registration_rounded,
    path: '/registration',
  ),
  NavItem(
    label: 'Access PIN',
    icon: Icons.lock_outline_rounded,
    activeIcon: Icons.lock_rounded,
    path: '/access',
  ),
  NavItem(
    label: 'Analytics',
    icon: Icons.analytics_outlined,
    activeIcon: Icons.analytics_rounded,
    path: '/analytics',
  ),
  NavItem(
    label: 'Settings',
    icon: Icons.settings_outlined,
    activeIcon: Icons.settings_rounded,
    path: '/settings',
  ),
];

List<NavItem> get allNavItems => [...primaryNavItems, ...secondaryNavItems];

import 'package:flutter/material.dart';

class NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const NavItem(this.icon, this.activeIcon, this.label);
}

const List<NavItem> navItems = [
  NavItem(Icons.home_outlined,      Icons.home_rounded,      'Home'),
  NavItem(Icons.swap_vert_outlined, Icons.swap_vert_rounded, 'Cashflow'),
  NavItem(Icons.grid_view_outlined, Icons.grid_view_rounded, 'Budgets'),
  NavItem(Icons.person_outline,     Icons.person_rounded,    'Account'),
];

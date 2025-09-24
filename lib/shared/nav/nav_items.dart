import 'package:flutter/material.dart';

class NavItem {
  final IconData icon;
  final String label;
  const NavItem(this.icon, this.label);
}

const List<NavItem> navItems = [
  NavItem(Icons.dashboard, 'Dashboard'),
  NavItem(Icons.category, 'Categories'),
  NavItem(Icons.trending_up, 'Cash Flow'),
  NavItem(Icons.account_circle, 'Account'),
];

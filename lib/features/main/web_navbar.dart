import 'package:flutter/material.dart';
import '../main/main_page_notifier.dart';
import '../../shared/nav/nav_items.dart';

class WebNavbar extends StatelessWidget {
  final MainPageNotifier notifier;
  const WebNavbar({super.key, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      minWidth: 200,
      selectedIndex: notifier.selectedIndex,
      onDestinationSelected: notifier.setIndex,
      labelType: NavigationRailLabelType.all,
      backgroundColor: Theme.of(context).primaryColor,
      leading: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Text('Spendo',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onPrimary)),
      ),
      destinations: navItems
          .map((item) => NavigationRailDestination(
                icon: Icon(item.icon, color: Colors.white),
                label: Text(item.label, style: const TextStyle(color: Colors.white)),
              ))
          .toList(),
    );
  }
}

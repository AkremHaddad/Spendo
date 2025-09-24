import 'package:flutter/material.dart';
import '../main/main_page_notifier.dart';
import '../../shared/nav/nav_items.dart';

class MobileNavbar extends StatelessWidget {
  final MainPageNotifier notifier;
  const MobileNavbar({super.key, required this.notifier});

  @override
  Widget build(BuildContext context) {
    // Using BottomAppBar + IconButtons leaves room for a center FAB.
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 6,
      color: Theme.of(context).primaryColor,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // first two
            IconButton(
              icon: Icon(navItems[0].icon, color: _iconColor(context, 0, notifier.selectedIndex)),
              onPressed: () => notifier.setIndex(0),
            ),
            IconButton(
              icon: Icon(navItems[1].icon, color: _iconColor(context, 1, notifier.selectedIndex)),
              onPressed: () => notifier.setIndex(1),
            ),

            const SizedBox(width: 48), // space for FAB

            // last two
            IconButton(
              icon: Icon(navItems[2].icon, color: _iconColor(context, 2, notifier.selectedIndex)),
              onPressed: () => notifier.setIndex(2),
            ),
            IconButton(
              icon: Icon(navItems[3].icon, color: _iconColor(context, 3, notifier.selectedIndex)),
              onPressed: () => notifier.setIndex(3),
            ),
          ],
        ),
      ),
    );
  }

  Color _iconColor(BuildContext context, int index, int selected) {
    return index == selected ? Colors.white : Colors.white70;
  }
}

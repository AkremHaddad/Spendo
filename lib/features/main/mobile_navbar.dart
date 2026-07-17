import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main/main_page_notifier.dart';
import '../../shared/nav/nav_items.dart';
import '../../core/theme/theme.dart';

class MobileNavbar extends StatelessWidget {
  final MainPageNotifier notifier;
  final VoidCallback? onFabTap;

  const MobileNavbar({super.key, required this.notifier, this.onFabTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = notifier.selectedIndex;

    return Container(
      decoration: BoxDecoration(
        color: theme.surface,
        border: Border(top: BorderSide(color: theme.border)),
      ),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavBtn(item: navItems[0], active: selected == 0, onTap: () => notifier.setIndex(0)),
          _NavBtn(item: navItems[1], active: selected == 1, onTap: () => notifier.setIndex(1)),

          // Centre FAB
          GestureDetector(
            onTap: onFabTap,
            child: Container(
              width: 54,
              height: 54,
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: theme.accentColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: theme.accentSoftColor,
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(Icons.add_rounded, color: theme.accentInkColor, size: 26),
            ),
          ),

          _NavBtn(item: navItems[2], active: selected == 2, onTap: () => notifier.setIndex(2)),
          _NavBtn(item: navItems[3], active: selected == 3, onTap: () => notifier.setIndex(3)),
        ],
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final NavItem item;
  final bool active;
  final VoidCallback onTap;

  const _NavBtn({required this.item, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              active ? item.activeIcon : item.icon,
              size: 22,
              color: active ? theme.accentInkSoftColor : theme.ink3,
            ),
            const SizedBox(height: 2),
            Text(
              item.label,
              style: GoogleFonts.instrumentSans(
                fontSize: 10.5,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                color: active ? theme.accentInkSoftColor : theme.ink3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

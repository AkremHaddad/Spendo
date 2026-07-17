import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main/main_page_notifier.dart';
import '../../shared/nav/nav_items.dart';
import '../../core/theme/theme.dart';

class WebNavbar extends StatelessWidget {
  final MainPageNotifier notifier;
  const WebNavbar({super.key, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = notifier.selectedIndex;

    return Container(
      width: 220,
      height: double.infinity,
      decoration: BoxDecoration(
        color: theme.surface,
        border: Border(right: BorderSide(color: theme.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Row(
              children: [
                _SpendoLogo(size: 32),
                const SizedBox(width: 10),
                Text(
                  'Spendo',
                  style: GoogleFonts.instrumentSerif(
                    fontSize: 24,
                    color: theme.ink,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),

          // Nav items
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              children: List.generate(navItems.length, (i) {
                final item = navItems[i];
                final active = i == selected;
                return _NavButton(
                  icon: active ? item.activeIcon : item.icon,
                  label: item.label,
                  active: active,
                  onTap: () => notifier.setIndex(i),
                );
              }),
            ),
          ),

          const Spacer(),

          // Streak motivator card
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.tintButterBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Keep it up! 🔥',
                    style: GoogleFonts.instrumentSerif(
                      fontSize: 16,
                      color: theme.tintButterInk,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Log your spending today',
                    style: GoogleFonts.instrumentSans(
                      fontSize: 11.5,
                      color: theme.tintButterInk.withOpacity(0.8),
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
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(bottom: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: active ? theme.accentSoftColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: active ? theme.accentInkSoftColor : theme.ink2,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: GoogleFonts.instrumentSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: active ? theme.accentInkSoftColor : theme.ink2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpendoLogo extends StatelessWidget {
  final double size;
  const _SpendoLogo({required this.size});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [theme.accentColor, theme.tintSkyInk],
        ),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Center(
        child: Text(
          '\$',
          style: GoogleFonts.instrumentSerif(
            fontSize: size * 0.55,
            color: Colors.white,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

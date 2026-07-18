import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../auth/auth_page.dart';
import '../../core/theme/theme.dart';
import '../../core/utils/responsive.dart';
import '../main/theme_notifier.dart';
import '../dashboard/logic/dashboardNotifier.dart';
import '../cashflow/data/models/cashflow.dart';
import '../categories/logic/categoryNotifier.dart';

// ─── Card helper ──────────────────────────────────────────────────────────────
Widget _card({
  required BuildContext context,
  required Widget child,
  Color? bg,
  EdgeInsets padding = const EdgeInsets.all(20),
}) {
  final theme = Theme.of(context);
  return Container(
    decoration: bg != null ? theme.tintCardDecoration(bg) : theme.cardDecoration,
    padding: padding,
    child: child,
  );
}

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthPage()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeNotifier = context.watch<ThemeNotifier>();
    final dashNotifier = context.watch<DashboardNotifier>();
    final catNotifier = context.watch<CategoryNotifier>();
    final user = FirebaseAuth.instance.currentUser;
    final mobile = isMobile(context);
    final compact = isCompact(context);

    final displayName = user?.displayName ?? user?.email?.split('@').first ?? 'User';
    final email = user?.email ?? '';

    // Lifetime stats
    final txCount = dashNotifier.cashflows.length;
    final balance = dashNotifier.balance;
    final totalIncome = dashNotifier.cashflows
        .where((c) => c.isIncome)
        .fold(0.0, (s, c) => s + c.amount);

    final stats = [
      (icon: Icons.account_balance_wallet_rounded, value: '\$${balance.toStringAsFixed(0)}', label: 'Net worth'),
      (icon: Icons.trending_up_rounded, value: '\$${totalIncome.toStringAsFixed(0)}', label: 'Total income'),
      (icon: Icons.receipt_long_rounded, value: '$txCount', label: 'Transactions'),
    ];

    // Settings rows
    final settings = [
      (
        icon: Icons.dark_mode_outlined,
        title: 'Appearance',
        sub: _themeModeLabel(themeNotifier.themeMode),
        tintBg: theme.tintLavenderBg,
        tintInk: theme.tintLavenderInk,
        onTap: () => _showThemeModeDialog(context, themeNotifier) as VoidCallback?,
      ),
    ];

    return Scaffold(
      backgroundColor: theme.bg,
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          mobile ? 16 : 28,
          mobile ? 16 : 28,
          mobile ? 16 : 28,
          32,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Page header ──────────────────────────────────────────────
            Text('Your account', style: theme.serif(mobile ? 28 : 36)),
            const SizedBox(height: 4),
            Text('Settings & achievements',
                style: theme.sans(13.5, color: theme.ink2)),

            SizedBox(height: mobile ? 14 : 18),

            // ── Profile (kept minimal on purpose — just who's signed in) ──
            Text(displayName, style: theme.serif(mobile ? 20 : 24)),
            const SizedBox(height: 2),
            Text(email, style: theme.sans(13, color: theme.ink2)),

            SizedBox(height: mobile ? 14 : 18),

            // ── Stats row ────────────────────────────────────────────────
            Row(
              children: stats.asMap().entries.map((e) {
                final i = e.key;
                final s = e.value;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: i > 0 ? 12 : 0),
                    child: _card(
                      context: context,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(s.icon, size: 20, color: theme.ink2),
                          const SizedBox(height: 6),
                          Text(
                            s.value,
                            style: GoogleFonts.instrumentSerif(
                              fontSize: mobile ? 18 : 22,
                              color: theme.ink,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(s.label,
                              style: theme.sans(11, color: theme.ink2),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            SizedBox(height: mobile ? 12 : 16),

            // ── Achievements ─────────────────────────────────────────────
            _card(
              context: context,
              padding: EdgeInsets.all(mobile ? 20 : 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Achievements', style: theme.serif(mobile ? 22 : 26)),
                          const SizedBox(height: 2),
                          Text('Keep logging to unlock more',
                              style: theme.sans(13, color: theme.ink2)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.tintButterBg,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.emoji_events_rounded, size: 14, color: theme.tintButterInk),
                            const SizedBox(width: 4),
                            Text(_level(txCount),
                                style: theme.sans(12, color: theme.tintButterInk, weight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _AchievementsGrid(
                      dashNotifier: dashNotifier, catNotifier: catNotifier, compact: compact),
                ],
              ),
            ),

            SizedBox(height: mobile ? 12 : 16),

            // ── Settings ────────────────────────────────────────────────
            _card(
              context: context,
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              child: Column(
                children: [
                  // Sign out always follows, so every mapped row here gets a divider.
                  ...settings.map((row) {
                    return _SettingsRow(
                      icon: row.icon,
                      title: row.title,
                      sub: row.sub,
                      tintBg: row.tintBg,
                      tintInk: row.tintInk,
                      showDivider: true,
                      onTap: row.onTap ?? () {},
                    );
                  }),
                  _SettingsRow(
                    icon: Icons.logout_rounded,
                    title: 'Sign out',
                    sub: '',
                    tintBg: theme.tintCoralBg,
                    tintInk: theme.tintCoralInk,
                    showDivider: false,
                    onTap: () => _logout(context),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            Center(
              child: Text(
                'Spendo · Made with 💚',
                style: theme.sans(11.5, color: theme.ink3),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _level(int txCount) {
    if (txCount >= 200) return 'Level 5';
    if (txCount >= 100) return 'Level 4';
    if (txCount >= 50)  return 'Level 3';
    if (txCount >= 20)  return 'Level 2';
    return 'Level 1';
  }
}

String _themeModeLabel(ThemeMode mode) {
  switch (mode) {
    case ThemeMode.light:
      return 'Light';
    case ThemeMode.dark:
      return 'Dark';
    case ThemeMode.system:
      return 'System';
  }
}

/// Explicit 3-way picker (Light/Dark/System) — replaces a single ambiguous
/// toggle that couldn't represent "system" and silently forced light/dark
/// on first tap regardless of which one was actually showing.
void _showThemeModeDialog(BuildContext context, ThemeNotifier notifier) {
  showDialog(
    context: context,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      return AlertDialog(
        title: Text('Appearance', style: theme.serif(22)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ThemeModeOption(
              icon: Icons.light_mode_outlined,
              label: 'Light',
              selected: notifier.themeMode == ThemeMode.light,
              onTap: () {
                notifier.setThemeMode(ThemeMode.light);
                Navigator.pop(ctx);
              },
            ),
            _ThemeModeOption(
              icon: Icons.dark_mode_outlined,
              label: 'Dark',
              selected: notifier.themeMode == ThemeMode.dark,
              onTap: () {
                notifier.setThemeMode(ThemeMode.dark);
                Navigator.pop(ctx);
              },
            ),
            _ThemeModeOption(
              icon: Icons.brightness_auto_outlined,
              label: 'System',
              selected: notifier.themeMode == ThemeMode.system,
              onTap: () {
                notifier.setThemeMode(ThemeMode.system);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ],
      );
    },
  );
}

class _ThemeModeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeModeOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: selected ? theme.accentColor : theme.ink2),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label, style: theme.sans(14, weight: FontWeight.w500)),
            ),
            if (selected) Icon(Icons.check_rounded, size: 18, color: theme.accentColor),
          ],
        ),
      ),
    );
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _AchievementsGrid extends StatelessWidget {
  final DashboardNotifier dashNotifier;
  final CategoryNotifier catNotifier;
  final bool compact;

  const _AchievementsGrid({
    required this.dashNotifier,
    required this.catNotifier,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Practical achievements tied to actually using the app's real features
    // (goals, categories, products, budgeting discipline) rather than pure
    // transaction-count vanity milestones.
    final txCount = dashNotifier.cashflows.length;
    final hasIncome = dashNotifier.cashflows.any((c) => c.isIncome);
    final categories = catNotifier.categories;
    final hasCategoryGoal = categories.any((c) => c.monthlyGoal != null);
    final hasProducts = categories.any((c) => c.visibleProducts.isNotEmpty);
    final monthlyGoal = dashNotifier.monthlyGoal;
    final underBudget = monthlyGoal != null && dashNotifier.monthExpenses <= monthlyGoal;
    final distinctDays = dashNotifier.cashflows
        .map((c) => DateTime(c.date.year, c.date.month, c.date.day))
        .toSet()
        .length;

    final achievements = [
      (icon: Icons.receipt_long_rounded, name: 'First entry', desc: 'Logged your first transaction',
       earned: txCount >= 1, tintBg: theme.tintMintBg, tintInk: theme.tintMintInk),
      (icon: Icons.payments_rounded, name: 'First income', desc: 'Logged an income entry',
       earned: hasIncome, tintBg: theme.tintSkyBg, tintInk: theme.tintSkyInk),
      (icon: Icons.flag_rounded, name: 'Goal setter', desc: 'Set a monthly budget goal',
       earned: monthlyGoal != null, tintBg: theme.tintLavenderBg, tintInk: theme.tintLavenderInk),
      (icon: Icons.track_changes_rounded, name: 'Category goal', desc: 'Set a goal for a category',
       earned: hasCategoryGoal, tintBg: theme.tintRoseBg, tintInk: theme.tintRoseInk),
      (icon: Icons.inventory_2_rounded, name: 'Organized', desc: 'Added a product to a category',
       earned: hasProducts, tintBg: theme.tintButterBg, tintInk: theme.tintButterInk),
      (icon: Icons.grid_view_rounded, name: 'Multi-tracker', desc: 'Using 5+ categories',
       earned: categories.length >= 5, tintBg: theme.tintCoralBg, tintInk: theme.tintCoralInk),
      (icon: Icons.savings_rounded, name: 'Saver', desc: 'Positive net worth',
       earned: dashNotifier.balance > 0, tintBg: theme.tintMintBg, tintInk: theme.tintMintInk),
      (icon: Icons.verified_rounded, name: 'Budget keeper', desc: 'Under budget this month',
       earned: underBudget, tintBg: theme.tintSkyBg, tintInk: theme.tintSkyInk),
      (icon: Icons.local_fire_department_rounded, name: 'Consistent', desc: 'Logged on 5+ different days',
       earned: distinctDays >= 5, tintBg: theme.tintLavenderBg, tintInk: theme.tintLavenderInk),
    ];

    return LayoutBuilder(
      builder: (ctx, constraints) {
        // Below `compact` (which already covers all mobile widths — see
        // Breakpoints.compact) there isn't room for 3 columns without the
        // name/desc text overflowing each tile.
        final cols = compact ? 2 : 3;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: achievements.map((a) {
            return SizedBox(
              width: (constraints.maxWidth - (cols - 1) * 12) / cols,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: a.earned ? a.tintBg : theme.surface2,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Opacity(
                  opacity: a.earned ? 1.0 : 0.5,
                  child: Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: a.earned ? a.tintInk : theme.ink3,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(a.icon, size: 20, color: Colors.white),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(a.name,
                                      style: theme.sans(12, weight: FontWeight.w600,
                                          color: a.earned ? a.tintInk : theme.ink),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                ),
                                if (a.earned)
                                  Icon(Icons.check_rounded,
                                      size: 14, color: a.tintInk),
                              ],
                            ),
                            Text(a.desc,
                                style: theme.sans(10.5, color: a.earned ? a.tintInk.withOpacity(0.8) : theme.ink2),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title, sub;
  final Color tintBg, tintInk;
  final bool showDivider;
  final VoidCallback onTap;

  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.sub,
    required this.tintBg,
    required this.tintInk,
    required this.showDivider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Row(
              children: [
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: tintBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 18, color: tintInk),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.sans(14, weight: FontWeight.w500)),
                      if (sub.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(sub, style: theme.sans(12, color: theme.ink2)),
                      ],
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, size: 16, color: theme.ink3),
              ],
            ),
          ),
        ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Divider(height: 1, color: theme.border),
          ),
      ],
    );
  }
}

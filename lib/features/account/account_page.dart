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
    final user = FirebaseAuth.instance.currentUser;
    final mobile = isMobile(context);

    final isDark = themeNotifier.themeMode == ThemeMode.dark;
    final displayName = user?.displayName ?? user?.email?.split('@').first ?? 'User';
    final email = user?.email ?? '';
    final initials = _initials(displayName);

    // Lifetime stats
    final txCount = dashNotifier.cashflows.length;
    final balance = dashNotifier.balance;
    final totalIncome = dashNotifier.cashflows
        .where((c) => c.isIncome)
        .fold(0.0, (s, c) => s + c.amount);

    final stats = [
      (emoji: '💰', value: '\$${balance.toStringAsFixed(0)}', label: 'Net worth'),
      (emoji: '📈', value: '\$${totalIncome.toStringAsFixed(0)}', label: 'Total income'),
      (emoji: '🧾', value: '$txCount', label: 'Transactions'),
      (emoji: '🔥', value: 'Active', label: 'Status'),
    ];

    // Settings rows
    final settings = [
      (
        icon: Icons.notifications_outlined,
        title: 'Notifications',
        sub: 'Daily nudges, weekly summary',
        tintBg: theme.tintButterBg,
        tintInk: theme.tintButterInk,
        onTap: null as VoidCallback?,
      ),
      (
        icon: isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
        title: isDark ? 'Switch to Light mode' : 'Switch to Dark mode',
        sub: 'Toggle app appearance',
        tintBg: theme.tintLavenderBg,
        tintInk: theme.tintLavenderInk,
        onTap: () => themeNotifier.toggleTheme() as VoidCallback?,
      ),
      (
        icon: Icons.privacy_tip_outlined,
        title: 'Privacy & data',
        sub: 'Export, anonymize, delete',
        tintBg: theme.tintMintBg,
        tintInk: theme.tintMintInk,
        onTap: null as VoidCallback?,
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
            Text('Settings, achievements, plan',
                style: theme.sans(13.5, color: theme.ink2)),

            SizedBox(height: mobile ? 16 : 20),

            // ── Profile hero ─────────────────────────────────────────────
            _card(
              context: context,
              padding: EdgeInsets.all(mobile ? 22 : 32),
              child: Stack(
                children: [
                  // Decorative gradient blob
                  Positioned(
                    right: -60,
                    top: -60,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            theme.tintLavenderBg,
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  mobile
                      ? Column(
                          children: [
                            _Avatar(initials: initials, size: 96),
                            const SizedBox(height: 16),
                            _ProfileInfo(
                              displayName: displayName,
                              email: email,
                              mobile: mobile,
                              onLogout: () => _logout(context),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            _Avatar(initials: initials, size: 120),
                            const SizedBox(width: 24),
                            Expanded(
                              child: _ProfileInfo(
                                displayName: displayName,
                                email: email,
                                mobile: mobile,
                                onLogout: () => _logout(context),
                              ),
                            ),
                          ],
                        ),
                ],
              ),
            ),

            SizedBox(height: mobile ? 12 : 16),

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
                          Text(s.emoji, style: const TextStyle(fontSize: 22)),
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
                        child: Text('🏆 ${_level(txCount)}',
                            style: theme.sans(12, color: theme.tintButterInk, weight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _AchievementsGrid(
                      txCount: txCount, balance: balance, mobile: mobile),
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
                  ...settings.asMap().entries.map((e) {
                    final i = e.key;
                    final row = e.value;
                    return _SettingsRow(
                      icon: row.icon,
                      title: row.title,
                      sub: row.sub,
                      tintBg: row.tintBg,
                      tintInk: row.tintInk,
                      showDivider: i < settings.length - 1,
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

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length.clamp(0, 2)).toUpperCase();
  }

  String _level(int txCount) {
    if (txCount >= 200) return 'Level 5';
    if (txCount >= 100) return 'Level 4';
    if (txCount >= 50)  return 'Level 3';
    if (txCount >= 20)  return 'Level 2';
    return 'Level 1';
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String initials;
  final double size;
  const _Avatar({required this.initials, required this.size});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [theme.tintLavenderBg, theme.tintRoseBg],
        ),
        border: Border.all(color: theme.surface, width: 4),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24, offset: const Offset(0, 8))],
      ),
      child: Center(
        child: Text(
          initials,
          style: GoogleFonts.instrumentSerif(
            fontSize: size * 0.38,
            color: theme.ink,
          ),
        ),
      ),
    );
  }
}

class _ProfileInfo extends StatelessWidget {
  final String displayName, email;
  final bool mobile;
  final VoidCallback onLogout;

  const _ProfileInfo({
    required this.displayName,
    required this.email,
    required this.mobile,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: mobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          displayName,
          style: theme.serif(mobile ? 28 : 40),
          textAlign: mobile ? TextAlign.center : TextAlign.start,
        ),
        const SizedBox(height: 4),
        Text(email, style: theme.sans(13.5, color: theme.ink2)),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          alignment: mobile ? WrapAlignment.center : WrapAlignment.start,
          children: [
            _PillButton(label: 'Edit profile', primary: true),
            _PillButton(label: 'Share Spendo', primary: false),
          ],
        ),
      ],
    );
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final bool primary;
  const _PillButton({required this.label, required this.primary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: primary ? theme.accentColor : Colors.transparent,
        border: primary ? null : Border.all(color: theme.border),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.sans(13, weight: FontWeight.w600,
            color: primary ? theme.accentInkColor : theme.ink),
      ),
    );
  }
}

class _AchievementsGrid extends StatelessWidget {
  final int txCount;
  final double balance;
  final bool mobile;

  const _AchievementsGrid({
    required this.txCount,
    required this.balance,
    required this.mobile,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final achievements = [
      (emoji: '🧾', name: 'First transaction', desc: 'Logged your first entry',
       earned: txCount >= 1, tintBg: theme.tintMintBg, tintInk: theme.tintMintInk),
      (emoji: '🔥', name: 'Getting started', desc: 'Logged 10+ transactions',
       earned: txCount >= 10, tintBg: theme.tintButterBg, tintInk: theme.tintButterInk),
      (emoji: '📊', name: 'Data nerd', desc: 'Logged 50+ transactions',
       earned: txCount >= 50, tintBg: theme.tintSkyBg, tintInk: theme.tintSkyInk),
      (emoji: '💰', name: 'Saver', desc: 'Positive net worth',
       earned: balance > 0, tintBg: theme.tintCoralBg, tintInk: theme.tintCoralInk),
      (emoji: '🏆', name: 'Pro tracker', desc: '100+ transactions logged',
       earned: txCount >= 100, tintBg: theme.tintLavenderBg, tintInk: theme.tintLavenderInk),
      (emoji: '🚀', name: 'Power user', desc: '200+ transactions logged',
       earned: txCount >= 200, tintBg: theme.tintRoseBg, tintInk: theme.tintRoseInk),
    ];

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final cols = mobile ? 2 : 3;
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
                        child: Center(
                          child: Text(a.emoji,
                              style: const TextStyle(fontSize: 20)),
                        ),
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

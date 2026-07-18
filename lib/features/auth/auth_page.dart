import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/theme/theme.dart';
import 'auth_notifier.dart';
import '../main/main_page.dart';

const _featureItems = [
  (Icons.flag_rounded, 'Savings goals'),
  (Icons.auto_awesome_rounded, 'Smart insights'),
  (Icons.pie_chart_rounded, 'Real insights'),
  (Icons.swap_vert_rounded, 'Every transaction'),
];

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLogin = false;
  bool loading = false;
  String? errorMessage;

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final auth = Provider.of<AuthNotifier>(context, listen: false);
    setState(() {
      loading = true;
      errorMessage = null;
    });
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final username = usernameController.text.trim();

    String? error;
    if (isLogin) {
      error = await auth.loginWithEmail(email, password);
    } else if (username.isEmpty) {
      error = 'Name is required';
    } else {
      error = await auth.signUpWithEmail(email, password, username);
    }

    if (!mounted) return;
    setState(() {
      loading = false;
      errorMessage = error;
    });
    if (error == null && context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => MainPage(userId: auth.userId!)),
      );
    }
  }

  Future<void> _handleGoogle() async {
    final auth = Provider.of<AuthNotifier>(context, listen: false);
    setState(() {
      loading = true;
      errorMessage = null;
    });
    final error = await auth.loginWithGoogle();
    if (!mounted) return;
    setState(() {
      loading = false;
      errorMessage = error;
    });
    if (error == null && context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => MainPage(userId: auth.userId!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.bg,
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          final mobile = constraints.maxWidth < 900;
          return mobile ? _buildMobile(context, theme) : _buildDesktop(context, theme);
        }),
      ),
    );
  }

  // ─── Desktop: single screen, no scroll unless the window is too short ──
  Widget _buildDesktop(BuildContext context, ThemeData theme) {
    return Column(
      children: [
        _buildDesktopNav(theme),
        Expanded(
          child: LayoutBuilder(builder: (context, inner) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: inner.maxHeight),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(flex: 42, child: _heroTextBlock(theme, mobile: false)),
                        const SizedBox(width: 48),
                        Expanded(
                          flex: 58,
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 420),
                              child: Stack(
                                clipBehavior: Clip.none,
                                alignment: Alignment.center,
                                children: [
                                  Positioned(
                                    top: -60,
                                    left: -60,
                                    right: -60,
                                    bottom: -60,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: RadialGradient(colors: [theme.tintMintBg, theme.tintMintBg.withOpacity(0)]),
                                      ),
                                    ),
                                  ),
                                  _authSection(context, theme, mobile: false),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildDesktopNav(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 20),
      child: Row(
        children: [
          SvgPicture.asset('assets/images/logoMark.svg', width: 28, height: 28),
          const SizedBox(width: 10),
          Text('Spendo', style: theme.serif(22, color: theme.ink, letterSpacing: -0.02)),
          const Spacer(),
          Row(
            children: [
              for (int i = 0; i < _featureItems.length; i++) ...[
                if (i > 0) const SizedBox(width: 24),
                Icon(_featureItems[i].$1, size: 15, color: theme.tintMintInk),
                const SizedBox(width: 6),
                Text(_featureItems[i].$2, style: theme.sans(12.5, weight: FontWeight.w500, color: theme.ink2)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ─── Mobile: natural scroll ─────────────────────────────────────────────
  Widget _buildMobile(BuildContext context, ThemeData theme) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                SvgPicture.asset('assets/images/logoMark.svg', width: 26, height: 26),
                const SizedBox(width: 10),
                Text('Spendo', style: theme.serif(20, color: theme.ink, letterSpacing: -0.02)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _heroTextBlock(theme, mobile: true),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.6,
              children: [for (final f in _featureItems) _featureRow(theme, f.$1, f.$2)],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: _authSection(context, theme, mobile: true),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _featureRow(ThemeData theme, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: theme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.border)),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: theme.tintMintBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 16, color: theme.tintMintInk),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label, style: theme.sans(12.5, weight: FontWeight.w600, color: theme.ink), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  // ─── Hero text (badge, headline, subhead, stats) — shared ──────────────
  Widget _heroTextBlock(ThemeData theme, {required bool mobile}) {
    return Column(
      crossAxisAlignment: mobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(color: theme.tintButterBg, borderRadius: BorderRadius.circular(999)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome_rounded, size: 13, color: theme.tintButterInk),
              const SizedBox(width: 6),
              Text('Now with smart insights', style: theme.sans(12.5, weight: FontWeight.w600, color: theme.tintButterInk)),
            ],
          ),
        ),
        SizedBox(height: mobile ? 14 : 16),
        Text(
          'Money management that actually feels good',
          textAlign: mobile ? TextAlign.center : TextAlign.start,
          style: theme.serif(mobile ? 34 : 44, color: theme.ink, letterSpacing: -0.03).copyWith(height: mobile ? 1.1 : 1.08),
        ),
        SizedBox(height: mobile ? 14 : 16),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: mobile ? 320 : 420),
          child: Text(
            mobile
                ? 'Track spending, hit savings goals, and build streaks — Spendo turns budgeting '
                    'into something you look forward to.'
                : 'Track spending, hit savings goals, and build streaks — Spendo turns budgeting '
                    'into something you look forward to, not something you dread.',
            textAlign: mobile ? TextAlign.center : TextAlign.start,
            style: theme.sans(mobile ? 14.5 : 15, color: theme.ink2).copyWith(height: mobile ? 1.6 : 1.55),
          ),
        ),
        SizedBox(height: mobile ? 12 : 12),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _stat(theme, '\$2.4M', 'saved by users', mobile),
            SizedBox(width: mobile ? 20 : 24),
            _stat(theme, '4.9★', 'app rating', mobile),
            SizedBox(width: mobile ? 20 : 24),
            _stat(theme, '12k+', 'active users', mobile),
          ],
        ),
      ],
    );
  }

  Widget _stat(ThemeData theme, String value, String label, bool mobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: theme.serif(mobile ? 20 : 22, color: theme.ink, letterSpacing: -0.02)),
        Text(label, style: theme.sans(mobile ? 10.5 : 11, color: theme.ink3)),
      ],
    );
  }

  // ─── Auth section: heading + card, embedded directly in the hero ──────
  Widget _authSection(BuildContext context, ThemeData theme, {required bool mobile}) {
    return Column(
      children: [
        Text(
          isLogin ? 'Welcome back' : 'Create your account',
          textAlign: TextAlign.center,
          style: theme.serif(26, color: theme.ink, letterSpacing: -0.02),
        ),
        const SizedBox(height: 4),
        Text(
          isLogin ? 'Log in to see where your money went.' : 'Start tracking your money in under a minute.',
          textAlign: TextAlign.center,
          style: theme.sans(13, color: theme.ink2),
        ),
        SizedBox(height: mobile ? 16 : 14),
        _authCard(context, theme),
      ],
    );
  }

  Widget _authCard(BuildContext context, ThemeData theme) {
    InputDecoration fieldDecoration(String label) => InputDecoration(
          labelText: label,
          labelStyle: theme.sans(13.5, color: theme.ink2),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: BorderSide(color: theme.accentColor)),
          filled: true,
          fillColor: theme.surface2,
          contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
        );

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 360),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.border),
        boxShadow: theme.brightness == Brightness.dark
            ? []
            : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 24, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: theme.surface2, borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                Expanded(child: _segTab(theme, 'Sign up', active: !isLogin, onTap: () => setState(() => isLogin = false))),
                const SizedBox(width: 6),
                Expanded(child: _segTab(theme, 'Log in', active: isLogin, onTap: () => setState(() => isLogin = true))),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (errorMessage != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: theme.tintCoralBg, borderRadius: BorderRadius.circular(10)),
              child: Text(errorMessage!, style: theme.sans(12.5, color: theme.tintCoralInk)),
            ),
            const SizedBox(height: 12),
          ],
          OutlinedButton.icon(
            icon: Image.asset('assets/images/google.png', height: 18),
            label: Text('Continue with Google', style: theme.sans(13.5, weight: FontWeight.w600, color: theme.ink)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: theme.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: loading ? null : _handleGoogle,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: Divider(color: theme.border)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text('or', style: theme.sans(11.5, color: theme.ink3)),
              ),
              Expanded(child: Divider(color: theme.border)),
            ],
          ),
          const SizedBox(height: 14),
          AnimatedCrossFade(
            firstChild: Column(children: [
              TextField(controller: usernameController, style: theme.sans(13.5, color: theme.ink), decoration: fieldDecoration('Name')),
              const SizedBox(height: 10),
            ]),
            secondChild: const SizedBox.shrink(),
            crossFadeState: isLogin ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
          TextField(
            controller: emailController,
            style: theme.sans(13.5, color: theme.ink),
            decoration: fieldDecoration('Email'),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: passwordController,
            obscureText: true,
            style: theme.sans(13.5, color: theme.ink),
            decoration: fieldDecoration('Password'),
          ),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: theme.accentColor.withOpacity(theme.brightness == Brightness.dark ? 0.2 : 0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: loading ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.accentColor,
                foregroundColor: theme.accentInkColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                elevation: 0,
              ),
              child: loading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: theme.accentInkColor),
                    )
                  : Text(isLogin ? 'Log in' : 'Create account', style: theme.sans(14, weight: FontWeight.w600, color: theme.accentInkColor)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _segTab(ThemeData theme, String label, {required bool active, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: active ? theme.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: active ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)] : [],
        ),
        alignment: Alignment.center,
        child: Text(label, style: theme.sans(13, weight: FontWeight.w600, color: active ? theme.ink : theme.ink2)),
      ),
    );
  }
}

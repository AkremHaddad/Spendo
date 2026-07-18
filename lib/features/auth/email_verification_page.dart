import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/theme.dart';
import '../main/main_page.dart';
import 'auth_notifier.dart';
import 'auth_page.dart';

/// Shown to a signed-in user whose email hasn't been verified yet.
/// Polls Firebase periodically so the app moves on automatically once the
/// user clicks the link in their inbox, without requiring a manual refresh.
class EmailVerificationPage extends StatefulWidget {
  const EmailVerificationPage({super.key});

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  Timer? _pollTimer;
  bool _checking = false;
  bool _resending = false;
  String? _message;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _checkVerified());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkVerified() async {
    if (!mounted) return;
    final auth = Provider.of<AuthNotifier>(context, listen: false);
    final verified = await auth.refreshEmailVerifiedStatus();
    if (!mounted) return;
    if (verified) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => MainPage(userId: auth.userId!)),
      );
    }
  }

  Future<void> _handleManualCheck() async {
    setState(() {
      _checking = true;
      _message = null;
    });
    await _checkVerified();
    if (!mounted) return;
    setState(() {
      _checking = false;
      if (!Provider.of<AuthNotifier>(context, listen: false).isEmailVerified) {
        _message = 'Still not verified — check your inbox (and spam folder).';
      }
    });
  }

  Future<void> _handleResend() async {
    if (_resendCooldown > 0) return;
    final auth = Provider.of<AuthNotifier>(context, listen: false);
    setState(() {
      _resending = true;
      _message = null;
    });
    final error = await auth.resendVerificationEmail();
    if (!mounted) return;
    setState(() {
      _resending = false;
      _message = error == null ? 'Verification email sent.' : error;
    });
    if (error == null) _startCooldown();
  }

  void _startCooldown() {
    setState(() => _resendCooldown = 30);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _resendCooldown -= 1);
      if (_resendCooldown <= 0) timer.cancel();
    });
  }

  Future<void> _handleSignOut() async {
    final auth = Provider.of<AuthNotifier>(context, listen: false);
    await auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthPage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = Provider.of<AuthNotifier>(context, listen: false);
    final email = auth.currentUser?.email ?? '';

    return Scaffold(
      backgroundColor: theme.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: theme.tintMintBg, shape: BoxShape.circle),
                    child: Icon(Icons.mark_email_unread_rounded, size: 30, color: theme.tintMintInk),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Verify your email',
                    textAlign: TextAlign.center,
                    style: theme.serif(26, color: theme.ink, letterSpacing: -0.02),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    email.isEmpty
                        ? 'We sent you a verification link. Click it to continue.'
                        : 'We sent a verification link to $email. Click it to continue.',
                    textAlign: TextAlign.center,
                    style: theme.sans(13.5, color: theme.ink2),
                  ),
                  const SizedBox(height: 24),
                  if (_message != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: theme.surface2, borderRadius: BorderRadius.circular(10)),
                      child: Text(_message!, textAlign: TextAlign.center, style: theme.sans(12.5, color: theme.ink2)),
                    ),
                    const SizedBox(height: 14),
                  ],
                  ElevatedButton(
                    onPressed: _checking ? null : _handleManualCheck,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.accentColor,
                      foregroundColor: theme.accentInkColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                      elevation: 0,
                    ),
                    child: _checking
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: theme.accentInkColor),
                          )
                        : Text("I've verified", style: theme.sans(14, weight: FontWeight.w600, color: theme.accentInkColor)),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: (_resending || _resendCooldown > 0) ? null : _handleResend,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: theme.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      _resendCooldown > 0 ? 'Resend email (${_resendCooldown}s)' : 'Resend verification email',
                      style: theme.sans(13.5, weight: FontWeight.w600, color: theme.ink),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextButton(
                    onPressed: _handleSignOut,
                    child: Text('Sign out', style: theme.sans(13, color: theme.ink2)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

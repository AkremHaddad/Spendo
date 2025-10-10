// lib/features/account/account_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../auth/auth_page.dart';
import '../../core/theme/theme.dart';
import '../main/theme_notifier.dart'; // ThemeNotifier provider

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AuthPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeNotifier = context.watch<ThemeNotifier>();

    return Scaffold(
      backgroundColor: theme.base300,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: title at left, theme switcher at right
            Container(
              height: 80,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Account",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: theme.baseContent,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Toggle theme',
                    onPressed: () => themeNotifier.toggleTheme(),
                    icon: Icon(
                      themeNotifier.themeMode == ThemeMode.dark
                          ? Icons.dark_mode
                          : Icons.light_mode,
                      color: theme.baseContent,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Body content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting and subtitle
                  Text(
                    "Hello User!",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: theme.baseContent,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Enjoy your experience here in Spendo.",
                    style: TextStyle(
                      fontSize: 16,
                      color: theme.baseContent,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Logout (centered, fixed width)
                  Container(
                    child: SizedBox(
                      width: 220, // fixed width as requested
                      child: ElevatedButton.icon(
                        onPressed: () => _logout(context),
                        icon: const Icon(Icons.logout),
                        label: const Text("Logout"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          textStyle: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

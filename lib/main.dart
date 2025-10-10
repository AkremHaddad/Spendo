import 'package:flutter/material.dart';
import 'core/theme/theme.dart';
import 'features/main/main_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';

import 'features/auth/auth_notifier.dart';
import 'features/auth/auth_page.dart';
import 'features/categories/logic/categoryNotifier.dart';
import 'features/cashflow/logic/cashflowNotifier.dart';
import 'features/dashboard/logic/dashboardNotifier.dart';
import 'features/main/theme_notifier.dart'; // <-- add ThemeNotifier

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const SpendoApp());
}

class SpendoApp extends StatelessWidget {
  const SpendoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthNotifier()),

        ChangeNotifierProxyProvider<AuthNotifier, CategoryNotifier>(
          create: (ctx) {
            final auth = Provider.of<AuthNotifier>(ctx, listen: false);
            return CategoryNotifier(userId: auth.userId ?? '')..loadCategories();
          },
          update: (ctx, auth, previous) {
            final newUserId = auth.userId ?? '';
            if (previous != null && previous.userId == newUserId) return previous;
            return CategoryNotifier(userId: newUserId)..loadCategories();
          },
        ),

        /// Dashboard provider (create before Cashflow)
        ChangeNotifierProxyProvider<AuthNotifier, DashboardNotifier>(
          create: (ctx) {
            final auth = Provider.of<AuthNotifier>(ctx, listen: false);
            return DashboardNotifier(userId: auth.userId ?? '');
          },
          update: (ctx, auth, previous) {
            final newUserId = auth.userId ?? '';
            if (previous != null && previous.userId == newUserId) return previous;
            return DashboardNotifier(userId: newUserId);
          },
        ),

        /// Cashflow provider (uses same userId; updates balance doc directly)
        ChangeNotifierProxyProvider<AuthNotifier, CashflowNotifier>(
          create: (ctx) {
            final auth = Provider.of<AuthNotifier>(ctx, listen: false);
            return CashflowNotifier(userId: auth.userId ?? '')
              ..loadCashflowsForDate(DateTime.now());
          },
          update: (ctx, auth, previous) {
            final newUserId = auth.userId ?? '';
            if (previous != null && previous.userId == newUserId) return previous;
            return CashflowNotifier(userId: newUserId)
              ..loadCashflowsForDate(DateTime.now());
          },
        ),

        /// Theme notifier for global theme switching
        ChangeNotifierProvider(create: (_) => ThemeNotifier()),
      ],
      child: Consumer2<AuthNotifier, ThemeNotifier>(
        builder: (context, auth, themeNotifier, _) {
          return MaterialApp(
            title: 'Spendo',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeNotifier.themeMode, // <-- use themeNotifier
            home: auth.isLoggedIn
                ? MainPage(userId: auth.userId ?? '')
                : const AuthPage(),
          );
        },
      ),
    );
  }
}

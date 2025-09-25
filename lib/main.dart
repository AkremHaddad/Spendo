import 'package:flutter/material.dart';
import 'core/theme/theme.dart'; // <-- where you put your ThemeData
import 'features/main/main_page.dart';   // <-- the nav + pages container
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'features/auth/auth_notifier.dart';
import 'features/auth/auth_page.dart';

void main() async{
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
    return ChangeNotifierProvider(
      create: (_) => AuthNotifier(),
      child: Consumer<AuthNotifier>(
        builder: (context, auth, _) {
          return MaterialApp(
            title: 'Spendo',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,  // from app_theme.dart
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system, // auto switch light/dark
            home: auth.isLoggedIn ? const MainPage() : const AuthPage(),
          );
        },
      ),
    );
  }
}

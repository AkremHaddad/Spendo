import 'package:flutter/material.dart';
import 'core/theme/theme.dart'; 
import 'features/main/main_page.dart';   
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';

import 'features/auth/auth_notifier.dart';
import 'features/auth/auth_page.dart';
import 'features/categories/logic/categoryNotifier.dart';

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
        ChangeNotifierProvider(create: (_) => CategoryNotifier()),
        // add more notifiers here later if needed
      ],
      child: Consumer<AuthNotifier>(
        builder: (context, auth, _) {
          return MaterialApp(
            title: 'Spendo',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system,
            home: auth.isLoggedIn ? const MainPage() : const AuthPage(),
          );
        },
      ),
    );
  }
}

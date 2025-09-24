import 'package:flutter/material.dart';
import 'core/theme/theme.dart'; // <-- where you put your ThemeData
import 'features/main/main_page.dart';   // <-- the nav + pages container

void main() {
  runApp(const SpendoApp());
}

class SpendoApp extends StatelessWidget {
  const SpendoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spendo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,  // from app_theme.dart
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // auto switch light/dark
      home: const MainPage(),      // the root page with navbar/sidebar
    );
  }
}

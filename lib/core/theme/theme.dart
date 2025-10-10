import 'package:flutter/material.dart';

class AppColors {
  // Primary
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryContent = Color(0xFFFFFFFF);
  static const Color primaryDark = Color(0xFF1E3A8A);

  // Secondary
  static const Color secondary = Color(0xFF10B981);
  static const Color secondaryContent = Color(0xFFFFFFFF);
  static const Color secondaryDark = Color(0xFF34D399);
  static const Color secondaryContentDark = Color(0xFF064E3B);

  // Accent
  static const Color accent = Color(0xFFF43F5E);
  static const Color accentContent = Color(0xFFFFFFFF);
  static const Color accentDark = Color(0xFFF87185);
  static const Color accentContentDark = Color(0xFF7F1D1D);

  // Neutral / Grey
  static const Color neutral = Color(0xFF374151);
  static const Color neutralContent = Color(0xFFF3F4F6);
  static const Color neutralDark = Color(0xFFD1D5DB);
  static const Color neutralContentDark = Color(0xFF111827);

  // Base
  static const Color base100 = Color(0xFFFFFFFF);
  static const Color base200 = Color(0xFFF9FAFB);
  static const Color base300 = Color(0xFFE5E7EB);
  static const Color baseContent = Color(0xFF111827);

  static const Color base100Dark = Color(0xFF1F2937);
  static const Color base200Dark = Color(0xFF111827);
  static const Color base300Dark = Color.fromARGB(255, 7, 10, 18);
  // static const Color base300Dark = Color(0xFF0F172A);
  static const Color baseContentDark = Color(0xFFF9FAFB);

  // Status
  static const Color info = Color(0xFF3B82F6);
  static const Color infoContent = Color(0xFFFFFFFF);
  static const Color infoDark = Color(0xFF60A5FA);
  static const Color infoContentDark = Color(0xFF1E3A8A);

  static const Color success = Color(0xFF22C55E);
  static const Color successContent = Color(0xFFFFFFFF);
  static const Color successDark = Color(0xFF34D399);
  static const Color successContentDark = Color(0xFF064E3B);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningContent = Color(0xFFFFFFFF);
  static const Color warningDark = Color(0xFFFBBF24);
  static const Color warningContentDark = Color(0xFF78350F);

  static const Color error = Color(0xFFFF4444);
  static const Color errorContent = Color(0xFFFFFFFF);
  static const Color errorDark = Color(0xFFF87171);
  static const Color errorContentDark = Color(0xFF7F1D1D);
}

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.base100,
    colorScheme: ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.primaryContent,
      secondary: AppColors.secondary,
      onSecondary: AppColors.secondaryContent,
      surface: AppColors.base100,
      onSurface: AppColors.baseContent,
      error: AppColors.error,
      onError: AppColors.errorContent,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.primaryContent,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.primary,
      selectedItemColor: AppColors.primaryContent,
      unselectedItemColor: Color(0xB3FFFFFF), // slightly transparent white
    ),
    inputDecorationTheme: InputDecorationTheme(
      labelStyle: TextStyle(color: AppColors.baseContent),      
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.baseContent),  
        borderRadius: BorderRadius.circular(8),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.baseContent.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(8),
      ),
      fillColor: AppColors.base200,
      filled: true,
    ),
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: AppColors.primaryDark,
    scaffoldBackgroundColor: AppColors.base100Dark,
    colorScheme: ColorScheme.dark(
      primary: AppColors.primaryDark,
      onPrimary: AppColors.primaryContent,
      secondary: AppColors.secondaryDark,
      onSecondary: AppColors.secondaryContentDark,
      surface: AppColors.base100Dark,
      onSurface: AppColors.baseContentDark,
      error: AppColors.errorDark,
      onError: AppColors.errorContentDark,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primaryDark,
      foregroundColor: AppColors.primaryContent,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.primaryDark,
      selectedItemColor: AppColors.primaryContent,
      unselectedItemColor: Color(0xB3FFFFFF),
    ),
    inputDecorationTheme: InputDecorationTheme(
      labelStyle: TextStyle(color: AppColors.baseContentDark),      
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.baseContentDark),  
        borderRadius: BorderRadius.circular(8),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.baseContentDark.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(8),
      ),
      fillColor: AppColors.base200Dark,
      filled: true,
    ),
  );
}

extension ThemeColorsExtension on ThemeData {
  // Primary
  Color get primaryColorCustom =>
      brightness == Brightness.dark ? AppColors.primaryDark : AppColors.primary;
  Color get primaryContent =>
      brightness == Brightness.dark ? AppColors.primaryContent : AppColors.primaryContent;

  // Secondary
  Color get secondary =>
      brightness == Brightness.dark ? AppColors.secondaryDark : AppColors.secondary;
  Color get secondaryContent =>
      brightness == Brightness.dark ? AppColors.secondaryContentDark : AppColors.secondaryContent;

  // Accent
  Color get accent =>
      brightness == Brightness.dark ? AppColors.accentDark : AppColors.accent;
  Color get accentContent =>
      brightness == Brightness.dark ? AppColors.accentContentDark : AppColors.accentContent;

  // Neutral
  Color get neutral =>
      brightness == Brightness.dark ? AppColors.neutralDark : AppColors.neutral;
  Color get neutralContent =>
      brightness == Brightness.dark ? AppColors.neutralContentDark : AppColors.neutralContent;

  // Base / Background
  Color get base100 =>
      brightness == Brightness.dark ? AppColors.base100Dark : AppColors.base100;
  Color get base200 =>
      brightness == Brightness.dark ? AppColors.base200Dark : AppColors.base200;
  Color get base300 =>
      brightness == Brightness.dark ? AppColors.base300Dark : AppColors.base300;
  Color get baseContent =>
      brightness == Brightness.dark ? AppColors.baseContentDark : AppColors.baseContent;

  // Status
  Color get info =>
      brightness == Brightness.dark ? AppColors.infoDark : AppColors.info;
  Color get infoContent =>
      brightness == Brightness.dark ? AppColors.infoContentDark : AppColors.infoContent;

  Color get success =>
      brightness == Brightness.dark ? AppColors.successDark : AppColors.success;
  Color get successContent =>
      brightness == Brightness.dark ? AppColors.successContentDark : AppColors.successContent;

  Color get warning =>
      brightness == Brightness.dark ? AppColors.warningDark : AppColors.warning;
  Color get warningContent =>
      brightness == Brightness.dark ? AppColors.warningContentDark : AppColors.warningContent;

  Color get error =>
      brightness == Brightness.dark ? AppColors.errorDark : AppColors.error;
  Color get errorContent =>
      brightness == Brightness.dark ? AppColors.errorContentDark : AppColors.errorContent;
  Color get white =>
      brightness == Brightness.dark ? Colors.black : Colors.white;
  Color get cardsColor =>
      brightness == Brightness.dark ? AppColors.primaryDark.withOpacity(0.2) : AppColors.base100;
  Color get borderColor =>
      brightness == Brightness.dark ? primaryColor.withOpacity(0.5) : const Color(0xFFE5E7EB);
  Color get primarytext =>
      AppColors.primary;
}
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Color palette ──────────────────────────────────────────────────────────
class SpendoColors {
  // Light base
  static const Color bg        = Color(0xFFFAF7F2);
  static const Color surface   = Color(0xFFFFFFFF);
  static const Color surface2  = Color(0xFFF4EFE7);
  static const Color ink       = Color(0xFF1F1812);
  static const Color ink2      = Color(0xFF6B5D52);
  static const Color ink3      = Color(0xFFA89A8C);
  static const Color border    = Color(0x141F1812); // rgba(31,24,18,0.08)

  // Dark base
  static const Color bgDark       = Color(0xFF16120E);
  static const Color surfaceDark  = Color(0xFF221C16);
  static const Color surface2Dark = Color(0xFF2C251E);
  static const Color inkDark      = Color(0xFFF5EFE7);
  static const Color ink2Dark     = Color(0xFFB5A99B);
  static const Color ink3Dark     = Color(0xFF7A6E63);
  static const Color borderDark   = Color(0x14F5EFE7);

  // Accent – mint green
  static const Color accent          = Color(0xFF4A9B6E);
  static const Color accentDark      = Color(0xFF7BC0A0);
  static const Color accentInk       = Color(0xFFFFFFFF);
  static const Color accentInkDark   = Color(0xFF0D1F15);
  static const Color accentSoft      = Color(0xFFD7EDDD);
  static const Color accentSoftDark  = Color(0x1F7BC0A0);
  static const Color accentInkSoft   = Color(0xFF2D6948);
  static const Color accentInkSoftDk = Color(0xFFB0DCC5);

  // Semantic tints — light
  static const Color mintBg      = Color(0xFFD7EDDD);
  static const Color mintInk     = Color(0xFF2D6948);
  static const Color coralBg     = Color(0xFFFCDCD2);
  static const Color coralInk    = Color(0xFFB04638);
  static const Color butterBg    = Color(0xFFFBE9C0);
  static const Color butterInk   = Color(0xFF8C6315);
  static const Color lavenderBg  = Color(0xFFE5DEF1);
  static const Color lavenderInk = Color(0xFF5E4A95);
  static const Color skyBg       = Color(0xFFD7E6F1);
  static const Color skyInk      = Color(0xFF2F6A95);
  static const Color roseBg      = Color(0xFFF4D6E0);
  static const Color roseInk     = Color(0xFFA24876);

  // Semantic tints — dark
  static const Color mintBgDk      = Color(0x1F9CD8B8);
  static const Color mintInkDk     = Color(0xFF9CD8B8);
  static const Color coralBgDk     = Color(0x1FFFC1AE);
  static const Color coralInkDk    = Color(0xFFFFC1AE);
  static const Color butterBgDk    = Color(0x1FF2C97A);
  static const Color butterInkDk   = Color(0xFFF2C97A);
  static const Color lavenderBgDk  = Color(0x1FC8B6E2);
  static const Color lavenderInkDk = Color(0xFFC8B6E2);
  static const Color skyBgDk       = Color(0x1FA7CCE8);
  static const Color skyInkDk      = Color(0xFFA7CCE8);
  static const Color roseBgDk      = Color(0x1FE9A8C2);
  static const Color roseInkDk     = Color(0xFFE9A8C2);
}

// ─── App Themes ──────────────────────────────────────────────────────────────
class AppTheme {
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: SpendoColors.accent,
    scaffoldBackgroundColor: SpendoColors.bg,
    colorScheme: const ColorScheme.light(
      primary: SpendoColors.accent,
      onPrimary: SpendoColors.accentInk,
      secondary: SpendoColors.mintInk,
      onSecondary: Colors.white,
      surface: SpendoColors.surface,
      onSurface: SpendoColors.ink,
      error: SpendoColors.coralInk,
      onError: Colors.white,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: SpendoColors.surface,
      foregroundColor: SpendoColors.ink,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: GoogleFonts.instrumentSerif(
        fontSize: 20,
        color: SpendoColors.ink,
        fontWeight: FontWeight.w400,
      ),
    ),
    cardColor: SpendoColors.surface,
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: SpendoColors.surface,
      selectedItemColor: SpendoColors.accent,
      unselectedItemColor: SpendoColors.ink3,
    ),
    inputDecorationTheme: InputDecorationTheme(
      labelStyle: GoogleFonts.instrumentSans(color: SpendoColors.ink),
      hintStyle: GoogleFonts.instrumentSans(color: SpendoColors.ink3),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: SpendoColors.ink),
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: SpendoColors.ink.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(12),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      fillColor: SpendoColors.surface2,
      filled: true,
    ),
    // Dialogs (add/edit category, add/edit transaction, etc.) inherit this
    // instead of Material defaults, so every AlertDialog in the app matches
    // the rest of the redesign without needing per-dialog styling.
    dialogTheme: DialogThemeData(
      backgroundColor: SpendoColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle: GoogleFonts.instrumentSerif(
        fontSize: 22, color: SpendoColors.ink, fontWeight: FontWeight.w400,
      ),
      contentTextStyle: GoogleFonts.instrumentSans(fontSize: 14, color: SpendoColors.ink2),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: SpendoColors.accent,
        foregroundColor: SpendoColors.accentInk,
        disabledBackgroundColor: SpendoColors.ink3,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        textStyle: GoogleFonts.instrumentSans(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: SpendoColors.ink2,
        textStyle: GoogleFonts.instrumentSans(fontWeight: FontWeight.w500, fontSize: 14),
      ),
    ),
    textTheme: GoogleFonts.instrumentSansTextTheme(ThemeData.light().textTheme).apply(
      bodyColor: SpendoColors.ink,
      displayColor: SpendoColors.ink,
    ),
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: SpendoColors.accentDark,
    scaffoldBackgroundColor: SpendoColors.bgDark,
    colorScheme: const ColorScheme.dark(
      primary: SpendoColors.accentDark,
      onPrimary: SpendoColors.accentInkDark,
      secondary: SpendoColors.mintInkDk,
      onSecondary: SpendoColors.bgDark,
      surface: SpendoColors.surfaceDark,
      onSurface: SpendoColors.inkDark,
      error: SpendoColors.coralInkDk,
      onError: SpendoColors.bgDark,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: SpendoColors.surfaceDark,
      foregroundColor: SpendoColors.inkDark,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: GoogleFonts.instrumentSerif(
        fontSize: 20,
        color: SpendoColors.inkDark,
        fontWeight: FontWeight.w400,
      ),
    ),
    cardColor: SpendoColors.surfaceDark,
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: SpendoColors.surfaceDark,
      selectedItemColor: SpendoColors.accentDark,
      unselectedItemColor: SpendoColors.ink3Dark,
    ),
    inputDecorationTheme: InputDecorationTheme(
      labelStyle: GoogleFonts.instrumentSans(color: SpendoColors.inkDark),
      hintStyle: GoogleFonts.instrumentSans(color: SpendoColors.ink3Dark),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: SpendoColors.inkDark),
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: SpendoColors.inkDark.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(12),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      fillColor: SpendoColors.surface2Dark,
      filled: true,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: SpendoColors.surfaceDark,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle: GoogleFonts.instrumentSerif(
        fontSize: 22, color: SpendoColors.inkDark, fontWeight: FontWeight.w400,
      ),
      contentTextStyle: GoogleFonts.instrumentSans(fontSize: 14, color: SpendoColors.ink2Dark),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: SpendoColors.accentDark,
        foregroundColor: SpendoColors.accentInkDark,
        disabledBackgroundColor: SpendoColors.ink3Dark,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        textStyle: GoogleFonts.instrumentSans(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: SpendoColors.ink2Dark,
        textStyle: GoogleFonts.instrumentSans(fontWeight: FontWeight.w500, fontSize: 14),
      ),
    ),
    textTheme: GoogleFonts.instrumentSansTextTheme(ThemeData.dark().textTheme).apply(
      bodyColor: SpendoColors.inkDark,
      displayColor: SpendoColors.inkDark,
    ),
  );
}

// ─── Theme extension — semantic color getters ────────────────────────────────
extension ThemeColorsExtension on ThemeData {
  bool get _dark => brightness == Brightness.dark;

  // Page / surface backgrounds
  Color get bg       => _dark ? SpendoColors.bgDark       : SpendoColors.bg;
  Color get surface  => _dark ? SpendoColors.surfaceDark  : SpendoColors.surface;
  Color get surface2 => _dark ? SpendoColors.surface2Dark : SpendoColors.surface2;

  // Text
  Color get ink  => _dark ? SpendoColors.inkDark  : SpendoColors.ink;
  Color get ink2 => _dark ? SpendoColors.ink2Dark : SpendoColors.ink2;
  Color get ink3 => _dark ? SpendoColors.ink3Dark : SpendoColors.ink3;

  // Border
  Color get border => _dark ? SpendoColors.borderDark : SpendoColors.border;

  // Accent (mint primary)
  Color get accentColor       => _dark ? SpendoColors.accentDark     : SpendoColors.accent;
  Color get accentInkColor    => _dark ? SpendoColors.accentInkDark  : SpendoColors.accentInk;
  Color get accentSoftColor   => _dark ? SpendoColors.accentSoftDark : SpendoColors.accentSoft;
  Color get accentInkSoftColor => _dark ? SpendoColors.accentInkSoftDk : SpendoColors.accentInkSoft;

  // Tints
  Color get tintMintBg      => _dark ? SpendoColors.mintBgDk      : SpendoColors.mintBg;
  Color get tintMintInk     => _dark ? SpendoColors.mintInkDk     : SpendoColors.mintInk;
  Color get tintCoralBg     => _dark ? SpendoColors.coralBgDk     : SpendoColors.coralBg;
  Color get tintCoralInk    => _dark ? SpendoColors.coralInkDk    : SpendoColors.coralInk;
  Color get tintButterBg    => _dark ? SpendoColors.butterBgDk    : SpendoColors.butterBg;
  Color get tintButterInk   => _dark ? SpendoColors.butterInkDk   : SpendoColors.butterInk;
  Color get tintLavenderBg  => _dark ? SpendoColors.lavenderBgDk  : SpendoColors.lavenderBg;
  Color get tintLavenderInk => _dark ? SpendoColors.lavenderInkDk : SpendoColors.lavenderInk;
  Color get tintSkyBg       => _dark ? SpendoColors.skyBgDk       : SpendoColors.skyBg;
  Color get tintSkyInk      => _dark ? SpendoColors.skyInkDk      : SpendoColors.skyInk;
  Color get tintRoseBg      => _dark ? SpendoColors.roseBgDk      : SpendoColors.roseBg;
  Color get tintRoseInk     => _dark ? SpendoColors.roseInkDk     : SpendoColors.roseInk;

  // Card decoration helper
  BoxDecoration get cardDecoration => BoxDecoration(
    color: surface,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: border),
    boxShadow: _dark
        ? [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 16, offset: const Offset(0, 4))]
        : [BoxShadow(color: const Color(0x0A14100C), blurRadius: 16, offset: const Offset(0, 4)),
           BoxShadow(color: const Color(0x0514100C), blurRadius: 2, offset: const Offset(0, 1))],
  );

  // Tinted card (e.g. for tint='mint' → mintBg background)
  BoxDecoration tintCardDecoration(Color bgColor) => BoxDecoration(
    color: bgColor,
    borderRadius: BorderRadius.circular(20),
  );

  // Font helpers
  TextStyle serif(double size, {FontWeight weight = FontWeight.w400, Color? color, double letterSpacing = -0.02}) =>
      GoogleFonts.instrumentSerif(
        fontSize: size,
        fontWeight: weight,
        color: color ?? ink,
        letterSpacing: size * letterSpacing,
        height: 1.1,
      );

  TextStyle sans(double size, {FontWeight weight = FontWeight.w500, Color? color}) =>
      GoogleFonts.instrumentSans(
        fontSize: size,
        fontWeight: weight,
        color: color ?? ink,
      );

  TextStyle mono(double size, {FontWeight weight = FontWeight.w600, Color? color}) =>
      GoogleFonts.jetBrainsMono(
        fontSize: size,
        fontWeight: weight,
        color: color ?? ink,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  // ─── Backward-compat aliases ────────────────────────────────────────────
  // These keep existing widgets (charts, dialogs, etc.) compiling unchanged.
  Color get base100  => surface;
  Color get base200  => surface2;
  Color get base300  => bg;
  Color get baseContent => ink;
  Color get primaryColorCustom => accentColor;
  Color get primaryContent     => accentInkColor;
  Color get secondary          => tintMintInk;
  Color get secondaryContent   => _dark ? SpendoColors.bgDark : Colors.white;
  Color get accent             => tintCoralInk;
  Color get accentContent      => _dark ? SpendoColors.bgDark : Colors.white;
  Color get neutral            => ink3;
  Color get neutralContent     => _dark ? SpendoColors.ink2Dark : SpendoColors.ink2;
  Color get info               => tintSkyInk;
  Color get infoContent        => _dark ? SpendoColors.bgDark : Colors.white;
  Color get success            => tintMintInk;
  Color get successContent     => _dark ? SpendoColors.bgDark : Colors.white;
  Color get warning            => tintButterInk;
  Color get warningContent     => _dark ? SpendoColors.bgDark : Colors.white;
  Color get error              => tintCoralInk;
  Color get errorContent       => _dark ? SpendoColors.bgDark : Colors.white;
  Color get white              => _dark ? SpendoColors.bgDark : Colors.white;
  Color get cardsColor         => surface;
  Color get borderColor        => border;
  Color get primarytext        => accentColor;
}

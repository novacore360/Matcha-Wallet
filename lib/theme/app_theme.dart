import 'package:flutter/material.dart';

/// Matcha × Brown design system.
/// A warm, editorial, tea-house palette — flat surfaces, no glow,
/// no gradients, no rounded-pill everything. Confident whitespace,
/// quiet contrast, one accent used sparingly.
class AppColors {
  AppColors._();

  // Core palette
  static const Color matcha = Color(0xFF6B7A4E); // primary accent
  static const Color matchaDeep = Color(0xFF4C5936); // pressed / emphasis
  static const Color matchaMist = Color(0xFFDDE3CC); // soft accent fill

  static const Color espresso = Color(0xFF3B2E26); // primary text / ink
  static const Color mocha = Color(0xFF6E5C4E); // secondary text
  static const Color latte = Color(0xFFB8A793); // tertiary text / hints

  static const Color cream = Color(0xFFF7F3EC); // app background
  static const Color parchment = Color(0xFFEFE8DA); // card surface
  static const Color sand = Color(0xFFE3D9C6); // divider / border

  static const Color clay = Color(0xFFB2543B); // negative / send / alerts
  static const Color moss = Color(0xFF57794A); // positive / receive

  // Dark mode
  static const Color inkNight = Color(0xFF1C1A16);
  static const Color surfaceNight = Color(0xFF262320);
  static const Color cardNight = Color(0xFF2E2A25);
  static const Color borderNight = Color(0xFF3D372F);
}

class AppTheme {
  AppTheme._();

  static const String _fontFamily = 'Georgia'; // serif for numerals/headers
  static const String _bodyFamily = 'Helvetica';

  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.cream,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.matcha,
        onPrimary: AppColors.cream,
        secondary: AppColors.mocha,
        surface: AppColors.parchment,
        onSurface: AppColors.espresso,
        error: AppColors.clay,
      ),
      textTheme: _textTheme(AppColors.espresso, AppColors.mocha),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.cream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.espresso),
        titleTextStyle: const TextStyle(
          color: AppColors.espresso,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.sand,
        thickness: 1,
        space: 1,
      ),
      cardTheme: CardThemeData(
        color: AppColors.parchment,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.sand, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.espresso,
          foregroundColor: AppColors.cream,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.espresso,
          side: const BorderSide(color: AppColors.sand, width: 1.2),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.matchaDeep,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.parchment,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.sand),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.sand),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.matcha, width: 1.4),
        ),
        hintStyle: const TextStyle(color: AppColors.latte),
      ),
      iconTheme: const IconThemeData(color: AppColors.espresso, size: 22),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.cream,
        selectedItemColor: AppColors.espresso,
        unselectedItemColor: AppColors.latte,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }

  static TextTheme _textTheme(Color ink, Color secondary) {
    return TextTheme(
      displayLarge: TextStyle(
        fontFamily: _fontFamily,
        color: ink,
        fontSize: 40,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.5,
      ),
      headlineMedium: TextStyle(
        fontFamily: _fontFamily,
        color: ink,
        fontSize: 26,
        fontWeight: FontWeight.w500,
      ),
      titleLarge: TextStyle(
        color: ink,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: TextStyle(
        color: ink,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(color: ink, fontSize: 15, height: 1.4),
      bodyMedium: TextStyle(color: secondary, fontSize: 13.5, height: 1.4),
      labelSmall: TextStyle(
        color: secondary,
        fontSize: 11.5,
        letterSpacing: 0.6,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

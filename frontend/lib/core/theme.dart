import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF1A56DB);
  static const Color primaryDark = Color(0xFF1239A5);
  static const Color secondary = Color(0xFF0E9F6E);
  static const Color danger = Color(0xFFE02424);
  static const Color warning = Color(0xFFFF5A1F);
  static const Color surface = Color(0xFFF9FAFB);
  static const Color card = Color(0xFFFFFFFF);
  static const Color text = Color(0xFF111928);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);

  // Score colors
  static Color scoreColor(double score) {
    if (score >= 80) return const Color(0xFF0E9F6E);
    if (score >= 60) return const Color(0xFF1A56DB);
    if (score >= 40) return const Color(0xFFFF5A1F);
    return const Color(0xFFE02424);
  }

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        fontFamily: 'Inter',
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: surface,
        appBarTheme: const AppBarTheme(
          backgroundColor: card,
          foregroundColor: text,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: text,
          ),
        ),
        cardTheme: CardThemeData(
          color: card,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: border),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            textStyle: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: primary, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      );
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Canonical Tu Lojita brand and semantic surface tokens.
abstract final class TuLojitaBrandColors {
  static const Color indigo600 = Color(0xFF4F46E5);
  static const Color indigo700 = Color(0xFF3730A3);
  static const Color indigo500 = Color(0xFF6366F1);
  static const Color indigo100 = Color(0xFFE0E7FF);
  static const Color indigo50 = Color(0xFFEEF2FF);

  static const Color amber400 = Color(0xFFFBBF24);
  static const Color amber500 = Color(0xFFF59E0B);
  static const Color amber700 = Color(0xFFB45309);
  static const Color amber800 = Color(0xFF92400E);
  static const Color amber100 = Color(0xFFFEF3C7);
  static const Color amber50 = Color(0xFFFFFBEB);

  static const Color canvas = Color(0xFFF8FAFC);
  static const Color background = canvas;
  static const Color surface = Color(0xFFFFFFFF);
  static const Color borderSubtle = Color(0xFFF1F5F9);
  static const Color borderMuted = Color(0xFFE2E8F0);
  static const Color inkPrimary = Color(0xFF0F172A);
  static const Color inkSecondary = Color(0xFF64748B);
  static const Color inkMuted = inkSecondary;

  static const Color primary = indigo600;
  static const Color primarySoft = indigo50;

  static const Color positive = Color(0xFF047857);
  static const Color positiveBg = Color(0xFFECFDF5);
  static const Color danger = Color(0xFFDC2626);
  static const Color dangerBg = Color(0xFFFEF2F2);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: TuLojitaBrandColors.indigo600,
      brightness: Brightness.light,
      scaffoldBackgroundColor: TuLojitaBrandColors.canvas,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: TuLojitaBrandColors.indigo600,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: TuLojitaBrandColors.indigo600,
          foregroundColor: Colors.white,
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: TuLojitaBrandColors.indigo600,
      brightness: Brightness.dark,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
    );
  }
}

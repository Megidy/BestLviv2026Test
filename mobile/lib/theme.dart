import 'package:flutter/material.dart';

class AppColors {
  static const Color shell = Color(0xFF111111);
  static const Color canvas = Color(0xFF1A0F06);
  static const Color panel = Color(0xFF3A2908);
  static const Color mutedGold = Color(0xFF4A3508);
  static const Color warmGold = Color(0xFFC8A24B);
  static const Color goldStroke = Color(0xFF6B5318);
  static const Color creamText = Color(0xFFF2E9D3);
  static const Color softText = Color(0xFFB3A07A);
  static const Color stroke = Color(0xFF4B3212);
  static const Color redAlert = Color(0xFFF14A43);
  static const Color amberWarn = Color(0xFFE8A93A);
  static const Color greenOk = Color(0xFF39C86A);
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.shell,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.warmGold,
      secondary: AppColors.redAlert,
      surface: AppColors.panel,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.1,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      bodyMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.softText,
      ),
      labelLarge: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
      labelMedium: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
    ),
  );
}

import 'package:flutter/material.dart';

class AppColors {
  // Light
  static const lightPrimary = Color(0xFF616BC0);
  static const lightSecondary = Color(0xFF81D4FA);
  static const lightBackground = Color(0xFFF9F9F9);
  static const lightText = Color(0xFF212121);
  static const lightSurface = Color(0xFFFFFFFF);

  // Dark
  static const darkPrimary = Color(0xFF8E99F3);
  static const darkSecondary = Color(0xFF4DD0E1);
  static const darkBackground = Color(0xFF121212);
  static const darkText = Color(0xFFE0E0E0);
  static const darkSurface = Color(0xFF1E1E1E);

  // Shared helpers
  static InputDecorationTheme inputDecorationTheme(
    Color focusColor,
    Color fillColor,
  ) {
    return InputDecorationTheme(
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: focusColor),
      ),
    );
  }

  static CardThemeData cardTheme(Color surfaceColor) {
    return CardThemeData(
      color: surfaceColor,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
    );
  }

  static DialogThemeData dialogTheme(Color surfaceColor) {
    return DialogThemeData(
      backgroundColor: surfaceColor,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
  }
}

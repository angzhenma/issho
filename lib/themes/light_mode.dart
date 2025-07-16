import 'package:flutter/material.dart';
import 'theme_colors.dart';
import 'theme_text.dart';

final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: ColorScheme.light(
    primary: AppColors.lightPrimary,
    secondary: AppColors.lightSecondary,
    surface: AppColors.lightSurface,
    onPrimary: Colors.white,
    onSecondary: AppColors.lightText,
    onSurface: AppColors.lightText,
  ),
  scaffoldBackgroundColor: AppColors.lightBackground,
  textTheme: AppTextStyles.textTheme.apply(
    displayColor: AppColors.lightText,
    bodyColor: AppColors.lightText,
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: AppColors.lightBackground,
    foregroundColor: AppColors.lightText,
    centerTitle: true,
    elevation: 0,
  ),
  inputDecorationTheme: AppColors.inputDecorationTheme(AppColors.lightPrimary, AppColors.lightSurface),
  cardTheme: AppColors.cardTheme(AppColors.lightSurface),
  dialogTheme: AppColors.dialogTheme(AppColors.lightSurface),
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: AppColors.lightSurface,
    selectedItemColor: AppColors.lightPrimary,
    unselectedItemColor: Colors.grey.shade600,
    type: BottomNavigationBarType.fixed,
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: AppColors.lightPrimary,
    foregroundColor: Colors.white,
    elevation: 2,
  ),
);

import 'package:flutter/material.dart';
import 'theme_colors.dart';
import 'theme_text.dart';

final ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: ColorScheme.dark(
    primary: AppColors.darkPrimary,
    secondary: AppColors.darkSecondary,
    surface: AppColors.darkSurface,
    onPrimary: Colors.white,
    onSecondary: AppColors.darkText,
    onSurface: AppColors.darkText,
  ),
  scaffoldBackgroundColor: AppColors.darkBackground,
  textTheme: AppTextStyles.textTheme.apply(
    displayColor: AppColors.darkText,
    bodyColor: AppColors.darkText,
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: AppColors.darkBackground,
    foregroundColor: AppColors.darkText,
    centerTitle: true,
    elevation: 0,
  ),
  inputDecorationTheme: AppColors.inputDecorationTheme(AppColors.darkPrimary, AppColors.darkSurface),
  cardTheme: AppColors.cardTheme(AppColors.darkSurface),
  dialogTheme: AppColors.dialogTheme(AppColors.darkSurface),
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: AppColors.darkSurface,
    selectedItemColor: AppColors.darkPrimary,
    unselectedItemColor: Colors.grey.shade400,
    type: BottomNavigationBarType.fixed,
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: AppColors.darkPrimary,
    foregroundColor: Colors.white,
    elevation: 2,
  ),
);

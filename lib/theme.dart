// ============================================================
// EduAcademy - الثيم (فاتح، بنفسجي/أخضر)
// ============================================================

import 'package:flutter/material.dart';

class AppColors {
  static const bg = Color(0xFFF5F6FB);
  static const card = Colors.white;
  static const cardLight = Color(0xFFEEF0F8);
  static const primary = Color(0xFF5B4BDB); // بنفسجي
  static const secondary = Color(0xFF1FA97A); // أخضر
  static const orange = Color(0xFFF59E0B);
  static const teal = Color(0xFF0EA5E9);
  static const green = Color(0xFF1FA97A);
  static const purple = Color(0xFF5B4BDB);
  static const yellow = Color(0xFFF59E0B);
  static const red = Color(0xFFE5484D);
  static const textDim = Color(0xFF6B7280);
  static const text = Color(0xFF1F2937);
}

ThemeData buildTheme() {
  final base = ThemeData.light(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.card,
    ),
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.text,
      displayColor: AppColors.text,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.card,
      elevation: 1.5,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: EdgeInsets.zero,
    ),
    drawerTheme: const DrawerThemeData(backgroundColor: Colors.white),
    listTileTheme: const ListTileThemeData(iconColor: AppColors.primary),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.secondary,
      foregroundColor: Colors.white,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFD9DCE8)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFD9DCE8)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
      ),
      labelStyle: const TextStyle(color: AppColors.textDim),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white70,
      indicatorColor: Colors.white,
    ),
    dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
    bottomSheetTheme: const BottomSheetThemeData(backgroundColor: Colors.white),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}

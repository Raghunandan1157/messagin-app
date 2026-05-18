import 'package:flutter/material.dart';

class LoopColors {
  static const brand = Color(0xFF0F6B56);
  static const brandDark = Color(0xFF14A085);
  static const brandTint = Color(0xFFDAEDE5);
  static const accent = Color(0xFFE8A13A);
  static const paper = Color(0xFFF3EFE6);
  static const inkDark = Color(0xFF0A1310);
  static const bubbleMine = Color(0xFFDCF8C6);
  static const bubbleOther = Colors.white;
  static const bubbleMineDark = Color(0xFF075E54);
  static const bubbleOtherDark = Color(0xFF1F2C34);
  static const chatBg = Color(0xFFECE5DD);
  static const chatBgDark = Color(0xFF0B141A);
}

ThemeData buildLightTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: LoopColors.brand,
    primary: LoopColors.brand,
    secondary: LoopColors.brandDark,
    brightness: Brightness.light,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: LoopColors.brand,
      foregroundColor: Colors.white,
      elevation: 0,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: LoopColors.brandDark,
      foregroundColor: Colors.white,
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white70,
      indicatorColor: Colors.white,
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: LoopColors.brand,
    ),
  );
}

ThemeData buildDarkTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: LoopColors.brand,
    primary: LoopColors.brandDark,
    secondary: LoopColors.brand,
    brightness: Brightness.dark,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: const Color(0xFF111B21),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1F2C34),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: LoopColors.brandDark,
      foregroundColor: Colors.white,
    ),
  );
}

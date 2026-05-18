import 'package:flutter/material.dart';

class WAColors {
  // WhatsApp brand
  static const brand = Color(0xFF00A884);
  static const brandDark = Color(0xFF008069);
  static const brandHover = Color(0xFF06CF9C);

  // Panels / chrome
  static const panelLight = Color(0xFFF0F2F5);
  static const panelDark = Color(0xFF202C33);
  static const headerLight = Color(0xFFF0F2F5);
  static const headerDark = Color(0xFF202C33);
  static const sidebarLight = Color(0xFFFFFFFF);
  static const sidebarDark = Color(0xFF111B21);

  // Chat area
  static const chatBgLight = Color(0xFFEFEAE2);
  static const chatBgDark = Color(0xFF0B141A);

  // Bubbles
  static const bubbleSentLight = Color(0xFFD9FDD3);
  static const bubbleSentDark = Color(0xFF005C4B);
  static const bubbleRecvLight = Color(0xFFFFFFFF);
  static const bubbleRecvDark = Color(0xFF202C33);

  // Misc
  static const tickBlue = Color(0xFF53BDEB);
  static const inkLight = Color(0xFF111B21);
  static const inkDark = Color(0xFFE9EDEF);
  static const mutedLight = Color(0xFF667781);
  static const mutedDark = Color(0xFF8696A0);
  static const divider = Color(0xFFE9EDEF);
  static const dateChipLight = Color(0xFFE1F2FB);
  static const dateChipDark = Color(0xFF182229);
}

// Back-compat alias for the old name used elsewhere
class LoopColors {
  static const brand = WAColors.brand;
  static const brandDark = WAColors.brandDark;
  static const brandTint = Color(0xFFDAEDE5);
  static const accent = Color(0xFFE8A13A);
  static const paper = WAColors.panelLight;
  static const inkDark = WAColors.inkLight;
  static const bubbleMine = WAColors.bubbleSentLight;
  static const bubbleOther = WAColors.bubbleRecvLight;
  static const bubbleMineDark = WAColors.bubbleSentDark;
  static const bubbleOtherDark = WAColors.bubbleRecvDark;
  static const chatBg = WAColors.chatBgLight;
  static const chatBgDark = WAColors.chatBgDark;
}

ThemeData buildLightTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: WAColors.brand,
    primary: WAColors.brand,
    secondary: WAColors.brandDark,
    brightness: Brightness.light,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: WAColors.sidebarLight,
    fontFamily: 'Inter',
    appBarTheme: const AppBarTheme(
      backgroundColor: WAColors.headerLight,
      foregroundColor: WAColors.inkLight,
      elevation: 0,
      titleTextStyle: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w500,
        color: WAColors.inkLight,
      ),
      iconTheme: IconThemeData(color: WAColors.mutedLight),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: WAColors.brand,
      foregroundColor: Colors.white,
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: WAColors.brand,
      unselectedLabelColor: WAColors.mutedLight,
      indicatorColor: WAColors.brand,
      labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
    ),
    dividerColor: WAColors.divider,
    listTileTheme: const ListTileThemeData(
      iconColor: WAColors.mutedLight,
      titleTextStyle: TextStyle(
        color: WAColors.inkLight,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      subtitleTextStyle: TextStyle(
        color: WAColors.mutedLight,
        fontSize: 13,
      ),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: WAColors.inkLight),
      bodyMedium: TextStyle(color: WAColors.inkLight),
      bodySmall: TextStyle(color: WAColors.mutedLight),
      titleLarge: TextStyle(color: WAColors.inkLight, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(color: WAColors.inkLight, fontWeight: FontWeight.w500),
      titleSmall: TextStyle(color: WAColors.inkLight),
      labelLarge: TextStyle(color: WAColors.inkLight),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      hintStyle: TextStyle(color: WAColors.mutedLight),
    ),
  );
}

ThemeData buildDarkTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: WAColors.brand,
    primary: WAColors.brand,
    secondary: WAColors.brandDark,
    brightness: Brightness.dark,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: WAColors.sidebarDark,
    fontFamily: 'Inter',
    appBarTheme: const AppBarTheme(
      backgroundColor: WAColors.headerDark,
      foregroundColor: WAColors.inkDark,
      elevation: 0,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: WAColors.brand,
      foregroundColor: Colors.white,
    ),
  );
}

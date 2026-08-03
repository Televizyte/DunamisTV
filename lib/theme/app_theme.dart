import 'package:flutter/material.dart';

import '../app_config.dart';

class AppTheme {
  // =========================
  // DARK THEME COLORS
  // =========================
  static const Color _darkBgTop = Color(0xFF050714);
  static const Color _darkBgMid = Color(0xFF0B0A2A);
  static const Color _darkBgEnd = Color(0xFF1A0A2A);

  static const Color _darkSurface = Color(0xFF0D1228);
  static const Color _darkSurface2 = Color(0xFF0B1024);
  static const Color _darkText = Color(0xFFF2F3FF);

  // =========================
  // LIGHT THEME COLORS
  // =========================
  static const Color _lightBg = Color(0xFFF7F7FB);
  static const Color _lightSurface = Color(0xFFFFFFFF);
  static const Color _lightSurface2 = Color(0xFFF1F3FA);
  static const Color _lightText = Color(0xFF1C2240);
  static const Color _lightMuted = Color(0xFF6B738F);
  static const Color _lightRoyalBlue = Color(0xFFEFF3FF);

  /// Shared default background gradient.
  static const LinearGradient appBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [_darkBgTop, _darkBgMid, _darkBgEnd],
    stops: [0.0, 0.55, 1.0],
  );

  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);
    final accent = AppConfig.accentPinkColor;
    final appBarBrand = AppConfig.primaryPurpleColor;

    return base.copyWith(
      scaffoldBackgroundColor: _darkBgTop,
      colorScheme: const ColorScheme.dark().copyWith(
        primary: accent,
        secondary: accent,
        surface: _darkSurface,
        onSurface: _darkText,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: appBarBrand,
        foregroundColor: _darkText,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: const CardThemeData(
        color: _darkSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: _darkSurface2,
        selectedItemColor: accent,
        unselectedItemColor: const Color(0xFF9AA0C3),
        type: BottomNavigationBarType.fixed,
        elevation: 18,
      ),
      bottomAppBarTheme: const BottomAppBarTheme(
        color: _darkSurface2,
        elevation: 18,
        surfaceTintColor: Colors.transparent,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: _darkText,
        displayColor: _darkText,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0x22000000),
        thickness: 1,
        space: 1,
      ),
      iconTheme: const IconThemeData(color: _darkText),
      listTileTheme: const ListTileThemeData(
        iconColor: _darkText,
        textColor: _darkText,
      ),
    );
  }

  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);
    final accent = AppConfig.accentPinkColor;

    return base.copyWith(
      scaffoldBackgroundColor: _lightBg,
      colorScheme: const ColorScheme.light().copyWith(
        primary: accent,
        secondary: accent,
        surface: _lightSurface,
        onSurface: _lightText,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: _lightRoyalBlue,
        foregroundColor: _lightText,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: const CardThemeData(
        color: _lightSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: _lightSurface,
        selectedItemColor: accent,
        unselectedItemColor: _lightMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 12,
      ),
      bottomAppBarTheme: const BottomAppBarTheme(
        color: _lightSurface,
        elevation: 12,
        surfaceTintColor: Colors.transparent,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: _lightText,
        displayColor: _lightText,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0x14000000),
        thickness: 1,
        space: 1,
      ),
      iconTheme: const IconThemeData(color: _lightText),
      listTileTheme: const ListTileThemeData(
        iconColor: _lightText,
        textColor: _lightText,
      ),
    );
  }
}

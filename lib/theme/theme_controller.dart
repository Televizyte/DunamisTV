import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  ThemeController._();

  static final ThemeController instance = ThemeController._();

  static const String _prefsThemeKey = 'app_theme_mode_v1';

  ThemeMode _themeMode = ThemeMode.dark;
  bool _initialized = false;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  bool get isLightMode => _themeMode == ThemeMode.light;

  Future<void> init() async {
    if (_initialized) return;

    final prefs = await SharedPreferences.getInstance();
    final saved = (prefs.getString(_prefsThemeKey) ?? 'dark').trim();

    _themeMode = saved == 'light' ? ThemeMode.light : ThemeMode.dark;
    _initialized = true;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    await setThemeMode(isDarkMode ? ThemeMode.light : ThemeMode.dark);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode && _initialized) return;

    _themeMode = mode;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsThemeKey,
      mode == ThemeMode.light ? 'light' : 'dark',
    );

    notifyListeners();
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  SettingsProvider(this._prefs) {
    final stored = _prefs.getString(_themeKey);
    _themeMode = ThemeMode.values.firstWhere(
      (mode) => mode.name == stored,
      orElse: () => ThemeMode.system,
    );
  }

  static const _themeKey = 'settings.theme_mode';

  final SharedPreferences _prefs;

  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    await _prefs.setString(_themeKey, mode.name);
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_strings.dart';

/// Owns user-chosen app preferences:
/// - [themeMode]: light / dark / system
/// - [appLocale]: en / he / ar
///
/// Persisted via `shared_preferences`. Load `init()` once at app startup
/// before building `MaterialApp` so the first paint uses the saved values.
class SettingsProvider extends ChangeNotifier {
  static const _kThemeMode = 'settings.themeMode';
  static const _kLocale = 'settings.locale';

  ThemeMode _themeMode = ThemeMode.system;
  AppLocale _appLocale = AppLocale.en;
  SharedPreferences? _prefs;

  ThemeMode get themeMode => _themeMode;
  AppLocale get appLocale => _appLocale;
  Locale get locale => _appLocale.locale;

  /// Call once from `main.dart` before `runApp`.
  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final themeStr = _prefs?.getString(_kThemeMode);
      _themeMode = _parseThemeMode(themeStr);
      final localeStr = _prefs?.getString(_kLocale);
      _appLocale = AppLocaleX.parse(localeStr);
    } catch (_) {
      // If prefs init fails (very rare), fall back to defaults silently.
      _themeMode = ThemeMode.system;
      _appLocale = AppLocale.en;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    await _prefs?.setString(_kThemeMode, _themeModeKey(mode));
  }

  /// Convenience: cycle light -> dark -> system -> light (used by AppBar icon tap).
  Future<void> cycleThemeMode() async {
    final next = switch (_themeMode) {
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
      ThemeMode.system => ThemeMode.light,
    };
    await setThemeMode(next);
  }

  Future<void> setLocale(AppLocale locale) async {
    if (_appLocale == locale) return;
    _appLocale = locale;
    notifyListeners();
    await _prefs?.setString(_kLocale, locale.code);
  }

  static String _themeModeKey(ThemeMode mode) => switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      };

  static ThemeMode _parseThemeMode(String? v) => switch (v) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
}

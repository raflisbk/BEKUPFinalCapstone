import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger.dart';

/// Theme provider for managing dark/light mode
class ThemeProvider with ChangeNotifier {
  static const String _tag = 'ThemeProvider';
  static const String _themeKey = 'theme_mode';

  ThemeMode _themeMode = ThemeMode.light;
  bool _isInitialized = false;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isLightMode => _themeMode == ThemeMode.light;
  bool get isInitialized => _isInitialized;

  /// Initialize theme from saved preferences
  Future<void> initialize() async {
    try {
      AppLogger.debug(_tag, 'Initializing theme provider');

      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_themeKey);

      if (savedTheme != null) {
        _themeMode = ThemeMode.values.firstWhere(
          (mode) => mode.toString() == savedTheme,
          orElse: () => ThemeMode.light,
        );
        AppLogger.info(_tag, 'Loaded theme from preferences', {
          'theme': _themeMode.toString(),
        });
      } else {
        AppLogger.debug(_tag, 'No saved theme found, using light mode');
      }

      _isInitialized = true;
      notifyListeners();
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to initialize theme', e, stackTrace);
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Toggle between light and dark mode
  Future<void> toggleTheme() async {
    try {
      _themeMode = _themeMode == ThemeMode.light
          ? ThemeMode.dark
          : ThemeMode.light;

      AppLogger.info(_tag, 'Theme toggled', {
        'newTheme': _themeMode.toString(),
      });

      await _saveTheme();
      notifyListeners();
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to toggle theme', e, stackTrace);
    }
  }

  /// Set specific theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    try {
      if (_themeMode == mode) return;

      _themeMode = mode;

      AppLogger.info(_tag, 'Theme set', {
        'theme': _themeMode.toString(),
      });

      await _saveTheme();
      notifyListeners();
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to set theme', e, stackTrace);
    }
  }

  /// Save theme to preferences
  Future<void> _saveTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, _themeMode.toString());

      AppLogger.debug(_tag, 'Theme saved to preferences');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to save theme', e, stackTrace);
    }
  }

  /// Get brightness for current theme
  Brightness get brightness {
    return _themeMode == ThemeMode.dark
        ? Brightness.dark
        : Brightness.light;
  }

  /// Check if system theme should be used
  bool get useSystemTheme => _themeMode == ThemeMode.system;
}

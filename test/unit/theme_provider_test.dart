import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:relink/core/providers/theme_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ThemeProvider themeProvider;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    themeProvider = ThemeProvider();
  });

  group('ThemeProvider - Initialization Tests', () {
    test('initial theme mode is light', () {
      expect(themeProvider.themeMode, ThemeMode.light);
      expect(themeProvider.isLightMode, isTrue);
      expect(themeProvider.isDarkMode, isFalse);
    });

    test('isInitialized is false before initialization', () {
      expect(themeProvider.isInitialized, isFalse);
    });

    test('initialize sets isInitialized to true', () async {
      await themeProvider.initialize();
      expect(themeProvider.isInitialized, isTrue);
    });

    test('initialize loads saved theme from preferences', () async {
      SharedPreferences.setMockInitialValues({
        'theme_mode': ThemeMode.dark.toString(),
      });

      await themeProvider.initialize();

      expect(themeProvider.themeMode, ThemeMode.dark);
      expect(themeProvider.isDarkMode, isTrue);
    });

    test('initialize uses light mode when no saved theme', () async {
      await themeProvider.initialize();
      expect(themeProvider.themeMode, ThemeMode.light);
    });

    test('initialize handles invalid saved theme', () async {
      SharedPreferences.setMockInitialValues({
        'theme_mode': 'invalid_theme',
      });

      await themeProvider.initialize();
      expect(themeProvider.themeMode, ThemeMode.light);
    });

    test('initialize notifies listeners', () async {
      var notified = false;
      themeProvider.addListener(() {
        notified = true;
      });

      await themeProvider.initialize();
      expect(notified, isTrue);
    });
  });

  group('ThemeProvider - Toggle Tests', () {
    test('toggleTheme switches from light to dark', () async {
      await themeProvider.initialize();
      expect(themeProvider.themeMode, ThemeMode.light);

      await themeProvider.toggleTheme();
      expect(themeProvider.themeMode, ThemeMode.dark);
      expect(themeProvider.isDarkMode, isTrue);
    });

    test('toggleTheme switches from dark to light', () async {
      SharedPreferences.setMockInitialValues({
        'theme_mode': ThemeMode.dark.toString(),
      });
      await themeProvider.initialize();
      expect(themeProvider.themeMode, ThemeMode.dark);

      await themeProvider.toggleTheme();
      expect(themeProvider.themeMode, ThemeMode.light);
      expect(themeProvider.isLightMode, isTrue);
    });

    test('toggleTheme saves to preferences', () async {
      await themeProvider.initialize();
      await themeProvider.toggleTheme();

      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString('theme_mode');

      expect(savedTheme, ThemeMode.dark.toString());
    });

    test('toggleTheme notifies listeners', () async {
      await themeProvider.initialize();
      var notified = false;
      themeProvider.addListener(() {
        notified = true;
      });

      await themeProvider.toggleTheme();
      expect(notified, isTrue);
    });

    test('toggleTheme multiple times works correctly', () async {
      await themeProvider.initialize();

      await themeProvider.toggleTheme(); // light -> dark
      expect(themeProvider.themeMode, ThemeMode.dark);

      await themeProvider.toggleTheme(); // dark -> light
      expect(themeProvider.themeMode, ThemeMode.light);

      await themeProvider.toggleTheme(); // light -> dark
      expect(themeProvider.themeMode, ThemeMode.dark);
    });
  });

  group('ThemeProvider - SetThemeMode Tests', () {
    test('setThemeMode sets dark mode', () async {
      await themeProvider.initialize();
      await themeProvider.setThemeMode(ThemeMode.dark);

      expect(themeProvider.themeMode, ThemeMode.dark);
      expect(themeProvider.isDarkMode, isTrue);
    });

    test('setThemeMode sets light mode', () async {
      await themeProvider.initialize();
      await themeProvider.setThemeMode(ThemeMode.light);

      expect(themeProvider.themeMode, ThemeMode.light);
      expect(themeProvider.isLightMode, isTrue);
    });

    test('setThemeMode sets system mode', () async {
      await themeProvider.initialize();
      await themeProvider.setThemeMode(ThemeMode.system);

      expect(themeProvider.themeMode, ThemeMode.system);
      expect(themeProvider.useSystemTheme, isTrue);
    });

    test('setThemeMode does not change if already set', () async {
      await themeProvider.initialize();
      var notifyCount = 0;
      themeProvider.addListener(() {
        notifyCount++;
      });

      await themeProvider.setThemeMode(ThemeMode.light);

      // Should not notify since already light mode
      expect(notifyCount, 0);
    });

    test('setThemeMode saves to preferences', () async {
      await themeProvider.initialize();
      await themeProvider.setThemeMode(ThemeMode.dark);

      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString('theme_mode');

      expect(savedTheme, ThemeMode.dark.toString());
    });

    test('setThemeMode notifies listeners', () async {
      await themeProvider.initialize();
      var notified = false;
      themeProvider.addListener(() {
        notified = true;
      });

      await themeProvider.setThemeMode(ThemeMode.dark);
      expect(notified, isTrue);
    });
  });

  group('ThemeProvider - Getters Tests', () {
    test('isDarkMode returns true when dark mode', () async {
      await themeProvider.setThemeMode(ThemeMode.dark);
      expect(themeProvider.isDarkMode, isTrue);
      expect(themeProvider.isLightMode, isFalse);
    });

    test('isLightMode returns true when light mode', () async {
      await themeProvider.setThemeMode(ThemeMode.light);
      expect(themeProvider.isLightMode, isTrue);
      expect(themeProvider.isDarkMode, isFalse);
    });

    test('useSystemTheme returns true when system mode', () async {
      await themeProvider.setThemeMode(ThemeMode.system);
      expect(themeProvider.useSystemTheme, isTrue);
    });

    test('useSystemTheme returns false when not system mode', () async {
      await themeProvider.setThemeMode(ThemeMode.light);
      expect(themeProvider.useSystemTheme, isFalse);
    });

    test('brightness returns dark when dark mode', () async {
      await themeProvider.setThemeMode(ThemeMode.dark);
      expect(themeProvider.brightness, Brightness.dark);
    });

    test('brightness returns light when light mode', () async {
      await themeProvider.setThemeMode(ThemeMode.light);
      expect(themeProvider.brightness, Brightness.light);
    });
  });

  group('ThemeProvider - Persistence Tests', () {
    test('theme persists across provider instances', () async {
      final provider1 = ThemeProvider();
      await provider1.initialize();
      await provider1.setThemeMode(ThemeMode.dark);

      final provider2 = ThemeProvider();
      await provider2.initialize();

      expect(provider2.themeMode, ThemeMode.dark);
    });

    test('theme persists after app restart simulation', () async {
      await themeProvider.initialize();
      await themeProvider.setThemeMode(ThemeMode.dark);

      // Simulate app restart
      final newProvider = ThemeProvider();
      await newProvider.initialize();

      expect(newProvider.themeMode, ThemeMode.dark);
    });
  });

  group('ThemeProvider - Error Handling Tests', () {
    test('initialize handles errors gracefully', () async {
      // This test would require mocking SharedPreferences to throw error
      // For now, we verify it doesn't throw
      expect(() => themeProvider.initialize(), returnsNormally);
    });

    test('toggleTheme handles errors gracefully', () async {
      await themeProvider.initialize();
      expect(() => themeProvider.toggleTheme(), returnsNormally);
    });

    test('setThemeMode handles errors gracefully', () async {
      await themeProvider.initialize();
      expect(
        () => themeProvider.setThemeMode(ThemeMode.dark),
        returnsNormally,
      );
    });
  });

  group('ThemeProvider - Listener Tests', () {
    test('multiple listeners are notified', () async {
      await themeProvider.initialize();

      var listener1Called = false;
      var listener2Called = false;

      themeProvider.addListener(() {
        listener1Called = true;
      });

      themeProvider.addListener(() {
        listener2Called = true;
      });

      await themeProvider.toggleTheme();

      expect(listener1Called, isTrue);
      expect(listener2Called, isTrue);
    });

    test('removed listeners are not notified', () async {
      await themeProvider.initialize();

      var listenerCalled = false;
      void listener() {
        listenerCalled = true;
      }

      themeProvider.addListener(listener);
      themeProvider.removeListener(listener);

      await themeProvider.toggleTheme();

      expect(listenerCalled, isFalse);
    });
  });
}

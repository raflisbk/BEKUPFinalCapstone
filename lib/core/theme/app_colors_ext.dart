import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Extension untuk App Colors yang context-aware (dark mode support)
extension AppColorsExt on BuildContext {
  /// Check if dark mode is active
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  /// Get adaptive background color
  Color get adaptiveBackground =>
      isDarkMode ? const Color(0xFF000000) : AppColors.background;

  /// Get adaptive surface color
  Color get adaptiveSurface =>
      isDarkMode ? const Color(0xFF121212) : AppColors.surface;

  /// Get adaptive card color
  Color get adaptiveCard =>
      isDarkMode ? const Color(0xFF1E1E1E) : AppColors.white;

  /// Get adaptive text primary color
  Color get adaptiveTextPrimary =>
      isDarkMode ? AppColors.white : AppColors.textPrimary;

  /// Get adaptive text secondary color
  Color get adaptiveTextSecondary =>
      isDarkMode ? const Color(0xFFB0B0B0) : AppColors.textSecondary;

  /// Get adaptive text tertiary color
  Color get adaptiveTextTertiary =>
      isDarkMode ? const Color(0xFF808080) : AppColors.textTertiary;

  /// Get adaptive border color
  Color get adaptiveBorder =>
      isDarkMode ? const Color(0xFF2A2A2A) : AppColors.border;

  /// Get adaptive divider color
  Color get adaptiveDivider =>
      isDarkMode ? const Color(0xFF2A2A2A) : AppColors.divider;

  /// Get adaptive primary color (inverts in dark mode)
  Color get adaptivePrimary =>
      isDarkMode ? AppColors.white : AppColors.black;

  /// Get adaptive secondary color (inverts in dark mode)
  Color get adaptiveSecondary =>
      isDarkMode ? AppColors.black : AppColors.white;

  /// Get adaptive grey colors
  Color get adaptiveGrey50 =>
      isDarkMode ? const Color(0xFF2A2A2A) : AppColors.grey50;
  Color get adaptiveGrey100 =>
      isDarkMode ? const Color(0xFF2F2F2F) : AppColors.grey100;
  Color get adaptiveGrey200 =>
      isDarkMode ? const Color(0xFF3A3A3A) : AppColors.grey200;
  Color get adaptiveGrey300 =>
      isDarkMode ? const Color(0xFF4A4A4A) : AppColors.grey300;

  /// Get adaptive shadow color
  Color get adaptiveShadow =>
      isDarkMode ? const Color(0x33FFFFFF) : AppColors.shadow;

  /// Get adaptive overlay color
  Color get adaptiveOverlay =>
      isDarkMode ? const Color(0x1FFFFFFF) : AppColors.overlay;
}

/// Dark mode specific colors
class DarkModeColors {
  DarkModeColors._();

  static const Color background = Color(0xFF000000);
  static const Color surface = Color(0xFF121212);
  static const Color card = Color(0xFF1E1E1E);
  static const Color border = Color(0xFF2A2A2A);
  static const Color divider = Color(0xFF2A2A2A);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textTertiary = Color(0xFF808080);

  static const Color grey50 = Color(0xFF2A2A2A);
  static const Color grey100 = Color(0xFF2F2F2F);
  static const Color grey200 = Color(0xFF3A3A3A);
  static const Color grey300 = Color(0xFF4A4A4A);
  static const Color grey400 = Color(0xFF5A5A5A);
  static const Color grey500 = Color(0xFF6A6A6A);

  static const Color shadow = Color(0x33FFFFFF);
  static const Color overlay = Color(0x1FFFFFFF);
}

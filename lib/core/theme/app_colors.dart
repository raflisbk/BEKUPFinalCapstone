import 'package:flutter/material.dart';

/// App Colors - Minimalist Black & White Theme inspired by OpenAI
class AppColors {
  AppColors._();

  // Primary Colors - Pure Black & White
  static const Color primary = Color(0xFF000000); // Pure Black
  static const Color secondary = Color(0xFFFFFFFF); // Pure White
  static const Color background = Color(0xFFFFFFFF); // White Background
  static const Color surface = Color(0xFFFFFFFF); // White Surface

  // Grayscale Palette
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey900 = Color(0xFF212121);

  // Text Colors
  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF616161);
  static const Color textTertiary = Color(0xFF9E9E9E);
  static const Color textInverse = Color(0xFFFFFFFF);

  // Border & Divider
  static const Color border = Color(0xFFE0E0E0);
  static const Color divider = Color(0xFFEEEEEE);

  // Accent (minimal use for CTAs and highlights)
  static const Color accent = Color(0xFF000000);
  static const Color accentHover = Color(0xFF424242);

  // Status Colors (subtle)
  static const Color success = Color(0xFF2E7D32);
  static const Color error = Color(0xFFD32F2F);
  static const Color warning = Color(0xFFF57C00);
  static const Color info = Color(0xFF1976D2);

  // Shadow & Overlay
  static const Color shadow = Color(0x0A000000);
  static const Color overlay = Color(0x14000000);
  static const Color scrim = Color(0x33000000);
}

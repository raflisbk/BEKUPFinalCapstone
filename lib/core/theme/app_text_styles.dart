import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Text Styles - Minimalist Typography inspired by OpenAI
class AppTextStyles {
  AppTextStyles._();

  // Display Styles - For hero sections and large headings
  static const TextStyle displayLarge = TextStyle(
    fontSize: 72,
    fontWeight: FontWeight.w700,
    letterSpacing: -2.5,
    height: 1.1,
    color: AppColors.textPrimary,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 56,
    fontWeight: FontWeight.w700,
    letterSpacing: -2,
    height: 1.15,
    color: AppColors.textPrimary,
  );

  static const TextStyle displaySmall = TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.w600,
    letterSpacing: -1.5,
    height: 1.2,
    color: AppColors.textPrimary,
  );

  // Headline Styles
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 40,
    fontWeight: FontWeight.w600,
    letterSpacing: -1.2,
    height: 1.25,
    color: AppColors.textPrimary,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    letterSpacing: -1,
    height: 1.3,
    color: AppColors.textPrimary,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
    height: 1.35,
    color: AppColors.textPrimary,
  );

  // Title Styles
  static const TextStyle titleLarge = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.2,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  static const TextStyle titleSmall = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.1,
    height: 1.45,
    color: AppColors.textPrimary,
  );

  // Body Styles
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.2,
    height: 1.6,
    color: AppColors.textSecondary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.1,
    height: 1.6,
    color: AppColors.textSecondary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.5,
    color: AppColors.textSecondary,
  );

  // Label Styles
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.1,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.3,
    color: AppColors.textTertiary,
  );
}

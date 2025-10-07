import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_colors.dart';

/// Skeleton loader widgets for loading states
/// Provides consistent loading experience across the app
class SkeletonLoader {
  /// Skeleton container with shimmer effect
  static Widget container({
    required double width,
    required double height,
    double borderRadius = 8,
  }) {
    return Shimmer.fromColors(
      baseColor: AppColors.grey100,
      highlightColor: AppColors.grey50,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.grey100,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }

  /// Skeleton circle (for avatars)
  static Widget circle({required double size}) {
    return Shimmer.fromColors(
      baseColor: AppColors.grey100,
      highlightColor: AppColors.grey50,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.grey100,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  /// Skeleton line (for text)
  static Widget line({
    double width = double.infinity,
    double height = 16,
  }) {
    return Shimmer.fromColors(
      baseColor: AppColors.grey100,
      highlightColor: AppColors.grey50,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.grey100,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  /// Skeleton card for list items
  static Widget card({
    double height = 120,
    EdgeInsets margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  }) {
    return Container(
      margin: margin,
      child: Shimmer.fromColors(
        baseColor: AppColors.grey100,
        highlightColor: AppColors.grey50,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: AppColors.grey100,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  /// Skeleton for trip card
  static Widget tripCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder
          container(
            width: double.infinity,
            height: 160,
            borderRadius: 16,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                line(width: 200, height: 20),
                const SizedBox(height: 8),
                // Description
                line(width: double.infinity, height: 14),
                const SizedBox(height: 4),
                line(width: 150, height: 14),
                const SizedBox(height: 12),
                // Date and info
                Row(
                  children: [
                    line(width: 120, height: 12),
                    const Spacer(),
                    line(width: 60, height: 12),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Skeleton for chat conversation item
  static Widget chatListItem() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Avatar
          circle(size: 56),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                line(width: 150, height: 16),
                const SizedBox(height: 6),
                line(width: double.infinity, height: 14),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Timestamp
          line(width: 50, height: 12),
        ],
      ),
    );
  }

  /// Skeleton for review item
  static Widget reviewItem() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              circle(size: 40),
              const SizedBox(width: 12),
              // User info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    line(width: 120, height: 14),
                    const SizedBox(height: 4),
                    line(width: 80, height: 12),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Title
          line(width: 200, height: 16),
          const SizedBox(height: 8),
          // Content
          line(width: double.infinity, height: 14),
          const SizedBox(height: 4),
          line(width: double.infinity, height: 14),
          const SizedBox(height: 4),
          line(width: 180, height: 14),
        ],
      ),
    );
  }

  /// Skeleton for destination card
  static Widget destinationCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          container(
            width: double.infinity,
            height: 200,
            borderRadius: 16,
          ),
          const SizedBox(height: 12),
          // Title
          line(width: 180, height: 18),
          const SizedBox(height: 8),
          // Location
          line(width: 140, height: 14),
          const SizedBox(height: 8),
          // Rating
          Row(
            children: [
              line(width: 80, height: 14),
              const SizedBox(width: 16),
              line(width: 60, height: 14),
            ],
          ),
        ],
      ),
    );
  }

  /// Skeleton for profile header
  static Widget profileHeader() {
    return Shimmer.fromColors(
      baseColor: AppColors.grey100,
      highlightColor: AppColors.grey50,
      child: Column(
        children: [
          const SizedBox(height: 24),
          // Avatar
          Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(
              color: AppColors.grey100,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 16),
          // Name
          Container(
            width: 150,
            height: 20,
            decoration: BoxDecoration(
              color: AppColors.grey100,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          // Email
          Container(
            width: 200,
            height: 14,
            decoration: BoxDecoration(
              color: AppColors.grey100,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  /// List of skeleton cards
  static Widget list({
    required Widget Function() itemBuilder,
    int itemCount = 5,
  }) {
    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: (context, index) => itemBuilder(),
    );
  }

  /// Grid of skeleton items
  static Widget grid({
    required Widget Function() itemBuilder,
    int itemCount = 6,
    int crossAxisCount = 2,
  }) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) => itemBuilder(),
    );
  }

  /// Skeleton activity item
  static Widget activityItem() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          circle(size: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                line(width: double.infinity, height: 16),
                const SizedBox(height: 8),
                line(width: 100, height: 12),
              ],
            ),
          ),
          const SizedBox(width: 8),
          container(width: 36, height: 36, borderRadius: 8),
        ],
      ),
    );
  }

  /// Skeleton destination card
  static Widget destinationCard() {
    return Card(
      margin: const EdgeInsets.zero,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          container(width: double.infinity, height: 200, borderRadius: 12),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                container(width: 80, height: 24, borderRadius: 4),
                const SizedBox(height: 12),
                line(width: double.infinity, height: 20),
                const SizedBox(height: 8),
                line(width: 200, height: 16),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    container(width: 100, height: 16, borderRadius: 4),
                    container(width: 60, height: 16, borderRadius: 4),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

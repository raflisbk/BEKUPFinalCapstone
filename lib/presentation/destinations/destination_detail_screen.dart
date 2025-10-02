import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class DestinationDetailScreen extends StatelessWidget {
  final String title;
  final String location;
  final String guides;

  const DestinationDetailScreen({
    super.key,
    required this.title,
    required this.location,
    required this.guides,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: CustomScrollView(
        slivers: [
          // Image Hero Header
          SliverAppBar(
            expandedHeight: 350,
            pinned: true,
            backgroundColor: AppColors.white,
            surfaceTintColor: Colors.transparent,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.black),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border, width: 1.5),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.bookmark_outline, color: AppColors.black),
                    onPressed: () {},
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Placeholder Image
                  Container(
                    color: AppColors.grey100,
                    child: const Icon(
                      Icons.landscape_outlined,
                      size: 120,
                      color: AppColors.grey400,
                    ),
                  ),

                  // Gradient Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppColors.black.withOpacity(0.3),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Container(
              transform: Matrix4.translationValues(0, -20, 0),
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title & Location
                    FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: AppTextStyles.headlineMedium,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 20,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                location,
                                style: AppTextStyles.bodyLarge.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Stats
                    FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 100),
                      child: Row(
                        children: [
                          _StatCard(
                            icon: Icons.star,
                            value: '4.8',
                            label: 'Rating',
                          ),
                          const SizedBox(width: 16),
                          _StatCard(
                            icon: Icons.people_outline,
                            value: guides,
                            label: 'Guides',
                          ),
                          const SizedBox(width: 16),
                          _StatCard(
                            icon: Icons.remove_red_eye_outlined,
                            value: '2.5k',
                            label: 'Visitors',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Description
                    FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 200),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'About',
                            style: AppTextStyles.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Discover the breathtaking beauty of $title, a must-visit destination in $location. Experience authentic local culture, stunning landscapes, and unforgettable moments with our verified local guides.',
                            style: AppTextStyles.bodyLarge.copyWith(
                              height: 1.8,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Available Guides
                    FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 300),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Available Guides',
                                style: AppTextStyles.titleLarge,
                              ),
                              TextButton(
                                onPressed: () {},
                                child: const Text('View all'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _GuidePreviewCard(),
                          const SizedBox(height: 12),
                          _GuidePreviewCard(),
                        ],
                      ),
                    ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      // Bottom CTA
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border(
            top: BorderSide(color: AppColors.divider, width: 1),
          ),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: () {},
              child: const Text('Book a Guide'),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.grey50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Column(
          children: [
            Icon(icon, size: 24, color: AppColors.black),
            const SizedBox(height: 8),
            Text(
              value,
              style: AppTextStyles.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuidePreviewCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.grey100,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.person_outline,
              color: AppColors.grey400,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Made Wijaya',
                  style: AppTextStyles.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'Cultural Expert',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.grey50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.star, size: 14, color: AppColors.black),
                const SizedBox(width: 4),
                Text(
                  '4.9',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

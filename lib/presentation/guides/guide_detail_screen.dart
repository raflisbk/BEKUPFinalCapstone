import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class GuideDetailScreen extends StatelessWidget {
  final String name;
  final String expertise;
  final String rating;
  final String price;

  const GuideDetailScreen({
    super.key,
    required this.name,
    required this.expertise,
    required this.rating,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: AppColors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Section
              FadeInDown(
                duration: const Duration(milliseconds: 600),
                child: Center(
                  child: Column(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: AppColors.grey100,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.border, width: 3),
                        ),
                        child: const Icon(
                          Icons.person_outline,
                          size: 60,
                          color: AppColors.grey400,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        name,
                        style: AppTextStyles.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        expertise,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.grey50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, size: 18, color: AppColors.black),
                            const SizedBox(width: 6),
                            Text(
                              '$rating (156 reviews)',
                              style: AppTextStyles.labelLarge.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Stats
              FadeInUp(
                duration: const Duration(milliseconds: 600),
                delay: const Duration(milliseconds: 100),
                child: Row(
                  children: [
                    _StatItem(icon: Icons.tour_outlined, value: '127', label: 'Tours'),
                    const SizedBox(width: 16),
                    _StatItem(icon: Icons.language, value: '3', label: 'Languages'),
                    const SizedBox(width: 16),
                    _StatItem(icon: Icons.access_time, value: '5+', label: 'Years'),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // About
              FadeInUp(
                duration: const Duration(milliseconds: 600),
                delay: const Duration(milliseconds: 200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'About Me',
                      style: AppTextStyles.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Hello! I\'m $name, a passionate local guide with over 5 years of experience. I specialize in $expertise and love sharing the rich culture and hidden gems of my hometown with travelers from around the world.',
                      style: AppTextStyles.bodyLarge.copyWith(
                        height: 1.8,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Languages
              FadeInUp(
                duration: const Duration(milliseconds: 600),
                delay: const Duration(milliseconds: 300),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Languages',
                      style: AppTextStyles.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _LanguageChip(language: 'Indonesian'),
                        _LanguageChip(language: 'English'),
                        _LanguageChip(language: 'Japanese'),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Specializations
              FadeInUp(
                duration: const Duration(milliseconds: 600),
                delay: const Duration(milliseconds: 400),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Specializations',
                      style: AppTextStyles.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _SpecializationChip(label: 'Cultural Tours'),
                        _SpecializationChip(label: 'Historical Sites'),
                        _SpecializationChip(label: 'Food & Culinary'),
                        _SpecializationChip(label: 'Nature Hiking'),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Reviews Preview
              FadeInUp(
                duration: const Duration(milliseconds: 600),
                delay: const Duration(milliseconds: 500),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Reviews',
                          style: AppTextStyles.titleLarge,
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text('View all'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _ReviewCard(
                      name: 'John Smith',
                      rating: 5,
                      comment: 'Amazing experience! Very knowledgeable and friendly.',
                    ),
                    const SizedBox(height: 12),
                    _ReviewCard(
                      name: 'Sarah Lee',
                      rating: 5,
                      comment: 'Best guide ever! Highly recommended.',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
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
          child: Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Price',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    price,
                    style: AppTextStyles.titleLarge,
                  ),
                ],
              ),
              const SizedBox(width: 24),
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      _showBookingDialog(context);
                    },
                    child: const Text('Book Now'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBookingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.white,
        title: Text(
          'Book Guide',
          style: AppTextStyles.headlineSmall,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select your tour date',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                hintText: 'Select date',
                suffixIcon: Icon(Icons.calendar_today_outlined),
              ),
              readOnly: true,
              onTap: () {
                // Show date picker
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Booking request sent!'),
                  backgroundColor: AppColors.black,
                ),
              );
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatItem({
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

class _LanguageChip extends StatelessWidget {
  final String language;

  const _LanguageChip({required this.language});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        language,
        style: AppTextStyles.labelMedium,
      ),
    );
  }
}

class _SpecializationChip extends StatelessWidget {
  final String label;

  const _SpecializationChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.black,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelMedium.copyWith(
          color: AppColors.white,
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final String name;
  final int rating;
  final String comment;

  const _ReviewCard({
    required this.name,
    required this.rating,
    required this.comment,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(
                  Icons.person_outline,
                  size: 20,
                  color: AppColors.grey400,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AppTextStyles.titleSmall,
                    ),
                    Row(
                      children: List.generate(
                        rating,
                        (index) => const Icon(
                          Icons.star,
                          size: 14,
                          color: AppColors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            comment,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

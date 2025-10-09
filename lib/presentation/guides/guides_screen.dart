import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/logger.dart';
import 'guide_detail_screen.dart';

class GuidesScreen extends StatefulWidget {
  const GuidesScreen({super.key});

  @override
  State<GuidesScreen> createState() => _GuidesScreenState();
}

class _GuidesScreenState extends State<GuidesScreen> {
  static const String _tag = 'GuidesScreen';

  @override
  void initState() {
    super.initState();
    AppLogger.debug(_tag, 'Guides screen initialized', {
      'guidesCount': _guides.length,
    });
  }

  void _navigateToGuideDetail(BuildContext context, String name, String expertise, String rating, String price) {
    AppLogger.action('User tapped guide card', {
      'name': name,
      'expertise': expertise,
    });
    AppLogger.navigation(_tag, '/guide-detail', {'name': name});
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GuideDetailScreen(
          name: name,
          expertise: expertise,
          rating: rating,
          price: price,
        ),
      ),
    );
  }

  static final List<Map<String, String>> _guides = [
    {
      'name': 'Made Wijaya',
      'expertise': 'Cultural & History Tours',
      'rating': '4.9',
      'price': 'Rp 500k/day',
    },
    {
      'name': 'Siti Rahayu',
      'expertise': 'Culinary Adventures',
      'rating': '4.8',
      'price': 'Rp 400k/day',
    },
    {
      'name': 'Budi Santoso',
      'expertise': 'Nature & Hiking',
      'rating': '4.7',
      'price': 'Rp 600k/day',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              floating: true,
              backgroundColor: AppColors.white,
              surfaceTintColor: Colors.transparent,
              title: const Text(
                'Local Guides',
                style: AppTextStyles.headlineSmall,
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(
                  color: AppColors.divider,
                  height: 1,
                ),
              ),
            ),

            // Content
            SliverPadding(
              padding: const EdgeInsets.all(24.0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return _GuideCard(
                      name: _guides[index]['name']!,
                      expertise: _guides[index]['expertise']!,
                      rating: _guides[index]['rating']!,
                      price: _guides[index]['price']!,
                      onTap: () => _navigateToGuideDetail(
                        context,
                        _guides[index]['name']!,
                        _guides[index]['expertise']!,
                        _guides[index]['rating']!,
                        _guides[index]['price']!,
                      ),
                    );
                  },
                  childCount: _guides.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuideCard extends StatelessWidget {
  final String name;
  final String expertise;
  final String rating;
  final String price;
  final VoidCallback onTap;

  const _GuideCard({
    required this.name,
    required this.expertise,
    required this.rating,
    required this.price,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: AppColors.grey400,
                  size: 32,
                ),
              ),

              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: AppTextStyles.titleMedium,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.grey50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.star,
                                size: 14,
                                color: AppColors.black,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                rating,
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
                    const SizedBox(height: 6),
                    Text(
                      expertise,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      price,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.black,
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
    );
  }
}

import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Custom App Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Logo
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.black,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          'R',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppColors.white,
                            letterSpacing: -1,
                          ),
                        ),
                      ),
                    ),

                    // Notification Icon
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.notifications_outlined),
                      color: AppColors.black,
                    ),
                  ],
                ),
              ),
            ),

            // Hero Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),

                    // Greeting
                    FadeInDown(
                      duration: const Duration(milliseconds: 600),
                      child: Text(
                        'Discover your\nnext adventure',
                        style: AppTextStyles.displaySmall.copyWith(
                          fontSize: 48,
                          height: 1.1,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Subtitle
                    FadeInDown(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 100),
                      child: Text(
                        'Connect with local guides and fellow travelers\nfor authentic experiences.',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.6,
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Search Bar
                    FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 200),
                      child: _SearchBar(),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 56)),

            // Quick Actions
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: FadeInUp(
                  duration: const Duration(milliseconds: 600),
                  delay: const Duration(milliseconds: 300),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Actions',
                        style: AppTextStyles.titleLarge,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: _QuickActionCard(
                              icon: Icons.people_outline,
                              title: 'Find\nTravelers',
                              onTap: () {},
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _QuickActionCard(
                              icon: Icons.explore_outlined,
                              title: 'Local\nGuides',
                              onTap: () {},
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 56)),

            // Featured Destinations Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: FadeInUp(
                  duration: const Duration(milliseconds: 600),
                  delay: const Duration(milliseconds: 400),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Featured Destinations',
                        style: AppTextStyles.titleLarge,
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text('View all'),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Destinations List
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      delay: Duration(milliseconds: 500 + (index * 100)),
                      child: _DestinationCard(
                        title: _destinations[index]['title']!,
                        location: _destinations[index]['location']!,
                        guides: _destinations[index]['guides']!,
                      ),
                    );
                  },
                  childCount: _destinations.length,
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  static final List<Map<String, String>> _destinations = [
    {
      'title': 'Ubud Rice Terraces',
      'location': 'Bali, Indonesia',
      'guides': '12 guides available',
    },
    {
      'title': 'Mount Bromo',
      'location': 'East Java, Indonesia',
      'guides': '8 guides available',
    },
    {
      'title': 'Raja Ampat Islands',
      'location': 'West Papua, Indonesia',
      'guides': '5 guides available',
    },
  ];
}

class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search destinations, guides...',
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textTertiary,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: AppColors.textTertiary,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 160,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.black,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: AppColors.white,
                size: 24,
              ),
            ),
            Text(
              title,
              style: AppTextStyles.titleMedium.copyWith(
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DestinationCard extends StatelessWidget {
  final String title;
  final String location;
  final String guides;

  const _DestinationCard({
    required this.title,
    required this.location,
    required this.guides,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
          child: Row(
            children: [
              // Placeholder Image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(
                  Icons.landscape_outlined,
                  color: AppColors.grey400,
                  size: 32,
                ),
              ),

              const SizedBox(width: 20),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          location,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.grey50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        guides,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

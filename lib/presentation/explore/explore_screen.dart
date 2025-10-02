import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

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
              title: Text(
                'Explore',
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
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Map Placeholder
                    Container(
                      height: 300,
                      decoration: BoxDecoration(
                        color: AppColors.grey100,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border, width: 1.5),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.map_outlined,
                              size: 64,
                              color: AppColors.grey400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Map will be integrated here',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    Text(
                      'Nearby Travelers',
                      style: AppTextStyles.titleLarge,
                    ),

                    const SizedBox(height: 16),

                    Text(
                      'Find and connect with travelers near your location.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

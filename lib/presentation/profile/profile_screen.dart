import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
                'Profile',
                style: AppTextStyles.headlineSmall,
              ),
              actions: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.settings_outlined),
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(
                  color: AppColors.divider,
                  height: 1,
                ),
              ),
            ),

            // Profile Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // Avatar
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppColors.grey100,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border, width: 2),
                      ),
                      child: const Icon(
                        Icons.person_outline,
                        color: AppColors.grey400,
                        size: 48,
                      ),
                    ),

                    const SizedBox(height: 20),

                    Text(
                      'Guest User',
                      style: AppTextStyles.headlineSmall,
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'guest@relink.app',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Edit Profile Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () {},
                        child: const Text('Edit Profile'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Menu Items
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _MenuItem(
                    icon: Icons.bookmark_outline,
                    title: 'Saved Destinations',
                    onTap: () {},
                  ),
                  _MenuItem(
                    icon: Icons.history,
                    title: 'Trip History',
                    onTap: () {},
                  ),
                  _MenuItem(
                    icon: Icons.payment_outlined,
                    title: 'Payment Methods',
                    onTap: () {},
                  ),
                  _MenuItem(
                    icon: Icons.help_outline,
                    title: 'Help & Support',
                    onTap: () {},
                  ),
                  _MenuItem(
                    icon: Icons.info_outline,
                    title: 'About ReLink',
                    onTap: () {},
                  ),
                  const SizedBox(height: 16),
                  _MenuItem(
                    icon: Icons.logout,
                    title: 'Sign Out',
                    onTap: () {},
                    isDestructive: true,
                  ),
                ]),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDestructive ? AppColors.error : AppColors.black,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.titleSmall.copyWith(
                  color: isDestructive ? AppColors.error : AppColors.black,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isDestructive ? AppColors.error : AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

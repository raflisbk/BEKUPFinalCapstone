import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/logger.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/user_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const String _tag = 'ProfileScreen';

  @override
  void initState() {
    super.initState();
    AppLogger.debug(_tag, 'Profile screen initialized');

    // Fetch user profile when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.isAuthenticated && !authProvider.isGuest) {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        userProvider.fetchUserProfile();
      }
    });
  }

  void _handleSettings() {
    AppLogger.action('User tapped settings icon');
    // TODO: Navigate to settings screen
    AppLogger.warning(_tag, 'Settings screen not implemented yet');
  }

  void _handleEditProfile(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    AppLogger.action('User tapped edit profile');

    if (authProvider.isGuest) {
      _showGuestModeDialog(context);
      return;
    }

    if (userProvider.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please wait, loading profile...')),
      );
      return;
    }

    _showEditProfileDialog(context, userProvider);
  }

  void _showEditProfileDialog(BuildContext context, UserProvider userProvider) {
    final nameController = TextEditingController(text: userProvider.currentUser?.displayName);
    final bioController = TextEditingController(text: userProvider.currentUser?.bio);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                hintText: 'Enter your name',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: bioController,
              decoration: const InputDecoration(
                labelText: 'Bio',
                hintText: 'Tell us about yourself',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final updatedUser = userProvider.currentUser!.copyWith(
                displayName: nameController.text.trim(),
                bio: bioController.text.trim(),
              );

              final success = await userProvider.updateProfile(updatedUser);

              if (context.mounted) {
                Navigator.pop(context);

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profile updated successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(userProvider.errorMessage ?? 'Failed to update profile'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showGuestModeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign In Required'),
        content: const Text('Please create an account or sign in to edit your profile.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/auth');
            },
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
  }

  void _handleToggleGuideMode(BuildContext context, bool currentValue) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.isGuest) {
      _showGuestModeDialog(context);
      return;
    }

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final success = await userProvider.toggleGuideMode(!currentValue);

    if (context.mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            !currentValue ? 'Guide mode enabled' : 'Guide mode disabled',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _handleMenuItem(String menuItem) {
    AppLogger.action('User tapped menu item', {'item': menuItem});
    // TODO: Navigate to respective screen
    AppLogger.warning(_tag, 'Menu item "$menuItem" not implemented yet');
  }

  void _handleSignOut(BuildContext context) async {
    AppLogger.action('User tapped sign out');

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.signOut();

      if (context.mounted) {
        AppLogger.navigation(_tag, '/auth', {'reason': 'sign_out'});
        Navigator.pushReplacementNamed(context, '/auth');
      }
    }
  }

  @override
  void dispose() {
    AppLogger.debug(_tag, 'Disposing profile screen');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, UserProvider>(
      builder: (context, authProvider, userProvider, child) {
        final user = userProvider.currentUser;
        final isGuest = authProvider.isGuest;
        final displayName = isGuest
            ? 'Guest User'
            : (user?.displayName ?? authProvider.user?.displayName ?? 'User');
        final email = isGuest
            ? 'guest@relink.app'
            : (user?.email ?? authProvider.user?.email ?? '');
        final bio = user?.bio ?? 'No bio yet';
        final isGuideMode = user?.isGuide ?? false;

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
                      onPressed: _handleSettings,
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
                          child: user?.photoUrl != null
                              ? ClipOval(
                                  child: Image.network(
                                    user!.photoUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.person_outline,
                                      color: AppColors.grey400,
                                      size: 48,
                                    ),
                                  ),
                                )
                              : const Icon(
                                  Icons.person_outline,
                                  color: AppColors.grey400,
                                  size: 48,
                                ),
                        ),

                        const SizedBox(height: 20),

                        Text(
                          displayName,
                          style: AppTextStyles.headlineSmall,
                        ),

                        const SizedBox(height: 8),

                        Text(
                          email,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),

                        if (!isGuest && bio.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            bio,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textTertiary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],

                        const SizedBox(height: 24),

                        // Edit Profile Button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton(
                            onPressed: userProvider.isLoading
                                ? null
                                : () => _handleEditProfile(context),
                            child: userProvider.isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('Edit Profile'),
                          ),
                        ),

                        // Guide Mode Toggle (only for authenticated users)
                        if (!isGuest) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.border, width: 1.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.badge_outlined),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Guide Mode',
                                        style: AppTextStyles.titleSmall,
                                      ),
                                      Text(
                                        'Become a local guide',
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: AppColors.textTertiary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: isGuideMode,
                                  onChanged: userProvider.isLoading
                                      ? null
                                      : (value) => _handleToggleGuideMode(context, isGuideMode),
                                ),
                              ],
                            ),
                          ),
                        ],
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
                        onTap: () => _handleMenuItem('Saved Destinations'),
                      ),
                      _MenuItem(
                        icon: Icons.history,
                        title: 'Trip History',
                        onTap: () => _handleMenuItem('Trip History'),
                      ),
                      _MenuItem(
                        icon: Icons.payment_outlined,
                        title: 'Payment Methods',
                        onTap: () => _handleMenuItem('Payment Methods'),
                      ),
                      _MenuItem(
                        icon: Icons.help_outline,
                        title: 'Help & Support',
                        onTap: () => _handleMenuItem('Help & Support'),
                      ),
                      _MenuItem(
                        icon: Icons.info_outline,
                        title: 'About ReLink',
                        onTap: () => _handleMenuItem('About ReLink'),
                      ),
                      const SizedBox(height: 16),
                      _MenuItem(
                        icon: Icons.logout,
                        title: 'Sign Out',
                        onTap: () => _handleSignOut(context),
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
      },
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

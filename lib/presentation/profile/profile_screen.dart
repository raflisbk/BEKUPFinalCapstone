import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/logger.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/user_provider.dart';
import '../../core/constants/default_avatars.dart';
import '../../core/widgets/sync_status_widget.dart';
import '../../services/cloudinary_photo_upload_service.dart';

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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings available in menu'),
        duration: Duration(seconds: 2),
      ),
    );
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _EditProfileScreen(userProvider: userProvider),
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

    switch (menuItem) {
      case 'My Trips':
        Navigator.pushNamed(context, '/trips');
        break;
      case 'Saved Destinations':
        Navigator.pushNamed(context, '/destinations');
        break;
      case 'Reviews':
        Navigator.pushNamed(context, '/reviews');
        break;
      case 'Settings':
        _handleSettings();
        break;
      default:
        AppLogger.debug(_tag, 'Menu item handled: $menuItem');
    }
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
                  title: const Text(
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
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.border, width: 2),
                          ),
                          child: user?.photoUrl != null
                              ? (user!.photoUrl!.startsWith('avatar:')
                                  ? Center(
                                      child: Text(
                                        user.photoUrl!.replaceFirst('avatar:', ''),
                                        style: const TextStyle(fontSize: 56),
                                      ),
                                    )
                                  : ClipRRect(
                                      borderRadius: BorderRadius.circular(18),
                                      child: Image.network(
                                        user.photoUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => const Icon(
                                          Icons.person_outline,
                                          color: AppColors.grey400,
                                          size: 48,
                                        ),
                                      ),
                                    ))
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
                                      const Text(
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
                      // Sync Status Card
                      const Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: SyncStatusWidget(
                          showLabel: true,
                          compact: false,
                        ),
                      ),
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

// Edit Profile Full Screen
class _EditProfileScreen extends StatefulWidget {
  final UserProvider userProvider;

  const _EditProfileScreen({required this.userProvider});

  @override
  State<_EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<_EditProfileScreen> {
  static const String _tag = 'EditProfileScreen';
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  final CloudinaryPhotoUploadService _photoService = CloudinaryPhotoUploadService();
  File? _selectedImage;
  String? _newPhotoUrl;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userProvider.currentUser?.displayName);
    _bioController = TextEditingController(text: widget.userProvider.currentUser?.bio);
    AppLogger.debug(_tag, 'Edit profile screen initialized');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    AppLogger.debug(_tag, 'Edit profile screen disposed');
    super.dispose();
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose Profile Photo',
                style: AppTextStyles.headlineSmall,
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library),
                ),
                title: const Text('Gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  final image = await _photoService.pickImageFromGallery();
                  if (image != null) {
                    setState(() {
                      _selectedImage = image;
                    });
                  }
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.camera_alt),
                ),
                title: const Text('Camera'),
                onTap: () async {
                  Navigator.pop(context);
                  final image = await _photoService.pickImageFromCamera();
                  if (image != null) {
                    setState(() {
                      _selectedImage = image;
                    });
                  }
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.pets),
                ),
                title: const Text('Choose Avatar'),
                onTap: () {
                  Navigator.pop(context);
                  _showAvatarPicker();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAvatarPicker() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Choose Your Avatar',
                      style: AppTextStyles.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Select an animal that represents you',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: GridView.builder(
                    shrinkWrap: true,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 1,
                    ),
                    itemCount: DefaultAvatars.count,
                    itemBuilder: (context, index) {
                      final avatar = DefaultAvatars.getAvatarByIndex(index);
                      final isSelected = _newPhotoUrl == 'avatar:$avatar';
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _newPhotoUrl = 'avatar:$avatar';
                            _selectedImage = null;
                          });
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Avatar selected'),
                              backgroundColor: AppColors.black,
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.grey50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? AppColors.black : AppColors.border,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              avatar,
                              style: const TextStyle(fontSize: 28),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    AppLogger.action('User saving profile changes');

    try {
      String? photoUrl = widget.userProvider.currentUser?.photoUrl;

      // Upload new photo if selected
      if (_selectedImage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Uploading photo...'),
            duration: Duration(seconds: 2),
          ),
        );

        final uploadedUrl = await _photoService.uploadAvatar(_selectedImage!);
        if (uploadedUrl != null) {
          photoUrl = uploadedUrl;
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to upload photo'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      } else if (_newPhotoUrl != null) {
        photoUrl = _newPhotoUrl;
      }

      final updatedUser = widget.userProvider.currentUser!.copyWith(
        displayName: _nameController.text.trim(),
        bio: _bioController.text.trim(),
        photoUrl: photoUrl,
      );

      final success = await widget.userProvider.updateProfile(updatedUser);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.userProvider.errorMessage ?? 'Failed to update profile'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to save profile', e, stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred while saving'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        return Scaffold(
          backgroundColor: AppColors.white,
          appBar: AppBar(
            backgroundColor: AppColors.white,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Edit Profile',
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
          body: SafeArea(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Picture Section
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: AppColors.grey100,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border, width: 2),
                            ),
                            child: _selectedImage != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Image.file(
                                      _selectedImage!,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : _newPhotoUrl != null && _newPhotoUrl!.startsWith('avatar:')
                                    ? Center(
                                        child: Text(
                                          _newPhotoUrl!.replaceFirst('avatar:', ''),
                                          style: const TextStyle(fontSize: 56),
                                        ),
                                      )
                                    : userProvider.currentUser?.photoUrl != null
                                        ? (userProvider.currentUser!.photoUrl!.startsWith('avatar:')
                                            ? Center(
                                                child: Text(
                                                  userProvider.currentUser!.photoUrl!.replaceFirst('avatar:', ''),
                                                  style: const TextStyle(fontSize: 56),
                                                ),
                                              )
                                            : ClipRRect(
                                                borderRadius: BorderRadius.circular(14),
                                                child: Image.network(
                                                  userProvider.currentUser!.photoUrl!,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) => const Icon(
                                                    Icons.person_outline,
                                                    color: AppColors.grey400,
                                                    size: 48,
                                                  ),
                                                ),
                                              ))
                                        : const Icon(
                                            Icons.person_outline,
                                            color: AppColors.grey400,
                                            size: 48,
                                          ),
                          ),
                          const SizedBox(height: 12),
                          TextButton.icon(
                            onPressed: userProvider.isLoading ? null : _showPhotoOptions,
                            icon: const Icon(Icons.camera_alt_outlined, size: 20),
                            label: const Text('Change Photo'),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Full Name Field
                    const Text(
                      'Full Name',
                      style: AppTextStyles.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: 'Enter your full name',
                        hintStyle: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textTertiary,
                        ),
                        filled: true,
                        fillColor: AppColors.grey50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.black, width: 2),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.error),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      style: AppTextStyles.bodyMedium,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your name';
                        }
                        if (value.trim().length < 2) {
                          return 'Name must be at least 2 characters';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // Bio Field
                    const Text(
                      'Bio',
                      style: AppTextStyles.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _bioController,
                      decoration: InputDecoration(
                        hintText: 'Tell us about yourself...',
                        hintStyle: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textTertiary,
                        ),
                        filled: true,
                        fillColor: AppColors.grey50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.black, width: 2),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.error),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      style: AppTextStyles.bodyMedium,
                      maxLines: 5,
                      maxLength: 200,
                      textInputAction: TextInputAction.newline,
                    ),

                    const SizedBox(height: 32),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: userProvider.isLoading ? null : _handleSave,
                        child: userProvider.isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text('Save Changes'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

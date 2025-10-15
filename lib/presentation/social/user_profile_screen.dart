import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../services/user_service.dart';
import '../../services/social_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/haptic_helper.dart';
import '../../core/widgets/skeleton_loader.dart';

/// Screen to view another user's profile and follow/unfollow them
class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({
    super.key,
    required this.userId,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  Map<String, dynamic>? _userProfile;
  Map<String, dynamic>? _socialStats;
  bool _isFollowing = false;
  bool _isLoading = true;
  bool _isFollowActionLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      // Load user profile using UserService
      final userService = UserService();
      final userProfile = await userService.getUserProfile(widget.userId);

      if (userProfile == null) {
        throw Exception('User not found');
      }

      // Check if current user is following this user
      // ignore: use_build_context_synchronously
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUserId = authProvider.user?.uid;

      // Load social statistics
      Map<String, dynamic>? socialStats;
      bool following = false;
      
      if (currentUserId != null) {
        // Get social statistics
        socialStats = await SocialService.getUserSocialStatistics(userId: widget.userId);
        
        // Check if following
        following = await SocialService.isFollowing(widget.userId);
      }

      setState(() {
        _userProfile = userProfile;
        _socialStats = socialStats;
        _isFollowing = following;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  Future<void> _toggleFollow() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to follow users')),
      );
      return;
    }

    await HapticHelper.buttonTap();
    setState(() => _isFollowActionLoading = true);

    try {
      if (_isFollowing) {
        await SocialService.unfollowUser(widget.userId);
      } else {
        await SocialService.followUser(widget.userId);
      }

      setState(() {
        _isFollowing = !_isFollowing;
        // Update follower count in social stats
        if (_socialStats != null) {
          final currentFollowersCount = _socialStats!['followers_count'] as int? ?? 0;
          _socialStats = {
            ..._socialStats!,
            'followers_count': currentFollowersCount + (_isFollowing ? 1 : -1),
          };
        }
      });
      await HapticHelper.success();
    } catch (e) {
      await HapticHelper.error();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _isFollowActionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUserId = authProvider.user?.uid;
    final isOwnProfile = currentUserId == widget.userId;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.black,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: AppColors.grey200,
          ),
        ),
      ),
      body: _isLoading ? _buildLoadingState() : _buildContent(isOwnProfile),
    );
  }

  Widget _buildLoadingState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SkeletonLoader.circle(size: 120),
          const SizedBox(height: 16),
          SkeletonLoader.line(width: 150, height: 24),
          const SizedBox(height: 8),
          SkeletonLoader.line(width: 200, height: 16),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SkeletonLoader.container(width: 80, height: 60),
              SkeletonLoader.container(width: 80, height: 60),
              SkeletonLoader.container(width: 80, height: 60),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isOwnProfile) {
    if (_userProfile == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_off, size: 64, color: AppColors.grey400),
            const SizedBox(height: 16),
            Text(
              'User not found',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Profile photo
          _buildProfilePhoto(),
          const SizedBox(height: 16),

          // Name
          Text(
            _userProfile!['display_name'] ?? 'Unknown User',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),

          // Email
          if (_userProfile!['email'] != null && (_userProfile!['email'] as String).isNotEmpty)
            Text(
              _userProfile!['email'],
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.grey600,
                  ),
            ),
          const SizedBox(height: 24),

          // Follow button (only show if not own profile)
          if (!isOwnProfile) _buildFollowButton(),
          const SizedBox(height: 24),

          // Stats
          _buildStats(),
          const SizedBox(height: 32),

          // Bio section
          if (_userProfile!['bio'] != null && (_userProfile!['bio'] as String).isNotEmpty) ...[
            _buildBioSection(),
            const SizedBox(height: 32),
          ],

          // Interests section
          if (_userProfile!['interests'] != null && (_userProfile!['interests'] as List).isNotEmpty) ...[
            _buildInterestsSection(),
            const SizedBox(height: 32),
          ],
        ],
      ),
    );
  }

  Widget _buildProfilePhoto() {
    final photoUrl = _userProfile!['photo_url'] as String?;
    
    if (photoUrl != null && photoUrl.startsWith('avatar:')) {
      // Emoji avatar
      final emoji = photoUrl.replaceFirst('avatar:', '');
      return Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: AppColors.grey100,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.grey300, width: 3),
        ),
        child: Center(
          child: Text(
            emoji,
            style: const TextStyle(fontSize: 60),
          ),
        ),
      );
    } else if (photoUrl != null) {
      // Photo avatar
      return CircleAvatar(
        radius: 60,
        backgroundImage: NetworkImage(photoUrl),
        backgroundColor: AppColors.grey100,
      );
    } else {
      // Default avatar
      return const CircleAvatar(
        radius: 60,
        backgroundColor: AppColors.grey200,
        child: Icon(Icons.person, size: 60, color: AppColors.grey500),
      );
    }
  }

  Widget _buildFollowButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isFollowActionLoading ? null : _toggleFollow,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isFollowing ? Colors.white : AppColors.black,
          foregroundColor: _isFollowing ? AppColors.black : Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          side: BorderSide(
            color: _isFollowing ? AppColors.grey300 : AppColors.black,
            width: _isFollowing ? 1 : 0,
          ),
        ),
        child: _isFollowActionLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(_isFollowing ? 'Following' : 'Follow'),
      ),
    );
  }

  Widget _buildStats() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem(
          label: 'Followers',
          value: (_socialStats?['followers_count'] as int?)?.toString() ?? '0',
          onTap: () => _navigateToFollowersList(isFollowers: true),
        ),
        Container(
          width: 1,
          height: 40,
          color: AppColors.grey200,
        ),
        _buildStatItem(
          label: 'Following',
          value: (_socialStats?['following_count'] as int?)?.toString() ?? '0',
          onTap: () => _navigateToFollowersList(isFollowers: false),
        ),
        Container(
          width: 1,
          height: 40,
          color: AppColors.grey200,
        ),
        _buildStatItem(
          label: 'Reviews',
          value: (_userProfile!['review_count'] as int?)?.toString() ?? '0',
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    final content = Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.grey600,
              ),
        ),
      ],
    );

    if (onTap != null) {
      return InkWell(
        onTap: () {
          HapticHelper.lightImpact();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: content,
        ),
      );
    }

    return content;
  }

  Widget _buildBioSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bio',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          _userProfile!['bio'] ?? 'No bio available',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildInterestsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Interests',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: (_userProfile!['interests'] as List<dynamic>? ?? []).map((interest) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.grey300),
              ),
              child: Text(
                interest,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _navigateToFollowersList({required bool isFollowers}) {
    Navigator.pushNamed(
      context,
      '/followers-list',
      arguments: {
        'userId': widget.userId,
        'isFollowers': isFollowers,
      },
    );
  }
}

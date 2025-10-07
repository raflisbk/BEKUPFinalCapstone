import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/user_model.dart';
import '../../core/models/social_model.dart';
import '../../core/providers/auth_provider.dart';
import '../../services/user_service.dart';
import '../../services/social_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/haptic_helper.dart';
import '../../core/widgets/skeleton_loader.dart';

/// Screen showing followers or following list for a user
class FollowersListScreen extends StatefulWidget {
  final String userId;
  final bool isFollowers;

  const FollowersListScreen({
    super.key,
    required this.userId,
    required this.isFollowers,
  });

  @override
  State<FollowersListScreen> createState() => _FollowersListScreenState();
}

class _FollowersListScreenState extends State<FollowersListScreen> {
  final UserService _userService = UserService();
  final SocialService _socialService = SocialService();

  List<UserModel> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);

    try {
      // Get social connection
      final connection = await _socialService.getSocialConnection(widget.userId);

      if (connection == null) {
        setState(() {
          _users = [];
          _isLoading = false;
        });
        return;
      }

      // Get list of user IDs
      final userIds = widget.isFollowers ? connection.followers : connection.following;

      if (userIds.isEmpty) {
        setState(() {
          _users = [];
          _isLoading = false;
        });
        return;
      }

      // Fetch user details
      final users = await _userService.getUsersByIds(userIds);

      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading users: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isFollowers ? 'Followers' : 'Following'),
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
      body: _isLoading ? _buildLoadingState() : _buildContent(),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      itemCount: 10,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            SkeletonLoader.circle(size: 56),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonLoader.line(width: 150, height: 16),
                  const SizedBox(height: 8),
                  SkeletonLoader.line(width: 200, height: 14),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_users.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.isFollowers ? Icons.people_outline : Icons.person_add_outlined,
                size: 80,
                color: AppColors.grey300,
              ),
              const SizedBox(height: 24),
              Text(
                widget.isFollowers ? 'No Followers Yet' : 'Not Following Anyone',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.isFollowers
                    ? 'When people follow this user, they\'ll appear here'
                    : 'Start exploring and follow travelers',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.grey500,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _users.length,
      itemBuilder: (context, index) {
        return _buildUserItem(_users[index]);
      },
    );
  }

  Widget _buildUserItem(UserModel user) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUserId = authProvider.user?.uid;
    final isOwnProfile = currentUserId == user.uid;

    return InkWell(
      onTap: () {
        HapticHelper.lightImpact();
        Navigator.pushNamed(
          context,
          '/user-profile',
          arguments: {'userId': user.uid},
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar
            _buildAvatar(user),
            const SizedBox(width: 12),
            // User info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName ?? 'Unknown User',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (user.email.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.grey600,
                          ),
                    ),
                  ],
                ],
              ),
            ),
            // Follow button (only if not own profile)
            if (!isOwnProfile && currentUserId != null)
              _buildFollowButton(user, currentUserId),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(UserModel user) {
    if (user.photoUrl != null && user.photoUrl!.startsWith('avatar:')) {
      // Emoji avatar
      final emoji = user.photoUrl!.replaceFirst('avatar:', '');
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.grey100,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.grey300, width: 2),
        ),
        child: Center(
          child: Text(
            emoji,
            style: const TextStyle(fontSize: 28),
          ),
        ),
      );
    } else if (user.photoUrl != null) {
      // Photo avatar
      return CircleAvatar(
        radius: 28,
        backgroundImage: NetworkImage(user.photoUrl!),
        backgroundColor: AppColors.grey100,
      );
    } else {
      // Default avatar
      return CircleAvatar(
        radius: 28,
        backgroundColor: AppColors.grey200,
        child: const Icon(Icons.person, size: 28, color: AppColors.grey500),
      );
    }
  }

  Widget _buildFollowButton(UserModel user, String currentUserId) {
    return FutureBuilder<bool>(
      future: _socialService.isFollowing(currentUserId, user.uid),
      builder: (context, snapshot) {
        final isFollowing = snapshot.data ?? false;

        return OutlinedButton(
          onPressed: () async {
            await HapticHelper.buttonTap();

            final authProvider = Provider.of<AuthProvider>(context, listen: false);
            final currentUser = authProvider.user;

            if (currentUser == null) return;

            bool success;
            if (isFollowing) {
              success = await _socialService.unfollowUser(
                currentUserId: currentUserId,
                targetUserId: user.uid,
              );
            } else {
              success = await _socialService.followUser(
                currentUserId: currentUserId,
                targetUserId: user.uid,
                currentUserName: currentUser.displayName ?? 'Unknown',
                currentUserPhotoUrl: currentUser.photoURL,
              );
            }

            if (success) {
              await HapticHelper.success();
              setState(() {}); // Refresh to update button state
            } else {
              await HapticHelper.error();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to update follow status')),
                );
              }
            }
          },
          style: OutlinedButton.styleFrom(
            backgroundColor: isFollowing ? Colors.white : AppColors.black,
            foregroundColor: isFollowing ? AppColors.black : Colors.white,
            side: BorderSide(
              color: isFollowing ? AppColors.grey300 : AppColors.black,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: Text(
            isFollowing ? 'Following' : 'Follow',
            style: const TextStyle(fontSize: 12),
          ),
        );
      },
    );
  }
}

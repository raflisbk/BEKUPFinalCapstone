import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/models/social_model.dart';
import '../../core/providers/auth_provider.dart';
import '../../services/social_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../core/utils/haptic_helper.dart';

/// Activity feed screen showing activities from followed users
class ActivityFeedScreen extends StatefulWidget {
  const ActivityFeedScreen({super.key});

  @override
  State<ActivityFeedScreen> createState() => _ActivityFeedScreenState();
}

class _ActivityFeedScreenState extends State<ActivityFeedScreen> {
  final SocialService _socialService = SocialService();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUserId = authProvider.user?.uid;

    if (currentUserId == null) {
      return const Scaffold(
        body: Center(child: Text('Please login to view activity feed')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Feed'),
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
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _socialService.getActivityFeedStream(currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState();
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: AppColors.grey400),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading activities',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.grey500,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final activities = snapshot.data ?? [];

          if (activities.isEmpty) {
            return _buildEmptyState(currentUserId);
          }

          // Convert Map to ActivityItem-like objects for display
          final activityItems = activities.map((data) {
            return {
              'id': data['id'] ?? '',
              'userId': data['user_id'] ?? '',
              'userName': data['user_name'] ?? 'Unknown',
              'userPhotoUrl': data['user_photo_url'],
              'type': _parseActivityType(data['type'] ?? ''),
              'action': data['action'] ?? '',
              'targetId': data['target_id'],
              'targetName': data['target_name'],
              'targetImageUrl': data['target_image_url'],
              'createdAt': DateTime.tryParse(data['created_at']?.toString() ?? '') ?? DateTime.now(),
            };
          }).toList();

          return RefreshIndicator(
            onRefresh: () async {
              await HapticHelper.lightImpact();
              setState(() {});
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: activityItems.length,
              itemBuilder: (context, index) {
                return _buildActivityItem(activityItems[index], currentUserId);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: 8,
      itemBuilder: (context, index) => SkeletonLoader.activityItem(),
    );
  }

  Widget _buildEmptyState(String currentUserId) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.notifications_none,
              size: 80,
              color: AppColors.grey300,
            ),
            const SizedBox(height: 24),
            Text(
              'No Activity Yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Follow travelers to see their activities here',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.grey500,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                HapticHelper.buttonTap();
                Navigator.pushNamed(context, '/explore');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text('Explore Travelers'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> activity, String currentUserId) {
    return InkWell(
      onTap: () {
        HapticHelper.lightImpact();
        _handleActivityTap(activity);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User avatar
            _buildAvatar(activity),
            const SizedBox(width: 12),
            // Activity content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Activity text
                  RichText(
                    text: TextSpan(
                      style: Theme.of(context).textTheme.bodyMedium,
                      children: [
                        TextSpan(
                          text: activity['userName'] ?? 'Unknown',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: ' ${activity['action'] ?? ''}',
                          style: const TextStyle(color: AppColors.grey700),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Timestamp
                  Text(
                    _formatTimestamp(activity['createdAt'] as DateTime),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.grey500,
                        ),
                  ),
                ],
              ),
            ),
            // Activity icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getActivityColor(activity['type'] as ActivityType).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getActivityIcon(activity['type'] as ActivityType),
                size: 20,
                color: _getActivityColor(activity['type'] as ActivityType),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(Map<String, dynamic> activity) {
    final userPhotoUrl = activity['userPhotoUrl'] as String?;
    if (userPhotoUrl != null && userPhotoUrl.startsWith('avatar:')) {
      // Emoji avatar
      final emoji = userPhotoUrl.replaceFirst('avatar:', '');
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.grey100,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.grey300, width: 2),
        ),
        child: Center(
          child: Text(
            emoji,
            style: const TextStyle(fontSize: 24),
          ),
        ),
      );
    } else if (userPhotoUrl != null) {
      // Photo avatar
      return CircleAvatar(
        radius: 24,
        backgroundImage: NetworkImage(userPhotoUrl),
        backgroundColor: AppColors.grey100,
      );
    } else {
      // Default avatar
      return const CircleAvatar(
        radius: 24,
        backgroundColor: AppColors.grey200,
        child: Icon(Icons.person, color: AppColors.grey500),
      );
    }
  }

  ActivityType _parseActivityType(String typeStr) {
    try {
      return ActivityType.values.firstWhere(
        (e) => e.toString().split('.').last == typeStr,
        orElse: () => ActivityType.like,
      );
    } catch (e) {
      return ActivityType.like;
    }
  }

  IconData _getActivityIcon(ActivityType type) {
    switch (type) {
      case ActivityType.follow:
        return Icons.person_add;
      case ActivityType.like:
        return Icons.favorite;
      case ActivityType.comment:
        return Icons.comment;
      case ActivityType.review:
        return Icons.star;
      case ActivityType.trip:
        return Icons.flight_takeoff;
      case ActivityType.photo:
        return Icons.photo;
    }
  }

  Color _getActivityColor(ActivityType type) {
    switch (type) {
      case ActivityType.follow:
        return Colors.blue;
      case ActivityType.like:
        return Colors.red;
      case ActivityType.comment:
        return Colors.green;
      case ActivityType.review:
        return Colors.orange;
      case ActivityType.trip:
        return Colors.purple;
      case ActivityType.photo:
        return Colors.teal;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(timestamp);
    }
  }

  void _handleActivityTap(Map<String, dynamic> activity) {
    final activityType = activity['type'] as ActivityType;
    final userId = activity['userId'] as String?;
    final targetId = activity['targetId'] as String?;

    // Navigate based on activity type
    switch (activityType) {
      case ActivityType.follow:
        // Navigate to user profile
        if (userId != null && userId.isNotEmpty) {
          Navigator.pushNamed(
            context,
            '/user-profile',
            arguments: {'userId': userId},
          );
        }
        break;
      case ActivityType.photo:
        // Navigate to photo detail
        if (targetId != null) {
          Navigator.pushNamed(
            context,
            '/photo-detail',
            arguments: {'photoId': targetId},
          );
        }
        break;
      case ActivityType.review:
        // Navigate to destination/review
        if (targetId != null) {
          Navigator.pushNamed(
            context,
            '/destination-detail',
            arguments: {'destinationId': targetId},
          );
        }
        break;
      case ActivityType.trip:
        // Navigate to trip detail
        if (targetId != null) {
          Navigator.pushNamed(
            context,
            '/trip-detail',
            arguments: {'tripId': targetId},
          );
        }
        break;
      default:
        break;
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/models/social_model.dart';
import '../core/utils/logger.dart';
import 'user_safety_service.dart';

/// Service for managing social features (follow, activity feed)
class SocialService {
  static const String _tag = 'SocialService';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserSafetyService _safetyService = UserSafetyService();

  CollectionReference get _socialCollection => _firestore.collection('social_connections');
  CollectionReference get _activityCollection => _firestore.collection('activities');

  /// Follow a user
  Future<bool> followUser({
    required String currentUserId,
    required String targetUserId,
    required String currentUserName,
    String? currentUserPhotoUrl,
  }) async {
    try {
      AppLogger.debug(_tag, 'Following user', {
        'currentUserId': currentUserId,
        'targetUserId': targetUserId,
      });

      // Safety Check: Verify neither user has blocked the other
      final isBlocked = await _safetyService.isUserBlocked(
        userId: currentUserId,
        blockedUserId: targetUserId,
      );

      if (isBlocked) {
        AppLogger.warning(_tag, 'Cannot follow: User is blocked', {
          'currentUserId': currentUserId,
          'targetUserId': targetUserId,
        });
        return false;
      }

      final isBlockedBy = await _safetyService.isUserBlocked(
        userId: targetUserId,
        blockedUserId: currentUserId,
      );

      if (isBlockedBy) {
        AppLogger.warning(_tag, 'Cannot follow: Blocked by target user', {
          'currentUserId': currentUserId,
          'targetUserId': targetUserId,
        });
        return false;
      }

      // Update current user's following
      await _socialCollection.doc(currentUserId).set({
        'following': FieldValue.arrayUnion([targetUserId]),
        'followingCount': FieldValue.increment(1),
      }, SetOptions(merge: true));

      // Update target user's followers
      await _socialCollection.doc(targetUserId).set({
        'followers': FieldValue.arrayUnion([currentUserId]),
        'followersCount': FieldValue.increment(1),
      }, SetOptions(merge: true));

      // Create activity
      await _createActivity(
        userId: currentUserId,
        userName: currentUserName,
        userPhotoUrl: currentUserPhotoUrl,
        type: ActivityType.follow,
        action: 'started following you',
        targetId: targetUserId,
      );

      AppLogger.info(_tag, 'User followed successfully');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to follow user', e, stackTrace);
      return false;
    }
  }

  /// Unfollow a user
  Future<bool> unfollowUser({
    required String currentUserId,
    required String targetUserId,
  }) async {
    try {
      AppLogger.debug(_tag, 'Unfollowing user', {
        'currentUserId': currentUserId,
        'targetUserId': targetUserId,
      });

      // Update current user's following
      await _socialCollection.doc(currentUserId).update({
        'following': FieldValue.arrayRemove([targetUserId]),
        'followingCount': FieldValue.increment(-1),
      });

      // Update target user's followers
      await _socialCollection.doc(targetUserId).update({
        'followers': FieldValue.arrayRemove([currentUserId]),
        'followersCount': FieldValue.increment(-1),
      });

      AppLogger.info(_tag, 'User unfollowed successfully');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to unfollow user', e, stackTrace);
      return false;
    }
  }

  /// Get social connection for user
  Future<SocialConnection?> getSocialConnection(String userId) async {
    try {
      final doc = await _socialCollection.doc(userId).get();

      if (!doc.exists) {
        // Create initial connection
        await _socialCollection.doc(userId).set({
          'following': [],
          'followers': [],
          'followingCount': 0,
          'followersCount': 0,
        });

        final newDoc = await _socialCollection.doc(userId).get();
        return SocialConnection.fromFirestore(newDoc);
      }

      return SocialConnection.fromFirestore(doc);
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get social connection', e, stackTrace);
      return null;
    }
  }

  /// Get social connection stream
  Stream<SocialConnection?> getSocialConnectionStream(String userId) {
    return _socialCollection.doc(userId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return SocialConnection.fromFirestore(doc);
    });
  }

  /// Create activity
  Future<void> _createActivity({
    required String userId,
    required String userName,
    String? userPhotoUrl,
    required ActivityType type,
    required String action,
    String? targetId,
    String? targetName,
    String? targetImageUrl,
  }) async {
    try {
      final activity = ActivityItem(
        id: '',
        userId: userId,
        userName: userName,
        userPhotoUrl: userPhotoUrl,
        type: type,
        action: action,
        targetId: targetId,
        targetName: targetName,
        targetImageUrl: targetImageUrl,
        createdAt: DateTime.now(),
      );

      await _activityCollection.add(activity.toFirestore());
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to create activity', e, stackTrace);
    }
  }

  /// Get activity feed for user (from people they follow)
  Stream<List<ActivityItem>> getActivityFeedStream(String userId) {
    return _activityCollection
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .asyncMap((snapshot) async {
      // Get user's following list
      final connection = await getSocialConnection(userId);
      final following = connection?.following ?? [];

      // Safety Check: Get blocked users list
      final blockedUsers = await _safetyService.getBlockedUsers(userId);

      // Filter activities from people user follows (plus own activities)
      // AND filter out activities from blocked users
      final activities = snapshot.docs
          .map((doc) => ActivityItem.fromFirestore(doc))
          .where((activity) {
            // Skip if activity is from a blocked user
            if (blockedUsers.contains(activity.userId)) {
              return false;
            }
            
            // Include activities from people user follows, own activities,
            // or activities targeting the user
            return following.contains(activity.userId) ||
                activity.userId == userId ||
                activity.targetId == userId;
          })
          .toList();

      AppLogger.debug(_tag, 'Activity feed filtered', {
        'totalActivities': snapshot.docs.length,
        'filteredActivities': activities.length,
        'blockedCount': blockedUsers.length,
      });

      return activities;
    });
  }

  /// Get user's own activities
  Stream<List<ActivityItem>> getUserActivitiesStream(String userId) {
    return _activityCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(30)
        .snapshots()
        .asyncMap((snapshot) async {
      // Safety Check: Get blocked users list to filter activities
      final blockedUsers = await _safetyService.getBlockedUsers(userId);
      
      // Filter out activities targeting blocked users
      final activities = snapshot.docs
          .map((doc) => ActivityItem.fromFirestore(doc))
          .where((activity) {
            // Hide activities that involve blocked users
            if (activity.targetId != null && 
                blockedUsers.contains(activity.targetId)) {
              return false;
            }
            return true;
          })
          .toList();

      AppLogger.debug(_tag, 'User activities filtered', {
        'totalActivities': snapshot.docs.length,
        'visibleActivities': activities.length,
      });

      return activities;
    });
  }

  /// Check if user is following another user
  Future<bool> isFollowing(String currentUserId, String targetUserId) async {
    try {
      final connection = await getSocialConnection(currentUserId);
      return connection?.isFollowing(targetUserId) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Get filtered followers list (excluding blocked users)
  Future<List<String>> getVisibleFollowers(String userId) async {
    try {
      final connection = await getSocialConnection(userId);
      if (connection == null) return [];

      // Get blocked users
      final blockedUsers = await _safetyService.getBlockedUsers(userId);

      // Filter out blocked users from followers list
      final visibleFollowers = connection.followers
          .where((followerId) => !blockedUsers.contains(followerId))
          .toList();

      AppLogger.debug(_tag, 'Visible followers filtered', {
        'totalFollowers': connection.followers.length,
        'visibleFollowers': visibleFollowers.length,
        'blockedCount': blockedUsers.length,
      });

      return visibleFollowers;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get visible followers', e, stackTrace);
      return [];
    }
  }

  /// Get filtered following list (excluding blocked users)
  Future<List<String>> getVisibleFollowing(String userId) async {
    try {
      final connection = await getSocialConnection(userId);
      if (connection == null) return [];

      // Get blocked users
      final blockedUsers = await _safetyService.getBlockedUsers(userId);

      // Filter out blocked users from following list
      final visibleFollowing = connection.following
          .where((followingId) => !blockedUsers.contains(followingId))
          .toList();

      AppLogger.debug(_tag, 'Visible following filtered', {
        'totalFollowing': connection.following.length,
        'visibleFollowing': visibleFollowing.length,
        'blockedCount': blockedUsers.length,
      });

      return visibleFollowing;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get visible following', e, stackTrace);
      return [];
    }
  }

  /// Remove blocked users from following when they are blocked
  Future<void> cleanupBlockedConnections(
    String userId,
    String blockedUserId,
  ) async {
    try {
      AppLogger.debug(_tag, 'Cleaning up blocked connections', {
        'userId': userId,
        'blockedUserId': blockedUserId,
      });

      // Unfollow if currently following
      final connection = await getSocialConnection(userId);
      if (connection != null && connection.isFollowing(blockedUserId)) {
        await unfollowUser(
          currentUserId: userId,
          targetUserId: blockedUserId,
        );
      }

      // Remove from followers if they're following
      final blockedConnection = await getSocialConnection(blockedUserId);
      if (blockedConnection != null && blockedConnection.isFollowing(userId)) {
        await unfollowUser(
          currentUserId: blockedUserId,
          targetUserId: userId,
        );
      }

      AppLogger.info(_tag, 'Blocked connections cleaned up successfully');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to cleanup blocked connections', e, stackTrace);
    }
  }
}

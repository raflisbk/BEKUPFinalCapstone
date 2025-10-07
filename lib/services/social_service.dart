import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/models/social_model.dart';
import '../core/utils/logger.dart';

/// Service for managing social features (follow, activity feed)
class SocialService {
  static const String _tag = 'SocialService';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

      // Filter activities from people user follows (plus own activities)
      final activities = snapshot.docs
          .map((doc) => ActivityItem.fromFirestore(doc))
          .where((activity) =>
              following.contains(activity.userId) ||
              activity.userId == userId ||
              activity.targetId == userId // Activities targeting the user
          )
          .toList();

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
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ActivityItem.fromFirestore(doc))
          .toList();
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
}

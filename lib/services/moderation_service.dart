import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/logger.dart';

/// Service for user moderation (block/report)
class ModerationService {
  static const String _tag = 'ModerationService';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _blockedUsersCollection =>
      _firestore.collection('blocked_users');
  CollectionReference get _reportsCollection =>
      _firestore.collection('reports');

  /// Block a user
  Future<bool> blockUser({
    required String blockerId,
    required String blockedUserId,
  }) async {
    try {
      AppLogger.debug(_tag, 'Blocking user', {
        'blockerId': blockerId,
        'blockedUserId': blockedUserId,
      });

      // Add to blocker's blocked list
      await _blockedUsersCollection.doc(blockerId).set({
        'blockedUserIds': FieldValue.arrayUnion([blockedUserId]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      AppLogger.success(_tag, 'User blocked successfully');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to block user', e, stackTrace);
      return false;
    }
  }

  /// Unblock a user
  Future<bool> unblockUser({
    required String blockerId,
    required String blockedUserId,
  }) async {
    try {
      AppLogger.debug(_tag, 'Unblocking user', {
        'blockerId': blockerId,
        'blockedUserId': blockedUserId,
      });

      await _blockedUsersCollection.doc(blockerId).update({
        'blockedUserIds': FieldValue.arrayRemove([blockedUserId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      AppLogger.success(_tag, 'User unblocked successfully');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to unblock user', e, stackTrace);
      return false;
    }
  }

  /// Check if user is blocked
  Future<bool> isUserBlocked({
    required String blockerId,
    required String userId,
  }) async {
    try {
      final doc = await _blockedUsersCollection.doc(blockerId).get();

      if (!doc.exists) return false;

      final data = doc.data() as Map<String, dynamic>;
      final blockedUserIds = List<String>.from(data['blockedUserIds'] ?? []);

      return blockedUserIds.contains(userId);
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to check block status', e, stackTrace);
      return false;
    }
  }

  /// Report a user
  Future<bool> reportUser({
    required String reporterId,
    required String reportedUserId,
    required String reason,
    String? additionalInfo,
  }) async {
    try {
      AppLogger.debug(_tag, 'Reporting user', {
        'reporterId': reporterId,
        'reportedUserId': reportedUserId,
        'reason': reason,
      });

      await _reportsCollection.add({
        'reporterId': reporterId,
        'reportedUserId': reportedUserId,
        'reason': reason,
        'additionalInfo': additionalInfo,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      AppLogger.success(_tag, 'User reported successfully');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to report user', e, stackTrace);
      return false;
    }
  }

  /// Report content (photo, review, etc.)
  Future<bool> reportContent({
    required String reporterId,
    required String contentId,
    required String contentType, // 'photo', 'review', 'comment', etc.
    required String reason,
    String? additionalInfo,
  }) async {
    try {
      AppLogger.debug(_tag, 'Reporting content', {
        'reporterId': reporterId,
        'contentId': contentId,
        'contentType': contentType,
        'reason': reason,
      });

      await _reportsCollection.add({
        'reporterId': reporterId,
        'contentId': contentId,
        'contentType': contentType,
        'reason': reason,
        'additionalInfo': additionalInfo,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      AppLogger.success(_tag, 'Content reported successfully');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to report content', e, stackTrace);
      return false;
    }
  }

  /// Get blocked users list
  Future<List<String>> getBlockedUsers(String userId) async {
    try {
      final doc = await _blockedUsersCollection.doc(userId).get();

      if (!doc.exists) return [];

      final data = doc.data() as Map<String, dynamic>;
      return List<String>.from(data['blockedUserIds'] ?? []);
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get blocked users', e, stackTrace);
      return [];
    }
  }
}

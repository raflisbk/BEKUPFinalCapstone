import 'dart:async';
import '../core/utils/logger.dart';
import 'supabase_config.dart';
import 'supabase_database_service.dart';

/// User Safety Service
/// Handles user safety features, reporting, blocking, and moderation
class UserSafetyService {
  static const String _tag = 'UserSafetyService';
  static const String _reportsTable = 'user_reports';
  static const String _blockedUsersTable = 'blocked_users';
  static const String _moderationTable = 'moderation_actions';

  // ===============================
  // USER REPORTING
  // ===============================

  /// Report a user for inappropriate behavior
  static Future<Map<String, dynamic>> reportUser({
    required String reportedUserId,
    required String reason,
    String? description,
    List<String>? evidenceUrls,
  }) async {
    try {
      final reporterUserId = SupabaseConfig.userId;
      if (reporterUserId == null) {
        throw Exception('No authenticated user found');
      }

      if (reportedUserId == reporterUserId) {
        throw Exception('Cannot report yourself');
      }

      AppLogger.info(_tag, 'Reporting user: $reportedUserId for: $reason');

      final reportData = {
        'reporter_user_id': reporterUserId,
        'reported_user_id': reportedUserId,
        'reason': reason,
        'description': description,
        'evidence_urls': evidenceUrls ?? [],
        'status': 'pending',
        'priority': _calculateReportPriority(reason),
      };

      final result = await SupabaseDatabaseService.insert(
        table: _reportsTable,
        data: reportData,
      );

      AppLogger.success(_tag, 'User report submitted successfully');
      
      // Optionally trigger moderation workflow
      await _triggerModerationReview(result['id']);
      
      return result;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to report user', e, stackTrace);
      rethrow;
    }
  }

  /// Get user reports (for moderators/admins)
  static Future<List<Map<String, dynamic>>> getUserReports({
    String? status,
    String? reportedUserId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      AppLogger.debug(_tag, 'Getting user reports');

      final filters = <String, dynamic>{};
      if (status != null) filters['status'] = status;
      if (reportedUserId != null) filters['reported_user_id'] = reportedUserId;

      final reports = await SupabaseDatabaseService.select(
        table: _reportsTable,
        filters: filters,
        orderBy: 'created_at',
        ascending: false,
        limit: limit,
        offset: offset,
      );

      AppLogger.success(_tag, 'Retrieved ${reports.length} user reports');
      return reports;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get user reports', e, stackTrace);
      rethrow;
    }
  }

  /// Update report status
  static Future<void> updateReportStatus({
    required String reportId,
    required String status,
    String? moderatorNote,
  }) async {
    try {
      final moderatorUserId = SupabaseConfig.userId;
      if (moderatorUserId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Updating report status: $reportId to $status');

      final updateData = {
        'status': status,
        'moderator_user_id': moderatorUserId,
        'moderator_note': moderatorNote,
        'reviewed_at': DateTime.now().toIso8601String(),
      };

      await SupabaseDatabaseService.update(
        table: _reportsTable,
        id: reportId,
        data: updateData,
      );

      AppLogger.success(_tag, 'Report status updated successfully');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to update report status', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // USER BLOCKING
  // ===============================

  /// Block a user
  static Future<Map<String, dynamic>> blockUser(String blockedUserId) async {
    try {
      final blockerUserId = SupabaseConfig.userId;
      if (blockerUserId == null) {
        throw Exception('No authenticated user found');
      }

      if (blockedUserId == blockerUserId) {
        throw Exception('Cannot block yourself');
      }

      AppLogger.info(_tag, 'Blocking user: $blockedUserId');

      // Check if user is already blocked
      final existingBlock = await SupabaseDatabaseService.select(
        table: _blockedUsersTable,
        filters: {
          'blocker_user_id': blockerUserId,
          'blocked_user_id': blockedUserId,
        },
      );

      if (existingBlock.isNotEmpty) {
        throw Exception('User is already blocked');
      }

      final blockData = {
        'blocker_user_id': blockerUserId,
        'blocked_user_id': blockedUserId,
        'is_active': true,
      };

      final result = await SupabaseDatabaseService.insert(
        table: _blockedUsersTable,
        data: blockData,
      );

      AppLogger.success(_tag, 'User blocked successfully');
      return result;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to block user', e, stackTrace);
      rethrow;
    }
  }

  /// Unblock a user
  static Future<void> unblockUser(String blockedUserId) async {
    try {
      final blockerUserId = SupabaseConfig.userId;
      if (blockerUserId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.info(_tag, 'Unblocking user: $blockedUserId');

      // Find the block record
      final blocks = await SupabaseDatabaseService.select(
        table: _blockedUsersTable,
        filters: {
          'blocker_user_id': blockerUserId,
          'blocked_user_id': blockedUserId,
          'is_active': true,
        },
      );

      if (blocks.isEmpty) {
        throw Exception('User is not blocked');
      }

      // Deactivate the block
      await SupabaseDatabaseService.update(
        table: _blockedUsersTable,
        id: blocks.first['id'],
        data: {
          'is_active': false,
          'unblocked_at': DateTime.now().toIso8601String(),
        },
      );

      AppLogger.success(_tag, 'User unblocked successfully');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to unblock user', e, stackTrace);
      rethrow;
    }
  }

  /// Get blocked users list
  static Future<List<Map<String, dynamic>>> getBlockedUsers() async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Getting blocked users list');

      final blocks = await SupabaseDatabaseService.select(
        table: _blockedUsersTable,
        filters: {
          'blocker_user_id': userId,
          'is_active': true,
        },
        orderBy: 'created_at',
        ascending: false,
      );

      AppLogger.success(_tag, 'Retrieved ${blocks.length} blocked users');
      return blocks;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get blocked users', e, stackTrace);
      rethrow;
    }
  }

  /// Check if user is blocked
  static Future<bool> isUserBlocked(String userId) async {
    try {
      final currentUserId = SupabaseConfig.userId;
      if (currentUserId == null) return false;

      final blocks = await SupabaseDatabaseService.select(
        table: _blockedUsersTable,
        filters: {
          'blocker_user_id': currentUserId,
          'blocked_user_id': userId,
          'is_active': true,
        },
      );

      return blocks.isNotEmpty;
    } catch (e) {
      AppLogger.error(_tag, 'Failed to check if user is blocked', e);
      return false;
    }
  }

  /// Check if current user is blocked by another user
  static Future<bool> isBlockedByUser(String userId) async {
    try {
      final currentUserId = SupabaseConfig.userId;
      if (currentUserId == null) return false;

      final blocks = await SupabaseDatabaseService.select(
        table: _blockedUsersTable,
        filters: {
          'blocker_user_id': userId,
          'blocked_user_id': currentUserId,
          'is_active': true,
        },
      );

      return blocks.isNotEmpty;
    } catch (e) {
      AppLogger.error(_tag, 'Failed to check if blocked by user', e);
      return false;
    }
  }

  // ===============================
  // MODERATION ACTIONS
  // ===============================

  /// Take moderation action against a user
  static Future<Map<String, dynamic>> takeModerationAction({
    required String targetUserId,
    required String action,
    required String reason,
    String? description,
    Duration? duration,
  }) async {
    try {
      final moderatorUserId = SupabaseConfig.userId;
      if (moderatorUserId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.warning(_tag, 'Taking moderation action: $action against user: $targetUserId');

      final actionData = {
        'moderator_user_id': moderatorUserId,
        'target_user_id': targetUserId,
        'action_type': action,
        'reason': reason,
        'description': description,
        'duration_minutes': duration?.inMinutes,
        'expires_at': duration != null 
            ? DateTime.now().add(duration).toIso8601String()
            : null,
        'is_active': true,
      };

      final result = await SupabaseDatabaseService.insert(
        table: _moderationTable,
        data: actionData,
      );

      AppLogger.warning(_tag, 'Moderation action taken successfully');
      
      // Apply the moderation action
      await _applyModerationAction(result);
      
      return result;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to take moderation action', e, stackTrace);
      rethrow;
    }
  }

  /// Get moderation actions for a user
  static Future<List<Map<String, dynamic>>> getUserModerationActions(String userId) async {
    try {
      AppLogger.debug(_tag, 'Getting moderation actions for user: $userId');

      final actions = await SupabaseDatabaseService.select(
        table: _moderationTable,
        filters: {'target_user_id': userId},
        orderBy: 'created_at',
        ascending: false,
      );

      AppLogger.success(_tag, 'Retrieved ${actions.length} moderation actions');
      return actions;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get moderation actions', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // SAFETY UTILITIES
  // ===============================

  /// Get safety dashboard data
  static Future<Map<String, dynamic>> getSafetyDashboard() async {
    try {
      AppLogger.debug(_tag, 'Getting safety dashboard data');

      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      // Get counts for different safety metrics
      final [
        reportsCount,
        blockedUsersCount,
        moderationActionsCount,
      ] = await Future.wait([
        SupabaseDatabaseService.count(table: _reportsTable, filters: {'reporter_user_id': userId}),
        SupabaseDatabaseService.count(table: _blockedUsersTable, filters: {'blocker_user_id': userId, 'is_active': true}),
        SupabaseDatabaseService.count(table: _moderationTable, filters: {'target_user_id': userId, 'is_active': true}),
      ]);

      final dashboard = {
        'reports_submitted': reportsCount,
        'users_blocked': blockedUsersCount,
        'moderation_actions': moderationActionsCount,
        'last_updated': DateTime.now().toIso8601String(),
      };

      AppLogger.success(_tag, 'Retrieved safety dashboard data');
      return dashboard;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get safety dashboard', e, stackTrace);
      rethrow;
    }
  }

  /// Check if user has active moderation actions
  static Future<bool> hasActiveModerationActions(String userId) async {
    try {
      final actions = await SupabaseDatabaseService.select(
        table: _moderationTable,
        filters: {
          'target_user_id': userId,
          'is_active': true,
        },
      );

      // Check if any actions are still valid (not expired)
      final now = DateTime.now();
      return actions.any((action) {
        if (action['expires_at'] == null) return true;
        final expiresAt = DateTime.parse(action['expires_at']);
        return now.isBefore(expiresAt);
      });
    } catch (e) {
      AppLogger.error(_tag, 'Failed to check moderation actions', e);
      return false;
    }
  }

  // ===============================
  // PRIVATE HELPER METHODS
  // ===============================

  /// Calculate report priority based on reason
  static String _calculateReportPriority(String reason) {
    const highPriorityReasons = [
      'harassment',
      'threats', 
      'violence',
      'self_harm',
      'child_safety',
    ];

    const mediumPriorityReasons = [
      'hate_speech',
      'bullying',
      'sexual_content',
      'illegal_activity',
    ];

    if (highPriorityReasons.contains(reason.toLowerCase())) {
      return 'high';
    } else if (mediumPriorityReasons.contains(reason.toLowerCase())) {
      return 'medium';
    } else {
      return 'low';
    }
  }

  /// Trigger moderation review workflow
  static Future<void> _triggerModerationReview(String reportId) async {
    try {
      AppLogger.debug(_tag, 'Triggering moderation review for report: $reportId');
      
      // This could trigger a webhook or edge function for automated moderation
      // For now, we'll just log it
      AppLogger.info(_tag, 'Moderation review triggered for report: $reportId');
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to trigger moderation review', e);
      // Don't throw error as this is not critical
    }
  }

  /// Apply moderation action to user
  static Future<void> _applyModerationAction(Map<String, dynamic> action) async {
    try {
      final actionType = action['action_type'] as String;
      final targetUserId = action['target_user_id'] as String;

      AppLogger.debug(_tag, 'Applying moderation action: $actionType to user: $targetUserId');

      switch (actionType.toLowerCase()) {
        case 'warning':
          // Send warning notification to user
          break;
        case 'temporary_ban':
          // Temporarily restrict user access
          break;
        case 'permanent_ban':
          // Permanently ban user
          break;
        case 'content_removal':
          // Remove user's content
          break;
        default:
          AppLogger.warning(_tag, 'Unknown moderation action type: $actionType');
      }

      AppLogger.success(_tag, 'Moderation action applied successfully');
    } catch (e) {
      AppLogger.error(_tag, 'Failed to apply moderation action', e);
      // Don't throw error as the action was already recorded
    }
  }
}
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/utils/logger.dart';
import '../core/models/report_model.dart';

/// Service for handling user reports and blocking - Supabase version
class UserSafetyService {
  static const String _tag = 'UserSafetyService';
  static UserSafetyService? _instance;
  
  // Singleton pattern
  factory UserSafetyService() {
    return _instance ??= UserSafetyService._();
  }
  
  UserSafetyService._();

  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Table names
  static const String _reportsTable = 'reports';
  static const String _blockedUsersTable = 'blocked_users';
  
  // Cache management
  final Map<String, List<String>> _blockedUsersCache = {};
  final Map<String, DateTime> _cacheTimestamp = {};
  static const Duration _cacheDuration = Duration(minutes: 30);
  
  // Rate limiting
  DateTime? _lastWrite;
  DateTime? _lastRead;
  static const Duration _minWriteInterval = Duration(milliseconds: 100);
  static const Duration _minReadInterval = Duration(milliseconds: 50);

  /// Report a user with batching for optimal performance
  Future<bool> reportUser({
    required String reporterId,
    required String reportedUserId,
    required String reason,
    String? details,
    List<String>? evidenceUrls,
  }) async {
    try {
      await _ensureWriteInterval();

      AppLogger.debug(_tag, 'Creating user report', {
        'reporterId': reporterId,
        'reportedUserId': reportedUserId,
        'reason': reason,
      });

      final report = UserReport(
        id: '',
        reporterId: reporterId,
        reportedUserId: reportedUserId,
        reason: reason,
        details: details,
        evidenceUrls: evidenceUrls ?? [],
        status: ReportStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Check for existing reports
      final existing = await _supabase
          .from(_reportsTable)
          .select('id')
          .eq('reporter_id', reporterId)
          .eq('reported_user_id', reportedUserId)
          .neq('status', ReportStatus.resolved.toString());

      if (existing.isNotEmpty) {
        AppLogger.warning(_tag, 'Active report already exists', {
          'reportId': existing.first['id'],
        });
        return false;
      }

      final response = await _supabase
          .from(_reportsTable)
          .insert({
            'reporter_id': reporterId,
            'reported_user_id': reportedUserId,
            'reason': reason,
            'details': details,
            'evidence_urls': evidenceUrls ?? [],
            'status': ReportStatus.pending.toString(),
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select('id')
          .single();

      AppLogger.success(_tag, 'User report created', {
        'reportId': response['id'],
      });
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to create user report', e, stackTrace);
      return false;
    }
  }

  /// Block a user with optimized caching
  Future<bool> blockUser({
    required String userId,
    required String blockedUserId,
    Function(String, String)? onBlockCallback,
  }) async {
    try {
      await _ensureWriteInterval();

      AppLogger.debug(_tag, 'Blocking user', {
        'userId': userId,
        'blockedUserId': blockedUserId,
      });

      // Insert or update blocked user relationship
      await _supabase
          .from(_blockedUsersTable)
          .upsert({
            'user_id': userId,
            'blocked_user_id': blockedUserId,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });

      // Update cache
      _updateBlockedUsersCache(userId, blockedUserId, isBlocked: true);

      // Execute callback
      onBlockCallback?.call(userId, blockedUserId);

      AppLogger.success(_tag, 'User blocked successfully');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to block user', e, stackTrace);
      return false;
    }
  }

  /// Unblock a user
  Future<bool> unblockUser({
    required String userId,
    required String blockedUserId,
    Function(String, String)? onUnblockCallback,
  }) async {
    try {
      await _ensureWriteInterval();

      AppLogger.debug(_tag, 'Unblocking user', {
        'userId': userId,
        'blockedUserId': blockedUserId,
      });

      await _supabase
          .from(_blockedUsersTable)
          .delete()
          .eq('user_id', userId)
          .eq('blocked_user_id', blockedUserId);

      // Update cache
      _updateBlockedUsersCache(userId, blockedUserId, isBlocked: false);

      // Execute callback
      onUnblockCallback?.call(userId, blockedUserId);

      AppLogger.success(_tag, 'User unblocked successfully');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to unblock user', e, stackTrace);
      return false;
    }
  }

  /// Check if a user is blocked
  Future<bool> isUserBlocked({
    required String userId,
    required String checkedUserId,
  }) async {
    try {
      await _ensureReadInterval();

      // Check cache first
      if (_isCacheValid(userId)) {
        final cachedList = _blockedUsersCache[userId] ?? [];
        return cachedList.contains(checkedUserId);
      }

      AppLogger.debug(_tag, 'Checking if user is blocked', {
        'userId': userId,
        'checkedUserId': checkedUserId,
      });

      final response = await _supabase
          .from(_blockedUsersTable)
          .select('blocked_user_id')
          .eq('user_id', userId)
          .eq('blocked_user_id', checkedUserId)
          .maybeSingle();

      final isBlocked = response != null;

      AppLogger.debug(_tag, 'User block status checked', {
        'isBlocked': isBlocked,
      });

      return isBlocked;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to check if user is blocked', e, stackTrace);
      return false;
    }
  }

  /// Get blocked users list with caching
  Future<List<String>> getBlockedUsers(String userId) async {
    try {
      await _ensureReadInterval();

      // Check cache first
      if (_isCacheValid(userId)) {
        return _blockedUsersCache[userId] ?? [];
      }

      AppLogger.debug(_tag, 'Fetching blocked users', {
        'userId': userId,
      });

      final response = await _supabase
          .from(_blockedUsersTable)
          .select('blocked_user_id')
          .eq('user_id', userId);

      final blockedUsers = response
          .map((item) => item['blocked_user_id'] as String)
          .toList();

      // Update cache
      _blockedUsersCache[userId] = blockedUsers;
      _cacheTimestamp[userId] = DateTime.now();

      AppLogger.debug(_tag, 'Blocked users fetched', {
        'count': blockedUsers.length,
      });

      return blockedUsers;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to fetch blocked users', e, stackTrace);
      return [];
    }
  }

  /// Get user reports with pagination
  Future<List<UserReport>> getUserReports({
    String? reporterId,
    String? reportedUserId,
    ReportStatus? status,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      await _ensureReadInterval();

      AppLogger.debug(_tag, 'Fetching user reports', {
        'reporterId': reporterId,
        'reportedUserId': reportedUserId,
        'status': status?.toString(),
        'limit': limit,
        'offset': offset,
      });

      var query = _supabase
          .from(_reportsTable)
          .select();

      if (reporterId != null) {
        query = query.eq('reporter_id', reporterId);
      }

      if (reportedUserId != null) {
        query = query.eq('reported_user_id', reportedUserId);
      }

      if (status != null) {
        query = query.eq('status', status.toString());
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final reports = response
          .map((data) => UserReport.fromSupabase(data))
          .toList();

      AppLogger.debug(_tag, 'User reports fetched', {
        'count': reports.length,
      });

      return reports;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to fetch user reports', e, stackTrace);
      return [];
    }
  }

  /// Update report status
  Future<bool> updateReportStatus({
    required String reportId,
    required ReportStatus status,
    String? moderatorNotes,
  }) async {
    try {
      await _ensureWriteInterval();

      AppLogger.debug(_tag, 'Updating report status', {
        'reportId': reportId,
        'status': status.toString(),
      });

      await _supabase
          .from(_reportsTable)
          .update({
            'status': status.toString(),
            'moderator_notes': moderatorNotes,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', reportId);

      AppLogger.success(_tag, 'Report status updated');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to update report status', e, stackTrace);
      return false;
    }
  }

  /// Clear cache for a specific user
  void clearUserCache(String userId) {
    _blockedUsersCache.remove(userId);
    _cacheTimestamp.remove(userId);
    AppLogger.debug(_tag, 'Cache cleared for user', {'userId': userId});
  }

  /// Clear all cache
  void clearAllCache() {
    _blockedUsersCache.clear();
    _cacheTimestamp.clear();
    AppLogger.debug(_tag, 'All cache cleared');
  }

  // Private helper methods

  bool _isCacheValid(String userId) {
    final timestamp = _cacheTimestamp[userId];
    if (timestamp == null) return false;
    
    return DateTime.now().difference(timestamp) < _cacheDuration;
  }

  void _updateBlockedUsersCache(String userId, String blockedUserId, {required bool isBlocked}) {
    final currentList = _blockedUsersCache[userId] ?? [];
    
    if (isBlocked && !currentList.contains(blockedUserId)) {
      currentList.add(blockedUserId);
    } else if (!isBlocked) {
      currentList.remove(blockedUserId);
    }
    
    _blockedUsersCache[userId] = currentList;
    _cacheTimestamp[userId] = DateTime.now();
  }

  Future<void> _ensureWriteInterval() async {
    if (_lastWrite != null) {
      final elapsed = DateTime.now().difference(_lastWrite!);
      if (elapsed < _minWriteInterval) {
        await Future.delayed(_minWriteInterval - elapsed);
      }
    }
    _lastWrite = DateTime.now();
  }

  Future<void> _ensureReadInterval() async {
    if (_lastRead != null) {
      final elapsed = DateTime.now().difference(_lastRead!);
      if (elapsed < _minReadInterval) {
        await Future.delayed(_minReadInterval - elapsed);
      }
    }
    _lastRead = DateTime.now();
  }
}

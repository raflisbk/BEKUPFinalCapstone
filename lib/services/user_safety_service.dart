import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/logger.dart';
import '../core/models/report_model.dart';

/// Service for handling user reports and blocking
class UserSafetyService {
  static const String _tag = 'UserSafetyService';
  static UserSafetyService? _instance;
  
  // Singleton pattern
  factory UserSafetyService() {
    return _instance ??= UserSafetyService._();
  }
  
  UserSafetyService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Collections
  CollectionReference get _reportsCollection => _firestore.collection('reports');
  CollectionReference get _blockedUsersCollection => _firestore.collection('blocked_users');
  
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
      final existing = await _reportsCollection
          .where('reporterId', isEqualTo: reporterId)
          .where('reportedUserId', isEqualTo: reportedUserId)
          .where('status', isNotEqualTo: ReportStatus.resolved.toString())
          .get();

      if (existing.docs.isNotEmpty) {
        AppLogger.warning(_tag, 'Active report already exists', {
          'reportId': existing.docs.first.id,
        });
        return false;
      }

      final docRef = await _reportsCollection.add(report.toJson());

      AppLogger.success(_tag, 'User report created', {
        'reportId': docRef.id,
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

      final doc = _blockedUsersCollection.doc(userId);
      await doc.set({
        'blockedUsers': FieldValue.arrayUnion([blockedUserId]),
        'updatedAt': Timestamp.now(),
      }, SetOptions(merge: true));

      // Update cache
      _blockedUsersCache[userId] = [...(_blockedUsersCache[userId] ?? []), blockedUserId];
      _cacheTimestamp[userId] = DateTime.now();

      // Call cleanup callback if provided (for social connections, etc.)
      if (onBlockCallback != null) {
        try {
          onBlockCallback(userId, blockedUserId);
        } catch (e, stackTrace) {
          AppLogger.error(_tag, 'Block callback failed', e, stackTrace);
          // Don't fail the block operation if callback fails
        }
      }

      AppLogger.success(_tag, 'User blocked successfully');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to block user', e, stackTrace);
      return false;
    }
  }

  /// Unblock a user with cache update
  Future<bool> unblockUser({
    required String userId,
    required String blockedUserId,
  }) async {
    try {
      await _ensureWriteInterval();

      AppLogger.debug(_tag, 'Unblocking user', {
        'userId': userId,
        'blockedUserId': blockedUserId,
      });

      final doc = _blockedUsersCollection.doc(userId);
      await doc.update({
        'blockedUsers': FieldValue.arrayRemove([blockedUserId]),
        'updatedAt': Timestamp.now(),
      });

      // Update cache
      if (_blockedUsersCache.containsKey(userId)) {
        _blockedUsersCache[userId]?.remove(blockedUserId);
        _cacheTimestamp[userId] = DateTime.now();
      }

      AppLogger.success(_tag, 'User unblocked successfully');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to unblock user', e, stackTrace);
      return false;
    }
  }

  /// Check if user is blocked with caching
  Future<bool> isUserBlocked({
    required String userId,
    required String blockedUserId,
  }) async {
    try {
      await _ensureReadInterval();

      // Check cache first
      if (_blockedUsersCache.containsKey(userId)) {
        final timestamp = _cacheTimestamp[userId];
        if (timestamp != null && 
            DateTime.now().difference(timestamp) < _cacheDuration) {
          final isBlocked = _blockedUsersCache[userId]?.contains(blockedUserId) ?? false;
          AppLogger.debug(_tag, 'Block status retrieved from cache', {
            'isBlocked': isBlocked,
          });
          return isBlocked;
        }
      }

      final doc = await _blockedUsersCollection.doc(userId).get();
      if (!doc.exists) {
        _blockedUsersCache[userId] = [];
        _cacheTimestamp[userId] = DateTime.now();
        return false;
      }

      final blockedUsers = List<String>.from(doc.get('blockedUsers') ?? []);
      
      // Update cache
      _blockedUsersCache[userId] = blockedUsers;
      _cacheTimestamp[userId] = DateTime.now();

      AppLogger.debug(_tag, 'Block status retrieved from Firestore', {
        'isBlocked': blockedUsers.contains(blockedUserId),
      });
      return blockedUsers.contains(blockedUserId);
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to check block status', e, stackTrace);
      return false;
    }
  }

  /// Get blocked users list with caching
  Future<List<String>> getBlockedUsers(String userId) async {
    try {
      await _ensureReadInterval();

      // Check cache first
      if (_blockedUsersCache.containsKey(userId)) {
        final timestamp = _cacheTimestamp[userId];
        if (timestamp != null && 
            DateTime.now().difference(timestamp) < _cacheDuration) {
          AppLogger.debug(_tag, 'Blocked users retrieved from cache');
          return _blockedUsersCache[userId] ?? [];
        }
      }

      final doc = await _blockedUsersCollection.doc(userId).get();
      if (!doc.exists) {
        _blockedUsersCache[userId] = [];
        _cacheTimestamp[userId] = DateTime.now();
        return [];
      }

      final blockedUsers = List<String>.from(doc.get('blockedUsers') ?? []);
      
      // Update cache
      _blockedUsersCache[userId] = blockedUsers;
      _cacheTimestamp[userId] = DateTime.now();

      AppLogger.debug(_tag, 'Blocked users retrieved from Firestore', {
        'count': blockedUsers.length,
      });
      return blockedUsers;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get blocked users', e, stackTrace);
      return [];
    }
  }

  /// Get user's reports with pagination
  Future<List<UserReport>> getUserReports(String userId, {
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      await _ensureReadInterval();

      var query = _reportsCollection
          .where('reporterId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();
      
      final reports = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return UserReport.fromJson({...data, 'id': doc.id});
      }).toList();

      AppLogger.debug(_tag, 'User reports retrieved', {
        'count': reports.length,
      });
      return reports;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get user reports', e, stackTrace);
      return [];
    }
  }

  // Ensure write interval for rate limiting
  Future<void> _ensureWriteInterval() async {
    if (_lastWrite != null) {
      final timeSinceLastWrite = DateTime.now().difference(_lastWrite!);
      if (timeSinceLastWrite < _minWriteInterval) {
        await Future.delayed(_minWriteInterval - timeSinceLastWrite);
      }
    }
    _lastWrite = DateTime.now();
  }

  // Ensure read interval for rate limiting
  Future<void> _ensureReadInterval() async {
    if (_lastRead != null) {
      final timeSinceLastRead = DateTime.now().difference(_lastRead!);
      if (timeSinceLastRead < _minReadInterval) {
        await Future.delayed(_minReadInterval - timeSinceLastRead);
      }
    }
    _lastRead = DateTime.now();
  }

  // Clear cache
  void clearCache() {
    _blockedUsersCache.clear();
    _cacheTimestamp.clear();
    AppLogger.debug(_tag, 'Cache cleared');
  }
}

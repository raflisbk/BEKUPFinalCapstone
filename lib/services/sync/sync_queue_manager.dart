import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/logger.dart';
import 'dart:convert';

/// Service for managing offline sync queue - Supabase version
class SyncQueueManager {
  static const String _tag = 'SyncQueueManager';
  static SyncQueueManager? _instance;

  factory SyncQueueManager() {
    return _instance ??= SyncQueueManager._();
  }

  SyncQueueManager._();

  final SupabaseClient _supabase = Supabase.instance.client;
  bool _initialized = false;

  /// Initialize the sync queue manager
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      // Test connection and ensure tables exist
      await _supabase.from(_syncQueueTable).select('id').limit(1);
      _initialized = true;
    } catch (e) {
      // Tables may not exist yet, that's okay
      _initialized = true;
    }
  }

  // Table names
  static const String _syncQueueTable = 'sync_queue';
  static const String _conflictResolutionTable = 'sync_conflicts';

  // Sync operation types
  static const String operationCreate = 'CREATE';
  static const String operationUpdate = 'UPDATE';
  static const String operationDelete = 'DELETE';

  /// Add operation to sync queue
  Future<bool> addToQueue({
    required String operation,
    required String tableName,
    required String recordId,
    required Map<String, dynamic> data,
    required String userId,
    int priority = 1,
  }) async {
    try {
      AppLogger.debug(_tag, 'Adding operation to sync queue', {
        'operation': operation,
        'tableName': tableName,
        'recordId': recordId,
        'priority': priority,
      });

      await _supabase
          .from(_syncQueueTable)
          .insert({
            'operation': operation,
            'table_name': tableName,
            'record_id': recordId,
            'data': data,
            'user_id': userId,
            'priority': priority,
            'status': 'pending',
            'retry_count': 0,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });

      AppLogger.success(_tag, 'Operation added to sync queue');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to add operation to sync queue', e, stackTrace);
      return false;
    }
  }

  /// Process sync queue
  Future<bool> processSyncQueue({String? userId, int batchSize = 10}) async {
    try {
      AppLogger.debug(_tag, 'Processing sync queue', {
        'userId': userId,
        'batchSize': batchSize,
      });

      var query = _supabase
          .from(_syncQueueTable)
          .select()
          .eq('status', 'pending')
          .order('priority', ascending: false)
          .order('created_at', ascending: true)
          .limit(batchSize);

      if (userId != null) {
        query = query.eq('user_id', userId);
      }

      final pendingOperations = await query;

      if (pendingOperations.isEmpty) {
        AppLogger.debug(_tag, 'No pending operations in sync queue');
        return true;
      }

      int successCount = 0;
      int failureCount = 0;

      for (final operation in pendingOperations) {
        final success = await _processOperation(operation);
        if (success) {
          successCount++;
        } else {
          failureCount++;
        }
      }

      AppLogger.success(_tag, 'Sync queue processed', {
        'successful': successCount,
        'failed': failureCount,
      });

      return failureCount == 0;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to process sync queue', e, stackTrace);
      return false;
    }
  }

  /// Process individual operation
  Future<bool> _processOperation(Map<String, dynamic> operation) async {
    try {
      final operationType = operation['operation'] as String;
      final tableName = operation['table_name'] as String;
      final recordId = operation['record_id'] as String;
      final data = operation['data'] as Map<String, dynamic>;
      final queueId = operation['id'] as String;

      AppLogger.debug(_tag, 'Processing operation', {
        'type': operationType,
        'table': tableName,
        'recordId': recordId,
      });

      bool success = false;

      switch (operationType) {
        case operationCreate:
          success = await _processCreateOperation(tableName, data);
          break;
        case operationUpdate:
          success = await _processUpdateOperation(tableName, recordId, data);
          break;
        case operationDelete:
          success = await _processDeleteOperation(tableName, recordId);
          break;
        default:
          AppLogger.warning(_tag, 'Unknown operation type', {'type': operationType});
          success = false;
      }

      if (success) {
        // Mark as completed
        await _supabase
            .from(_syncQueueTable)
            .update({
              'status': 'completed',
              'completed_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', queueId);
      } else {
        // Increment retry count
        final retryCount = (operation['retry_count'] as int? ?? 0) + 1;
        const maxRetries = 3;

        if (retryCount >= maxRetries) {
          await _supabase
              .from(_syncQueueTable)
              .update({
                'status': 'failed',
                'retry_count': retryCount,
                'error_message': 'Max retries exceeded',
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('id', queueId);
        } else {
          await _supabase
              .from(_syncQueueTable)
              .update({
                'retry_count': retryCount,
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('id', queueId);
        }
      }

      return success;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to process operation', e, stackTrace);
      return false;
    }
  }

  /// Process CREATE operation
  Future<bool> _processCreateOperation(String tableName, Map<String, dynamic> data) async {
    try {
      await _supabase
          .from(tableName)
          .insert(data);

      return true;
    } catch (e) {
      AppLogger.error(_tag, 'Failed to process CREATE operation', e);
      return false;
    }
  }

  /// Process UPDATE operation
  Future<bool> _processUpdateOperation(String tableName, String recordId, Map<String, dynamic> data) async {
    try {
      await _supabase
          .from(tableName)
          .update(data)
          .eq('id', recordId);

      return true;
    } catch (e) {
      AppLogger.error(_tag, 'Failed to process UPDATE operation', e);
      return false;
    }
  }

  /// Process DELETE operation
  Future<bool> _processDeleteOperation(String tableName, String recordId) async {
    try {
      await _supabase
          .from(tableName)
          .delete()
          .eq('id', recordId);

      return true;
    } catch (e) {
      AppLogger.error(_tag, 'Failed to process DELETE operation', e);
      return false;
    }
  }

  /// Get sync queue status
  Future<Map<String, int>> getSyncQueueStatus({String? userId}) async {
    try {
      var query = _supabase
          .from(_syncQueueTable)
          .select('status', const FetchOptions(count: CountOption.exact));

      if (userId != null) {
        query = query.eq('user_id', userId);
      }

      final results = await query;

      final status = <String, int>{
        'pending': 0,
        'completed': 0,
        'failed': 0,
      };

      for (final result in results) {
        final statusValue = result['status'] as String;
        status[statusValue] = (status[statusValue] ?? 0) + 1;
      }

      return status;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get sync queue status', e, stackTrace);
      return {'pending': 0, 'completed': 0, 'failed': 0};
    }
  }

  /// Clear completed operations from queue
  Future<bool> clearCompletedOperations({String? userId, int olderThanDays = 7}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: olderThanDays));

      var query = _supabase
          .from(_syncQueueTable)
          .delete()
          .eq('status', 'completed')
          .lt('completed_at', cutoffDate.toIso8601String());

      if (userId != null) {
        query = query.eq('user_id', userId);
      }

      await query;

      AppLogger.success(_tag, 'Completed operations cleared from queue');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to clear completed operations', e, stackTrace);
      return false;
    }
  }

  /// Retry failed operations
  Future<bool> retryFailedOperations({String? userId}) async {
    try {
      var query = _supabase
          .from(_syncQueueTable)
          .update({
            'status': 'pending',
            'retry_count': 0,
            'error_message': null,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('status', 'failed');

      if (userId != null) {
        query = query.eq('user_id', userId);
      }

      await query;

      AppLogger.success(_tag, 'Failed operations reset for retry');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to retry failed operations', e, stackTrace);
      return false;
    }
  }

  /// Get pending operations count
  Future<int> getPendingOperationsCount({String? userId}) async {
    try {
      var query = _supabase
          .from(_syncQueueTable)
          .select('id', const FetchOptions(count: CountOption.exact))
          .eq('status', 'pending');

      if (userId != null) {
        query = query.eq('user_id', userId);
      }

      final result = await query;
      return result.length;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get pending operations count', e, stackTrace);
      return 0;
    }
  }

  /// Check if sync is needed
  Future<bool> isSyncNeeded({String? userId}) async {
    final pendingCount = await getPendingOperationsCount(userId: userId);
    return pendingCount > 0;
  }

  /// Handle sync conflicts
  Future<bool> handleSyncConflict({
    required String tableName,
    required String recordId,
    required Map<String, dynamic> localData,
    required Map<String, dynamic> remoteData,
    required String resolutionType, // 'local', 'remote', 'merge'
  }) async {
    try {
      AppLogger.debug(_tag, 'Handling sync conflict', {
        'table': tableName,
        'recordId': recordId,
        'resolutionType': resolutionType,
      });

      // Log the conflict
      await _supabase
          .from(_conflictResolutionTable)
          .insert({
            'table_name': tableName,
            'record_id': recordId,
            'local_data': localData,
            'remote_data': remoteData,
            'resolution_type': resolutionType,
            'resolved_at': DateTime.now().toIso8601String(),
            'created_at': DateTime.now().toIso8601String(),
          });

      Map<String, dynamic> finalData;

      switch (resolutionType) {
        case 'local':
          finalData = localData;
          break;
        case 'remote':
          finalData = remoteData;
          break;
        case 'merge':
          finalData = {...remoteData, ...localData}; // Simple merge - local wins
          break;
        default:
          finalData = remoteData; // Default to remote
      }

      // Apply the resolution
      await _supabase
          .from(tableName)
          .update(finalData)
          .eq('id', recordId);

      AppLogger.success(_tag, 'Sync conflict resolved');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to handle sync conflict', e, stackTrace);
      return false;
    }
  }

  /// Start periodic sync
  Future<void> startPeriodicSync({
    Duration interval = const Duration(minutes: 5),
    String? userId,
  }) async {
    AppLogger.info(_tag, 'Starting periodic sync', {
      'interval': interval.inMinutes,
      'userId': userId,
    });

    // Note: In a real implementation, you'd want to use a proper background task scheduler
    // This is a simplified version for demonstration
    while (true) {
      try {
        await Future.delayed(interval);
        
        if (await isSyncNeeded(userId: userId)) {
          await processSyncQueue(userId: userId);
        }
      } catch (e) {
        AppLogger.error(_tag, 'Error in periodic sync', e);
      }
    }
  }

  /// Sync all pending operations
  Future<void> syncAll({String? userId}) async {
    await processSyncQueue(userId: userId);
  }

  /// Get sync statistics
  Future<Map<String, dynamic>> getStats({String? userId}) async {
    try {
      final pendingCount = await getPendingOperationsCount(userId: userId);
      final failedCount = await _supabase
          .from(_syncQueueTable)
          .select('id')
          .eq('status', 'failed')
          .then((response) => response.length);

      return {
        'pending': pendingCount,
        'failed': failedCount,
        'total': pendingCount + failedCount,
      };
    } catch (e) {
      return {'pending': 0, 'failed': 0, 'total': 0};
    }
  }

  /// Get pending operations count
  Future<int> getPendingCount({String? userId}) async {
    return await getPendingOperationsCount(userId: userId);
  }

  /// Clear failed operations
  Future<void> clearFailed({String? userId}) async {
    try {
      var query = _supabase
          .from(_syncQueueTable)
          .delete()
          .eq('status', 'failed');

      if (userId != null) {
        query = query.eq('user_id', userId);
      }

      await query;
    } catch (e) {
      AppLogger.error(_tag, 'Failed to clear failed operations', e);
    }
  }

  /// Sync progress stream (placeholder)
  Stream<Map<String, dynamic>> get syncProgress async* {
    while (true) {
      yield await getStats();
      await Future.delayed(const Duration(seconds: 5));
    }
  }
}

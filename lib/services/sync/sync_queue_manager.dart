import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/database/hive_service.dart';
import '../../core/database/models/cached_data.dart';
import '../../core/utils/connectivity_service.dart';
import '../../core/models/trip_model.dart';
import '../../core/models/destination_model.dart';
import '../../core/models/review_model.dart';
import '../../core/models/user_model.dart';
import '../cache/trip_cache_service.dart';
import '../cache/destination_cache_service.dart';
import '../cache/review_cache_service.dart';
import '../cache/profile_cache_service.dart';
import 'conflict_resolver.dart';

/// Manager for sync queue operations
class SyncQueueManager {
  static final SyncQueueManager _instance = SyncQueueManager._internal();
  factory SyncQueueManager() => _instance;
  SyncQueueManager._internal();

  final HiveService _hiveService = HiveService.instance;
  final ConnectivityService _connectivityService = ConnectivityService.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConflictResolver _conflictResolver = ConflictResolver();

  // Cache services
  final TripCacheService _tripCache = TripCacheService();
  final DestinationCacheService _destCache = DestinationCacheService();
  final ReviewCacheService _reviewCache = ReviewCacheService();
  final ProfileCacheService _profileCache = ProfileCacheService();

  bool _isSyncing = false;
  final _syncController = StreamController<SyncProgress>.broadcast();

  /// Stream of sync progress
  Stream<SyncProgress> get syncProgress => _syncController.stream;

  /// Initialize sync queue manager
  Future<void> initialize() async {
    try {
      // Listen to connectivity changes
      _connectivityService.onConnectivityChanged.listen((isOnline) {
        if (isOnline) {
          syncAll();
        }
      });

      print('SyncQueueManager initialized');
    } catch (e) {
      print('Error initializing SyncQueueManager: $e');
    }
  }

  /// Add operation to sync queue
  Future<void> addToQueue(SyncOperation operation) async {
    try {
      final box = _hiveService.syncQueue;
      await box.put(operation.id, operation);
      
      print('Added to sync queue: ${operation.type} ${operation.collection}/${operation.id}');

      // Try to sync immediately if online
      if (_connectivityService.isOnline) {
        syncAll();
      }
    } catch (e) {
      print('Error adding to sync queue: $e');
    }
  }

  /// Sync all pending operations
  Future<void> syncAll() async {
    if (_isSyncing) {
      print('Sync already in progress');
      return;
    }

    if (!_connectivityService.isOnline) {
      print('Cannot sync: offline');
      return;
    }

    _isSyncing = true;
    _syncController.add(SyncProgress(status: SyncStatus.syncing, progress: 0.0));

    try {
      final box = _hiveService.syncQueue;
      final operations = <SyncOperation>[];

      // Get all operations sorted by priority
      for (final key in box.keys) {
        final data = box.get(key);
        if (data is SyncOperation) {
          operations.add(data);
        } else if (data is Map) {
          operations.add(SyncOperation.fromMap(Map<String, dynamic>.from(data)));
        }
      }

      if (operations.isEmpty) {
        _syncController.add(SyncProgress(
          status: SyncStatus.completed,
          progress: 1.0,
          message: 'No operations to sync',
        ));
        return;
      }

      // Sort by priority (higher first)
      operations.sort((a, b) => b.priority.compareTo(a.priority));

      print('Syncing ${operations.length} operations...');

      int completed = 0;
      int failed = 0;

      for (final operation in operations) {
        try {
          // Skip if max retries reached
          if (operation.hasMaxRetries) {
            print('Operation ${operation.id} exceeded max retries, skipping');
            failed++;
            continue;
          }

          final success = await _syncOperation(operation);

          if (success) {
            await box.delete(operation.id);
            completed++;
            print('Synced: ${operation.type} ${operation.collection}/${operation.id}');
          } else {
            // Increment retry count
            operation.incrementRetry('Sync failed');
            await box.put(operation.id, operation);
            failed++;
          }

          // Update progress
          final progress = (completed + failed) / operations.length;
          _syncController.add(SyncProgress(
            status: SyncStatus.syncing,
            progress: progress,
            message: 'Synced $completed/${operations.length}',
            completed: completed,
            failed: failed,
            total: operations.length,
          ));
        } catch (e) {
          print('Error syncing operation ${operation.id}: $e');
          operation.incrementRetry(e.toString());
          await box.put(operation.id, operation);
          failed++;
        }
      }

      _syncController.add(SyncProgress(
        status: SyncStatus.completed,
        progress: 1.0,
        message: 'Sync completed: $completed succeeded, $failed failed',
        completed: completed,
        failed: failed,
        total: operations.length,
      ));

      print('Sync completed: $completed succeeded, $failed failed');
    } catch (e) {
      print('Error during sync: $e');
      _syncController.add(SyncProgress(
        status: SyncStatus.error,
        progress: 0.0,
        message: 'Sync error: $e',
      ));
    } finally {
      _isSyncing = false;
    }
  }

  /// Sync single operation
  Future<bool> _syncOperation(SyncOperation operation) async {
    try {
      switch (operation.collection) {
        case 'trips':
          return await _syncTrip(operation);
        case 'destinations':
          return await _syncDestination(operation);
        case 'reviews':
          return await _syncReview(operation);
        case 'profiles':
          return await _syncProfile(operation);
        default:
          print('Unknown collection: ${operation.collection}');
          return false;
      }
    } catch (e) {
      print('Error syncing operation: $e');
      return false;
    }
  }

  /// Sync trip operation
  Future<bool> _syncTrip(SyncOperation operation) async {
    try {
      final ref = _firestore.collection('trips').doc(operation.id);

      switch (operation.type) {
        case 'create':
        case 'update':
          // Get local data
          final localTrip = await _tripCache.getCachedTrip(operation.id);
          if (localTrip == null) {
            print('Local trip not found: ${operation.id}');
            return false;
          }

          // Check for conflicts
          final remoteDoc = await ref.get();
          if (remoteDoc.exists && operation.type == 'update') {
            final remoteTrip = Trip.fromFirestore(remoteDoc);
            final resolution = _conflictResolver.resolve(
              localData: localTrip.toMap(),
              remoteData: remoteTrip.toMap(),
              strategy: _conflictResolver.getStrategyForEntity('trip'),
            );

            if (resolution.wasConflict) {
              print('Conflict resolved for trip ${operation.id}: ${resolution.reason}');
            }

            final resolvedTrip = Trip.fromMap(resolution.data);
            await ref.set(resolvedTrip.toFirestore());
            await _tripCache.updateCachedTrip(resolvedTrip);
          } else {
            // No conflict, just upload
            await ref.set(localTrip.toFirestore());
          }

          // Mark as synced
          await _tripCache.markTripSynced(operation.id);
          return true;

        case 'delete':
          await ref.delete();
          await _tripCache.deleteCachedTrip(operation.id);
          return true;

        default:
          print('Unknown operation type: ${operation.type}');
          return false;
      }
    } catch (e) {
      print('Error syncing trip: $e');
      return false;
    }
  }

  /// Sync destination operation
  Future<bool> _syncDestination(SyncOperation operation) async {
    try {
      final ref = _firestore.collection('destinations').doc(operation.id);

      switch (operation.type) {
        case 'create':
        case 'update':
          final localDest = await _destCache.getCachedDestination(operation.id);
          if (localDest == null) return false;

          final remoteDoc = await ref.get();
          if (remoteDoc.exists && operation.type == 'update') {
            final remoteDest = Destination.fromFirestore(remoteDoc);
            final resolution = _conflictResolver.resolve(
              localData: localDest.toMap(),
              remoteData: remoteDest.toMap(),
              strategy: _conflictResolver.getStrategyForEntity('destination'),
            );

            final resolvedDest = Destination.fromMap(resolution.data);
            await ref.set(resolvedDest.toFirestore());
            await _destCache.updateCachedDestination(resolvedDest);
          } else {
            await ref.set(localDest.toFirestore());
          }

          await _destCache.markDestinationSynced(operation.id);
          return true;

        case 'delete':
          await ref.delete();
          await _destCache.deleteCachedDestination(operation.id);
          return true;

        default:
          return false;
      }
    } catch (e) {
      print('Error syncing destination: $e');
      return false;
    }
  }

  /// Sync review operation
  Future<bool> _syncReview(SyncOperation operation) async {
    try {
      final ref = _firestore.collection('reviews').doc(operation.id);

      switch (operation.type) {
        case 'create':
        case 'update':
          final localReview = await _reviewCache.getCachedReview(operation.id);
          if (localReview == null) return false;

          final remoteDoc = await ref.get();
          if (remoteDoc.exists && operation.type == 'update') {
            final remoteReview = DestinationReview.fromFirestore(remoteDoc);
            final resolution = _conflictResolver.resolve(
              localData: localReview.toMap(),
              remoteData: remoteReview.toMap(),
              strategy: _conflictResolver.getStrategyForEntity('review'),
            );

            final resolvedReview = DestinationReview.fromMap(resolution.data);
            await ref.set(resolvedReview.toFirestore());
            await _reviewCache.updateCachedReview(resolvedReview);
          } else {
            await ref.set(localReview.toFirestore());
          }

          await _reviewCache.markReviewSynced(operation.id);
          return true;

        case 'delete':
          await ref.delete();
          await _reviewCache.deleteCachedReview(operation.id);
          return true;

        default:
          return false;
      }
    } catch (e) {
      print('Error syncing review: $e');
      return false;
    }
  }

  /// Sync profile operation
  Future<bool> _syncProfile(SyncOperation operation) async {
    try {
      final ref = _firestore.collection('users').doc(operation.id);

      switch (operation.type) {
        case 'create':
        case 'update':
          final localProfile = await _profileCache.getCachedProfile(operation.id);
          if (localProfile == null) return false;

          final remoteDoc = await ref.get();
          if (remoteDoc.exists && operation.type == 'update') {
            final remoteProfile = UserModel.fromFirestore(remoteDoc);
            final resolution = _conflictResolver.resolve(
              localData: localProfile.toJson(),
              remoteData: remoteProfile.toJson(),
              strategy: _conflictResolver.getStrategyForEntity('profile'),
            );

            final resolvedProfile = UserModel.fromMap(resolution.data);
            await ref.set(resolvedProfile.toMap());
            await _profileCache.updateCachedProfile(resolvedProfile);
          } else {
            await ref.set(localProfile.toMap());
          }

          await _profileCache.markProfileSynced(operation.id);
          return true;

        case 'delete':
          await ref.delete();
          await _profileCache.deleteCachedProfile(operation.id);
          return true;

        default:
          return false;
      }
    } catch (e) {
      print('Error syncing profile: $e');
      return false;
    }
  }

  /// Get pending operations count
  int getPendingCount() {
    try {
      return _hiveService.syncQueue.length;
    } catch (e) {
      print('Error getting pending count: $e');
      return 0;
    }
  }

  /// Get sync queue statistics
  Map<String, dynamic> getStats() {
    try {
      final box = _hiveService.syncQueue;
      final operations = <SyncOperation>[];

      for (final key in box.keys) {
        final data = box.get(key);
        if (data is SyncOperation) {
          operations.add(data);
        } else if (data is Map) {
          operations.add(SyncOperation.fromMap(Map<String, dynamic>.from(data)));
        }
      }

      int pending = 0;
      int failed = 0;
      
      for (final op in operations) {
        if (op.hasMaxRetries) {
          failed++;
        } else {
          pending++;
        }
      }

      return {
        'total': operations.length,
        'pending': pending,
        'failed': failed,
        'isSyncing': _isSyncing,
      };
    } catch (e) {
      print('Error getting sync stats: $e');
      return {
        'total': 0,
        'pending': 0,
        'failed': 0,
        'isSyncing': false,
      };
    }
  }

  /// Clear failed operations
  Future<void> clearFailed() async {
    try {
      final box = _hiveService.syncQueue;
      final keys = box.keys.toList();

      for (final key in keys) {
        final data = box.get(key);
        SyncOperation? operation;
        
        if (data is SyncOperation) {
          operation = data;
        } else if (data is Map) {
          operation = SyncOperation.fromMap(Map<String, dynamic>.from(data));
        }

        if (operation != null && operation.hasMaxRetries) {
          await box.delete(key);
        }
      }

      print('Failed operations cleared');
    } catch (e) {
      print('Error clearing failed operations: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _syncController.close();
  }
}

/// Sync progress information
class SyncProgress {
  final SyncStatus status;
  final double progress; // 0.0 to 1.0
  final String? message;
  final int? completed;
  final int? failed;
  final int? total;

  SyncProgress({
    required this.status,
    required this.progress,
    this.message,
    this.completed,
    this.failed,
    this.total,
  });
}

/// Sync status
enum SyncStatus {
  idle,
  syncing,
  completed,
  error,
}

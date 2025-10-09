import 'package:flutter/foundation.dart';
import 'dart:async';
// NOTE: Workmanager removed due to Flutter embedding V2 compatibility issues
// Using Timer-based periodic sync as alternative
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../core/utils/connectivity_service.dart';
import 'sync_queue_manager.dart';
import '../cache/upload_queue_service.dart';

/// Service for managing background sync with periodic timers
/// Alternative to workmanager due to compatibility issues
class BackgroundSyncService {
  static final BackgroundSyncService _instance = BackgroundSyncService._internal();
  factory BackgroundSyncService() => _instance;
  BackgroundSyncService._internal();

  final SyncQueueManager _syncQueue = SyncQueueManager();
  final UploadQueueService _uploadQueue = UploadQueueService();
  final ConnectivityService _connectivity = ConnectivityService.instance;

  // Timer-based sync
  Timer? _periodicSyncTimer;
  static const Duration _syncInterval = Duration(minutes: 15);
  bool _isSyncing = false;

  bool _isInitialized = false;
  FlutterLocalNotificationsPlugin? _notifications;

  /// Initialize background sync service
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('BackgroundSyncService already initialized');
      return;
    }

    try {
      // Initialize notifications
      await _initializeNotifications();

      // Start periodic sync timer
      await _registerPeriodicSync();

      // Listen to connectivity changes
      _connectivity.onConnectivityChanged.listen((isOnline) {
        if (isOnline) {
          // Schedule quick sync when coming online
          scheduleQuickSync();
        }
      });

      _isInitialized = true;
      debugPrint('BackgroundSyncService initialized with periodic timer (${_syncInterval.inMinutes}min intervals)');
    } catch (e) {
      debugPrint('Error initializing BackgroundSyncService: $e');
    }
  }

  /// Initialize local notifications
  Future<void> _initializeNotifications() async {
    try {
      _notifications = FlutterLocalNotificationsPlugin();

      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications?.initialize(initSettings);
      debugPrint('Notifications initialized');
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
    }
  }

  /// Register periodic background sync using Timer
  Future<void> _registerPeriodicSync() async {
    try {
      // Cancel existing timer if any
      _periodicSyncTimer?.cancel();

      // Start new periodic timer
      _periodicSyncTimer = Timer.periodic(_syncInterval, (timer) async {
        await _performBackgroundSync();
      });

      debugPrint('Periodic sync timer started: every ${_syncInterval.inMinutes} minutes');
    } catch (e) {
      debugPrint('Error registering periodic sync: $e');
    }
  }

  /// Perform background sync (called by timer)
  Future<void> _performBackgroundSync() async {
    // Prevent concurrent syncs
    if (_isSyncing) {
      debugPrint('Sync already in progress, skipping');
      return;
    }

    // Check if online
    if (!_connectivity.isOnline) {
      debugPrint('Background sync skipped: offline');
      return;
    }

    _isSyncing = true;

    try {
      debugPrint('Background sync started');

      // Sync queue operations
      await _syncQueue.syncAll();

      // Process upload queue
      await _uploadQueue.processQueue();

      debugPrint('Background sync completed successfully');
    } catch (e) {
      debugPrint('Background sync error: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Schedule quick sync (used when coming online)
  Future<void> scheduleQuickSync() async {
    try {
      // Wait a bit before syncing to avoid immediate sync after network connection
      await Future.delayed(const Duration(seconds: 5));

      if (_connectivity.isOnline && !_isSyncing) {
        debugPrint('Quick sync triggered');
        await _performBackgroundSync();
      }
    } catch (e) {
      debugPrint('Error scheduling quick sync: $e');
    }
  }

  /// Trigger immediate sync in foreground
  Future<void> syncNow({bool showNotification = true}) async {
    try {
      if (!_connectivity.isOnline) {
        debugPrint('Cannot sync: offline');
        if (showNotification) {
          await _showNotification(
            'Sync Failed',
            'No internet connection',
            isError: true,
          );
        }
        return;
      }

      if (showNotification) {
        await _showNotification(
          'Syncing...',
          'Uploading your changes',
        );
      }

      // Get counts before sync
      final syncStats = _syncQueue.getStats();
      final uploadStats = await _uploadQueue.getQueueStats();
      
      final totalItems = (syncStats['pending'] ?? 0) + (uploadStats['pending'] ?? 0);

      if (totalItems == 0) {
        debugPrint('No items to sync');
        if (showNotification) {
          await _showNotification(
            'Already Synced',
            'All changes are up to date',
          );
        }
        return;
      }

      // Perform sync
      await _syncQueue.syncAll();
      await _uploadQueue.processQueue();

      // Get counts after sync
      final finalSyncStats = _syncQueue.getStats();
      final finalUploadStats = await _uploadQueue.getQueueStats();
      
      final remainingItems = (finalSyncStats['pending'] ?? 0) + 
                             (finalUploadStats['pending'] ?? 0);
      final syncedItems = totalItems - remainingItems;

      if (showNotification) {
        if (remainingItems == 0) {
          await _showNotification(
            'Sync Complete',
            'Successfully synced $syncedItems items',
          );
        } else {
          await _showNotification(
            'Sync Partial',
            'Synced $syncedItems of $totalItems items',
            isError: true,
          );
        }
      }

      debugPrint('Foreground sync completed: $syncedItems/$totalItems items');
    } catch (e) {
      debugPrint('Error during sync: $e');
      if (showNotification) {
        await _showNotification(
          'Sync Error',
          'Failed to sync: ${e.toString()}',
          isError: true,
        );
      }
    }
  }

  /// Show local notification
  Future<void> _showNotification(
    String title,
    String body, {
    bool isError = false,
  }) async {
    try {
      if (_notifications == null) return;

      const androidDetails = AndroidNotificationDetails(
        'sync_channel',
        'Sync Notifications',
        channelDescription: 'Notifications for data synchronization',
        importance: Importance.high,
        priority: Priority.high,
      );

      const iosDetails = DarwinNotificationDetails();

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications?.show(
        isError ? 999 : 1000,
        title,
        body,
        details,
      );
    } catch (e) {
      debugPrint('Error showing notification: $e');
    }
  }

  /// Get sync status
  Map<String, dynamic> getSyncStatus() {
    final syncStats = _syncQueue.getStats();
    
    return {
      'isInitialized': _isInitialized,
      'isOnline': _connectivity.isOnline,
      'syncQueue': syncStats,
      'lastCheck': DateTime.now().toIso8601String(),
    };
  }

  /// Enable background sync
  Future<void> enableBackgroundSync() async {
    try {
      await _registerPeriodicSync();
      debugPrint('Background sync enabled');
    } catch (e) {
      debugPrint('Error enabling background sync: $e');
    }
  }

  /// Disable background sync
  Future<void> disableBackgroundSync() async {
    try {
      _periodicSyncTimer?.cancel();
      _periodicSyncTimer = null;
      debugPrint('Background sync disabled');
    } catch (e) {
      debugPrint('Error disabling background sync: $e');
    }
  }

  /// Cancel all background tasks
  Future<void> cancelAllTasks() async {
    try {
      _periodicSyncTimer?.cancel();
      _periodicSyncTimer = null;
      debugPrint('All background tasks cancelled');
    } catch (e) {
      debugPrint('Error cancelling tasks: $e');
    }
  }

  /// Check if background sync is enabled
  Future<bool> isBackgroundSyncEnabled() async {
    return _periodicSyncTimer != null && _periodicSyncTimer!.isActive;
  }

  /// Get pending sync counts
  Future<Map<String, int>> getPendingCounts() async {
    final syncStats = _syncQueue.getStats();
    final uploadStats = await _uploadQueue.getQueueStats();

    return {
      'syncQueue': syncStats['pending'] ?? 0,
      'uploadQueue': uploadStats['pending'] ?? 0,
      'total': (syncStats['pending'] ?? 0) + (uploadStats['pending'] ?? 0),
    };
  }

  /// Listen to sync progress
  Stream<SyncProgress> get syncProgress => _syncQueue.syncProgress;

  /// Dispose resources
  void dispose() {
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = null;
    debugPrint('BackgroundSyncService disposed');
  }
}

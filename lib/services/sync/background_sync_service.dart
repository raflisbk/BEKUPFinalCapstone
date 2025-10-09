import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../core/database/hive_service.dart';
import '../../core/utils/connectivity_service.dart';
import 'sync_queue_manager.dart';
import '../cache/upload_queue_service.dart';

/// Background callback for workmanager (must be top-level function)
@pragma('vm:entry-point')
void backgroundSyncCallback() {
  Workmanager().executeTask((task, inputData) async {
    try {
      debugPrint('Background sync started: $task');

      // Initialize Hive for background task
      await HiveService.instance.initialize();

      // Initialize connectivity
      await ConnectivityService.instance.initialize();

      // Check if online
      if (!ConnectivityService.instance.isOnline) {
        debugPrint('Background sync skipped: offline');
        return Future.value(true);
      }

      // Sync queue operations
      await SyncQueueManager().syncAll();

      // Process upload queue
      await UploadQueueService().processQueue();

      debugPrint('Background sync completed successfully');
      return Future.value(true);
    } catch (e) {
      debugPrint('Background sync error: $e');
      return Future.value(false);
    }
  });
}

/// Service for managing background sync with workmanager
class BackgroundSyncService {
  static final BackgroundSyncService _instance = BackgroundSyncService._internal();
  factory BackgroundSyncService() => _instance;
  BackgroundSyncService._internal();

  final SyncQueueManager _syncQueue = SyncQueueManager();
  final UploadQueueService _uploadQueue = UploadQueueService();
  final ConnectivityService _connectivity = ConnectivityService.instance;

  static const String _syncTaskName = 'background_sync_task';
  static const String _uniqueTaskName = 'relink_background_sync';
  
  // Sync intervals
  static const Duration _periodicSyncInterval = Duration(minutes: 15);

  bool _isInitialized = false;
  FlutterLocalNotificationsPlugin? _notifications;

  /// Initialize background sync service
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('BackgroundSyncService already initialized');
      return;
    }

    try {
      // Initialize workmanager
      await Workmanager().initialize(
        backgroundSyncCallback,
        isInDebugMode: false, // Set to false for production
      );

      // Initialize notifications
      await _initializeNotifications();

      // Register periodic sync task
      await _registerPeriodicSync();

      // Listen to connectivity changes
      _connectivity.onConnectivityChanged.listen((isOnline) {
        if (isOnline) {
          // Schedule quick sync when coming online
          scheduleQuickSync();
        }
      });

      _isInitialized = true;
      debugPrint('BackgroundSyncService initialized');
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

  /// Register periodic background sync
  Future<void> _registerPeriodicSync() async {
    try {
      await Workmanager().registerPeriodicTask(
        _uniqueTaskName,
        _syncTaskName,
        frequency: _periodicSyncInterval,
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: true,
          requiresCharging: false,
        ),
        backoffPolicy: BackoffPolicy.exponential,
        backoffPolicyDelay: const Duration(minutes: 1),
        existingWorkPolicy: ExistingWorkPolicy.keep,
      );

      debugPrint('Periodic sync registered: every ${_periodicSyncInterval.inMinutes} minutes');
    } catch (e) {
      debugPrint('Error registering periodic sync: $e');
    }
  }

  /// Schedule quick sync (used when coming online)
  Future<void> scheduleQuickSync() async {
    try {
      await Workmanager().registerOneOffTask(
        '${_uniqueTaskName}_quick',
        _syncTaskName,
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
        initialDelay: const Duration(seconds: 5),
        existingWorkPolicy: ExistingWorkPolicy.replace,
      );

      debugPrint('Quick sync scheduled');
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
      await Workmanager().cancelByUniqueName(_uniqueTaskName);
      debugPrint('Background sync disabled');
    } catch (e) {
      debugPrint('Error disabling background sync: $e');
    }
  }

  /// Cancel all background tasks
  Future<void> cancelAllTasks() async {
    try {
      await Workmanager().cancelAll();
      debugPrint('All background tasks cancelled');
    } catch (e) {
      debugPrint('Error cancelling tasks: $e');
    }
  }

  /// Check if background sync is enabled
  Future<bool> isBackgroundSyncEnabled() async {
    // Note: Workmanager doesn't provide a way to check if task exists
    // This is a placeholder - you'd need to track this in shared preferences
    return _isInitialized;
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
    // Cleanup if needed
  }
}

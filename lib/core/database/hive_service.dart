import 'package:hive_flutter/hive_flutter.dart';
import '../utils/logger.dart';
import 'models/cached_data.dart';

/// Core Hive database service for offline storage
class HiveService {
  static const String _tag = 'HiveService';

  // Box names
  static const String tripsBox = 'cached_trips';
  static const String destinationsBox = 'cached_destinations';
  static const String reviewsBox = 'cached_reviews';
  static const String profilesBox = 'cached_profiles';
  static const String syncQueueBox = 'sync_queue';
  static const String metadataBox = 'app_metadata';
  static const String uploadQueueBox = 'upload_queue';

  static HiveService? _instance;
  static HiveService get instance => _instance ??= HiveService._();

  HiveService._();

  bool _isInitialized = false;

  /// Initialize Hive database
  Future<void> initialize() async {
    if (_isInitialized) {
      AppLogger.debug(_tag, 'Hive already initialized');
      return;
    }

    try {
      AppLogger.info(_tag, 'Initializing Hive database');

      // Initialize Hive
      await Hive.initFlutter();

      // Register adapters
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(CachedDataAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(SyncOperationAdapter());
      }

      // Open boxes
      await _openBoxes();

      _isInitialized = true;
      AppLogger.success(_tag, 'Hive initialized successfully');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to initialize Hive', e, stackTrace);
      rethrow;
    }
  }

  /// Open all required boxes
  Future<void> _openBoxes() async {
    try {
      await Future.wait([
        Hive.openBox(tripsBox),
        Hive.openBox(destinationsBox),
        Hive.openBox(reviewsBox),
        Hive.openBox(profilesBox),
        Hive.openBox(syncQueueBox),
        Hive.openBox(metadataBox),
        Hive.openBox(uploadQueueBox),
      ]);

      AppLogger.info(_tag, 'All boxes opened successfully');
    } catch (e) {
      AppLogger.error(_tag, 'Failed to open boxes', e);
      rethrow;
    }
  }

  /// Get a box by name
  Box getBox(String boxName) {
    if (!Hive.isBoxOpen(boxName)) {
      throw Exception('Box $boxName is not open');
    }
    return Hive.box(boxName);
  }

  /// Get trips box
  Box get trips => getBox(tripsBox);

  /// Get destinations box
  Box get destinations => getBox(destinationsBox);

  /// Get reviews box
  Box get reviews => getBox(reviewsBox);

  /// Get profiles box
  Box get profiles => getBox(profilesBox);

  /// Get sync queue box
  Box get syncQueue => getBox(syncQueueBox);

  /// Get metadata box
  Box get metadata => getBox(metadataBox);

  /// Get upload queue box
  Box get uploadQueue => getBox(uploadQueueBox);

  /// Clear all cached data (use with caution!)
  Future<void> clearAllCache() async {
    try {
      AppLogger.warning(_tag, 'Clearing all cached data');

      await Future.wait([
        trips.clear(),
        destinations.clear(),
        reviews.clear(),
        profiles.clear(),
        // Note: Don't clear syncQueue - we need pending operations
      ]);

      AppLogger.success(_tag, 'All cache cleared');
    } catch (e) {
      AppLogger.error(_tag, 'Failed to clear cache', e);
      rethrow;
    }
  }

  /// Clear sync queue (use when sync is complete)
  Future<void> clearSyncQueue() async {
    try {
      await syncQueue.clear();
      AppLogger.info(_tag, 'Sync queue cleared');
    } catch (e) {
      AppLogger.error(_tag, 'Failed to clear sync queue', e);
    }
  }

  /// Get cache size in bytes
  Future<int> getCacheSize() async {
    try {
      int totalSize = 0;

      for (final boxName in [
        tripsBox,
        destinationsBox,
        reviewsBox,
        profilesBox,
        syncQueueBox,
        metadataBox
      ]) {
        final box = getBox(boxName);
        // Approximate size calculation
        totalSize += box.length * 1024; // Rough estimate: 1KB per entry
      }

      return totalSize;
    } catch (e) {
      AppLogger.error(_tag, 'Failed to calculate cache size', e);
      return 0;
    }
  }

  /// Get cache statistics
  Map<String, int> getCacheStats() {
    try {
      return {
        'trips': trips.length,
        'destinations': destinations.length,
        'reviews': reviews.length,
        'profiles': profiles.length,
        'syncQueue': syncQueue.length,
        'uploadQueue': uploadQueue.length,
      };
    } catch (e) {
      AppLogger.error(_tag, 'Failed to get cache stats', e);
      return {};
    }
  }

  /// Close all boxes
  Future<void> close() async {
    try {
      await Hive.close();
      _isInitialized = false;
      AppLogger.info(_tag, 'Hive closed');
    } catch (e) {
      AppLogger.error(_tag, 'Failed to close Hive', e);
    }
  }

  /// Delete all data and close (nuclear option)
  Future<void> deleteAllData() async {
    try {
      AppLogger.warning(_tag, 'Deleting all Hive data');
      await Hive.deleteFromDisk();
      _isInitialized = false;
      AppLogger.success(_tag, 'All Hive data deleted');
    } catch (e) {
      AppLogger.error(_tag, 'Failed to delete Hive data', e);
      rethrow;
    }
  }
}

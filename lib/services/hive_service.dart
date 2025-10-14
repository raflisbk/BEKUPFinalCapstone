import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../core/utils/logger.dart';

/// Hive Service
/// Handles local storage operations using Hive database
class HiveService {
  static const String _tag = 'HiveService';
  static bool _isInitialized = false;

  // Box names for different data types
  static const String userBox = 'user_cache';
  static const String tripBox = 'trip_cache';
  static const String destinationBox = 'destination_cache';
  static const String reviewBox = 'review_cache';
  static const String settingsBox = 'settings';
  static const String offlineBox = 'offline_data';
  static const String syncQueueBox = 'sync_queue';
  static const String tempBox = 'temp_data';

  /// Initialize Hive database
  static Future<void> initialize() async {
    try {
      if (_isInitialized) {
        AppLogger.warning(_tag, 'Hive already initialized');
        return;
      }

      AppLogger.info(_tag, 'Initializing Hive database...');

      // Initialize Hive Flutter
      await Hive.initFlutter();

      // Get application documents directory for additional storage if needed
      final appDocDir = await getApplicationDocumentsDirectory();
      AppLogger.debug(_tag, 'App documents directory: ${appDocDir.path}');

      // Register adapters if needed (for custom objects)
      // registerAdapters();

      // Open essential boxes
      await _openBoxes();

      _isInitialized = true;
      AppLogger.success(_tag, 'Hive database initialized successfully');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to initialize Hive database', e, stackTrace);
      rethrow;
    }
  }

  /// Open all essential boxes
  static Future<void> _openBoxes() async {
    try {
      final boxes = [
        userBox,
        tripBox,
        destinationBox,
        reviewBox,
        settingsBox,
        offlineBox,
        syncQueueBox,
        tempBox,
      ];

      for (final boxName in boxes) {
        try {
          await Hive.openBox(boxName);
          AppLogger.debug(_tag, 'Opened box: $boxName');
        } catch (e) {
          AppLogger.error(_tag, 'Failed to open box: $boxName', e);
          // Try to delete corrupted box and recreate
          await _recreateBox(boxName);
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to open Hive boxes', e, stackTrace);
      rethrow;
    }
  }

  /// Recreate corrupted box
  static Future<void> _recreateBox(String boxName) async {
    try {
      AppLogger.warning(_tag, 'Recreating corrupted box: $boxName');
      
      // Delete corrupted box
      await Hive.deleteBoxFromDisk(boxName);
      
      // Recreate box
      await Hive.openBox(boxName);
      
      AppLogger.success(_tag, 'Successfully recreated box: $boxName');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to recreate box: $boxName', e, stackTrace);
    }
  }

  /// Register custom adapters
  static void registerAdapters() {
    // Register your custom type adapters here
    // Example:
    // if (!Hive.isAdapterRegistered(UserAdapter().typeId)) {
    //   Hive.registerAdapter(UserAdapter());
    // }
  }

  /// Get box by name
  static Box getBox(String boxName) {
    if (!_isInitialized) {
      throw Exception('Hive not initialized. Call initialize() first.');
    }

    if (!Hive.isBoxOpen(boxName)) {
      throw Exception('Box $boxName is not open.');
    }

    return Hive.box(boxName);
  }

  /// Check if box exists and is open
  static bool isBoxOpen(String boxName) {
    return Hive.isBoxOpen(boxName);
  }

  // ===============================
  // GENERIC CRUD OPERATIONS
  // ===============================

  /// Store data in box
  static Future<void> put(String boxName, String key, dynamic value) async {
    try {
      final box = getBox(boxName);
      await box.put(key, value);
      AppLogger.debug(_tag, 'Stored data in $boxName: $key');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to store data in $boxName', e, stackTrace);
      rethrow;
    }
  }

  /// Get data from box
  static T? get<T>(String boxName, String key, {T? defaultValue}) {
    try {
      final box = getBox(boxName);
      final value = box.get(key, defaultValue: defaultValue);
      AppLogger.debug(_tag, 'Retrieved data from $boxName: $key');
      return value as T?;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get data from $boxName', e, stackTrace);
      return defaultValue;
    }
  }

  /// Delete data from box
  static Future<void> delete(String boxName, String key) async {
    try {
      final box = getBox(boxName);
      await box.delete(key);
      AppLogger.debug(_tag, 'Deleted data from $boxName: $key');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to delete data from $boxName', e, stackTrace);
      rethrow;
    }
  }

  /// Check if key exists in box
  static bool containsKey(String boxName, String key) {
    try {
      final box = getBox(boxName);
      return box.containsKey(key);
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to check key in $boxName', e, stackTrace);
      return false;
    }
  }

  /// Get all keys from box
  static List<String> getKeys(String boxName) {
    try {
      final box = getBox(boxName);
      return box.keys.cast<String>().toList();
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get keys from $boxName', e, stackTrace);
      return [];
    }
  }

  /// Get all values from box
  static List<T> getValues<T>(String boxName) {
    try {
      final box = getBox(boxName);
      return box.values.cast<T>().toList();
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get values from $boxName', e, stackTrace);
      return [];
    }
  }

  /// Get all entries from box
  static Map<String, T> getAll<T>(String boxName) {
    try {
      final box = getBox(boxName);
      final Map<String, T> result = {};
      
      for (final key in box.keys) {
        result[key.toString()] = box.get(key) as T;
      }
      
      return result;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get all data from $boxName', e, stackTrace);
      return {};
    }
  }

  /// Clear all data from box
  static Future<void> clear(String boxName) async {
    try {
      final box = getBox(boxName);
      await box.clear();
      AppLogger.info(_tag, 'Cleared all data from $boxName');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to clear $boxName', e, stackTrace);
      rethrow;
    }
  }

  /// Get box size (number of entries)
  static int getBoxSize(String boxName) {
    try {
      final box = getBox(boxName);
      return box.length;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get box size for $boxName', e, stackTrace);
      return 0;
    }
  }

  // ===============================
  // BATCH OPERATIONS
  // ===============================

  /// Store multiple key-value pairs
  static Future<void> putAll(String boxName, Map<String, dynamic> entries) async {
    try {
      final box = getBox(boxName);
      await box.putAll(entries);
      AppLogger.debug(_tag, 'Stored ${entries.length} entries in $boxName');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to store batch data in $boxName', e, stackTrace);
      rethrow;
    }
  }

  /// Delete multiple keys
  static Future<void> deleteAll(String boxName, List<String> keys) async {
    try {
      final box = getBox(boxName);
      await box.deleteAll(keys);
      AppLogger.debug(_tag, 'Deleted ${keys.length} entries from $boxName');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to delete batch data from $boxName', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // UTILITY METHODS
  // ===============================

  /// Get storage statistics
  static Map<String, dynamic> getStorageStats() {
    try {
      final stats = <String, dynamic>{
        'isInitialized': _isInitialized,
        'openBoxes': [],
        'totalEntries': 0,
      };

      if (_isInitialized) {
        final openBoxes = <Map<String, dynamic>>[];
        int totalEntries = 0;

        for (final boxName in [userBox, tripBox, destinationBox, reviewBox, settingsBox, offlineBox, syncQueueBox, tempBox]) {
          if (isBoxOpen(boxName)) {
            final box = getBox(boxName);
            final boxInfo = {
              'name': boxName,
              'entries': box.length,
              'keys': box.keys.length,
            };
            openBoxes.add(boxInfo);
            totalEntries += box.length;
          }
        }

        stats['openBoxes'] = openBoxes;
        stats['totalEntries'] = totalEntries;
      }

      return stats;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get storage stats', e, stackTrace);
      return {'error': e.toString()};
    }
  }

  /// Compact box (reduce file size)
  static Future<void> compact(String boxName) async {
    try {
      final box = getBox(boxName);
      await box.compact();
      AppLogger.info(_tag, 'Compacted box: $boxName');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to compact box: $boxName', e, stackTrace);
      rethrow;
    }
  }

  /// Close specific box
  static Future<void> closeBox(String boxName) async {
    try {
      if (isBoxOpen(boxName)) {
        await Hive.box(boxName).close();
        AppLogger.debug(_tag, 'Closed box: $boxName');
      }
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to close box: $boxName', e, stackTrace);
    }
  }

  /// Close all boxes and dispose Hive
  static Future<void> dispose() async {
    try {
      AppLogger.info(_tag, 'Disposing Hive service...');

      // Close all boxes
      await Hive.close();
      
      _isInitialized = false;
      AppLogger.success(_tag, 'Hive service disposed successfully');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to dispose Hive service', e, stackTrace);
    }
  }

  /// Delete box from disk permanently
  static Future<void> deleteBoxFromDisk(String boxName) async {
    try {
      AppLogger.warning(_tag, 'Deleting box from disk: $boxName');
      
      // Close box if open
      if (isBoxOpen(boxName)) {
        await closeBox(boxName);
      }
      
      // Delete from disk
      await Hive.deleteBoxFromDisk(boxName);
      
      AppLogger.success(_tag, 'Box deleted from disk: $boxName');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to delete box from disk: $boxName', e, stackTrace);
      rethrow;
    }
  }

  /// Clear all application data
  static Future<void> clearAllData() async {
    try {
      AppLogger.warning(_tag, 'Clearing all application data...');

      final boxes = [userBox, tripBox, destinationBox, reviewBox, settingsBox, offlineBox, syncQueueBox, tempBox];
      
      for (final boxName in boxes) {
        if (isBoxOpen(boxName)) {
          await clear(boxName);
        }
      }

      AppLogger.success(_tag, 'All application data cleared');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to clear all data', e, stackTrace);
      rethrow;
    }
  }
}
import 'dart:async';
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../core/utils/logger.dart';

/// Cache Service
/// Handles local caching using Hive for improved performance and offline capabilities
class CacheService {
  static const String _tag = 'CacheService';
  static const String _defaultBoxName = 'cache';
  static const String _metadataBoxName = 'cache_metadata';
  
  static Box<String>? _cacheBox;
  static Box<Map<dynamic, dynamic>>? _metadataBox;
  static bool _initialized = false;

  // Cache categories
  static const String categorySearch = 'search';
  static const String categoryDestinations = 'destinations';
  static const String categoryUsers = 'users';
  static const String categoryAccommodations = 'accommodations';
  static const String categoryActivities = 'activities';
  static const String categoryMedia = 'media';
  static const String categoryGeneral = 'general';

  // Default cache durations
  static const Duration defaultDuration = Duration(hours: 1);
  static const Duration shortDuration = Duration(minutes: 15);
  static const Duration mediumDuration = Duration(hours: 6);
  static const Duration longDuration = Duration(days: 1);
  static const Duration weekDuration = Duration(days: 7);

  // ===============================
  // INITIALIZATION
  // ===============================

  /// Initialize cache service
  static Future<void> initialize() async {
    try {
      if (_initialized) return;

      AppLogger.debug(_tag, 'Initializing cache service');

      // Open cache boxes
      _cacheBox = await Hive.openBox<String>(_defaultBoxName);
      _metadataBox = await Hive.openBox<Map<dynamic, dynamic>>(_metadataBoxName);

      _initialized = true;

      // Clean expired cache on startup
      await _cleanExpiredCache();

      AppLogger.success(_tag, 'Cache service initialized successfully');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to initialize cache service', e, stackTrace);
      rethrow;
    }
  }

  /// Ensure cache is initialized
  static Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await initialize();
    }
  }

  // ===============================
  // CACHE OPERATIONS
  // ===============================

  /// Store data in cache
  static Future<void> set(
    String key,
    dynamic data, {
    Duration duration = defaultDuration,
    String category = categoryGeneral,
  }) async {
    try {
      await _ensureInitialized();

      AppLogger.debug(_tag, 'Caching data with key: $key');

      final jsonData = jsonEncode(data);
      final expiry = DateTime.now().add(duration);

      // Store data
      await _cacheBox!.put(key, jsonData);

      // Store metadata
      await _metadataBox!.put(key, {
        'expiry': expiry.toIso8601String(),
        'category': category,
        'size': jsonData.length,
        'created_at': DateTime.now().toIso8601String(),
      });

      AppLogger.debug(_tag, 'Data cached successfully: $key');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to cache data', e, stackTrace);
      // Don't rethrow cache errors to avoid breaking app flow
    }
  }

  /// Get data from cache
  static Future<T?> get<T>(String key) async {
    try {
      await _ensureInitialized();

      AppLogger.debug(_tag, 'Retrieving cached data: $key');

      // Check if key exists
      if (!_cacheBox!.containsKey(key)) {
        AppLogger.debug(_tag, 'Cache miss: $key');
        return null;
      }

      // Check if expired
      final metadata = _metadataBox!.get(key);
      if (metadata != null) {
        final expiryString = metadata['expiry'] as String?;
        if (expiryString != null) {
          final expiry = DateTime.parse(expiryString);
          if (DateTime.now().isAfter(expiry)) {
            AppLogger.debug(_tag, 'Cache expired: $key');
            await remove(key);
            return null;
          }
        }
      }

      // Get and decode data
      final jsonData = _cacheBox!.get(key);
      if (jsonData == null) {
        return null;
      }

      final data = jsonDecode(jsonData);
      AppLogger.debug(_tag, 'Cache hit: $key');
      return data as T;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get cached data: $key', e, stackTrace);
      return null;
    }
  }

  /// Remove data from cache
  static Future<void> remove(String key) async {
    try {
      await _ensureInitialized();

      AppLogger.debug(_tag, 'Removing cached data: $key');

      await _cacheBox!.delete(key);
      await _metadataBox!.delete(key);

      AppLogger.debug(_tag, 'Cached data removed: $key');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to remove cached data: $key', e, stackTrace);
    }
  }

  /// Check if key exists in cache
  static Future<bool> contains(String key) async {
    try {
      await _ensureInitialized();
      
      if (!_cacheBox!.containsKey(key)) {
        return false;
      }

      // Check if expired
      final metadata = _metadataBox!.get(key);
      if (metadata != null) {
        final expiryString = metadata['expiry'] as String?;
        if (expiryString != null) {
          final expiry = DateTime.parse(expiryString);
          if (DateTime.now().isAfter(expiry)) {
            await remove(key);
            return false;
          }
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Clear cache by category
  static Future<void> clearCategory(String category) async {
    try {
      await _ensureInitialized();

      AppLogger.debug(_tag, 'Clearing cache category: $category');

      final keysToRemove = <String>[];

      // Find all keys in category
      for (final key in _metadataBox!.keys) {
        final metadata = _metadataBox!.get(key);
        if (metadata != null && metadata['category'] == category) {
          keysToRemove.add(key as String);
        }
      }

      // Remove all keys in category
      for (final key in keysToRemove) {
        await remove(key);
      }

      AppLogger.success(_tag, 'Cleared ${keysToRemove.length} items from category: $category');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to clear cache category: $category', e, stackTrace);
    }
  }

  /// Clear all cache
  static Future<void> clearAll() async {
    try {
      await _ensureInitialized();

      AppLogger.debug(_tag, 'Clearing all cache');

      await _cacheBox!.clear();
      await _metadataBox!.clear();

      AppLogger.success(_tag, 'All cache cleared');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to clear all cache', e, stackTrace);
    }
  }

  /// Clean expired cache entries
  static Future<void> cleanExpiredCache() async {
    try {
      await _ensureInitialized();
      await _cleanExpiredCache();
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to clean expired cache', e, stackTrace);
    }
  }

  // ===============================
  // CACHE STATISTICS
  // ===============================

  /// Get cache statistics
  static Future<Map<String, dynamic>> getStatistics() async {
    try {
      await _ensureInitialized();

      final stats = <String, dynamic>{
        'total_entries': 0,
        'total_size': 0,
        'categories': <String, int>{},
        'expired_entries': 0,
        'cache_hit_ratio': 0.0,
      };

      var totalSize = 0;
      var expiredCount = 0;
      final categories = <String, int>{};
      final now = DateTime.now();

      for (final key in _metadataBox!.keys) {
        final metadata = _metadataBox!.get(key);
        if (metadata != null) {
          // Check if expired
          final expiryString = metadata['expiry'] as String?;
          if (expiryString != null) {
            final expiry = DateTime.parse(expiryString);
            if (now.isAfter(expiry)) {
              expiredCount++;
              continue;
            }
          }

          // Add to stats
          final size = metadata['size'] as int? ?? 0;
          totalSize += size;

          final category = metadata['category'] as String? ?? categoryGeneral;
          categories[category] = (categories[category] ?? 0) + 1;
        }
      }

      stats['total_entries'] = _cacheBox!.length - expiredCount;
      stats['total_size'] = totalSize;
      stats['categories'] = categories;
      stats['expired_entries'] = expiredCount;

      AppLogger.debug(_tag, 'Cache statistics: $stats');
      return stats;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get cache statistics', e, stackTrace);
      return {};
    }
  }

  /// Get cache size in bytes
  static Future<int> getCacheSize() async {
    try {
      final stats = await getStatistics();
      return stats['total_size'] as int? ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Get number of cache entries
  static Future<int> getCacheEntryCount() async {
    try {
      await _ensureInitialized();
      return _cacheBox!.length;
    } catch (e) {
      return 0;
    }
  }

  // ===============================
  // ADVANCED CACHE OPERATIONS
  // ===============================

  /// Set multiple items in cache
  static Future<void> setMultiple(
    Map<String, dynamic> items, {
    Duration duration = defaultDuration,
    String category = categoryGeneral,
  }) async {
    try {
      await _ensureInitialized();

      AppLogger.debug(_tag, 'Caching multiple items: ${items.length}');

      final expiry = DateTime.now().add(duration);

      // Prepare batch operations
      final cacheUpdates = <String, String>{};
      final metadataUpdates = <String, Map<dynamic, dynamic>>{};

      for (final entry in items.entries) {
        final jsonData = jsonEncode(entry.value);
        cacheUpdates[entry.key] = jsonData;
        metadataUpdates[entry.key] = {
          'expiry': expiry.toIso8601String(),
          'category': category,
          'size': jsonData.length,
          'created_at': DateTime.now().toIso8601String(),
        };
      }

      // Batch update
      await _cacheBox!.putAll(cacheUpdates);
      await _metadataBox!.putAll(metadataUpdates);

      AppLogger.success(_tag, 'Multiple items cached successfully: ${items.length}');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to cache multiple items', e, stackTrace);
    }
  }

  /// Get multiple items from cache
  static Future<Map<String, T?>> getMultiple<T>(List<String> keys) async {
    try {
      await _ensureInitialized();

      AppLogger.debug(_tag, 'Retrieving multiple cached items: ${keys.length}');

      final results = <String, T?>{};

      for (final key in keys) {
        results[key] = await get<T>(key);
      }

      final hitCount = results.values.where((v) => v != null).length;
      AppLogger.debug(_tag, 'Cache hits: $hitCount/${keys.length}');

      return results;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get multiple cached items', e, stackTrace);
      return {};
    }
  }

  /// Update cache expiry
  static Future<void> updateExpiry(String key, Duration newDuration) async {
    try {
      await _ensureInitialized();

      if (!_cacheBox!.containsKey(key)) {
        return;
      }

      final metadata = _metadataBox!.get(key);
      if (metadata != null) {
        final newExpiry = DateTime.now().add(newDuration);
        metadata['expiry'] = newExpiry.toIso8601String();
        await _metadataBox!.put(key, metadata);
      }

      AppLogger.debug(_tag, 'Cache expiry updated: $key');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to update cache expiry: $key', e, stackTrace);
    }
  }

  /// Refresh cache entry
  static Future<void> refresh(
    String key,
    Future<dynamic> Function() dataProvider, {
    Duration duration = defaultDuration,
    String category = categoryGeneral,
  }) async {
    try {
      AppLogger.debug(_tag, 'Refreshing cache entry: $key');

      final newData = await dataProvider();
      await set(key, newData, duration: duration, category: category);

      AppLogger.success(_tag, 'Cache entry refreshed: $key');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to refresh cache entry: $key', e, stackTrace);
    }
  }

  // ===============================
  // CACHE WARMING
  // ===============================

  /// Warm up cache with popular data
  static Future<void> warmUpCache() async {
    try {
      AppLogger.debug(_tag, 'Warming up cache');

      // This would typically preload popular destinations, activities, etc.
      // Implementation depends on app requirements

      AppLogger.success(_tag, 'Cache warmed up successfully');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to warm up cache', e, stackTrace);
    }
  }

  // ===============================
  // PRIVATE HELPER METHODS
  // ===============================

  /// Clean expired cache entries
  static Future<void> _cleanExpiredCache() async {
    try {
      AppLogger.debug(_tag, 'Cleaning expired cache entries');

      final expiredKeys = <String>[];
      final now = DateTime.now();

      // Find expired keys
      for (final key in _metadataBox!.keys) {
        final metadata = _metadataBox!.get(key);
        if (metadata != null) {
          final expiryString = metadata['expiry'] as String?;
          if (expiryString != null) {
            final expiry = DateTime.parse(expiryString);
            if (now.isAfter(expiry)) {
              expiredKeys.add(key as String);
            }
          }
        }
      }

      // Remove expired entries
      for (final key in expiredKeys) {
        await remove(key);
      }

      if (expiredKeys.isNotEmpty) {
        AppLogger.success(_tag, 'Cleaned ${expiredKeys.length} expired cache entries');
      }
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to clean expired cache', e, stackTrace);
    }
  }

  // ===============================
  // CACHE MAINTENANCE
  // ===============================

  /// Perform cache maintenance
  static Future<void> performMaintenance() async {
    try {
      AppLogger.debug(_tag, 'Performing cache maintenance');

      // Clean expired entries
      await _cleanExpiredCache();

      // Compact cache if needed
      await _compactCache();

      AppLogger.success(_tag, 'Cache maintenance completed');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to perform cache maintenance', e, stackTrace);
    }
  }

  /// Compact cache by removing unused space
  static Future<void> _compactCache() async {
    try {
      await _cacheBox!.compact();
      await _metadataBox!.compact();
      AppLogger.debug(_tag, 'Cache compacted successfully');
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to compact cache', e);
    }
  }

  /// Schedule periodic cache maintenance
  static void schedulePeriodicMaintenance() {
    Timer.periodic(const Duration(hours: 6), (timer) {
      performMaintenance();
    });
  }
}
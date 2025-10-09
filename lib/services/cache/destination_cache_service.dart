import '../../core/database/hive_service.dart';
import '../../core/database/models/cached_data.dart';
import '../../core/models/destination_model.dart';
import '../../core/utils/logger.dart';

/// Service for caching destination data offline
class DestinationCacheService {
  static const String _tag = 'DestinationCacheService';
  static final DestinationCacheService _instance = DestinationCacheService._internal();
  factory DestinationCacheService() => _instance;
  DestinationCacheService._internal();

  final HiveService _hiveService = HiveService.instance;

  /// Get cached destination by ID
  Future<Destination?> getCachedDestination(String id) async {
    try {
      final box = _hiveService.destinations;
      final cached = box.get(id) as CachedData?;
      
      if (cached == null) return null;
      
      return Destination.fromMap(cached.data);
    } catch (e) {
      AppLogger.error(_tag, 'Error getting cached destination', e);
      return null;
    }
  }

  /// Get all cached destinations
  Future<List<Destination>> getAllCachedDestinations() async {
    try {
      final box = _hiveService.destinations;
      final destinations = <Destination>[];
      
      for (final key in box.keys) {
        final cached = box.get(key) as CachedData?;
        if (cached != null) {
          try {
            destinations.add(Destination.fromMap(cached.data));
          } catch (e) {
            AppLogger.error(_tag, 'Error parsing cached destination $key', e);
          }
        }
      }
      
      return destinations;
    } catch (e) {
      AppLogger.error(_tag, 'Error getting all cached destinations', e);
      return [];
    }
  }

  /// Cache single destination
  Future<void> cacheDestination(Destination destination) async {
    try {
      final box = _hiveService.destinations;
      final cached = CachedData(
        id: destination.id,
        data: destination.toMap(),
        cachedAt: DateTime.now(),
        isDirty: false,
      );
      
      await box.put(destination.id, cached);
    } catch (e) {
      AppLogger.error(_tag, 'Error caching destination', e);
    }
  }

  /// Cache multiple destinations
  Future<void> cacheDestinations(List<Destination> destinations) async {
    try {
      final box = _hiveService.destinations;
      final now = DateTime.now();
      
      final cachedData = {
        for (var dest in destinations)
          dest.id: CachedData(
            id: dest.id,
            data: dest.toMap(),
            cachedAt: now,
            isDirty: false,
          )
      };
      
      await box.putAll(cachedData);
    } catch (e) {
      AppLogger.error(_tag, 'Error caching destinations', e);
    }
  }

  /// Update cached destination
  Future<void> updateCachedDestination(
    Destination destination, {
    bool markDirty = false,
  }) async {
    try {
      final box = _hiveService.destinations;
      final existing = box.get(destination.id) as CachedData?;
      
      final cached = CachedData(
        id: destination.id,
        data: destination.toMap(),
        cachedAt: existing?.cachedAt ?? DateTime.now(),
        isDirty: markDirty,
        lastSyncedAt: markDirty ? existing?.lastSyncedAt : DateTime.now(),
      );
      
      await box.put(destination.id, cached);
    } catch (e) {
      AppLogger.error(_tag, 'Error updating cached destination', e);
    }
  }

  /// Delete cached destination
  Future<void> deleteCachedDestination(String id) async {
    try {
      final box = _hiveService.destinations;
      await box.delete(id);
    } catch (e) {
      AppLogger.error(_tag, 'Error deleting cached destination', e);
    }
  }

  /// Get dirty destinations (need sync)
  Future<List<Destination>> getDirtyDestinations() async {
    try {
      final box = _hiveService.destinations;
      final destinations = <Destination>[];
      
      for (final key in box.keys) {
        final cached = box.get(key) as CachedData?;
        if (cached != null && cached.isDirty) {
          try {
            destinations.add(Destination.fromMap(cached.data));
          } catch (e) {
            AppLogger.error(_tag, 'Error parsing dirty destination $key', e);
          }
        }
      }
      
      return destinations;
    } catch (e) {
      AppLogger.error(_tag, 'Error getting dirty destinations', e);
      return [];
    }
  }

  /// Mark destination as synced
  Future<void> markDestinationSynced(String id) async {
    try {
      final box = _hiveService.destinations;
      final cached = box.get(id) as CachedData?;
      
      if (cached != null) {
        cached.markSynced();
      }
    } catch (e) {
      AppLogger.error(_tag, 'Error marking destination as synced', e);
    }
  }

  /// Check if destination is cached
  bool isDestinationCached(String id) {
    try {
      final box = _hiveService.destinations;
      return box.containsKey(id);
    } catch (e) {
      AppLogger.error(_tag, 'Error checking if destination is cached', e);
      return false;
    }
  }

  /// Get cache statistics
  Map<String, int> getCacheStats() {
    try {
      final box = _hiveService.destinations;
      int total = box.length;
      int dirty = 0;
      int valid = 0;
      int invalid = 0;
      
      for (final key in box.keys) {
        final cached = box.get(key) as CachedData?;
        if (cached != null) {
          if (cached.isDirty) dirty++;
          if (cached.isValid()) {
            valid++;
          } else {
            invalid++;
          }
        }
      }
      
      return {
        'total': total,
        'dirty': dirty,
        'valid': valid,
        'invalid': invalid,
      };
    } catch (e) {
      AppLogger.error(_tag, 'Error getting cache stats', e);
      return {
        'total': 0,
        'dirty': 0,
        'valid': 0,
        'invalid': 0,
      };
    }
  }

  /// Search cached destinations
  Future<List<Destination>> searchCachedDestinations(String query) async {
    try {
      final allDestinations = await getAllCachedDestinations();
      final lowerQuery = query.toLowerCase();
      
      return allDestinations.where((dest) {
        return dest.name.toLowerCase().contains(lowerQuery) ||
               dest.description.toLowerCase().contains(lowerQuery) ||
               dest.location.toLowerCase().contains(lowerQuery) ||
               dest.category.toLowerCase().contains(lowerQuery);
      }).toList();
    } catch (e) {
      AppLogger.error(_tag, 'Error searching cached destinations', e);
      return [];
    }
  }

  /// Get cached destinations by category
  Future<List<Destination>> getCachedDestinationsByCategory(String category) async {
    try {
      final allDestinations = await getAllCachedDestinations();
      return allDestinations.where((dest) => dest.category == category).toList();
    } catch (e) {
      AppLogger.error(_tag, 'Error getting cached destinations by category', e);
      return [];
    }
  }

  /// Get cached destinations by price range
  Future<List<Destination>> getCachedDestinationsByPriceRange({
    double minPrice = 1.0,
    double maxPrice = 5.0,
  }) async {
    try {
      final allDestinations = await getAllCachedDestinations();
      return allDestinations.where((dest) {
        return dest.priceRange >= minPrice && dest.priceRange <= maxPrice;
      }).toList();
    } catch (e) {
      AppLogger.error(_tag, 'Error getting cached destinations by price range', e);
      return [];
    }
  }

  /// Get cached destinations by minimum rating
  Future<List<Destination>> getCachedDestinationsByRating(double minRating) async {
    try {
      final allDestinations = await getAllCachedDestinations();
      return allDestinations.where((dest) => dest.rating >= minRating).toList();
    } catch (e) {
      AppLogger.error(_tag, 'Error getting cached destinations by rating', e);
      return [];
    }
  }

  /// Clear all cached destinations
  Future<void> clearCache() async {
    try {
      final box = _hiveService.destinations;
      await box.clear();
    } catch (e) {
      AppLogger.error(_tag, 'Error clearing destination cache', e);
    }
  }
}

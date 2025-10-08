import '../../core/database/hive_service.dart';
import '../../core/database/models/cached_data.dart';
import '../../core/models/trip_model.dart';
import '../../core/utils/logger.dart';

/// Cache service for trips with offline support
class TripCacheService {
  static const String _tag = 'TripCacheService';

  final HiveService _hiveService = HiveService.instance;

  /// Get cached trip by ID
  Future<Trip?> getCachedTrip(String tripId) async {
    try {
      final box = _hiveService.trips;
      final cached = box.get(tripId) as CachedData?;

      if (cached == null) {
        AppLogger.debug(_tag, 'Trip not found in cache', {'tripId': tripId});
        return null;
      }

      AppLogger.debug(_tag, 'Trip retrieved from cache', {
        'tripId': tripId,
        'isDirty': cached.isDirty,
        'cachedAt': cached.cachedAt.toString(),
      });

      return Trip.fromMap(cached.data);
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get cached trip', e, stackTrace);
      return null;
    }
  }

  /// Get all cached trips
  Future<List<Trip>> getAllCachedTrips() async {
    try {
      final box = _hiveService.trips;
      final List<Trip> trips = [];

      for (var key in box.keys) {
        final cached = box.get(key) as CachedData?;
        if (cached != null) {
          try {
            trips.add(Trip.fromMap(cached.data));
          } catch (e) {
            AppLogger.error(_tag, 'Failed to parse cached trip', e);
          }
        }
      }

      AppLogger.info(_tag, 'Retrieved all cached trips', {
        'count': trips.length,
      });

      return trips;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get all cached trips', e, stackTrace);
      return [];
    }
  }

  /// Cache trip data
  Future<void> cacheTrip(Trip trip) async {
    try {
      final box = _hiveService.trips;

      final cached = CachedData(
        id: trip.id,
        data: trip.toMap(),
        cachedAt: DateTime.now(),
        isDirty: false,
      );

      await box.put(trip.id, cached);

      AppLogger.debug(_tag, 'Trip cached successfully', {
        'tripId': trip.id,
        'title': trip.title,
      });
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to cache trip', e, stackTrace);
      rethrow;
    }
  }

  /// Cache multiple trips (batch operation)
  Future<void> cacheTrips(List<Trip> trips) async {
    try {
      final box = _hiveService.trips;
      final Map<String, CachedData> cacheMap = {};

      for (final trip in trips) {
        cacheMap[trip.id] = CachedData(
          id: trip.id,
          data: trip.toMap(),
          cachedAt: DateTime.now(),
          isDirty: false,
        );
      }

      await box.putAll(cacheMap);

      AppLogger.info(_tag, 'Batch cached trips', {
        'count': trips.length,
      });
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to batch cache trips', e, stackTrace);
      rethrow;
    }
  }

  /// Update cached trip (mark as dirty for sync)
  Future<void> updateCachedTrip(Trip trip, {bool markDirty = true}) async {
    try {
      final box = _hiveService.trips;

      final cached = CachedData(
        id: trip.id,
        data: trip.toMap(),
        cachedAt: DateTime.now(),
        isDirty: markDirty,
      );

      await box.put(trip.id, cached);

      AppLogger.debug(_tag, 'Trip updated in cache', {
        'tripId': trip.id,
        'isDirty': markDirty,
      });
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to update cached trip', e, stackTrace);
      rethrow;
    }
  }

  /// Delete cached trip
  Future<void> deleteCachedTrip(String tripId) async {
    try {
      final box = _hiveService.trips;
      await box.delete(tripId);

      AppLogger.debug(_tag, 'Trip deleted from cache', {
        'tripId': tripId,
      });
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to delete cached trip', e, stackTrace);
      rethrow;
    }
  }

  /// Get trips that need sync (dirty trips)
  Future<List<Trip>> getDirtyTrips() async {
    try {
      final box = _hiveService.trips;
      final List<Trip> dirtyTrips = [];

      for (var key in box.keys) {
        final cached = box.get(key) as CachedData?;
        if (cached != null && cached.isDirty) {
          try {
            dirtyTrips.add(Trip.fromMap(cached.data));
          } catch (e) {
            AppLogger.error(_tag, 'Failed to parse dirty trip', e);
          }
        }
      }

      AppLogger.info(_tag, 'Retrieved dirty trips', {
        'count': dirtyTrips.length,
      });

      return dirtyTrips;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get dirty trips', e, stackTrace);
      return [];
    }
  }

  /// Mark trip as synced
  Future<void> markTripSynced(String tripId) async {
    try {
      final box = _hiveService.trips;
      final cached = box.get(tripId) as CachedData?;

      if (cached != null) {
        cached.markSynced();
        AppLogger.debug(_tag, 'Trip marked as synced', {'tripId': tripId});
      }
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to mark trip as synced', e, stackTrace);
    }
  }

  /// Check if trip exists in cache
  bool isTripCached(String tripId) {
    try {
      final box = _hiveService.trips;
      return box.containsKey(tripId);
    } catch (e) {
      AppLogger.error(_tag, 'Failed to check if trip is cached', e);
      return false;
    }
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    try {
      final box = _hiveService.trips;
      int totalTrips = 0;
      int dirtyTrips = 0;
      int validTrips = 0;

      for (var key in box.keys) {
        final cached = box.get(key) as CachedData?;
        if (cached != null) {
          totalTrips++;
          if (cached.isDirty) dirtyTrips++;
          if (cached.isValid()) validTrips++;
        }
      }

      return {
        'total': totalTrips,
        'dirty': dirtyTrips,
        'valid': validTrips,
        'invalid': totalTrips - validTrips,
      };
    } catch (e) {
      AppLogger.error(_tag, 'Failed to get cache stats', e);
      return {};
    }
  }

  /// Clear all cached trips
  Future<void> clearCache() async {
    try {
      final box = _hiveService.trips;
      await box.clear();
      AppLogger.info(_tag, 'Trips cache cleared');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to clear trips cache', e, stackTrace);
    }
  }

  /// Search cached trips by query
  Future<List<Trip>> searchCachedTrips(String query) async {
    try {
      final allTrips = await getAllCachedTrips();
      final lowerQuery = query.toLowerCase();

      final results = allTrips.where((trip) {
        return trip.title.toLowerCase().contains(lowerQuery) ||
            trip.description.toLowerCase().contains(lowerQuery) ||
            trip.destinations.any((dest) => 
              dest.name.toLowerCase().contains(lowerQuery)
            );
      }).toList();

      AppLogger.debug(_tag, 'Searched cached trips', {
        'query': query,
        'results': results.length,
      });

      return results;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to search cached trips', e, stackTrace);
      return [];
    }
  }

  /// Get trips by user ID
  Future<List<Trip>> getCachedTripsByUser(String userId) async {
    try {
      final allTrips = await getAllCachedTrips();
      final userTrips = allTrips.where((trip) => trip.userId == userId).toList();

      AppLogger.debug(_tag, 'Retrieved user trips from cache', {
        'userId': userId,
        'count': userTrips.length,
      });

      return userTrips;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get user trips from cache', e, stackTrace);
      return [];
    }
  }
}

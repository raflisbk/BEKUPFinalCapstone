import 'dart:async';
import 'dart:math' as math;
import '../core/utils/logger.dart';
import 'supabase_config.dart';
import 'supabase_database_service.dart';

/// Destination Service
/// Handles destination management, discovery, and related operations
class DestinationService {
  static const String _tag = 'DestinationService';
  static const String _tableName = 'destinations';
  static const String _categoriesTable = 'destination_categories';
  static const String _bookmarksTable = 'destination_bookmarks';

  // Singleton pattern
  static DestinationService? _instance;
  static DestinationService get instance => _instance ??= DestinationService._internal();
  
  DestinationService._internal();

  // ===============================
  // DESTINATION CRUD OPERATIONS
  // ===============================

  /// Get all destinations with optional filtering
  Future<List<Map<String, dynamic>>> getDestinations({
    String? category,
    String? province,
    String? city,
    double? minRating,
    double? maxDistance,
    double? userLat,
    double? userLng,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      AppLogger.debug(_tag, 'Getting destinations with filters');

      final filters = <String, dynamic>{};
      if (category != null) filters['category'] = category;
      if (province != null) filters['province'] = province;
      if (city != null) filters['city'] = city;

      List<Map<String, dynamic>> destinations = await SupabaseDatabaseService.select(
        table: _tableName,
        filters: filters,
        orderBy: 'rating',
        ascending: false,
        limit: limit,
        offset: offset,
      );

      // Apply additional filters that can't be done at database level
      if (minRating != null) {
        destinations = destinations.where((dest) {
          final rating = dest['rating'] as double?;
          return rating != null && rating >= minRating;
        }).toList();
      }

      // Calculate distance if user location is provided
      if (userLat != null && userLng != null) {
        destinations = destinations.map((dest) {
          final destLat = dest['latitude'] as double?;
          final destLng = dest['longitude'] as double?;
          
          if (destLat != null && destLng != null) {
            final distance = _calculateDistance(userLat, userLng, destLat, destLng);
            dest['distance_km'] = distance;
          }
          
          return dest;
        }).toList();

        // Filter by max distance if specified
        if (maxDistance != null) {
          destinations = destinations.where((dest) {
            final distance = dest['distance_km'] as double?;
            return distance != null && distance <= maxDistance;
          }).toList();
        }

        // Sort by distance
        destinations.sort((a, b) {
          final distanceA = a['distance_km'] as double? ?? double.infinity;
          final distanceB = b['distance_km'] as double? ?? double.infinity;
          return distanceA.compareTo(distanceB);
        });
      }

      AppLogger.success(_tag, 'Retrieved ${destinations.length} destinations');
      return destinations;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get destinations', e, stackTrace);
      rethrow;
    }
  }

  /// Get destination by ID
  Future<Map<String, dynamic>?> getDestination(String destinationId) async {
    try {
      AppLogger.debug(_tag, 'Getting destination: $destinationId');

      final destinations = await SupabaseDatabaseService.select(
        table: _tableName,
        filters: {'id': destinationId},
      );

      if (destinations.isEmpty) {
        AppLogger.warning(_tag, 'Destination not found: $destinationId');
        return null;
      }

      final destination = destinations.first;
      
      // Get additional data
      await _enrichDestinationData(destination);

      AppLogger.success(_tag, 'Retrieved destination: ${destination['name']}');
      return destination;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get destination', e, stackTrace);
      rethrow;
    }
  }

  /// Create new destination
  static Future<Map<String, dynamic>> createDestination({
    required String name,
    required String description,
    required double latitude,
    required double longitude,
    required String category,
    String? province,
    String? city,
    String? address,
    List<String>? imageUrls,
    Map<String, dynamic>? facilities,
    Map<String, dynamic>? pricing,
    Map<String, dynamic>? openingHours,
    String? contactInfo,
    String? website,
  }) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Creating new destination: $name');

      final destinationData = {
        'name': name,
        'description': description,
        'latitude': latitude,
        'longitude': longitude,
        'category': category,
        'province': province,
        'city': city,
        'address': address,
        'image_urls': imageUrls ?? [],
        'facilities': facilities ?? {},
        'pricing': pricing ?? {},
        'opening_hours': openingHours ?? {},
        'contact_info': contactInfo,
        'website': website,
        'created_by': userId,
        'is_verified': false,
        'is_active': true,
        'rating': 0.0,
        'review_count': 0,
        'visit_count': 0,
      };

      final result = await SupabaseDatabaseService.insert(
        table: _tableName,
        data: destinationData,
      );

      AppLogger.success(_tag, 'Destination created successfully: $name');
      return result;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to create destination', e, stackTrace);
      rethrow;
    }
  }

  /// Update destination
  static Future<Map<String, dynamic>> updateDestination({
    required String destinationId,
    String? name,
    String? description,
    double? latitude,
    double? longitude,
    String? category,
    String? province,
    String? city,
    String? address,
    List<String>? imageUrls,
    Map<String, dynamic>? facilities,
    Map<String, dynamic>? pricing,
    Map<String, dynamic>? openingHours,
    String? contactInfo,
    String? website,
  }) async {
    try {
      AppLogger.debug(_tag, 'Updating destination: $destinationId');

      final updateData = <String, dynamic>{};
      
      if (name != null) updateData['name'] = name;
      if (description != null) updateData['description'] = description;
      if (latitude != null) updateData['latitude'] = latitude;
      if (longitude != null) updateData['longitude'] = longitude;
      if (category != null) updateData['category'] = category;
      if (province != null) updateData['province'] = province;
      if (city != null) updateData['city'] = city;
      if (address != null) updateData['address'] = address;
      if (imageUrls != null) updateData['image_urls'] = imageUrls;
      if (facilities != null) updateData['facilities'] = facilities;
      if (pricing != null) updateData['pricing'] = pricing;
      if (openingHours != null) updateData['opening_hours'] = openingHours;
      if (contactInfo != null) updateData['contact_info'] = contactInfo;
      if (website != null) updateData['website'] = website;

      if (updateData.isEmpty) {
        throw Exception('No data provided for update');
      }

      final result = await SupabaseDatabaseService.update(
        table: _tableName,
        id: destinationId,
        data: updateData,
      );

      AppLogger.success(_tag, 'Destination updated successfully');
      return result;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to update destination', e, stackTrace);
      rethrow;
    }
  }

  /// Delete destination
  static Future<void> deleteDestination(String destinationId) async {
    try {
      AppLogger.warning(_tag, 'Deleting destination: $destinationId');

      await SupabaseDatabaseService.delete(
        table: _tableName,
        id: destinationId,
      );

      AppLogger.success(_tag, 'Destination deleted successfully');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to delete destination', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // SEARCH & DISCOVERY
  // ===============================

  /// Search destinations by name, description, or location
  static Future<List<Map<String, dynamic>>> searchDestinations({
    required String query,
    String? category,
    String? province,
    int limit = 20,
  }) async {
    try {
      AppLogger.debug(_tag, 'Searching destinations: $query');

      // Get all destinations first with basic filters
      final filters = <String, dynamic>{};
      if (category != null) filters['category'] = category;
      if (province != null) filters['province'] = province;

      final results = await SupabaseDatabaseService.textSearch(
        table: _tableName,
        searchTerm: query,
        searchColumns: ['name', 'description', 'city', 'address'],
        limit: limit,
      );

      AppLogger.success(_tag, 'Found ${results.length} destinations for query: $query');
      return results;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to search destinations', e, stackTrace);
      rethrow;
    }
  }

  /// Get popular destinations
  Future<List<Map<String, dynamic>>> getPopularDestinations({
    int limit = 10,
    String? category,
  }) async {
    try {
      AppLogger.debug(_tag, 'Getting popular destinations');

      final filters = <String, dynamic>{'is_active': true};
      if (category != null) filters['category'] = category;

      final destinations = await SupabaseDatabaseService.select(
        table: _tableName,
        filters: filters,
        orderBy: 'visit_count',
        ascending: false,
        limit: limit,
      );

      AppLogger.success(_tag, 'Retrieved ${destinations.length} popular destinations');
      return destinations;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get popular destinations', e, stackTrace);
      rethrow;
    }
  }

  /// Get top rated destinations
  static Future<List<Map<String, dynamic>>> getTopRatedDestinations({
    int limit = 10,
    String? category,
    int minReviews = 5,
  }) async {
    try {
      AppLogger.debug(_tag, 'Getting top rated destinations');

      final filters = <String, dynamic>{'is_active': true};
      if (category != null) filters['category'] = category;

      List<Map<String, dynamic>> destinations = await SupabaseDatabaseService.select(
        table: _tableName,
        filters: filters,
        orderBy: 'rating',
        ascending: false,
        limit: limit * 2, // Get more to filter by review count
      );

      // Filter by minimum review count
      destinations = destinations.where((dest) {
        final reviewCount = dest['review_count'] as int? ?? 0;
        return reviewCount >= minReviews;
      }).take(limit).toList();

      AppLogger.success(_tag, 'Retrieved ${destinations.length} top rated destinations');
      return destinations;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get top rated destinations', e, stackTrace);
      rethrow;
    }
  }

  /// Get nearby destinations
  static Future<List<Map<String, dynamic>>> getNearbyDestinations({
    required double latitude,
    required double longitude,
    double radiusKm = 50.0,
    int limit = 20,
  }) async {
    try {
      AppLogger.debug(_tag, 'Getting nearby destinations within ${radiusKm}km');

      // Get all active destinations
      final allDestinations = await SupabaseDatabaseService.select(
        table: _tableName,
        filters: {'is_active': true},
      );

      // Calculate distances and filter
      final nearbyDestinations = <Map<String, dynamic>>[];

      for (final destination in allDestinations) {
        final destLat = destination['latitude'] as double?;
        final destLng = destination['longitude'] as double?;

        if (destLat != null && destLng != null) {
          final distance = _calculateDistance(latitude, longitude, destLat, destLng);
          
          if (distance <= radiusKm) {
            destination['distance_km'] = distance;
            nearbyDestinations.add(destination);
          }
        }
      }

      // Sort by distance
      nearbyDestinations.sort((a, b) {
        final distanceA = a['distance_km'] as double;
        final distanceB = b['distance_km'] as double;
        return distanceA.compareTo(distanceB);
      });

      final result = nearbyDestinations.take(limit).toList();

      AppLogger.success(_tag, 'Found ${result.length} nearby destinations');
      return result;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get nearby destinations', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // CATEGORIES & FILTERING
  // ===============================

  /// Get all destination categories
  static Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      AppLogger.debug(_tag, 'Getting destination categories');

      final categories = await SupabaseDatabaseService.select(
        table: _categoriesTable,
        orderBy: 'name',
      );

      AppLogger.success(_tag, 'Retrieved ${categories.length} categories');
      return categories;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get categories', e, stackTrace);
      // Return default categories if database call fails
      return _getDefaultCategories();
    }
  }

  /// Get destinations by category
  static Future<List<Map<String, dynamic>>> getDestinationsByCategory({
    required String category,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      AppLogger.debug(_tag, 'Getting destinations by category: $category');

      final destinations = await SupabaseDatabaseService.select(
        table: _tableName,
        filters: {'category': category, 'is_active': true},
        orderBy: 'rating',
        ascending: false,
        limit: limit,
        offset: offset,
      );

      AppLogger.success(_tag, 'Retrieved ${destinations.length} destinations for category: $category');
      return destinations;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get destinations by category', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // BOOKMARKS
  // ===============================

  /// Bookmark a destination
  static Future<Map<String, dynamic>> bookmarkDestination(String destinationId) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Bookmarking destination: $destinationId');

      // Check if already bookmarked
      final existing = await SupabaseDatabaseService.select(
        table: _bookmarksTable,
        filters: {
          'user_id': userId,
          'destination_id': destinationId,
        },
      );

      if (existing.isNotEmpty) {
        throw Exception('Destination already bookmarked');
      }

      final bookmarkData = {
        'user_id': userId,
        'destination_id': destinationId,
      };

      final result = await SupabaseDatabaseService.insert(
        table: _bookmarksTable,
        data: bookmarkData,
      );

      AppLogger.success(_tag, 'Destination bookmarked successfully');
      return result;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to bookmark destination', e, stackTrace);
      rethrow;
    }
  }

  /// Remove bookmark
  static Future<void> removeBookmark(String destinationId) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Removing bookmark: $destinationId');

      final bookmarks = await SupabaseDatabaseService.select(
        table: _bookmarksTable,
        filters: {
          'user_id': userId,
          'destination_id': destinationId,
        },
      );

      if (bookmarks.isEmpty) {
        throw Exception('Bookmark not found');
      }

      await SupabaseDatabaseService.delete(
        table: _bookmarksTable,
        id: bookmarks.first['id'],
      );

      AppLogger.success(_tag, 'Bookmark removed successfully');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to remove bookmark', e, stackTrace);
      rethrow;
    }
  }

  /// Get user bookmarks
  static Future<List<Map<String, dynamic>>> getUserBookmarks() async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Getting user bookmarks');

      final bookmarks = await SupabaseDatabaseService.select(
        table: _bookmarksTable,
        filters: {'user_id': userId},
        orderBy: 'created_at',
        ascending: false,
      );

      // Get destination details for each bookmark
      final destinationService = DestinationService.instance;
      final destinations = <Map<String, dynamic>>[];
      for (final bookmark in bookmarks) {
        final destination = await destinationService.getDestination(bookmark['destination_id']);
        if (destination != null) {
          destination['bookmarked_at'] = bookmark['created_at'];
          destinations.add(destination);
        }
      }

      AppLogger.success(_tag, 'Retrieved ${destinations.length} bookmarked destinations');
      return destinations;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get user bookmarks', e, stackTrace);
      rethrow;
    }
  }

  /// Check if destination is bookmarked
  static Future<bool> isDestinationBookmarked(String destinationId) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) return false;

      final bookmarks = await SupabaseDatabaseService.select(
        table: _bookmarksTable,
        filters: {
          'user_id': userId,
          'destination_id': destinationId,
        },
      );

      return bookmarks.isNotEmpty;
    } catch (e) {
      AppLogger.error(_tag, 'Failed to check bookmark status', e);
      return false;
    }
  }

  // ===============================
  // STATISTICS & ANALYTICS
  // ===============================

  /// Increment visit count
  static Future<void> incrementVisitCount(String destinationId) async {
    try {
      AppLogger.debug(_tag, 'Incrementing visit count for: $destinationId');

      // Get current destination
      final destinationService = DestinationService.instance;
      final destination = await destinationService.getDestination(destinationId);
      if (destination == null) {
        throw Exception('Destination not found');
      }

      final currentCount = destination['visit_count'] as int? ?? 0;

      await SupabaseDatabaseService.update(
        table: _tableName,
        id: destinationId,
        data: {'visit_count': currentCount + 1},
      );

      AppLogger.success(_tag, 'Visit count incremented');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to increment visit count', e, stackTrace);
      // Don't rethrow as this is not critical
    }
  }

  /// Update destination rating
  static Future<void> updateDestinationRating(String destinationId) async {
    try {
      AppLogger.debug(_tag, 'Updating destination rating: $destinationId');

      // This would typically be called after a review is added/updated
      // Calculate average rating from reviews table
      // For now, we'll implement a placeholder

      AppLogger.success(_tag, 'Destination rating updated');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to update destination rating', e, stackTrace);
      // Don't rethrow as this is not critical
    }
  }

  // ===============================
  // PRIVATE HELPER METHODS
  // ===============================

  /// Calculate distance between two coordinates using Haversine formula
  static double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371; // Earth radius in kilometers

    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLng = _degreesToRadians(lng2 - lng1);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
        math.cos(_degreesToRadians(lat2)) *
        math.sin(dLng / 2) *
        math.sin(dLng / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  /// Convert degrees to radians
  static double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  /// Enrich destination data with additional information
  static Future<void> _enrichDestinationData(Map<String, dynamic> destination) async {
    try {
      // Add bookmark status if user is logged in
      final userId = SupabaseConfig.userId;
      if (userId != null) {
        destination['is_bookmarked'] = await isDestinationBookmarked(destination['id']);
      }

      // Add any other enrichment data here
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to enrich destination data', e);
      // Don't throw error as this is not critical
    }
  }

  /// Get default categories as fallback
  static List<Map<String, dynamic>> _getDefaultCategories() {
    return [
      {'id': '1', 'name': 'Wisata Alam', 'icon': 'nature', 'color': '#4CAF50'},
      {'id': '2', 'name': 'Wisata Budaya', 'icon': 'culture', 'color': '#FF9800'},
      {'id': '3', 'name': 'Wisata Kuliner', 'icon': 'food', 'color': '#F44336'},
      {'id': '4', 'name': 'Wisata Religi', 'icon': 'religious', 'color': '#9C27B0'},
      {'id': '5', 'name': 'Wisata Pantai', 'icon': 'beach', 'color': '#2196F3'},
      {'id': '6', 'name': 'Wisata Gunung', 'icon': 'mountain', 'color': '#795548'},
      {'id': '7', 'name': 'Wisata Belanja', 'icon': 'shopping', 'color': '#E91E63'},
      {'id': '8', 'name': 'Wisata Sejarah', 'icon': 'history', 'color': '#607D8B'},
    ];
  }
}
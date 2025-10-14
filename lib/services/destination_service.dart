import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/models/destination_model.dart';
import '../core/utils/logger.dart';

/// Service for managing destinations using Supabase
class DestinationService {
  static const String _tag = 'DestinationService';

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get all destinations with optional filters
  Stream<List<Destination>> getDestinationsStream({
    DestinationFilter? filter,
    int limit = 50,
  }) {
    try {
      var query = _supabase.from('destinations').select();

      // Apply category filter
      if (filter?.category != null) {
        query = query.eq('category', filter!.category!);
      }

      // Apply rating filter
      if (filter?.minRating != null) {
        query = query.where('rating', isGreaterThanOrEqualTo: filter!.minRating);
      }

      // Apply price range filter
      if (filter?.maxPriceRange != null) {
        query = query.where('priceRange', isLessThanOrEqualTo: filter!.maxPriceRange);
      }

      // Apply sorting
      if (filter?.sortBy != null) {
        switch (filter!.sortBy) {
          case DestinationSort.rating:
            query = query.orderBy('rating', descending: true);
            break;
          case DestinationSort.newest:
            query = query.orderBy('createdAt', descending: true);
            break;
          case DestinationSort.name:
            query = query.orderBy('name', descending: false);
            break;
          case DestinationSort.priceRange:
            query = query.orderBy('priceRange', descending: false);
            break;
        }
      } else {
        // Default sort by rating
        query = query.orderBy('rating', descending: true);
      }

      query = query.limit(limit);

      return query.snapshots().map((snapshot) {
        var destinations = snapshot.docs
            .map((doc) => Destination.fromFirestore(doc))
            .toList();

        // Apply search filter on client side (Firestore doesn't support LIKE)
        if (filter?.searchQuery != null && filter!.searchQuery!.isNotEmpty) {
          final searchLower = filter.searchQuery!.toLowerCase();
          destinations = destinations.where((dest) {
            return dest.name.toLowerCase().contains(searchLower) ||
                dest.location.toLowerCase().contains(searchLower) ||
                dest.description.toLowerCase().contains(searchLower);
          }).toList();
        }

        AppLogger.info(_tag, 'Destinations loaded', {
          'count': destinations.length,
        });

        return destinations;
      });
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get destinations stream', e, stackTrace);
      return Stream.value([]);
    }
  }

  /// Get destination by ID
  Future<Destination?> getDestinationById(String destinationId) async {
    try {
      AppLogger.debug(_tag, 'Getting destination by ID', {
        'destinationId': destinationId,
      });

      final doc = await _destinationsCollection.doc(destinationId).get();

      if (!doc.exists) {
        AppLogger.warning(_tag, 'Destination not found');
        return null;
      }

      return Destination.fromFirestore(doc);
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get destination', e, stackTrace);
      return null;
    }
  }

  /// Get destination stream by ID
  Stream<Destination?> getDestinationStream(String destinationId) {
    return _destinationsCollection.doc(destinationId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Destination.fromFirestore(doc);
    });
  }

  /// Create new destination
  Future<String?> createDestination({
    required String name,
    required String description,
    required String location,
    required double latitude,
    required double longitude,
    required String category,
    required List<String> images,
    required double priceRange,
    required List<String> facilities,
    required List<String> activities,
    required String openingHours,
    required String bestTimeToVisit,
    required String userId,
  }) async {
    try {
      AppLogger.debug(_tag, 'Creating destination', {'name': name});

      final now = DateTime.now();
      final destination = Destination(
        id: '',
        name: name,
        description: description,
        location: location,
        latitude: latitude,
        longitude: longitude,
        category: category,
        images: images,
        priceRange: priceRange,
        rating: 0.0,
        reviewCount: 0,
        facilities: facilities,
        activities: activities,
        openingHours: openingHours,
        bestTimeToVisit: bestTimeToVisit,
        isVerified: false,
        createdBy: userId,
        createdAt: now,
        updatedAt: now,
      );

      final docRef = await _destinationsCollection.add(destination.toFirestore());

      AppLogger.info(_tag, 'Destination created successfully', {
        'destinationId': docRef.id,
      });

      return docRef.id;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to create destination', e, stackTrace);
      return null;
    }
  }

  /// Update destination
  Future<bool> updateDestination({
    required String destinationId,
    String? name,
    String? description,
    String? location,
    double? latitude,
    double? longitude,
    String? category,
    List<String>? images,
    double? priceRange,
    List<String>? facilities,
    List<String>? activities,
    String? openingHours,
    String? bestTimeToVisit,
  }) async {
    try {
      AppLogger.debug(_tag, 'Updating destination', {
        'destinationId': destinationId,
      });

      final Map<String, dynamic> updates = {
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (name != null) updates['name'] = name;
      if (description != null) updates['description'] = description;
      if (location != null) updates['location'] = location;
      if (latitude != null) updates['latitude'] = latitude;
      if (longitude != null) updates['longitude'] = longitude;
      if (category != null) updates['category'] = category;
      if (images != null) updates['images'] = images;
      if (priceRange != null) updates['priceRange'] = priceRange;
      if (facilities != null) updates['facilities'] = facilities;
      if (activities != null) updates['activities'] = activities;
      if (openingHours != null) updates['openingHours'] = openingHours;
      if (bestTimeToVisit != null) updates['bestTimeToVisit'] = bestTimeToVisit;

      await _destinationsCollection.doc(destinationId).update(updates);

      AppLogger.info(_tag, 'Destination updated successfully');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to update destination', e, stackTrace);
      return false;
    }
  }

  /// Delete destination
  Future<bool> deleteDestination(String destinationId) async {
    try {
      AppLogger.debug(_tag, 'Deleting destination', {
        'destinationId': destinationId,
      });

      await _destinationsCollection.doc(destinationId).delete();

      AppLogger.info(_tag, 'Destination deleted successfully');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to delete destination', e, stackTrace);
      return false;
    }
  }

  /// Update destination rating (called from ReviewService)
  Future<void> updateDestinationRating(
    String destinationId,
    double averageRating,
    int reviewCount,
  ) async {
    try {
      await _destinationsCollection.doc(destinationId).update({
        'rating': averageRating,
        'reviewCount': reviewCount,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      AppLogger.info(_tag, 'Destination rating updated', {
        'destinationId': destinationId,
        'rating': averageRating,
        'reviewCount': reviewCount,
      });
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to update rating', e, stackTrace);
    }
  }

  /// Get user bookmarks
  Future<UserBookmark?> getUserBookmarks(String userId) async {
    try {
      final doc = await _bookmarksCollection.doc(userId).get();

      if (!doc.exists) {
        // Create initial bookmark document
        final bookmark = UserBookmark(
          userId: userId,
          destinationIds: [],
          updatedAt: DateTime.now(),
        );

        await _bookmarksCollection.doc(userId).set(bookmark.toFirestore());
        return bookmark;
      }

      return UserBookmark.fromFirestore(doc);
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get bookmarks', e, stackTrace);
      return null;
    }
  }

  /// Get user bookmarks stream
  Stream<UserBookmark?> getUserBookmarksStream(String userId) {
    return _bookmarksCollection.doc(userId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserBookmark.fromFirestore(doc);
    });
  }

  /// Toggle bookmark
  Future<bool> toggleBookmark(String userId, String destinationId) async {
    try {
      AppLogger.debug(_tag, 'Toggling bookmark', {
        'userId': userId,
        'destinationId': destinationId,
      });

      final bookmark = await getUserBookmarks(userId);
      if (bookmark == null) return false;

      final isBookmarked = bookmark.isBookmarked(destinationId);

      if (isBookmarked) {
        // Remove bookmark
        await _bookmarksCollection.doc(userId).update({
          'destinationIds': FieldValue.arrayRemove([destinationId]),
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      } else {
        // Add bookmark
        await _bookmarksCollection.doc(userId).update({
          'destinationIds': FieldValue.arrayUnion([destinationId]),
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      }

      AppLogger.info(_tag, 'Bookmark toggled', {'isBookmarked': !isBookmarked});
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to toggle bookmark', e, stackTrace);
      return false;
    }
  }

  /// Get bookmarked destinations
  Future<List<Destination>> getBookmarkedDestinations(String userId) async {
    try {
      final bookmark = await getUserBookmarks(userId);
      if (bookmark == null || bookmark.destinationIds.isEmpty) {
        return [];
      }

      // Firestore 'in' query limit is 10, so batch the requests
      final List<Destination> destinations = [];

      for (int i = 0; i < bookmark.destinationIds.length; i += 10) {
        final batch = bookmark.destinationIds.skip(i).take(10).toList();

        final querySnapshot = await _destinationsCollection
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        destinations.addAll(
          querySnapshot.docs
              .map((doc) => Destination.fromFirestore(doc))
              .toList(),
        );
      }

      AppLogger.info(_tag, 'Bookmarked destinations loaded', {
        'count': destinations.length,
      });

      return destinations;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get bookmarked destinations', e, stackTrace);
      return [];
    }
  }

  /// Search destinations by query
  Future<List<Destination>> searchDestinations(String query) async {
    try {
      if (query.isEmpty) return [];

      AppLogger.debug(_tag, 'Searching destinations', {'query': query});

      // Get all destinations and filter on client side
      // Note: For production, consider using Algolia or Elasticsearch
      final snapshot = await _destinationsCollection
          .orderBy('rating', descending: true)
          .limit(100)
          .get();

      final searchLower = query.toLowerCase();
      final results = snapshot.docs
          .map((doc) => Destination.fromFirestore(doc))
          .where((dest) {
        return dest.name.toLowerCase().contains(searchLower) ||
            dest.location.toLowerCase().contains(searchLower) ||
            dest.description.toLowerCase().contains(searchLower) ||
            dest.category.toLowerCase().contains(searchLower);
      }).toList();

      AppLogger.info(_tag, 'Search completed', {
        'query': query,
        'results': results.length,
      });

      return results;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to search destinations', e, stackTrace);
      return [];
    }
  }

  /// Get destinations by category
  Stream<List<Destination>> getDestinationsByCategory(
    String category, {
    int limit = 20,
  }) {
    return _destinationsCollection
        .where('category', isEqualTo: category)
        .orderBy('rating', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Destination.fromFirestore(doc))
          .toList();
    });
  }

  /// Get nearby destinations
  Future<List<Destination>> getNearbyDestinations({
    required double latitude,
    required double longitude,
    double radiusKm = 50.0,
  }) async {
    try {
      AppLogger.debug(_tag, 'Getting nearby destinations', {
        'latitude': latitude,
        'longitude': longitude,
        'radius': radiusKm,
      });

      // Get all destinations (for simplicity, in production use geohash)
      final snapshot = await _destinationsCollection.get();

      final destinations = snapshot.docs
          .map((doc) => Destination.fromFirestore(doc))
          .where((dest) {
        final distance = _calculateDistance(
          latitude,
          longitude,
          dest.latitude,
          dest.longitude,
        );
        return distance <= radiusKm;
      }).toList();

      // Sort by distance
      destinations.sort((a, b) {
        final distA = _calculateDistance(latitude, longitude, a.latitude, a.longitude);
        final distB = _calculateDistance(latitude, longitude, b.latitude, b.longitude);
        return distA.compareTo(distB);
      });

      AppLogger.info(_tag, 'Nearby destinations found', {
        'count': destinations.length,
      });

      return destinations;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get nearby destinations', e, stackTrace);
      return [];
    }
  }

  /// Calculate distance between two points (Haversine formula)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // km

    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }
}

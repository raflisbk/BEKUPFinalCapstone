import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/models/destination_model.dart';
import '../core/utils/logger.dart';

/// Advanced search filters for destinations
class SearchFilters {
  final double? minPrice;
  final double? maxPrice;
  final List<String>? activityTypes;
  final int? minDuration; // in days
  final int? maxDuration; // in days
  final String? difficulty; // easy, moderate, hard
  final double? minRating;
  final String? season; // spring, summer, fall, winter
  final List<String>? amenities;
  final bool? familyFriendly;
  final bool? petFriendly;

  const SearchFilters({
    this.minPrice,
    this.maxPrice,
    this.activityTypes,
    this.minDuration,
    this.maxDuration,
    this.difficulty,
    this.minRating,
    this.season,
    this.amenities,
    this.familyFriendly,
    this.petFriendly,
  });

  Map<String, dynamic> toMap() {
    return {
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'activityTypes': activityTypes,
      'minDuration': minDuration,
      'maxDuration': maxDuration,
      'difficulty': difficulty,
      'minRating': minRating,
      'season': season,
      'amenities': amenities,
      'familyFriendly': familyFriendly,
      'petFriendly': petFriendly,
    };
  }
}

/// Service for advanced search with filters
class AdvancedSearchService {
  static const String _tag = 'AdvancedSearchService';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Search destinations with advanced filters
  Future<List<Destination>> searchWithFilters({
    required String query,
    SearchFilters? filters,
    int limit = 20,
  }) async {
    try {
      AppLogger.debug(_tag, 'Searching with filters', {
        'query': query,
        'filters': filters?.toMap(),
      });

      Query<Map<String, dynamic>> queryRef = _firestore.collection('destinations');

      // Text search
      if (query.isNotEmpty) {
        queryRef = queryRef.where('searchTerms', arrayContains: query.toLowerCase());
      }

      // Price range filter
      if (filters?.minPrice != null) {
        queryRef = queryRef.where('estimatedCost', isGreaterThanOrEqualTo: filters!.minPrice);
      }
      if (filters?.maxPrice != null) {
        queryRef = queryRef.where('estimatedCost', isLessThanOrEqualTo: filters!.maxPrice);
      }

      // Rating filter
      if (filters?.minRating != null) {
        queryRef = queryRef.where('averageRating', isGreaterThanOrEqualTo: filters!.minRating);
      }

      // Difficulty filter
      if (filters?.difficulty != null) {
        queryRef = queryRef.where('difficulty', isEqualTo: filters!.difficulty);
      }

      // Family friendly filter
      if (filters?.familyFriendly == true) {
        queryRef = queryRef.where('familyFriendly', isEqualTo: true);
      }

      // Pet friendly filter
      if (filters?.petFriendly == true) {
        queryRef = queryRef.where('petFriendly', isEqualTo: true);
      }

      // Execute query
      final snapshot = await queryRef.limit(limit).get();

      List<Destination> results = snapshot.docs
          .map((doc) => Destination.fromFirestore(doc))
          .toList();

      // Client-side filtering for complex criteria
      results = _applyClientSideFilters(results, filters);

      AppLogger.info(_tag, 'Search completed', {
        'resultsCount': results.length,
      });

      return results;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to search with filters', e, stackTrace);
      return [];
    }
  }

  /// Apply filters that can't be done in Firestore query
  List<Destination> _applyClientSideFilters(
    List<Destination> destinations,
    SearchFilters? filters,
  ) {
    if (filters == null) return destinations;

    return destinations.where((dest) {
      // Duration filter - skipped (recommendedDuration not in Destination model)
      // This would need to be implemented when duration field is added to Destination

      // Activity types filter
      if (filters.activityTypes != null && filters.activityTypes!.isNotEmpty) {
        final hasMatchingActivity = filters.activityTypes!.any(
          (activity) => dest.activities.contains(activity),
        );
        if (!hasMatchingActivity) return false;
      }

      // Season filter - using bestTimeToVisit string field
      if (filters.season != null) {
        final bestTimeToVisit = dest.bestTimeToVisit.toLowerCase();
        if (!bestTimeToVisit.contains(filters.season!.toLowerCase())) return false;
      }

      // Amenities filter - using facilities field
      if (filters.amenities != null && filters.amenities!.isNotEmpty) {
        final hasAllAmenities = filters.amenities!.every(
          (amenity) => dest.facilities.contains(amenity),
        );
        if (!hasAllAmenities) return false;
      }

      return true;
    }).toList();
  }

  /// Get popular search filters (for suggestions)
  Future<Map<String, List<String>>> getPopularFilters() async {
    try {
      AppLogger.debug(_tag, 'Getting popular filters');

      // In a real app, this would aggregate from user searches
      // For now, return predefined popular filters
      return {
        'activityTypes': [
          'Hiking',
          'Beach',
          'Culture',
          'Adventure',
          'Food & Dining',
          'Shopping',
          'Wildlife',
          'Photography',
        ],
        'difficulty': [
          'easy',
          'moderate',
          'hard',
        ],
        'seasons': [
          'spring',
          'summer',
          'fall',
          'winter',
        ],
        'amenities': [
          'WiFi',
          'Parking',
          'Restaurant',
          'Restrooms',
          'Accessibility',
          'Guide Service',
        ],
      };
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get popular filters', e, stackTrace);
      return {};
    }
  }

  /// Save search with filters (for history and analytics)
  Future<void> saveSearchHistory({
    required String userId,
    required String query,
    SearchFilters? filters,
  }) async {
    try {
      await _firestore.collection('search_history').add({
        'userId': userId,
        'query': query,
        'filters': filters?.toMap(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      AppLogger.debug(_tag, 'Search history saved');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to save search history', e, stackTrace);
    }
  }

  /// Get user's recent searches
  Future<List<Map<String, dynamic>>> getRecentSearches(String userId, {int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection('search_history')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get recent searches', e, stackTrace);
      return [];
    }
  }

  /// Clear search history
  Future<void> clearSearchHistory(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('search_history')
          .where('userId', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      AppLogger.info(_tag, 'Search history cleared');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to clear search history', e, stackTrace);
    }
  }
}

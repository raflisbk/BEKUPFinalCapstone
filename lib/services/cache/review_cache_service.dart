import 'package:flutter/foundation.dart';
import '../../core/database/hive_service.dart';
import '../../core/database/models/cached_data.dart';
import '../../core/models/review_model.dart';

/// Service for caching review data offline
class ReviewCacheService {
  static final ReviewCacheService _instance = ReviewCacheService._internal();
  factory ReviewCacheService() => _instance;
  ReviewCacheService._internal();

  final HiveService _hiveService = HiveService.instance;

  /// Get cached review by ID
  Future<DestinationReview?> getCachedReview(String id) async {
    try {
      final box = _hiveService.reviews;
      final cached = box.get(id) as CachedData?;
      
      if (cached == null) return null;
      
      return DestinationReview.fromMap(cached.data);
    } catch (e) {
      debugPrint('Error getting cached review: $e');
      return null;
    }
  }

  /// Get all cached reviews
  Future<List<DestinationReview>> getAllCachedReviews() async {
    try {
      final box = _hiveService.reviews;
      final reviews = <DestinationReview>[];
      
      for (final key in box.keys) {
        final cached = box.get(key) as CachedData?;
        if (cached != null) {
          try {
            reviews.add(DestinationReview.fromMap(cached.data));
          } catch (e) {
            debugPrint('Error parsing cached review $key: $e');
          }
        }
      }
      
      return reviews;
    } catch (e) {
      debugPrint('Error getting all cached reviews: $e');
      return [];
    }
  }

  /// Cache single review
  Future<void> cacheReview(DestinationReview review) async {
    try {
      final box = _hiveService.reviews;
      final cached = CachedData(
        id: review.id,
        data: review.toMap(),
        cachedAt: DateTime.now(),
        isDirty: false,
      );
      
      await box.put(review.id, cached);
    } catch (e) {
      debugPrint('Error caching review: $e');
    }
  }

  /// Cache multiple reviews
  Future<void> cacheReviews(List<DestinationReview> reviews) async {
    try {
      final box = _hiveService.reviews;
      final now = DateTime.now();
      
      final cachedData = {
        for (var review in reviews)
          review.id: CachedData(
            id: review.id,
            data: review.toMap(),
            cachedAt: now,
            isDirty: false,
          )
      };
      
      await box.putAll(cachedData);
    } catch (e) {
      debugPrint('Error caching reviews: $e');
    }
  }

  /// Update cached review
  Future<void> updateCachedReview(
    DestinationReview review, {
    bool markDirty = false,
  }) async {
    try {
      final box = _hiveService.reviews;
      final existing = box.get(review.id) as CachedData?;
      
      final cached = CachedData(
        id: review.id,
        data: review.toMap(),
        cachedAt: existing?.cachedAt ?? DateTime.now(),
        isDirty: markDirty,
        lastSyncedAt: markDirty ? existing?.lastSyncedAt : DateTime.now(),
      );
      
      await box.put(review.id, cached);
    } catch (e) {
      debugPrint('Error updating cached review: $e');
    }
  }

  /// Delete cached review
  Future<void> deleteCachedReview(String id) async {
    try {
      final box = _hiveService.reviews;
      await box.delete(id);
    } catch (e) {
      debugPrint('Error deleting cached review: $e');
    }
  }

  /// Get dirty reviews (need sync)
  Future<List<DestinationReview>> getDirtyReviews() async {
    try {
      final box = _hiveService.reviews;
      final reviews = <DestinationReview>[];
      
      for (final key in box.keys) {
        final cached = box.get(key) as CachedData?;
        if (cached != null && cached.isDirty) {
          try {
            reviews.add(DestinationReview.fromMap(cached.data));
          } catch (e) {
            debugPrint('Error parsing dirty review $key: $e');
          }
        }
      }
      
      return reviews;
    } catch (e) {
      debugPrint('Error getting dirty reviews: $e');
      return [];
    }
  }

  /// Mark review as synced
  Future<void> markReviewSynced(String id) async {
    try {
      final box = _hiveService.reviews;
      final cached = box.get(id) as CachedData?;
      
      if (cached != null) {
        cached.markSynced();
      }
    } catch (e) {
      debugPrint('Error marking review as synced: $e');
    }
  }

  /// Check if review is cached
  bool isReviewCached(String id) {
    try {
      final box = _hiveService.reviews;
      return box.containsKey(id);
    } catch (e) {
      debugPrint('Error checking if review is cached: $e');
      return false;
    }
  }

  /// Get cache statistics
  Map<String, int> getCacheStats() {
    try {
      final box = _hiveService.reviews;
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
      debugPrint('Error getting cache stats: $e');
      return {
        'total': 0,
        'dirty': 0,
        'valid': 0,
        'invalid': 0,
      };
    }
  }

  /// Search cached reviews by text
  Future<List<DestinationReview>> searchCachedReviews(String query) async {
    try {
      final allReviews = await getAllCachedReviews();
      final lowerQuery = query.toLowerCase();
      
      return allReviews.where((review) {
        return review.title.toLowerCase().contains(lowerQuery) ||
               review.content.toLowerCase().contains(lowerQuery) ||
               review.userName.toLowerCase().contains(lowerQuery);
      }).toList();
    } catch (e) {
      debugPrint('Error searching cached reviews: $e');
      return [];
    }
  }

  /// Get cached reviews by destination
  Future<List<DestinationReview>> getCachedReviewsByDestination(String destinationId) async {
    try {
      final allReviews = await getAllCachedReviews();
      return allReviews.where((review) => review.destinationId == destinationId).toList();
    } catch (e) {
      debugPrint('Error getting cached reviews by destination: $e');
      return [];
    }
  }

  /// Get cached reviews by user
  Future<List<DestinationReview>> getCachedReviewsByUser(String userId) async {
    try {
      final allReviews = await getAllCachedReviews();
      return allReviews.where((review) => review.userId == userId).toList();
    } catch (e) {
      debugPrint('Error getting cached reviews by user: $e');
      return [];
    }
  }

  /// Get cached reviews by minimum rating
  Future<List<DestinationReview>> getCachedReviewsByRating(double minRating) async {
    try {
      final allReviews = await getAllCachedReviews();
      return allReviews.where((review) => review.rating >= minRating).toList();
    } catch (e) {
      debugPrint('Error getting cached reviews by rating: $e');
      return [];
    }
  }

  /// Clear all cached reviews
  Future<void> clearCache() async {
    try {
      final box = _hiveService.reviews;
      await box.clear();
    } catch (e) {
      debugPrint('Error clearing review cache: $e');
    }
  }
}

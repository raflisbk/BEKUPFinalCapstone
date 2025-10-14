import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/models/review_model.dart';
import '../core/utils/logger.dart';

/// Service for managing reviews and ratings - Supabase version
class ReviewService {
  static const String _tag = 'ReviewService';

  final SupabaseClient _supabase = Supabase.instance.client;

  // Table names
  static const String _reviewsTable = 'reviews';
  static const String _reviewHelpfulTable = 'review_helpful';

  /// Submit a review
  Future<String?> submitReview({
    required String reviewerId,
    required String targetId,
    required String targetType, // 'user', 'destination', 'trip'
    required double rating,
    required String content,
    List<String>? imageUrls,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      AppLogger.debug(_tag, 'Submitting review', {
        'reviewerId': reviewerId,
        'targetId': targetId,
        'targetType': targetType,
        'rating': rating,
      });

      // Check if user already reviewed this target
      final existingReview = await _supabase
          .from(_reviewsTable)
          .select('id')
          .eq('reviewer_id', reviewerId)
          .eq('target_id', targetId)
          .eq('target_type', targetType)
          .maybeSingle();

      if (existingReview != null) {
        AppLogger.warning(_tag, 'User already reviewed this target');
        return null;
      }

      final response = await _supabase
          .from(_reviewsTable)
          .insert({
            'reviewer_id': reviewerId,
            'target_id': targetId,
            'target_type': targetType,
            'rating': rating,
            'content': content,
            'image_urls': imageUrls ?? [],
            'metadata': metadata ?? {},
            'helpful_count': 0,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select('id')
          .single();

      final reviewId = response['id'] as String;

      // Update target's average rating
      await _updateTargetRating(targetId, targetType);

      AppLogger.success(_tag, 'Review submitted successfully', {
        'reviewId': reviewId,
      });

      return reviewId;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to submit review', e, stackTrace);
      return null;
    }
  }

  /// Get reviews for a target
  Future<List<Review>> getReviews({
    required String targetId,
    required String targetType,
    int limit = 20,
    int offset = 0,
    String? sortBy = 'created_at', // 'created_at', 'rating', 'helpful_count'
    bool ascending = false,
  }) async {
    try {
      AppLogger.debug(_tag, 'Fetching reviews', {
        'targetId': targetId,
        'targetType': targetType,
        'limit': limit,
        'offset': offset,
      });

      final response = await _supabase
          .from(_reviewsTable)
          .select()
          .eq('target_id', targetId)
          .eq('target_type', targetType)
          .order(sortBy, ascending: ascending)
          .range(offset, offset + limit - 1);

      final reviews = response
          .map((data) => Review.fromSupabase(data))
          .toList();

      AppLogger.success(_tag, 'Reviews fetched successfully', {
        'count': reviews.length,
      });

      return reviews;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to fetch reviews', e, stackTrace);
      return [];
    }
  }

  /// Get review by ID
  Future<Review?> getReviewById(String reviewId) async {
    try {
      final response = await _supabase
          .from(_reviewsTable)
          .select()
          .eq('id', reviewId)
          .maybeSingle();

      if (response == null) {
        AppLogger.warning(_tag, 'Review not found', {'reviewId': reviewId});
        return null;
      }

      return Review.fromSupabase(response);
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to fetch review by ID', e, stackTrace);
      return null;
    }
  }

  /// Update a review
  Future<bool> updateReview({
    required String reviewId,
    required String reviewerId,
    double? rating,
    String? content,
    List<String>? imageUrls,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      AppLogger.debug(_tag, 'Updating review', {
        'reviewId': reviewId,
        'reviewerId': reviewerId,
      });

      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (rating != null) updates['rating'] = rating;
      if (content != null) updates['content'] = content;
      if (imageUrls != null) updates['image_urls'] = imageUrls;
      if (metadata != null) updates['metadata'] = metadata;

      await _supabase
          .from(_reviewsTable)
          .update(updates)
          .eq('id', reviewId)
          .eq('reviewer_id', reviewerId);

      // Update target's average rating if rating changed
      if (rating != null) {
        final review = await getReviewById(reviewId);
        if (review != null) {
          await _updateTargetRating(review.targetId, review.targetType);
        }
      }

      AppLogger.success(_tag, 'Review updated successfully');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to update review', e, stackTrace);
      return false;
    }
  }

  /// Delete a review
  Future<bool> deleteReview({
    required String reviewId,
    required String reviewerId,
  }) async {
    try {
      AppLogger.debug(_tag, 'Deleting review', {
        'reviewId': reviewId,
        'reviewerId': reviewerId,
      });

      // Get review details before deletion for rating update
      final review = await getReviewById(reviewId);

      await _supabase
          .from(_reviewsTable)
          .delete()
          .eq('id', reviewId)
          .eq('reviewer_id', reviewerId);

      // Update target's average rating
      if (review != null) {
        await _updateTargetRating(review.targetId, review.targetType);
      }

      AppLogger.success(_tag, 'Review deleted successfully');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to delete review', e, stackTrace);
      return false;
    }
  }

  /// Mark review as helpful
  Future<bool> markReviewHelpful({
    required String reviewId,
    required String userId,
  }) async {
    try {
      AppLogger.debug(_tag, 'Marking review as helpful', {
        'reviewId': reviewId,
        'userId': userId,
      });

      await _supabase
          .from(_reviewHelpfulTable)
          .upsert({
            'review_id': reviewId,
            'user_id': userId,
            'created_at': DateTime.now().toIso8601String(),
          });

      // Update helpful count
      await _supabase.rpc('increment_review_helpful', params: {
        'review_id': reviewId,
      });

      AppLogger.success(_tag, 'Review marked as helpful');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to mark review as helpful', e, stackTrace);
      return false;
    }
  }

  /// Remove helpful mark from review
  Future<bool> removeHelpfulMark({
    required String reviewId,
    required String userId,
  }) async {
    try {
      await _supabase
          .from(_reviewHelpfulTable)
          .delete()
          .eq('review_id', reviewId)
          .eq('user_id', userId);

      // Update helpful count
      await _supabase.rpc('decrement_review_helpful', params: {
        'review_id': reviewId,
      });

      AppLogger.success(_tag, 'Helpful mark removed');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to remove helpful mark', e, stackTrace);
      return false;
    }
  }

  /// Get review statistics for a target
  Future<Map<String, dynamic>> getReviewStats({
    required String targetId,
    required String targetType,
  }) async {
    try {
      final response = await _supabase.rpc('get_review_stats', params: {
        'target_id': targetId,
        'target_type': targetType,
      });

      return {
        'average_rating': response['average_rating'] ?? 0.0,
        'total_reviews': response['total_reviews'] ?? 0,
        'rating_distribution': response['rating_distribution'] ?? {},
      };
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get review stats', e, stackTrace);
      return {
        'average_rating': 0.0,
        'total_reviews': 0,
        'rating_distribution': {},
      };
    }
  }

  /// Get user's reviews
  Future<List<Review>> getUserReviews({
    required String userId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from(_reviewsTable)
          .select()
          .eq('reviewer_id', userId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return response
          .map((data) => Review.fromSupabase(data))
          .toList();
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get user reviews', e, stackTrace);
      return [];
    }
  }

  /// Check if user has reviewed a target
  Future<bool> hasUserReviewed({
    required String userId,
    required String targetId,
    required String targetType,
  }) async {
    try {
      final response = await _supabase
          .from(_reviewsTable)
          .select('id')
          .eq('reviewer_id', userId)
          .eq('target_id', targetId)
          .eq('target_type', targetType)
          .maybeSingle();

      return response != null;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to check if user reviewed', e, stackTrace);
      return false;
    }
  }

  /// Get user's review for a specific target
  Future<Review?> getUserReviewForTarget({
    required String userId,
    required String targetId,
    required String targetType,
  }) async {
    try {
      final response = await _supabase
          .from(_reviewsTable)
          .select()
          .eq('reviewer_id', userId)
          .eq('target_id', targetId)
          .eq('target_type', targetType)
          .maybeSingle();

      if (response == null) return null;

      return Review.fromSupabase(response);
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get user review for target', e, stackTrace);
      return null;
    }
  }

  /// Get recent reviews
  Future<List<Review>> getRecentReviews({
    int limit = 10,
    String? targetType,
  }) async {
    try {
      var query = _supabase
          .from(_reviewsTable)
          .select();

      if (targetType != null) {
        query = query.eq('target_type', targetType);
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);

      return response
          .map((data) => Review.fromSupabase(data))
          .toList();
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get recent reviews', e, stackTrace);
      return [];
    }
  }

  /// Upload review photos
  Future<List<String>> uploadReviewPhotos(List<String> imagePaths) async {
    try {
      AppLogger.debug(_tag, 'Uploading review photos', {'count': imagePaths.length});
      
      final List<String> photoUrls = [];
      
      for (int i = 0; i < imagePaths.length; i++) {
        final fileName = 'review_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        
        // For now, return mock URLs - implement actual upload later
        photoUrls.add('https://example.com/reviews/$fileName');
      }
      
      return photoUrls;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to upload review photos', e, stackTrace);
      return [];
    }
  }

  /// Get reviews stream for real-time updates
  Stream<List<Review>> getReviewsStream({
    required String targetId,
    required String targetType,
    int limit = 20,
  }) {
    try {
      return _supabase
          .from(_reviewsTable)
          .stream(primaryKey: ['id']).map((data) {
            final filtered = data.where((json) => 
              json['target_id'] == targetId && 
              json['target_type'] == targetType
            ).toList();
            
            filtered.sort((a, b) => DateTime.parse(b['created_at'] ?? '').compareTo(DateTime.parse(a['created_at'] ?? '')));
            
            return filtered.take(limit).map((json) => Review.fromMap(json)).toList();
          });
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get reviews stream', e, stackTrace);
      return Stream.value([]);
    }
  }

  /// Get rating summary stream
  Stream<RatingSummary> getRatingSummaryStream({
    required String targetId,
    required String targetType,
  }) {
    try {
      return _supabase
          .from(_reviewsTable)
          .stream(primaryKey: ['id']).map((data) {
        final filtered = data.where((json) => 
          json['target_id'] == targetId && 
          json['target_type'] == targetType
        ).toList();
        
        if (filtered.isEmpty) {
          return RatingSummary(
            destinationId: targetId,
            averageRating: 0.0,
            totalReviews: 0,
            ratingDistribution: <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
          );
        }
        
        final reviews = filtered.map((json) => Review.fromMap(json)).toList();
        final totalReviews = reviews.length;
        final totalRating = reviews.fold<double>(0.0, (sum, review) => sum + review.rating);
        final averageRating = totalRating / totalReviews;
        
        final ratingDistribution = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
        for (final review in reviews) {
          final rating = review.rating.round();
          ratingDistribution[rating] = (ratingDistribution[rating] ?? 0) + 1;
        }
        
        return RatingSummary(
          destinationId: targetId,
          averageRating: averageRating,
          totalReviews: totalReviews,
          ratingDistribution: ratingDistribution,
        );
      });
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get rating summary stream', e, stackTrace);
      return Stream.value(RatingSummary(
        destinationId: targetId,
        averageRating: 0.0,
        totalReviews: 0,
        ratingDistribution: <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
      ));
    }
  }

  /// Toggle helpful status of a review
  Future<bool> toggleHelpful({
    required String reviewId,
    required String userId,
  }) async {
    try {
      AppLogger.debug(_tag, 'Toggling helpful status', {
        'reviewId': reviewId,
        'userId': userId,
      });

      // Check if user already marked as helpful
      final existing = await _supabase
          .from(_reviewHelpfulTable)
          .select()
          .eq('review_id', reviewId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existing != null) {
        // Remove helpful mark
        await _supabase
            .from(_reviewHelpfulTable)
            .delete()
            .eq('review_id', reviewId)
            .eq('user_id', userId);
      } else {
        // Add helpful mark
        await _supabase.from(_reviewHelpfulTable).insert({
          'review_id': reviewId,
          'user_id': userId,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to toggle helpful status', e, stackTrace);
      return false;
    }
  }

  /// Private method to update target's average rating
  Future<void> _updateTargetRating(String targetId, String targetType) async {
    try {
      await _supabase.rpc('update_target_rating', params: {
        'target_id': targetId,
        'target_type': targetType,
      });
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to update target rating', e, stackTrace);
    }
  }
}

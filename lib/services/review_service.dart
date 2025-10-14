import 'dart:async';
import '../core/utils/logger.dart';
import 'supabase_config.dart';
import 'supabase_database_service.dart';
import 'content_moderation_service.dart';

/// Review Service
/// Handles user reviews, ratings, and feedback for destinations, accommodations, and activities
class ReviewService {
  static const String _tag = 'ReviewService';
  static const String _reviewsTable = 'reviews';
  static const String _reviewLikesTable = 'review_likes';
  static const String _reviewReportsTable = 'review_reports';
  static const String _reviewStatisticsTable = 'review_statistics';

  // Singleton pattern
  static ReviewService? _instance;
  static ReviewService get instance => _instance ??= ReviewService._internal();
  
  ReviewService._internal();

  // Content moderation service instance
  late final ContentModerationService _moderationService = ContentModerationService.instance;

  // Review types
  static const String typeDestination = 'destination';
  static const String typeAccommodation = 'accommodation';
  static const String typeActivity = 'activity';
  static const String typeRestaurant = 'restaurant';
  static const String typeTransport = 'transport';
  static const String typeGuide = 'guide';
  static const String typeTrip = 'trip';

  // Review status
  static const String statusPending = 'pending';
  static const String statusApproved = 'approved';
  static const String statusRejected = 'rejected';
  static const String statusFlagged = 'flagged';

  // ===============================
  // REVIEW MANAGEMENT
  // ===============================

  /// Create new review
  Future<Map<String, dynamic>> createReview({
    required String entityId,
    required String entityType,
    required double rating,
    required String title,
    required String content,
    List<String>? pros,
    List<String>? cons,
    List<String>? tags,
    List<String>? imageUrls,
    Map<String, dynamic>? metadata,
    bool skipModeration = false,
  }) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Creating review for $entityType: $entityId');

      // Validate rating
      if (rating < 1.0 || rating > 5.0) {
        throw Exception('Rating must be between 1.0 and 5.0');
      }

      // Check if user already reviewed this entity
      final existingReviews = await SupabaseDatabaseService.select(
        table: _reviewsTable,
        filters: {
          'entity_id': entityId,
          'entity_type': entityType,
          'user_id': userId,
          'is_active': true,
        },
      );

      if (existingReviews.isNotEmpty) {
        throw Exception('You have already reviewed this ${entityType.toLowerCase()}');
      }

      // Moderate content if not skipped
      String status = statusApproved;
      if (!skipModeration) {
        final moderationResult = await _moderationService.moderateTextContent(
          content: '$title\n$content',
          contentType: 'review',
          userId: userId,
          metadata: {'entity_id': entityId, 'entity_type': entityType},
        );

        if (moderationResult['action'] == 'block') {
          status = statusRejected;
        } else if (moderationResult['action'] == 'flag') {
          status = statusFlagged;
        }
      }

      // Create review
      final reviewData = {
        'entity_id': entityId,
        'entity_type': entityType,
        'user_id': userId,
        'rating': rating,
        'title': title,
        'content': content,
        'pros': pros ?? [],
        'cons': cons ?? [],
        'tags': tags ?? [],
        'image_urls': imageUrls ?? [],
        'metadata': metadata ?? {},
        'status': status,
        'like_count': 0,
        'dislike_count': 0,
        'helpful_count': 0,
        'is_verified': false,
        'is_active': true,
      };

      final review = await SupabaseDatabaseService.insert(
        table: _reviewsTable,
        data: reviewData,
      );

      // Update entity statistics
      await _updateEntityStatistics(entityId, entityType);

      AppLogger.success(_tag, 'Review created successfully: ${review['id']}');
      return review;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to create review', e, stackTrace);
      rethrow;
    }
  }

  /// Get reviews for entity
  static Future<List<Map<String, dynamic>>> getEntityReviews({
    required String entityId,
    required String entityType,
    String? sortBy, // 'newest', 'oldest', 'rating_high', 'rating_low', 'helpful'
    int? minRating,
    int? maxRating,
    List<String>? tags,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      AppLogger.debug(_tag, 'Getting reviews for $entityType: $entityId');

      // Build filters
      final filters = {
        'entity_id': entityId,
        'entity_type': entityType,
        'status': statusApproved,
        'is_active': true,
      };

      var reviews = await SupabaseDatabaseService.select(
        table: _reviewsTable,
        filters: filters,
        orderBy: _getSortField(sortBy),
        ascending: _getSortOrder(sortBy),
        limit: limit + offset,
      );

      // Apply additional filters
      if (minRating != null) {
        reviews = reviews.where((r) => (r['rating'] as double) >= minRating).toList();
      }

      if (maxRating != null) {
        reviews = reviews.where((r) => (r['rating'] as double) <= maxRating).toList();
      }

      if (tags != null && tags.isNotEmpty) {
        reviews = reviews.where((review) {
          final reviewTags = List<String>.from(review['tags'] ?? []);
          return tags.any((tag) => reviewTags.contains(tag));
        }).toList();
      }

      // Apply offset and limit
      reviews = reviews.skip(offset).take(limit).toList();

      // Enrich reviews with user data and like status
      for (final review in reviews) {
        review['user_data'] = await _getUserData(review['user_id']);
        review['liked_by_current_user'] = await _isLikedByUser(review['id']);
      }

      AppLogger.success(_tag, 'Retrieved ${reviews.length} reviews');
      return reviews;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get entity reviews', e, stackTrace);
      rethrow;
    }
  }

  /// Get user reviews
  static Future<List<Map<String, dynamic>>> getUserReviews({
    String? userId,
    String? entityType,
    String? status,
    int limit = 20,
  }) async {
    try {
      final currentUserId = userId ?? SupabaseConfig.userId;
      if (currentUserId == null) {
        throw Exception('No user ID provided');
      }

      AppLogger.debug(_tag, 'Getting reviews for user: $currentUserId');

      final filters = <String, dynamic>{
        'user_id': currentUserId,
        'is_active': true,
      };

      if (entityType != null) filters['entity_type'] = entityType;
      if (status != null) filters['status'] = status;

      final reviews = await SupabaseDatabaseService.select(
        table: _reviewsTable,
        filters: filters,
        orderBy: 'created_at',
        ascending: false,
        limit: limit,
      );

      // Enrich with entity data
      for (final review in reviews) {
        review['entity_data'] = await _getEntityData(
          review['entity_id'],
          review['entity_type'],
        );
      }

      AppLogger.success(_tag, 'Retrieved ${reviews.length} user reviews');
      return reviews;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get user reviews', e, stackTrace);
      rethrow;
    }
  }

  /// Update review
  static Future<Map<String, dynamic>> updateReview({
    required String reviewId,
    double? rating,
    String? title,
    String? content,
    List<String>? pros,
    List<String>? cons,
    List<String>? tags,
    List<String>? imageUrls,
  }) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Updating review: $reviewId');

      // Get review to verify ownership
      final reviews = await SupabaseDatabaseService.select(
        table: _reviewsTable,
        filters: {'id': reviewId},
      );

      if (reviews.isEmpty) {
        throw Exception('Review not found');
      }

      final review = reviews.first;
      if (review['user_id'] != userId) {
        throw Exception('Not authorized to update this review');
      }

      // Build update data
      final updateData = <String, dynamic>{};
      
      if (rating != null) {
        if (rating < 1.0 || rating > 5.0) {
          throw Exception('Rating must be between 1.0 and 5.0');
        }
        updateData['rating'] = rating;
      }
      
      if (title != null) updateData['title'] = title;
      if (content != null) updateData['content'] = content;
      if (pros != null) updateData['pros'] = pros;
      if (cons != null) updateData['cons'] = cons;
      if (tags != null) updateData['tags'] = tags;
      if (imageUrls != null) updateData['image_urls'] = imageUrls;

      if (updateData.isEmpty) {
        throw Exception('No data provided for update');
      }

      // Re-moderate if content changed
      if (title != null || content != null) {
        final moderationResult = await ContentModerationService.moderateTextContent(
          content: '${title ?? review['title']}\n${content ?? review['content']}',
          contentType: 'review',
          contentId: reviewId,
          userId: userId,
        );

        if (moderationResult['action'] == 'block') {
          updateData['status'] = statusRejected;
        } else if (moderationResult['action'] == 'flag') {
          updateData['status'] = statusFlagged;
        } else {
          updateData['status'] = statusApproved;
        }
      }

      updateData['updated_at'] = DateTime.now().toIso8601String();

      final result = await SupabaseDatabaseService.update(
        table: _reviewsTable,
        id: reviewId,
        data: updateData,
      );

      // Update entity statistics if rating changed
      if (rating != null) {
        await _updateEntityStatistics(review['entity_id'], review['entity_type']);
      }

      AppLogger.success(_tag, 'Review updated successfully');
      return result;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to update review', e, stackTrace);
      rethrow;
    }
  }

  /// Delete review
  static Future<void> deleteReview(String reviewId) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.warning(_tag, 'Deleting review: $reviewId');

      // Get review to verify ownership
      final reviews = await SupabaseDatabaseService.select(
        table: _reviewsTable,
        filters: {'id': reviewId},
      );

      if (reviews.isEmpty) {
        throw Exception('Review not found');
      }

      final review = reviews.first;
      if (review['user_id'] != userId) {
        throw Exception('Not authorized to delete this review');
      }

      // Soft delete
      await SupabaseDatabaseService.update(
        table: _reviewsTable,
        id: reviewId,
        data: {
          'is_active': false,
          'deleted_at': DateTime.now().toIso8601String(),
        },
      );

      // Update entity statistics
      await _updateEntityStatistics(review['entity_id'], review['entity_type']);

      AppLogger.success(_tag, 'Review deleted successfully');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to delete review', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // REVIEW INTERACTIONS
  // ===============================

  /// Like/unlike review
  static Future<Map<String, dynamic>> toggleReviewLike(String reviewId) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Toggling like for review: $reviewId');

      // Check if already liked
      final existingLikes = await SupabaseDatabaseService.select(
        table: _reviewLikesTable,
        filters: {'review_id': reviewId, 'user_id': userId},
      );

      bool isLiked;
      if (existingLikes.isNotEmpty) {
        // Unlike
        await SupabaseDatabaseService.delete(
          table: _reviewLikesTable,
          id: existingLikes.first['id'],
        );
        isLiked = false;
      } else {
        // Like
        await SupabaseDatabaseService.insert(
          table: _reviewLikesTable,
          data: {
            'review_id': reviewId,
            'user_id': userId,
          },
        );
        isLiked = true;
      }

      // Update like count
      await _updateReviewLikeCount(reviewId);

      AppLogger.success(_tag, 'Review like toggled: $isLiked');
      return {
        'review_id': reviewId,
        'is_liked': isLiked,
        'like_count': await _getReviewLikeCount(reviewId),
      };
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to toggle review like', e, stackTrace);
      rethrow;
    }
  }

  /// Mark review as helpful
  static Future<void> markReviewHelpful(String reviewId) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Marking review as helpful: $reviewId');

      // Get current review
      final reviews = await SupabaseDatabaseService.select(
        table: _reviewsTable,
        filters: {'id': reviewId},
      );

      if (reviews.isEmpty) {
        throw Exception('Review not found');
      }

      final review = reviews.first;
      final currentCount = review['helpful_count'] as int? ?? 0;

      // Update helpful count
      await SupabaseDatabaseService.update(
        table: _reviewsTable,
        id: reviewId,
        data: {'helpful_count': currentCount + 1},
      );

      AppLogger.success(_tag, 'Review marked as helpful');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to mark review as helpful', e, stackTrace);
      rethrow;
    }
  }

  /// Report review
  static Future<Map<String, dynamic>> reportReview({
    required String reviewId,
    required String reason,
    String? description,
  }) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.warning(_tag, 'Reporting review: $reviewId');

      final reportData = {
        'review_id': reviewId,
        'reported_by': userId,
        'reason': reason,
        'description': description,
        'status': 'pending',
      };

      final report = await SupabaseDatabaseService.insert(
        table: _reviewReportsTable,
        data: reportData,
      );

      // Also report to content moderation service
      await ContentModerationService.reportContent(
        contentId: reviewId,
        contentType: 'review',
        reason: reason,
        description: description,
      );

      AppLogger.success(_tag, 'Review reported successfully');
      return report;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to report review', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // STATISTICS & ANALYTICS
  // ===============================

  /// Get entity review statistics
  static Future<Map<String, dynamic>> getEntityStatistics({
    required String entityId,
    required String entityType,
  }) async {
    try {
      AppLogger.debug(_tag, 'Getting review statistics for $entityType: $entityId');

      // Check if statistics exist
      final existingStats = await SupabaseDatabaseService.select(
        table: _reviewStatisticsTable,
        filters: {'entity_id': entityId, 'entity_type': entityType},
      );

      if (existingStats.isNotEmpty) {
        final stats = existingStats.first;
        
        // Check if stats are recent (less than 1 hour old)
        final lastUpdated = DateTime.parse(stats['updated_at']);
        if (DateTime.now().difference(lastUpdated).inHours < 1) {
          return stats;
        }
      }

      // Calculate fresh statistics
      return await _calculateEntityStatistics(entityId, entityType);
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get entity statistics', e, stackTrace);
      rethrow;
    }
  }

  /// Get review trends
  static Future<Map<String, dynamic>> getReviewTrends({
    String? entityId,
    String? entityType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      AppLogger.debug(_tag, 'Getting review trends');

      final filters = <String, dynamic>{
        'status': statusApproved,
        'is_active': true,
      };

      if (entityId != null) filters['entity_id'] = entityId;
      if (entityType != null) filters['entity_type'] = entityType;

      var reviews = await SupabaseDatabaseService.select(
        table: _reviewsTable,
        filters: filters,
      );

      // Filter by date range
      if (startDate != null || endDate != null) {
        reviews = reviews.where((review) {
          final createdAt = DateTime.parse(review['created_at']);
          if (startDate != null && createdAt.isBefore(startDate)) return false;
          if (endDate != null && createdAt.isAfter(endDate)) return false;
          return true;
        }).toList();
      }

      // Calculate trends
      final ratingDistribution = <int, int>{};
      final monthlyTrends = <String, int>{};
      final tagFrequency = <String, int>{};

      for (final review in reviews) {
        // Rating distribution
        final rating = (review['rating'] as double).round();
        ratingDistribution[rating] = (ratingDistribution[rating] ?? 0) + 1;

        // Monthly trends
        final createdAt = DateTime.parse(review['created_at']);
        final monthKey = '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}';
        monthlyTrends[monthKey] = (monthlyTrends[monthKey] ?? 0) + 1;

        // Tag frequency
        final tags = List<String>.from(review['tags'] ?? []);
        for (final tag in tags) {
          tagFrequency[tag] = (tagFrequency[tag] ?? 0) + 1;
        }
      }

      final averageRating = reviews.isNotEmpty
          ? reviews.map((r) => r['rating'] as double).reduce((a, b) => a + b) / reviews.length
          : 0.0;

      return {
        'total_reviews': reviews.length,
        'average_rating': averageRating,
        'rating_distribution': ratingDistribution,
        'monthly_trends': monthlyTrends,
        'tag_frequency': tagFrequency,
        'period': {
          'start_date': startDate?.toIso8601String(),
          'end_date': endDate?.toIso8601String(),
        },
      };
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get review trends', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // PRIVATE HELPER METHODS
  // ===============================

  /// Get sort field for reviews
  static String _getSortField(String? sortBy) {
    switch (sortBy) {
      case 'newest':
        return 'created_at';
      case 'oldest':
        return 'created_at';
      case 'rating_high':
      case 'rating_low':
        return 'rating';
      case 'helpful':
        return 'helpful_count';
      default:
        return 'created_at';
    }
  }

  /// Get sort order for reviews
  static bool _getSortOrder(String? sortBy) {
    switch (sortBy) {
      case 'oldest':
      case 'rating_low':
        return true; // ascending
      default:
        return false; // descending
    }
  }

  /// Get user data for review
  static Future<Map<String, dynamic>> _getUserData(String userId) async {
    try {
      // This would normally fetch from user service
      // For now, returning placeholder data
      return {
        'id': userId,
        'name': 'User Name',
        'avatar_url': null,
        'is_verified': false,
        'review_count': 0,
      };
    } catch (e) {
      return {
        'id': userId,
        'name': 'Anonymous User',
        'avatar_url': null,
        'is_verified': false,
        'review_count': 0,
      };
    }
  }

  /// Get entity data for review
  static Future<Map<String, dynamic>> _getEntityData(String entityId, String entityType) async {
    try {
      // This would normally fetch from appropriate service
      // For now, returning placeholder data
      return {
        'id': entityId,
        'type': entityType,
        'name': 'Entity Name',
        'image_url': null,
      };
    } catch (e) {
      return {
        'id': entityId,
        'type': entityType,
        'name': 'Unknown Entity',
        'image_url': null,
      };
    }
  }

  /// Check if review is liked by current user
  static Future<bool> _isLikedByUser(String reviewId) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) return false;

      final likes = await SupabaseDatabaseService.select(
        table: _reviewLikesTable,
        filters: {'review_id': reviewId, 'user_id': userId},
      );

      return likes.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Update review like count
  static Future<void> _updateReviewLikeCount(String reviewId) async {
    try {
      final likeCount = await _getReviewLikeCount(reviewId);
      
      await SupabaseDatabaseService.update(
        table: _reviewsTable,
        id: reviewId,
        data: {'like_count': likeCount},
      );
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to update like count', e);
    }
  }

  /// Get review like count
  static Future<int> _getReviewLikeCount(String reviewId) async {
    try {
      final likes = await SupabaseDatabaseService.select(
        table: _reviewLikesTable,
        filters: {'review_id': reviewId},
      );

      return likes.length;
    } catch (e) {
      return 0;
    }
  }

  /// Update entity statistics
  static Future<void> _updateEntityStatistics(String entityId, String entityType) async {
    try {
      AppLogger.debug(_tag, 'Updating statistics for $entityType: $entityId');
      
      final stats = await _calculateEntityStatistics(entityId, entityType);
      
      // Save or update statistics
      final existingStats = await SupabaseDatabaseService.select(
        table: _reviewStatisticsTable,
        filters: {'entity_id': entityId, 'entity_type': entityType},
      );

      if (existingStats.isNotEmpty) {
        await SupabaseDatabaseService.update(
          table: _reviewStatisticsTable,
          id: existingStats.first['id'],
          data: stats,
        );
      } else {
        await SupabaseDatabaseService.insert(
          table: _reviewStatisticsTable,
          data: stats,
        );
      }
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to update entity statistics', e);
    }
  }

  /// Calculate entity statistics
  static Future<Map<String, dynamic>> _calculateEntityStatistics(String entityId, String entityType) async {
    try {
      final reviews = await SupabaseDatabaseService.select(
        table: _reviewsTable,
        filters: {
          'entity_id': entityId,
          'entity_type': entityType,
          'status': statusApproved,
          'is_active': true,
        },
      );

      if (reviews.isEmpty) {
        return {
          'entity_id': entityId,
          'entity_type': entityType,
          'total_reviews': 0,
          'average_rating': 0.0,
          'rating_distribution': {'1': 0, '2': 0, '3': 0, '4': 0, '5': 0},
          'total_likes': 0,
          'updated_at': DateTime.now().toIso8601String(),
        };
      }

      // Calculate statistics
      final ratings = reviews.map((r) => r['rating'] as double).toList();
      final averageRating = ratings.reduce((a, b) => a + b) / ratings.length;

      final ratingDistribution = <String, int>{'1': 0, '2': 0, '3': 0, '4': 0, '5': 0};
      for (final rating in ratings) {
        final key = rating.round().toString();
        if (ratingDistribution.containsKey(key)) {
          ratingDistribution[key] = ratingDistribution[key]! + 1;
        }
      }

      final totalLikes = reviews.map((r) => r['like_count'] as int? ?? 0).reduce((a, b) => a + b);

      return {
        'entity_id': entityId,
        'entity_type': entityType,
        'total_reviews': reviews.length,
        'average_rating': averageRating,
        'rating_distribution': ratingDistribution,
        'total_likes': totalLikes,
        'updated_at': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to calculate entity statistics', e);
      return {
        'entity_id': entityId,
        'entity_type': entityType,
        'total_reviews': 0,
        'average_rating': 0.0,
        'rating_distribution': {'1': 0, '2': 0, '3': 0, '4': 0, '5': 0},
        'total_likes': 0,
        'updated_at': DateTime.now().toIso8601String(),
      };
    }
  }
}
import 'dart:async';
import '../core/utils/logger.dart';
import '../core/interfaces/i_review_service.dart';
import 'supabase_config.dart';
import 'supabase_database_service.dart';
import 'content_moderation_service.dart';

/// Review Service
/// Handles user reviews, ratings, and feedback for destinations, accommodations, and activities
class ReviewService implements IReviewService {
  static const String _tag = 'ReviewService';
  static const String _reviewsTable = 'reviews';
  static const String _reviewLikesTable = 'review_likes';
  static const String _reviewReportsTable = 'review_reports';
  static const String _reviewStatisticsTable = 'review_statistics';

  // Content moderation service instance
  late final ContentModerationService _moderationService = ContentModerationService.instance;

  /// Helper method for deleting records with multiple filter criteria
  Future<void> _deleteWithFilters({
    required String table,
    required Map<String, dynamic> filters,
  }) async {
    AppLogger.debug(_tag, 'Deleting from $table with filters: $filters');
    
    var query = SupabaseConfig.client.from(table).delete();
    
    filters.forEach((key, value) {
      if (value != null) {
        query = query.eq(key, value);
      }
    });
    
    await query;
    AppLogger.success(_tag, 'Successfully deleted from $table');
  }

  // ===============================
  // REVIEW MANAGEMENT
  // ===============================

  /// Create new review
  @override
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
      String status = IReviewService.statusApproved;
      if (!skipModeration) {
        final moderationResult = await _moderationService.moderateTextContent(
          content: '$title\n$content',
          contentType: 'review',
          userId: userId,
        );

        if (!moderationResult['isClean']) {
          status = IReviewService.statusPending;
          AppLogger.warning(_tag, 'Review content flagged for moderation');
        }
      }

      // Create review data
      final reviewData = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'entity_id': entityId,
        'entity_type': entityType,
        'user_id': userId,
        'rating': rating,
        'title': title,
        'content': content,
        'pros': pros,
        'cons': cons,
        'tags': tags,
        'image_urls': imageUrls,
        'metadata': metadata,
        'status': status,
        'like_count': 0,
        'helpful_count': 0,
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Insert review
      final result = await SupabaseDatabaseService.insert(
        table: _reviewsTable,
        data: reviewData,
      );

      // Update entity statistics
      await _updateEntityStatistics(entityId, entityType);

      AppLogger.info(_tag, 'Review created successfully: ${result['id']}');
      return result;

    } catch (e) {
      AppLogger.error(_tag, 'Error creating review: $e');
      rethrow;
    }
  }

  /// Get reviews for a specific entity (destination, accommodation, etc.)
  @override
  Future<List<Map<String, dynamic>>> getEntityReviews({
    required String entityId,
    required String entityType,
    String? sortBy,
    String? filterBy,
    int? limit,
    int? offset,
  }) async {
    try {
      AppLogger.debug(_tag, 'Getting reviews for $entityType: $entityId');

      Map<String, dynamic> filters = {
        'entity_id': entityId,
        'entity_type': entityType,
        'is_active': true,
      };

      // Add status filter for approved reviews by default
      if (filterBy == null || filterBy.isEmpty) {
        filters['status'] = IReviewService.statusApproved;
      } else {
        filters['status'] = filterBy;
      }

      final reviews = await SupabaseDatabaseService.select(
        table: _reviewsTable,
        filters: filters,
        orderBy: sortBy ?? 'created_at',
        ascending: false,
        limit: limit,
        offset: offset,
      );

      // Enrich reviews with user and like information
      final enrichedReviews = <Map<String, dynamic>>[];
      for (final review in reviews) {
        final enrichedReview = Map<String, dynamic>.from(review);
        
        // Get user data
        final userData = await _getUserData(review['user_id']);
        enrichedReview['user'] = userData;
        
        // Check if current user liked this review
        enrichedReview['is_liked'] = await _isLikedByUser(review['id']);
        
        enrichedReviews.add(enrichedReview);
      }

      AppLogger.info(_tag, 'Found ${enrichedReviews.length} reviews');
      return enrichedReviews;

    } catch (e) {
      AppLogger.error(_tag, 'Error getting entity reviews: $e');
      rethrow;
    }
  }

  /// Get reviews written by a specific user
  @override
  Future<List<Map<String, dynamic>>> getUserReviews({
    required String userId,
    String? entityType,
    String? status,
    int? limit,
    int? offset,
  }) async {
    try {
      AppLogger.debug(_tag, 'Getting reviews for user: $userId');

      Map<String, dynamic> filters = {
        'user_id': userId,
        'is_active': true,
      };

      if (entityType != null) {
        filters['entity_type'] = entityType;
      }

      if (status != null) {
        filters['status'] = status;
      }

      final reviews = await SupabaseDatabaseService.select(
        table: _reviewsTable,
        filters: filters,
        orderBy: 'created_at',
        ascending: false,
        limit: limit,
        offset: offset,
      );

      // Enrich reviews with entity information
      final enrichedReviews = <Map<String, dynamic>>[];
      for (final review in reviews) {
        final enrichedReview = Map<String, dynamic>.from(review);
        
        // Get entity data
        final entityData = await _getEntityData(review['entity_id'], review['entity_type']);
        enrichedReview['entity'] = entityData;
        
        enrichedReviews.add(enrichedReview);
      }

      AppLogger.info(_tag, 'Found ${enrichedReviews.length} user reviews');
      return enrichedReviews;

    } catch (e) {
      AppLogger.error(_tag, 'Error getting user reviews: $e');
      rethrow;
    }
  }

  /// Update an existing review
  @override
  Future<Map<String, dynamic>> updateReview({
    required String reviewId,
    String? title,
    String? content,
    double? rating,
    List<String>? pros,
    List<String>? cons,
    List<String>? tags,
    List<String>? imageUrls,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Updating review: $reviewId');

      // Check if review exists and belongs to user
      final existingReviews = await SupabaseDatabaseService.select(
        table: _reviewsTable,
        filters: {'id': reviewId},
      );

      if (existingReviews.isEmpty) {
        throw Exception('Review not found');
      }

      final existingReview = existingReviews.first;

      if (existingReview['user_id'] != userId) {
        throw Exception('You can only update your own reviews');
      }

      // Validate rating if provided
      if (rating != null && (rating < 1.0 || rating > 5.0)) {
        throw Exception('Rating must be between 1.0 and 5.0');
      }

      // Prepare update data
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (title != null) updateData['title'] = title;
      if (content != null) updateData['content'] = content;
      if (rating != null) updateData['rating'] = rating;
      if (pros != null) updateData['pros'] = pros;
      if (cons != null) updateData['cons'] = cons;
      if (tags != null) updateData['tags'] = tags;
      if (imageUrls != null) updateData['image_urls'] = imageUrls;
      if (metadata != null) updateData['metadata'] = metadata;

      // Moderate content if title or content changed
      if (title != null || content != null) {
        final moderationContent = '${title ?? existingReview['title']}\n${content ?? existingReview['content']}';
        final moderationResult = await _moderationService.moderateTextContent(
          content: moderationContent,
          contentType: 'review',
          userId: userId,
        );

        if (!moderationResult['isClean']) {
          updateData['status'] = IReviewService.statusPending;
          AppLogger.warning(_tag, 'Updated review content flagged for moderation');
        }
      }

      // Update review
      final result = await SupabaseDatabaseService.update(
        table: _reviewsTable,
        id: reviewId,
        data: updateData,
      );

      // Update entity statistics if rating changed
      if (rating != null) {
        await _updateEntityStatistics(existingReview['entity_id'], existingReview['entity_type']);
      }

      AppLogger.info(_tag, 'Review updated successfully: $reviewId');
      return result;

    } catch (e) {
      AppLogger.error(_tag, 'Error updating review: $e');
      rethrow;
    }
  }

  /// Delete a review
  @override
  Future<void> deleteReview(String reviewId) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Deleting review: $reviewId');

      // Check if review exists and belongs to user
      final existingReviews = await SupabaseDatabaseService.select(
        table: _reviewsTable,
        filters: {'id': reviewId},
      );

      if (existingReviews.isEmpty) {
        throw Exception('Review not found');
      }

      final existingReview = existingReviews.first;

      if (existingReview['user_id'] != userId) {
        throw Exception('You can only delete your own reviews');
      }

      // Soft delete - mark as inactive
      await SupabaseDatabaseService.update(
        table: _reviewsTable,
        id: reviewId,
        data: {
          'is_active': false,
          'updated_at': DateTime.now().toIso8601String(),
        },
      );

      // Delete associated likes
      await _deleteWithFilters(
        table: _reviewLikesTable,
        filters: {'review_id': reviewId},
      );

      // Update entity statistics
      await _updateEntityStatistics(existingReview['entity_id'], existingReview['entity_type']);

      AppLogger.info(_tag, 'Review deleted successfully: $reviewId');

    } catch (e) {
      AppLogger.error(_tag, 'Error deleting review: $e');
      rethrow;
    }
  }

  // ===============================
  // REVIEW INTERACTIONS
  // ===============================

  /// Toggle like/unlike on a review
  @override
  Future<Map<String, dynamic>> toggleReviewLike(String reviewId) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Toggling like for review: $reviewId');

      // Check if user already liked this review
      final existingLike = await SupabaseDatabaseService.select(
        table: _reviewLikesTable,
        filters: {
          'review_id': reviewId,
          'user_id': userId,
        },
      );

      bool isLiked;
      if (existingLike.isNotEmpty) {
        // Remove like
        await _deleteWithFilters(
          table: _reviewLikesTable,
          filters: {
            'review_id': reviewId,
            'user_id': userId,
          },
        );
        isLiked = false;
      } else {
        // Add like
        await SupabaseDatabaseService.insert(
          table: _reviewLikesTable,
          data: {
            'review_id': reviewId,
            'user_id': userId,
            'created_at': DateTime.now().toIso8601String(),
          },
        );
        isLiked = true;
      }

      // Update like count
      await _updateReviewLikeCount(reviewId);

      final likeCount = await _getReviewLikeCount(reviewId);

      AppLogger.info(_tag, 'Review like toggled: $reviewId (liked: $isLiked)');
      return {
        'is_liked': isLiked,
        'like_count': likeCount,
      };

    } catch (e) {
      AppLogger.error(_tag, 'Error toggling review like: $e');
      rethrow;
    }
  }

  /// Mark a review as helpful
  @override
  Future<void> markReviewHelpful(String reviewId) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Marking review as helpful: $reviewId');

      // Increment helpful count
      final reviews = await SupabaseDatabaseService.select(
        table: _reviewsTable,
        filters: {'id': reviewId},
      );

      if (reviews.isEmpty) {
        throw Exception('Review not found');
      }

      final review = reviews.first;

      final currentCount = review['helpful_count'] ?? 0;
      await SupabaseDatabaseService.update(
        table: _reviewsTable,
        id: reviewId,
        data: {
          'helpful_count': currentCount + 1,
          'updated_at': DateTime.now().toIso8601String(),
        },
      );

      AppLogger.info(_tag, 'Review marked as helpful: $reviewId');

    } catch (e) {
      AppLogger.error(_tag, 'Error marking review as helpful: $e');
      rethrow;
    }
  }

  /// Report a review for inappropriate content
  @override
  Future<Map<String, dynamic>> reportReview({
    required String reviewId,
    required String reason,
    String? description,
  }) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Reporting review: $reviewId');

      // Check if review exists
      final reviews = await SupabaseDatabaseService.select(
        table: _reviewsTable,
        filters: {'id': reviewId},
      );

      if (reviews.isEmpty) {
        throw Exception('Review not found');
      }

      // Create report
      final reportData = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'review_id': reviewId,
        'reporter_id': userId,
        'reason': reason,
        'description': description,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      };

      final result = await SupabaseDatabaseService.insert(
        table: _reviewReportsTable,
        data: reportData,
      );

      // Update review status to flagged if multiple reports
      final reports = await SupabaseDatabaseService.select(
        table: _reviewReportsTable,
        filters: {'review_id': reviewId},
      );

      if (reports.length >= 3) {
        await SupabaseDatabaseService.update(
          table: _reviewsTable,
          id: reviewId,
          data: {
            'status': IReviewService.statusFlagged,
            'updated_at': DateTime.now().toIso8601String(),
          },
        );
      }

      AppLogger.info(_tag, 'Review reported: $reviewId');
      return result;

    } catch (e) {
      AppLogger.error(_tag, 'Error reporting review: $e');
      rethrow;
    }
  }

  // ===============================
  // STATISTICS & ANALYTICS
  // ===============================

  /// Get statistics for a specific entity
  @override
  Future<Map<String, dynamic>> getEntityStatistics({
    required String entityId,
    required String entityType,
  }) async {
    try {
      AppLogger.debug(_tag, 'Getting statistics for $entityType: $entityId');

      // Try to get cached statistics first
      final cachedStats = await SupabaseDatabaseService.select(
        table: _reviewStatisticsTable,
        filters: {
          'entity_id': entityId,
          'entity_type': entityType,
        },
      );

      if (cachedStats.isNotEmpty) {
        final stats = cachedStats.first;
        // Check if statistics are recent (within last hour)
        final updatedAt = DateTime.parse(stats['updated_at']);
        final now = DateTime.now();
        if (now.difference(updatedAt).inHours < 1) {
          return stats;
        }
      }

      // Calculate fresh statistics
      final stats = await _calculateEntityStatistics(entityId, entityType);
      
      AppLogger.info(_tag, 'Entity statistics retrieved');
      return stats;

    } catch (e) {
      AppLogger.error(_tag, 'Error getting entity statistics: $e');
      rethrow;
    }
  }

  /// Get review trends and analytics
  @override
  Future<Map<String, dynamic>> getReviewTrends({
    String? entityType,
    String? timeframe,
    List<String>? entityIds,
  }) async {
    try {
      AppLogger.debug(_tag, 'Getting review trends');

      // Calculate timeframe
      final endDate = DateTime.now();
      DateTime startDate;
      
      switch (timeframe) {
        case 'week':
          startDate = endDate.subtract(const Duration(days: 7));
          break;
        case 'month':
          startDate = endDate.subtract(const Duration(days: 30));
          break;
        case 'year':
          startDate = endDate.subtract(const Duration(days: 365));
          break;
        default:
          startDate = endDate.subtract(const Duration(days: 30));
      }

      // Build filters
      Map<String, dynamic> filters = {
        'is_active': true,
        'status': IReviewService.statusApproved,
      };

      if (entityType != null) {
        filters['entity_type'] = entityType;
      }

      // Get reviews in timeframe
      final reviews = await SupabaseDatabaseService.select(
        table: _reviewsTable,
        filters: filters,
      );

      // Filter by date and entity IDs
      final filteredReviews = reviews.where((review) {
        final createdAt = DateTime.parse(review['created_at']);
        final isInTimeframe = createdAt.isAfter(startDate) && createdAt.isBefore(endDate);
        
        if (entityIds != null) {
          return isInTimeframe && entityIds.contains(review['entity_id']);
        }
        
        return isInTimeframe;
      }).toList();

      // Calculate trends
      final totalReviews = filteredReviews.length;
      final averageRating = totalReviews > 0 
          ? filteredReviews.map((r) => r['rating'] as double).reduce((a, b) => a + b) / totalReviews
          : 0.0;

      // Group by time periods
      final reviewsByDay = <String, int>{};
      final ratingsByDay = <String, double>{};
      
      for (final review in filteredReviews) {
        final date = DateTime.parse(review['created_at']);
        final dayKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        
        reviewsByDay[dayKey] = (reviewsByDay[dayKey] ?? 0) + 1;
        ratingsByDay[dayKey] = ((ratingsByDay[dayKey] ?? 0) + review['rating']) / (reviewsByDay[dayKey]!);
      }

      AppLogger.info(_tag, 'Review trends calculated');
      return {
        'total_reviews': totalReviews,
        'average_rating': averageRating,
        'reviews_by_day': reviewsByDay,
        'ratings_by_day': ratingsByDay,
        'timeframe': timeframe ?? 'month',
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
      };

    } catch (e) {
      AppLogger.error(_tag, 'Error getting review trends: $e');
      rethrow;
    }
  }

  // ===============================
  // PRIVATE HELPER METHODS
  // ===============================

  Future<Map<String, dynamic>> _getUserData(String userId) async {
    try {
      final users = await SupabaseDatabaseService.select(
        table: 'users',
        filters: {'id': userId},
      );

      if (users.isEmpty) {
        return {
          'id': userId,
          'name': 'Unknown User',
          'avatar_url': null,
        };
      }

      final userData = users.first;

      return {
        'id': userData['id'],
        'name': userData['name'] ?? 'Unknown User',
        'avatar_url': userData['avatar_url'],
      };
    } catch (e) {
      return {
        'id': userId,
        'name': 'Unknown User',
        'avatar_url': null,
      };
    }
  }

  Future<Map<String, dynamic>> _getEntityData(String entityId, String entityType) async {
    try {
      String table;
      switch (entityType) {
        case IReviewService.typeDestination:
          table = 'destinations';
          break;
        case IReviewService.typeAccommodation:
          table = 'accommodations';
          break;
        case IReviewService.typeActivity:
          table = 'activities';
          break;
        case IReviewService.typeRestaurant:
          table = 'restaurants';
          break;
        default:
          table = 'destinations';
      }

      final entities = await SupabaseDatabaseService.select(
        table: table,
        filters: {'id': entityId},
      );

      return entities.isNotEmpty ? entities.first : {'id': entityId, 'name': 'Unknown Entity'};
    } catch (e) {
      return {'id': entityId, 'name': 'Unknown Entity'};
    }
  }

  Future<bool> _isLikedByUser(String reviewId) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) return false;

      final likes = await SupabaseDatabaseService.select(
        table: _reviewLikesTable,
        filters: {
          'review_id': reviewId,
          'user_id': userId,
        },
      );

      return likes.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<void> _updateReviewLikeCount(String reviewId) async {
    try {
      final likeCount = await _getReviewLikeCount(reviewId);
      
      await SupabaseDatabaseService.update(
        table: _reviewsTable,
        id: reviewId,
        data: {
          'like_count': likeCount,
          'updated_at': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      AppLogger.error(_tag, 'Error updating review like count: $e');
    }
  }

  Future<int> _getReviewLikeCount(String reviewId) async {
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

  Future<void> _updateEntityStatistics(String entityId, String entityType) async {
    try {
      final stats = await _calculateEntityStatistics(entityId, entityType);
      
      // Update or insert statistics
      final existingStats = await SupabaseDatabaseService.select(
        table: _reviewStatisticsTable,
        filters: {
          'entity_id': entityId,
          'entity_type': entityType,
        },
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
          data: {
            'id': DateTime.now().millisecondsSinceEpoch.toString(),
            'entity_id': entityId,
            'entity_type': entityType,
            ...stats,
          },
        );
      }
    } catch (e) {
      AppLogger.error(_tag, 'Error updating entity statistics: $e');
    }
  }

  Future<Map<String, dynamic>> _calculateEntityStatistics(String entityId, String entityType) async {
    try {
      final reviews = await SupabaseDatabaseService.select(
        table: _reviewsTable,
        filters: {
          'entity_id': entityId,
          'entity_type': entityType,
          'status': IReviewService.statusApproved,
          'is_active': true,
        },
      );

      if (reviews.isEmpty) {
        return {
          'total_reviews': 0,
          'average_rating': 0.0,
          'rating_distribution': {'1': 0, '2': 0, '3': 0, '4': 0, '5': 0},
          'updated_at': DateTime.now().toIso8601String(),
        };
      }

      final totalReviews = reviews.length;
      final totalRating = reviews.fold<double>(0, (sum, review) => sum + review['rating']);
      final averageRating = totalRating / totalReviews;

      // Calculate rating distribution
      final distribution = {'1': 0, '2': 0, '3': 0, '4': 0, '5': 0};
      for (final review in reviews) {
        final rating = review['rating'].round().toString();
        distribution[rating] = (distribution[rating] ?? 0) + 1;
      }

      return {
        'total_reviews': totalReviews,
        'average_rating': averageRating,
        'rating_distribution': distribution,
        'updated_at': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      AppLogger.error(_tag, 'Error calculating entity statistics: $e');
      return {
        'total_reviews': 0,
        'average_rating': 0.0,
        'rating_distribution': {'1': 0, '2': 0, '3': 0, '4': 0, '5': 0},
        'updated_at': DateTime.now().toIso8601String(),
      };
    }
  }
}
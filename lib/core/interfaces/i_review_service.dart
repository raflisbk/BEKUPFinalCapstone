/// Interface for Review Service
/// Handles user reviews, ratings, and feedback for destinations, accommodations, and activities
abstract class IReviewService {
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
  });

  /// Get reviews for a specific entity (destination, accommodation, etc.)
  Future<List<Map<String, dynamic>>> getEntityReviews({
    required String entityId,
    required String entityType,
    String? sortBy,
    String? filterBy,
    int? limit,
    int? offset,
  });

  /// Get reviews written by a specific user
  Future<List<Map<String, dynamic>>> getUserReviews({
    required String userId,
    String? entityType,
    String? status,
    int? limit,
    int? offset,
  });

  /// Update an existing review
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
  });

  /// Delete a review
  Future<void> deleteReview(String reviewId);

  // ===============================
  // REVIEW INTERACTIONS
  // ===============================

  /// Toggle like/unlike on a review
  Future<Map<String, dynamic>> toggleReviewLike(String reviewId);

  /// Mark a review as helpful
  Future<void> markReviewHelpful(String reviewId);

  /// Report a review for inappropriate content
  Future<Map<String, dynamic>> reportReview({
    required String reviewId,
    required String reason,
    String? description,
  });

  // ===============================
  // STATISTICS & ANALYTICS
  // ===============================

  /// Get statistics for a specific entity
  Future<Map<String, dynamic>> getEntityStatistics({
    required String entityId,
    required String entityType,
  });

  /// Get review trends and analytics
  Future<Map<String, dynamic>> getReviewTrends({
    String? entityType,
    String? timeframe,
    List<String>? entityIds,
  });

  // ===============================
  // REVIEW TYPES
  // ===============================

  /// Review types
  static const String typeDestination = 'destination';
  static const String typeAccommodation = 'accommodation';
  static const String typeActivity = 'activity';
  static const String typeRestaurant = 'restaurant';
  static const String typeTransport = 'transport';
  static const String typeGuide = 'guide';
  static const String typeTrip = 'trip';

  /// Review status values
  static const String statusPending = 'pending';
  static const String statusApproved = 'approved';
  static const String statusRejected = 'rejected';
  static const String statusFlagged = 'flagged';
}
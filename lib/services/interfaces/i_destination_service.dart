/// Destination Service Interface
/// Defines the contract for destination management operations
abstract class IDestinationService {
  // CRUD operations
  Future<Map<String, dynamic>> createDestination({
    required String name,
    required String description,
    required String location,
    required String category,
    required double latitude,
    required double longitude,
    String? address,
    List<String>? images,
    Map<String, dynamic>? amenities,
    Map<String, dynamic>? pricing,
    Map<String, dynamic>? contactInfo,
    List<String>? tags,
    Map<String, dynamic>? businessHours,
  });

  Future<Map<String, dynamic>?> getDestination(String destinationId);
  Future<List<Map<String, dynamic>>> getUserDestinations({
    String? status,
    int? limit,
    int? offset,
  });

  Future<Map<String, dynamic>> updateDestination({
    required String destinationId,
    String? name,
    String? description,
    String? location,
    String? category,
    double? latitude,
    double? longitude,
    String? address,
    List<String>? images,
    Map<String, dynamic>? amenities,
    Map<String, dynamic>? pricing,
    Map<String, dynamic>? contactInfo,
    List<String>? tags,
    Map<String, dynamic>? businessHours,
    String? status,
  });

  Future<void> deleteDestination(String destinationId);

  // Search and filtering
  Future<List<Map<String, dynamic>>> searchDestinations({
    String? query,
    String? category,
    String? location,
    double? latitude,
    double? longitude,
    double? radiusKm,
    double? minRating,
    double? maxPrice,
    List<String>? amenities,
    List<String>? tags,
    String? sortBy,
    bool ascending = true,
    int? limit,
    int? offset,
  });

  Future<List<Map<String, dynamic>>> getTopRatedDestinations({
    String? category,
    String? location,
    int limit = 10,
  });

  Future<List<Map<String, dynamic>>> getNearbyDestinations({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
    String? category,
    int? limit,
  });

  Future<List<Map<String, dynamic>>> getTrendingDestinations({
    String? category,
    String? location,
    int limit = 10,
  });

  // Categories
  Future<List<Map<String, dynamic>>> getCategories();
  Future<List<Map<String, dynamic>>> getDestinationsByCategory({
    required String category,
    String? location,
    int? limit,
    int? offset,
  });

  // Bookmarks/Favorites
  Future<Map<String, dynamic>> bookmarkDestination(String destinationId);
  Future<void> removeBookmark(String destinationId);
  Future<List<Map<String, dynamic>>> getUserBookmarks();
  Future<bool> isDestinationBookmarked(String destinationId);

  // Reviews and ratings
  Future<Map<String, dynamic>> addReview({
    required String destinationId,
    required double rating,
    String? reviewText,
    List<String>? images,
    List<String>? tags,
  });

  Future<Map<String, dynamic>> updateReview({
    required String reviewId,
    double? rating,
    String? reviewText,
    List<String>? images,
    List<String>? tags,
  });

  Future<void> deleteReview(String reviewId);
  Future<List<Map<String, dynamic>>> getDestinationReviews({
    required String destinationId,
    double? minRating,
    String? sortBy,
    bool ascending = false,
    int? limit,
    int? offset,
  });

  Future<Map<String, dynamic>?> getUserReview({
    required String destinationId,
    String? userId,
  });

  // Analytics and statistics
  Future<void> incrementVisitCount(String destinationId);
  Future<void> updateDestinationRating(String destinationId);
  Future<Map<String, dynamic>> getDestinationStatistics(String destinationId);
  Future<Map<String, dynamic>> getPopularityTrends({
    String? category,
    String? location,
    int days = 30,
  });

  // Admin operations
  Future<void> approveDestination(String destinationId);
  Future<void> rejectDestination(String destinationId, {String? reason});
  Future<List<Map<String, dynamic>>> getPendingDestinations({
    int? limit,
    int? offset,
  });
}
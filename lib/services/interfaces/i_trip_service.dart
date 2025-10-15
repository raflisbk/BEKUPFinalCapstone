/// Trip Service Interface
/// Defines the contract for trip management operations
abstract class ITripService {
  // Trip CRUD operations
  Future<Map<String, dynamic>> createTrip({
    required String title,
    required String description,
    required DateTime startDate,
    required DateTime endDate,
    required String destination,
    required int maxParticipants,
    required bool isPublic,
    required String category,
    String? coverImageUrl,
    Map<String, dynamic>? itinerary,
    Map<String, dynamic>? budget,
    List<String>? tags,
    Map<String, dynamic>? preferences,
  });

  Future<Map<String, dynamic>?> getTrip(String tripId);
  Future<List<Map<String, dynamic>>> getUserTrips({
    String? status,
    int? limit,
    int? offset,
  });

  Future<Map<String, dynamic>> updateTrip({
    required String tripId,
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    String? destination,
    int? maxParticipants,
    bool? isPublic,
    String? status,
    String? category,
    String? coverImageUrl,
    Map<String, dynamic>? itinerary,
    Map<String, dynamic>? budget,
    List<String>? tags,
    Map<String, dynamic>? preferences,
  });

  Future<void> deleteTrip(String tripId);

  // Participant management
  Future<Map<String, dynamic>> addTripParticipant({
    required String tripId,
    required String userId,
    String role = 'participant',
    Map<String, dynamic>? permissions,
  });

  Future<void> removeTripParticipant({
    required String tripId,
    required String userId,
  });

  Future<List<Map<String, dynamic>>> getTripParticipants(String tripId);

  // Search and discovery
  Future<List<Map<String, dynamic>>> searchPublicTrips({
    String? query,
    String? destination,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    int? maxParticipants,
    List<String>? tags,
    String? sortBy,
    bool ascending = true,
    int? limit,
    int? offset,
  });

  Future<List<Map<String, dynamic>>> getRecommendedTrips({
    int limit = 10,
  });

  Future<List<Map<String, dynamic>>> getTrendingTrips({
    int limit = 10,
  });

  // Trip status management
  Future<void> startTrip(String tripId);
  Future<void> completeTrip(String tripId);
  Future<void> cancelTrip(String tripId, {String? reason});

  // Analytics
  Future<Map<String, dynamic>> getTripStatistics(String tripId);
  Future<Map<String, dynamic>> getUserTripStatistics();
}
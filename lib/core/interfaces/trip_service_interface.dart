/// Trip Service Interface
/// Defines contract for trip management operations
abstract class ITripService {
  // ===============================
  // TRIP CRUD OPERATIONS
  // ===============================

  /// Create new trip
  Future<Map<String, dynamic>> createTrip({
    required String title,
    required String description,
    required DateTime startDate,
    required DateTime endDate,
    double? budget,
    String? destination,
    bool isPublic = false,
    List<String>? tags,
    Map<String, dynamic>? preferences,
  });

  /// Get trip by ID
  Future<Map<String, dynamic>?> getTrip(String tripId);

  /// Get user trips
  Future<List<Map<String, dynamic>>> getUserTrips({
    String? status,
    int? limit,
    int? offset,
  });

  /// Update trip
  Future<Map<String, dynamic>> updateTrip({
    required String tripId,
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    double? budget,
    String? destination,
    bool? isPublic,
    List<String>? tags,
    Map<String, dynamic>? preferences,
  });

  /// Delete trip
  Future<void> deleteTrip(String tripId);

  // ===============================
  // TRIP PARTICIPANTS MANAGEMENT
  // ===============================

  /// Add participant to trip
  Future<Map<String, dynamic>> addTripParticipant({
    required String tripId,
    required String userId,
    String role = 'participant',
  });

  /// Remove participant from trip
  Future<void> removeTripParticipant({
    required String tripId,
    required String userId,
  });

  /// Get trip participants
  Future<List<Map<String, dynamic>>> getTripParticipants(String tripId);

  // ===============================
  // TRIP DISCOVERY & SEARCH
  // ===============================

  /// Search public trips
  Future<List<Map<String, dynamic>>> searchPublicTrips({
    String? query,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? tags,
    double? maxBudget,
    int? limit,
    int? offset,
  });

  /// Get featured trips
  Future<List<Map<String, dynamic>>> getFeaturedTrips({int limit = 10});

  /// Get trips by location
  Future<List<Map<String, dynamic>>> getTripsByLocation({
    required String location,
    int? limit,
    int? offset,
  });

  // ===============================
  // TRIP STATUS MANAGEMENT
  // ===============================

  /// Start trip (change status to active)
  Future<void> startTrip(String tripId);

  /// Complete trip (change status to completed)
  Future<void> completeTrip(String tripId);

  /// Cancel trip
  Future<void> cancelTrip(String tripId, {String? reason});

  // ===============================
  // TRIP ANALYTICS
  // ===============================

  /// Get trip statistics
  Future<Map<String, dynamic>> getTripStatistics(String tripId);

  /// Get user trip analytics
  Future<Map<String, dynamic>> getUserTripAnalytics(String userId);
}
import 'dart:async';

/// Interface for Itinerary Service
/// Defines the contract for trip itinerary planning, activities, and schedule management
abstract class IItineraryService {
  // ===============================
  // ITINERARY CRUD OPERATIONS
  // ===============================

  /// Create itinerary for trip
  Future<Map<String, dynamic>> createItinerary({
    required String tripId,
    required String title,
    String? description,
    DateTime? date,
    int dayNumber = 1,
    Map<String, dynamic>? preferences,
  });

  /// Get itinerary by ID
  Future<Map<String, dynamic>?> getItinerary(String itineraryId);

  /// Get trip itineraries
  Future<List<Map<String, dynamic>>> getTripItineraries(String tripId);

  /// Update itinerary
  Future<Map<String, dynamic>> updateItinerary({
    required String itineraryId,
    String? title,
    String? description,
    DateTime? date,
    int? dayNumber,
    String? status,
    Map<String, dynamic>? preferences,
  });

  /// Delete itinerary
  Future<void> deleteItinerary(String itineraryId);

  // ===============================
  // ACTIVITY MANAGEMENT
  // ===============================

  /// Add activity to itinerary
  Future<Map<String, dynamic>> addActivity({
    required String itineraryId,
    required String title,
    required String type, // attraction, restaurant, transport, accommodation, etc.
    String? description,
    String? location,
    double? latitude,
    double? longitude,
    DateTime? startTime,
    DateTime? endTime,
    double? estimatedCost,
    Map<String, dynamic>? details,
    int? sortOrder,
  });

  /// Update activity
  Future<Map<String, dynamic>> updateActivity({
    required String activityId,
    String? title,
    String? type,
    String? description,
    String? location,
    double? latitude,
    double? longitude,
    DateTime? startTime,
    DateTime? endTime,
    double? estimatedCost,
    double? actualCost,
    String? status,
    bool? isCompleted,
    Map<String, dynamic>? details,
    int? sortOrder,
  });

  /// Delete activity
  Future<void> deleteActivity(String activityId);

  /// Get itinerary activities
  Future<List<Map<String, dynamic>>> getItineraryActivities(String itineraryId);

  /// Reorder activities
  Future<void> reorderActivities({
    required String itineraryId,
    required List<String> activityIds,
  });

  // ===============================
  // ITINERARY TEMPLATES
  // ===============================

  /// Create itinerary template
  Future<Map<String, dynamic>> createTemplate({
    required String name,
    required String description,
    required String category,
    required int durationDays,
    List<Map<String, dynamic>>? templateActivities,
    Map<String, dynamic>? metadata,
  });

  /// Get itinerary templates
  Future<List<Map<String, dynamic>>> getTemplates({
    String? category,
    int? durationDays,
    bool? isPublic,
    int limit = 20,
  });

  /// Apply template to trip
  Future<List<Map<String, dynamic>>> applyTemplateToTrip({
    required String tripId,
    required String templateId,
    DateTime? startDate,
  });

  // ===============================
  // ITINERARY OPTIMIZATION
  // ===============================

  /// Optimize itinerary by location (minimize travel time)
  Future<List<Map<String, dynamic>>> optimizeItineraryByLocation(String itineraryId);

  // ===============================
  // STATISTICS & ANALYTICS
  // ===============================

  /// Get itinerary statistics
  Future<Map<String, dynamic>> getItineraryStatistics(String itineraryId);
}
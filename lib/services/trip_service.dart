import 'dart:async';
import '../core/utils/logger.dart';
import 'supabase_config.dart';
import 'supabase_database_service.dart';

/// Trip Service
/// Handles trip planning, management, and related operations
class TripService {
  static const String _tag = 'TripService';
  static const String _tableName = 'trips';
  static const String _participantsTable = 'trip_participants';

  // Singleton pattern
  static TripService? _instance;
  static TripService get instance => _instance ??= TripService._internal();
  
  TripService._internal();

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
  }) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Creating new trip: $title');

      // Validate dates
      if (endDate.isBefore(startDate)) {
        throw Exception('End date cannot be before start date');
      }

      final tripData = {
        'title': title,
        'description': description,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        'budget': budget,
        'destination': destination,
        'is_public': isPublic,
        'tags': tags ?? [],
        'preferences': preferences ?? {},
        'creator_id': userId,
        'status': 'planning',
        'participant_count': 1,
        'expenses_total': 0.0,
        'itinerary_count': 0,
      };

      final result = await SupabaseDatabaseService.insert(
        table: _tableName,
        data: tripData,
      );

      // Add creator as participant
      await _addTripParticipant(
        tripId: result['id'],
        userId: userId,
        role: 'creator',
      );

      AppLogger.success(_tag, 'Trip created successfully: $title');
      return result;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to create trip', e, stackTrace);
      rethrow;
    }
  }

  /// Get trip by ID
  Future<Map<String, dynamic>?> getTrip(String tripId) async {
    try {
      AppLogger.debug(_tag, 'Getting trip: $tripId');

      final trips = await SupabaseDatabaseService.select(
        table: _tableName,
        filters: {'id': tripId},
      );

      if (trips.isEmpty) {
        AppLogger.warning(_tag, 'Trip not found: $tripId');
        return null;
      }

      final trip = trips.first;
      
      // Enrich trip data
      await _enrichTripData(trip);

      AppLogger.success(_tag, 'Retrieved trip: ${trip['title']}');
      return trip;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get trip', e, stackTrace);
      rethrow;
    }
  }

  /// Get user trips
  Future<List<Map<String, dynamic>>> getUserTrips({
    String? status,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Getting user trips');

      final filters = <String, dynamic>{'creator_id': userId};
      if (status != null) filters['status'] = status;

      final trips = await SupabaseDatabaseService.select(
        table: _tableName,
        filters: filters,
        orderBy: 'created_at',
        ascending: false,
        limit: limit,
        offset: offset,
      );

      // Enrich each trip with additional data
      for (final trip in trips) {
        await _enrichTripData(trip);
      }

      AppLogger.success(_tag, 'Retrieved ${trips.length} user trips');
      return trips;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get user trips', e, stackTrace);
      rethrow;
    }
  }

  /// Update trip
  static Future<Map<String, dynamic>> updateTrip({
    required String tripId,
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    double? budget,
    String? destination,
    bool? isPublic,
    List<String>? tags,
    String? status,
    Map<String, dynamic>? preferences,
  }) async {
    try {
      AppLogger.debug(_tag, 'Updating trip: $tripId');

      final updateData = <String, dynamic>{};
      
      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (startDate != null) updateData['start_date'] = startDate.toIso8601String();
      if (endDate != null) updateData['end_date'] = endDate.toIso8601String();
      if (budget != null) updateData['budget'] = budget;
      if (destination != null) updateData['destination'] = destination;
      if (isPublic != null) updateData['is_public'] = isPublic;
      if (tags != null) updateData['tags'] = tags;
      if (status != null) updateData['status'] = status;
      if (preferences != null) updateData['preferences'] = preferences;

      // Validate dates if both are provided
      if (startDate != null && endDate != null && endDate.isBefore(startDate)) {
        throw Exception('End date cannot be before start date');
      }

      if (updateData.isEmpty) {
        throw Exception('No data provided for update');
      }

      final result = await SupabaseDatabaseService.update(
        table: _tableName,
        id: tripId,
        data: updateData,
      );

      AppLogger.success(_tag, 'Trip updated successfully');
      return result;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to update trip', e, stackTrace);
      rethrow;
    }
  }

  /// Delete trip
  static Future<void> deleteTrip(String tripId) async {
    try {
      AppLogger.warning(_tag, 'Deleting trip: $tripId');

      // Check if user is the creator
      final trip = await getTrip(tripId);
      if (trip == null) {
        throw Exception('Trip not found');
      }

      final currentUserId = SupabaseConfig.userId;
      if (trip['creator_id'] != currentUserId) {
        throw Exception('Only trip creator can delete the trip');
      }

      await SupabaseDatabaseService.delete(
        table: _tableName,
        id: tripId,
      );

      AppLogger.success(_tag, 'Trip deleted successfully');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to delete trip', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // TRIP PARTICIPANTS
  // ===============================

  /// Add participant to trip
  static Future<Map<String, dynamic>> addTripParticipant({
    required String tripId,
    required String email,
    String role = 'participant',
  }) async {
    try {
      AppLogger.debug(_tag, 'Adding participant to trip: $tripId');

      // Check if user is trip creator
      final trip = await getTrip(tripId);
      if (trip == null) {
        throw Exception('Trip not found');
      }

      final currentUserId = SupabaseConfig.userId;
      if (trip['creator_id'] != currentUserId) {
        throw Exception('Only trip creator can add participants');
      }

      // Find user by email (would need user lookup functionality)
      // For now, we'll assume we have the userId
      
      final participantData = {
        'trip_id': tripId,
        'user_email': email,
        'role': role,
        'status': 'invited',
        'invited_by': currentUserId,
      };

      final result = await SupabaseDatabaseService.insert(
        table: _participantsTable,
        data: participantData,
      );

      // Update participant count
      await _updateTripParticipantCount(tripId);

      AppLogger.success(_tag, 'Participant added successfully');
      return result;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to add trip participant', e, stackTrace);
      rethrow;
    }
  }

  /// Remove participant from trip
  static Future<void> removeTripParticipant({
    required String tripId,
    required String participantId,
  }) async {
    try {
      AppLogger.debug(_tag, 'Removing participant from trip: $tripId');

      await SupabaseDatabaseService.delete(
        table: _participantsTable,
        id: participantId,
      );

      // Update participant count
      await _updateTripParticipantCount(tripId);

      AppLogger.success(_tag, 'Participant removed successfully');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to remove trip participant', e, stackTrace);
      rethrow;
    }
  }

  /// Get trip participants
  Future<List<Map<String, dynamic>>> getTripParticipants(String tripId) async {
    try {
      AppLogger.debug(_tag, 'Getting trip participants: $tripId');

      final participants = await SupabaseDatabaseService.select(
        table: _participantsTable,
        filters: {'trip_id': tripId},
        orderBy: 'created_at',
      );

      AppLogger.success(_tag, 'Retrieved ${participants.length} participants');
      return participants;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get trip participants', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // TRIP SEARCH & DISCOVERY
  // ===============================

  /// Search public trips
  static Future<List<Map<String, dynamic>>> searchPublicTrips({
    String? query,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? tags,
    int limit = 20,
  }) async {
    try {
      AppLogger.debug(_tag, 'Searching public trips');

      final filters = <String, dynamic>{'is_public': true, 'status': 'active'};
      if (destination != null) filters['destination'] = destination;

      List<Map<String, dynamic>> trips;

      if (query != null) {
        trips = await SupabaseDatabaseService.textSearch(
          table: _tableName,
          searchTerm: query,
          searchColumns: ['title', 'description', 'destination'],
          limit: limit,
        );

        // Apply additional filters
        trips = trips.where((trip) {
          bool matches = trip['is_public'] == true && trip['status'] == 'active';
          
          if (destination != null) {
            matches &= trip['destination'] == destination;
          }
          
          if (tags != null && tags.isNotEmpty) {
            final tripTags = List<String>.from(trip['tags'] ?? []);
            matches &= tags.any((tag) => tripTags.contains(tag));
          }
          
          return matches;
        }).toList();
      } else {
        trips = await SupabaseDatabaseService.select(
          table: _tableName,
          filters: filters,
          orderBy: 'created_at',
          ascending: false,
          limit: limit,
        );
      }

      AppLogger.success(_tag, 'Found ${trips.length} public trips');
      return trips;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to search public trips', e, stackTrace);
      rethrow;
    }
  }

  /// Get popular trips
  Future<List<Map<String, dynamic>>> getPopularTrips({
    int limit = 10,
    String? destination,
  }) async {
    try {
      AppLogger.debug(_tag, 'Getting popular trips');

      final filters = <String, dynamic>{'is_public': true};
      if (destination != null) filters['destination'] = destination;

      final trips = await SupabaseDatabaseService.select(
        table: _tableName,
        filters: filters,
        orderBy: 'participant_count',
        ascending: false,
        limit: limit,
      );

      AppLogger.success(_tag, 'Retrieved ${trips.length} popular trips');
      return trips;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get popular trips', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // TRIP STATUS MANAGEMENT
  // ===============================

  /// Start trip (change status to active)
  static Future<void> startTrip(String tripId) async {
    try {
      AppLogger.info(_tag, 'Starting trip: $tripId');

      await updateTrip(
        tripId: tripId,
        status: 'active',
      );

      AppLogger.success(_tag, 'Trip started successfully');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to start trip', e, stackTrace);
      rethrow;
    }
  }

  /// Complete trip
  static Future<void> completeTrip(String tripId) async {
    try {
      AppLogger.info(_tag, 'Completing trip: $tripId');

      await updateTrip(
        tripId: tripId,
        status: 'completed',
      );

      AppLogger.success(_tag, 'Trip completed successfully');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to complete trip', e, stackTrace);
      rethrow;
    }
  }

  /// Cancel trip
  static Future<void> cancelTrip(String tripId, {String? reason}) async {
    try {
      AppLogger.warning(_tag, 'Canceling trip: $tripId');

      final updateData = <String, dynamic>{
        'status': 'cancelled',
      };

      if (reason != null) {
        final preferences = {'cancellation_reason': reason};
        updateData['preferences'] = preferences;
      }

      await SupabaseDatabaseService.update(
        table: _tableName,
        id: tripId,
        data: updateData,
      );

      AppLogger.success(_tag, 'Trip cancelled successfully');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to cancel trip', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // TRIP STATISTICS
  // ===============================

  /// Get trip statistics
  static Future<Map<String, dynamic>> getTripStatistics(String tripId) async {
    try {
      AppLogger.debug(_tag, 'Getting trip statistics: $tripId');

      final trip = await getTrip(tripId);
      if (trip == null) {
        throw Exception('Trip not found');
      }

      final participants = await getTripParticipants(tripId);
      
      final stats = {
        'trip_id': tripId,
        'title': trip['title'],
        'status': trip['status'],
        'duration_days': _calculateTripDuration(
          DateTime.parse(trip['start_date']),
          DateTime.parse(trip['end_date']),
        ),
        'participant_count': participants.length,
        'budget': trip['budget'],
        'expenses_total': trip['expenses_total'] ?? 0.0,
        'budget_remaining': (trip['budget'] ?? 0.0) - (trip['expenses_total'] ?? 0.0),
        'itinerary_count': trip['itinerary_count'] ?? 0,
        'created_at': trip['created_at'],
        'last_updated': trip['updated_at'],
      };

      AppLogger.success(_tag, 'Retrieved trip statistics');
      return stats;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get trip statistics', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // PRIVATE HELPER METHODS
  // ===============================

  /// Add trip participant (internal)
  static Future<void> _addTripParticipant({
    required String tripId,
    required String userId,
    String role = 'participant',
  }) async {
    try {
      final participantData = {
        'trip_id': tripId,
        'user_id': userId,
        'role': role,
        'status': 'accepted',
      };

      await SupabaseDatabaseService.insert(
        table: _participantsTable,
        data: participantData,
      );
    } catch (e) {
      AppLogger.error(_tag, 'Failed to add trip participant internally', e);
      // Don't rethrow as this is used during trip creation
    }
  }

  /// Update trip participant count
  static Future<void> _updateTripParticipantCount(String tripId) async {
    try {
      final participants = await getTripParticipants(tripId);
      
      await SupabaseDatabaseService.update(
        table: _tableName,
        id: tripId,
        data: {'participant_count': participants.length},
      );
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to update participant count', e);
      // Don't throw error as this is not critical
    }
  }

  /// Enrich trip data with additional information
  static Future<void> _enrichTripData(Map<String, dynamic> trip) async {
    try {
      // Calculate trip duration
      final startDate = DateTime.parse(trip['start_date']);
      final endDate = DateTime.parse(trip['end_date']);
      trip['duration_days'] = _calculateTripDuration(startDate, endDate);

      // Add trip status info
      trip['is_upcoming'] = startDate.isAfter(DateTime.now());
      trip['is_ongoing'] = DateTime.now().isAfter(startDate) && DateTime.now().isBefore(endDate);
      trip['is_past'] = endDate.isBefore(DateTime.now());

      // Calculate budget status
      final budget = trip['budget'] as double? ?? 0.0;
      final expensesTotal = trip['expenses_total'] as double? ?? 0.0;
      trip['budget_remaining'] = budget - expensesTotal;
      trip['budget_used_percentage'] = budget > 0 ? (expensesTotal / budget * 100) : 0.0;
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to enrich trip data', e);
      // Don't throw error as this is not critical
    }
  }

  /// Calculate trip duration in days
  static int _calculateTripDuration(DateTime startDate, DateTime endDate) {
    return endDate.difference(startDate).inDays + 1; // Include both start and end day
  }
}
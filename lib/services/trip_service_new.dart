import 'dart:async';
import '../core/interfaces/trip_service_interface.dart';
import '../core/utils/logger.dart';
import 'supabase_config.dart';
import 'supabase_database_service.dart';

/// Trip Service Implementation
/// Handles trip planning, management, and related operations
class TripService implements ITripService {
  static const String _tag = 'TripService';
  static const String _tableName = 'trips';
  static const String _participantsTable = 'trip_participants';

  /// Constructor with dependency injection
  TripService();

  // ===============================
  // TRIP CRUD OPERATIONS
  // ===============================

  /// Create new trip
  @override
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
        'status': 'planning',
        'creator_id': userId,
        'participant_count': 1,
      };

      final result = await SupabaseDatabaseService.insert(
        table: _tableName,
        data: tripData,
      );

      // Add creator as first participant with organizer role
      await _addTripParticipant(
        tripId: result['id'],
        userId: userId,
        role: 'organizer',
      );

      AppLogger.success(_tag, 'Trip created successfully: $title');
      return result;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to create trip', e, stackTrace);
      rethrow;
    }
  }

  /// Get trip by ID
  @override
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
      
      // Enrich with additional data
      await _enrichTripData(trip);

      AppLogger.success(_tag, 'Retrieved trip: $tripId');
      return trip;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get trip', e, stackTrace);
      rethrow;
    }
  }

  /// Get user trips
  @override
  Future<List<Map<String, dynamic>>> getUserTrips({
    String? status,
    int? limit,
    int? offset,
  }) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Getting trips for user: $userId');

      // Get trips where user is a participant
      const participantFilters = <String, dynamic>{};
      participantFilters['user_id'] = userId;
      final participantTrips = await SupabaseDatabaseService.select(
        table: _participantsTable,
        filters: participantFilters,
      );

      final tripIds = participantTrips.map((p) => p['trip_id']).toList();

      if (tripIds.isEmpty) {
        return [];
      }

      // Get all trips and filter by IDs manually
      final allTrips = await SupabaseDatabaseService.select(
        table: _tableName,
        orderBy: 'created_at',
        ascending: false,
        limit: limit,
        offset: offset,
      );

      // Filter trips by IDs
      List<Map<String, dynamic>> trips = allTrips.where((trip) => 
        tripIds.contains(trip['id'])
      ).toList();

      // Apply status filter if provided
      if (status != null) {
        trips = trips.where((trip) => trip['status'] == status).toList();
      }

      // Enrich each trip with additional data
      for (final trip in trips) {
        await _enrichTripData(trip);
      }

      AppLogger.success(_tag, 'Retrieved ${trips.length} trips');
      return trips;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get user trips', e, stackTrace);
      rethrow;
    }
  }

  /// Update trip
  @override
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
  }) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Updating trip: $tripId');

      // Validate dates if provided
      if (startDate != null && endDate != null && endDate.isBefore(startDate)) {
        throw Exception('End date cannot be before start date');
      }

      final updateData = <String, dynamic>{};
      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (startDate != null) updateData['start_date'] = startDate.toIso8601String();
      if (endDate != null) updateData['end_date'] = endDate.toIso8601String();
      if (budget != null) updateData['budget'] = budget;
      if (destination != null) updateData['destination'] = destination;
      if (isPublic != null) updateData['is_public'] = isPublic;
      if (tags != null) updateData['tags'] = tags;
      if (preferences != null) updateData['preferences'] = preferences;

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
  @override
  Future<void> deleteTrip(String tripId) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.warning(_tag, 'Deleting trip: $tripId');

      // Check if user is the creator
      final trip = await getTrip(tripId);
      if (trip == null) {
        throw Exception('Trip not found');
      }

      if (trip['creator_id'] != userId) {
        throw Exception('Only trip creator can delete the trip');
      }

      // Delete trip participants first
      final participants = await SupabaseDatabaseService.select(
        table: _participantsTable,
        filters: {'trip_id': tripId},
      );

      final participantIds = participants.map((p) => p['id'].toString()).toList();
      if (participantIds.isNotEmpty) {
        await SupabaseDatabaseService.batchDelete(
          table: _participantsTable,
          ids: participantIds,
        );
      }

      // Delete the trip
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
  // TRIP PARTICIPANTS MANAGEMENT
  // ===============================

  /// Add participant to trip
  @override
  Future<Map<String, dynamic>> addTripParticipant({
    required String tripId,
    required String userId,
    String role = 'participant',
  }) async {
    try {
      AppLogger.debug(_tag, 'Adding participant to trip: $tripId');

      final result = await _addTripParticipant(
        tripId: tripId,
        userId: userId,
        role: role,
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
  @override
  Future<void> removeTripParticipant({
    required String tripId,
    required String userId,
  }) async {
    try {
      AppLogger.warning(_tag, 'Removing participant from trip: $tripId');

      // Find participant record
      final participants = await SupabaseDatabaseService.select(
        table: _participantsTable,
        filters: {'trip_id': tripId, 'user_id': userId},
      );

      if (participants.isEmpty) {
        throw Exception('Participant not found in trip');
      }

      // Delete participant record
      await SupabaseDatabaseService.delete(
        table: _participantsTable,
        id: participants.first['id'],
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
  @override
  Future<List<Map<String, dynamic>>> getTripParticipants(String tripId) async {
    try {
      AppLogger.debug(_tag, 'Getting participants for trip: $tripId');

      final participants = await SupabaseDatabaseService.select(
        table: _participantsTable,
        filters: {'trip_id': tripId},
        orderBy: 'joined_at',
        ascending: true,
      );

      AppLogger.success(_tag, 'Retrieved ${participants.length} participants');
      return participants;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get trip participants', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // TRIP DISCOVERY & SEARCH
  // ===============================

  /// Search public trips
  @override
  Future<List<Map<String, dynamic>>> searchPublicTrips({
    String? query,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? tags,
    double? maxBudget,
    int? limit,
    int? offset,
  }) async {
    try {
      AppLogger.debug(_tag, 'Searching public trips with query: $query');

      final filters = <String, dynamic>{'is_public': true};
      if (destination != null) filters['destination'] = destination;
      if (maxBudget != null) {
        // For budget filtering, we'll need to filter manually since SupabaseDatabaseService doesn't support range queries
      }

      final trips = await SupabaseDatabaseService.select(
        table: _tableName,
        filters: filters,
        orderBy: 'created_at',
        ascending: false,
        limit: limit,
        offset: offset,
      );

      // Manual filtering for complex conditions
      List<Map<String, dynamic>> filteredTrips = trips;

      // Filter by query (title or description)
      if (query != null && query.isNotEmpty) {
        filteredTrips = filteredTrips.where((trip) {
          final title = trip['title']?.toString().toLowerCase() ?? '';
          final description = trip['description']?.toString().toLowerCase() ?? '';
          final searchQuery = query.toLowerCase();
          return title.contains(searchQuery) || description.contains(searchQuery);
        }).toList();
      }

      // Filter by date range
      if (startDate != null || endDate != null) {
        filteredTrips = filteredTrips.where((trip) {
          final tripStartDate = DateTime.parse(trip['start_date']);
          final tripEndDate = DateTime.parse(trip['end_date']);
          
          if (startDate != null && tripEndDate.isBefore(startDate)) return false;
          if (endDate != null && tripStartDate.isAfter(endDate)) return false;
          return true;
        }).toList();
      }

      // Filter by budget
      if (maxBudget != null) {
        filteredTrips = filteredTrips.where((trip) {
          final budget = trip['budget']?.toDouble();
          return budget == null || budget <= maxBudget;
        }).toList();
      }

      // Filter by tags
      if (tags != null && tags.isNotEmpty) {
        filteredTrips = filteredTrips.where((trip) {
          final tripTags = List<String>.from(trip['tags'] ?? []);
          return tags.any((tag) => tripTags.contains(tag));
        }).toList();
      }

      // Enrich each trip with additional data
      for (final trip in filteredTrips) {
        await _enrichTripData(trip);
      }

      AppLogger.success(_tag, 'Found ${filteredTrips.length} public trips');
      return filteredTrips;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to search public trips', e, stackTrace);
      rethrow;
    }
  }

  /// Get featured trips
  @override
  Future<List<Map<String, dynamic>>> getFeaturedTrips({int limit = 10}) async {
    try {
      AppLogger.debug(_tag, 'Getting featured trips');

      final trips = await SupabaseDatabaseService.select(
        table: _tableName,
        filters: {'is_public': true, 'status': 'active'},
        orderBy: 'participant_count',
        ascending: false,
        limit: limit,
      );

      // Enrich each trip with additional data
      for (final trip in trips) {
        await _enrichTripData(trip);
      }

      AppLogger.success(_tag, 'Retrieved ${trips.length} featured trips');
      return trips;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get featured trips', e, stackTrace);
      rethrow;
    }
  }

  /// Get trips by location
  @override
  Future<List<Map<String, dynamic>>> getTripsByLocation({
    required String location,
    int? limit,
    int? offset,
  }) async {
    try {
      AppLogger.debug(_tag, 'Getting trips for location: $location');

      final trips = await SupabaseDatabaseService.select(
        table: _tableName,
        filters: {'destination': location, 'is_public': true},
        orderBy: 'start_date',
        ascending: true,
        limit: limit,
        offset: offset,
      );

      // Enrich each trip with additional data
      for (final trip in trips) {
        await _enrichTripData(trip);
      }

      AppLogger.success(_tag, 'Retrieved ${trips.length} trips for location');
      return trips;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get trips by location', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // TRIP STATUS MANAGEMENT
  // ===============================

  /// Start trip (change status to active)
  @override
  Future<void> startTrip(String tripId) async {
    try {
      AppLogger.debug(_tag, 'Starting trip: $tripId');

      await SupabaseDatabaseService.update(
        table: _tableName,
        id: tripId,
        data: {
          'status': 'active',
          'started_at': DateTime.now().toIso8601String(),
        },
      );

      AppLogger.success(_tag, 'Trip started successfully');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to start trip', e, stackTrace);
      rethrow;
    }
  }

  /// Complete trip (change status to completed)
  @override
  Future<void> completeTrip(String tripId) async {
    try {
      AppLogger.debug(_tag, 'Completing trip: $tripId');

      await SupabaseDatabaseService.update(
        table: _tableName,
        id: tripId,
        data: {
          'status': 'completed',
          'completed_at': DateTime.now().toIso8601String(),
        },
      );

      AppLogger.success(_tag, 'Trip completed successfully');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to complete trip', e, stackTrace);
      rethrow;
    }
  }

  /// Cancel trip
  @override
  Future<void> cancelTrip(String tripId, {String? reason}) async {
    try {
      AppLogger.warning(_tag, 'Cancelling trip: $tripId');

      final updateData = {
        'status': 'cancelled',
        'cancelled_at': DateTime.now().toIso8601String(),
      };

      if (reason != null) {
        updateData['cancellation_reason'] = reason;
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
  // TRIP ANALYTICS
  // ===============================

  /// Get trip statistics
  @override
  Future<Map<String, dynamic>> getTripStatistics(String tripId) async {
    try {
      AppLogger.debug(_tag, 'Getting statistics for trip: $tripId');

      final trip = await getTrip(tripId);
      if (trip == null) {
        throw Exception('Trip not found');
      }

      final participants = await getTripParticipants(tripId);
      
      // Calculate trip duration
      final startDate = DateTime.parse(trip['start_date']);
      final endDate = DateTime.parse(trip['end_date']);
      final duration = endDate.difference(startDate).inDays;

      final statistics = {
        'trip_id': tripId,
        'title': trip['title'],
        'status': trip['status'],
        'duration_days': duration,
        'participant_count': participants.length,
        'budget': trip['budget'],
        'created_at': trip['created_at'],
        'start_date': trip['start_date'],
        'end_date': trip['end_date'],
        'destination': trip['destination'],
        'is_public': trip['is_public'],
        'tags': trip['tags'],
      };

      AppLogger.success(_tag, 'Retrieved trip statistics');
      return statistics;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get trip statistics', e, stackTrace);
      rethrow;
    }
  }

  /// Get user trip analytics
  @override
  Future<Map<String, dynamic>> getUserTripAnalytics(String userId) async {
    try {
      AppLogger.debug(_tag, 'Getting trip analytics for user: $userId');

      // Get all user trips
      final allTrips = await getUserTrips();

      // Calculate analytics
      final totalTrips = allTrips.length;
      final completedTrips = allTrips.where((t) => t['status'] == 'completed').length;
      final activeTrips = allTrips.where((t) => t['status'] == 'active').length;
      final planningTrips = allTrips.where((t) => t['status'] == 'planning').length;

      // Calculate total budget
      final totalBudget = allTrips.fold<double>(0, (sum, trip) {
        final budget = trip['budget']?.toDouble() ?? 0;
        return sum + budget;
      });

      // Most visited destinations
      final destinationCounts = <String, int>{};
      for (final trip in allTrips) {
        final destination = trip['destination']?.toString();
        if (destination != null && destination.isNotEmpty) {
          destinationCounts[destination] = (destinationCounts[destination] ?? 0) + 1;
        }
      }

      final sortedDestinations = destinationCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final analytics = {
        'user_id': userId,
        'total_trips': totalTrips,
        'completed_trips': completedTrips,
        'active_trips': activeTrips,
        'planning_trips': planningTrips,
        'completion_rate': totalTrips > 0 ? (completedTrips / totalTrips * 100).round() : 0,
        'total_budget': totalBudget,
        'average_budget': totalTrips > 0 ? totalBudget / totalTrips : 0,
        'favorite_destinations': sortedDestinations.take(5).map((e) => {
          'destination': e.key,
          'visit_count': e.value,
        }).toList(),
        'analysis_date': DateTime.now().toIso8601String(),
      };

      AppLogger.success(_tag, 'Retrieved user trip analytics');
      return analytics;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get user trip analytics', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // PRIVATE HELPER METHODS
  // ===============================

  /// Add trip participant (internal method)
  Future<Map<String, dynamic>> _addTripParticipant({
    required String tripId,
    required String userId,
    String role = 'participant',
  }) async {
    final participantData = {
      'trip_id': tripId,
      'user_id': userId,
      'role': role,
      'status': 'confirmed',
      'joined_at': DateTime.now().toIso8601String(),
    };

    return await SupabaseDatabaseService.insert(
      table: _participantsTable,
      data: participantData,
    );
  }

  /// Update trip participant count
  Future<void> _updateTripParticipantCount(String tripId) async {
    final participants = await getTripParticipants(tripId);
    
    await SupabaseDatabaseService.update(
      table: _tableName,
      id: tripId,
      data: {'participant_count': participants.length},
    );
  }

  /// Enrich trip data with additional information
  Future<void> _enrichTripData(Map<String, dynamic> trip) async {
    // Add participant count if not present
    if (trip['participant_count'] == null) {
      final participants = await getTripParticipants(trip['id']);
      trip['participant_count'] = participants.length;
    }
    
    // Add days until trip starts
    final startDate = DateTime.parse(trip['start_date']);
    final now = DateTime.now();
    trip['days_until_start'] = startDate.difference(now).inDays;
    
    // Add trip duration
    final endDate = DateTime.parse(trip['end_date']);
    trip['duration_days'] = endDate.difference(startDate).inDays;
  }
}
import 'dart:async';
import 'dart:math';
import '../core/utils/logger.dart';
import 'supabase_config.dart';
import 'supabase_database_service.dart';
import 'interfaces/i_trip_service.dart';

/// Trip Service Implementation
/// Handles trip management and related operations using instance pattern
class TripService implements ITripService {
  static const String _tag = 'TripService';
  static const String _tripsTable = 'trips';
  static const String _participantsTable = 'trip_participants';

  // Constructor
  TripService();

  /// Generate a simple UUID
  String _generateUuid() {
    final random = Random();
    return 'trip_${random.nextInt(999999999).toString().padLeft(9, '0')}';
  }

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
  // TRIP CRUD OPERATIONS
  // ===============================

  @override
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
  }) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Creating trip: $title');

      final tripData = {
        'id': _generateUuid(),
        'creator_id': userId,
        'title': title,
        'description': description,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        'destination': destination,
        'max_participants': maxParticipants,
        'current_participants': 1, // Creator is first participant
        'is_public': isPublic,
        'status': 'planned',
        'category': category,
        'cover_image_url': coverImageUrl,
        'itinerary': itinerary,
        'budget': budget,
        'tags': tags,
        'preferences': preferences,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final createdTrip = await SupabaseDatabaseService.insert(
        table: _tripsTable,
        data: tripData,
      );

      // Add creator as first participant
      await _addTripParticipant(
        tripId: createdTrip['id'],
        userId: userId,
        role: 'creator',
      );

      AppLogger.success(_tag, 'Trip created successfully: ${createdTrip['id']}');
      return createdTrip;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to create trip', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>?> getTrip(String tripId) async {
    try {
      AppLogger.debug(_tag, 'Getting trip: $tripId');

      final trips = await SupabaseDatabaseService.select(
        table: _tripsTable,
        filters: {'id': tripId},
      );

      if (trips.isEmpty) {
        AppLogger.warning(_tag, 'Trip not found: $tripId');
        return null;
      }

      final trip = trips.first;
      await _enrichTripData(trip);

      AppLogger.success(_tag, 'Retrieved trip: $tripId');
      return trip;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get trip: $tripId', e, stackTrace);
      rethrow;
    }
  }

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

      AppLogger.debug(_tag, 'Getting user trips for: $userId');

      final filters = <String, dynamic>{'creator_id': userId};
      if (status != null) {
        filters['status'] = status;
      }

      final trips = await SupabaseDatabaseService.select(
        table: _tripsTable,
        filters: filters,
        orderBy: 'created_at',
        limit: limit,
        offset: offset,
      );

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

  @override
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
  }) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Updating trip: $tripId');

      // Check if user has permission to update
      final trip = await getTrip(tripId);
      if (trip == null) {
        throw Exception('Trip not found: $tripId');
      }

      if (trip['creator_id'] != userId) {
        throw Exception('Unauthorized to update trip');
      }

      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (startDate != null) updateData['start_date'] = startDate.toIso8601String();
      if (endDate != null) updateData['end_date'] = endDate.toIso8601String();
      if (destination != null) updateData['destination'] = destination;
      if (maxParticipants != null) updateData['max_participants'] = maxParticipants;
      if (isPublic != null) updateData['is_public'] = isPublic;
      if (status != null) updateData['status'] = status;
      if (category != null) updateData['category'] = category;
      if (coverImageUrl != null) updateData['cover_image_url'] = coverImageUrl;
      if (itinerary != null) updateData['itinerary'] = itinerary;
      if (budget != null) updateData['budget'] = budget;
      if (tags != null) updateData['tags'] = tags;
      if (preferences != null) updateData['preferences'] = preferences;

      final updatedTrip = await SupabaseDatabaseService.update(
        table: _tripsTable,
        id: tripId,
        data: updateData,
      );

      AppLogger.success(_tag, 'Trip updated successfully: $tripId');
      return updatedTrip;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to update trip: $tripId', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> deleteTrip(String tripId) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Deleting trip: $tripId');

      // Check if user has permission to delete
      final trip = await getTrip(tripId);
      if (trip == null) {
        throw Exception('Trip not found: $tripId');
      }

      if (trip['creator_id'] != userId) {
        throw Exception('Unauthorized to delete trip');
      }

      // Delete participants first
      await _deleteWithFilters(
        table: _participantsTable,
        filters: {'trip_id': tripId},
      );

      // Delete trip
      await SupabaseDatabaseService.delete(
        table: _tripsTable,
        id: tripId,
      );

      AppLogger.success(_tag, 'Trip deleted successfully: $tripId');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to delete trip: $tripId', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // PARTICIPANT MANAGEMENT
  // ===============================

  @override
  Future<Map<String, dynamic>> addTripParticipant({
    required String tripId,
    required String userId,
    String role = 'participant',
    Map<String, dynamic>? permissions,
  }) async {
    try {
      final currentUserId = SupabaseConfig.userId;
      if (currentUserId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Adding participant to trip: $tripId');

      // Check if trip exists and has space
      final trip = await getTrip(tripId);
      if (trip == null) {
        throw Exception('Trip not found: $tripId');
      }

      if (trip['current_participants'] >= trip['max_participants']) {
        throw Exception('Trip is full');
      }

      // Check if user is already a participant
      final existingParticipants = await SupabaseDatabaseService.select(
        table: _participantsTable,
        filters: {
          'trip_id': tripId,
          'user_id': userId,
        },
      );

      if (existingParticipants.isNotEmpty) {
        throw Exception('User is already a participant');
      }

      await _addTripParticipant(
        tripId: tripId,
        userId: userId,
        role: role,
        permissions: permissions,
      );

      await _updateTripParticipantCount(tripId);

      AppLogger.success(_tag, 'Participant added to trip: $tripId');
      return {'success': true, 'message': 'Participant added successfully'};
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to add participant to trip: $tripId', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> removeTripParticipant({
    required String tripId,
    required String userId,
  }) async {
    try {
      final currentUserId = SupabaseConfig.userId;
      if (currentUserId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Removing participant from trip: $tripId');

      // Check if trip exists
      final trip = await getTrip(tripId);
      if (trip == null) {
        throw Exception('Trip not found: $tripId');
      }

      // Don't allow removing the creator
      if (trip['creator_id'] == userId) {
        throw Exception('Cannot remove trip creator');
      }

      // Remove participant
      await _deleteWithFilters(
        table: _participantsTable,
        filters: {
          'trip_id': tripId,
          'user_id': userId,
        },
      );

      await _updateTripParticipantCount(tripId);

      AppLogger.success(_tag, 'Participant removed from trip: $tripId');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to remove participant from trip: $tripId', e, stackTrace);
      rethrow;
    }
  }

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

      AppLogger.success(_tag, 'Retrieved ${participants.length} participants for trip: $tripId');
      return participants;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get trip participants: $tripId', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // SEARCH AND DISCOVERY
  // ===============================

  @override
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
  }) async {
    try {
      AppLogger.debug(_tag, 'Searching public trips with query: $query');

      final filters = <String, dynamic>{'is_public': true};

      if (destination != null) {
        filters['destination'] = destination;
      }
      if (category != null) {
        filters['category'] = category;
      }
      if (maxParticipants != null) {
        // Use simple filter for max participants
        filters['max_participants'] = maxParticipants;
      }

      String orderByField;
      bool orderAscending = ascending;
      if (sortBy != null) {
        orderByField = sortBy;
      } else {
        orderByField = 'created_at';
        orderAscending = false; // desc for created_at by default
      }

      List<Map<String, dynamic>> trips = await SupabaseDatabaseService.select(
        table: _tripsTable,
        filters: filters,
        orderBy: orderByField,
        ascending: orderAscending,
        limit: limit,
        offset: offset,
      );

      // Apply additional filters in memory
      if (query != null && query.isNotEmpty) {
        trips = trips.where((trip) {
          final title = trip['title']?.toString().toLowerCase() ?? '';
          final description = trip['description']?.toString().toLowerCase() ?? '';
          final queryLower = query.toLowerCase();
          return title.contains(queryLower) || description.contains(queryLower);
        }).toList();
      }

      if (startDate != null) {
        trips = trips.where((trip) {
          final tripStartDate = DateTime.tryParse(trip['start_date'] ?? '');
          return tripStartDate != null && tripStartDate.isAfter(startDate);
        }).toList();
      }

      if (endDate != null) {
        trips = trips.where((trip) {
          final tripEndDate = DateTime.tryParse(trip['end_date'] ?? '');
          return tripEndDate != null && tripEndDate.isBefore(endDate);
        }).toList();
      }

      if (tags != null && tags.isNotEmpty) {
        trips = trips.where((trip) {
          final tripTags = List<String>.from(trip['tags'] ?? []);
          return tags.any((tag) => tripTags.contains(tag));
        }).toList();
      }

      for (final trip in trips) {
        await _enrichTripData(trip);
      }

      AppLogger.success(_tag, 'Found ${trips.length} public trips');
      return trips;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to search public trips', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getRecommendedTrips({
    int limit = 10,
  }) async {
    try {
      AppLogger.debug(_tag, 'Getting recommended trips');

      // Simple recommendation: get popular public trips
      final trips = await SupabaseDatabaseService.select(
        table: _tripsTable,
        filters: {'is_public': true, 'status': 'planned'},
        orderBy: 'current_participants',
        ascending: false,
        limit: limit,
      );

      for (final trip in trips) {
        await _enrichTripData(trip);
      }

      AppLogger.success(_tag, 'Retrieved ${trips.length} recommended trips');
      return trips;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get recommended trips', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getTrendingTrips({
    int limit = 10,
  }) async {
    try {
      AppLogger.debug(_tag, 'Getting trending trips');

      // Simple trending: get recently created public trips with participants
      final trips = await SupabaseDatabaseService.select(
        table: _tripsTable,
        filters: {'is_public': true},
        orderBy: 'created_at',
        ascending: false,
        limit: limit,
      );

      // Filter trips with participants
      final trendingTrips = trips.where((trip) => 
        (trip['current_participants'] ?? 0) > 1
      ).toList();

      for (final trip in trendingTrips) {
        await _enrichTripData(trip);
      }

      AppLogger.success(_tag, 'Retrieved ${trendingTrips.length} trending trips');
      return trendingTrips;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get trending trips', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // TRIP STATUS MANAGEMENT
  // ===============================

  @override
  Future<void> startTrip(String tripId) async {
    try {
      AppLogger.debug(_tag, 'Starting trip: $tripId');

      await SupabaseDatabaseService.update(
        table: _tripsTable,
        id: tripId,
        data: {
          'status': 'active',
          'actual_start_date': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
      );

      AppLogger.success(_tag, 'Trip started successfully: $tripId');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to start trip: $tripId', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> completeTrip(String tripId) async {
    try {
      AppLogger.debug(_tag, 'Completing trip: $tripId');

      await SupabaseDatabaseService.update(
        table: _tripsTable,
        id: tripId,
        data: {
          'status': 'completed',
          'actual_end_date': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
      );

      AppLogger.success(_tag, 'Trip completed successfully: $tripId');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to complete trip: $tripId', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> cancelTrip(String tripId, {String? reason}) async {
    try {
      AppLogger.debug(_tag, 'Cancelling trip: $tripId');

      final updateData = {
        'status': 'cancelled',
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (reason != null) {
        updateData['cancellation_reason'] = reason;
      }

      await SupabaseDatabaseService.update(
        table: _tripsTable,
        id: tripId,
        data: updateData,
      );

      AppLogger.success(_tag, 'Trip cancelled successfully: $tripId');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to cancel trip: $tripId', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // ANALYTICS
  // ===============================

  @override
  Future<Map<String, dynamic>> getTripStatistics(String tripId) async {
    try {
      AppLogger.debug(_tag, 'Getting trip statistics: $tripId');

      final trip = await getTrip(tripId);
      if (trip == null) {
        throw Exception('Trip not found: $tripId');
      }

      final participants = await getTripParticipants(tripId);
      
      final statistics = {
        'trip_id': tripId,
        'total_participants': participants.length,
        'max_participants': trip['max_participants'],
        'participation_rate': participants.length / trip['max_participants'],
        'status': trip['status'],
        'days_until_start': _calculateDaysUntilStart(trip['start_date']),
        'trip_duration': _calculateTripDuration(trip['start_date'], trip['end_date']),
        'created_at': trip['created_at'],
        'last_updated': trip['updated_at'],
      };

      AppLogger.success(_tag, 'Retrieved trip statistics: $tripId');
      return statistics;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get trip statistics: $tripId', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> getUserTripStatistics() async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Getting user trip statistics');

      final allTrips = await getUserTrips();
      
      final statistics = {
        'total_trips': allTrips.length,
        'active_trips': allTrips.where((t) => t['status'] == 'active').length,
        'completed_trips': allTrips.where((t) => t['status'] == 'completed').length,
        'planned_trips': allTrips.where((t) => t['status'] == 'planned').length,
        'cancelled_trips': allTrips.where((t) => t['status'] == 'cancelled').length,
        'total_participants_hosted': allTrips.fold<int>(0, (sum, trip) => sum + (trip['current_participants'] as int? ?? 0)),
        'average_trip_duration': _calculateAverageTripDuration(allTrips),
        'most_popular_destination': _getMostPopularDestination(allTrips),
      };

      AppLogger.success(_tag, 'Retrieved user trip statistics');
      return statistics;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get user trip statistics', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // PRIVATE HELPER METHODS
  // ===============================

  Future<void> _addTripParticipant({
    required String tripId,
    required String userId,
    String role = 'participant',
    Map<String, dynamic>? permissions,
  }) async {
    try {
      final participantData = {
        'id': _generateUuid(),
        'trip_id': tripId,
        'user_id': userId,
        'role': role,
        'permissions': permissions,
        'joined_at': DateTime.now().toIso8601String(),
        'status': 'active',
      };

      await SupabaseDatabaseService.insert(
        table: _participantsTable,
        data: participantData,
      );
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to add trip participant', e, stackTrace);
      rethrow;
    }
  }

  Future<void> _updateTripParticipantCount(String tripId) async {
    try {
      final participants = await getTripParticipants(tripId);
      
      await SupabaseDatabaseService.update(
        table: _tripsTable,
        id: tripId,
        data: {
          'current_participants': participants.length,
          'updated_at': DateTime.now().toIso8601String(),
        },
      );
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to update trip participant count', e, stackTrace);
      rethrow;
    }
  }

  Future<void> _enrichTripData(Map<String, dynamic> trip) async {
    try {
      // Add participant count if not present
      if (trip['current_participants'] == null) {
        final participants = await getTripParticipants(trip['id']);
        trip['current_participants'] = participants.length;
      }

      // Add calculated fields
      trip['days_until_start'] = _calculateDaysUntilStart(trip['start_date']);
      trip['trip_duration'] = _calculateTripDuration(trip['start_date'], trip['end_date']);
      trip['is_full'] = (trip['current_participants'] ?? 0) >= (trip['max_participants'] ?? 0);
      trip['participation_rate'] = (trip['current_participants'] ?? 0) / (trip['max_participants'] ?? 1);
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to enrich trip data', e, stackTrace);
      // Don't rethrow for enrichment failures
    }
  }

  int _calculateDaysUntilStart(String? startDateStr) {
    if (startDateStr == null) return 0;
    final startDate = DateTime.tryParse(startDateStr);
    if (startDate == null) return 0;
    return startDate.difference(DateTime.now()).inDays;
  }

  int _calculateTripDuration(String? startDateStr, String? endDateStr) {
    if (startDateStr == null || endDateStr == null) return 0;
    final startDate = DateTime.tryParse(startDateStr);
    final endDate = DateTime.tryParse(endDateStr);
    if (startDate == null || endDate == null) return 0;
    return endDate.difference(startDate).inDays;
  }

  double _calculateAverageTripDuration(List<Map<String, dynamic>> trips) {
    if (trips.isEmpty) return 0.0;
    final totalDuration = trips.fold<int>(0, (sum, trip) => 
      sum + _calculateTripDuration(trip['start_date'], trip['end_date']));
    return totalDuration / trips.length;
  }

  String? _getMostPopularDestination(List<Map<String, dynamic>> trips) {
    if (trips.isEmpty) return null;
    final destinationCounts = <String, int>{};
    for (final trip in trips) {
      final destination = trip['destination'] as String?;
      if (destination != null) {
        destinationCounts[destination] = (destinationCounts[destination] ?? 0) + 1;
      }
    }
    if (destinationCounts.isEmpty) return null;
    return destinationCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }
}
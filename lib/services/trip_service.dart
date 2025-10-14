import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/models/trip_model.dart';
import '../core/utils/logger.dart';
import 'user_safety_service.dart';

/// Service for managing trip planning with itinerary, budget tracking, and safety features - Supabase version
class TripService {
  static const String _tag = 'TripService';
  static TripService? _instance;
  
  // Singleton pattern
  factory TripService() {
    return _instance ??= TripService._();
  }
  
  TripService._();

  final SupabaseClient _supabase = Supabase.instance.client;
  final UserSafetyService _safetyService = UserSafetyService();
  
  // Table names
  static const String _tripsTable = 'trips';
  static const String _itineraryTable = 'trip_itinerary';
  static const String _expensesTable = 'trip_expenses';

  // Cache management
  final Map<String, Trip> _tripCache = {};
  final Map<String, DateTime> _cacheTimestamp = {};
  
  // Rate limiting
  DateTime? _lastWrite;
  DateTime? _lastRead;
  static const Duration _minWriteInterval = Duration(milliseconds: 100);
  static const Duration _minReadInterval = Duration(milliseconds: 50);

  /// Create a new trip
  Future<String?> createTrip({
    required String userId,
    required String userName,
    String? userPhotoUrl,
    required String title,
    required String description,
    required DateTime startDate,
    required DateTime endDate,
    bool isPublic = true,
  }) async {
    try {
      await _ensureWriteInterval();

      AppLogger.debug(_tag, 'Creating new trip', {
        'title': title,
        'userId': userId,
        'isPublic': isPublic,
      });

      final response = await _supabase
          .from(_tripsTable)
          .insert({
            'title': title,
            'description': description,
            'user_id': userId,  // Changed from owner_id to user_id
            'user_name': userName,
            'user_photo_url': userPhotoUrl,
            'start_date': startDate.toIso8601String(),
            'end_date': endDate.toIso8601String(),
            'is_public': isPublic,
            'status': 'planning',
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select('id')
          .single();

      final tripId = response['id'] as String;

      // Clear cache since we have new data
      _tripCache.remove(tripId);
      _cacheTimestamp.remove(tripId);

      AppLogger.success(_tag, 'Trip created successfully', {
        'tripId': tripId,
      });

      return tripId;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to create trip', e, stackTrace);
      return null;
    }
  }

  /// Get trip by ID
  Future<Trip?> getTripById(String tripId) async {
    try {
      await _ensureReadInterval();

      // Check cache first
      if (_isCacheValid(tripId)) {
        return _tripCache[tripId];
      }

      AppLogger.debug(_tag, 'Fetching trip by ID', {'tripId': tripId});

      final response = await _supabase
          .from(_tripsTable)
          .select()
          .eq('id', tripId)
          .maybeSingle();

      if (response == null) {
        AppLogger.warning(_tag, 'Trip not found', {'tripId': tripId});
        return null;
      }

      final trip = Trip.fromSupabase(response);

      // Update cache
      _tripCache[tripId] = trip;
      _cacheTimestamp[tripId] = DateTime.now();

      AppLogger.success(_tag, 'Trip fetched successfully');
      return trip;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to fetch trip', e, stackTrace);
      return null;
    }
  }

  /// Update trip
  Future<bool> updateTrip({
    required String tripId,
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    bool? isPublic,
  }) async {
    try {
      await _ensureWriteInterval();

      AppLogger.debug(_tag, 'Updating trip', {
        'tripId': tripId,
        'hasTitle': title != null,
        'hasDescription': description != null,
      });

      // Build update map with only non-null values
      final Map<String, dynamic> updateData = {};
      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (startDate != null) updateData['start_date'] = startDate.toIso8601String();
      if (endDate != null) updateData['end_date'] = endDate.toIso8601String();
      if (isPublic != null) updateData['is_public'] = isPublic;
      updateData['updated_at'] = DateTime.now().toIso8601String();

      await _supabase
          .from(_tripsTable)
          .update(updateData)
          .eq('id', tripId);

      // Clear cache
      _tripCache.remove(tripId);
      _cacheTimestamp.remove(tripId);

      AppLogger.success(_tag, 'Trip updated successfully');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to update trip', e, stackTrace);
      return false;
    }
  }

  /// Delete trip
  Future<bool> deleteTrip(String tripId) async {
    try {
      await _ensureWriteInterval();

      AppLogger.debug(_tag, 'Deleting trip', {'tripId': tripId});

      await _supabase
          .from(_tripsTable)
          .delete()
          .eq('id', tripId);

      // Clear cache
      _tripCache.remove(tripId);
      _cacheTimestamp.remove(tripId);

      AppLogger.success(_tag, 'Trip deleted successfully');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to delete trip', e, stackTrace);
      return false;
    }
  }

  /// Get user trips
  Future<List<Trip>> getUserTrips(String userId, {int limit = 20, int offset = 0}) async {
    try {
      await _ensureReadInterval();

      AppLogger.debug(_tag, 'Fetching user trips', {
        'userId': userId,
        'limit': limit,
        'offset': offset,
      });

      final response = await _supabase
          .from(_tripsTable)
          .select()
          .eq('owner_id', userId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final trips = response
          .map((data) => Trip.fromSupabase(data))
          .toList();

      AppLogger.success(_tag, 'User trips fetched', {
        'count': trips.length,
      });

      return trips;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to fetch user trips', e, stackTrace);
      return [];
    }
  }

  /// Search public trips
  Future<List<Trip>> searchPublicTrips({
    String? query,
    List<String>? destinations,
    DateTime? startDate,
    DateTime? endDate,
    double? maxBudget,
    List<String>? tags,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      await _ensureReadInterval();

      AppLogger.debug(_tag, 'Searching public trips', {
        'query': query,
        'destinations': destinations?.length,
        'limit': limit,
        'offset': offset,
      });

      var supabaseQuery = _supabase
          .from(_tripsTable)
          .select()
          .eq('is_public', true);

      if (query != null && query.isNotEmpty) {
        supabaseQuery = supabaseQuery.or('title.ilike.%$query%,description.ilike.%$query%');
      }

      if (maxBudget != null) {
        supabaseQuery = supabaseQuery.lte('budget', maxBudget);
      }

      if (startDate != null) {
        supabaseQuery = supabaseQuery.gte('start_date', startDate.toIso8601String());
      }

      if (endDate != null) {
        supabaseQuery = supabaseQuery.lte('end_date', endDate.toIso8601String());
      }

      final response = await supabaseQuery
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final trips = response
          .map((data) => Trip.fromSupabase(data))
          .toList();

      AppLogger.success(_tag, 'Public trips search completed', {
        'count': trips.length,
      });

      return trips;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to search public trips', e, stackTrace);
      return [];
    }
  }

  /// Join trip
  Future<bool> joinTrip({
    required String tripId,
    required String userId,
    String? userName,
    String? userPhotoUrl,
  }) async {
    try {
      await _ensureWriteInterval();

      AppLogger.debug(_tag, 'User joining trip', {
        'tripId': tripId,
        'userId': userId,
      });

      // Get current trip to check participants
      final trip = await getTripById(tripId);
      if (trip == null) {
        AppLogger.error(_tag, 'Trip not found for joining', null);
        return false;
      }

      if (trip.participants.contains(userId)) {
        AppLogger.warning(_tag, 'User already in trip');
        return true;
      }

      if (trip.participants.length >= trip.participantLimit) {
        AppLogger.warning(_tag, 'Trip participant limit reached');
        return false;
      }

      final updatedParticipants = [...trip.participants, userId];

      await _supabase
          .from(_tripsTable)
          .update({
            'participants': updatedParticipants,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', tripId);

      // Clear cache
      _tripCache.remove(tripId);

      AppLogger.success(_tag, 'User joined trip successfully');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to join trip', e, stackTrace);
      return false;
    }
  }

  /// Leave trip
  Future<bool> leaveTrip({
    required String tripId,
    required String userId,
  }) async {
    try {
      await _ensureWriteInterval();

      AppLogger.debug(_tag, 'User leaving trip', {
        'tripId': tripId,
        'userId': userId,
      });

      // Get current trip
      final trip = await getTripById(tripId);
      if (trip == null) {
        AppLogger.error(_tag, 'Trip not found for leaving', null);
        return false;
      }

      if (!trip.participants.contains(userId)) {
        AppLogger.warning(_tag, 'User not in trip');
        return true;
      }

      final updatedParticipants = trip.participants.where((id) => id != userId).toList();

      await _supabase
          .from(_tripsTable)
          .update({
            'participants': updatedParticipants,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', tripId);

      // Clear cache
      _tripCache.remove(tripId);

      AppLogger.success(_tag, 'User left trip successfully');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to leave trip', e, stackTrace);
      return false;
    }
  }

  /// Add expense to trip
  Future<bool> addExpense({
    required String tripId,
    String? description,
    required double amount,
    required BudgetCategory category,
    String? paidBy,
    List<String>? sharedWith,
    DateTime? date,
    String? currency,
    String? notes,
  }) async {
    try {
      await _ensureWriteInterval();

      AppLogger.debug(_tag, 'Adding expense to trip', {
        'tripId': tripId,
        'amount': amount,
        'category': category,
      });

      await _supabase
          .from(_expensesTable)
          .insert({
            'trip_id': tripId,
            'description': description,
            'amount': amount,
            'category': category.name,
            'paid_by': paidBy,
            'shared_with': sharedWith ?? (paidBy != null ? [paidBy] : []),
            'date': (date ?? DateTime.now()).toIso8601String(),
            'currency': currency ?? 'USD',
            'notes': notes,
            'created_at': DateTime.now().toIso8601String(),
          });

      AppLogger.success(_tag, 'Expense added successfully');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to add expense', e, stackTrace);
      return false;
    }
  }

  /// Get trip expenses
  Future<List<Map<String, dynamic>>> getTripExpenses(String tripId) async {
    try {
      await _ensureReadInterval();

      AppLogger.debug(_tag, 'Fetching trip expenses', {'tripId': tripId});

      final response = await _supabase
          .from(_expensesTable)
          .select()
          .eq('trip_id', tripId)
          .order('date', ascending: false);

      AppLogger.success(_tag, 'Trip expenses fetched', {
        'count': response.length,
      });

      return response;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to fetch trip expenses', e, stackTrace);
      return [];
    }
  }

  /// Clear cache
  void clearCache() {
    _tripCache.clear();
    _cacheTimestamp.clear();
    AppLogger.debug(_tag, 'Trip cache cleared');
  }

  /// Clear cache for specific trip
  void clearTripCache(String tripId) {
    _tripCache.remove(tripId);
    _cacheTimestamp.remove(tripId);
    AppLogger.debug(_tag, 'Cache cleared for trip', {'tripId': tripId});
  }

  /// Get real-time stream of trips for a user
  Stream<List<Trip>> getTripsStream({
    required String userId,
    TripFilter? filter,
  }) {
    try {
      AppLogger.debug(_tag, 'Getting trips stream', {'userId': userId});

      return _supabase
          .from(_tripsTable)
          .stream(primaryKey: ['id'])
          .eq('user_id', userId)
          .map((data) {
        return data.map((tripData) => Trip.fromMap(tripData)).toList();
      });
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get trips stream', e, stackTrace);
      return Stream.value([]);
    }
  }

  /// Update an expense
  Future<bool> updateExpense({
    required String tripId,
    required String expenseId,
    required BudgetCategory category,
    required double amount,
    String? description,
    String? notes,
    String? currency,
    DateTime? date,
  }) async {
    try {
      await _ensureWriteInterval();
      AppLogger.debug(_tag, 'Updating expense', {
        'tripId': tripId,
        'expenseId': expenseId,
        'amount': amount,
      });

      await _supabase
          .from('trip_expenses')
          .update({
            'category': category.name,
            'amount': amount,
            'description': description,
            'notes': notes,
            'currency': currency ?? 'USD',
            'date': date?.toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', expenseId)
          .eq('trip_id', tripId);

      AppLogger.success(_tag, 'Expense updated successfully');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to update expense', e, stackTrace);
      return false;
    }
  }

  /// Delete an expense
  Future<bool> deleteExpense({
    required String tripId,
    required String expenseId,
  }) async {
    try {
      await _ensureWriteInterval();
      AppLogger.debug(_tag, 'Deleting expense', {
        'tripId': tripId,
        'expenseId': expenseId,
      });

      await _supabase
          .from('trip_expenses')
          .delete()
          .eq('id', expenseId)
          .eq('trip_id', tripId);

      AppLogger.success(_tag, 'Expense deleted successfully');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to delete expense', e, stackTrace);
      return false;
    }
  }

  /// Add itinerary item
  Future<bool> addItineraryItem({
    required String tripId,
    required String title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    String? location,
    ItineraryType? type,
    String? notes,
    double? cost,
  }) async {
    try {
      await _ensureWriteInterval();
      AppLogger.debug(_tag, 'Adding itinerary item', {
        'tripId': tripId,
        'title': title,
      });

      await _supabase
          .from(_itineraryTable)
          .insert({
            'trip_id': tripId,
            'title': title,
            'description': description,
            'start_time': startTime?.toIso8601String(),
            'end_time': endTime?.toIso8601String(),
            'location': location,
            'type': type?.name,
            'notes': notes,
            'cost': cost,
            'created_at': DateTime.now().toIso8601String(),
          });

      AppLogger.success(_tag, 'Itinerary item added successfully');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to add itinerary item', e, stackTrace);
      return false;
    }
  }

  /// Update itinerary item
  Future<bool> updateItineraryItem({
    required String tripId,
    required String itemId,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    String? location,
    String? notes,
    double? cost,
    bool? isCompleted,
  }) async {
    try {
      await _ensureWriteInterval();
      AppLogger.debug(_tag, 'Updating itinerary item', {
        'tripId': tripId,
        'itemId': itemId,
        'title': title,
      });

      await _supabase
          .from(_itineraryTable)
          .update({
            if (title != null) 'title': title,
            if (description != null) 'description': description,
            if (startTime != null) 'start_time': startTime.toIso8601String(),
            if (endTime != null) 'end_time': endTime.toIso8601String(),
            if (location != null) 'location': location,
            if (notes != null) 'notes': notes,
            if (cost != null) 'cost': cost,
            if (isCompleted != null) 'is_completed': isCompleted,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', itemId)
          .eq('trip_id', tripId);

      AppLogger.success(_tag, 'Itinerary item updated successfully');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to update itinerary item', e, stackTrace);
      return false;
    }
  }

  /// Delete itinerary item
  Future<bool> deleteItineraryItem({
    required String tripId,
    required String itemId,
  }) async {
    try {
      await _ensureWriteInterval();
      AppLogger.debug(_tag, 'Deleting itinerary item', {
        'tripId': tripId,
        'itemId': itemId,
      });

      await _supabase
          .from(_itineraryTable)
          .delete()
          .eq('id', itemId)
          .eq('trip_id', tripId);

      AppLogger.success(_tag, 'Itinerary item deleted successfully');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to delete itinerary item', e, stackTrace);
      return false;
    }
  }

  /// Reorder itinerary items
  Future<bool> reorderItineraryItems({
    required String tripId,
    required List<String> itemIds,
  }) async {
    try {
      await _ensureWriteInterval();
      AppLogger.debug(_tag, 'Reordering itinerary items', {
        'tripId': tripId,
        'itemCount': itemIds.length,
      });

      // Update order for each item
      for (int i = 0; i < itemIds.length; i++) {
        await _supabase
            .from(_itineraryTable)
            .update({
              'order': i,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', itemIds[i])
            .eq('trip_id', tripId);
      }

      AppLogger.success(_tag, 'Itinerary items reordered successfully');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to reorder itinerary items', e, stackTrace);
      return false;
    }
  }

  /// Set trip budget
  Future<bool> setTripBudget({
    required String tripId,
    required double amount,
    String currency = 'USD',
  }) async {
    try {
      await _ensureWriteInterval();
      AppLogger.debug(_tag, 'Setting trip budget', {
        'tripId': tripId,
        'amount': amount,
        'currency': currency,
      });

      await _supabase
          .from(_tripsTable)
          .update({
            'budget': amount,
            'currency': currency,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', tripId);

      AppLogger.success(_tag, 'Trip budget set successfully');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to set trip budget', e, stackTrace);
      return false;
    }
  }

  bool _isCacheValid(String tripId) {
    final timestamp = _cacheTimestamp[tripId];
    if (timestamp == null) return false;
    
    return DateTime.now().difference(timestamp) < const Duration(minutes: 15);
  }

  Future<void> _ensureWriteInterval() async {
    if (_lastWrite != null) {
      final timeSinceLastWrite = DateTime.now().difference(_lastWrite!);
      if (timeSinceLastWrite < _minWriteInterval) {
        await Future.delayed(_minWriteInterval - timeSinceLastWrite);
      }
    }
    _lastWrite = DateTime.now();
  }

  Future<void> _ensureReadInterval() async {
    if (_lastRead != null) {
      final timeSinceLastRead = DateTime.now().difference(_lastRead!);
      if (timeSinceLastRead < _minReadInterval) {
        await Future.delayed(_minReadInterval - timeSinceLastRead);
      }
    }
    _lastRead = DateTime.now();
  }
}
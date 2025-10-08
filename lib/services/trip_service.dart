import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/models/trip_model.dart';
import '../core/utils/logger.dart';
import 'user_safety_service.dart';

/// Service for managing trip planning with itinerary, budget tracking, and safety features
class TripService {
  static const String _tag = 'TripService';
  static TripService? _instance;
  
  // Singleton pattern
  factory TripService() {
    return _instance ??= TripService._();
  }
  
  TripService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserSafetyService _safetyService = UserSafetyService();
  CollectionReference get _tripsCollection => _firestore.collection('trips');

  // Cache management
  final Map<String, Trip> _tripCache = {};
  final Map<String, DateTime> _cacheTimestamp = {};
  static const Duration _cacheDuration = Duration(minutes: 15);
  
  // Batch operations
  WriteBatch? _batch;
  int _batchOperations = 0;
  static const int _maxBatchOperations = 500;
  
  // Rate limiting
  DateTime? _lastWrite;
  DateTime? _lastRead;
  static const Duration _minWriteInterval = Duration(milliseconds: 100);
  static const Duration _minReadInterval = Duration(milliseconds: 50);

  /// Create a new trip
  // Initialize batch if needed
  void _initializeBatchIfNeeded() {
    if (_batch == null) {
      _batch = _firestore.batch();
      _batchOperations = 0;
      AppLogger.debug(_tag, 'Initialized new batch');
    }
  }

  // Commit batch if needed
  Future<void> _commitBatchIfNeeded() async {
    if (_batch != null && _batchOperations >= _maxBatchOperations) {
      AppLogger.debug(_tag, 'Committing batch', {
        'operations': _batchOperations,
      });
      await _batch!.commit();
      _batch = null;
      _batchOperations = 0;
    }
  }

  // Ensure write interval
  Future<void> _ensureWriteInterval() async {
    if (_lastWrite != null) {
      final timeSinceLastWrite = DateTime.now().difference(_lastWrite!);
      if (timeSinceLastWrite < _minWriteInterval) {
        await Future.delayed(_minWriteInterval - timeSinceLastWrite);
      }
    }
    _lastWrite = DateTime.now();
  }

  // Ensure read interval
  Future<void> _ensureReadInterval() async {
    if (_lastRead != null) {
      final timeSinceLastRead = DateTime.now().difference(_lastRead!);
      if (timeSinceLastRead < _minReadInterval) {
        await Future.delayed(_minReadInterval - timeSinceLastRead);
      }
    }
    _lastRead = DateTime.now();
  }

  // Update cache
  void _updateCache(String tripId, Trip trip) {
    _tripCache[tripId] = trip;
    _cacheTimestamp[tripId] = DateTime.now();
    AppLogger.debug(_tag, 'Updated cache', {
      'tripId': tripId,
    });
  }

  // Get from cache if valid
  Trip? _getFromCache(String tripId) {
    final timestamp = _cacheTimestamp[tripId];
    if (timestamp != null && 
        DateTime.now().difference(timestamp) < _cacheDuration) {
      AppLogger.debug(_tag, 'Retrieved from cache', {
        'tripId': tripId,
      });
      return _tripCache[tripId];
    }
    return null;
  }

  // Clear cache for trip
  void _clearCache(String tripId) {
    _tripCache.remove(tripId);
    _cacheTimestamp.remove(tripId);
    AppLogger.debug(_tag, 'Cleared cache', {
      'tripId': tripId,
    });
  }

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
      AppLogger.debug(_tag, 'Creating trip', {
        'title': title,
        'userId': userId,
      });

      final now = DateTime.now();

      final trip = Trip(
        id: '',
        userId: userId,
        userName: userName,
        userPhotoUrl: userPhotoUrl,
        title: title,
        description: description,
        startDate: startDate,
        endDate: endDate,
        participantIds: [userId],
        participants: {
          userId: ParticipantInfo(
            name: userName,
            photoUrl: userPhotoUrl,
            joinedAt: now,
          ),
        },
        isPublic: isPublic,
        createdAt: now,
        updatedAt: now,
      );

      final docRef = await _tripsCollection.add(trip.toFirestore());

      AppLogger.info(_tag, 'Trip created successfully', {
        'tripId': docRef.id,
      });

      return docRef.id;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to create trip', e, stackTrace);
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
    TripStatus? status,
    bool? isPublic,
  }) async {
    try {
      AppLogger.debug(_tag, 'Updating trip', {'tripId': tripId});

      final updates = <String, dynamic>{
        'updatedAt': Timestamp.now(),
      };

      if (title != null) updates['title'] = title;
      if (description != null) updates['description'] = description;
      if (startDate != null) updates['startDate'] = Timestamp.fromDate(startDate);
      if (endDate != null) updates['endDate'] = Timestamp.fromDate(endDate);
      if (status != null) updates['status'] = status.toString().split('.').last;
      if (isPublic != null) updates['isPublic'] = isPublic;

      await _tripsCollection.doc(tripId).update(updates);

      AppLogger.info(_tag, 'Trip updated successfully');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to update trip', e, stackTrace);
      return false;
    }
  }

  /// Delete trip
  Future<bool> deleteTrip(String tripId) async {
    try {
      AppLogger.debug(_tag, 'Deleting trip', {'tripId': tripId});

      await _tripsCollection.doc(tripId).delete();

      AppLogger.info(_tag, 'Trip deleted successfully');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to delete trip', e, stackTrace);
      return false;
    }
  }

  /// Add destination to trip
  Future<bool> addDestination({
    required String tripId,
    required String destinationId,
    required String destinationName,
    String? imageUrl,
    DateTime? scheduledDate,
    String? notes,
  }) async {
    try {
      AppLogger.debug(_tag, 'Adding destination to trip', {
        'tripId': tripId,
        'destinationId': destinationId,
      });

      final doc = await _tripsCollection.doc(tripId).get();
      if (!doc.exists) return false;

      final trip = Trip.fromFirestore(doc);

      final newDestination = TripDestination(
        id: destinationId,
        name: destinationName,
        imageUrl: imageUrl,
        scheduledDate: scheduledDate,
        notes: notes,
        order: trip.destinations.length,
      );

      await _tripsCollection.doc(tripId).update({
        'destinationIds': FieldValue.arrayUnion([destinationId]),
        'destinations': FieldValue.arrayUnion([newDestination.toMap()]),
        'updatedAt': Timestamp.now(),
      });

      AppLogger.info(_tag, 'Destination added successfully');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to add destination', e, stackTrace);
      return false;
    }
  }

  /// Remove destination from trip
  Future<bool> removeDestination({
    required String tripId,
    required String destinationId,
  }) async {
    try {
      AppLogger.debug(_tag, 'Removing destination from trip', {
        'tripId': tripId,
        'destinationId': destinationId,
      });

      final doc = await _tripsCollection.doc(tripId).get();
      if (!doc.exists) return false;

      final trip = Trip.fromFirestore(doc);

      final updatedDestinations = trip.destinations
          .where((d) => d.id != destinationId)
          .toList();

      await _tripsCollection.doc(tripId).update({
        'destinationIds': FieldValue.arrayRemove([destinationId]),
        'destinations': updatedDestinations.map((d) => d.toMap()).toList(),
        'updatedAt': Timestamp.now(),
      });

      AppLogger.info(_tag, 'Destination removed successfully');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to remove destination', e, stackTrace);
      return false;
    }
  }

  /// Join trip with safety checks
  Future<bool> joinTrip({
    required String tripId,
    required String userId,
    required String userName,
    String? userPhotoUrl,
  }) async {
    try {
      AppLogger.debug(_tag, 'User joining trip', {
        'tripId': tripId,
        'userId': userId,
      });

      await _ensureWriteInterval();

      // Get trip details to check owner and participants
      final tripDoc = await _tripsCollection.doc(tripId).get();
      if (!tripDoc.exists) {
        AppLogger.warning(_tag, 'Trip not found', {'tripId': tripId});
        return false;
      }

      final trip = Trip.fromFirestore(tripDoc);

      // Safety check: Verify user is not blocked by trip owner
      final isBlockedByOwner = await _safetyService.isUserBlocked(
        userId: trip.userId,
        blockedUserId: userId,
      );

      if (isBlockedByOwner) {
        AppLogger.warning(_tag, 'User blocked by trip owner', {
          'userId': userId,
          'ownerId': trip.userId,
        });
        return false;
      }

      // Safety check: Verify user has not blocked trip owner
      final hasBlockedOwner = await _safetyService.isUserBlocked(
        userId: userId,
        blockedUserId: trip.userId,
      );

      if (hasBlockedOwner) {
        AppLogger.warning(_tag, 'User has blocked trip owner', {
          'userId': userId,
          'ownerId': trip.userId,
        });
        return false;
      }

      // Safety check: Verify user is not blocked by any participant
      final blockedUsers = await _safetyService.getBlockedUsers(userId);
      final hasBlockedParticipants = trip.participantIds
          .any((participantId) => blockedUsers.contains(participantId));

      if (hasBlockedParticipants) {
        AppLogger.warning(_tag, 'User has blocked relationships with participants', {
          'userId': userId,
        });
        return false;
      }

      // All safety checks passed, proceed with join
      final participantInfo = ParticipantInfo(
        name: userName,
        photoUrl: userPhotoUrl,
        joinedAt: DateTime.now(),
      );

      await _tripsCollection.doc(tripId).update({
        'participantIds': FieldValue.arrayUnion([userId]),
        'participants.$userId': participantInfo.toMap(),
        'updatedAt': Timestamp.now(),
      });

      _clearCache(tripId);

      AppLogger.info(_tag, 'User joined trip successfully', {
        'tripId': tripId,
        'userId': userId,
      });
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
      AppLogger.debug(_tag, 'User leaving trip', {
        'tripId': tripId,
        'userId': userId,
      });

      await _tripsCollection.doc(tripId).update({
        'participantIds': FieldValue.arrayRemove([userId]),
        'participants.$userId': FieldValue.delete(),
        'updatedAt': Timestamp.now(),
      });

      AppLogger.info(_tag, 'User left trip successfully');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to leave trip', e, stackTrace);
      return false;
    }
  }

  /// Get trips stream for user
  Stream<List<Trip>> getTripsStream({
    required String userId,
    TripFilter filter = TripFilter.all,
  }) {
    AppLogger.debug(_tag, 'Getting trips stream', {
      'userId': userId,
      'filter': filter.toString(),
    });

    Query query = _tripsCollection;

    // Apply filters
    switch (filter) {
      case TripFilter.myTrips:
        query = query.where('userId', isEqualTo: userId);
        break;
      case TripFilter.joined:
        query = query.where('participantIds', arrayContains: userId);
        break;
      case TripFilter.all:
      case TripFilter.upcoming:
      case TripFilter.ongoing:
      case TripFilter.past:
        query = query.where('participantIds', arrayContains: userId);
        break;
    }

    return query
        .orderBy('startDate', descending: false)
        .snapshots()
        .map((snapshot) {
      var trips = snapshot.docs.map((doc) => Trip.fromFirestore(doc)).toList();

      // Apply date-based filters
      switch (filter) {
        case TripFilter.upcoming:
          trips = trips.where((trip) => trip.isUpcoming).toList();
          break;
        case TripFilter.ongoing:
          trips = trips.where((trip) => trip.isOngoing).toList();
          break;
        case TripFilter.past:
          trips = trips.where((trip) => trip.isPast).toList();
          break;
        default:
          break;
      }

      AppLogger.debug(_tag, 'Trips stream update', {
        'count': trips.length,
      });

      return trips;
    });
  }

  /// Get trip by ID
  Future<Trip?> getTripById(String tripId) async {
    try {
      final doc = await _tripsCollection.doc(tripId).get();
      if (!doc.exists) return null;

      return Trip.fromFirestore(doc);
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get trip', e, stackTrace);
      return null;
    }
  }

  /// Get public trips (discover) with safety filtering
  Stream<List<Trip>> getPublicTripsStream({
    required String currentUserId,
    int limit = 20,
  }) async* {
    AppLogger.debug(_tag, 'Getting public trips stream', {
      'userId': currentUserId,
      'limit': limit,
    });

    await for (final snapshot in _tripsCollection
        .where('isPublic', isEqualTo: true)
        .where('startDate', isGreaterThan: Timestamp.now())
        .orderBy('startDate', descending: false)
        .limit(limit * 2) // Fetch more to account for filtering
        .snapshots()) {
      
      // Get blocked users list
      final blockedUsers = await _safetyService.getBlockedUsers(currentUserId);
      
      // Filter trips from blocked users
      final trips = snapshot.docs
          .map((doc) => Trip.fromFirestore(doc))
          .where((trip) => !blockedUsers.contains(trip.userId))
          .take(limit)
          .toList();

      AppLogger.debug(_tag, 'Public trips filtered', {
        'totalFetched': snapshot.docs.length,
        'afterFiltering': trips.length,
      });

      yield trips;
    }
  }

  // ==================== ITINERARY MANAGEMENT ====================

  /// Add itinerary item to trip
  Future<bool> addItineraryItem({
    required String tripId,
    required String title,
    String? description,
    required DateTime startTime,
    required DateTime endTime,
    String? location,
    String? locationId,
    ItineraryType type = ItineraryType.activity,
    String? notes,
  }) async {
    try {
      await _ensureWriteInterval();

      AppLogger.debug(_tag, 'Adding itinerary item', {
        'tripId': tripId,
        'title': title,
        'type': type.toString(),
      });

      // Get current trip to calculate order
      final doc = await _tripsCollection.doc(tripId).get();
      if (!doc.exists) {
        AppLogger.warning(_tag, 'Trip not found', {'tripId': tripId});
        return false;
      }

      final trip = Trip.fromFirestore(doc);

      // Check for time conflicts
      final hasConflict = trip.itinerary.any((item) {
        return (startTime.isBefore(item.endTime) && 
                endTime.isAfter(item.startTime));
      });

      if (hasConflict) {
        AppLogger.warning(_tag, 'Itinerary time conflict detected', {
          'startTime': startTime.toIso8601String(),
          'endTime': endTime.toIso8601String(),
        });
      }

      final newItem = ItineraryItem(
        id: _firestore.collection('_').doc().id, // Generate unique ID
        title: title,
        description: description,
        startTime: startTime,
        endTime: endTime,
        location: location,
        locationId: locationId,
        type: type,
        notes: notes,
        order: trip.itinerary.length,
      );

      await _tripsCollection.doc(tripId).update({
        'itinerary': FieldValue.arrayUnion([newItem.toMap()]),
        'updatedAt': Timestamp.now(),
      });

      _clearCache(tripId);

      AppLogger.info(_tag, 'Itinerary item added successfully', {
        'tripId': tripId,
        'itemId': newItem.id,
      });
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
    bool? isCompleted,
  }) async {
    try {
      await _ensureWriteInterval();

      AppLogger.debug(_tag, 'Updating itinerary item', {
        'tripId': tripId,
        'itemId': itemId,
      });

      final doc = await _tripsCollection.doc(tripId).get();
      if (!doc.exists) return false;

      final trip = Trip.fromFirestore(doc);
      final updatedItinerary = trip.itinerary.map((item) {
        if (item.id == itemId) {
          return ItineraryItem(
            id: item.id,
            title: title ?? item.title,
            description: description ?? item.description,
            startTime: startTime ?? item.startTime,
            endTime: endTime ?? item.endTime,
            location: location ?? item.location,
            locationId: item.locationId,
            type: item.type,
            notes: notes ?? item.notes,
            isCompleted: isCompleted ?? item.isCompleted,
            order: item.order,
          );
        }
        return item;
      }).toList();

      await _tripsCollection.doc(tripId).update({
        'itinerary': updatedItinerary.map((i) => i.toMap()).toList(),
        'updatedAt': Timestamp.now(),
      });

      _clearCache(tripId);

      AppLogger.info(_tag, 'Itinerary item updated successfully');
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

      final doc = await _tripsCollection.doc(tripId).get();
      if (!doc.exists) return false;

      final trip = Trip.fromFirestore(doc);
      final updatedItinerary = trip.itinerary
          .where((item) => item.id != itemId)
          .toList();

      await _tripsCollection.doc(tripId).update({
        'itinerary': updatedItinerary.map((i) => i.toMap()).toList(),
        'updatedAt': Timestamp.now(),
      });

      _clearCache(tripId);

      AppLogger.info(_tag, 'Itinerary item deleted successfully');
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

      final doc = await _tripsCollection.doc(tripId).get();
      if (!doc.exists) return false;

      final trip = Trip.fromFirestore(doc);
      final itemMap = {for (var item in trip.itinerary) item.id: item};

      final reorderedItinerary = <ItineraryItem>[];
      for (var i = 0; i < itemIds.length; i++) {
        final item = itemMap[itemIds[i]];
        if (item != null) {
          reorderedItinerary.add(ItineraryItem(
            id: item.id,
            title: item.title,
            description: item.description,
            startTime: item.startTime,
            endTime: item.endTime,
            location: item.location,
            locationId: item.locationId,
            type: item.type,
            notes: item.notes,
            isCompleted: item.isCompleted,
            order: i,
          ));
        }
      }

      await _tripsCollection.doc(tripId).update({
        'itinerary': reorderedItinerary.map((i) => i.toMap()).toList(),
        'updatedAt': Timestamp.now(),
      });

      _clearCache(tripId);

      AppLogger.info(_tag, 'Itinerary items reordered successfully');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to reorder itinerary items', e, stackTrace);
      return false;
    }
  }

  // ==================== BUDGET MANAGEMENT ====================

  /// Set trip budget
  Future<bool> setTripBudget({
    required String tripId,
    required double totalBudget,
    String currency = 'USD',
    Map<BudgetCategory, double>? categoryBudgets,
  }) async {
    try {
      await _ensureWriteInterval();

      AppLogger.debug(_tag, 'Setting trip budget', {
        'tripId': tripId,
        'totalBudget': totalBudget,
        'currency': currency,
      });

      final now = DateTime.now();
      final budget = TripBudget(
        totalBudget: totalBudget,
        currency: currency,
        categoryBudgets: categoryBudgets ?? {},
        createdAt: now,
        updatedAt: now,
      );

      await _tripsCollection.doc(tripId).update({
        'budget': budget.toMap(),
        'updatedAt': Timestamp.now(),
      });

      _clearCache(tripId);

      AppLogger.info(_tag, 'Trip budget set successfully', {
        'tripId': tripId,
        'amount': totalBudget,
      });
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to set trip budget', e, stackTrace);
      return false;
    }
  }

  /// Add expense to trip
  Future<bool> addExpense({
    required String tripId,
    required String description,
    required double amount,
    String currency = 'USD',
    required BudgetCategory category,
    required DateTime date,
    String? paidBy,
    List<String>? sharedWith,
    String? receiptUrl,
    String? notes,
  }) async {
    try {
      await _ensureWriteInterval();

      AppLogger.debug(_tag, 'Adding expense', {
        'tripId': tripId,
        'description': description,
        'amount': amount,
        'category': category.toString(),
      });

      final expense = BudgetExpense(
        id: _firestore.collection('_').doc().id,
        description: description,
        amount: amount,
        currency: currency,
        category: category,
        date: date,
        paidBy: paidBy,
        sharedWith: sharedWith ?? [],
        receiptUrl: receiptUrl,
        notes: notes,
        createdAt: DateTime.now(),
      );

      await _tripsCollection.doc(tripId).update({
        'expenses': FieldValue.arrayUnion([expense.toMap()]),
        'updatedAt': Timestamp.now(),
      });

      _clearCache(tripId);

      AppLogger.info(_tag, 'Expense added successfully', {
        'tripId': tripId,
        'expenseId': expense.id,
        'amount': amount,
      });
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to add expense', e, stackTrace);
      return false;
    }
  }

  /// Update expense
  Future<bool> updateExpense({
    required String tripId,
    required String expenseId,
    String? description,
    double? amount,
    BudgetCategory? category,
    DateTime? date,
    String? receiptUrl,
    String? notes,
  }) async {
    try {
      await _ensureWriteInterval();

      AppLogger.debug(_tag, 'Updating expense', {
        'tripId': tripId,
        'expenseId': expenseId,
      });

      final doc = await _tripsCollection.doc(tripId).get();
      if (!doc.exists) return false;

      final trip = Trip.fromFirestore(doc);
      final updatedExpenses = trip.expenses.map((expense) {
        if (expense.id == expenseId) {
          return BudgetExpense(
            id: expense.id,
            description: description ?? expense.description,
            amount: amount ?? expense.amount,
            currency: expense.currency,
            category: category ?? expense.category,
            date: date ?? expense.date,
            paidBy: expense.paidBy,
            sharedWith: expense.sharedWith,
            receiptUrl: receiptUrl ?? expense.receiptUrl,
            notes: notes ?? expense.notes,
            createdAt: expense.createdAt,
          );
        }
        return expense;
      }).toList();

      await _tripsCollection.doc(tripId).update({
        'expenses': updatedExpenses.map((e) => e.toMap()).toList(),
        'updatedAt': Timestamp.now(),
      });

      _clearCache(tripId);

      AppLogger.info(_tag, 'Expense updated successfully');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to update expense', e, stackTrace);
      return false;
    }
  }

  /// Delete expense
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

      final doc = await _tripsCollection.doc(tripId).get();
      if (!doc.exists) return false;

      final trip = Trip.fromFirestore(doc);
      final updatedExpenses = trip.expenses
          .where((expense) => expense.id != expenseId)
          .toList();

      await _tripsCollection.doc(tripId).update({
        'expenses': updatedExpenses.map((e) => e.toMap()).toList(),
        'updatedAt': Timestamp.now(),
      });

      _clearCache(tripId);

      AppLogger.info(_tag, 'Expense deleted successfully');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to delete expense', e, stackTrace);
      return false;
    }
  }

  /// Get expenses by category
  Future<Map<BudgetCategory, double>> getExpensesByCategory(String tripId) async {
    try {
      await _ensureReadInterval();

      AppLogger.debug(_tag, 'Getting expenses by category', {
        'tripId': tripId,
      });

      final doc = await _tripsCollection.doc(tripId).get();
      if (!doc.exists) return {};

      final trip = Trip.fromFirestore(doc);
      final categoryTotals = <BudgetCategory, double>{};

      for (final expense in trip.expenses) {
        categoryTotals[expense.category] = 
            (categoryTotals[expense.category] ?? 0.0) + expense.amount;
      }

      AppLogger.debug(_tag, 'Expenses calculated by category', {
        'categories': categoryTotals.length,
      });

      return categoryTotals;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get expenses by category', e, stackTrace);
      return {};
    }
  }

  /// Get budget summary
  Future<Map<String, dynamic>> getBudgetSummary(String tripId) async {
    try {
      await _ensureReadInterval();

      AppLogger.debug(_tag, 'Getting budget summary', {
        'tripId': tripId,
      });

      final doc = await _tripsCollection.doc(tripId).get();
      if (!doc.exists) return {};

      final trip = Trip.fromFirestore(doc);
      final categoryExpenses = await getExpensesByCategory(tripId);

      final summary = {
        'totalBudget': trip.budget?.totalBudget ?? 0.0,
        'totalSpent': trip.totalSpent,
        'remaining': trip.budgetRemaining,
        'isOverBudget': trip.isOverBudget,
        'usagePercentage': trip.budgetUsagePercentage,
        'categoryExpenses': categoryExpenses,
        'expenseCount': trip.expenses.length,
      };

      AppLogger.debug(_tag, 'Budget summary calculated', {
        'totalBudget': summary['totalBudget'],
        'totalSpent': summary['totalSpent'],
      });

      return summary;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get budget summary', e, stackTrace);
      return {};
    }
  }
}


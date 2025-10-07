import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/models/trip_model.dart';
import '../core/utils/logger.dart';

/// Service for managing trip planning
class TripService {
  static const String _tag = 'TripService';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _tripsCollection => _firestore.collection('trips');

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

  /// Join trip
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

      AppLogger.info(_tag, 'User joined trip successfully');
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

  /// Get public trips (discover)
  Stream<List<Trip>> getPublicTripsStream({int limit = 20}) {
    return _tripsCollection
        .where('isPublic', isEqualTo: true)
        .where('startDate', isGreaterThan: Timestamp.now())
        .orderBy('startDate', descending: false)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Trip.fromFirestore(doc)).toList();
    });
  }
}

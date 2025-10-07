import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../core/models/itinerary_model.dart';
import '../core/utils/logger.dart';

/// Service for managing trip itineraries
class ItineraryService {
  static const String _tag = 'ItineraryService';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  CollectionReference get _itinerariesCollection =>
      _firestore.collection('itineraries');

  /// Get itinerary for a trip
  Future<TripItinerary?> getItinerary(String tripId) async {
    try {
      AppLogger.debug(_tag, 'Getting itinerary', {'tripId': tripId});

      final querySnapshot = await _itinerariesCollection
          .where('tripId', isEqualTo: tripId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        AppLogger.debug(_tag, 'No itinerary found for trip');
        return null;
      }

      return TripItinerary.fromFirestore(querySnapshot.docs.first);
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get itinerary', e, stackTrace);
      return null;
    }
  }

  /// Create new itinerary for trip
  Future<TripItinerary?> createItinerary({
    required String tripId,
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      AppLogger.debug(_tag, 'Creating itinerary', {
        'tripId': tripId,
        'days': endDate.difference(startDate).inDays + 1,
      });

      final now = DateTime.now();

      // Generate days for the trip
      final days = <ItineraryDay>[];
      var currentDate = startDate;

      while (currentDate.isBefore(endDate) ||
          _isSameDay(currentDate, endDate)) {
        days.add(ItineraryDay(
          date: currentDate,
          activities: [],
          notes: '',
        ));
        currentDate = currentDate.add(const Duration(days: 1));
      }

      final itinerary = TripItinerary(
        id: '',
        tripId: tripId,
        userId: userId,
        days: days,
        createdAt: now,
        updatedAt: now,
      );

      final docRef = await _itinerariesCollection.add(itinerary.toFirestore());

      AppLogger.info(_tag, 'Itinerary created successfully', {
        'itineraryId': docRef.id,
        'dayCount': days.length,
      });

      return TripItinerary.fromFirestore(await docRef.get());
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to create itinerary', e, stackTrace);
      return null;
    }
  }

  /// Add activity to a specific day
  Future<bool> addActivity({
    required String itineraryId,
    required DateTime date,
    required ItineraryActivity activity,
  }) async {
    try {
      AppLogger.debug(_tag, 'Adding activity', {
        'itineraryId': itineraryId,
        'date': date.toString(),
        'activityTitle': activity.title,
      });

      final doc = await _itinerariesCollection.doc(itineraryId).get();
      if (!doc.exists) {
        AppLogger.warning(_tag, 'Itinerary not found');
        return false;
      }

      final itinerary = TripItinerary.fromFirestore(doc);

      // Find the day and add activity
      final updatedDays = itinerary.days.map((day) {
        if (_isSameDay(day.date, date)) {
          return day.copyWith(
            activities: [...day.activities, activity],
          );
        }
        return day;
      }).toList();

      await _itinerariesCollection.doc(itineraryId).update({
        'days': updatedDays.map((d) => d.toMap()).toList(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      AppLogger.info(_tag, 'Activity added successfully');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to add activity', e, stackTrace);
      return false;
    }
  }

  /// Update activity
  Future<bool> updateActivity({
    required String itineraryId,
    required DateTime date,
    required String activityId,
    required ItineraryActivity updatedActivity,
  }) async {
    try {
      AppLogger.debug(_tag, 'Updating activity', {
        'itineraryId': itineraryId,
        'activityId': activityId,
      });

      final doc = await _itinerariesCollection.doc(itineraryId).get();
      if (!doc.exists) {
        AppLogger.warning(_tag, 'Itinerary not found');
        return false;
      }

      final itinerary = TripItinerary.fromFirestore(doc);

      // Find the day and update activity
      final updatedDays = itinerary.days.map((day) {
        if (_isSameDay(day.date, date)) {
          final updatedActivities = day.activities.map((activity) {
            return activity.id == activityId ? updatedActivity : activity;
          }).toList();
          return day.copyWith(activities: updatedActivities);
        }
        return day;
      }).toList();

      await _itinerariesCollection.doc(itineraryId).update({
        'days': updatedDays.map((d) => d.toMap()).toList(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      AppLogger.info(_tag, 'Activity updated successfully');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to update activity', e, stackTrace);
      return false;
    }
  }

  /// Delete activity
  Future<bool> deleteActivity({
    required String itineraryId,
    required DateTime date,
    required String activityId,
  }) async {
    try {
      AppLogger.debug(_tag, 'Deleting activity', {
        'itineraryId': itineraryId,
        'activityId': activityId,
      });

      final doc = await _itinerariesCollection.doc(itineraryId).get();
      if (!doc.exists) {
        AppLogger.warning(_tag, 'Itinerary not found');
        return false;
      }

      final itinerary = TripItinerary.fromFirestore(doc);

      // Find the day and remove activity
      final updatedDays = itinerary.days.map((day) {
        if (_isSameDay(day.date, date)) {
          final updatedActivities = day.activities
              .where((activity) => activity.id != activityId)
              .toList();
          return day.copyWith(activities: updatedActivities);
        }
        return day;
      }).toList();

      await _itinerariesCollection.doc(itineraryId).update({
        'days': updatedDays.map((d) => d.toMap()).toList(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      AppLogger.info(_tag, 'Activity deleted successfully');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to delete activity', e, stackTrace);
      return false;
    }
  }

  /// Update day notes
  Future<bool> updateDayNotes({
    required String itineraryId,
    required DateTime date,
    required String notes,
  }) async {
    try {
      AppLogger.debug(_tag, 'Updating day notes', {
        'itineraryId': itineraryId,
        'date': date.toString(),
      });

      final doc = await _itinerariesCollection.doc(itineraryId).get();
      if (!doc.exists) {
        AppLogger.warning(_tag, 'Itinerary not found');
        return false;
      }

      final itinerary = TripItinerary.fromFirestore(doc);

      // Find the day and update notes
      final updatedDays = itinerary.days.map((day) {
        if (_isSameDay(day.date, date)) {
          return day.copyWith(notes: notes);
        }
        return day;
      }).toList();

      await _itinerariesCollection.doc(itineraryId).update({
        'days': updatedDays.map((d) => d.toMap()).toList(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      AppLogger.info(_tag, 'Day notes updated successfully');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to update day notes', e, stackTrace);
      return false;
    }
  }

  /// Toggle activity completion
  Future<bool> toggleActivityCompletion({
    required String itineraryId,
    required DateTime date,
    required String activityId,
  }) async {
    try {
      AppLogger.debug(_tag, 'Toggling activity completion', {
        'itineraryId': itineraryId,
        'activityId': activityId,
      });

      final doc = await _itinerariesCollection.doc(itineraryId).get();
      if (!doc.exists) {
        AppLogger.warning(_tag, 'Itinerary not found');
        return false;
      }

      final itinerary = TripItinerary.fromFirestore(doc);

      // Find the day and toggle activity completion
      final updatedDays = itinerary.days.map((day) {
        if (_isSameDay(day.date, date)) {
          final updatedActivities = day.activities.map((activity) {
            if (activity.id == activityId) {
              return activity.copyWith(isCompleted: !activity.isCompleted);
            }
            return activity;
          }).toList();
          return day.copyWith(activities: updatedActivities);
        }
        return day;
      }).toList();

      await _itinerariesCollection.doc(itineraryId).update({
        'days': updatedDays.map((d) => d.toMap()).toList(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      AppLogger.info(_tag, 'Activity completion toggled');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to toggle activity completion', e, stackTrace);
      return false;
    }
  }

  /// Generate unique activity ID
  String generateActivityId() {
    return _uuid.v4();
  }

  /// Check if two dates are on the same day
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// Get itinerary stream (real-time)
  Stream<TripItinerary?> getItineraryStream(String tripId) {
    AppLogger.debug(_tag, 'Getting itinerary stream', {'tripId': tripId});

    return _itinerariesCollection
        .where('tripId', isEqualTo: tripId)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return TripItinerary.fromFirestore(snapshot.docs.first);
    });
  }

  /// Delete itinerary
  Future<bool> deleteItinerary(String itineraryId) async {
    try {
      AppLogger.debug(_tag, 'Deleting itinerary', {
        'itineraryId': itineraryId,
      });

      await _itinerariesCollection.doc(itineraryId).delete();

      AppLogger.info(_tag, 'Itinerary deleted successfully');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to delete itinerary', e, stackTrace);
      return false;
    }
  }

  /// Get total estimated cost for itinerary
  Future<double> getTotalEstimatedCost(String itineraryId) async {
    try {
      final doc = await _itinerariesCollection.doc(itineraryId).get();
      if (!doc.exists) return 0.0;

      final itinerary = TripItinerary.fromFirestore(doc);

      double total = 0.0;
      for (var day in itinerary.days) {
        for (var activity in day.activities) {
          total += activity.estimatedCost ?? 0.0;
        }
      }

      return total;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to calculate total cost', e, stackTrace);
      return 0.0;
    }
  }
}

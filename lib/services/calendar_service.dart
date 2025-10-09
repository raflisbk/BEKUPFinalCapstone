import '../core/models/trip_model.dart';
import '../core/models/itinerary_model.dart';
import '../core/utils/logger.dart';

/// Calendar event model
class CalendarEvent {
  final String id;
  final String title;
  final String? description;
  final DateTime startDate;
  final DateTime endDate;
  final String? location;
  final bool isAllDay;
  final String? calendarId;

  const CalendarEvent({
    required this.id,
    required this.title,
    this.description,
    required this.startDate,
    required this.endDate,
    this.location,
    this.isAllDay = false,
    this.calendarId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'location': location,
      'isAllDay': isAllDay,
      'calendarId': calendarId,
    };
  }
}

/// Service for device calendar integration
class CalendarService {
  static const String _tag = 'CalendarService';

  // In a real implementation, this would use device_calendar package
  // For now, we'll create a mock implementation that demonstrates the functionality

  /// Check if calendar permissions are granted
  Future<bool> hasCalendarPermission() async {
    try {
      AppLogger.debug(_tag, 'Checking calendar permission');

      // Mock implementation
      // In real app: await DeviceCalendarPlugin().hasPermissions()
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to check calendar permission', e, stackTrace);
      return false;
    }
  }

  /// Request calendar permissions
  Future<bool> requestCalendarPermission() async {
    try {
      AppLogger.debug(_tag, 'Requesting calendar permission');

      // Mock implementation
      // In real app: await DeviceCalendarPlugin().requestPermissions()
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to request calendar permission', e, stackTrace);
      return false;
    }
  }

  /// Sync trip to device calendar
  Future<bool> syncTripToCalendar(Trip trip) async {
    try {
      AppLogger.info(_tag, 'Syncing trip to calendar', {
        'tripId': trip.id,
        'tripName': trip.title,
      });

      final hasPermission = await hasCalendarPermission();
      if (!hasPermission) {
        final granted = await requestCalendarPermission();
        if (!granted) {
          AppLogger.warning(_tag, 'Calendar permission not granted');
          return false;
        }
      }

      // Create main trip event
      final tripEvent = CalendarEvent(
        id: 'trip_${trip.id}',
        title: trip.title,
        description: trip.description,
        startDate: trip.startDate,
        endDate: trip.endDate,
        location: trip.destinations.isNotEmpty ? trip.destinations.first.name : null,
        isAllDay: true,
      );

      await _addEventToCalendar(tripEvent);

      AppLogger.success(_tag, 'Trip synced to calendar successfully');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to sync trip to calendar', e, stackTrace);
      return false;
    }
  }

  /// Sync itinerary activities to calendar
  Future<bool> syncItineraryToCalendar(
    Trip trip,
    List<ItineraryDay> itineraries,
  ) async {
    try {
      AppLogger.info(_tag, 'Syncing itinerary to calendar', {
        'tripId': trip.id,
        'daysCount': itineraries.length,
      });

      final hasPermission = await hasCalendarPermission();
      if (!hasPermission) {
        final granted = await requestCalendarPermission();
        if (!granted) {
          AppLogger.warning(_tag, 'Calendar permission not granted');
          return false;
        }
      }

      int activityCount = 0;

      for (var dailyItinerary in itineraries) {
        for (var activity in dailyItinerary.activities) {
          final activityEvent = CalendarEvent(
            id: 'activity_${activity.id}',
            title: '${trip.title} - ${activity.title}',
            description: activity.description,
            startDate: _combineDateTime(dailyItinerary.date, activity.startTime ?? '09:00'),
            endDate: _combineDateTime(dailyItinerary.date, activity.endTime ?? '10:00'),
            location: activity.location,
            isAllDay: false,
          );

          await _addEventToCalendar(activityEvent);
          activityCount++;
        }
      }

      AppLogger.success(_tag, 'Itinerary synced to calendar', {
        'activitiesCount': activityCount,
      });
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to sync itinerary to calendar', e, stackTrace);
      return false;
    }
  }

  /// Remove trip from calendar
  Future<bool> removeTripFromCalendar(String tripId) async {
    try {
      AppLogger.info(_tag, 'Removing trip from calendar', {
        'tripId': tripId,
      });

      await _deleteEventFromCalendar('trip_$tripId');

      AppLogger.success(_tag, 'Trip removed from calendar');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to remove trip from calendar', e, stackTrace);
      return false;
    }
  }

  /// Remove itinerary activities from calendar
  Future<bool> removeItineraryFromCalendar(List<String> activityIds) async {
    try {
      AppLogger.info(_tag, 'Removing itinerary from calendar', {
        'activitiesCount': activityIds.length,
      });

      for (var activityId in activityIds) {
        await _deleteEventFromCalendar('activity_$activityId');
      }

      AppLogger.success(_tag, 'Itinerary removed from calendar');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to remove itinerary from calendar', e, stackTrace);
      return false;
    }
  }

  /// Get available calendars on device
  Future<List<Map<String, dynamic>>> getDeviceCalendars() async {
    try {
      AppLogger.debug(_tag, 'Getting device calendars');

      // Mock implementation
      // In real app: await DeviceCalendarPlugin().retrieveCalendars()
      return [
        {
          'id': 'default',
          'name': 'Default Calendar',
          'isReadOnly': false,
        },
      ];
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get device calendars', e, stackTrace);
      return [];
    }
  }

  /// Create reminder for trip
  Future<bool> createTripReminder(
    Trip trip, {
    Duration beforeStart = const Duration(days: 1),
  }) async {
    try {
      AppLogger.info(_tag, 'Creating trip reminder', {
        'tripId': trip.id,
        'beforeStart': beforeStart.inDays,
      });

      final reminderDate = trip.startDate.subtract(beforeStart);

      final reminderEvent = CalendarEvent(
        id: 'reminder_${trip.id}',
        title: '🧳 Reminder: ${trip.title} starts tomorrow',
        description: 'Your trip "${trip.title}" starts on ${trip.startDate.toString().split(' ')[0]}',
        startDate: reminderDate,
        endDate: reminderDate.add(const Duration(hours: 1)),
        isAllDay: false,
      );

      await _addEventToCalendar(reminderEvent);

      AppLogger.success(_tag, 'Trip reminder created');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to create trip reminder', e, stackTrace);
      return false;
    }
  }

  /// Private helper: Add event to calendar
  Future<void> _addEventToCalendar(CalendarEvent event) async {
    // Mock implementation
    // In real app:
    // final calendar = await _getOrCreateReLinkcalendar();
    // final calendarEvent = Event(calendar.id)
    //   ..title = event.title
    //   ..description = event.description
    //   ..start = event.startDate
    //   ..end = event.endDate
    //   ..location = event.location;
    // await DeviceCalendarPlugin().createOrUpdateEvent(calendarEvent);

    AppLogger.debug(_tag, 'Event added to calendar', {
      'eventId': event.id,
      'title': event.title,
    });

    // Simulate async operation
    await Future.delayed(const Duration(milliseconds: 100));
  }

  /// Private helper: Delete event from calendar
  Future<void> _deleteEventFromCalendar(String eventId) async {
    // Mock implementation
    // In real app:
    // await DeviceCalendarPlugin().deleteEvent(calendarId, eventId);

    AppLogger.debug(_tag, 'Event deleted from calendar', {
      'eventId': eventId,
    });

    // Simulate async operation
    await Future.delayed(const Duration(milliseconds: 100));
  }

  /// Private helper: Combine date and time
  DateTime _combineDateTime(DateTime date, String time) {
    final timeParts = time.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    return DateTime(
      date.year,
      date.month,
      date.day,
      hour,
      minute,
    );
  }

  /// Check if trip is already synced to calendar
  Future<bool> isTripSynced(String tripId) async {
    try {
      // Mock implementation
      // In real app: check if event exists in calendar
      return false;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to check trip sync status', e, stackTrace);
      return false;
    }
  }

  /// Update trip in calendar when trip details change
  Future<bool> updateTripInCalendar(Trip trip) async {
    try {
      AppLogger.info(_tag, 'Updating trip in calendar', {
        'tripId': trip.id,
      });

      // Remove old event and create new one
      await removeTripFromCalendar(trip.id);
      await syncTripToCalendar(trip);

      AppLogger.success(_tag, 'Trip updated in calendar');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to update trip in calendar', e, stackTrace);
      return false;
    }
  }
}

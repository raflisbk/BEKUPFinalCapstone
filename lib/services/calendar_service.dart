import 'dart:async';
import '../core/utils/logger.dart';
import 'supabase_config.dart';
import 'supabase_database_service.dart';

/// Calendar Service
/// Handles calendar integration, event scheduling, and reminders
class CalendarService {
  static const String _tag = 'CalendarService';
  static const String _eventsTable = 'calendar_events';
  static const String _remindersTable = 'event_reminders';
  static const String _availabilityTable = 'user_availability';

  // ===============================
  // EVENT MANAGEMENT
  // ===============================

  /// Create calendar event
  static Future<Map<String, dynamic>> createEvent({
    required String title,
    required DateTime startTime,
    required DateTime endTime,
    String? description,
    String? location,
    String? tripId,
    String? itineraryId,
    String? activityId,
    String? type,
    List<String>? attendees,
    Map<String, dynamic>? metadata,
    bool isAllDay = false,
    String? recurrenceRule,
  }) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Creating calendar event: $title');

      final eventData = {
        'created_by': userId,
        'title': title,
        'description': description,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
        'location': location,
        'trip_id': tripId,
        'itinerary_id': itineraryId,
        'activity_id': activityId,
        'type': type ?? 'general',
        'attendees': attendees ?? [],
        'metadata': metadata ?? {},
        'is_all_day': isAllDay,
        'recurrence_rule': recurrenceRule,
        'status': 'confirmed',
        'is_private': false,
        'reminder_count': 0,
      };

      final result = await SupabaseDatabaseService.insert(
        table: _eventsTable,
        data: eventData,
      );

      AppLogger.success(_tag, 'Calendar event created successfully: $title');
      return result;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to create calendar event', e, stackTrace);
      rethrow;
    }
  }

  /// Get user events
  static Future<List<Map<String, dynamic>>> getUserEvents({
    DateTime? startDate,
    DateTime? endDate,
    String? tripId,
    String? type,
    String? status,
    int limit = 100,
  }) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Getting user events');

      final filters = <String, dynamic>{'created_by': userId};
      if (tripId != null) filters['trip_id'] = tripId;
      if (type != null) filters['type'] = type;
      if (status != null) filters['status'] = status;

      var events = await SupabaseDatabaseService.select(
        table: _eventsTable,
        filters: filters,
        orderBy: 'start_time',
        limit: limit,
      );

      // Filter by date range if provided
      if (startDate != null || endDate != null) {
        events = events.where((event) {
          final eventStart = DateTime.parse(event['start_time']);
          final eventEnd = DateTime.parse(event['end_time']);
          
          if (startDate != null && eventEnd.isBefore(startDate)) {
            return false;
          }
          
          if (endDate != null && eventStart.isAfter(endDate)) {
            return false;
          }
          
          return true;
        }).toList();
      }

      // Get reminders for each event
      for (final event in events) {
        event['reminders'] = await getEventReminders(event['id']);
      }

      AppLogger.success(_tag, 'Retrieved ${events.length} events');
      return events;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get user events', e, stackTrace);
      rethrow;
    }
  }

  /// Get events by date range
  static Future<List<Map<String, dynamic>>> getEventsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
    String? tripId,
  }) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Getting events by date range: ${startDate.toIso8601String()} to ${endDate.toIso8601String()}');

      final filters = <String, dynamic>{'created_by': userId};
      if (tripId != null) filters['trip_id'] = tripId;

      final events = await SupabaseDatabaseService.select(
        table: _eventsTable,
        filters: filters,
        orderBy: 'start_time',
      );

      // Filter events that overlap with the date range
      final filteredEvents = events.where((event) {
        final eventStart = DateTime.parse(event['start_time']);
        final eventEnd = DateTime.parse(event['end_time']);
        
        // Check if event overlaps with the date range
        return eventStart.isBefore(endDate) && eventEnd.isAfter(startDate);
      }).toList();

      AppLogger.success(_tag, 'Retrieved ${filteredEvents.length} events in date range');
      return filteredEvents;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get events by date range', e, stackTrace);
      rethrow;
    }
  }

  /// Update event
  static Future<Map<String, dynamic>> updateEvent({
    required String eventId,
    String? title,
    DateTime? startTime,
    DateTime? endTime,
    String? description,
    String? location,
    String? type,
    List<String>? attendees,
    String? status,
    bool? isAllDay,
    String? recurrenceRule,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      AppLogger.debug(_tag, 'Updating event: $eventId');

      final updateData = <String, dynamic>{};
      
      if (title != null) updateData['title'] = title;
      if (startTime != null) updateData['start_time'] = startTime.toIso8601String();
      if (endTime != null) updateData['end_time'] = endTime.toIso8601String();
      if (description != null) updateData['description'] = description;
      if (location != null) updateData['location'] = location;
      if (type != null) updateData['type'] = type;
      if (attendees != null) updateData['attendees'] = attendees;
      if (status != null) updateData['status'] = status;
      if (isAllDay != null) updateData['is_all_day'] = isAllDay;
      if (recurrenceRule != null) updateData['recurrence_rule'] = recurrenceRule;
      if (metadata != null) updateData['metadata'] = metadata;

      if (updateData.isEmpty) {
        throw Exception('No data provided for update');
      }

      final result = await SupabaseDatabaseService.update(
        table: _eventsTable,
        id: eventId,
        data: updateData,
      );

      AppLogger.success(_tag, 'Event updated successfully');
      return result;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to update event', e, stackTrace);
      rethrow;
    }
  }

  /// Delete event
  static Future<void> deleteEvent(String eventId) async {
    try {
      AppLogger.warning(_tag, 'Deleting event: $eventId');

      // Delete all reminders for this event
      final reminders = await SupabaseDatabaseService.select(
        table: _remindersTable,
        filters: {'event_id': eventId},
      );
      
      for (final reminder in reminders) {
        await SupabaseDatabaseService.delete(
          table: _remindersTable,
          id: reminder['id'],
        );
      }

      // Delete the event
      await SupabaseDatabaseService.delete(
        table: _eventsTable,
        id: eventId,
      );

      AppLogger.success(_tag, 'Event deleted successfully');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to delete event', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // EVENT REMINDERS
  // ===============================

  /// Add reminder to event
  static Future<Map<String, dynamic>> addReminder({
    required String eventId,
    required Duration reminderTime, // How long before the event
    String? title,
    String? message,
    String? type,
    bool isEnabled = true,
  }) async {
    try {
      AppLogger.debug(_tag, 'Adding reminder to event: $eventId');

      final reminderData = {
        'event_id': eventId,
        'reminder_minutes': reminderTime.inMinutes,
        'title': title,
        'message': message,
        'type': type ?? 'notification',
        'is_enabled': isEnabled,
        'is_sent': false,
      };

      final result = await SupabaseDatabaseService.insert(
        table: _remindersTable,
        data: reminderData,
      );

      // Update event reminder count
      await _updateEventReminderCount(eventId);

      AppLogger.success(_tag, 'Reminder added successfully');
      return result;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to add reminder', e, stackTrace);
      rethrow;
    }
  }

  /// Get event reminders
  static Future<List<Map<String, dynamic>>> getEventReminders(String eventId) async {
    try {
      AppLogger.debug(_tag, 'Getting reminders for event: $eventId');

      final reminders = await SupabaseDatabaseService.select(
        table: _remindersTable,
        filters: {'event_id': eventId},
        orderBy: 'reminder_minutes',
      );

      AppLogger.success(_tag, 'Retrieved ${reminders.length} reminders');
      return reminders;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get event reminders', e, stackTrace);
      rethrow;
    }
  }

  /// Get pending reminders
  static Future<List<Map<String, dynamic>>> getPendingReminders() async {
    try {
      AppLogger.debug(_tag, 'Getting pending reminders');

      final now = DateTime.now();
      
      // Get all events with their reminders
      final events = await SupabaseDatabaseService.select(
        table: _eventsTable,
        filters: {'status': 'confirmed'},
        orderBy: 'start_time',
      );

      final pendingReminders = <Map<String, dynamic>>[];

      for (final event in events) {
        final eventStartTime = DateTime.parse(event['start_time']);
        
        // Skip past events
        if (eventStartTime.isBefore(now)) continue;

        final reminders = await getEventReminders(event['id']);
        
        for (final reminder in reminders) {
          if (!reminder['is_enabled'] || reminder['is_sent']) continue;
          
          final reminderMinutes = reminder['reminder_minutes'] as int;
          final reminderTime = eventStartTime.subtract(Duration(minutes: reminderMinutes));
          
          // Check if reminder time has passed
          if (reminderTime.isBefore(now) || reminderTime.isAtSameMomentAs(now)) {
            pendingReminders.add({
              ...reminder,
              'event': event,
              'reminder_time': reminderTime.toIso8601String(),
            });
          }
        }
      }

      AppLogger.success(_tag, 'Retrieved ${pendingReminders.length} pending reminders');
      return pendingReminders;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get pending reminders', e, stackTrace);
      rethrow;
    }
  }

  /// Mark reminder as sent
  static Future<void> markReminderAsSent(String reminderId) async {
    try {
      AppLogger.debug(_tag, 'Marking reminder as sent: $reminderId');

      await SupabaseDatabaseService.update(
        table: _remindersTable,
        id: reminderId,
        data: {'is_sent': true},
      );

      AppLogger.success(_tag, 'Reminder marked as sent');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to mark reminder as sent', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // USER AVAILABILITY
  // ===============================

  /// Set user availability
  static Future<Map<String, dynamic>> setAvailability({
    required DateTime date,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    String? status,
    String? note,
  }) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Setting user availability for: ${date.toIso8601String()}');

      final availabilityData = {
        'user_id': userId,
        'date': date.toIso8601String().split('T')[0], // Date only
        'start_time': '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
        'end_time': '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
        'status': status ?? 'available',
        'note': note,
      };

      // Check if availability already exists for this date
      final existingAvailability = await SupabaseDatabaseService.select(
        table: _availabilityTable,
        filters: {
          'user_id': userId,
          'date': availabilityData['date'],
        },
      );

      Map<String, dynamic> result;
      
      if (existingAvailability.isNotEmpty) {
        // Update existing availability
        result = await SupabaseDatabaseService.update(
          table: _availabilityTable,
          id: existingAvailability.first['id'],
          data: availabilityData,
        );
      } else {
        // Create new availability
        result = await SupabaseDatabaseService.insert(
          table: _availabilityTable,
          data: availabilityData,
        );
      }

      AppLogger.success(_tag, 'User availability set successfully');
      return result;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to set user availability', e, stackTrace);
      rethrow;
    }
  }

  /// Get user availability for date range
  static Future<List<Map<String, dynamic>>> getUserAvailability({
    String? userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final currentUserId = userId ?? SupabaseConfig.userId;
      if (currentUserId == null) {
        throw Exception('No user ID provided');
      }

      AppLogger.debug(_tag, 'Getting user availability for: $currentUserId');

      final availability = await SupabaseDatabaseService.select(
        table: _availabilityTable,
        filters: {'user_id': currentUserId},
        orderBy: 'date',
      );

      // Filter by date range
      final filteredAvailability = availability.where((avail) {
        final availDate = DateTime.parse(avail['date']);
        return !availDate.isBefore(startDate) && !availDate.isAfter(endDate);
      }).toList();

      AppLogger.success(_tag, 'Retrieved ${filteredAvailability.length} availability records');
      return filteredAvailability;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get user availability', e, stackTrace);
      rethrow;
    }
  }

  /// Check if user is available at specific time
  static Future<bool> isUserAvailable({
    String? userId,
    required DateTime dateTime,
  }) async {
    try {
      final currentUserId = userId ?? SupabaseConfig.userId;
      if (currentUserId == null) {
        throw Exception('No user ID provided');
      }

      AppLogger.debug(_tag, 'Checking user availability at: ${dateTime.toIso8601String()}');

      final dateString = dateTime.toIso8601String().split('T')[0];
      final timeString = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

      final availability = await SupabaseDatabaseService.select(
        table: _availabilityTable,
        filters: {
          'user_id': currentUserId,
          'date': dateString,
        },
      );

      if (availability.isEmpty) {
        // No availability set, assume available
        return true;
      }

      final userAvailability = availability.first;
      final startTime = userAvailability['start_time'] as String;
      final endTime = userAvailability['end_time'] as String;
      final status = userAvailability['status'] as String;

      // Check if time is within available range and status is available
      final isWithinTimeRange = timeString.compareTo(startTime) >= 0 && 
                               timeString.compareTo(endTime) <= 0;
      
      final isAvailable = status == 'available' && isWithinTimeRange;

      AppLogger.success(_tag, 'User availability check complete: $isAvailable');
      return isAvailable;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to check user availability', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // CALENDAR INTEGRATION
  // ===============================

  /// Sync events from external calendar
  static Future<List<Map<String, dynamic>>> syncExternalCalendar({
    required String calendarProvider, // google, outlook, etc.
    required String accessToken,
    DateTime? lastSyncTime,
  }) async {
    try {
      AppLogger.debug(_tag, 'Syncing external calendar: $calendarProvider');

      // This is a placeholder for external calendar integration
      // In production, implement actual API calls to calendar providers
      
      final syncedEvents = <Map<String, dynamic>>[];
      
      // Simulate syncing events
      // In real implementation, fetch events from external API
      // and create/update local events accordingly
      
      AppLogger.success(_tag, 'External calendar sync completed: ${syncedEvents.length} events');
      return syncedEvents;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to sync external calendar', e, stackTrace);
      rethrow;
    }
  }

  /// Export events to external calendar format (iCal)
  static Future<String> exportToICal({
    List<String>? eventIds,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      AppLogger.debug(_tag, 'Exporting events to iCal format');

      List<Map<String, dynamic>> eventsToExport;

      if (eventIds != null) {
        // Export specific events
        eventsToExport = [];
        for (final eventId in eventIds) {
          final events = await SupabaseDatabaseService.select(
            table: _eventsTable,
            filters: {'id': eventId},
          );
          if (events.isNotEmpty) {
            eventsToExport.add(events.first);
          }
        }
      } else {
        // Export events by date range
        eventsToExport = await getEventsByDateRange(
          startDate: startDate ?? DateTime.now(),
          endDate: endDate ?? DateTime.now().add(const Duration(days: 365)),
        );
      }

      // Generate iCal content
      final icalContent = _generateICalContent(eventsToExport);

      AppLogger.success(_tag, 'Events exported to iCal format');
      return icalContent;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to export events to iCal', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // CALENDAR ANALYTICS
  // ===============================

  /// Get calendar statistics
  static Future<Map<String, dynamic>> getCalendarStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Getting calendar statistics');

      final dateStart = startDate ?? DateTime.now().subtract(const Duration(days: 30));
      final dateEnd = endDate ?? DateTime.now().add(const Duration(days: 30));

      final events = await getEventsByDateRange(
        startDate: dateStart,
        endDate: dateEnd,
      );

      final stats = {
        'total_events': events.length,
        'upcoming_events': events.where((e) => 
          DateTime.parse(e['start_time']).isAfter(DateTime.now())
        ).length,
        'past_events': events.where((e) => 
          DateTime.parse(e['end_time']).isBefore(DateTime.now())
        ).length,
        'events_by_type': <String, int>{},
        'events_by_status': <String, int>{},
        'total_event_hours': 0.0,
        'busiest_day': null,
        'busiest_day_count': 0,
      };

      final eventsByDay = <String, int>{};
      double totalHours = 0;

      for (final event in events) {
        final type = event['type'] as String? ?? 'general';
        final status = event['status'] as String? ?? 'confirmed';
        final startTime = DateTime.parse(event['start_time']);
        final endTime = DateTime.parse(event['end_time']);
        final duration = endTime.difference(startTime).inHours;

        // Count by type
        final eventsByType = stats['events_by_type'] as Map<String, int>;
        eventsByType[type] = (eventsByType[type] ?? 0) + 1;
        
        // Count by status
        final eventsByStatus = stats['events_by_status'] as Map<String, int>;
        eventsByStatus[status] = (eventsByStatus[status] ?? 0) + 1;
        
        // Add to total hours
        totalHours += duration;

        // Count events by day
        final dayKey = '${startTime.year}-${startTime.month.toString().padLeft(2, '0')}-${startTime.day.toString().padLeft(2, '0')}';
        eventsByDay[dayKey] = (eventsByDay[dayKey] ?? 0) + 1;
      }

      stats['total_event_hours'] = totalHours;

      // Find busiest day
      if (eventsByDay.isNotEmpty) {
        final busiestEntry = eventsByDay.entries.reduce((a, b) => a.value > b.value ? a : b);
        stats['busiest_day'] = busiestEntry.key;
        stats['busiest_day_count'] = busiestEntry.value;
      }

      AppLogger.success(_tag, 'Calendar statistics retrieved');
      return stats;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get calendar statistics', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // PRIVATE HELPER METHODS
  // ===============================

  /// Update event reminder count
  static Future<void> _updateEventReminderCount(String eventId) async {
    try {
      final reminders = await getEventReminders(eventId);
      
      await SupabaseDatabaseService.update(
        table: _eventsTable,
        id: eventId,
        data: {'reminder_count': reminders.length},
      );
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to update event reminder count', e);
    }
  }

  /// Generate iCal content from events
  static String _generateICalContent(List<Map<String, dynamic>> events) {
    final buffer = StringBuffer();
    
    // iCal header
    buffer.writeln('BEGIN:VCALENDAR');
    buffer.writeln('VERSION:2.0');
    buffer.writeln('PRODID:-//Relink Travel App//Calendar//EN');
    buffer.writeln('CALSCALE:GREGORIAN');
    buffer.writeln('METHOD:PUBLISH');

    // Add events
    for (final event in events) {
      buffer.writeln('BEGIN:VEVENT');
      buffer.writeln('UID:${event['id']}@relink.app');
      buffer.writeln('DTSTART:${_formatDateTimeForICal(DateTime.parse(event['start_time']))}');
      buffer.writeln('DTEND:${_formatDateTimeForICal(DateTime.parse(event['end_time']))}');
      buffer.writeln('SUMMARY:${event['title'] ?? ''}');
      
      if (event['description'] != null) {
        buffer.writeln('DESCRIPTION:${event['description']}');
      }
      
      if (event['location'] != null) {
        buffer.writeln('LOCATION:${event['location']}');
      }
      
      buffer.writeln('STATUS:${(event['status'] ?? 'CONFIRMED').toUpperCase()}');
      buffer.writeln('CREATED:${_formatDateTimeForICal(DateTime.parse(event['created_at'] ?? DateTime.now().toIso8601String()))}');
      buffer.writeln('LAST-MODIFIED:${_formatDateTimeForICal(DateTime.parse(event['updated_at'] ?? DateTime.now().toIso8601String()))}');
      buffer.writeln('END:VEVENT');
    }

    // iCal footer
    buffer.writeln('END:VCALENDAR');

    return buffer.toString();
  }

  /// Format DateTime for iCal format
  static String _formatDateTimeForICal(DateTime dateTime) {
    final utc = dateTime.toUtc();
    return '${utc.year}${utc.month.toString().padLeft(2, '0')}${utc.day.toString().padLeft(2, '0')}T${utc.hour.toString().padLeft(2, '0')}${utc.minute.toString().padLeft(2, '0')}${utc.second.toString().padLeft(2, '0')}Z';
  }
}

/// Time of Day helper class for calendar service
class TimeOfDay {
  final int hour;
  final int minute;

  const TimeOfDay({required this.hour, required this.minute});

  @override
  String toString() => '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}
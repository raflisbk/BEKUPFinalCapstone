import 'dart:async';
import '../core/utils/logger.dart';
import 'supabase_config.dart';
import 'supabase_database_service.dart';

/// Itinerary Service
/// Handles trip itinerary planning, activities, and schedule management
class ItineraryService {
  static const String _tag = 'ItineraryService';
  static const String _tableName = 'trip_itinerary';
  static const String _activitiesTable = 'itinerary_activities';
  static const String _templatesTable = 'itinerary_templates';

  // Singleton pattern
  static ItineraryService? _instance;
  static ItineraryService get instance => _instance ??= ItineraryService._internal();
  
  ItineraryService._internal();

  // ===============================
  // ITINERARY CRUD OPERATIONS
  // ===============================

  /// Create itinerary for trip
  static Future<Map<String, dynamic>> createItinerary({
    required String tripId,
    required String title,
    String? description,
    DateTime? date,
    int dayNumber = 1,
    Map<String, dynamic>? preferences,
  }) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Creating itinerary for trip: $tripId');

      final itineraryData = {
        'trip_id': tripId,
        'created_by': userId,
        'title': title,
        'description': description,
        'date': date?.toIso8601String(),
        'day_number': dayNumber,
        'preferences': preferences ?? {},
        'activity_count': 0,
        'estimated_duration_minutes': 0,
        'estimated_cost': 0.0,
        'status': 'draft',
      };

      final result = await SupabaseDatabaseService.insert(
        table: _tableName,
        data: itineraryData,
      );

      AppLogger.success(_tag, 'Itinerary created successfully: $title');
      return result;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to create itinerary', e, stackTrace);
      rethrow;
    }
  }

  /// Get itinerary by ID
  static Future<Map<String, dynamic>?> getItinerary(String itineraryId) async {
    try {
      AppLogger.debug(_tag, 'Getting itinerary: $itineraryId');

      final itineraries = await SupabaseDatabaseService.select(
        table: _tableName,
        filters: {'id': itineraryId},
      );

      if (itineraries.isEmpty) {
        AppLogger.warning(_tag, 'Itinerary not found: $itineraryId');
        return null;
      }

      final itinerary = itineraries.first;
      
      // Get activities for this itinerary
      itinerary['activities'] = await getItineraryActivities(itineraryId);

      AppLogger.success(_tag, 'Retrieved itinerary: ${itinerary['title']}');
      return itinerary;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get itinerary', e, stackTrace);
      rethrow;
    }
  }

  /// Get trip itineraries
  static Future<List<Map<String, dynamic>>> getTripItineraries(String tripId) async {
    try {
      AppLogger.debug(_tag, 'Getting itineraries for trip: $tripId');

      final itineraries = await SupabaseDatabaseService.select(
        table: _tableName,
        filters: {'trip_id': tripId},
        orderBy: 'day_number',
      );

      // Get activities for each itinerary
      for (final itinerary in itineraries) {
        itinerary['activities'] = await getItineraryActivities(itinerary['id']);
      }

      AppLogger.success(_tag, 'Retrieved ${itineraries.length} itineraries');
      return itineraries;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get trip itineraries', e, stackTrace);
      rethrow;
    }
  }

  /// Update itinerary
  static Future<Map<String, dynamic>> updateItinerary({
    required String itineraryId,
    String? title,
    String? description,
    DateTime? date,
    int? dayNumber,
    String? status,
    Map<String, dynamic>? preferences,
  }) async {
    try {
      AppLogger.debug(_tag, 'Updating itinerary: $itineraryId');

      final updateData = <String, dynamic>{};
      
      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (date != null) updateData['date'] = date.toIso8601String();
      if (dayNumber != null) updateData['day_number'] = dayNumber;
      if (status != null) updateData['status'] = status;
      if (preferences != null) updateData['preferences'] = preferences;

      if (updateData.isEmpty) {
        throw Exception('No data provided for update');
      }

      final result = await SupabaseDatabaseService.update(
        table: _tableName,
        id: itineraryId,
        data: updateData,
      );

      AppLogger.success(_tag, 'Itinerary updated successfully');
      return result;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to update itinerary', e, stackTrace);
      rethrow;
    }
  }

  /// Delete itinerary
  static Future<void> deleteItinerary(String itineraryId) async {
    try {
      AppLogger.warning(_tag, 'Deleting itinerary: $itineraryId');

      await SupabaseDatabaseService.delete(
        table: _tableName,
        id: itineraryId,
      );

      AppLogger.success(_tag, 'Itinerary deleted successfully');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to delete itinerary', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // ACTIVITY MANAGEMENT
  // ===============================

  /// Add activity to itinerary
  static Future<Map<String, dynamic>> addActivity({
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
  }) async {
    try {
      AppLogger.debug(_tag, 'Adding activity to itinerary: $itineraryId');

      final activityData = {
        'itinerary_id': itineraryId,
        'title': title,
        'type': type,
        'description': description,
        'location': location,
        'latitude': latitude,
        'longitude': longitude,
        'start_time': startTime?.toIso8601String(),
        'end_time': endTime?.toIso8601String(),
        'estimated_cost': estimatedCost ?? 0.0,
        'actual_cost': 0.0,
        'details': details ?? {},
        'sort_order': sortOrder ?? 0,
        'status': 'planned',
        'is_completed': false,
      };

      final result = await SupabaseDatabaseService.insert(
        table: _activitiesTable,
        data: activityData,
      );

      // Update itinerary statistics
      await _updateItineraryStats(itineraryId);

      AppLogger.success(_tag, 'Activity added successfully: $title');
      return result;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to add activity', e, stackTrace);
      rethrow;
    }
  }

  /// Update activity
  static Future<Map<String, dynamic>> updateActivity({
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
  }) async {
    try {
      AppLogger.debug(_tag, 'Updating activity: $activityId');

      final updateData = <String, dynamic>{};
      
      if (title != null) updateData['title'] = title;
      if (type != null) updateData['type'] = type;
      if (description != null) updateData['description'] = description;
      if (location != null) updateData['location'] = location;
      if (latitude != null) updateData['latitude'] = latitude;
      if (longitude != null) updateData['longitude'] = longitude;
      if (startTime != null) updateData['start_time'] = startTime.toIso8601String();
      if (endTime != null) updateData['end_time'] = endTime.toIso8601String();
      if (estimatedCost != null) updateData['estimated_cost'] = estimatedCost;
      if (actualCost != null) updateData['actual_cost'] = actualCost;
      if (status != null) updateData['status'] = status;
      if (isCompleted != null) updateData['is_completed'] = isCompleted;
      if (details != null) updateData['details'] = details;
      if (sortOrder != null) updateData['sort_order'] = sortOrder;

      if (updateData.isEmpty) {
        throw Exception('No data provided for update');
      }

      final result = await SupabaseDatabaseService.update(
        table: _activitiesTable,
        id: activityId,
        data: updateData,
      );

      // Get itinerary ID and update stats
      final activity = await _getActivity(activityId);
      if (activity != null) {
        await _updateItineraryStats(activity['itinerary_id']);
      }

      AppLogger.success(_tag, 'Activity updated successfully');
      return result;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to update activity', e, stackTrace);
      rethrow;
    }
  }

  /// Delete activity
  static Future<void> deleteActivity(String activityId) async {
    try {
      AppLogger.warning(_tag, 'Deleting activity: $activityId');

      // Get activity before deletion to update itinerary stats
      final activity = await _getActivity(activityId);
      
      await SupabaseDatabaseService.delete(
        table: _activitiesTable,
        id: activityId,
      );

      // Update itinerary statistics
      if (activity != null) {
        await _updateItineraryStats(activity['itinerary_id']);
      }

      AppLogger.success(_tag, 'Activity deleted successfully');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to delete activity', e, stackTrace);
      rethrow;
    }
  }

  /// Get itinerary activities
  static Future<List<Map<String, dynamic>>> getItineraryActivities(String itineraryId) async {
    try {
      AppLogger.debug(_tag, 'Getting activities for itinerary: $itineraryId');

      final activities = await SupabaseDatabaseService.select(
        table: _activitiesTable,
        filters: {'itinerary_id': itineraryId},
        orderBy: 'sort_order',
      );

      AppLogger.success(_tag, 'Retrieved ${activities.length} activities');
      return activities;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get itinerary activities', e, stackTrace);
      rethrow;
    }
  }

  /// Reorder activities
  static Future<void> reorderActivities({
    required String itineraryId,
    required List<String> activityIds,
  }) async {
    try {
      AppLogger.debug(_tag, 'Reordering activities for itinerary: $itineraryId');

      for (int i = 0; i < activityIds.length; i++) {
        await SupabaseDatabaseService.update(
          table: _activitiesTable,
          id: activityIds[i],
          data: {'sort_order': i},
        );
      }

      AppLogger.success(_tag, 'Activities reordered successfully');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to reorder activities', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // ITINERARY TEMPLATES
  // ===============================

  /// Create itinerary template
  static Future<Map<String, dynamic>> createTemplate({
    required String name,
    required String description,
    required String category,
    required int durationDays,
    List<Map<String, dynamic>>? templateActivities,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Creating itinerary template: $name');

      final templateData = {
        'created_by': userId,
        'name': name,
        'description': description,
        'category': category,
        'duration_days': durationDays,
        'template_activities': templateActivities ?? [],
        'metadata': metadata ?? {},
        'is_public': false,
        'usage_count': 0,
      };

      final result = await SupabaseDatabaseService.insert(
        table: _templatesTable,
        data: templateData,
      );

      AppLogger.success(_tag, 'Itinerary template created successfully: $name');
      return result;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to create itinerary template', e, stackTrace);
      rethrow;
    }
  }

  /// Get itinerary templates
  static Future<List<Map<String, dynamic>>> getTemplates({
    String? category,
    int? durationDays,
    bool? isPublic,
    int limit = 20,
  }) async {
    try {
      AppLogger.debug(_tag, 'Getting itinerary templates');

      final filters = <String, dynamic>{};
      if (category != null) filters['category'] = category;
      if (durationDays != null) filters['duration_days'] = durationDays;
      if (isPublic != null) filters['is_public'] = isPublic;

      final templates = await SupabaseDatabaseService.select(
        table: _templatesTable,
        filters: filters,
        orderBy: 'usage_count',
        ascending: false,
        limit: limit,
      );

      AppLogger.success(_tag, 'Retrieved ${templates.length} templates');
      return templates;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get itinerary templates', e, stackTrace);
      rethrow;
    }
  }

  /// Apply template to trip
  static Future<List<Map<String, dynamic>>> applyTemplateToTrip({
    required String tripId,
    required String templateId,
    DateTime? startDate,
  }) async {
    try {
      AppLogger.debug(_tag, 'Applying template to trip: $tripId');

      final templates = await SupabaseDatabaseService.select(
        table: _templatesTable,
        filters: {'id': templateId},
      );

      if (templates.isEmpty) {
        throw Exception('Template not found');
      }

      final template = templates.first;
      final templateActivities = List<Map<String, dynamic>>.from(
        template['template_activities'] ?? []
      );

      final createdItineraries = <Map<String, dynamic>>[];

      // Create itineraries for each day
      for (int day = 1; day <= template['duration_days']; day++) {
        final itineraryDate = startDate?.add(Duration(days: day - 1));
        
        final itinerary = await createItinerary(
          tripId: tripId,
          title: '${template['name']} - Hari $day',
          description: 'Itinerary berdasarkan template: ${template['name']}',
          date: itineraryDate,
          dayNumber: day,
        );

        // Add activities for this day
        final dayActivities = templateActivities
            .where((activity) => activity['day'] == day)
            .toList();

        for (final templateActivity in dayActivities) {
          await addActivity(
            itineraryId: itinerary['id'],
            title: templateActivity['title'] ?? '',
            type: templateActivity['type'] ?? 'attraction',
            description: templateActivity['description'],
            location: templateActivity['location'],
            estimatedCost: templateActivity['estimated_cost']?.toDouble(),
            sortOrder: templateActivity['sort_order'],
          );
        }

        createdItineraries.add(itinerary);
      }

      // Update template usage count
      await SupabaseDatabaseService.update(
        table: _templatesTable,
        id: templateId,
        data: {'usage_count': (template['usage_count'] ?? 0) + 1},
      );

      AppLogger.success(_tag, 'Template applied successfully to trip');
      return createdItineraries;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to apply template to trip', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // ITINERARY OPTIMIZATION
  // ===============================

  /// Optimize itinerary by location (minimize travel time)
  static Future<List<Map<String, dynamic>>> optimizeItineraryByLocation(String itineraryId) async {
    try {
      AppLogger.debug(_tag, 'Optimizing itinerary by location: $itineraryId');

      final activities = await getItineraryActivities(itineraryId);
      
      // Filter activities with location data
      final activitiesWithLocation = activities.where((activity) {
        return activity['latitude'] != null && activity['longitude'] != null;
      }).toList();

      if (activitiesWithLocation.length < 2) {
        AppLogger.warning(_tag, 'Not enough activities with location data for optimization');
        return activities;
      }

      // Simple optimization: sort by proximity (nearest neighbor algorithm)
      final optimizedActivities = <Map<String, dynamic>>[];
      final remainingActivities = List<Map<String, dynamic>>.from(activitiesWithLocation);
      
      // Start with first activity
      optimizedActivities.add(remainingActivities.removeAt(0));

      // Find nearest activity for each step
      while (remainingActivities.isNotEmpty) {
        final currentActivity = optimizedActivities.last;
        final currentLat = currentActivity['latitude'] as double;
        final currentLng = currentActivity['longitude'] as double;

        double minDistance = double.infinity;
        int nearestIndex = 0;

        for (int i = 0; i < remainingActivities.length; i++) {
          final activity = remainingActivities[i];
          final lat = activity['latitude'] as double;
          final lng = activity['longitude'] as double;
          
          final distance = _calculateDistance(currentLat, currentLng, lat, lng);
          
          if (distance < minDistance) {
            minDistance = distance;
            nearestIndex = i;
          }
        }

        optimizedActivities.add(remainingActivities.removeAt(nearestIndex));
      }

      // Add activities without location data at the end
      final activitiesWithoutLocation = activities.where((activity) {
        return activity['latitude'] == null || activity['longitude'] == null;
      }).toList();
      
      optimizedActivities.addAll(activitiesWithoutLocation);

      // Update sort orders
      final activityIds = optimizedActivities.map((a) => a['id'] as String).toList();
      await reorderActivities(
        itineraryId: itineraryId,
        activityIds: activityIds,
      );

      AppLogger.success(_tag, 'Itinerary optimized by location');
      return optimizedActivities;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to optimize itinerary by location', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // STATISTICS & ANALYTICS
  // ===============================

  /// Get itinerary statistics
  static Future<Map<String, dynamic>> getItineraryStatistics(String itineraryId) async {
    try {
      AppLogger.debug(_tag, 'Getting itinerary statistics: $itineraryId');

      final itinerary = await getItinerary(itineraryId);
      if (itinerary == null) {
        throw Exception('Itinerary not found');
      }

      final activities = itinerary['activities'] as List<Map<String, dynamic>>;
      
      final stats = {
        'itinerary_id': itineraryId,
        'title': itinerary['title'],
        'activity_count': activities.length,
        'completed_activities': activities.where((a) => a['is_completed'] == true).length,
        'completion_percentage': activities.isNotEmpty 
            ? (activities.where((a) => a['is_completed'] == true).length / activities.length * 100).round()
            : 0,
        'total_estimated_cost': activities.fold(0.0, (sum, a) => sum + (a['estimated_cost'] ?? 0.0)),
        'total_actual_cost': activities.fold(0.0, (sum, a) => sum + (a['actual_cost'] ?? 0.0)),
        'activity_types': _getActivityTypeBreakdown(activities),
        'estimated_duration_minutes': itinerary['estimated_duration_minutes'] ?? 0,
        'status': itinerary['status'],
      };

      AppLogger.success(_tag, 'Retrieved itinerary statistics');
      return stats;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get itinerary statistics', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // PRIVATE HELPER METHODS
  // ===============================

  /// Get single activity
  static Future<Map<String, dynamic>?> _getActivity(String activityId) async {
    try {
      final activities = await SupabaseDatabaseService.select(
        table: _activitiesTable,
        filters: {'id': activityId},
      );
      return activities.isNotEmpty ? activities.first : null;
    } catch (e) {
      return null;
    }
  }

  /// Update itinerary statistics
  static Future<void> _updateItineraryStats(String itineraryId) async {
    try {
      final activities = await getItineraryActivities(itineraryId);
      
      final totalCost = activities.fold(0.0, (sum, a) => sum + (a['estimated_cost'] ?? 0.0));
      final totalDuration = activities.fold(0, (sum, a) {
        final startTime = a['start_time'] as String?;
        final endTime = a['end_time'] as String?;
        
        if (startTime != null && endTime != null) {
          final start = DateTime.parse(startTime);
          final end = DateTime.parse(endTime);
          return sum + end.difference(start).inMinutes;
        }
        
        return sum;
      });

      await SupabaseDatabaseService.update(
        table: _tableName,
        id: itineraryId,
        data: {
          'activity_count': activities.length,
          'estimated_cost': totalCost,
          'estimated_duration_minutes': totalDuration,
        },
      );
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to update itinerary stats', e);
      // Don't throw error as this is not critical
    }
  }

  /// Calculate distance between two points
  static double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371; // Earth radius in kilometers
    final double dLat = (lat2 - lat1) * (3.14159 / 180);
    final double dLng = (lng2 - lng1) * (3.14159 / 180);

    final double a = 0.5 - (dLat / 2).abs() + 
        (lat1 * 3.14159 / 180).abs() * (lat2 * 3.14159 / 180).abs() * 
        (1 - (dLng / 2).abs()) / 2;

    return earthRadius * 2 * (a.abs().clamp(0.0, 1.0));
  }

  /// Get activity type breakdown
  static Map<String, int> _getActivityTypeBreakdown(List<Map<String, dynamic>> activities) {
    final breakdown = <String, int>{};
    
    for (final activity in activities) {
      final type = activity['type'] as String? ?? 'unknown';
      breakdown[type] = (breakdown[type] ?? 0) + 1;
    }
    
    return breakdown;
  }
}
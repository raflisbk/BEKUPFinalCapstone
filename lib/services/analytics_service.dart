import 'dart:async';
import '../core/utils/logger.dart';
import 'supabase_config.dart';
import 'supabase_database_service.dart';
import 'cache_service.dart';
import 'interfaces/i_analytics_service.dart';

/// Analytics Service
/// Handles user analytics, tracking, and insights for app usage
class AnalyticsService implements IAnalyticsService {
  static const String _tag = 'AnalyticsService';
  static const String _eventsTable = 'analytics_events';
  static const String _sessionTable = 'user_sessions';
  static const String _userMetricsTable = 'user_metrics';

  // Event categories
  static const String categoryUser = 'user';
  static const String categoryContent = 'content';
  static const String categoryNavigation = 'navigation';
  static const String categorySearch = 'search';
  static const String categoryBooking = 'booking';
  static const String categoryEngagement = 'engagement';
  static const String categoryError = 'error';
  static const String categoryPerformance = 'performance';

  // Common events
  static const String eventUserLogin = 'user_login';
  static const String eventUserLogout = 'user_logout';
  static const String eventUserSignup = 'user_signup';
  static const String eventContentView = 'content_view';
  static const String eventContentShare = 'content_share';
  static const String eventContentLike = 'content_like';
  static const String eventSearchPerformed = 'search_performed';
  static const String eventBookingStarted = 'booking_started';
  static const String eventBookingCompleted = 'booking_completed';
  static const String eventScreenView = 'screen_view';
  static const String eventButtonClick = 'button_click';
  static const String eventError = 'error_occurred';

  // Instance fields
  String? _sessionId;
  DateTime? _sessionStartTime;
  int _eventCount = 0;

  // ===============================
  // SESSION MANAGEMENT
  // ===============================

  /// Start analytics session
  @override
  Future<void> startSession() async {
    try {
      final userId = SupabaseConfig.userId;
      
      AppLogger.debug(_tag, 'Starting analytics session');

      _sessionId = _generateSessionId();
      _sessionStartTime = DateTime.now();
      _eventCount = 0;

      // Create session record
      final sessionData = {
        'session_id': _sessionId,
        'user_id': userId,
        'started_at': _sessionStartTime!.toIso8601String(),
        'platform': _getPlatform(),
        'app_version': _getAppVersion(),
        'device_info': await _getDeviceInfo(),
        'is_active': true,
      };

      await SupabaseDatabaseService.insert(
        table: _sessionTable,
        data: sessionData,
      );

      // Track session start event
      await trackEvent(eventUserLogin, {
        'session_id': _sessionId,
        'timestamp': _sessionStartTime!.toIso8601String(),
      });

      AppLogger.success(_tag, 'Analytics session started: $_sessionId');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to start analytics session', e, stackTrace);
    }
  }

  /// End analytics session
  @override
  Future<void> endSession() async {
    try {
      if (_sessionId == null || _sessionStartTime == null) {
        return;
      }

      AppLogger.debug(_tag, 'Ending analytics session: $_sessionId');

      final sessionDuration = DateTime.now().difference(_sessionStartTime!);

      // Update session record
      final sessions = await SupabaseDatabaseService.select(
        table: _sessionTable,
        filters: {'session_id': _sessionId},
      );

      if (sessions.isNotEmpty) {
        await SupabaseDatabaseService.update(
          table: _sessionTable,
          id: sessions.first['id'],
          data: {
            'ended_at': DateTime.now().toIso8601String(),
            'duration_seconds': sessionDuration.inSeconds,
            'event_count': _eventCount,
            'is_active': false,
          },
        );
      }

      // Track session end event
      await trackEvent(eventUserLogout, {
        'session_id': _sessionId,
        'duration_seconds': sessionDuration.inSeconds,
        'event_count': _eventCount,
      });

      AppLogger.success(_tag, 'Analytics session ended: $_sessionId');

      // Clear session data
      _sessionId = null;
      _sessionStartTime = null;
      _eventCount = 0;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to end analytics session', e, stackTrace);
    }
  }

  // ===============================
  // EVENT TRACKING
  // ===============================

  /// Track an event
  @override
  Future<void> trackEvent(
    String eventName,
    Map<String, dynamic>? properties, {
    String? category,
    String? userId,
  }) async {
    try {
      final currentUserId = userId ?? SupabaseConfig.userId;
      
      AppLogger.debug(_tag, 'Tracking event: $eventName');

      final eventData = {
        'session_id': _sessionId,
        'user_id': currentUserId,
        'event_name': eventName,
        'category': category ?? _categorizeEvent(eventName),
        'properties': properties ?? {},
        'timestamp': DateTime.now().toIso8601String(),
        'platform': _getPlatform(),
        'app_version': _getAppVersion(),
      };

      await SupabaseDatabaseService.insert(
        table: _eventsTable,
        data: eventData,
      );

      _eventCount++;

      AppLogger.debug(_tag, 'Event tracked successfully: $eventName');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to track event: $eventName', e, stackTrace);
    }
  }

  /// Track screen view
  @override
  Future<void> trackScreenView(
    String screenName, {
    Map<String, dynamic>? properties,
  }) async {
    await trackEvent(
      eventScreenView,
      {
        'screen_name': screenName,
        ...?properties,
      },
      category: categoryNavigation,
    );
  }

  /// Track user action
  @override
  Future<void> trackUserAction(
    String action,
    String target, {
    Map<String, dynamic>? properties,
  }) async {
    await trackEvent(
      eventButtonClick,
      {
        'action': action,
        'target': target,
        ...?properties,
      },
      category: categoryEngagement,
    );
  }

  /// Track content interaction
  @override
  Future<void> trackContentInteraction(
    String contentType,
    String contentId,
    String interaction, {
    Map<String, dynamic>? properties,
  }) async {
    await trackEvent(
      '${contentType}_$interaction',
      {
        'content_type': contentType,
        'content_id': contentId,
        'interaction': interaction,
        ...?properties,
      },
      category: categoryContent,
    );
  }

  /// Track search
  @override
  Future<void> trackSearch(
    String query,
    String category,
    int resultCount, {
    Map<String, dynamic>? filters,
  }) async {
    await trackEvent(
      eventSearchPerformed,
      {
        'query': query,
        'category': category,
        'result_count': resultCount,
        'has_filters': filters != null && filters.isNotEmpty,
        'filters': filters ?? {},
      },
      category: categorySearch,
    );
  }

  /// Track booking flow
  @override
  Future<void> trackBookingStep(
    String step,
    String bookingId, {
    Map<String, dynamic>? properties,
  }) async {
    await trackEvent(
      'booking_$step',
      {
        'booking_id': bookingId,
        'step': step,
        ...?properties,
      },
      category: categoryBooking,
    );
  }

  /// Track error
  @override
  Future<void> trackError(
    String errorType,
    String errorMessage, {
    String? stackTrace,
    Map<String, dynamic>? context,
  }) async {
    await trackEvent(
      eventError,
      {
        'error_type': errorType,
        'error_message': errorMessage,
        'stack_trace': stackTrace,
        'context': context ?? {},
      },
      category: categoryError,
    );
  }

  /// Track performance metric
  @override
  Future<void> trackPerformance(
    String metric,
    double value, {
    String? unit,
    Map<String, dynamic>? context,
  }) async {
    await trackEvent(
      'performance_$metric',
      {
        'metric': metric,
        'value': value,
        'unit': unit ?? 'ms',
        'context': context ?? {},
      },
      category: categoryPerformance,
    );
  }

  // ===============================
  // ANALYTICS QUERIES
  // ===============================

  /// Get event analytics
  @override
  Future<Map<String, dynamic>> getEventAnalytics({
    String? eventName,
    String? category,
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
    String groupBy = 'day',
  }) async {
    try {
      AppLogger.debug(_tag, 'Getting event analytics');

      final filters = <String, dynamic>{};
      
      if (eventName != null) filters['event_name'] = eventName;
      if (category != null) filters['category'] = category;
      if (userId != null) filters['user_id'] = userId;

      var events = await SupabaseDatabaseService.select(
        table: _eventsTable,
        filters: filters,
        orderBy: 'timestamp',
        ascending: false,
        limit: 10000,
      );

      // Apply date filters
      if (startDate != null || endDate != null) {
        events = events.where((event) {
          final eventDate = DateTime.parse(event['timestamp']);
          if (startDate != null && eventDate.isBefore(startDate)) return false;
          if (endDate != null && eventDate.isAfter(endDate)) return false;
          return true;
        }).toList();
      }

      // Group events
      final groupedEvents = _groupEventsByPeriod(events, groupBy);

      final analytics = {
        'total_events': events.length,
        'unique_users': _getUniqueUsers(events),
        'grouped_data': groupedEvents,
        'top_events': _getTopEvents(events),
        'event_categories': _getEventCategories(events),
      };

      AppLogger.success(_tag, 'Event analytics retrieved');
      return analytics;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get event analytics', e, stackTrace);
      return {};
    }
  }

  /// Get user analytics
  @override
  Future<Map<String, dynamic>> getUserAnalytics({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final targetUserId = userId ?? SupabaseConfig.userId;
      if (targetUserId == null) {
        throw Exception('No user ID provided');
      }

      AppLogger.debug(_tag, 'Getting user analytics: $targetUserId');

      // Get user events
      final events = await SupabaseDatabaseService.select(
        table: _eventsTable,
        filters: {'user_id': targetUserId},
        orderBy: 'timestamp',
        ascending: false,
      );

      // Get user sessions
      final sessions = await SupabaseDatabaseService.select(
        table: _sessionTable,
        filters: {'user_id': targetUserId},
        orderBy: 'started_at',
        ascending: false,
      );

      // Apply date filters
      var filteredEvents = events;
      var filteredSessions = sessions;

      if (startDate != null || endDate != null) {
        filteredEvents = events.where((event) {
          final eventDate = DateTime.parse(event['timestamp']);
          if (startDate != null && eventDate.isBefore(startDate)) return false;
          if (endDate != null && eventDate.isAfter(endDate)) return false;
          return true;
        }).toList();

        filteredSessions = sessions.where((session) {
          final sessionDate = DateTime.parse(session['started_at']);
          if (startDate != null && sessionDate.isBefore(startDate)) return false;
          if (endDate != null && sessionDate.isAfter(endDate)) return false;
          return true;
        }).toList();
      }

      final analytics = {
        'user_id': targetUserId,
        'total_events': filteredEvents.length,
        'total_sessions': filteredSessions.length,
        'average_session_duration': _calculateAverageSessionDuration(filteredSessions),
        'most_active_day': _getMostActiveDay(filteredEvents),
        'top_actions': _getTopUserActions(filteredEvents),
        'activity_timeline': _getUserActivityTimeline(filteredEvents),
        'engagement_score': _calculateEngagementScore(filteredEvents, filteredSessions),
      };

      AppLogger.success(_tag, 'User analytics retrieved');
      return analytics;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get user analytics', e, stackTrace);
      return {};
    }
  }

  /// Get app performance metrics
  @override
  Future<Map<String, dynamic>> getPerformanceMetrics({
    Duration period = const Duration(days: 7),
  }) async {
    try {
      AppLogger.debug(_tag, 'Getting performance metrics');

      final startDate = DateTime.now().subtract(period);

      final events = await SupabaseDatabaseService.select(
        table: _eventsTable,
        filters: {
          'category': categoryPerformance,
          'timestamp': '>=${startDate.toIso8601String()}',
        },
        orderBy: 'timestamp',
        ascending: false,
      );

      final metrics = {
        'average_load_time': _calculateAverageMetric(events, 'load_time'),
        'average_response_time': _calculateAverageMetric(events, 'response_time'),
        'error_rate': await _calculateErrorRate(startDate),
        'crash_rate': await _calculateCrashRate(startDate),
        'performance_trends': _getPerformanceTrends(events),
      };

      AppLogger.success(_tag, 'Performance metrics retrieved');
      return metrics;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get performance metrics', e, stackTrace);
      return {};
    }
  }

  // ===============================
  // USER METRICS
  // ===============================

  /// Update user metrics
  @override
  Future<void> updateUserMetrics({
    String? userId,
    Map<String, dynamic>? metrics,
  }) async {
    try {
      final targetUserId = userId ?? SupabaseConfig.userId;
      if (targetUserId == null) return;

      AppLogger.debug(_tag, 'Updating user metrics: $targetUserId');

      final existingMetrics = await SupabaseDatabaseService.select(
        table: _userMetricsTable,
        filters: {'user_id': targetUserId},
      );

      final metricsData = {
        'user_id': targetUserId,
        'last_active': DateTime.now().toIso8601String(),
        'total_sessions': (existingMetrics.isNotEmpty 
            ? (existingMetrics.first['total_sessions'] as int? ?? 0) + 1 
            : 1),
        'total_events': (existingMetrics.isNotEmpty 
            ? (existingMetrics.first['total_events'] as int? ?? 0) + _eventCount 
            : _eventCount),
        ...?metrics,
      };

      if (existingMetrics.isNotEmpty) {
        await SupabaseDatabaseService.update(
          table: _userMetricsTable,
          id: existingMetrics.first['id'],
          data: metricsData,
        );
      } else {
        await SupabaseDatabaseService.insert(
          table: _userMetricsTable,
          data: metricsData,
        );
      }

      AppLogger.success(_tag, 'User metrics updated');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to update user metrics', e, stackTrace);
    }
  }

  /// Get user engagement score
  @override
  Future<double> getUserEngagementScore([String? userId]) async {
    try {
      final targetUserId = userId ?? SupabaseConfig.userId;
      if (targetUserId == null) return 0.0;

      final userMetrics = await SupabaseDatabaseService.select(
        table: _userMetricsTable,
        filters: {'user_id': targetUserId},
      );

      if (userMetrics.isEmpty) return 0.0;

      // Calculate engagement based on available metrics
      return _calculateEngagementScore([], []);
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to get user engagement score', e);
      return 0.0;
    }
  }

  // ===============================
  // BATCH OPERATIONS
  // ===============================

  /// Track multiple events in batch
  @override
  Future<void> trackEventsBatch(List<Map<String, dynamic>> events) async {
    try {
      AppLogger.debug(_tag, 'Tracking ${events.length} events in batch');

      final eventsData = events.map((event) {
        return {
          'session_id': _sessionId,
          'user_id': event['user_id'] ?? SupabaseConfig.userId,
          'event_name': event['event_name'],
          'category': event['category'] ?? _categorizeEvent(event['event_name']),
          'properties': event['properties'] ?? {},
          'timestamp': DateTime.now().toIso8601String(),
          'platform': _getPlatform(),
          'app_version': _getAppVersion(),
        };
      }).toList();

      // Insert events one by one since batch insert not available
      for (final eventData in eventsData) {
        await SupabaseDatabaseService.insert(
          table: _eventsTable,
          data: eventData,
        );
      }

      _eventCount += events.length;

      AppLogger.success(_tag, 'Batch events tracked successfully');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to track batch events', e, stackTrace);
    }
  }

  // ===============================
  // CACHE AND PERFORMANCE
  // ===============================

  /// Get cached analytics
  @override
  Future<Map<String, dynamic>?> getCachedAnalytics(String key) async {
    try {
      return await CacheService.get<Map<String, dynamic>>(key);
    } catch (e) {
      return null;
    }
  }

  /// Cache analytics data
  @override
  Future<void> cacheAnalytics(
    String key,
    Map<String, dynamic> data, {
    Duration duration = const Duration(hours: 1),
  }) async {
    try {
      await CacheService.set(key, data, duration: duration, category: CacheService.categoryGeneral);
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to cache analytics data', e);
    }
  }

  // ===============================
  // PRIVATE HELPER METHODS
  // ===============================

  /// Generate session ID
  String _generateSessionId() {
    return 'session_${DateTime.now().millisecondsSinceEpoch}_${(DateTime.now().microsecond % 1000)}';
  }

  /// Get platform
  String _getPlatform() {
    // This would detect the actual platform
    return 'mobile'; // flutter, android, ios, web
  }

  /// Get app version
  String _getAppVersion() {
    // This would get the actual app version
    return '1.0.0';
  }

  /// Get device info
  Future<Map<String, dynamic>> _getDeviceInfo() async {
    // This would get actual device information
    return {
      'platform': _getPlatform(),
      'os_version': 'Unknown',
      'device_model': 'Unknown',
      'screen_resolution': 'Unknown',
    };
  }

  /// Categorize event
  String _categorizeEvent(String eventName) {
    if (eventName.contains('user') || eventName.contains('login') || eventName.contains('signup')) {
      return categoryUser;
    } else if (eventName.contains('view') || eventName.contains('like') || eventName.contains('share')) {
      return categoryContent;
    } else if (eventName.contains('screen') || eventName.contains('navigation')) {
      return categoryNavigation;
    } else if (eventName.contains('search')) {
      return categorySearch;
    } else if (eventName.contains('booking')) {
      return categoryBooking;
    } else if (eventName.contains('click') || eventName.contains('tap')) {
      return categoryEngagement;
    } else if (eventName.contains('error')) {
      return categoryError;
    } else if (eventName.contains('performance')) {
      return categoryPerformance;
    }
    return categoryEngagement;
  }

  /// Group events by period
  Map<String, int> _groupEventsByPeriod(List<Map<String, dynamic>> events, String groupBy) {
    final grouped = <String, int>{};

    for (final event in events) {
      final timestamp = DateTime.parse(event['timestamp']);
      String key;

      switch (groupBy) {
        case 'hour':
          key = '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')} ${timestamp.hour.toString().padLeft(2, '0')}:00';
          break;
        case 'day':
          key = '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}';
          break;
        case 'week':
          final weekStart = timestamp.subtract(Duration(days: timestamp.weekday - 1));
          key = '${weekStart.year}-W${((weekStart.dayOfYear - 1) / 7).floor() + 1}';
          break;
        case 'month':
          key = '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}';
          break;
        default:
          key = timestamp.toIso8601String().split('T')[0];
      }

      grouped[key] = (grouped[key] ?? 0) + 1;
    }

    return grouped;
  }

  /// Get unique users from events
  int _getUniqueUsers(List<Map<String, dynamic>> events) {
    final userIds = events
        .map((event) => event['user_id'] as String?)
        .where((userId) => userId != null)
        .toSet();
    return userIds.length;
  }

  /// Get top events
  List<Map<String, dynamic>> _getTopEvents(List<Map<String, dynamic>> events) {
    final eventCounts = <String, int>{};
    
    for (final event in events) {
      final eventName = event['event_name'] as String;
      eventCounts[eventName] = (eventCounts[eventName] ?? 0) + 1;
    }

    final sortedEvents = eventCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedEvents.take(10).map((entry) => {
      'event_name': entry.key,
      'count': entry.value,
    }).toList();
  }

  /// Get event categories
  Map<String, int> _getEventCategories(List<Map<String, dynamic>> events) {
    final categories = <String, int>{};
    
    for (final event in events) {
      final category = event['category'] as String? ?? 'unknown';
      categories[category] = (categories[category] ?? 0) + 1;
    }

    return categories;
  }

  /// Calculate average session duration
  double _calculateAverageSessionDuration(List<Map<String, dynamic>> sessions) {
    if (sessions.isEmpty) return 0.0;

    var totalDuration = 0;
    var validSessions = 0;

    for (final session in sessions) {
      final duration = session['duration_seconds'] as int?;
      if (duration != null) {
        totalDuration += duration;
        validSessions++;
      }
    }

    return validSessions > 0 ? totalDuration / validSessions : 0.0;
  }

  /// Get most active day
  String _getMostActiveDay(List<Map<String, dynamic>> events) {
    final dayGroups = _groupEventsByPeriod(events, 'day');
    if (dayGroups.isEmpty) return 'N/A';

    final mostActiveEntry = dayGroups.entries.reduce((a, b) => a.value > b.value ? a : b);
    return mostActiveEntry.key;
  }

  /// Get top user actions
  List<Map<String, dynamic>> _getTopUserActions(List<Map<String, dynamic>> events) {
    return _getTopEvents(events);
  }

  /// Get user activity timeline
  List<Map<String, dynamic>> _getUserActivityTimeline(List<Map<String, dynamic>> events) {
    final timeline = <String, dynamic>{};
    
    for (final event in events) {
      final date = DateTime.parse(event['timestamp']).toIso8601String().split('T')[0];
      if (!timeline.containsKey(date)) {
        timeline[date] = {'date': date, 'events': 0, 'unique_events': <String>{}};
      }
      timeline[date]['events']++;
      (timeline[date]['unique_events'] as Set<String>).add(event['event_name']);
    }

    return timeline.values.map((entry) => {
      'date': entry['date'],
      'events': entry['events'],
      'unique_events': (entry['unique_events'] as Set<String>).length,
    }).toList()..sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));
  }

  /// Calculate engagement score
  double _calculateEngagementScore(
    List<Map<String, dynamic>> events,
    List<Map<String, dynamic>> sessions,
  ) {
    // Simple engagement score calculation
    if (sessions.isEmpty) return 0.0;

    final avgSessionDuration = _calculateAverageSessionDuration(sessions);
    final eventsPerSession = events.length / sessions.length;
    
    return (avgSessionDuration / 60 + eventsPerSession).clamp(0.0, 10.0);
  }

  /// Calculate average metric
  double _calculateAverageMetric(List<Map<String, dynamic>> events, String metricName) {
    final values = events
        .map((event) => (event['properties'] as Map<String, dynamic>?)?[metricName] as double?)
        .where((value) => value != null)
        .cast<double>()
        .toList();

    if (values.isEmpty) return 0.0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  /// Calculate error rate
  Future<double> _calculateErrorRate(DateTime startDate) async {
    try {
      final allEvents = await SupabaseDatabaseService.select(
        table: _eventsTable,
        filters: {'timestamp': '>=${startDate.toIso8601String()}'},
      );

      final errorEvents = allEvents.where((event) => event['category'] == categoryError).length;
      
      return allEvents.isNotEmpty ? errorEvents / allEvents.length : 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  /// Calculate crash rate
  Future<double> _calculateCrashRate(DateTime startDate) async {
    try {
      final errorEvents = await SupabaseDatabaseService.select(
        table: _eventsTable,
        filters: {
          'category': categoryError,
          'timestamp': '>=${startDate.toIso8601String()}',
        },
      );

      final crashEvents = errorEvents.where((event) => 
          (event['properties'] as Map<String, dynamic>?)?.containsKey('crash') == true).length;
      
      final totalSessions = await SupabaseDatabaseService.select(
        table: _sessionTable,
        filters: {'started_at': '>=${startDate.toIso8601String()}'},
      );

      return totalSessions.isNotEmpty ? crashEvents / totalSessions.length : 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  /// Get performance trends
  Map<String, List<double>> _getPerformanceTrends(List<Map<String, dynamic>> events) {
    final trends = <String, List<double>>{};
    
    for (final event in events) {
      final properties = event['properties'] as Map<String, dynamic>? ?? {};
      final metric = properties['metric'] as String?;
      final value = properties['value'] as double?;
      
      if (metric != null && value != null) {
        trends.putIfAbsent(metric, () => []);
        trends[metric]!.add(value);
      }
    }

    return trends;
  }
}

extension on DateTime {
  int get dayOfYear {
    final firstDayOfYear = DateTime(year, 1, 1);
    return difference(firstDayOfYear).inDays + 1;
  }
}
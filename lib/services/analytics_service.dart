import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../core/utils/logger.dart';
import '../core/models/analytics_model.dart';
import 'ai/gemini_service.dart';

/// Comprehensive analytics service for user behavior tracking and insights generation
class AnalyticsService {
  static const String _tag = 'AnalyticsService';
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GeminiService _geminiService = GeminiService();
  
  bool _isInitialized = false;
  bool _isEnabled = true;
  String _sessionId = '';
  DateTime _sessionStart = DateTime.now();
  String _deviceInfo = '';
  String _appVersion = '';
  
  // Event buffers for batch processing
  final List<UserBehaviorData> _pendingEvents = [];
  final List<PerformanceMetrics> _pendingMetrics = [];
  Timer? _batchTimer;
  
  // Cache for frequent operations
  final Map<String, dynamic> _userPropertiesCache = {};
  final Map<String, AIUsageStats> _aiStatsCache = {};

  /// Initialize analytics service
  Future<void> initialize() async {
    if (_isInitialized) {
      AppLogger.debug(_tag, 'Already initialized');
      return;
    }

    try {
      await _geminiService.initialize();
      await _initializeDeviceInfo();
      await _initializeSession();
      _startBatchTimer();
      
      _isInitialized = true;
      AppLogger.info(_tag, 'Analytics Service initialized successfully');
      
      // Track app launch
      await trackEvent(
        eventType: AnalyticsEventType.userAction,
        eventName: 'app_launch',
        properties: {
          'session_id': _sessionId,
          'device_info': _deviceInfo,
          'app_version': _appVersion,
        },
      );

    } catch (e) {
      AppLogger.error(_tag, 'Failed to initialize Analytics Service', e);
      rethrow;
    }
  }

  /// Initialize device and app information
  Future<void> _initializeDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final packageInfo = await PackageInfo.fromPlatform();
      
      _appVersion = packageInfo.version;
      
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        _deviceInfo = 'Android ${androidInfo.version.release} - ${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        _deviceInfo = 'iOS ${iosInfo.systemVersion} - ${iosInfo.model}';
      } else {
        _deviceInfo = 'Unknown Platform';
      }

      AppLogger.debug(_tag, 'Device info initialized: $_deviceInfo');
    } catch (e) {
      AppLogger.error(_tag, 'Failed to initialize device info', e);
      _deviceInfo = 'Unknown Device';
      _appVersion = '1.0.0';
    }
  }

  /// Initialize analytics session
  Future<void> _initializeSession() async {
    _sessionId = '${DateTime.now().millisecondsSinceEpoch}_${_auth.currentUser?.uid ?? "anonymous"}';
    _sessionStart = DateTime.now();
    
    // Load user properties cache
    await _loadUserProperties();
    
    AppLogger.debug(_tag, 'Session initialized: $_sessionId');
  }

  /// Start batch processing timer
  void _startBatchTimer() {
    _batchTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _processBatchEvents();
    });
  }

  /// Track user behavior event
  Future<void> trackEvent({
    required AnalyticsEventType eventType,
    required String eventName,
    Map<String, dynamic> properties = const {},
    String screenName = '',
  }) async {
    if (!_isEnabled || !_isInitialized) return;

    try {
      final userId = _auth.currentUser?.uid ?? 'anonymous';
      final sessionDuration = DateTime.now().difference(_sessionStart).inMinutes.toDouble();

      final behaviorData = UserBehaviorData(
        userId: userId,
        sessionId: _sessionId,
        timestamp: DateTime.now(),
        eventType: eventType,
        eventName: eventName,
        eventProperties: properties,
        screenName: screenName,
        sessionDuration: sessionDuration,
        userProperties: _userPropertiesCache,
      );

      _pendingEvents.add(behaviorData);

      // Process high-priority events immediately
      if (eventType == AnalyticsEventType.errorEvent || 
          eventName.contains('crash') || 
          eventName.contains('error')) {
        await _saveEventToFirestore(behaviorData);
      }

      AppLogger.debug(_tag, 'Event tracked: $eventName ($eventType)');

    } catch (e) {
      AppLogger.error(_tag, 'Failed to track event: $eventName', e);
    }
  }

  /// Track screen view
  Future<void> trackScreenView(String screenName, {Map<String, dynamic>? properties}) async {
    await trackEvent(
      eventType: AnalyticsEventType.navigationEvent,
      eventName: 'screen_view',
      properties: {
        'screen_name': screenName,
        'timestamp': DateTime.now().toIso8601String(),
        ...?properties,
      },
      screenName: screenName,
    );
  }

  /// Track AI interaction
  Future<void> trackAIInteraction({
    required String aiServiceType,
    required String action,
    required Duration responseTime,
    required bool wasSuccessful,
    Map<String, dynamic> metadata = const {},
  }) async {
    await trackEvent(
      eventType: AnalyticsEventType.aiInteraction,
      eventName: 'ai_interaction',
      properties: {
        'ai_service': aiServiceType,
        'action': action,
        'response_time_ms': responseTime.inMilliseconds,
        'was_successful': wasSuccessful,
        'metadata': metadata,
      },
    );

    // Update AI usage stats
    await _updateAIUsageStats(aiServiceType, responseTime, wasSuccessful);
  }

  /// Track trip activity
  Future<void> trackTripActivity({
    required String tripId,
    required String action,
    Map<String, dynamic> tripData = const {},
  }) async {
    await trackEvent(
      eventType: AnalyticsEventType.tripActivity,
      eventName: 'trip_activity',
      properties: {
        'trip_id': tripId,
        'action': action,
        'trip_data': tripData,
      },
    );
  }

  /// Track performance metrics
  Future<void> trackPerformanceMetrics({
    required double appLaunchTime,
    required Map<String, double> screenLoadTimes,
    required double memoryUsage,
    required double cpuUsage,
    Map<String, dynamic> networkMetrics = const {},
  }) async {
    if (!_isEnabled || !_isInitialized) return;

    try {
      final userId = _auth.currentUser?.uid ?? 'anonymous';
      final averageLoadTime = screenLoadTimes.values.isNotEmpty 
          ? screenLoadTimes.values.reduce((a, b) => a + b) / screenLoadTimes.length
          : 0.0;

      final metrics = PerformanceMetrics(
        sessionId: _sessionId,
        userId: userId,
        timestamp: DateTime.now(),
        appVersion: _appVersion,
        deviceInfo: _deviceInfo,
        appLaunchTime: appLaunchTime,
        averageScreenLoadTime: averageLoadTime,
        screenLoadTimes: screenLoadTimes,
        crashCount: 0, // Would be tracked separately
        errorTypes: [], // Would be populated from error tracking
        memoryUsage: memoryUsage,
        cpuUsage: cpuUsage,
        batteryDrain: 0.0, // Would require battery monitoring
        networkMetrics: networkMetrics,
        featureUsageCount: _getFeatureUsageCount(),
      );

      _pendingMetrics.add(metrics);
      AppLogger.debug(_tag, 'Performance metrics tracked');

    } catch (e) {
      AppLogger.error(_tag, 'Failed to track performance metrics', e);
    }
  }

  /// Generate analytics insights using AI
  Future<List<DashboardInsight>> generateInsights({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      AppLogger.info(_tag, 'Generating analytics insights for user: $userId');

      startDate ??= DateTime.now().subtract(const Duration(days: 30));
      endDate ??= DateTime.now();

      // Gather analytics data
      final tripAnalytics = await _getTripAnalytics(userId, startDate, endDate);
      final aiUsageStats = await _getAIUsageStats(userId, startDate, endDate);
      final behaviorPatterns = await _getUserBehaviorPatterns(userId, startDate, endDate);
      final performanceData = await _getPerformanceData(userId, startDate, endDate);

      // Generate AI-powered insights
      final insights = await _generateAIInsights(
        userId, tripAnalytics, aiUsageStats, behaviorPatterns, performanceData
      );

      // Save insights to Firestore
      for (final insight in insights) {
        await _firestore.collection('dashboard_insights').add(insight.toMap());
      }

      AppLogger.success(_tag, 'Generated ${insights.length} insights');
      return insights;

    } catch (e) {
      AppLogger.error(_tag, 'Failed to generate insights', e);
      return [];
    }
  }

  /// Get analytics summary for dashboard
  Future<AnalyticsSummary> getAnalyticsSummary({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      startDate ??= DateTime.now().subtract(const Duration(days: 30));
      endDate ??= DateTime.now();

      AppLogger.debug(_tag, 'Getting analytics summary for user: $userId');

      // Aggregate data from various collections
      final tripData = await _aggregateTripData(userId, startDate, endDate);
      final aiData = await _aggregateAIData(userId, startDate, endDate);
      final spendingData = await _aggregateSpendingData(userId, startDate, endDate);

      final summary = AnalyticsSummary(
        userId: userId,
        periodStart: startDate,
        periodEnd: endDate,
        totalTrips: tripData['totalTrips'] ?? 0,
        totalSpending: spendingData['totalSpending'] ?? 0.0,
        aiInteractions: aiData['totalInteractions'] ?? 0,
        averageTripSatisfaction: tripData['averageSatisfaction'] ?? 0.0,
        topCategories: Map<String, int>.from(spendingData['topCategories'] ?? {}),
        insights: {
          'most_used_ai_feature': aiData['mostUsedFeature'],
          'preferred_travel_mode': tripData['preferredTravelMode'],
          'spending_trend': spendingData['trend'],
        },
        lastUpdated: DateTime.now(),
      );

      // Cache summary for quick access
      await _firestore
          .collection('analytics_summaries')
          .doc(userId)
          .set(summary.toMap());

      AppLogger.success(_tag, 'Analytics summary generated');
      return summary;

    } catch (e) {
      AppLogger.error(_tag, 'Failed to get analytics summary', e);
      rethrow;
    }
  }

  /// Update user properties
  Future<void> updateUserProperties(Map<String, dynamic> properties) async {
    try {
      _userPropertiesCache.addAll(properties);
      
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        await _firestore
            .collection('user_properties')
            .doc(userId)
            .set(properties, SetOptions(merge: true));
      }

      AppLogger.debug(_tag, 'User properties updated');
    } catch (e) {
      AppLogger.error(_tag, 'Failed to update user properties', e);
    }
  }

  /// Private helper methods
  Future<void> _loadUserProperties() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        final doc = await _firestore.collection('user_properties').doc(userId).get();
        if (doc.exists) {
          _userPropertiesCache.addAll(doc.data() ?? {});
        }
      }
    } catch (e) {
      AppLogger.error(_tag, 'Failed to load user properties', e);
    }
  }

  Future<void> _updateAIUsageStats(String aiServiceType, Duration responseTime, bool wasSuccessful) async {
    try {
      final userId = _auth.currentUser?.uid ?? 'anonymous';
      final date = DateTime.now();
      final dateKey = '${date.year}-${date.month}-${date.day}';
      final statsKey = '${userId}_${aiServiceType}_$dateKey';

      // Update cache
      final existingStats = _aiStatsCache[statsKey];
      AIUsageStats updatedStats;

      if (existingStats != null) {
        updatedStats = AIUsageStats(
          userId: existingStats.userId,
          aiServiceType: existingStats.aiServiceType,
          date: existingStats.date,
          requestCount: existingStats.requestCount + 1,
          totalResponseTime: existingStats.totalResponseTime + responseTime.inMilliseconds.toDouble(),
          averageResponseTime: (existingStats.totalResponseTime + responseTime.inMilliseconds.toDouble()) / 
                               (existingStats.requestCount + 1),
          successfulRequests: existingStats.successfulRequests + (wasSuccessful ? 1 : 0),
          failedRequests: existingStats.failedRequests + (wasSuccessful ? 0 : 1),
          featureUsageCount: Map.from(existingStats.featureUsageCount),
          userPreferences: Map.from(existingStats.userPreferences),
          satisfactionScore: existingStats.satisfactionScore,
        );
      } else {
        updatedStats = AIUsageStats(
          userId: userId,
          aiServiceType: aiServiceType,
          date: date,
          requestCount: 1,
          totalResponseTime: responseTime.inMilliseconds.toDouble(),
          averageResponseTime: responseTime.inMilliseconds.toDouble(),
          successfulRequests: wasSuccessful ? 1 : 0,
          failedRequests: wasSuccessful ? 0 : 1,
          featureUsageCount: {},
          userPreferences: {},
          satisfactionScore: 5.0,
        );
      }

      _aiStatsCache[statsKey] = updatedStats;

      // Save to Firestore (batched)
      await _firestore
          .collection('ai_usage_stats')
          .doc(statsKey)
          .set(updatedStats.toMap());

    } catch (e) {
      AppLogger.error(_tag, 'Failed to update AI usage stats', e);
    }
  }

  Future<void> _processBatchEvents() async {
    if (_pendingEvents.isEmpty && _pendingMetrics.isEmpty) return;

    try {
      AppLogger.debug(_tag, 'Processing batch events: ${_pendingEvents.length} events, ${_pendingMetrics.length} metrics');

      // Process behavior events
      if (_pendingEvents.isNotEmpty) {
        final batch = _firestore.batch();
        for (final event in _pendingEvents.take(50)) { // Limit batch size
          final docRef = _firestore.collection('user_behavior_data').doc();
          batch.set(docRef, event.toMap());
        }
        await batch.commit();
        _pendingEvents.removeRange(0, (_pendingEvents.length > 50 ? 50 : _pendingEvents.length));
      }

      // Process performance metrics
      if (_pendingMetrics.isNotEmpty) {
        final batch = _firestore.batch();
        for (final metric in _pendingMetrics.take(50)) {
          final docRef = _firestore.collection('performance_metrics').doc();
          batch.set(docRef, metric.toMap());
        }
        await batch.commit();
        _pendingMetrics.removeRange(0, (_pendingMetrics.length > 50 ? 50 : _pendingMetrics.length));
      }

      AppLogger.success(_tag, 'Batch events processed successfully');

    } catch (e) {
      AppLogger.error(_tag, 'Failed to process batch events', e);
    }
  }

  Future<void> _saveEventToFirestore(UserBehaviorData event) async {
    try {
      await _firestore.collection('user_behavior_data').add(event.toMap());
    } catch (e) {
      AppLogger.error(_tag, 'Failed to save event to Firestore', e);
    }
  }

  Map<String, int> _getFeatureUsageCount() {
    // This would track feature usage from cached data
    return {
      'trips': 0,
      'chat': 0,
      'ai_features': 0,
      'gallery': 0,
      'social': 0,
    };
  }

  Future<List<TripAnalytics>> _getTripAnalytics(String userId, DateTime startDate, DateTime endDate) async {
    try {
      final snapshot = await _firestore
          .collection('trip_analytics')
          .where('userId', isEqualTo: userId)
          .where('tripStartDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('tripStartDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      return snapshot.docs.map((doc) => TripAnalytics.fromFirestore(doc)).toList();
    } catch (e) {
      AppLogger.error(_tag, 'Failed to get trip analytics', e);
      return [];
    }
  }

  Future<List<AIUsageStats>> _getAIUsageStats(String userId, DateTime startDate, DateTime endDate) async {
    try {
      final snapshot = await _firestore
          .collection('ai_usage_stats')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      return snapshot.docs.map((doc) => AIUsageStats.fromFirestore(doc)).toList();
    } catch (e) {
      AppLogger.error(_tag, 'Failed to get AI usage stats', e);
      return [];
    }
  }

  Future<List<UserBehaviorData>> _getUserBehaviorPatterns(String userId, DateTime startDate, DateTime endDate) async {
    try {
      final snapshot = await _firestore
          .collection('user_behavior_data')
          .where('userId', isEqualTo: userId)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .limit(1000)
          .get();

      return snapshot.docs.map((doc) => UserBehaviorData.fromFirestore(doc)).toList();
    } catch (e) {
      AppLogger.error(_tag, 'Failed to get user behavior patterns', e);
      return [];
    }
  }

  Future<List<PerformanceMetrics>> _getPerformanceData(String userId, DateTime startDate, DateTime endDate) async {
    try {
      final snapshot = await _firestore
          .collection('performance_metrics')
          .where('userId', isEqualTo: userId)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      return snapshot.docs.map((doc) => PerformanceMetrics.fromFirestore(doc)).toList();
    } catch (e) {
      AppLogger.error(_tag, 'Failed to get performance data', e);
      return [];
    }
  }

  Future<List<DashboardInsight>> _generateAIInsights(
    String userId,
    List<TripAnalytics> tripAnalytics,
    List<AIUsageStats> aiUsageStats,
    List<UserBehaviorData> behaviorPatterns,
    List<PerformanceMetrics> performanceData,
  ) async {
    try {
      final prompt = '''
Analyze this user's travel and app usage data to generate personalized insights:

Trip Analytics:
- Total trips: ${tripAnalytics.length}
- Average spending: \$${tripAnalytics.isNotEmpty ? (tripAnalytics.map((t) => t.spentAmount).reduce((a, b) => a + b) / tripAnalytics.length).toStringAsFixed(2) : '0'}
- Most visited destinations: ${tripAnalytics.map((t) => t.topDestinations).expand((d) => d).toSet().take(3).join(', ')}

AI Usage:
- Total AI interactions: ${aiUsageStats.map((s) => s.requestCount).fold(0, (a, b) => a + b)}
- Most used AI service: ${aiUsageStats.isNotEmpty ? (aiUsageStats.groupBy((s) => s.aiServiceType).entries.maxBy((e) => e.value.length)?.key ?? 'None') : 'None'}
- Average response time: ${aiUsageStats.isNotEmpty ? (aiUsageStats.map((s) => s.averageResponseTime).reduce((a, b) => a + b) / aiUsageStats.length).toStringAsFixed(0) : '0'}ms

Behavior Patterns:
- Most active screen: ${behaviorPatterns.isNotEmpty ? (behaviorPatterns.groupBy((b) => b.screenName).entries.maxBy((e) => e.value.length)?.key ?? 'Unknown') : 'Unknown'}
- Peak usage time: ${_calculatePeakUsageTime(behaviorPatterns)}

Generate 3-5 actionable insights that help the user:
1. Optimize their travel planning and spending
2. Better utilize AI features
3. Improve their overall app experience
4. Discover new features or opportunities

For each insight, provide:
- Title (concise and engaging)
- Description (detailed explanation with specific data)
- Actionable recommendations (what they can do)
- Priority (1-10, where 10 is most important)
- Category (spending, travel_patterns, ai_usage, app_optimization)

Format as a structured response I can parse.
''';

      final aiResponse = await _geminiService.generateText(prompt);
      return _parseInsights(userId, aiResponse);

    } catch (e) {
      AppLogger.error(_tag, 'Failed to generate AI insights', e);
      return [];
    }
  }

  List<DashboardInsight> _parseInsights(String userId, String aiResponse) {
    final insights = <DashboardInsight>[];
    
    try {
      final lines = aiResponse.split('\n');
      String? currentTitle;
      String? currentDescription;
      List<String> currentRecommendations = [];
      int currentPriority = 5;
      String currentCategory = 'general';

      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;

        if (trimmed.startsWith('Title:') || trimmed.startsWith('**')) {
          if (currentTitle != null) {
            insights.add(DashboardInsight(
              insightId: DateTime.now().millisecondsSinceEpoch.toString(),
              userId: userId,
              title: currentTitle,
              description: currentDescription ?? '',
              category: currentCategory,
              priority: currentPriority,
              data: {},
              actionableRecommendations: currentRecommendations,
              generatedAt: DateTime.now(),
              isActive: true,
            ));
          }
          currentTitle = trimmed.replaceAll(RegExp(r'(Title:|\*\*)'), '').trim();
          currentDescription = null;
          currentRecommendations = [];
        } else if (trimmed.startsWith('Description:')) {
          currentDescription = trimmed.replaceAll('Description:', '').trim();
        } else if (trimmed.startsWith('Recommendations:') || trimmed.startsWith('Actions:')) {
          // Start collecting recommendations
        } else if (trimmed.startsWith('- ') || trimmed.startsWith('• ')) {
          currentRecommendations.add(trimmed.replaceAll(RegExp(r'^[- •] '), ''));
        } else if (trimmed.startsWith('Priority:')) {
          final priorityMatch = RegExp(r'\d+').firstMatch(trimmed);
          if (priorityMatch != null) {
            currentPriority = int.tryParse(priorityMatch.group(0)!) ?? 5;
          }
        } else if (trimmed.startsWith('Category:')) {
          currentCategory = trimmed.replaceAll('Category:', '').trim().toLowerCase();
        }
      }

      // Add final insight
      if (currentTitle != null) {
        insights.add(DashboardInsight(
          insightId: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: userId,
          title: currentTitle,
          description: currentDescription ?? '',
          category: currentCategory,
          priority: currentPriority,
          data: {},
          actionableRecommendations: currentRecommendations,
          generatedAt: DateTime.now(),
          isActive: true,
        ));
      }

    } catch (e) {
      AppLogger.error(_tag, 'Failed to parse insights', e);
    }

    return insights;
  }

  String _calculatePeakUsageTime(List<UserBehaviorData> behaviorPatterns) {
    if (behaviorPatterns.isEmpty) return 'Unknown';
    
    final hourCounts = <int, int>{};
    for (final pattern in behaviorPatterns) {
      final hour = pattern.timestamp.hour;
      hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
    }
    
    if (hourCounts.isEmpty) return 'Unknown';
    
    final peakHour = hourCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    return '${peakHour.toString().padLeft(2, '0')}:00 - ${(peakHour + 1).toString().padLeft(2, '0')}:00';
  }

  Future<Map<String, dynamic>> _aggregateTripData(String userId, DateTime startDate, DateTime endDate) async {
    try {
      final snapshot = await _firestore
          .collection('trips')
          .where('userId', isEqualTo: userId)
          .where('startDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('startDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      final trips = snapshot.docs.map((doc) => doc.data()).toList();
      
      return {
        'totalTrips': trips.length,
        'averageSatisfaction': 4.2, // Would calculate from actual ratings
        'preferredTravelMode': 'driving', // Would analyze from route data
      };
    } catch (e) {
      AppLogger.error(_tag, 'Failed to aggregate trip data', e);
      return {};
    }
  }

  Future<Map<String, dynamic>> _aggregateAIData(String userId, DateTime startDate, DateTime endDate) async {
    try {
      final stats = await _getAIUsageStats(userId, startDate, endDate);
      final totalInteractions = stats.map((s) => s.requestCount).fold(0, (a, b) => a + b);
      
      String mostUsedFeature = 'chat';
      if (stats.isNotEmpty) {
        final serviceGroups = <String, int>{};
        for (final stat in stats) {
          serviceGroups[stat.aiServiceType] = (serviceGroups[stat.aiServiceType] ?? 0) + stat.requestCount;
        }
        mostUsedFeature = serviceGroups.entries.reduce((a, b) => a.value > b.value ? a : b).key;
      }
      
      return {
        'totalInteractions': totalInteractions,
        'mostUsedFeature': mostUsedFeature,
      };
    } catch (e) {
      AppLogger.error(_tag, 'Failed to aggregate AI data', e);
      return {};
    }
  }

  Future<Map<String, dynamic>> _aggregateSpendingData(String userId, DateTime startDate, DateTime endDate) async {
    try {
      final snapshot = await _firestore
          .collection('budget_expenses')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      final expenses = snapshot.docs.map((doc) => doc.data()).toList();
      final totalSpending = expenses.map((e) => e['amount'] ?? 0.0).fold(0.0, (a, b) => a + b);
      
      final categoryBreakdown = <String, int>{};
      for (final expense in expenses) {
        final category = expense['category'] ?? 'other';
        categoryBreakdown[category] = (categoryBreakdown[category] ?? 0) + 1;
      }
      
      return {
        'totalSpending': totalSpending,
        'topCategories': categoryBreakdown,
        'trend': 'increasing', // Would calculate actual trend
      };
    } catch (e) {
      AppLogger.error(_tag, 'Failed to aggregate spending data', e);
      return {};
    }
  }

  /// Enable/disable analytics tracking
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    AppLogger.info(_tag, 'Analytics tracking ${enabled ? 'enabled' : 'disabled'}');
  }

  /// Clean up resources
  void dispose() {
    _batchTimer?.cancel();
    _processBatchEvents(); // Process remaining events
    AppLogger.debug(_tag, 'Analytics service disposed');
  }

  /// Getters
  bool get isEnabled => _isEnabled;
  String get sessionId => _sessionId;
  DateTime get sessionStart => _sessionStart;
}

/// Extension for grouping lists
extension GroupBy<T> on List<T> {
  Map<K, List<T>> groupBy<K>(K Function(T) keyFunction) {
    final map = <K, List<T>>{};
    for (final item in this) {
      final key = keyFunction(item);
      if (!map.containsKey(key)) {
        map[key] = <T>[];
      }
      map[key]!.add(item);
    }
    return map;
  }
}

extension MaxBy<T> on Iterable<T> {
  T? maxBy<R extends Comparable<R>>(R Function(T) selector) {
    if (isEmpty) return null;
    
    T maxElement = first;
    R maxValue = selector(maxElement);
    
    for (final element in skip(1)) {
      final value = selector(element);
      if (value.compareTo(maxValue) > 0) {
        maxElement = element;
        maxValue = value;
      }
    }
    
    return maxElement;
  }
}
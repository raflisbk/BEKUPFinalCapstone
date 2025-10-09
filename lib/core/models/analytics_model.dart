import 'package:cloud_firestore/cloud_firestore.dart';

/// Analytics event types enumeration
enum AnalyticsEventType {
  userAction('user_action'),
  aiInteraction('ai_interaction'),
  tripActivity('trip_activity'),
  socialActivity('social_activity'),
  performanceMetric('performance_metric'),
  errorEvent('error_event'),
  navigationEvent('navigation_event'),
  contentEngagement('content_engagement');

  const AnalyticsEventType(this.value);
  final String value;

  static AnalyticsEventType fromString(String value) {
    return AnalyticsEventType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => AnalyticsEventType.userAction,
    );
  }
}

/// User behavior tracking data
class UserBehaviorData {
  final String userId;
  final String sessionId;
  final DateTime timestamp;
  final AnalyticsEventType eventType;
  final String eventName;
  final Map<String, dynamic> eventProperties;
  final String screenName;
  final double sessionDuration;
  final Map<String, dynamic> userProperties;

  const UserBehaviorData({
    required this.userId,
    required this.sessionId,
    required this.timestamp,
    required this.eventType,
    required this.eventName,
    required this.eventProperties,
    required this.screenName,
    required this.sessionDuration,
    required this.userProperties,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'sessionId': sessionId,
      'timestamp': Timestamp.fromDate(timestamp),
      'eventType': eventType.value,
      'eventName': eventName,
      'eventProperties': eventProperties,
      'screenName': screenName,
      'sessionDuration': sessionDuration,
      'userProperties': userProperties,
    };
  }

  factory UserBehaviorData.fromMap(Map<String, dynamic> map) {
    return UserBehaviorData(
      userId: map['userId'] ?? '',
      sessionId: map['sessionId'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      eventType: AnalyticsEventType.fromString(map['eventType'] ?? 'user_action'),
      eventName: map['eventName'] ?? '',
      eventProperties: map['eventProperties'] ?? {},
      screenName: map['screenName'] ?? '',
      sessionDuration: map['sessionDuration']?.toDouble() ?? 0.0,
      userProperties: map['userProperties'] ?? {},
    );
  }

  factory UserBehaviorData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserBehaviorData.fromMap(data);
  }
}

/// AI usage statistics and patterns
class AIUsageStats {
  final String userId;
  final String aiServiceType; // 'gemini', 'budget', 'chat', etc.
  final DateTime date;
  final int requestCount;
  final double totalResponseTime;
  final double averageResponseTime;
  final int successfulRequests;
  final int failedRequests;
  final Map<String, int> featureUsageCount;
  final Map<String, dynamic> userPreferences;
  final double satisfactionScore; // 1-10 based on user interactions

  const AIUsageStats({
    required this.userId,
    required this.aiServiceType,
    required this.date,
    required this.requestCount,
    required this.totalResponseTime,
    required this.averageResponseTime,
    required this.successfulRequests,
    required this.failedRequests,
    required this.featureUsageCount,
    required this.userPreferences,
    required this.satisfactionScore,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'aiServiceType': aiServiceType,
      'date': Timestamp.fromDate(date),
      'requestCount': requestCount,
      'totalResponseTime': totalResponseTime,
      'averageResponseTime': averageResponseTime,
      'successfulRequests': successfulRequests,
      'failedRequests': failedRequests,
      'featureUsageCount': featureUsageCount,
      'userPreferences': userPreferences,
      'satisfactionScore': satisfactionScore,
    };
  }

  factory AIUsageStats.fromMap(Map<String, dynamic> map) {
    return AIUsageStats(
      userId: map['userId'] ?? '',
      aiServiceType: map['aiServiceType'] ?? '',
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      requestCount: map['requestCount']?.toInt() ?? 0,
      totalResponseTime: map['totalResponseTime']?.toDouble() ?? 0.0,
      averageResponseTime: map['averageResponseTime']?.toDouble() ?? 0.0,
      successfulRequests: map['successfulRequests']?.toInt() ?? 0,
      failedRequests: map['failedRequests']?.toInt() ?? 0,
      featureUsageCount: Map<String, int>.from(map['featureUsageCount'] ?? {}),
      userPreferences: map['userPreferences'] ?? {},
      satisfactionScore: map['satisfactionScore']?.toDouble() ?? 5.0,
    );
  }

  factory AIUsageStats.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AIUsageStats.fromMap(data);
  }
}

/// Trip analytics and performance metrics
class TripAnalytics {
  final String tripId;
  final String userId;
  final DateTime tripStartDate;
  final DateTime? tripEndDate;
  final int totalDestinations;
  final int completedDestinations;
  final double totalBudget;
  final double spentAmount;
  final int totalActivities;
  final int completedActivities;
  final Map<String, int> categoryBreakdown; // expense categories
  final double averageDailySpending;
  final List<String> topDestinations;
  final Map<String, double> satisfactionRatings;
  final int socialInteractions; // likes, comments, shares
  final Map<String, dynamic> behaviorPatterns;

  const TripAnalytics({
    required this.tripId,
    required this.userId,
    required this.tripStartDate,
    this.tripEndDate,
    required this.totalDestinations,
    required this.completedDestinations,
    required this.totalBudget,
    required this.spentAmount,
    required this.totalActivities,
    required this.completedActivities,
    required this.categoryBreakdown,
    required this.averageDailySpending,
    required this.topDestinations,
    required this.satisfactionRatings,
    required this.socialInteractions,
    required this.behaviorPatterns,
  });

  Map<String, dynamic> toMap() {
    return {
      'tripId': tripId,
      'userId': userId,
      'tripStartDate': Timestamp.fromDate(tripStartDate),
      'tripEndDate': tripEndDate != null ? Timestamp.fromDate(tripEndDate!) : null,
      'totalDestinations': totalDestinations,
      'completedDestinations': completedDestinations,
      'totalBudget': totalBudget,
      'spentAmount': spentAmount,
      'totalActivities': totalActivities,
      'completedActivities': completedActivities,
      'categoryBreakdown': categoryBreakdown,
      'averageDailySpending': averageDailySpending,
      'topDestinations': topDestinations,
      'satisfactionRatings': satisfactionRatings,
      'socialInteractions': socialInteractions,
      'behaviorPatterns': behaviorPatterns,
    };
  }

  factory TripAnalytics.fromMap(Map<String, dynamic> map) {
    return TripAnalytics(
      tripId: map['tripId'] ?? '',
      userId: map['userId'] ?? '',
      tripStartDate: (map['tripStartDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      tripEndDate: (map['tripEndDate'] as Timestamp?)?.toDate(),
      totalDestinations: map['totalDestinations']?.toInt() ?? 0,
      completedDestinations: map['completedDestinations']?.toInt() ?? 0,
      totalBudget: map['totalBudget']?.toDouble() ?? 0.0,
      spentAmount: map['spentAmount']?.toDouble() ?? 0.0,
      totalActivities: map['totalActivities']?.toInt() ?? 0,
      completedActivities: map['completedActivities']?.toInt() ?? 0,
      categoryBreakdown: Map<String, int>.from(map['categoryBreakdown'] ?? {}),
      averageDailySpending: map['averageDailySpending']?.toDouble() ?? 0.0,
      topDestinations: List<String>.from(map['topDestinations'] ?? []),
      satisfactionRatings: Map<String, double>.from(map['satisfactionRatings'] ?? {}),
      socialInteractions: map['socialInteractions']?.toInt() ?? 0,
      behaviorPatterns: map['behaviorPatterns'] ?? {},
    );
  }

  factory TripAnalytics.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return TripAnalytics.fromMap({...data, 'tripId': doc.id});
  }
}

/// App performance metrics
class PerformanceMetrics {
  final String sessionId;
  final String userId;
  final DateTime timestamp;
  final String appVersion;
  final String deviceInfo;
  final double appLaunchTime;
  final double averageScreenLoadTime;
  final Map<String, double> screenLoadTimes;
  final int crashCount;
  final List<String> errorTypes;
  final double memoryUsage; // MB
  final double cpuUsage; // percentage
  final double batteryDrain; // percentage per hour
  final Map<String, dynamic> networkMetrics;
  final Map<String, int> featureUsageCount;

  const PerformanceMetrics({
    required this.sessionId,
    required this.userId,
    required this.timestamp,
    required this.appVersion,
    required this.deviceInfo,
    required this.appLaunchTime,
    required this.averageScreenLoadTime,
    required this.screenLoadTimes,
    required this.crashCount,
    required this.errorTypes,
    required this.memoryUsage,
    required this.cpuUsage,
    required this.batteryDrain,
    required this.networkMetrics,
    required this.featureUsageCount,
  });

  Map<String, dynamic> toMap() {
    return {
      'sessionId': sessionId,
      'userId': userId,
      'timestamp': Timestamp.fromDate(timestamp),
      'appVersion': appVersion,
      'deviceInfo': deviceInfo,
      'appLaunchTime': appLaunchTime,
      'averageScreenLoadTime': averageScreenLoadTime,
      'screenLoadTimes': screenLoadTimes,
      'crashCount': crashCount,
      'errorTypes': errorTypes,
      'memoryUsage': memoryUsage,
      'cpuUsage': cpuUsage,
      'batteryDrain': batteryDrain,
      'networkMetrics': networkMetrics,
      'featureUsageCount': featureUsageCount,
    };
  }

  factory PerformanceMetrics.fromMap(Map<String, dynamic> map) {
    return PerformanceMetrics(
      sessionId: map['sessionId'] ?? '',
      userId: map['userId'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      appVersion: map['appVersion'] ?? '',
      deviceInfo: map['deviceInfo'] ?? '',
      appLaunchTime: map['appLaunchTime']?.toDouble() ?? 0.0,
      averageScreenLoadTime: map['averageScreenLoadTime']?.toDouble() ?? 0.0,
      screenLoadTimes: Map<String, double>.from(map['screenLoadTimes'] ?? {}),
      crashCount: map['crashCount']?.toInt() ?? 0,
      errorTypes: List<String>.from(map['errorTypes'] ?? []),
      memoryUsage: map['memoryUsage']?.toDouble() ?? 0.0,
      cpuUsage: map['cpuUsage']?.toDouble() ?? 0.0,
      batteryDrain: map['batteryDrain']?.toDouble() ?? 0.0,
      networkMetrics: map['networkMetrics'] ?? {},
      featureUsageCount: Map<String, int>.from(map['featureUsageCount'] ?? {}),
    );
  }

  factory PerformanceMetrics.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return PerformanceMetrics.fromMap(data);
  }
}

/// Dashboard insights generated by AI
class DashboardInsight {
  final String insightId;
  final String userId;
  final String title;
  final String description;
  final String category; // 'spending', 'travel_patterns', 'ai_usage', etc.
  final int priority; // 1-10
  final Map<String, dynamic> data;
  final List<String> actionableRecommendations;
  final DateTime generatedAt;
  final DateTime? dismissedAt;
  final bool isActive;

  const DashboardInsight({
    required this.insightId,
    required this.userId,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.data,
    required this.actionableRecommendations,
    required this.generatedAt,
    this.dismissedAt,
    required this.isActive,
  });

  Map<String, dynamic> toMap() {
    return {
      'insightId': insightId,
      'userId': userId,
      'title': title,
      'description': description,
      'category': category,
      'priority': priority,
      'data': data,
      'actionableRecommendations': actionableRecommendations,
      'generatedAt': Timestamp.fromDate(generatedAt),
      'dismissedAt': dismissedAt != null ? Timestamp.fromDate(dismissedAt!) : null,
      'isActive': isActive,
    };
  }

  factory DashboardInsight.fromMap(Map<String, dynamic> map) {
    return DashboardInsight(
      insightId: map['insightId'] ?? '',
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      priority: map['priority']?.toInt() ?? 5,
      data: map['data'] ?? {},
      actionableRecommendations: List<String>.from(map['actionableRecommendations'] ?? []),
      generatedAt: (map['generatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dismissedAt: (map['dismissedAt'] as Timestamp?)?.toDate(),
      isActive: map['isActive'] ?? true,
    );
  }

  factory DashboardInsight.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return DashboardInsight.fromMap({...data, 'insightId': doc.id});
  }

  DashboardInsight copyWith({
    String? title,
    String? description,
    int? priority,
    Map<String, dynamic>? data,
    List<String>? actionableRecommendations,
    DateTime? dismissedAt,
    bool? isActive,
  }) {
    return DashboardInsight(
      insightId: insightId,
      userId: userId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category,
      priority: priority ?? this.priority,
      data: data ?? this.data,
      actionableRecommendations: actionableRecommendations ?? this.actionableRecommendations,
      generatedAt: generatedAt,
      dismissedAt: dismissedAt ?? this.dismissedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DashboardInsight && other.insightId == insightId;
  }

  @override
  int get hashCode => insightId.hashCode;

  @override
  String toString() {
    return 'DashboardInsight(id: $insightId, category: $category, title: $title)';
  }
}

/// Aggregated analytics summary
class AnalyticsSummary {
  final String userId;
  final DateTime periodStart;
  final DateTime periodEnd;
  final int totalTrips;
  final double totalSpending;
  final int aiInteractions;
  final double averageTripSatisfaction;
  final Map<String, int> topCategories;
  final Map<String, dynamic> insights;
  final DateTime lastUpdated;

  const AnalyticsSummary({
    required this.userId,
    required this.periodStart,
    required this.periodEnd,
    required this.totalTrips,
    required this.totalSpending,
    required this.aiInteractions,
    required this.averageTripSatisfaction,
    required this.topCategories,
    required this.insights,
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'periodStart': Timestamp.fromDate(periodStart),
      'periodEnd': Timestamp.fromDate(periodEnd),
      'totalTrips': totalTrips,
      'totalSpending': totalSpending,
      'aiInteractions': aiInteractions,
      'averageTripSatisfaction': averageTripSatisfaction,
      'topCategories': topCategories,
      'insights': insights,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  factory AnalyticsSummary.fromMap(Map<String, dynamic> map) {
    return AnalyticsSummary(
      userId: map['userId'] ?? '',
      periodStart: (map['periodStart'] as Timestamp?)?.toDate() ?? DateTime.now(),
      periodEnd: (map['periodEnd'] as Timestamp?)?.toDate() ?? DateTime.now(),
      totalTrips: map['totalTrips']?.toInt() ?? 0,
      totalSpending: map['totalSpending']?.toDouble() ?? 0.0,
      aiInteractions: map['aiInteractions']?.toInt() ?? 0,
      averageTripSatisfaction: map['averageTripSatisfaction']?.toDouble() ?? 0.0,
      topCategories: Map<String, int>.from(map['topCategories'] ?? {}),
      insights: map['insights'] ?? {},
      lastUpdated: (map['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory AnalyticsSummary.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AnalyticsSummary.fromMap(data);
  }
}
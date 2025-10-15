/// Analytics Service Interface
/// Defines contract for analytics tracking, session management, and insights
abstract class IAnalyticsService {
  // ===============================
  // SESSION MANAGEMENT
  // ===============================

  /// Start analytics session
  Future<void> startSession();

  /// End analytics session
  Future<void> endSession();

  // ===============================
  // EVENT TRACKING
  // ===============================

  /// Track an event
  Future<void> trackEvent(
    String eventName,
    Map<String, dynamic>? properties, {
    String? category,
    String? userId,
  });

  /// Track screen view
  Future<void> trackScreenView(
    String screenName, {
    Map<String, dynamic>? properties,
  });

  /// Track user action
  Future<void> trackUserAction(
    String action,
    String target, {
    Map<String, dynamic>? properties,
  });

  /// Track content interaction
  Future<void> trackContentInteraction(
    String contentType,
    String contentId,
    String interaction, {
    Map<String, dynamic>? properties,
  });

  /// Track search
  Future<void> trackSearch(
    String query,
    String category,
    int resultCount, {
    Map<String, dynamic>? filters,
  });

  /// Track booking flow
  Future<void> trackBookingStep(
    String step,
    String bookingId, {
    Map<String, dynamic>? properties,
  });

  /// Track error
  Future<void> trackError(
    String errorType,
    String errorMessage, {
    String? stackTrace,
    Map<String, dynamic>? context,
  });

  /// Track performance metric
  Future<void> trackPerformance(
    String metric,
    double value, {
    String? unit,
    Map<String, dynamic>? context,
  });

  // ===============================
  // ANALYTICS QUERIES
  // ===============================

  /// Get event analytics
  Future<Map<String, dynamic>> getEventAnalytics({
    String? eventName,
    String? category,
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
    String groupBy = 'day',
  });

  /// Get user analytics
  Future<Map<String, dynamic>> getUserAnalytics({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Get app performance metrics
  Future<Map<String, dynamic>> getPerformanceMetrics({
    Duration period = const Duration(days: 7),
  });

  // ===============================
  // USER METRICS
  // ===============================

  /// Update user metrics
  Future<void> updateUserMetrics({
    String? userId,
    Map<String, dynamic>? metrics,
  });

  /// Get user engagement score
  Future<double> getUserEngagementScore([String? userId]);

  // ===============================
  // BATCH OPERATIONS
  // ===============================

  /// Track multiple events in batch
  Future<void> trackEventsBatch(List<Map<String, dynamic>> events);

  // ===============================
  // CACHE AND PERFORMANCE
  // ===============================

  /// Get cached analytics
  Future<Map<String, dynamic>?> getCachedAnalytics(String key);

  /// Cache analytics data
  Future<void> cacheAnalytics(
    String key,
    Map<String, dynamic> data, {
    Duration duration = const Duration(hours: 1),
  });
}
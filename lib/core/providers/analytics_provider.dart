import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/interfaces/i_analytics_service.dart';
import '../../services/supabase_auth_service.dart';
import '../config/service_locator.dart';
import '../models/analytics_model.dart';
import '../utils/logger.dart';

class AnalyticsProvider extends ChangeNotifier {
  static const String _tag = 'AnalyticsProvider';
  
  // ignore: unused_field
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Analytics Service instance
  late final IAnalyticsService _analyticsService;
  
  // Analytics state
  AnalyticsSummary? _analyticsSummary;
  List<DashboardInsight> _insights = [];
  bool _isLoading = false;
  String? _error;
  
  // Cache for performance
  DateTime? _lastFetchTime;
  static const Duration _cacheTimeout = Duration(minutes: 5);
  
  // Getters
  AnalyticsSummary? get analyticsSummary => _analyticsSummary;
  List<DashboardInsight> get insights => _insights;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Initialize analytics
  Future<void> initialize() async {
    try {
      AppLogger.info(_tag, 'Initializing analytics provider');
      
      // Initialize analytics service and start session
      await analyticsService.startSession();
      await loadAnalyticsData();
      AppLogger.success(_tag, 'Analytics provider initialized successfully');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to initialize analytics provider', e, stackTrace);
    }
  }
  
  // Load analytics data
  Future<void> loadAnalyticsData({bool forceRefresh = false}) async {
    try {
      // Check if we need to refresh data
      if (!forceRefresh && _lastFetchTime != null) {
        final timeDiff = DateTime.now().difference(_lastFetchTime!);
        if (timeDiff < _cacheTimeout && _analyticsSummary != null) {
          AppLogger.debug(_tag, 'Using cached analytics data');
          return;
        }
      }
      
      final userId = SupabaseAuthService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }
      
      _setLoading(true);
      _error = null;
      
      AppLogger.info(_tag, 'Loading analytics data');
      
      // Create placeholder analytics data since we don't have specific methods yet
      final now = DateTime.now();
      _analyticsSummary = AnalyticsSummary(
        userId: userId,
        periodStart: now.subtract(const Duration(days: 30)),
        periodEnd: now,
        totalTrips: 0,
        totalSpending: 0.0,
        aiInteractions: 0,
        averageTripSatisfaction: 0.0,
        topCategories: {},
        insights: {},
        lastUpdated: now,
      );
      
      _insights = [
        DashboardInsight(
          insightId: 'welcome',
          userId: userId,
          title: 'Analytics Initialized',
          description: 'Analytics tracking is now active for your account',
          category: 'system',
          priority: 5,
          data: {},
          actionableRecommendations: [],
          generatedAt: now,
          isActive: true,
        ),
      ];
      
      _lastFetchTime = DateTime.now();
      
      AppLogger.success(_tag, 'Analytics data loaded successfully', {
        'totalTrips': _analyticsSummary?.totalTrips ?? 0,
        'totalSpending': _analyticsSummary?.totalSpending ?? 0,
        'insightsCount': _insights.length,
      });
      
    } catch (e, stackTrace) {
      _error = e.toString();
      AppLogger.error(_tag, 'Failed to load analytics data', e, stackTrace);
    } finally {
      _setLoading(false);
    }
  }
  
  // Track user behavior event
  Future<void> trackEvent({
    required String eventName,
    Map<String, dynamic>? properties,
    String? category,
  }) async {
    try {
      await analyticsService.trackEvent(
        eventName,
        properties,
        category: category,
      );
      
      AppLogger.debug(_tag, 'Event tracked', {
        'eventName': eventName,
        'category': category,
      });
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to track event', e, stackTrace);
    }
  }

  // Track screen view
  Future<void> trackScreenView(String screenName, {Map<String, dynamic>? properties}) async {
    try {
      await analyticsService.trackScreenView(screenName, properties: properties);
      AppLogger.debug(_tag, 'Screen view tracked: $screenName');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to track screen view', e, stackTrace);
    }
  }  // Dismiss insight
  Future<void> dismissInsight(String insightId) async {
    try {
      AppLogger.debug(_tag, 'Dismissing insight', {'insightId': insightId});
      
      _insights.removeWhere((insight) => insight.insightId == insightId);
      notifyListeners();

      // Dismissed insights are removed from memory
      // Could be persisted to local storage if needed in future

    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to dismiss insight', e, stackTrace);
    }
  }
  
  // Get spending trends for charts
  List<Map<String, dynamic>> getSpendingTrends() {
    if (_analyticsSummary == null) {
      return [];
    }
    
    // Create mock monthly data from total spending
    final totalSpending = _analyticsSummary!.totalSpending;
    final monthlyAverage = totalSpending / 6; // Distribute over 6 months
    
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
    return months.asMap().entries.map((entry) {
      final variation = (entry.key % 2 == 0) ? 0.8 : 1.2; // Add some variation
      return {
        'month': entry.value,
        'amount': monthlyAverage * variation,
      };
    }).toList();
  }
  
  // Get category breakdown for pie chart
  Map<String, int> getCategoryBreakdown() {
    return _analyticsSummary?.topCategories ?? {};
  }
  
  // Helper method to safely get analytics service
  IAnalyticsService get analyticsService {
    if (!_isServiceInitialized) {
      _analyticsService = ServiceLocator.analyticsService;
      _isServiceInitialized = true;
    }
    return _analyticsService;
  }
  
  bool _isServiceInitialized = false;
  
  // Helper methods
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
  
  @override
  void dispose() {
    AppLogger.debug(_tag, 'Disposing analytics provider');
    // Note: We don't end session here as it should be managed at app level
    // _analyticsService.endSession() should be called when app closes
    super.dispose();
  }
}
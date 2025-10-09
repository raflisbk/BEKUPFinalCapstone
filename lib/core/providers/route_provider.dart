import 'package:flutter/foundation.dart';
import '../../services/ai/ai_route_planning_service.dart';
import '../../services/ai/ai_navigation_service.dart';
import '../models/route_model.dart';
import '../utils/logger.dart';

class RouteProvider extends ChangeNotifier {
  static const String _tag = 'RouteProvider';
  
  final AIRoutePlanningService _routePlanningService = AIRoutePlanningService();
  final AINavigationService _navigationService = AINavigationService();
  
  // Route planning state
  RoutePlan? _currentRoutePlan;
  List<AIRouteSuggestion> _aiSuggestions = [];
  bool _isLoading = false;
  String? _error;
  
  // Navigation state
  bool _isNavigating = false;
  String? _currentInstruction;
  final List<AINavigationSuggestion> _navigationSuggestions = [];
  
  // Getters
  RoutePlan? get currentRoutePlan => _currentRoutePlan;
  List<AIRouteSuggestion> get aiSuggestions => _aiSuggestions;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isNavigating => _isNavigating;
  String? get currentInstruction => _currentInstruction;
  List<AINavigationSuggestion> get navigationSuggestions => _navigationSuggestions;
  
  // Create route plan
  Future<void> createRoutePlan({
    required String userId,
    required String tripId,
    required String name,
    required RouteLocation origin,
    required RouteLocation destination,
    List<RouteLocation>? waypoints,
    TravelMode travelMode = TravelMode.driving,
    RouteOptimization optimization = RouteOptimization.fastest,
  }) async {
    try {
      _setLoading(true);
      _error = null;
      
      AppLogger.info(_tag, 'Creating route plan', {
        'userId': userId,
        'tripId': tripId,
        'name': name,
        'origin': origin.name,
        'destination': destination.name,
        'waypoints': waypoints?.length ?? 0,
        'travelMode': travelMode.name,
        'optimization': optimization.name,
      });
      
      _currentRoutePlan = await _routePlanningService.createRoutePlan(
        userId: userId,
        tripId: tripId,
        name: name,
        origin: origin,
        destination: destination,
        waypoints: waypoints ?? [],
        travelMode: travelMode,
        optimization: optimization,
      );
      
      if (_currentRoutePlan != null) {
        _aiSuggestions = _currentRoutePlan!.aiSuggestions;
        AppLogger.success(_tag, 'Route plan created successfully');
      }
      
    } catch (e, stackTrace) {
      _error = e.toString();
      AppLogger.error(_tag, 'Failed to create route plan', e, stackTrace);
    } finally {
      _setLoading(false);
    }
  }
  
  // Start navigation
  Future<void> startNavigation(RoutePlan routePlan) async {
    try {
      AppLogger.info(_tag, 'Starting navigation', {
        'routeId': routePlan.id,
        'totalDistance': routePlan.totalDistance,
        'totalDuration': routePlan.totalDuration,
      });
      
      _isNavigating = true;
      notifyListeners();
      
      await _navigationService.startNavigation(routePlan);
      
      AppLogger.success(_tag, 'Navigation started successfully');
      
    } catch (e, stackTrace) {
      _error = e.toString();
      _isNavigating = false;
      AppLogger.error(_tag, 'Failed to start navigation', e, stackTrace);
      notifyListeners();
    }
  }
  
  // Stop navigation
  Future<void> stopNavigation() async {
    try {
      AppLogger.info(_tag, 'Stopping navigation');
      
      await _navigationService.stopNavigation();
      _isNavigating = false;
      _currentInstruction = null;
      _navigationSuggestions.clear();
      
      AppLogger.success(_tag, 'Navigation stopped successfully');
      notifyListeners();
      
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to stop navigation', e, stackTrace);
    }
  }
  
  // Clear current route plan
  void clearRoutePlan() {
    AppLogger.debug(_tag, 'Clearing route plan');
    _currentRoutePlan = null;
    _aiSuggestions.clear();
    _error = null;
    notifyListeners();
  }
  
  // Apply AI suggestion
  Future<void> applyAISuggestion(AIRouteSuggestion suggestion) async {
    try {
      AppLogger.info(_tag, 'Applying AI suggestion', {
        'optimizationType': suggestion.optimizationType.name,
        'title': suggestion.title,
      });

      // Apply the suggestion based on optimization type
      if (_currentRoutePlan != null) {
        await createRoutePlan(
          userId: _currentRoutePlan!.userId,
          tripId: _currentRoutePlan!.tripId,
          name: _currentRoutePlan!.name,
          origin: _currentRoutePlan!.origin,
          destination: _currentRoutePlan!.destination,
          waypoints: _currentRoutePlan!.waypoints,
          travelMode: _currentRoutePlan!.travelMode,
          optimization: suggestion.optimizationType,
        );
      }

      AppLogger.success(_tag, 'AI suggestion applied successfully');
      notifyListeners();

    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to apply AI suggestion', e, stackTrace);
    }
  }
  
  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  @override
  void dispose() {
    AppLogger.debug(_tag, 'Disposing route provider');
    if (_isNavigating) {
      stopNavigation();
    }
    super.dispose();
  }
}
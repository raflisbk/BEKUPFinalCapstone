import 'dart:async';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/config/env_config.dart';
import '../../core/utils/logger.dart';
import '../../core/models/route_model.dart';
import './gemini_service.dart';

/// Real-time navigation service with AI-powered suggestions and traffic optimization
class AINavigationService {
  static const String _tag = 'AINavigationService';
  static final AINavigationService _instance = AINavigationService._internal();
  factory AINavigationService() => _instance;
  AINavigationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GeminiService _geminiService = GeminiService();
  
  late final String _googleMapsApiKey;
  bool _isInitialized = false;
  bool _isNavigating = false;
  
  // Navigation state
  RoutePlan? _currentRoute;
  Position? _currentPosition;
  int _currentStepIndex = 0;
  StreamSubscription<Position>? _positionSubscription;
  Timer? _navigationTimer;
  final List<NavigationUpdate> _navigationHistory = [];
  
  // AI suggestions cache
  final Map<String, List<AINavigationSuggestion>> _suggestionCache = {};
  DateTime? _lastSuggestionUpdate;

  /// Navigation update callback
  void Function(NavigationUpdate)? onNavigationUpdate;
  void Function(AINavigationSuggestion)? onAISuggestion;
  void Function(String)? onRouteDeviation;

  /// Initialize the navigation service
  Future<void> initialize() async {
    if (_isInitialized) {
      AppLogger.debug(_tag, 'Already initialized');
      return;
    }

    try {
      _googleMapsApiKey = EnvConfig.googleMapsApiKey;
      
      if (_googleMapsApiKey.isEmpty) {
        throw Exception('GOOGLE_MAPS_API_KEY not found in .env file');
      }

      await _geminiService.initialize();
      _isInitialized = true;
      
      AppLogger.info(_tag, 'AI Navigation Service initialized successfully');
    } catch (e) {
      AppLogger.error(_tag, 'Failed to initialize AI Navigation Service', e);
      rethrow;
    }
  }

  /// Start navigation for a route plan
  Future<bool> startNavigation(RoutePlan routePlan) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      AppLogger.info(_tag, 'Starting navigation for route: ${routePlan.name}');

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      _currentRoute = routePlan;
      _currentStepIndex = 0;
      _isNavigating = true;
      _navigationHistory.clear();

      // Get initial position
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Start position tracking
      await _startPositionTracking();

      // Start AI suggestion generation
      _startAISuggestionGeneration();

      // Save navigation session to Firestore
      await _saveNavigationSession();

      AppLogger.success(_tag, 'Navigation started successfully');
      return true;

    } catch (e) {
      AppLogger.error(_tag, 'Failed to start navigation', e);
      _isNavigating = false;
      return false;
    }
  }

  /// Stop navigation
  Future<void> stopNavigation() async {
    try {
      AppLogger.info(_tag, 'Stopping navigation');

      _isNavigating = false;
      await _positionSubscription?.cancel();
      _navigationTimer?.cancel();

      // Save navigation completion data
      if (_currentRoute != null) {
        await _saveNavigationCompletion();
      }

      _currentRoute = null;
      _currentPosition = null;
      _currentStepIndex = 0;
      _suggestionCache.clear();

      AppLogger.success(_tag, 'Navigation stopped successfully');
    } catch (e) {
      AppLogger.error(_tag, 'Error stopping navigation', e);
    }
  }

  /// Start real-time position tracking
  Future<void> _startPositionTracking() async {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        _handlePositionUpdate(position);
      },
      onError: (error) {
        AppLogger.error(_tag, 'Position tracking error', error);
      },
    );

    AppLogger.debug(_tag, 'Position tracking started');
  }

  /// Handle position updates during navigation
  void _handlePositionUpdate(Position position) async {
    if (!_isNavigating || _currentRoute == null) return;

    _currentPosition = position;

    try {
      // Calculate progress and generate navigation update
      final update = await _generateNavigationUpdate(position);
      
      // Add to history
      _navigationHistory.add(update);

      // Check for route deviation
      await _checkRouteDeviation(position);

      // Check if step is completed
      await _checkStepCompletion(position);

      // Notify listeners
      onNavigationUpdate?.call(update);

      AppLogger.debug(_tag, 'Position updated: ${position.latitude}, ${position.longitude}');

    } catch (e) {
      AppLogger.error(_tag, 'Error handling position update', e);
    }
  }

  /// Generate navigation update with current status
  Future<NavigationUpdate> _generateNavigationUpdate(Position position) async {
    final currentStep = _getCurrentStep();
    if (currentStep == null) {
      throw Exception('No current navigation step');
    }

    // Calculate distance to next step
    final distanceToNext = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      currentStep.endLocation.latitude,
      currentStep.endLocation.longitude,
    );

    // Calculate ETA
    final eta = await _calculateETA(position);

    // Get traffic information
    final trafficInfo = await _getTrafficInformation(position);

    return NavigationUpdate(
      currentPosition: RouteLocation(
        id: 'current_pos',
        name: 'Current Location',
        address: '',
        latitude: position.latitude,
        longitude: position.longitude,
      ),
      currentStep: currentStep,
      stepIndex: _currentStepIndex,
      totalSteps: _currentRoute!.steps.length,
      distanceToNextStep: distanceToNext,
      estimatedTimeArrival: eta,
      currentSpeed: position.speed,
      bearing: position.heading,
      trafficInfo: trafficInfo,
      timestamp: DateTime.now(),
    );
  }

  /// Check if user has deviated from the planned route
  Future<void> _checkRouteDeviation(Position position) async {
    final currentStep = _getCurrentStep();
    if (currentStep == null) return;

    // Calculate distance from route polyline
    final deviationDistance = _calculateDistanceFromRoute(position, currentStep);
    
    if (deviationDistance > 100) { // 100 meters threshold
      AppLogger.warning(_tag, 'Route deviation detected: ${deviationDistance.toStringAsFixed(0)}m');
      
      // Generate rerouting suggestion
      final reroutingSuggestion = await _generateReroutingSuggestion(position);
      onRouteDeviation?.call('Route deviation detected. Calculating alternative route...');
      
      if (reroutingSuggestion != null) {
        onAISuggestion?.call(reroutingSuggestion);
      }
    }
  }

  /// Check if current step is completed
  Future<void> _checkStepCompletion(Position position) async {
    final currentStep = _getCurrentStep();
    if (currentStep == null) return;

    final distanceToEnd = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      currentStep.endLocation.latitude,
      currentStep.endLocation.longitude,
    );

    if (distanceToEnd < 20) { // 20 meters threshold
      _currentStepIndex++;
      
      if (_currentStepIndex >= _currentRoute!.steps.length) {
        // Navigation completed
        AppLogger.success(_tag, 'Navigation completed successfully');
        await stopNavigation();
      } else {
        AppLogger.info(_tag, 'Step ${_currentStepIndex - 1} completed, moving to step $_currentStepIndex');
      }
    }
  }

  /// Start AI suggestion generation timer
  void _startAISuggestionGeneration() {
    _navigationTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      if (_isNavigating && _currentPosition != null) {
        _generateAINavigationSuggestions();
      }
    });

    // Generate initial suggestions
    _generateAINavigationSuggestions();
  }

  /// Generate AI-powered navigation suggestions
  Future<void> _generateAINavigationSuggestions() async {
    if (_currentPosition == null || _currentRoute == null) return;

    try {
      final cacheKey = '${_currentPosition!.latitude}_${_currentPosition!.longitude}_${DateTime.now().hour}';
      
      // Check cache first
      if (_suggestionCache.containsKey(cacheKey) && 
          _lastSuggestionUpdate != null &&
          DateTime.now().difference(_lastSuggestionUpdate!).inMinutes < 5) {
        return;
      }

      AppLogger.debug(_tag, 'Generating AI navigation suggestions');

      final currentStep = _getCurrentStep();
      final trafficInfo = await _getTrafficInformation(_currentPosition!);
      final nearbyPOIs = await _getNearbyPointsOfInterest(_currentPosition!);

      final prompt = '''
You are an AI navigation assistant providing real-time travel suggestions. Analyze the current situation and provide helpful recommendations.

Current Navigation Context:
- Current Location: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}
- Current Step: ${currentStep?.instruction ?? 'Unknown'}
- Travel Mode: ${_currentRoute!.travelMode.value}
- Destination: ${_currentRoute!.destination.name}
- Steps Remaining: ${_currentRoute!.steps.length - _currentStepIndex}

Traffic Information:
${trafficInfo['summary'] ?? 'No traffic data available'}

Nearby Points of Interest:
${nearbyPOIs.take(5).map((poi) => '- ${poi['name']}: ${poi['vicinity']}').join('\n')}

Weather Conditions: ${await _getCurrentWeatherConditions()}

Please provide 2-3 contextual suggestions considering:
1. Traffic optimization and alternative routes
2. Nearby amenities (gas stations, restaurants, rest stops)
3. Safety and comfort recommendations
4. Time-sensitive opportunities or warnings
5. Cost-saving tips

Format each suggestion with:
- Title (concise)
- Description (actionable advice)
- Priority (1-10)
- Category (traffic, amenity, safety, opportunity)
''';

      final aiResponse = await _geminiService.generateText(prompt);
      final suggestions = _parseAINavigationSuggestions(aiResponse);

      _suggestionCache[cacheKey] = suggestions;
      _lastSuggestionUpdate = DateTime.now();

      // Send high-priority suggestions immediately
      for (final suggestion in suggestions) {
        if (suggestion.priority >= 8) {
          onAISuggestion?.call(suggestion);
        }
      }

      AppLogger.success(_tag, 'Generated ${suggestions.length} AI navigation suggestions');

    } catch (e) {
      AppLogger.error(_tag, 'Failed to generate AI navigation suggestions', e);
    }
  }

  /// Parse AI response into navigation suggestions
  List<AINavigationSuggestion> _parseAINavigationSuggestions(String aiResponse) {
    final suggestions = <AINavigationSuggestion>[];
    
    try {
      final lines = aiResponse.split('\n');
      String? currentTitle;
      String? currentDescription;
      int currentPriority = 5;
      String currentCategory = 'general';

      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;

        if (trimmed.startsWith('Title:') || trimmed.startsWith('**')) {
          if (currentTitle != null) {
            suggestions.add(AINavigationSuggestion(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              title: currentTitle,
              description: currentDescription ?? '',
              priority: currentPriority,
              category: currentCategory,
              timestamp: DateTime.now(),
              isActive: true,
            ));
          }
          currentTitle = trimmed.replaceAll(RegExp(r'(Title:|\*\*)'), '').trim();
          currentDescription = null;
        } else if (trimmed.startsWith('Description:')) {
          currentDescription = trimmed.replaceAll('Description:', '').trim();
        } else if (trimmed.startsWith('Priority:')) {
          final priorityMatch = RegExp(r'\d+').firstMatch(trimmed);
          if (priorityMatch != null) {
            currentPriority = int.tryParse(priorityMatch.group(0)!) ?? 5;
          }
        } else if (trimmed.startsWith('Category:')) {
          currentCategory = trimmed.replaceAll('Category:', '').trim().toLowerCase();
        }
      }

      // Add final suggestion
      if (currentTitle != null) {
        suggestions.add(AINavigationSuggestion(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: currentTitle,
          description: currentDescription ?? '',
          priority: currentPriority,
          category: currentCategory,
          timestamp: DateTime.now(),
          isActive: true,
        ));
      }

    } catch (e) {
      AppLogger.error(_tag, 'Failed to parse AI navigation suggestions', e);
    }

    return suggestions;
  }

  /// Generate rerouting suggestion when user deviates from route
  Future<AINavigationSuggestion?> _generateReroutingSuggestion(Position position) async {
    try {
      final prompt = '''
User has deviated from planned route. Current position: ${position.latitude}, ${position.longitude}
Destination: ${_currentRoute!.destination.name}

Provide a helpful rerouting suggestion that:
1. Acknowledges the deviation
2. Offers to recalculate the route
3. Suggests the best course of action

Keep it concise and actionable.
''';

      final aiResponse = await _geminiService.generateText(prompt);
      
      return AINavigationSuggestion(
        id: 'reroute_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Route Recalculation',
        description: aiResponse.trim(),
        priority: 9,
        category: 'rerouting',
        timestamp: DateTime.now(),
        isActive: true,
      );

    } catch (e) {
      AppLogger.error(_tag, 'Failed to generate rerouting suggestion', e);
      return null;
    }
  }

  /// Get current traffic information
  Future<Map<String, dynamic>> _getTrafficInformation(Position position) async {
    try {
      // This would integrate with traffic APIs in production
      // For now, return mock data
      return {
        'summary': 'Moderate traffic ahead',
        'delayMinutes': 5,
        'alternativeAvailable': true,
      };
    } catch (e) {
      AppLogger.error(_tag, 'Failed to get traffic information', e);
      return {};
    }
  }

  /// Get nearby points of interest
  Future<List<Map<String, dynamic>>> _getNearbyPointsOfInterest(Position position) async {
    try {
      final url = Uri.parse('https://maps.googleapis.com/maps/api/place/nearbysearch/json'
          '?location=${position.latitude},${position.longitude}'
          '&radius=2000'
          '&type=gas_station|restaurant|hospital'
          '&key=$_googleMapsApiKey');

      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['results'] ?? []);
      }
    } catch (e) {
      AppLogger.error(_tag, 'Failed to get nearby POIs', e);
    }
    
    return [];
  }

  /// Get current weather conditions
  Future<String> _getCurrentWeatherConditions() async {
    try {
      // This would integrate with weather API
      // For now, return placeholder
      return 'Clear skies, 22°C';
    } catch (e) {
      return 'Weather data unavailable';
    }
  }

  /// Calculate ETA to destination
  Future<DateTime> _calculateETA(Position position) async {
    if (_currentRoute == null) return DateTime.now();

    final remainingDistance = _calculateRemainingDistance(position);
    final averageSpeed = _calculateAverageSpeed();
    final remainingTimeHours = remainingDistance / averageSpeed;
    
    return DateTime.now().add(Duration(minutes: (remainingTimeHours * 60).round()));
  }

  /// Helper methods
  RouteStep? _getCurrentStep() {
    if (_currentRoute == null || _currentStepIndex >= _currentRoute!.steps.length) {
      return null;
    }
    return _currentRoute!.steps[_currentStepIndex];
  }

  double _calculateDistanceFromRoute(Position position, RouteStep step) {
    // Simplified distance calculation to route polyline
    return Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      step.startLocation.latitude,
      step.startLocation.longitude,
    );
  }

  double _calculateRemainingDistance(Position position) {
    if (_currentRoute == null) return 0.0;

    double distance = 0.0;
    
    // Distance to current step end
    final currentStep = _getCurrentStep();
    if (currentStep != null) {
      distance += Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        currentStep.endLocation.latitude,
        currentStep.endLocation.longitude,
      );
    }

    // Distance for remaining steps
    for (int i = _currentStepIndex + 1; i < _currentRoute!.steps.length; i++) {
      final step = _currentRoute!.steps[i];
      distance += Geolocator.distanceBetween(
        step.startLocation.latitude,
        step.startLocation.longitude,
        step.endLocation.latitude,
        step.endLocation.longitude,
      );
    }

    return distance / 1000; // Convert to kilometers
  }

  double _calculateAverageSpeed() {
    if (_navigationHistory.length < 2) return 50.0; // Default 50 km/h

    final recentHistory = _navigationHistory.length > 10 
        ? _navigationHistory.sublist(_navigationHistory.length - 10)
        : _navigationHistory;
    double totalSpeed = 0.0;
    int count = 0;

    for (final update in recentHistory) {
      if (update.currentSpeed > 0) {
        totalSpeed += update.currentSpeed * 3.6; // Convert m/s to km/h
        count++;
      }
    }

    return count > 0 ? totalSpeed / count : 50.0;
  }

  /// Save navigation session to Firestore
  Future<void> _saveNavigationSession() async {
    if (_currentRoute == null) return;

    try {
      await _firestore.collection('navigation_sessions').add({
        'routePlanId': _currentRoute!.id,
        'userId': _currentRoute!.userId,
        'startTime': Timestamp.now(),
        'startLocation': {
          'latitude': _currentPosition?.latitude,
          'longitude': _currentPosition?.longitude,
        },
        'status': 'active',
      });

      AppLogger.debug(_tag, 'Navigation session saved');
    } catch (e) {
      AppLogger.error(_tag, 'Failed to save navigation session', e);
    }
  }

  /// Save navigation completion data
  Future<void> _saveNavigationCompletion() async {
    try {
      await _firestore.collection('navigation_completions').add({
        'routePlanId': _currentRoute!.id,
        'userId': _currentRoute!.userId,
        'endTime': Timestamp.now(),
        'totalSteps': _currentRoute!.steps.length,
        'completedSteps': _currentStepIndex,
        'navigationHistory': _navigationHistory.map((update) => update.toMap()).toList(),
        'wasCompleted': _currentStepIndex >= _currentRoute!.steps.length,
      });

      AppLogger.debug(_tag, 'Navigation completion saved');
    } catch (e) {
      AppLogger.error(_tag, 'Failed to save navigation completion', e);
    }
  }

  /// Getters
  bool get isNavigating => _isNavigating;
  RoutePlan? get currentRoute => _currentRoute;
  Position? get currentPosition => _currentPosition;
  int get currentStepIndex => _currentStepIndex;
  List<NavigationUpdate> get navigationHistory => List.unmodifiable(_navigationHistory);
}

/// Navigation update data class
class NavigationUpdate {
  final RouteLocation currentPosition;
  final RouteStep currentStep;
  final int stepIndex;
  final int totalSteps;
  final double distanceToNextStep;
  final DateTime estimatedTimeArrival;
  final double currentSpeed;
  final double bearing;
  final Map<String, dynamic> trafficInfo;
  final DateTime timestamp;

  const NavigationUpdate({
    required this.currentPosition,
    required this.currentStep,
    required this.stepIndex,
    required this.totalSteps,
    required this.distanceToNextStep,
    required this.estimatedTimeArrival,
    required this.currentSpeed,
    required this.bearing,
    required this.trafficInfo,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'currentPosition': currentPosition.toMap(),
      'currentStep': currentStep.toMap(),
      'stepIndex': stepIndex,
      'totalSteps': totalSteps,
      'distanceToNextStep': distanceToNextStep,
      'estimatedTimeArrival': Timestamp.fromDate(estimatedTimeArrival),
      'currentSpeed': currentSpeed,
      'bearing': bearing,
      'trafficInfo': trafficInfo,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}

/// AI navigation suggestion data class
class AINavigationSuggestion {
  final String id;
  final String title;
  final String description;
  final int priority;
  final String category;
  final DateTime timestamp;
  final bool isActive;

  const AINavigationSuggestion({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.category,
    required this.timestamp,
    required this.isActive,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'priority': priority,
      'category': category,
      'timestamp': Timestamp.fromDate(timestamp),
      'isActive': isActive,
    };
  }
}
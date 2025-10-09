import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/logger.dart';
import '../../core/models/route_model.dart';
import './gemini_service.dart';

/// AI-powered route planning service with Google Directions API integration
class AIRoutePlanningService {
  static const String _tag = 'AIRoutePlanningService';
  static final AIRoutePlanningService _instance = AIRoutePlanningService._internal();
  factory AIRoutePlanningService() => _instance;
  AIRoutePlanningService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GeminiService _geminiService = GeminiService();
  
  late final String _googleMapsApiKey;
  bool _isInitialized = false;

  /// Initialize the service with API keys
  Future<void> initialize() async {
    if (_isInitialized) {
      AppLogger.debug(_tag, 'Already initialized');
      return;
    }

    try {
      _googleMapsApiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
      
      if (_googleMapsApiKey.isEmpty) {
        throw Exception('GOOGLE_MAPS_API_KEY not found in .env file');
      }

      await _geminiService.initialize();
      _isInitialized = true;
      
      AppLogger.info(_tag, 'AI Route Planning Service initialized successfully');
    } catch (e) {
      AppLogger.error(_tag, 'Failed to initialize AI Route Planning Service', e);
      rethrow;
    }
  }

  /// Create an optimized route plan with AI suggestions
  Future<RoutePlan> createRoutePlan({
    required String userId,
    required String tripId,
    required String name,
    required RouteLocation origin,
    required RouteLocation destination,
    List<RouteLocation> waypoints = const [],
    TravelMode travelMode = TravelMode.driving,
    RouteOptimization optimization = RouteOptimization.fastest,
  }) async {
    try {
      AppLogger.info(_tag, 'Creating route plan: $name');

      // Optimize waypoints order using AI
      final optimizedWaypoints = await _optimizeWaypointOrder(
        origin, destination, waypoints, travelMode, optimization
      );

      // Get route directions from Google Directions API
      final directions = await _getDirections(
        origin, destination, optimizedWaypoints, travelMode, optimization
      );

      // Generate AI suggestions for route optimization
      final aiSuggestions = await _generateAISuggestions(
        origin, destination, optimizedWaypoints, travelMode, optimization
      );

      // Calculate estimated cost
      final estimatedCost = await _calculateEstimatedCost(
        directions['totalDistance'], directions['totalDuration'], travelMode
      );

      // Create route plan
      final routePlan = RoutePlan(
        id: '', // Will be set by Firestore
        userId: userId,
        tripId: tripId,
        name: name,
        origin: origin,
        destination: destination,
        waypoints: optimizedWaypoints,
        travelMode: travelMode,
        optimization: optimization,
        steps: directions['steps'] as List<RouteStep>,
        totalDistance: directions['totalDistance'] as String,
        totalDuration: directions['totalDuration'] as String,
        estimatedCost: estimatedCost,
        aiSuggestions: aiSuggestions,
        routeMetadata: directions['metadata'] as Map<String, dynamic>,
        createdAt: DateTime.now(),
        isActive: true,
      );

      // Save to Firestore
      final docRef = await _firestore.collection('route_plans').add(routePlan.toMap());
      final savedRoutePlan = routePlan.copyWith();
      
      AppLogger.success(_tag, 'Route plan created successfully: ${docRef.id}');
      return savedRoutePlan;

    } catch (e) {
      AppLogger.error(_tag, 'Failed to create route plan', e);
      rethrow;
    }
  }

  /// Optimize waypoint order using AI and travel algorithms
  Future<List<RouteLocation>> _optimizeWaypointOrder(
    RouteLocation origin,
    RouteLocation destination,
    List<RouteLocation> waypoints,
    TravelMode travelMode,
    RouteOptimization optimization,
  ) async {
    if (waypoints.length <= 1) return waypoints;

    try {
      AppLogger.debug(_tag, 'Optimizing waypoint order for ${waypoints.length} points');

      // Use AI to suggest optimal order
      final aiPrompt = '''
Optimize the order of these waypoints for the most efficient travel route:

Origin: ${origin.name} (${origin.latitude}, ${origin.longitude})
Destination: ${destination.name} (${destination.latitude}, ${destination.longitude})

Waypoints:
${waypoints.map((wp) => '- ${wp.name} (${wp.latitude}, ${wp.longitude})').join('\n')}

Travel Mode: ${travelMode.value}
Optimization: ${optimization.value}

Consider:
1. Geographic proximity and logical flow
2. Travel time and distance efficiency
3. Traffic patterns if driving
4. Tourist flow and opening hours
5. Seasonal considerations

Return only the optimized waypoint names in order, one per line.
''';

      final aiResponse = await _geminiService.generateText(aiPrompt);
      final optimizedOrder = _parseOptimizedOrder(aiResponse, waypoints);

      if (optimizedOrder.isNotEmpty) {
        AppLogger.success(_tag, 'AI optimized waypoint order successfully');
        return optimizedOrder;
      }

      // Fallback to simple distance-based optimization
      return _optimizeByDistance(origin, destination, waypoints);

    } catch (e) {
      AppLogger.warning(_tag, 'AI optimization failed, using distance-based fallback', e);
      return _optimizeByDistance(origin, destination, waypoints);
    }
  }

  /// Fallback optimization using simple distance calculations
  List<RouteLocation> _optimizeByDistance(
    RouteLocation origin,
    RouteLocation destination,
    List<RouteLocation> waypoints,
  ) {
    if (waypoints.length <= 1) return waypoints;

    final optimized = <RouteLocation>[];
    final remaining = List<RouteLocation>.from(waypoints);
    RouteLocation current = origin;

    while (remaining.isNotEmpty) {
      // Find closest remaining waypoint
      remaining.sort((a, b) {
        final distA = _calculateDistance(current.latitude, current.longitude, a.latitude, a.longitude);
        final distB = _calculateDistance(current.latitude, current.longitude, b.latitude, b.longitude);
        return distA.compareTo(distB);
      });

      final next = remaining.removeAt(0);
      optimized.add(next);
      current = next;
    }

    AppLogger.debug(_tag, 'Distance-based optimization completed');
    return optimized;
  }

  /// Parse AI response to extract optimized waypoint order
  List<RouteLocation> _parseOptimizedOrder(String aiResponse, List<RouteLocation> originalWaypoints) {
    try {
      final lines = aiResponse.split('\n').map((line) => line.trim()).where((line) => line.isNotEmpty);
      final optimizedOrder = <RouteLocation>[];

      for (final line in lines) {
        final waypoint = originalWaypoints.firstWhere(
          (wp) => wp.name.toLowerCase().contains(line.toLowerCase()) || 
                  line.toLowerCase().contains(wp.name.toLowerCase()),
          orElse: () => originalWaypoints.first,
        );
        
        if (!optimizedOrder.contains(waypoint)) {
          optimizedOrder.add(waypoint);
        }
      }

      // Add any missing waypoints
      for (final wp in originalWaypoints) {
        if (!optimizedOrder.contains(wp)) {
          optimizedOrder.add(wp);
        }
      }

      return optimizedOrder;
    } catch (e) {
      AppLogger.error(_tag, 'Failed to parse AI optimized order', e);
      return originalWaypoints;
    }
  }

  /// Get directions from Google Directions API
  Future<Map<String, dynamic>> _getDirections(
    RouteLocation origin,
    RouteLocation destination,
    List<RouteLocation> waypoints,
    TravelMode travelMode,
    RouteOptimization optimization,
  ) async {
    try {
      AppLogger.debug(_tag, 'Getting directions from Google Directions API');

      final waypointsParam = waypoints.isNotEmpty
          ? waypoints.map((wp) => '${wp.latitude},${wp.longitude}').join('|')
          : '';

      final avoid = _getAvoidParameter(optimization);
      
      final url = Uri.parse('https://maps.googleapis.com/maps/api/directions/json'
          '?origin=${origin.latitude},${origin.longitude}'
          '&destination=${destination.latitude},${destination.longitude}'
          '${waypointsParam.isNotEmpty ? '&waypoints=$waypointsParam' : ''}'
          '&mode=${travelMode.value}'
          '&optimize=${optimization == RouteOptimization.fastest ? 'true' : 'false'}'
          '${avoid.isNotEmpty ? '&avoid=$avoid' : ''}'
          '&key=$_googleMapsApiKey');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final leg = route['legs'][0];

          final steps = <RouteStep>[];
          for (final step in leg['steps']) {
            steps.add(RouteStep(
              instruction: step['html_instructions'].replaceAll(RegExp(r'<[^>]*>'), ''),
              distance: step['distance']['text'],
              duration: step['duration']['text'],
              startLocation: RouteLocation(
                id: 'start_${steps.length}',
                name: 'Start Point',
                address: '',
                latitude: step['start_location']['lat'].toDouble(),
                longitude: step['start_location']['lng'].toDouble(),
              ),
              endLocation: RouteLocation(
                id: 'end_${steps.length}',
                name: 'End Point',
                address: '',
                latitude: step['end_location']['lat'].toDouble(),
                longitude: step['end_location']['lng'].toDouble(),
              ),
              maneuver: step['maneuver'],
              polylinePoints: _decodePolyline(step['polyline']['points']),
            ));
          }

          AppLogger.success(_tag, 'Directions obtained successfully');
          return {
            'steps': steps,
            'totalDistance': leg['distance']['text'],
            'totalDuration': leg['duration']['text'],
            'metadata': {
              'polyline': route['overview_polyline']['points'],
              'bounds': route['bounds'],
              'copyrights': route['copyrights'],
            },
          };
        } else {
          throw Exception('No routes found: ${data['status']}');
        }
      } else {
        throw Exception('Directions API error: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error(_tag, 'Failed to get directions', e);
      rethrow;
    }
  }

  /// Generate AI suggestions for route optimization
  Future<List<AIRouteSuggestion>> _generateAISuggestions(
    RouteLocation origin,
    RouteLocation destination,
    List<RouteLocation> waypoints,
    TravelMode travelMode,
    RouteOptimization optimization,
  ) async {
    try {
      AppLogger.debug(_tag, 'Generating AI suggestions for route');

      final prompt = '''
Analyze this travel route and provide intelligent optimization suggestions:

Route Details:
- Origin: ${origin.name}
- Destination: ${destination.name}
- Waypoints: ${waypoints.map((wp) => wp.name).join(', ')}
- Travel Mode: ${travelMode.value}
- Current Optimization: ${optimization.value}

Provide 3-5 specific, actionable suggestions to improve this route considering:
1. Time efficiency and traffic patterns
2. Cost optimization (fuel, tolls, parking)
3. Tourist experience and attractions
4. Safety and comfort
5. Local insights and hidden gems

For each suggestion, provide:
- Title (concise)
- Description (detailed explanation)
- Reasoning (why this helps)
- Priority score (1-10, where 10 is most important)

Format as JSON array with objects containing: title, description, reasoning, priorityScore, optimizationType
''';

      final aiResponse = await _geminiService.generateText(prompt);
      final suggestions = _parseAISuggestions(aiResponse);

      AppLogger.success(_tag, 'Generated ${suggestions.length} AI suggestions');
      return suggestions;

    } catch (e) {
      AppLogger.warning(_tag, 'Failed to generate AI suggestions', e);
      return [];
    }
  }

  /// Parse AI response to extract route suggestions
  List<AIRouteSuggestion> _parseAISuggestions(String aiResponse) {
    try {
      // Try to parse as JSON first
      final jsonMatch = RegExp(r'\[.*\]', dotAll: true).firstMatch(aiResponse);
      if (jsonMatch != null) {
        final jsonString = jsonMatch.group(0)!;
        final List<dynamic> parsed = json.decode(jsonString);
        
        return parsed.map((item) => AIRouteSuggestion(
          suggestionId: DateTime.now().millisecondsSinceEpoch.toString(),
          title: item['title'] ?? 'Route Suggestion',
          description: item['description'] ?? '',
          reasoning: item['reasoning'] ?? '',
          priorityScore: (item['priorityScore'] ?? 5).toInt(),
          optimizationType: RouteOptimization.fromString(item['optimizationType'] ?? 'fastest'),
          metadata: {'source': 'ai_generated'},
          createdAt: DateTime.now(),
        )).toList();
      }

      // Fallback to parsing structured text
      return _parseStructuredTextSuggestions(aiResponse);

    } catch (e) {
      AppLogger.error(_tag, 'Failed to parse AI suggestions', e);
      return [];
    }
  }

  /// Parse AI suggestions from structured text format
  List<AIRouteSuggestion> _parseStructuredTextSuggestions(String text) {
    final suggestions = <AIRouteSuggestion>[];
    final lines = text.split('\n');
    
    String? currentTitle;
    String? currentDescription;
    String? currentReasoning;
    int currentPriority = 5;

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      if (trimmed.startsWith('Title:') || trimmed.startsWith('**')) {
        if (currentTitle != null) {
          suggestions.add(AIRouteSuggestion(
            suggestionId: DateTime.now().millisecondsSinceEpoch.toString(),
            title: currentTitle,
            description: currentDescription ?? '',
            reasoning: currentReasoning ?? '',
            priorityScore: currentPriority,
            optimizationType: RouteOptimization.fastest,
            metadata: {'source': 'ai_parsed'},
            createdAt: DateTime.now(),
          ));
        }
        currentTitle = trimmed.replaceAll(RegExp(r'(Title:|Description:|Reasoning:|\*\*)'), '').trim();
        currentDescription = null;
        currentReasoning = null;
      } else if (trimmed.startsWith('Description:')) {
        currentDescription = trimmed.replaceAll('Description:', '').trim();
      } else if (trimmed.startsWith('Reasoning:')) {
        currentReasoning = trimmed.replaceAll('Reasoning:', '').trim();
      } else if (trimmed.startsWith('Priority:')) {
        final priorityMatch = RegExp(r'\d+').firstMatch(trimmed);
        if (priorityMatch != null) {
          currentPriority = int.tryParse(priorityMatch.group(0)!) ?? 5;
        }
      }
    }

    // Add final suggestion
    if (currentTitle != null) {
      suggestions.add(AIRouteSuggestion(
        suggestionId: DateTime.now().millisecondsSinceEpoch.toString(),
        title: currentTitle,
        description: currentDescription ?? '',
        reasoning: currentReasoning ?? '',
        priorityScore: currentPriority,
        optimizationType: RouteOptimization.fastest,
        metadata: {'source': 'ai_parsed'},
        createdAt: DateTime.now(),
      ));
    }

    return suggestions;
  }

  /// Calculate estimated cost for the route
  Future<double> _calculateEstimatedCost(
    String totalDistance,
    String totalDuration,
    TravelMode travelMode,
  ) async {
    try {
      final distanceKm = _extractNumericValue(totalDistance);
      final durationHours = _extractNumericValue(totalDuration) / 60.0;

      double cost = 0.0;

      switch (travelMode) {
        case TravelMode.driving:
          // Fuel cost + tolls + parking
          final fuelCost = distanceKm * 0.15; // $0.15 per km
          final tollEstimate = distanceKm * 0.05; // $0.05 per km for tolls
          final parkingCost = durationHours * 2.0; // $2 per hour parking
          cost = fuelCost + tollEstimate + parkingCost;
          break;
        case TravelMode.transit:
          // Public transport fare
          cost = distanceKm * 0.10; // $0.10 per km
          break;
        case TravelMode.walking:
          cost = 0.0; // Free
          break;
        case TravelMode.bicycling:
          cost = 0.0; // Free (assuming own bike)
          break;
      }

      AppLogger.debug(_tag, 'Estimated cost calculated: \$${cost.toStringAsFixed(2)}');
      return cost;

    } catch (e) {
      AppLogger.error(_tag, 'Failed to calculate estimated cost', e);
      return 0.0;
    }
  }

  /// Get route plans for a specific trip
  Future<List<RoutePlan>> getRoutePlansForTrip(String tripId) async {
    try {
      AppLogger.debug(_tag, 'Getting route plans for trip: $tripId');

      final snapshot = await _firestore
          .collection('route_plans')
          .where('tripId', isEqualTo: tripId)
          .orderBy('createdAt', descending: true)
          .get();

      final routes = snapshot.docs.map((doc) => RoutePlan.fromFirestore(doc)).toList();
      
      AppLogger.success(_tag, 'Retrieved ${routes.length} route plans for trip');
      return routes;

    } catch (e) {
      AppLogger.error(_tag, 'Failed to get route plans for trip', e);
      return [];
    }
  }

  /// Update an existing route plan
  Future<RoutePlan?> updateRoutePlan(
    String routeId,
    Map<String, dynamic> updates,
  ) async {
    try {
      AppLogger.debug(_tag, 'Updating route plan: $routeId');

      await _firestore
          .collection('route_plans')
          .doc(routeId)
          .update({
        ...updates,
        'lastModified': Timestamp.now(),
      });

      final doc = await _firestore.collection('route_plans').doc(routeId).get();
      if (doc.exists) {
        final updatedRoute = RoutePlan.fromFirestore(doc);
        AppLogger.success(_tag, 'Route plan updated successfully');
        return updatedRoute;
      }

      return null;
    } catch (e) {
      AppLogger.error(_tag, 'Failed to update route plan', e);
      return null;
    }
  }

  /// Delete a route plan
  Future<bool> deleteRoutePlan(String routeId) async {
    try {
      AppLogger.debug(_tag, 'Deleting route plan: $routeId');

      await _firestore.collection('route_plans').doc(routeId).delete();
      
      AppLogger.success(_tag, 'Route plan deleted successfully');
      return true;

    } catch (e) {
      AppLogger.error(_tag, 'Failed to delete route plan', e);
      return false;
    }
  }

  /// Helper methods
  String _getAvoidParameter(RouteOptimization optimization) {
    switch (optimization) {
      case RouteOptimization.avoidTolls:
        return 'tolls';
      case RouteOptimization.avoidHighways:
        return 'highways';
      default:
        return '';
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // km
    final double dLat = (lat2 - lat1) * (pi / 180);
    final double dLon = (lon2 - lon1) * (pi / 180);
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180)) * cos(lat2 * (pi / 180)) * sin(dLon / 2) * sin(dLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _extractNumericValue(String text) {
    final regex = RegExp(r'[\d.]+');
    final match = regex.firstMatch(text);
    return match != null ? double.tryParse(match.group(0)!) ?? 0.0 : 0.0;
  }

  List<RouteLocation> _decodePolyline(String encoded) {
    // Simplified polyline decoding - in production, use a proper library
    // This is a basic implementation for demonstration
    final points = <RouteLocation>[];
    int index = 0;
    int lat = 0;
    int lng = 0;
    int pointIndex = 0;

    while (index < encoded.length) {
      int shift = 0;
      int result = 0;
      int byte;
      
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20);
      
      int deltaLat = ((result & 1) == 1 ? ~(result >> 1) : (result >> 1));
      lat += deltaLat;

      shift = 0;
      result = 0;
      
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20);
      
      int deltaLng = ((result & 1) == 1 ? ~(result >> 1) : (result >> 1));
      lng += deltaLng;

      points.add(RouteLocation(
        id: 'polyline_$pointIndex',
        name: 'Route Point',
        address: '',
        latitude: lat / 1E5,
        longitude: lng / 1E5,
      ));
      pointIndex++;
    }

    return points;
  }
}
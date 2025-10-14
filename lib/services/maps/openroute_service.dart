import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/utils/logger.dart';
import '../../core/models/route_model.dart';
import '../../core/config/env_config.dart';

/// OpenRouteService for free routing and directions
class OpenRouteService {
  static const String _tag = 'OpenRouteService';
  static const String _baseUrl = 'https://api.openrouteservice.org/v2';
  
  // Profile types for different travel modes
  static const Map<String, String> profiles = {
    'driving': 'driving-car',
    'walking': 'foot-walking',
    'cycling': 'cycling-regular',
    'wheelchair': 'wheelchair',
  };

  /// Get directions between two points - FREE up to 2000/day
  static Future<Map<String, dynamic>> getDirections({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
    String travelMode = 'driving',
    List<List<double>>? waypoints,
    bool avoidTolls = false,
    bool avoidHighways = false,
  }) async {
    try {
      AppLogger.debug(_tag, 'Getting directions from OpenRouteService');

      final profile = profiles[travelMode] ?? profiles['driving']!;
      final url = '$_baseUrl/directions/$profile';

      // Build coordinates array
      final coordinates = <List<double>>[
        [startLng, startLat], // ORS uses [lng, lat] format
      ];
      
      // Add waypoints if provided
      if (waypoints != null) {
        coordinates.addAll(waypoints);
      }
      
      coordinates.add([endLng, endLat]);

      // Build avoid options
      final avoid = <String>[];
      if (avoidTolls) avoid.add('tollways');
      if (avoidHighways) avoid.add('highways');

      final requestBody = {
        'coordinates': coordinates,
        'format': 'geojson',
        'instructions': true,
        'language': 'en',
        'geometry': true,
        'elevation': false,
        'extra_info': ['waytype', 'surface'],
        if (avoid.isNotEmpty) 'options': {'avoid_features': avoid},
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': EnvConfig.openRouteApiKey.isNotEmpty ? EnvConfig.openRouteApiKey : 'demo', // Use demo for testing
          'Content-Type': 'application/json',
          'User-Agent': 'ReLink Travel App',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseDirectionsResponse(data);
      } else {
        throw Exception('Failed to get directions: ${response.statusCode}');
      }

    } catch (e) {
      AppLogger.error(_tag, 'Failed to get directions', e);
      return _getEmptyDirectionsResponse();
    }
  }

  /// Parse OpenRouteService response to our format
  static Map<String, dynamic> _parseDirectionsResponse(Map<String, dynamic> data) {
    try {
      if (data['features'] == null || data['features'].isEmpty) {
        return _getEmptyDirectionsResponse();
      }

      final route = data['features'][0];
      final properties = route['properties'];
      final geometry = route['geometry'];
      final segments = properties['segments'] ?? [];

      // Extract total distance and duration
      final totalDistance = _formatDistance(properties['summary']['distance'].toDouble());
      final totalDuration = _formatDuration(properties['summary']['duration'].toDouble());

      // Extract route steps
      final steps = <RouteStep>[];
      for (final segment in segments) {
        final segmentSteps = segment['steps'] ?? [];
        for (final step in segmentSteps) {
          steps.add(RouteStep(
            instruction: step['instruction'] ?? '',
            distance: _formatDistance(step['distance'].toDouble()),
            duration: _formatDuration(step['duration'].toDouble()),
            startLocation: RouteLocation(
              id: 'step_${steps.length}',
              name: 'Step ${steps.length + 1}',
              address: '',
              latitude: 0.0, // Will be calculated from geometry
              longitude: 0.0,
            ),
            endLocation: RouteLocation(
              id: 'step_${steps.length}_end',
              name: 'Step ${steps.length + 1} End',
              address: '',
              latitude: 0.0,
              longitude: 0.0,
            ),
            polylinePoints: _extractPolylinePoints(geometry),
            maneuver: step['type']?.toString() ?? 'continue',
          ));
        }
      }

      return {
        'totalDistance': totalDistance,
        'totalDuration': totalDuration,
        'steps': steps,
        'polylinePoints': _extractPolylinePoints(geometry),
        'bbox': properties['summary']['bbox'] ?? [],
      };

    } catch (e) {
      AppLogger.error(_tag, 'Failed to parse directions response', e);
      return _getEmptyDirectionsResponse();
    }
  }

  /// Extract polyline points from GeoJSON geometry
  static List<RoutePoint> _extractPolylinePoints(Map<String, dynamic> geometry) {
    try {
      final coordinates = geometry['coordinates'] as List;
      return coordinates.map((coord) {
        return RoutePoint(
          latitude: coord[1].toDouble(),
          longitude: coord[0].toDouble(),
        );
      }).toList();
    } catch (e) {
      AppLogger.error(_tag, 'Failed to extract polyline points', e);
      return [];
    }
  }

  /// Format distance in meters to human readable string
  static String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }

  /// Format duration in seconds to human readable string
  static String _formatDuration(double seconds) {
    final minutes = (seconds / 60).round();
    if (minutes < 60) {
      return '$minutes min';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      return '${hours}h ${remainingMinutes}m';
    }
  }

  /// Get empty directions response for error cases
  static Map<String, dynamic> _getEmptyDirectionsResponse() {
    return {
      'totalDistance': '0 km',
      'totalDuration': '0 min',
      'steps': <RouteStep>[],
      'polylinePoints': <RoutePoint>[],
      'bbox': [],
    };
  }

  /// Get isochrone (reachability) data - FREE
  static Future<Map<String, dynamic>> getIsochrone({
    required double lat,
    required double lng,
    required int timeInSeconds,
    String travelMode = 'driving',
  }) async {
    try {
      AppLogger.debug(_tag, 'Getting isochrone data');

      final profile = profiles[travelMode] ?? profiles['driving']!;
      final url = '$_baseUrl/isochrones/$profile';

      final requestBody = {
        'locations': [[lng, lat]], // ORS uses [lng, lat] format
        'range': [timeInSeconds],
        'format': 'geojson',
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': EnvConfig.openRouteApiKey.isNotEmpty ? EnvConfig.openRouteApiKey : 'demo',
          'Content-Type': 'application/json',
          'User-Agent': 'ReLink Travel App',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get isochrone: ${response.statusCode}');
      }

    } catch (e) {
      AppLogger.error(_tag, 'Failed to get isochrone', e);
      return {};
    }
  }

  /// Get elevation data for a route - FREE
  static Future<List<double>> getElevationProfile({
    required List<RoutePoint> points,
  }) async {
    try {
      AppLogger.debug(_tag, 'Getting elevation profile');

      const url = '$_baseUrl/elevation/line';
      final coordinates = points.map((p) => [p.longitude, p.latitude]).toList();

      final requestBody = {
        'coordinates': coordinates,
        'format': 'geojson',
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': EnvConfig.openRouteApiKey.isNotEmpty ? EnvConfig.openRouteApiKey : 'demo',
          'Content-Type': 'application/json',
          'User-Agent': 'ReLink Travel App',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final coordinates = data['geometry']['coordinates'] as List;
        return coordinates.map((coord) => coord[2].toDouble()).toList();
      } else {
        throw Exception('Failed to get elevation: ${response.statusCode}');
      }

    } catch (e) {
      AppLogger.error(_tag, 'Failed to get elevation profile', e);
      return [];
    }
  }

  /// Check if API key is configured
  static bool get isConfigured => EnvConfig.hasOpenRouteConfig;

  /// Get API usage limits
  static Map<String, dynamic> getApiLimits() {
    return {
      'daily_requests': isConfigured ? 2000 : 2000, // Free tier limit
      'requests_per_minute': isConfigured ? 40 : 40,
      'cost': 0.0,
      'upgrade_url': 'https://openrouteservice.org/plans/',
    };
  }
}

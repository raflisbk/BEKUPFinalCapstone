import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/utils/logger.dart';
import '../../core/models/route_model.dart';
import '../../core/config/env_config.dart';

/// Mapbox Directions service for FREE routing - 100,000 requests per month
class MapboxDirectionsService {
  static const String _tag = 'MapboxDirectionsService';
  static const String _baseUrl = 'https://api.mapbox.com/directions/v5/mapbox';
  
  // Mapbox routing profiles
  static const Map<String, String> profiles = {
    'driving': 'driving',
    'walking': 'walking',
    'cycling': 'cycling',
    'driving-traffic': 'driving-traffic', // Real-time traffic
  };

  /// Get directions between two points - FREE up to 100,000/month
  static Future<Map<String, dynamic>> getDirections({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
    String travelMode = 'driving',
    List<List<double>>? waypoints,
    bool avoidTolls = false,
    bool avoidHighways = false,
    bool includeSteps = true,
    bool includeGeometry = true,
    String language = 'en',
  }) async {
    try {
      AppLogger.debug(_tag, 'Getting directions from Mapbox (FREE)');

      if (!isConfigured) {
        throw Exception('Mapbox access token not configured');
      }

      final profile = profiles[travelMode] ?? profiles['driving']!;
      
      // Build coordinates string: lng,lat format for Mapbox
      final coordinates = <String>[];
      coordinates.add('$startLng,$startLat');
      
      // Add waypoints if provided
      if (waypoints != null) {
        for (final waypoint in waypoints) {
          coordinates.add('${waypoint[0]},${waypoint[1]}'); // lng,lat
        }
      }
      
      coordinates.add('$endLng,$endLat');
      final coordinatesString = coordinates.join(';');

      // Build query parameters
      final params = <String, String>{
        'access_token': EnvConfig.mapboxPublicToken,
        'geometries': 'geojson',
        'language': language,
        'overview': 'full',
        'steps': includeSteps.toString(),
        'continue_straight': 'true',
      };

      // Add avoid parameters
      final exclude = <String>[];
      if (avoidTolls) exclude.add('toll');
      if (avoidHighways) exclude.add('motorway');
      if (exclude.isNotEmpty) {
        params['exclude'] = exclude.join(',');
      }

      // Build URL
      final uri = Uri.parse('$_baseUrl/$profile/$coordinatesString')
          .replace(queryParameters: params);

      AppLogger.debug(_tag, 'Mapbox request URL: ${uri.toString()}');

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseDirectionsResponse(data);
      } else {
        final error = json.decode(response.body);
        throw Exception('Mapbox Directions API error: ${error['message'] ?? response.statusCode}');
      }

    } catch (e) {
      AppLogger.error(_tag, 'Failed to get directions from Mapbox', e);
      return _getEmptyDirectionsResponse();
    }
  }

  /// Parse Mapbox Directions response
  static Map<String, dynamic> _parseDirectionsResponse(Map<String, dynamic> data) {
    try {
      if (data['routes'] == null || (data['routes'] as List).isEmpty) {
        return _getEmptyDirectionsResponse();
      }

      final route = data['routes'][0];
      final legs = route['legs'] as List? ?? [];

      // Extract total distance and duration
      final totalDistance = _formatDistance(route['distance']?.toDouble() ?? 0.0);
      final totalDuration = _formatDuration(route['duration']?.toDouble() ?? 0.0);

      // Extract route steps from all legs
      final steps = <RouteStep>[];
      for (final leg in legs) {
        final legSteps = leg['steps'] as List? ?? [];
        for (final step in legSteps) {
          steps.add(RouteStep(
            instruction: step['maneuver']['instruction'] ?? '',
            distance: _formatDistance(step['distance']?.toDouble() ?? 0.0),
            duration: _formatDuration(step['duration']?.toDouble() ?? 0.0),
            startLocation: RouteLocation(
              id: 'step_${steps.length}',
              name: 'Step ${steps.length + 1}',
              address: '',
              latitude: step['maneuver']['location'][1].toDouble(),
              longitude: step['maneuver']['location'][0].toDouble(),
            ),
            endLocation: RouteLocation(
              id: 'step_${steps.length}_end',
              name: 'Step ${steps.length + 1} End',
              address: '',
              latitude: step['maneuver']['location'][1].toDouble(),
              longitude: step['maneuver']['location'][0].toDouble(),
            ),
            polylinePoints: _extractPolylinePoints(step['geometry']),
            maneuver: step['maneuver']['type']?.toString() ?? 'continue',
          ));
        }
      }

      // Extract full route polyline
      final routePolyline = _extractPolylinePoints(route['geometry']);

      return {
        'totalDistance': totalDistance,
        'totalDuration': totalDuration,
        'steps': steps,
        'polylinePoints': routePolyline,
        'bbox': route['bbox'] ?? [],
        'metadata': {
          'weight': route['weight'],
          'weight_name': route['weight_name'],
          'confidence': route['confidence'],
        },
      };

    } catch (e) {
      AppLogger.error(_tag, 'Failed to parse Mapbox directions response', e);
      return _getEmptyDirectionsResponse();
    }
  }

  /// Extract polyline points from GeoJSON geometry
  static List<RoutePoint> _extractPolylinePoints(Map<String, dynamic>? geometry) {
    try {
      if (geometry == null || geometry['coordinates'] == null) return [];
      
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

  /// Get route matrix for multiple origins/destinations - FREE 25,000/month
  static Future<Map<String, dynamic>> getMatrix({
    required List<List<double>> coordinates, // [[lng, lat], ...]
    String profile = 'driving',
    List<int>? sources,
    List<int>? destinations,
  }) async {
    try {
      AppLogger.debug(_tag, 'Getting route matrix from Mapbox');

      if (!isConfigured) {
        throw Exception('Mapbox access token not configured');
      }

      final coordinatesString = coordinates
          .map((coord) => '${coord[0]},${coord[1]}') // lng,lat
          .join(';');

      final params = <String, String>{
        'access_token': EnvConfig.mapboxPublicToken,
      };

      if (sources != null) params['sources'] = sources.join(';');
      if (destinations != null) params['destinations'] = destinations.join(';');

      final uri = Uri.parse('https://api.mapbox.com/directions-matrix/v1/mapbox/$profile/$coordinatesString')
          .replace(queryParameters: params);

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Matrix API error: ${response.statusCode}');
      }

    } catch (e) {
      AppLogger.error(_tag, 'Failed to get route matrix', e);
      return {};
    }
  }

  /// Get isochrone (reachability) data - FREE 25,000/month
  static Future<Map<String, dynamic>> getIsochrone({
    required double lat,
    required double lng,
    required List<int> contours, // Time in minutes
    String profile = 'driving',
  }) async {
    try {
      AppLogger.debug(_tag, 'Getting isochrone from Mapbox');

      if (!isConfigured) {
        throw Exception('Mapbox access token not configured');
      }

      final params = {
        'contours_minutes': contours.join(','),
        'polygons': 'true',
        'access_token': EnvConfig.mapboxPublicToken,
      };

      final uri = Uri.parse('https://api.mapbox.com/isochrone/v1/mapbox/$profile/$lng,$lat')
          .replace(queryParameters: params);

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Isochrone API error: ${response.statusCode}');
      }

    } catch (e) {
      AppLogger.error(_tag, 'Failed to get isochrone', e);
      return {};
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
      'metadata': {},
    };
  }

  /// Check if access token is configured
  static bool get isConfigured => EnvConfig.hasMapboxConfig;

  /// Get API usage limits
  static Map<String, dynamic> getApiLimits() {
    return {
      'directions': 100000, // per month
      'isochrone': 25000, // per month
      'matrix': 25000, // per month
      'cost_after_limit': 0.50, // per 1000 requests
      'upgrade_url': 'https://account.mapbox.com/pricing/',
      'note': 'Very generous free tier with professional features',
    };
  }

  /// Get supported routing profiles
  static List<String> getSupportedProfiles() {
    return profiles.keys.toList();
  }

  /// Validate coordinates
  static bool isValidCoordinate(double lat, double lng) {
    return lat >= -85.0511 && lat <= 85.0511 && lng >= -180 && lng <= 180;
  }
}

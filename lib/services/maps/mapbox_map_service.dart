import 'dart:math' as math;
import '../../core/utils/logger.dart';
import '../../core/config/env_config.dart';

/// Mapbox Maps service for displaying maps with FREE 50,000 map loads per month
class MapboxMapService {
  static const String _tag = 'MapboxMapService';
  
  // Mapbox Style URLs (all FREE to use)
  static const Map<String, String> styleUrls = {
    'streets': 'mapbox://styles/mapbox/streets-v12',
    'outdoors': 'mapbox://styles/mapbox/outdoors-v12',
    'light': 'mapbox://styles/mapbox/light-v11',
    'dark': 'mapbox://styles/mapbox/dark-v11',
    'satellite': 'mapbox://styles/mapbox/satellite-v9',
    'satellite_streets': 'mapbox://styles/mapbox/satellite-streets-v12',
    'navigation_day': 'mapbox://styles/mapbox/navigation-day-v1',
    'navigation_night': 'mapbox://styles/mapbox/navigation-night-v1',
  };

  /// Get Mapbox access token - FREE up to 50,000 map loads/month
  static String get accessToken {
    final token = EnvConfig.mapboxPublicToken;
    if (token.isEmpty) {
      AppLogger.warning(_tag, 'Mapbox access token not configured! Check your .env file');
      return 'demo_token'; // Fallback for testing
    }
    return token;
  }

  /// Get style URL for different map types
  static String getStyleUrl(String style) {
    return styleUrls[style] ?? styleUrls['streets']!;
  }

  /// Get all available map styles
  static List<MapStyle> getAvailableStyles() {
    return [
      const MapStyle(id: 'streets', name: 'Streets', description: 'Clear street map for navigation'),
      const MapStyle(id: 'outdoors', name: 'Outdoors', description: 'Perfect for hiking and outdoor activities'),
      const MapStyle(id: 'light', name: 'Light', description: 'Clean, minimal design'),
      const MapStyle(id: 'dark', name: 'Dark', description: 'Dark theme for night use'),
      const MapStyle(id: 'satellite', name: 'Satellite', description: 'High-resolution satellite imagery'),
      const MapStyle(id: 'satellite_streets', name: 'Satellite Streets', description: 'Satellite with street labels'),
      const MapStyle(id: 'navigation_day', name: 'Navigation Day', description: 'Optimized for turn-by-turn navigation'),
      const MapStyle(id: 'navigation_night', name: 'Navigation Night', description: 'Night mode navigation'),
    ];
  }

  /// Get static map image URL - FREE up to 50,000 requests/month
  static String getStaticMapUrl({
    required double lat,
    required double lng,
    required int zoom,
    int width = 300,
    int height = 200,
    String style = 'streets',
    List<MapMarker>? markers,
    String? overlay,
  }) {
    try {
      final baseUrl = 'https://api.mapbox.com/styles/v1/mapbox/${style.replaceAll('mapbox://styles/mapbox/', '')}';
      
      // Add markers if provided
      String markerString = '';
      if (markers != null && markers.isNotEmpty) {
        final markerParams = markers.map((marker) {
          return 'pin-s-${marker.color}+${marker.icon}(${marker.lng},${marker.lat})';
        }).join(',');
        markerString = '/$markerParams';
      }

      // Add overlay (polyline) if provided
      String overlayString = '';
      if (overlay != null && overlay.isNotEmpty) {
        overlayString = '/path($overlay)';
      }

      return '$baseUrl/static$markerString$overlayString/$lng,$lat,$zoom/${width}x$height@2x'
             '?access_token=$accessToken';

    } catch (e) {
      AppLogger.error(_tag, 'Failed to generate static map URL', e);
      return '';
    }
  }

  /// Get Mapbox tile URL for custom tile layer - FREE
  static String getTileUrl(String style) {
    return 'https://api.mapbox.com/styles/v1/mapbox/$style/tiles/{z}/{x}/{y}@2x'
           '?access_token=$accessToken';
  }

  /// Check if access token is configured
  static bool get isConfigured => EnvConfig.hasMapboxConfig;

  /// Get usage limits for free tier
  static Map<String, dynamic> getUsageLimits() {
    return {
      'map_loads': 50000, // per month
      'static_images': 50000, // per month
      'cost_after_limit': 0.50, // per 1000 requests
      'upgrade_url': 'https://account.mapbox.com/pricing/',
      'note': 'Very generous free tier - perfect for most applications',
    };
  }

  /// Validate coordinates
  static bool isValidCoordinate(double lat, double lng) {
    return lat >= -85.0511 && lat <= 85.0511 && lng >= -180 && lng <= 180;
  }

  /// Calculate distance between two points using Haversine formula
  static double calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371; // km
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLng = _degreesToRadians(lng2 - lng1);
    
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
        sin(dLng / 2) * sin(dLng / 2);
    
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  /// Convert degrees to radians
  static double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

  /// Import required math functions
  static double sin(double x) => math.sin(x);
  static double cos(double x) => math.cos(x);
  static double sqrt(double x) => math.sqrt(x);
  static double atan2(double y, double x) => math.atan2(y, x);
  static double get pi => math.pi;
}

/// Map style configuration
class MapStyle {
  final String id;
  final String name;
  final String description;

  const MapStyle({
    required this.id,
    required this.name,
    required this.description,
  });
}

/// Marker for static maps
class MapMarker {
  final double lat;
  final double lng;
  final String color;
  final String icon;

  const MapMarker({
    required this.lat,
    required this.lng,
    this.color = 'red',
    this.icon = 'marker',
  });
}


import 'dart:math';
import '../../core/utils/logger.dart';

/// OpenStreetMap service for free map tiles and basic map functionality
class OpenStreetMapService {
  static const String _tag = 'OpenStreetMapService';
  
  // OpenStreetMap tile servers
  static const String tileUrl = 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const List<String> subdomains = ['a', 'b', 'c'];
  
  // Alternative tile servers for different styles
  static const Map<String, String> tileUrls = {
    'standard': 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
    'humanitarian': 'https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
    'cycle': 'https://{s}.tile-cyclosm.openstreetmap.fr/cyclosm/{z}/{x}/{y}.png',
    'transport': 'https://{s}.tile.thunderforest.com/transport/{z}/{x}/{y}.png',
  };

  /// Get tile URL for map display - completely FREE
  static String getTileUrl(int z, int x, int y, {String style = 'standard'}) {
    try {
      final baseUrl = tileUrls[style] ?? tileUrls['standard']!;
      final subdomain = subdomains[Random().nextInt(subdomains.length)];
      
      return baseUrl
          .replaceAll('{s}', subdomain)
          .replaceAll('{z}', z.toString())
          .replaceAll('{x}', x.toString())
          .replaceAll('{y}', y.toString());
      
    } catch (e) {
      AppLogger.error(_tag, 'Failed to generate tile URL', e);
      return tileUrls['standard']!
          .replaceAll('{s}', 'a')
          .replaceAll('{z}', z.toString())
          .replaceAll('{x}', x.toString())
          .replaceAll('{y}', y.toString());
    }
  }

  /// Get user-agent string for OSM requests
  static String getUserAgent() {
    return 'ReLink Travel App (contact@relink.com)';
  }

  /// Calculate distance between two points using Haversine formula
  static double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // km
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);
    
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  /// Convert degrees to radians
  static double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

  /// Get available map styles
  static List<String> getAvailableStyles() {
    return tileUrls.keys.toList();
  }

  /// Get attribution text for OpenStreetMap
  static String getAttribution() {
    return '© OpenStreetMap contributors';
  }

  /// Get tile size (standard is 256x256)
  static int getTileSize() {
    return 256;
  }

  /// Get maximum zoom level
  static int getMaxZoom() {
    return 19;
  }

  /// Get minimum zoom level
  static int getMinZoom() {
    return 1;
  }
}

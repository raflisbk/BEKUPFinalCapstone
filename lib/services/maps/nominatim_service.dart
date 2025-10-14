import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/utils/logger.dart';
import '../../core/models/route_model.dart';

/// Nominatim service for free geocoding using OpenStreetMap data
class NominatimService {
  static const String _tag = 'NominatimService';
  static const String _baseUrl = 'https://nominatim.openstreetmap.org';
  
  /// Search for places by text query - completely FREE
  static Future<List<RouteLocation>> searchPlaces(String query, {
    int limit = 5,
    String countryCode = '',
    String language = 'en',
  }) async {
    try {
      AppLogger.debug(_tag, 'Searching places: $query');

      final params = {
        'q': query,
        'format': 'json',
        'limit': limit.toString(),
        'addressdetails': '1',
        'extratags': '1',
        'namedetails': '1',
        'accept-language': language,
        if (countryCode.isNotEmpty) 'countrycodes': countryCode,
      };

      final uri = Uri.parse('$_baseUrl/search').replace(queryParameters: params);
      
      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'ReLink Travel App (contact@relink.com)',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> results = json.decode(response.body);
        return results.map((e) => _parseSearchResult(e as Map<String, dynamic>)).toList();
      } else {
        throw Exception('Search failed: ${response.statusCode}');
      }

    } catch (e) {
      AppLogger.error(_tag, 'Failed to search places', e);
      return [];
    }
  }

  /// Reverse geocoding - get place from coordinates - completely FREE
  static Future<RouteLocation?> reverseGeocode(double lat, double lon, {
    String language = 'en',
    bool includeAddress = true,
  }) async {
    try {
      AppLogger.debug(_tag, 'Reverse geocoding: $lat, $lon');

      final params = {
        'lat': lat.toString(),
        'lon': lon.toString(),
        'format': 'json',
        'zoom': '18',
        'addressdetails': includeAddress ? '1' : '0',
        'extratags': '1',
        'namedetails': '1',
        'accept-language': language,
      };

      final uri = Uri.parse('$_baseUrl/reverse').replace(queryParameters: params);
      
      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'ReLink Travel App (contact@relink.com)',
        },
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        return _parseReverseResult(result);
      } else {
        throw Exception('Reverse geocoding failed: ${response.statusCode}');
      }

    } catch (e) {
      AppLogger.error(_tag, 'Failed to reverse geocode', e);
      return null;
    }
  }

  /// Search for addresses with structured query - FREE
  static Future<List<RouteLocation>> searchStructured({
    String? street,
    String? city,
    String? county,
    String? state,
    String? country,
    String? postalCode,
    int limit = 5,
    String language = 'en',
  }) async {
    try {
      AppLogger.debug(_tag, 'Structured address search');

      final params = <String, String>{
        'format': 'json',
        'limit': limit.toString(),
        'addressdetails': '1',
        'extratags': '1',
        'namedetails': '1',
        'accept-language': language,
      };

      if (street != null) params['street'] = street;
      if (city != null) params['city'] = city;
      if (county != null) params['county'] = county;
      if (state != null) params['state'] = state;
      if (country != null) params['country'] = country;
      if (postalCode != null) params['postalcode'] = postalCode;

      final uri = Uri.parse('$_baseUrl/search').replace(queryParameters: params);
      
      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'ReLink Travel App (contact@relink.com)',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> results = json.decode(response.body);
        return results.map((e) => _parseSearchResult(e as Map<String, dynamic>)).toList();
      } else {
        throw Exception('Structured search failed: ${response.statusCode}');
      }

    } catch (e) {
      AppLogger.error(_tag, 'Failed to perform structured search', e);
      return [];
    }
  }

  /// Parse search result to RouteLocation
  static RouteLocation _parseSearchResult(Map<String, dynamic> result) {
    final address = result['address'] as Map<String, dynamic>? ?? {};
    final displayName = result['display_name'] as String? ?? '';
    
    // Extract name from various possible fields
    String name = result['name'] as String? ?? '';
    if (name.isEmpty) {
      name = address['amenity'] as String? ?? 
             address['shop'] as String? ?? 
             address['tourism'] as String? ?? 
             address['building'] as String? ?? 
             _extractFirstPartOfDisplayName(displayName);
    }

    // Build formatted address
    final addressParts = <String>[];
    if (address['house_number'] != null) addressParts.add(address['house_number']);
    if (address['road'] != null) addressParts.add(address['road']);
    if (address['city'] != null) addressParts.add(address['city']);
    if (address['state'] != null) addressParts.add(address['state']);
    if (address['country'] != null) addressParts.add(address['country']);
    
    final formattedAddress = addressParts.isNotEmpty ? addressParts.join(', ') : displayName;

    return RouteLocation(
      id: 'nominatim_${result['osm_id'] ?? DateTime.now().millisecondsSinceEpoch}',
      name: name,
      address: formattedAddress,
      latitude: double.parse(result['lat'].toString()),
      longitude: double.parse(result['lon'].toString()),
      additionalInfo: {
        'category': result['category'] as String?,
        'type': result['type'] as String?,
        'importance': result['importance']?.toDouble(),
        'boundingBox': _parseBoundingBox(result['boundingbox']),
      },
    );
  }

  /// Parse reverse geocoding result
  static RouteLocation _parseReverseResult(Map<String, dynamic> result) {
    final address = result['address'] as Map<String, dynamic>? ?? {};
    final displayName = result['display_name'] as String? ?? '';
    
    // Extract name from various possible fields
    String name = result['name'] as String? ?? '';
    if (name.isEmpty) {
      name = address['amenity'] as String? ?? 
             address['shop'] as String? ?? 
             address['tourism'] as String? ?? 
             address['building'] as String? ?? 
             _extractFirstPartOfDisplayName(displayName);
    }

    // Build formatted address
    final addressParts = <String>[];
    if (address['house_number'] != null) addressParts.add(address['house_number']);
    if (address['road'] != null) addressParts.add(address['road']);
    if (address['city'] != null) addressParts.add(address['city']);
    if (address['state'] != null) addressParts.add(address['state']);
    if (address['country'] != null) addressParts.add(address['country']);
    
    final formattedAddress = addressParts.isNotEmpty ? addressParts.join(', ') : displayName;

    return RouteLocation(
      id: 'nominatim_reverse_${result['osm_id'] ?? DateTime.now().millisecondsSinceEpoch}',
      name: name,
      address: formattedAddress,
      latitude: double.parse(result['lat'].toString()),
      longitude: double.parse(result['lon'].toString()),
      additionalInfo: {
        'category': result['category'] as String?,
        'type': result['type'] as String?,
        'importance': result['importance']?.toDouble(),
      },
    );
  }

  /// Extract first part of display name as fallback name
  static String _extractFirstPartOfDisplayName(String displayName) {
    if (displayName.isEmpty) return 'Unknown Location';
    final parts = displayName.split(',');
    return parts.first.trim();
  }

  /// Parse bounding box
  static List<double>? _parseBoundingBox(dynamic bbox) {
    if (bbox is List && bbox.length == 4) {
      try {
        return bbox.map((e) => double.parse(e.toString())).toList();
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Get place details by OSM ID - FREE
  static Future<RouteLocation?> getPlaceDetails(String osmId, String osmType) async {
    try {
      AppLogger.debug(_tag, 'Getting place details: $osmType/$osmId');

      final params = {
        'osm_type': osmType.toUpperCase(),
        'osm_id': osmId,
        'format': 'json',
        'addressdetails': '1',
        'extratags': '1',
        'namedetails': '1',
      };

      final uri = Uri.parse('$_baseUrl/details').replace(queryParameters: params);
      
      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'ReLink Travel App (contact@relink.com)',
        },
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        return _parseSearchResult(result);
      } else {
        throw Exception('Details request failed: ${response.statusCode}');
      }

    } catch (e) {
      AppLogger.error(_tag, 'Failed to get place details', e);
      return null;
    }
  }

  /// Get geocoding usage information
  static Map<String, dynamic> getUsageInfo() {
    return {
      'daily_requests': 'Unlimited (fair use policy)',
      'requests_per_second': 1,
      'cost': 0.0,
      'terms_url': 'https://operations.osmfoundation.org/policies/nominatim/',
      'note': 'Please respect fair use policy - max 1 request per second',
    };
  }

  /// Check if coordinates are valid
  static bool isValidCoordinate(double lat, double lon) {
    return lat >= -90 && lat <= 90 && lon >= -180 && lon <= 180;
  }
}

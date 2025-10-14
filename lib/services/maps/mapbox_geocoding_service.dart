import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/utils/logger.dart';
import '../../core/models/route_model.dart';
import '../../core/config/env_config.dart';

/// Mapbox Geocoding service with FREE 100,000 requests per month
class MapboxGeocodingService {
  static const String _tag = 'MapboxGeocodingService';
  static const String _baseUrl = 'https://api.mapbox.com/geocoding/v5';

  /// Forward geocoding - search places by text - FREE up to 100,000/month
  static Future<List<RouteLocation>> searchPlaces(String query, {
    int limit = 5,
    String? country,
    String? proximity, // 'lng,lat' format
    List<String>? types, // poi, address, etc.
    String language = 'en',
    bool autocomplete = true,
  }) async {
    try {
      AppLogger.debug(_tag, 'Searching places: $query');

      if (!isConfigured) {
        throw Exception('Mapbox access token not configured');
      }

      if (query.trim().isEmpty) {
        return [];
      }

      final params = <String, String>{
        'access_token': EnvConfig.mapboxPublicToken,
        'limit': limit.toString(),
        'language': language,
      };

      if (country != null) params['country'] = country;
      if (proximity != null) params['proximity'] = proximity;
      if (types != null && types.isNotEmpty) params['types'] = types.join(',');
      if (autocomplete) params['autocomplete'] = 'true';

      final encodedQuery = Uri.encodeComponent(query);
      final uri = Uri.parse('$_baseUrl/mapbox.places/$encodedQuery.json')
          .replace(queryParameters: params);

      AppLogger.debug(_tag, 'Mapbox geocoding URL: ${uri.toString()}');

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseGeocodingResponse(data);
      } else {
        final error = json.decode(response.body);
        throw Exception('Mapbox Geocoding API error: ${error['message'] ?? response.statusCode}');
      }

    } catch (e) {
      AppLogger.error(_tag, 'Failed to search places', e);
      return [];
    }
  }

  /// Reverse geocoding - get place from coordinates - FREE up to 100,000/month
  static Future<RouteLocation?> reverseGeocode(double lat, double lng, {
    List<String>? types,
    String language = 'en',
  }) async {
    try {
      AppLogger.debug(_tag, 'Reverse geocoding: $lat, $lng');

      if (!isConfigured) {
        throw Exception('Mapbox access token not configured');
      }

      final params = <String, String>{
        'access_token': EnvConfig.mapboxPublicToken,
        'language': language,
      };

      if (types != null && types.isNotEmpty) params['types'] = types.join(',');

      final uri = Uri.parse('$_baseUrl/mapbox.places/$lng,$lat.json')
          .replace(queryParameters: params);

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = _parseGeocodingResponse(data);
        return results.isNotEmpty ? results.first : null;
      } else {
        final error = json.decode(response.body);
        throw Exception('Mapbox Reverse Geocoding API error: ${error['message'] ?? response.statusCode}');
      }

    } catch (e) {
      AppLogger.error(_tag, 'Failed to reverse geocode', e);
      return null;
    }
  }

  /// Search for addresses with structured query
  static Future<List<RouteLocation>> searchAddresses({
    String? address,
    String? city,
    String? region,
    String? country,
    String? postcode,
    int limit = 5,
    String language = 'en',
  }) async {
    try {
      final queryParts = <String>[];
      if (address != null && address.isNotEmpty) queryParts.add(address);
      if (city != null && city.isNotEmpty) queryParts.add(city);
      if (region != null && region.isNotEmpty) queryParts.add(region);
      if (country != null && country.isNotEmpty) queryParts.add(country);
      if (postcode != null && postcode.isNotEmpty) queryParts.add(postcode);

      if (queryParts.isEmpty) return [];

      final query = queryParts.join(', ');
      return searchPlaces(
        query,
        limit: limit,
        country: country,
        types: ['address'],
        language: language,
      );

    } catch (e) {
      AppLogger.error(_tag, 'Failed to search structured addresses', e);
      return [];
    }
  }

  /// Search for points of interest (POI)
  static Future<List<RouteLocation>> searchPOI({
    required String category, // restaurant, gas_station, hospital, etc.
    required double lat,
    required double lng,
    double radius = 2000, // meters
    int limit = 20,
    String language = 'en',
  }) async {
    try {
      AppLogger.debug(_tag, 'Searching POI: $category near $lat,$lng');

      return searchPlaces(
        category,
        limit: limit,
        proximity: '$lng,$lat',
        types: ['poi'],
        language: language,
      );

    } catch (e) {
      AppLogger.error(_tag, 'Failed to search POI', e);
      return [];
    }
  }

  /// Parse Mapbox geocoding response
  static List<RouteLocation> _parseGeocodingResponse(Map<String, dynamic> data) {
    try {
      final features = data['features'] as List? ?? [];
      final locations = <RouteLocation>[];

      for (final feature in features) {
        final geometry = feature['geometry'] as Map<String, dynamic>? ?? {};
        final properties = feature['properties'] as Map<String, dynamic>? ?? {};
        final context = feature['context'] as List? ?? [];
        
        final coordinates = geometry['coordinates'] as List? ?? [];
        if (coordinates.length < 2) continue;

        final lng = coordinates[0].toDouble();
        final lat = coordinates[1].toDouble();

        // Extract place name
        final placeName = feature['place_name'] as String? ?? '';
        final text = feature['text'] as String? ?? '';
        final name = text.isNotEmpty ? text : _extractNameFromPlaceName(placeName);

        // Extract address components from context
        final addressComponents = _parseAddressContext(context);
        
        // Create location
        final location = RouteLocation(
          id: feature['id'] as String? ?? 'mapbox_${DateTime.now().millisecondsSinceEpoch}',
          name: name,
          address: placeName,
          latitude: lat,
          longitude: lng,
          category: _extractCategory(feature),
          type: feature['place_type']?.toString(),
          phone: properties['phone'] as String?,
          website: properties['website'] as String?,
          metadata: {
            'mapbox_id': feature['id'],
            'relevance': feature['relevance'],
            'place_type': feature['place_type'],
            'bbox': feature['bbox'],
            'address_components': addressComponents,
            'properties': properties,
          },
        );

        locations.add(location);
      }

      return locations;

    } catch (e) {
      AppLogger.error(_tag, 'Failed to parse geocoding response', e);
      return [];
    }
  }

  /// Extract category from feature
  static String? _extractCategory(Map<String, dynamic> feature) {
    final placeType = feature['place_type'] as List? ?? [];
    if (placeType.isNotEmpty) {
      return placeType.first.toString();
    }
    return null;
  }

  /// Extract name from place_name
  static String _extractNameFromPlaceName(String placeName) {
    if (placeName.isEmpty) return 'Unknown Location';
    final parts = placeName.split(',');
    return parts.first.trim();
  }

  /// Parse address context
  static Map<String, String> _parseAddressContext(List context) {
    final components = <String, String>{};
    
    for (final item in context) {
      if (item is Map<String, dynamic>) {
        final id = item['id'] as String? ?? '';
        final text = item['text'] as String? ?? '';
        
        if (id.startsWith('country.')) {
          components['country'] = text;
        } else if (id.startsWith('region.')) {
          components['region'] = text;
        } else if (id.startsWith('place.')) {
          components['city'] = text;
        } else if (id.startsWith('postcode.')) {
          components['postcode'] = text;
        } else if (id.startsWith('district.')) {
          components['district'] = text;
        } else if (id.startsWith('locality.')) {
          components['locality'] = text;
        }
      }
    }
    
    return components;
  }

  /// Get supported POI categories
  static List<String> getSupportedPOICategories() {
    return [
      'restaurant',
      'cafe',
      'bar',
      'hotel',
      'hospital',
      'pharmacy',
      'gas_station',
      'bank',
      'atm',
      'shopping_mall',
      'grocery_store',
      'school',
      'university',
      'library',
      'museum',
      'park',
      'gym',
      'beauty_salon',
      'car_repair',
      'police',
      'fire_station',
      'post_office',
    ];
  }

  /// Get supported place types
  static List<String> getSupportedPlaceTypes() {
    return [
      'country',
      'region',
      'postcode',
      'district',
      'place',
      'locality',
      'neighborhood',
      'address',
      'poi',
    ];
  }

  /// Check if access token is configured
  static bool get isConfigured => EnvConfig.hasMapboxConfig;

  /// Get API usage limits
  static Map<String, dynamic> getApiLimits() {
    return {
      'geocoding_requests': 100000, // per month
      'cost_after_limit': 0.50, // per 1000 requests
      'temporary_geocoding': 'unlimited', // For search-as-you-type
      'permanent_geocoding': 'counted', // For storing results
      'upgrade_url': 'https://account.mapbox.com/pricing/',
      'note': 'Generous free tier with professional geocoding features',
    };
  }

  /// Validate coordinates
  static bool isValidCoordinate(double lat, double lng) {
    return lat >= -85.0511 && lat <= 85.0511 && lng >= -180 && lng <= 180;
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/utils/logger.dart';
import '../../core/models/route_model.dart';

/// Overpass API service for finding places and points of interest using OpenStreetMap data
class OverpassService {
  static const String _tag = 'OverpassService';
  static const String _baseUrl = 'https://overpass-api.de/api/interpreter';
  
  // Alternative Overpass API servers for load balancing
  static const List<String> _servers = [
    'https://overpass-api.de/api/interpreter',
    'https://overpass.kumi.systems/api/interpreter',
    'https://overpass.openstreetmap.ru/api/interpreter',
  ];

  /// Find nearby places by amenity type - completely FREE
  static Future<List<RouteLocation>> findNearbyPlaces({
    required double lat,
    required double lon,
    required String amenity,
    double radius = 2000,
    int limit = 20,
  }) async {
    try {
      AppLogger.debug(_tag, 'Finding nearby $amenity within ${radius}m of $lat,$lon');

      final query = '''
        [out:json][timeout:25];
        (
          node["amenity"="$amenity"](around:$radius,$lat,$lon);
          way["amenity"="$amenity"](around:$radius,$lat,$lon);
          relation["amenity"="$amenity"](around:$radius,$lat,$lon);
        );
        out center meta $limit;
      ''';

      final response = await _executeQuery(query);
      return _parseOverpassResponse(response, 'amenity', amenity);

    } catch (e) {
      AppLogger.error(_tag, 'Failed to find nearby places', e);
      return [];
    }
  }

  /// Find places by category (shop, tourism, etc.) - FREE
  static Future<List<RouteLocation>> findPlacesByCategory({
    required double lat,
    required double lon,
    required String category,
    String? subcategory,
    double radius = 2000,
    int limit = 20,
  }) async {
    try {
      AppLogger.debug(_tag, 'Finding $category places within ${radius}m');

      String filter = '';
      if (subcategory != null) {
        filter = '["$category"="$subcategory"]';
      } else {
        filter = '["$category"]';
      }

      final query = '''
        [out:json][timeout:25];
        (
          node$filter(around:$radius,$lat,$lon);
          way$filter(around:$radius,$lat,$lon);
          relation$filter(around:$radius,$lat,$lon);
        );
        out center meta $limit;
      ''';

      final response = await _executeQuery(query);
      return _parseOverpassResponse(response, category, subcategory);

    } catch (e) {
      AppLogger.error(_tag, 'Failed to find places by category', e);
      return [];
    }
  }

  /// Find restaurants with cuisine type - FREE
  static Future<List<RouteLocation>> findRestaurants({
    required double lat,
    required double lon,
    String? cuisine,
    double radius = 2000,
    int limit = 20,
  }) async {
    try {
      AppLogger.debug(_tag, 'Finding restaurants${cuisine != null ? ' with $cuisine cuisine' : ''} within ${radius}m');

      String filter = '["amenity"="restaurant"]';
      if (cuisine != null) {
        filter += '["cuisine"~"$cuisine",i]';
      }

      final query = '''
        [out:json][timeout:25];
        (
          node$filter(around:$radius,$lat,$lon);
          way$filter(around:$radius,$lat,$lon);
          relation$filter(around:$radius,$lat,$lon);
        );
        out center meta $limit;
      ''';

      final response = await _executeQuery(query);
      return _parseOverpassResponse(response, 'amenity', 'restaurant');

    } catch (e) {
      AppLogger.error(_tag, 'Failed to find restaurants', e);
      return [];
    }
  }

  /// Find gas stations - FREE
  static Future<List<RouteLocation>> findGasStations({
    required double lat,
    required double lon,
    double radius = 5000,
    int limit = 20,
  }) async {
    return findNearbyPlaces(
      lat: lat,
      lon: lon,
      amenity: 'fuel',
      radius: radius,
      limit: limit,
    );
  }

  /// Find hospitals - FREE
  static Future<List<RouteLocation>> findHospitals({
    required double lat,
    required double lon,
    double radius = 10000,
    int limit = 10,
  }) async {
    return findNearbyPlaces(
      lat: lat,
      lon: lon,
      amenity: 'hospital',
      radius: radius,
      limit: limit,
    );
  }

  /// Find tourist attractions - FREE
  static Future<List<RouteLocation>> findTouristAttractions({
    required double lat,
    required double lon,
    double radius = 5000,
    int limit = 20,
  }) async {
    return findPlacesByCategory(
      lat: lat,
      lon: lon,
      category: 'tourism',
      radius: radius,
      limit: limit,
    );
  }

  /// Find hotels and accommodations - FREE
  static Future<List<RouteLocation>> findAccommodations({
    required double lat,
    required double lon,
    double radius = 5000,
    int limit = 20,
  }) async {
    try {
      AppLogger.debug(_tag, 'Finding accommodations within ${radius}m');

      final query = '''
        [out:json][timeout:25];
        (
          node["tourism"~"^(hotel|motel|guesthouse|hostel|apartment)"][name](around:$radius,$lat,$lon);
          way["tourism"~"^(hotel|motel|guesthouse|hostel|apartment)"][name](around:$radius,$lat,$lon);
          relation["tourism"~"^(hotel|motel|guesthouse|hostel|apartment)"][name](around:$radius,$lat,$lon);
        );
        out center meta $limit;
      ''';

      final response = await _executeQuery(query);
      return _parseOverpassResponse(response, 'tourism', 'accommodation');

    } catch (e) {
      AppLogger.error(_tag, 'Failed to find accommodations', e);
      return [];
    }
  }

  /// Execute Overpass query with fallback servers
  static Future<Map<String, dynamic>> _executeQuery(String query) async {
    for (int i = 0; i < _servers.length; i++) {
      try {
        final response = await http.post(
          Uri.parse(_servers[i]),
          headers: {
            'Content-Type': 'text/plain; charset=utf-8',
            'User-Agent': 'ReLink Travel App (contact@relink.com)',
          },
          body: query,
        ).timeout(const Duration(seconds: 30));

        if (response.statusCode == 200) {
          return json.decode(response.body);
        } else if (response.statusCode == 429) {
          // Rate limited, try next server
          AppLogger.warning(_tag, 'Rate limited on server ${i + 1}, trying next');
          continue;
        } else {
          throw Exception('Query failed: ${response.statusCode}');
        }
      } catch (e) {
        AppLogger.warning(_tag, 'Server ${i + 1} failed: $e');
        if (i == _servers.length - 1) {
          rethrow; // Last server, rethrow error
        }
      }
    }
    
    throw Exception('All Overpass servers failed');
  }

  /// Parse Overpass API response
  static List<RouteLocation> _parseOverpassResponse(
    Map<String, dynamic> response,
    String category,
    String? subcategory,
  ) {
    try {
      final elements = response['elements'] as List? ?? [];
      final locations = <RouteLocation>[];

      for (final element in elements) {
        final tags = element['tags'] as Map<String, dynamic>? ?? {};
        
        // Get coordinates
        double? lat, lon;
        if (element['lat'] != null && element['lon'] != null) {
          lat = element['lat'].toDouble();
          lon = element['lon'].toDouble();
        } else if (element['center'] != null) {
          lat = element['center']['lat'].toDouble();
          lon = element['center']['lon'].toDouble();
        } else {
          continue; // Skip if no coordinates
        }

        // Extract name
        String name = tags['name'] as String? ?? 
                     tags['brand'] as String? ?? 
                     tags[category] as String? ?? 
                     'Unknown';

        // Extract address
        final addressParts = <String>[];
        if (tags['addr:housenumber'] != null) addressParts.add(tags['addr:housenumber']);
        if (tags['addr:street'] != null) addressParts.add(tags['addr:street']);
        if (tags['addr:city'] != null) addressParts.add(tags['addr:city']);
        
        final address = addressParts.isNotEmpty ? addressParts.join(', ') : '';

        // Create location
        final location = RouteLocation(
          id: 'overpass_${element['type']}_${element['id']}',
          name: name,
          address: address,
          latitude: lat,
          longitude: lon,
          category: category,
          type: subcategory ?? tags[category]?.toString(),
          phone: tags['phone'] as String?,
          website: tags['website'] as String?,
          openingHours: tags['opening_hours'] as String?,
          rating: _parseRating(tags['stars']),
          metadata: {
            'osm_type': element['type'],
            'osm_id': element['id'],
            'cuisine': tags['cuisine'],
            'brand': tags['brand'],
            'operator': tags['operator'],
            'wheelchair': tags['wheelchair'],
            'internet_access': tags['internet_access'],
            'parking': tags['parking'],
            'outdoor_seating': tags['outdoor_seating'],
          },
        );

        locations.add(location);
      }

      // Sort by distance (assuming first coordinate is center)
      // This is approximate sorting, for exact distance calculation use Haversine formula
      locations.sort((a, b) {
        // Simple distance comparison - for exact implementation, use Haversine formula
        return 0; // Keep original order for now
      });

      return locations;

    } catch (e) {
      AppLogger.error(_tag, 'Failed to parse Overpass response', e);
      return [];
    }
  }

  /// Parse rating from stars tag
  static double? _parseRating(dynamic stars) {
    if (stars == null) return null;
    try {
      return double.parse(stars.toString());
    } catch (e) {
      return null;
    }
  }

  /// Get supported amenity types
  static List<String> getSupportedAmenities() {
    return [
      'restaurant',
      'cafe',
      'fast_food',
      'bar',
      'pub',
      'fuel',
      'hospital',
      'pharmacy',
      'bank',
      'atm',
      'post_office',
      'police',
      'fire_station',
      'parking',
      'toilet',
      'library',
      'school',
      'university',
      'place_of_worship',
      'cinema',
      'theatre',
      'marketplace',
      'shopping_mall',
    ];
  }

  /// Get supported tourism types
  static List<String> getSupportedTourismTypes() {
    return [
      'attraction',
      'museum',
      'gallery',
      'monument',
      'memorial',
      'artwork',
      'viewpoint',
      'zoo',
      'theme_park',
      'hotel',
      'motel',
      'guesthouse',
      'hostel',
      'apartment',
      'camp_site',
      'information',
    ];
  }

  /// Get API usage information
  static Map<String, dynamic> getUsageInfo() {
    return {
      'daily_requests': 'Unlimited (fair use policy)',
      'requests_per_minute': 'Limited by server capacity',
      'cost': 0.0,
      'servers': _servers.length,
      'timeout': '30 seconds per request',
      'note': 'Free service provided by OpenStreetMap Foundation',
    };
  }
}

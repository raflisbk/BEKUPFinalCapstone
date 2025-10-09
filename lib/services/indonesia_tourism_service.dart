import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/models/destination_model.dart';
import '../core/utils/logger.dart';
import '../core/config/env_config.dart';

/// Indonesian provinces for tourism
enum IndonesianProvince {
  bali,
  yogyakarta,
  jakarta,
  jawaBarat,
  jawaTimur,
  jawaTengah,
  sumateraUtara,
  sumateraBarat,
  sulawesiSelatan,
  ntb,
  ntt,
  kalimantan,
  papua,
}

/// Tourism categories in Indonesia
enum TourismCategory {
  beach,
  mountain,
  culture,
  culinary,
  nature,
  historical,
  religious,
  adventure,
  urban,
  rural,
}

/// Extension for province display names
extension IndonesianProvinceExt on IndonesianProvince {
  String get displayName {
    switch (this) {
      case IndonesianProvince.bali:
        return 'Bali';
      case IndonesianProvince.yogyakarta:
        return 'D.I. Yogyakarta';
      case IndonesianProvince.jakarta:
        return 'DKI Jakarta';
      case IndonesianProvince.jawaBarat:
        return 'Jawa Barat';
      case IndonesianProvince.jawaTimur:
        return 'Jawa Timur';
      case IndonesianProvince.jawaTengah:
        return 'Jawa Tengah';
      case IndonesianProvince.sumateraUtara:
        return 'Sumatera Utara';
      case IndonesianProvince.sumateraBarat:
        return 'Sumatera Barat';
      case IndonesianProvince.sulawesiSelatan:
        return 'Sulawesi Selatan';
      case IndonesianProvince.ntb:
        return 'Nusa Tenggara Barat';
      case IndonesianProvince.ntt:
        return 'Nusa Tenggara Timur';
      case IndonesianProvince.kalimantan:
        return 'Kalimantan';
      case IndonesianProvince.papua:
        return 'Papua';
    }
  }

  String get searchQuery {
    switch (this) {
      case IndonesianProvince.bali:
        return 'Bali, Indonesia';
      case IndonesianProvince.yogyakarta:
        return 'Yogyakarta, Indonesia';
      case IndonesianProvince.jakarta:
        return 'Jakarta, Indonesia';
      case IndonesianProvince.jawaBarat:
        return 'West Java, Indonesia';
      case IndonesianProvince.jawaTimur:
        return 'East Java, Indonesia';
      case IndonesianProvince.jawaTengah:
        return 'Central Java, Indonesia';
      case IndonesianProvince.sumateraUtara:
        return 'North Sumatra, Indonesia';
      case IndonesianProvince.sumateraBarat:
        return 'West Sumatra, Indonesia';
      case IndonesianProvince.sulawesiSelatan:
        return 'South Sulawesi, Indonesia';
      case IndonesianProvince.ntb:
        return 'Lombok, Indonesia';
      case IndonesianProvince.ntt:
        return 'Flores, Indonesia';
      case IndonesianProvince.kalimantan:
        return 'Kalimantan, Indonesia';
      case IndonesianProvince.papua:
        return 'Papua, Indonesia';
    }
  }
}

/// Extension for tourism categories
extension TourismCategoryExt on TourismCategory {
  String get displayName {
    switch (this) {
      case TourismCategory.beach:
        return 'Pantai';
      case TourismCategory.mountain:
        return 'Gunung';
      case TourismCategory.culture:
        return 'Budaya';
      case TourismCategory.culinary:
        return 'Kuliner';
      case TourismCategory.nature:
        return 'Alam';
      case TourismCategory.historical:
        return 'Sejarah';
      case TourismCategory.religious:
        return 'Religi';
      case TourismCategory.adventure:
        return 'Petualangan';
      case TourismCategory.urban:
        return 'Perkotaan';
      case TourismCategory.rural:
        return 'Pedesaan';
    }
  }

  String get placeType {
    switch (this) {
      case TourismCategory.beach:
        return 'beach';
      case TourismCategory.mountain:
        return 'mountain';
      case TourismCategory.culture:
        return 'museum';
      case TourismCategory.culinary:
        return 'restaurant';
      case TourismCategory.nature:
        return 'park';
      case TourismCategory.historical:
        return 'historical_landmark';
      case TourismCategory.religious:
        return 'place_of_worship';
      case TourismCategory.adventure:
        return 'tourist_attraction';
      case TourismCategory.urban:
        return 'shopping_mall';
      case TourismCategory.rural:
        return 'natural_feature';
    }
  }
}

/// Service for Indonesia Tourism data using Google Places API
class IndonesiaTourismService {
  static const String _tag = 'IndonesiaTourismService';

  late final String _apiKey = EnvConfig.googleMapsApiKey;

  static const String _placesApiBaseUrl = 'https://maps.googleapis.com/maps/api/place';

  /// Popular Indonesian tourist destinations curated list
  static final Map<String, List<Map<String, dynamic>>> _curatedDestinations = {
    'Bali': [
      {
        'name': 'Tanah Lot Temple',
        'description': 'Pura ikonik di atas batu karang di tepi laut, terkenal dengan sunset yang memukau',
        'category': 'religious',
        'placeId': 'ChIJoVqUSa4i0i0RwY7Ye7wGDuY',
      },
      {
        'name': 'Uluwatu Temple',
        'description': 'Pura megah di tepi tebing dengan pemandangan Samudra Hindia',
        'category': 'religious',
        'placeId': 'ChIJ_SqRPl1D0i0ROFPrw_BI4KU',
      },
      {
        'name': 'Tegallalang Rice Terrace',
        'description': 'Sawah terasering hijau yang menjadi ikon Ubud, Bali',
        'category': 'nature',
        'placeId': 'ChIJSe5hoa760i0RkG7Ye7wGDuY',
      },
      {
        'name': 'Kuta Beach',
        'description': 'Pantai terkenal dengan ombak yang cocok untuk surfing',
        'category': 'beach',
        'placeId': 'ChIJLa4sGkME0i0RMJPrw_BI4KU',
      },
      {
        'name': 'Mount Batur',
        'description': 'Gunung berapi aktif populer untuk pendakian sunrise',
        'category': 'mountain',
        'placeId': 'ChIJVy-I3S8Q0i0R4G7Ye7wGDuY',
      },
    ],
    'Yogyakarta': [
      {
        'name': 'Borobudur Temple',
        'description': 'Candi Buddha terbesar di dunia, warisan UNESCO',
        'category': 'historical',
        'placeId': 'ChIJvyaSi5nYi2kRJGr-Ys-CjgM',
      },
      {
        'name': 'Prambanan Temple',
        'description': 'Kompleks candi Hindu terbesar di Indonesia',
        'category': 'historical',
        'placeId': 'ChIJq7smVZbYi2kRoFPrw_BI4KU',
      },
      {
        'name': 'Malioboro Street',
        'description': 'Jalan legendaris pusat belanja dan kuliner Yogyakarta',
        'category': 'urban',
        'placeId': 'ChIJBwaBQMnYi2kR0G7Ye7wGDuY',
      },
      {
        'name': 'Taman Sari Water Castle',
        'description': 'Bekas taman istana Kesultanan Yogyakarta',
        'category': 'historical',
        'placeId': 'ChIJe-I3S8Q0i0R4G7Ye7wGDuY',
      },
      {
        'name': 'Mount Merapi',
        'description': 'Gunung berapi paling aktif di Indonesia',
        'category': 'mountain',
        'placeId': 'ChIJVyaSi5nYi2kRJGr-Ys-CjgM',
      },
    ],
    'Jakarta': [
      {
        'name': 'National Monument (Monas)',
        'description': 'Monumen ikonik setinggi 132 meter di pusat Jakarta',
        'category': 'historical',
        'placeId': 'ChIJlSz5TIr3aS4R4IpFJ8IpCQw',
      },
      {
        'name': 'Kota Tua Jakarta',
        'description': 'Kawasan bersejarah dengan bangunan kolonial Belanda',
        'category': 'historical',
        'placeId': 'ChIJNd9MlY34aS4RwC1-4_VGrbg',
      },
      {
        'name': 'Ancol Dreamland',
        'description': 'Taman rekreasi tepi pantai terbesar di Indonesia',
        'category': 'beach',
        'placeId': 'ChIJo3qcpS34aS4R8FPrw_BI4KU',
      },
      {
        'name': 'Thousand Islands (Kepulauan Seribu)',
        'description': 'Kepulauan eksotis dengan pantai berpasir putih',
        'category': 'beach',
        'placeId': 'ChIJE3Pwcy34aS4RkG7Ye7wGDuY',
      },
    ],
    'West Java': [
      {
        'name': 'Tangkuban Perahu',
        'description': 'Gunung berapi dengan kawah yang bisa dikunjungi',
        'category': 'mountain',
        'placeId': 'ChIJQT-aSh_ZaS4RMJPrw_BI4KU',
      },
      {
        'name': 'Kawah Putih',
        'description': 'Danau kawah berwarna putih kehijauan yang memukau',
        'category': 'nature',
        'placeId': 'ChIJJ2sD_Rv3aS4R4G7Ye7wGDuY',
      },
      {
        'name': 'Bandung City',
        'description': 'Kota kembang dengan factory outlets dan kuliner',
        'category': 'urban',
        'placeId': 'ChIJEw_FpBbZaS4RoFPrw_BI4KU',
      },
    ],
    'East Java': [
      {
        'name': 'Mount Bromo',
        'description': 'Gunung berapi ikonik dengan pemandangan sunrise spektakuler',
        'category': 'mountain',
        'placeId': 'ChIJsUfrNmQq1S0RwY7Ye7wGDuY',
      },
      {
        'name': 'Ijen Crater',
        'description': 'Kawah dengan blue fire fenomena api biru',
        'category': 'mountain',
        'placeId': 'ChIJ-Vq0zMQq1S0R4G7Ye7wGDuY',
      },
    ],
    'Lombok': [
      {
        'name': 'Mount Rinjani',
        'description': 'Gunung tertinggi kedua di Indonesia dengan danau Segara Anak',
        'category': 'mountain',
        'placeId': 'ChIJlwfrNmQq1S0RwY7Ye7wGDuY',
      },
      {
        'name': 'Gili Islands',
        'description': 'Tiga pulau cantik: Gili Trawangan, Meno, dan Air',
        'category': 'beach',
        'placeId': 'ChIJ2e_OOa4p1S0RMJPrw_BI4KU',
      },
      {
        'name': 'Senggigi Beach',
        'description': 'Pantai dengan sunset indah di Lombok Barat',
        'category': 'beach',
        'placeId': 'ChIJVy-I3S8Q0i0R4G7Ye7wGDuY',
      },
    ],
    'North Sumatra': [
      {
        'name': 'Lake Toba',
        'description': 'Danau vulkanik terbesar di Asia Tenggara',
        'category': 'nature',
        'placeId': 'ChIJy0VJT2H5OjARsIpFJ8IpCQw',
      },
      {
        'name': 'Samosir Island',
        'description': 'Pulau di tengah Danau Toba, pusat budaya Batak',
        'category': 'culture',
        'placeId': 'ChIJH0VJWGH5OjAR4G7Ye7wGDuY',
      },
    ],
    'West Sumatra': [
      {
        'name': 'Bukittinggi',
        'description': 'Kota wisata dengan jam gadang dan ngarai sianok',
        'category': 'urban',
        'placeId': 'ChIJBwaBQMnYi2kR0G7Ye7wGDuY',
      },
      {
        'name': 'Harau Valley',
        'description': 'Lembah dengan tebing tinggi dan air terjun',
        'category': 'nature',
        'placeId': 'ChIJe-I3S8Q0i0R4G7Ye7wGDuY',
      },
    ],
  };

  /// Search Indonesian tourist destinations using Google Places API
  Future<List<Destination>> searchIndonesianDestinations({
    IndonesianProvince? province,
    TourismCategory? category,
    String? keyword,
    int limit = 20,
  }) async {
    try {
      if (_apiKey.isEmpty || _apiKey.contains('YOUR_')) {
        AppLogger.warning(_tag, 'Google Maps API key not configured, using curated data');
        return _getCuratedDestinations(province: province, category: category, limit: limit);
      }

      AppLogger.info(_tag, 'Searching Indonesian destinations', {
        'province': province?.displayName,
        'category': category?.displayName,
        'keyword': keyword,
      });

      // Build search query
      String query = keyword ?? '';
      if (province != null) {
        query += ' ${province.searchQuery}';
      }
      if (category != null) {
        query += ' ${category.displayName}';
      }

      if (query.isEmpty) {
        query = 'tourist attractions in Indonesia';
      }

      // Call Google Places Text Search API
      final url = Uri.parse(
        '$_placesApiBaseUrl/textsearch/json?query=$query&key=$_apiKey&language=id&region=id',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final results = data['results'] as List;

          final destinations = <Destination>[];
          for (var i = 0; i < results.length && i < limit; i++) {
            final place = results[i];

            // Get place details for more information
            final destination = await _convertPlaceToDestination(place);
            if (destination != null) {
              destinations.add(destination);
            }
          }

          AppLogger.success(_tag, 'Found ${destinations.length} Indonesian destinations');
          return destinations;
        } else {
          AppLogger.warning(_tag, 'Google Places API returned: ${data['status']}');
          return _getCuratedDestinations(province: province, category: category, limit: limit);
        }
      } else {
        AppLogger.error(_tag, 'Failed to search destinations: ${response.statusCode}');
        return _getCuratedDestinations(province: province, category: category, limit: limit);
      }
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Error searching Indonesian destinations', e, stackTrace);
      return _getCuratedDestinations(province: province, category: category, limit: limit);
    }
  }

  /// Convert Google Place to Destination model
  Future<Destination?> _convertPlaceToDestination(Map<String, dynamic> place) async {
    try {
      final placeId = place['place_id'] as String;
      final name = place['name'] as String;
      final address = place['formatted_address'] as String? ?? '';
      final rating = (place['rating'] as num?)?.toDouble() ?? 4.0;
      final userRatingsTotal = place['user_ratings_total'] as int? ?? 0;

      final geometry = place['geometry'];
      final location = geometry['location'];
      final latitude = (location['lat'] as num).toDouble();
      final longitude = (location['lng'] as num).toDouble();

      // Get photos
      final photos = <String>[];
      if (place['photos'] != null) {
        final photoList = place['photos'] as List;
        for (var photo in photoList.take(5)) {
          final photoReference = photo['photo_reference'];
          final photoUrl = '$_placesApiBaseUrl/photo?maxwidth=800&photo_reference=$photoReference&key=$_apiKey';
          photos.add(photoUrl);
        }
      }

      // Get place details for description
      final description = await _getPlaceDescription(placeId);

      return Destination(
        id: placeId,
        name: name,
        description: description ?? 'Destinasi wisata populer di Indonesia',
        location: address,
        latitude: latitude,
        longitude: longitude,
        category: _getCategoryFromPlace(place),
        images: photos.isNotEmpty ? photos : [_getDefaultImage()],
        priceRange: 3.0,
        rating: rating,
        reviewCount: userRatingsTotal,
        facilities: [],
        activities: [],
        openingHours: '24 hours',
        bestTimeToVisit: 'All year',
        isVerified: true,
        createdBy: 'system',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Error converting place to destination', e, stackTrace);
      return null;
    }
  }

  /// Get place description from Google Place Details API
  Future<String?> _getPlaceDescription(String placeId) async {
    try {
      final url = Uri.parse(
        '$_placesApiBaseUrl/details/json?place_id=$placeId&fields=editorial_summary&key=$_apiKey&language=id',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final result = data['result'];
          return result['editorial_summary']?['overview'];
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get category from Google Place types
  String _getCategoryFromPlace(Map<String, dynamic> place) {
    final types = place['types'] as List?;
    if (types == null) return 'other';

    if (types.contains('natural_feature') || types.contains('park')) return 'nature';
    if (types.contains('museum') || types.contains('art_gallery')) return 'culture';
    if (types.contains('restaurant') || types.contains('cafe')) return 'culinary';
    if (types.contains('beach')) return 'beach';
    if (types.contains('mountain') || types.contains('hiking_area')) return 'mountain';
    if (types.contains('place_of_worship') || types.contains('church') || types.contains('mosque')) return 'religious';
    if (types.contains('historical_landmark') || types.contains('historical_site')) return 'historical';
    if (types.contains('shopping_mall') || types.contains('shopping')) return 'urban';

    return 'adventure';
  }


  /// Get curated destinations (fallback when API not available)
  Future<List<Destination>> _getCuratedDestinations({
    IndonesianProvince? province,
    TourismCategory? category,
    int limit = 20,
  }) async {
    AppLogger.info(_tag, 'Using curated Indonesian destinations data');

    final destinations = <Destination>[];

    // Filter by province
    List<String> provinces = province != null
        ? [province.displayName]
        : _curatedDestinations.keys.toList();

    for (var provinceName in provinces) {
      final places = _curatedDestinations[provinceName] ?? [];

      for (var place in places) {
        // Filter by category
        if (category != null && place['category'] != category.placeType) {
          continue;
        }

        destinations.add(Destination(
          id: place['placeId'],
          name: place['name'],
          description: place['description'],
          location: provinceName,
          latitude: _getDefaultLatLng(provinceName)['lat']!,
          longitude: _getDefaultLatLng(provinceName)['lng']!,
          category: place['category'],
          images: [_getDefaultImage()],
          priceRange: 3.0,
          rating: 4.5,
          reviewCount: 1000,
          facilities: ['Parking', 'Restroom', 'WiFi'],
          activities: ['Sightseeing', 'Photography'],
          openingHours: '24 hours',
          bestTimeToVisit: 'All year',
          isVerified: true,
          createdBy: 'system',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));

        if (destinations.length >= limit) break;
      }

      if (destinations.length >= limit) break;
    }

    return destinations;
  }

  /// Get default coordinates for provinces
  Map<String, double> _getDefaultLatLng(String province) {
    final coords = <String, Map<String, double>>{
      'Bali': {'lat': -8.4095, 'lng': 115.1889},
      'Yogyakarta': {'lat': -7.7956, 'lng': 110.3695},
      'Jakarta': {'lat': -6.2088, 'lng': 106.8456},
      'West Java': {'lat': -6.9175, 'lng': 107.6191},
      'East Java': {'lat': -7.5361, 'lng': 112.2384},
      'Lombok': {'lat': -8.6500, 'lng': 116.3242},
      'North Sumatra': {'lat': 2.1154, 'lng': 99.5451},
      'West Sumatra': {'lat': -0.7399, 'lng': 100.8000},
    };

    return coords[province] ?? {'lat': -6.2088, 'lng': 106.8456};
  }

  /// Get default image URL
  String _getDefaultImage() {
    return 'https://images.unsplash.com/photo-1537996194471-e657df975ab4?w=800';
  }

  /// Get popular destinations by province
  Future<List<Destination>> getPopularDestinationsByProvince(
    IndonesianProvince province, {
    int limit = 10,
  }) async {
    return searchIndonesianDestinations(
      province: province,
      limit: limit,
    );
  }

  /// Get destinations by category
  Future<List<Destination>> getDestinationsByCategory(
    TourismCategory category, {
    IndonesianProvince? province,
    int limit = 20,
  }) async {
    return searchIndonesianDestinations(
      province: province,
      category: category,
      limit: limit,
    );
  }

  /// Get trending Indonesian destinations
  Future<List<Destination>> getTrendingDestinations({int limit = 10}) async {
    // Mix of popular destinations from different provinces
    final trending = <Destination>[];

    final provinces = [
      IndonesianProvince.bali,
      IndonesianProvince.yogyakarta,
      IndonesianProvince.jakarta,
      IndonesianProvince.ntb,
    ];

    for (var province in provinces) {
      final destinations = await searchIndonesianDestinations(
        province: province,
        limit: 3,
      );
      trending.addAll(destinations);

      if (trending.length >= limit) break;
    }

    return trending.take(limit).toList();
  }

  /// Search destinations with keyword
  Future<List<Destination>> searchByKeyword(
    String keyword, {
    IndonesianProvince? province,
    int limit = 20,
  }) async {
    return searchIndonesianDestinations(
      keyword: keyword,
      province: province,
      limit: limit,
    );
  }
}

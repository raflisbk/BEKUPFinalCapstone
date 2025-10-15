import 'dart:async';
import '../core/interfaces/i_tourism_service.dart';
import '../core/utils/logger.dart';
import 'destination_service.dart';

/// Indonesia Tourism Service
/// Handles tourism data specific to Indonesia with provinces, cities, and popular destinations
class IndonesiaTourismService implements ITourismService {
  static const String _tag = 'IndonesiaTourismService';

  // Popular provinces in Indonesia
  static const List<Map<String, dynamic>> _provinces = [
    {
      'id': 'jawa-barat',
      'name': 'Jawa Barat',
      'code': 'JB',
      'capital': 'Bandung',
      'popular_cities': ['Bandung', 'Bogor', 'Depok', 'Bekasi', 'Cirebon'],
      'tourism_highlights': ['Tangkuban Perahu', 'Kawah Putih', 'Braga Street', 'Situ Patenggang'],
    },
    {
      'id': 'dki-jakarta',
      'name': 'DKI Jakarta',
      'code': 'JK',
      'capital': 'Jakarta',
      'popular_cities': ['Jakarta Pusat', 'Jakarta Selatan', 'Jakarta Barat', 'Jakarta Utara', 'Jakarta Timur'],
      'tourism_highlights': ['Monas', 'Kota Tua', 'Ancol', 'Ragunan Zoo'],
    },
    {
      'id': 'jawa-tengah',
      'name': 'Jawa Tengah',
      'code': 'JT',
      'capital': 'Semarang',
      'popular_cities': ['Semarang', 'Solo', 'Yogyakarta', 'Magelang', 'Tegal'],
      'tourism_highlights': ['Borobudur', 'Prambanan', 'Lawang Sewu', 'Dieng Plateau'],
    },
    {
      'id': 'jawa-timur',
      'name': 'Jawa Timur',
      'code': 'JI',
      'capital': 'Surabaya',
      'popular_cities': ['Surabaya', 'Malang', 'Kediri', 'Madiun', 'Jember'],
      'tourism_highlights': ['Mount Bromo', 'Ijen Crater', 'Tumpak Sewu', 'Jatim Park'],
    },
    {
      'id': 'bali',
      'name': 'Bali',
      'code': 'BA',
      'capital': 'Denpasar',
      'popular_cities': ['Denpasar', 'Ubud', 'Sanur', 'Kuta', 'Canggu'],
      'tourism_highlights': ['Tanah Lot', 'Uluwatu', 'Tegallalang Rice Terraces', 'Mount Batur'],
    },
    {
      'id': 'nusa-tenggara-barat',
      'name': 'Nusa Tenggara Barat',
      'code': 'NB',
      'capital': 'Mataram',
      'popular_cities': ['Mataram', 'Lombok', 'Sumbawa', 'Dompu'],
      'tourism_highlights': ['Gili Islands', 'Mount Rinjani', 'Senggigi Beach', 'Sasak Village'],
    },
    {
      'id': 'sumatera-utara',
      'name': 'Sumatera Utara',
      'code': 'SU',
      'capital': 'Medan',
      'popular_cities': ['Medan', 'Pematangsiantar', 'Binjai', 'Tanjung Balai'],
      'tourism_highlights': ['Lake Toba', 'Bukit Lawang', 'Samosir Island', 'Berastagi'],
    },
    {
      'id': 'sulawesi-selatan',
      'name': 'Sulawesi Selatan',
      'code': 'SN',
      'capital': 'Makassar',
      'popular_cities': ['Makassar', 'Parepare', 'Palopo', 'Watampone'],
      'tourism_highlights': ['Losari Beach', 'Bantimurung', 'Toraja Land', 'Rammang-Rammang'],
    },
    {
      'id': 'kalimantan-timur',
      'name': 'Kalimantan Timur',
      'code': 'KI',
      'capital': 'Samarinda',
      'popular_cities': ['Samarinda', 'Balikpapan', 'Bontang', 'Sangatta'],
      'tourism_highlights': ['Derawan Islands', 'Mahakam River', 'Samboja Lestari', 'Kutai National Park'],
    },
    {
      'id': 'papua',
      'name': 'Papua',
      'code': 'PA',
      'capital': 'Jayapura',
      'popular_cities': ['Jayapura', 'Merauke', 'Sorong', 'Nabire'],
      'tourism_highlights': ['Raja Ampat', 'Puncak Jaya', 'Baliem Valley', 'Cenderawasih Bay'],
    },
  ];

  // Popular destination categories in Indonesia
  static const List<Map<String, dynamic>> _categories = [
    {
      'id': 'wisata-alam',
      'name': 'Wisata Alam',
      'description': 'Destinasi alam seperti gunung, danau, hutan, dan taman nasional',
      'icon': 'nature_people',
      'color': '#4CAF50',
      'examples': ['Gunung Bromo', 'Danau Toba', 'Raja Ampat', 'Taman Nasional Komodo'],
    },
    {
      'id': 'wisata-pantai',
      'name': 'Wisata Pantai',
      'description': 'Pantai-pantai indah di seluruh Indonesia',
      'icon': 'beach_access',
      'color': '#2196F3',
      'examples': ['Kuta Beach', 'Sanur Beach', 'Gili Trawangan', 'Pink Beach'],
    },
    {
      'id': 'wisata-budaya',
      'name': 'Wisata Budaya',
      'description': 'Destinasi bersejarah dan budaya Indonesia',
      'icon': 'account_balance',
      'color': '#FF9800',
      'examples': ['Borobudur', 'Prambanan', 'Keraton Yogyakarta', 'Taman Mini'],
    },
    {
      'id': 'wisata-kuliner',
      'name': 'Wisata Kuliner',
      'description': 'Destinasi untuk menikmati kuliner khas Indonesia',
      'icon': 'restaurant',
      'color': '#F44336',
      'examples': ['Malioboro Street', 'Braga Street', 'Pasar Santa', 'Jalan Alor'],
    },
    {
      'id': 'wisata-gunung',
      'name': 'Wisata Gunung',
      'description': 'Gunung-gunung untuk hiking dan pendakian',
      'icon': 'terrain',
      'color': '#795548',
      'examples': ['Gunung Rinjani', 'Gunung Semeru', 'Gunung Merapi', 'Gunung Batur'],
    },
    {
      'id': 'wisata-religi',
      'name': 'Wisata Religi',
      'description': 'Tempat-tempat ibadah dan ziarah',
      'icon': 'place_of_worship',
      'color': '#9C27B0',
      'examples': ['Masjid Istiqlal', 'Candi Borobudur', 'Wihara Dharma Bhakti', 'Gereja Katedral'],
    },
    {
      'id': 'wisata-modern',
      'name': 'Wisata Modern',
      'description': 'Destinasi modern seperti mall, taman hiburan, dan gedung pencakar langit',
      'icon': 'location_city',
      'color': '#607D8B',
      'examples': ['Ancol', 'Dufan', 'Central Park', 'Sky Bridge'],
    },
    {
      'id': 'eco-tourism',
      'name': 'Eco Tourism',
      'description': 'Wisata ramah lingkungan dan konservasi',
      'icon': 'eco',
      'color': '#8BC34A',
      'examples': ['Taman Nasional Ujung Kulon', 'Bukit Lawang', 'Tangkoko Nature Reserve'],
    },
  ];

  // ===============================
  // PROVINCE & CITY DATA
  // ===============================

  /// Get all provinces
  @override
  Future<List<Map<String, dynamic>>> getProvinces() async {
    try {
      AppLogger.debug(_tag, 'Getting all provinces');
      
      // In a real implementation, this might come from database
      // For now, returning static data
      AppLogger.success(_tag, 'Retrieved ${_provinces.length} provinces');
      return _provinces;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get provinces', e, stackTrace);
      rethrow;
    }
  }

  /// Get province by ID
  @override
  Future<Map<String, dynamic>?> getProvince(String provinceId) async {
    try {
      AppLogger.debug(_tag, 'Getting province: $provinceId');
      
      final province = _provinces.firstWhere(
        (p) => p['id'] == provinceId,
        orElse: () => {},
      );

      if (province.isEmpty) {
        AppLogger.warning(_tag, 'Province not found: $provinceId');
        return null;
      }

      AppLogger.success(_tag, 'Retrieved province: ${province['name']}');
      return province;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get province', e, stackTrace);
      rethrow;
    }
  }

  /// Get cities by province
  @override
  Future<List<String>> getCitiesByProvince(String provinceId) async {
    try {
      AppLogger.debug(_tag, 'Getting cities for province: $provinceId');
      
      final province = await getProvince(provinceId);
      if (province == null) {
        return [];
      }

      final cities = List<String>.from(province['popular_cities'] ?? []);
      AppLogger.success(_tag, 'Retrieved ${cities.length} cities for province: $provinceId');
      return cities;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get cities by province', e, stackTrace);
      rethrow;
    }
  }

  /// Search provinces by name
  @override
  Future<List<Map<String, dynamic>>> searchProvinces(String query) async {
    try {
      AppLogger.debug(_tag, 'Searching provinces: $query');
      
      final results = _provinces.where((province) {
        final name = province['name'].toString().toLowerCase();
        final searchQuery = query.toLowerCase();
        return name.contains(searchQuery);
      }).toList();

      AppLogger.success(_tag, 'Found ${results.length} provinces for query: $query');
      return results;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to search provinces', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // TOURISM CATEGORIES
  // ===============================

  /// Get all tourism categories
  @override
  Future<List<Map<String, dynamic>>> getTourismCategories() async {
    try {
      AppLogger.debug(_tag, 'Getting tourism categories');
      
      AppLogger.success(_tag, 'Retrieved ${_categories.length} tourism categories');
      return _categories;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get tourism categories', e, stackTrace);
      rethrow;
    }
  }

  /// Get category by ID
  @override
  Future<Map<String, dynamic>?> getTourismCategory(String categoryId) async {
    try {
      AppLogger.debug(_tag, 'Getting tourism category: $categoryId');
      
      final category = _categories.firstWhere(
        (c) => c['id'] == categoryId,
        orElse: () => {},
      );

      if (category.isEmpty) {
        AppLogger.warning(_tag, 'Tourism category not found: $categoryId');
        return null;
      }

      AppLogger.success(_tag, 'Retrieved category: ${category['name']}');
      return category;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get tourism category', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // POPULAR DESTINATIONS
  // ===============================

  /// Get popular destinations by province
  @override
  Future<List<Map<String, dynamic>>> getPopularDestinationsByProvince(
    String provinceId, {
    int limit = 10,
  }) async {
    try {
      AppLogger.debug(_tag, 'Getting popular destinations for province: $provinceId');
      
      final province = await getProvince(provinceId);
      if (province == null) {
        return [];
      }

      // Get destinations from DestinationService filtered by province
      final destinationService = DestinationService.instance;
      final destinations = await destinationService.getDestinations(
        province: province['name'],
        limit: limit,
      );

      AppLogger.success(_tag, 'Retrieved ${destinations.length} popular destinations');
      return destinations;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get popular destinations by province', e, stackTrace);
      rethrow;
    }
  }

  /// Get featured destinations across Indonesia
  @override
  Future<List<Map<String, dynamic>>> getFeaturedDestinations({
    String? category,
    String? province,
    int limit = 20,
  }) async {
    try {
      AppLogger.debug(_tag, 'Getting featured destinations across Indonesia');
      
      // Get top-rated destinations from multiple provinces
      final allDestinations = <Map<String, dynamic>>[];

      // Filter provinces if specified
      var provincesToFetch = _provinces;
      if (province != null) {
        provincesToFetch = _provinces.where((p) => p['id'] == province).toList();
      }

      for (final prov in provincesToFetch.take(5)) { // Top 5 provinces
        try {
          final destinations = await DestinationService.getTopRatedDestinations(
            limit: 4, // 4 per province
          );
          
          // Add province info to destinations
          for (final dest in destinations) {
            dest['province_info'] = {
              'id': prov['id'],
              'name': prov['name'],
              'code': prov['code'],
            };
          }
          
          allDestinations.addAll(destinations);
        } catch (e) {
          AppLogger.warning(_tag, 'Failed to get destinations for ${prov['name']}', e);
          continue;
        }
      }

      // Sort by rating and take top results
      allDestinations.sort((a, b) {
        final ratingA = a['rating'] as double? ?? 0.0;
        final ratingB = b['rating'] as double? ?? 0.0;
        return ratingB.compareTo(ratingA);
      });

      final result = allDestinations.take(limit).toList();

      AppLogger.success(_tag, 'Retrieved ${result.length} featured destinations');
      return result;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get featured destinations', e, stackTrace);
      rethrow;
    }
  }

  /// Get destinations by tourism category
  @override
  Future<List<Map<String, dynamic>>> getDestinationsByTourismCategory(
    String categoryId, {
    String? province,
    int limit = 20,
  }) async {
    try {
      AppLogger.debug(_tag, 'Getting destinations by tourism category: $categoryId');
      
      final category = await getTourismCategory(categoryId);
      if (category == null) {
        return [];
      }

      String? provinceName;
      if (province != null) {
        final prov = await getProvince(province);
        provinceName = prov?['name'];
      }

      final destinations = await DestinationService.getDestinationsByCategory(
        category: category['name'],
        limit: limit,
      );

      // Filter by province if specified
      final filteredDestinations = provinceName != null
          ? destinations.where((dest) => dest['province'] == provinceName).toList()
          : destinations;

      AppLogger.success(_tag, 'Retrieved ${filteredDestinations.length} destinations for category: $categoryId');
      return filteredDestinations;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get destinations by tourism category', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // RECOMMENDATIONS
  // ===============================

  /// Get travel recommendations based on user preferences
  @override
  Future<List<Map<String, dynamic>>> getTravelRecommendations({
    required List<String> interests,
    String? budget,
    int? days,
    String? startLocation,
    int limit = 15,
  }) async {
    try {
      AppLogger.debug(_tag, 'Getting travel recommendations');
      
      final recommendations = <Map<String, dynamic>>[];

      // Map interests to preferred categories
      final preferredCategories = interests;

      // Get destinations based on preferred categories (interests)
      if (preferredCategories.isNotEmpty) {
        for (final categoryId in preferredCategories) {
          try {
            final categoryDestinations = await getDestinationsByTourismCategory(
              categoryId,
              limit: 5,
            );
            recommendations.addAll(categoryDestinations);
          } catch (e) {
            AppLogger.warning(_tag, 'Failed to get destinations for category: $categoryId', e);
          }
        }
      }

      // If start location specified, try to get province and its destinations
      if (startLocation != null) {
        try {
          final provinceDestinations = await getPopularDestinationsByProvince(
            startLocation,
            limit: 5,
          );
          recommendations.addAll(provinceDestinations);
        } catch (e) {
          AppLogger.warning(_tag, 'Failed to get destinations for location: $startLocation', e);
        }
      }

      // If no specific preferences, get featured destinations
      if (recommendations.isEmpty) {
        try {
          final featured = await getFeaturedDestinations(limit: limit);
          recommendations.addAll(featured);
        } catch (e) {
          AppLogger.warning(_tag, 'Failed to get featured destinations', e);
        }
      }

      // Remove duplicates and limit results
      final uniqueRecommendations = <String, Map<String, dynamic>>{};
      for (final dest in recommendations) {
        uniqueRecommendations[dest['id']] = dest;
      }

      final result = uniqueRecommendations.values.take(limit).toList();

      // Sort by rating
      result.sort((a, b) {
        final ratingA = a['rating'] as double? ?? 0.0;
        final ratingB = b['rating'] as double? ?? 0.0;
        return ratingB.compareTo(ratingA);
      });

      AppLogger.success(_tag, 'Generated ${result.length} travel recommendations');
      return result;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get travel recommendations', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // UTILITY METHODS
  // ===============================

  /// Get tourism statistics for Indonesia
  @override
  Future<Map<String, dynamic>> getTourismStatistics() async {
    try {
      AppLogger.debug(_tag, 'Getting tourism statistics');
      
      // In a real implementation, this would aggregate data from database
      final stats = {
        'total_provinces': _provinces.length,
        'total_categories': _categories.length,
        'popular_provinces': _provinces.take(5).map((p) => p['name']).toList(),
        'popular_categories': _categories.take(5).map((c) => c['name']).toList(),
        'last_updated': DateTime.now().toIso8601String(),
      };

      AppLogger.success(_tag, 'Retrieved tourism statistics');
      return stats;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get tourism statistics', e, stackTrace);
      rethrow;
    }
  }

  /// Validate province and city combination
  @override
  Future<bool> validateProvinceCity(String provinceId, String cityName) async {
    try {
      final cities = await getCitiesByProvince(provinceId);
      return cities.contains(cityName);
    } catch (e) {
      AppLogger.error(_tag, 'Failed to validate province-city combination', e);
      return false;
    }
  }

  /// Get province by city name
  @override
  Future<Map<String, dynamic>?> getProvinceByCity(String cityName) async {
    try {
      AppLogger.debug(_tag, 'Getting province for city: $cityName');
      
      for (final province in _provinces) {
        final cities = List<String>.from(province['popular_cities'] ?? []);
        if (cities.contains(cityName)) {
          AppLogger.success(_tag, 'Found province for city: $cityName');
          return province;
        }
      }

      AppLogger.warning(_tag, 'No province found for city: $cityName');
      return null;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get province by city', e, stackTrace);
      rethrow;
    }
  }
}
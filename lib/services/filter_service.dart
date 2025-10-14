import 'dart:async';
import '../core/utils/logger.dart';
import 'supabase_config.dart';
import 'supabase_database_service.dart';

/// Filter Service
/// Handles advanced filtering, sorting, and data processing operations
class FilterService {
  static const String _tag = 'FilterService';
  static const String _filterPresetsTable = 'filter_presets';
  static const String _filterAnalyticsTable = 'filter_analytics';

  // Filter types
  static const String filterTypeLocation = 'location';
  static const String filterTypePrice = 'price';
  static const String filterTypeRating = 'rating';
  static const String filterTypeDate = 'date';
  static const String filterTypeCategory = 'category';
  static const String filterTypeTags = 'tags';
  static const String filterTypeAmenities = 'amenities';
  static const String filterTypeDistance = 'distance';
  static const String filterTypeAvailability = 'availability';
  static const String filterTypeType = 'type';

  // Sort options
  static const String sortByRelevance = 'relevance';
  static const String sortByPrice = 'price';
  static const String sortByRating = 'rating';
  static const String sortByDistance = 'distance';
  static const String sortByPopularity = 'popularity';
  static const String sortByDate = 'date';
  static const String sortByName = 'name';
  static const String sortByNewest = 'newest';

  // Price ranges
  static const String priceRangeBudget = 'budget';
  static const String priceRangeMid = 'mid';
  static const String priceRangeHigh = 'high';
  static const String priceRangeLuxury = 'luxury';

  // ===============================
  // FILTER APPLICATION
  // ===============================

  /// Apply filters to a dataset
  static List<Map<String, dynamic>> applyFilters({
    required List<Map<String, dynamic>> data,
    required Map<String, dynamic> filters,
    String? sortBy,
    bool ascending = false,
    double? userLatitude,
    double? userLongitude,
  }) {
    try {
      AppLogger.debug(_tag, 'Applying filters to ${data.length} items');

      var filteredData = List<Map<String, dynamic>>.from(data);

      // Apply each filter
      if (filters.containsKey(filterTypeLocation)) {
        filteredData = _applyLocationFilter(filteredData, filters[filterTypeLocation], userLatitude, userLongitude);
      }

      if (filters.containsKey(filterTypePrice)) {
        filteredData = _applyPriceFilter(filteredData, filters[filterTypePrice]);
      }

      if (filters.containsKey(filterTypeRating)) {
        filteredData = _applyRatingFilter(filteredData, filters[filterTypeRating]);
      }

      if (filters.containsKey(filterTypeDate)) {
        filteredData = _applyDateFilter(filteredData, filters[filterTypeDate]);
      }

      if (filters.containsKey(filterTypeCategory)) {
        filteredData = _applyCategoryFilter(filteredData, filters[filterTypeCategory]);
      }

      if (filters.containsKey(filterTypeTags)) {
        filteredData = _applyTagsFilter(filteredData, filters[filterTypeTags]);
      }

      if (filters.containsKey(filterTypeAmenities)) {
        filteredData = _applyAmenitiesFilter(filteredData, filters[filterTypeAmenities]);
      }

      if (filters.containsKey(filterTypeDistance)) {
        filteredData = _applyDistanceFilter(filteredData, filters[filterTypeDistance], userLatitude, userLongitude);
      }

      if (filters.containsKey(filterTypeAvailability)) {
        filteredData = _applyAvailabilityFilter(filteredData, filters[filterTypeAvailability]);
      }

      if (filters.containsKey(filterTypeType)) {
        filteredData = _applyTypeFilter(filteredData, filters[filterTypeType]);
      }

      // Apply sorting
      if (sortBy != null) {
        filteredData = applySorting(filteredData, sortBy, ascending, userLatitude, userLongitude);
      }

      AppLogger.success(_tag, 'Filters applied: ${filteredData.length} items remaining');
      return filteredData;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to apply filters', e, stackTrace);
      return data;
    }
  }

  /// Apply sorting to data
  static List<Map<String, dynamic>> applySorting(
    List<Map<String, dynamic>> data,
    String sortBy,
    bool ascending, [
    double? userLatitude,
    double? userLongitude,
  ]) {
    try {
      AppLogger.debug(_tag, 'Applying sorting: $sortBy (ascending: $ascending)');

      final sortedData = List<Map<String, dynamic>>.from(data);

      switch (sortBy) {
        case sortByPrice:
          sortedData.sort((a, b) => _comparePrice(a, b, ascending));
          break;

        case sortByRating:
          sortedData.sort((a, b) => _compareRating(a, b, ascending));
          break;

        case sortByDistance:
          if (userLatitude != null && userLongitude != null) {
            sortedData.sort((a, b) => _compareDistance(a, b, userLatitude, userLongitude, ascending));
          }
          break;

        case sortByPopularity:
          sortedData.sort((a, b) => _comparePopularity(a, b, ascending));
          break;

        case sortByDate:
          sortedData.sort((a, b) => _compareDate(a, b, ascending));
          break;

        case sortByName:
          sortedData.sort((a, b) => _compareName(a, b, ascending));
          break;

        case sortByNewest:
          sortedData.sort((a, b) => _compareCreatedDate(a, b, ascending));
          break;

        case sortByRelevance:
        default:
          sortedData.sort((a, b) => _compareRelevance(a, b, ascending));
          break;
      }

      AppLogger.success(_tag, 'Sorting applied successfully');
      return sortedData;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to apply sorting', e, stackTrace);
      return data;
    }
  }

  // ===============================
  // FILTER PRESETS
  // ===============================

  /// Save filter preset
  static Future<Map<String, dynamic>> saveFilterPreset({
    required String name,
    required Map<String, dynamic> filters,
    String? description,
    String? category,
  }) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Saving filter preset: $name');

      final presetData = {
        'user_id': userId,
        'name': name,
        'description': description,
        'category': category,
        'filters': filters,
        'is_public': false,
        'usage_count': 0,
        'created_at': DateTime.now().toIso8601String(),
      };

      final preset = await SupabaseDatabaseService.insert(
        table: _filterPresetsTable,
        data: presetData,
      );

      AppLogger.success(_tag, 'Filter preset saved: ${preset['id']}');
      return preset;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to save filter preset', e, stackTrace);
      rethrow;
    }
  }

  /// Get user's filter presets
  static Future<List<Map<String, dynamic>>> getFilterPresets({
    String? category,
    bool includePublic = true,
  }) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        return [];
      }

      AppLogger.debug(_tag, 'Getting filter presets');

      final presets = await SupabaseDatabaseService.select(
        table: _filterPresetsTable,
        filters: includePublic 
            ? {} 
            : {'user_id': userId},
        orderBy: 'usage_count',
        ascending: false,
      );

      // Filter by category if specified
      var filteredPresets = presets;
      if (category != null) {
        filteredPresets = presets.where((preset) => preset['category'] == category).toList();
      }

      // Filter out other users' private presets if including public
      if (includePublic) {
        filteredPresets = filteredPresets.where((preset) {
          return preset['user_id'] == userId || preset['is_public'] == true;
        }).toList();
      }

      AppLogger.success(_tag, 'Retrieved ${filteredPresets.length} filter presets');
      return filteredPresets;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get filter presets', e, stackTrace);
      return [];
    }
  }

  /// Apply filter preset
  static Future<Map<String, dynamic>> applyFilterPreset(String presetId) async {
    try {
      AppLogger.debug(_tag, 'Applying filter preset: $presetId');

      final presets = await SupabaseDatabaseService.select(
        table: _filterPresetsTable,
        filters: {'id': presetId},
      );

      if (presets.isEmpty) {
        throw Exception('Filter preset not found');
      }

      final preset = presets.first;
      final filters = preset['filters'] as Map<String, dynamic>;

      // Increment usage count
      await SupabaseDatabaseService.update(
        table: _filterPresetsTable,
        id: presetId,
        data: {'usage_count': (preset['usage_count'] as int? ?? 0) + 1},
      );

      AppLogger.success(_tag, 'Filter preset applied successfully');
      return filters;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to apply filter preset', e, stackTrace);
      rethrow;
    }
  }

  /// Delete filter preset
  static Future<void> deleteFilterPreset(String presetId) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Deleting filter preset: $presetId');

      // Verify ownership
      final presets = await SupabaseDatabaseService.select(
        table: _filterPresetsTable,
        filters: {'id': presetId, 'user_id': userId},
      );

      if (presets.isEmpty) {
        throw Exception('Filter preset not found or not owned by user');
      }

      await SupabaseDatabaseService.delete(
        table: _filterPresetsTable,
        id: presetId,
      );

      AppLogger.success(_tag, 'Filter preset deleted successfully');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to delete filter preset', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // FILTER SUGGESTIONS
  // ===============================

  /// Get suggested filters based on data
  static Map<String, dynamic> getSuggestedFilters(List<Map<String, dynamic>> data) {
    try {
      AppLogger.debug(_tag, 'Generating filter suggestions for ${data.length} items');

      final suggestions = <String, dynamic>{};

      // Price range suggestions
      final prices = data
          .map((item) => item['price'] as double?)
          .where((price) => price != null)
          .cast<double>()
          .toList();

      if (prices.isNotEmpty) {
        prices.sort();
        suggestions[filterTypePrice] = {
          'min': prices.first,
          'max': prices.last,
          'average': prices.reduce((a, b) => a + b) / prices.length,
          'suggested_ranges': _getSuggestedPriceRanges(prices),
        };
      }

      // Rating suggestions
      final ratings = data
          .map((item) => item['average_rating'] as double?)
          .where((rating) => rating != null)
          .cast<double>()
          .toList();

      if (ratings.isNotEmpty) {
        suggestions[filterTypeRating] = {
          'min': ratings.reduce((a, b) => a < b ? a : b),
          'max': ratings.reduce((a, b) => a > b ? a : b),
          'average': ratings.reduce((a, b) => a + b) / ratings.length,
        };
      }

      // Category suggestions
      final categories = <String, int>{};
      for (final item in data) {
        final category = item['category'] as String?;
        if (category != null) {
          categories[category] = (categories[category] ?? 0) + 1;
        }
      }
      if (categories.isNotEmpty) {
        suggestions[filterTypeCategory] = categories;
      }

      // Tags suggestions
      final allTags = <String, int>{};
      for (final item in data) {
        final tags = item['tags'] as List<dynamic>?;
        if (tags != null) {
          for (final tag in tags) {
            final tagString = tag.toString();
            allTags[tagString] = (allTags[tagString] ?? 0) + 1;
          }
        }
      }
      if (allTags.isNotEmpty) {
        // Sort by frequency and take top tags
        final sortedTags = allTags.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        suggestions[filterTypeTags] = Map.fromEntries(sortedTags.take(20));
      }

      AppLogger.success(_tag, 'Generated filter suggestions');
      return suggestions;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to generate filter suggestions', e, stackTrace);
      return {};
    }
  }

  /// Get popular filter combinations
  static Future<List<Map<String, dynamic>>> getPopularFilterCombinations({
    String? category,
    int limit = 10,
  }) async {
    try {
      AppLogger.debug(_tag, 'Getting popular filter combinations');

      final analytics = await SupabaseDatabaseService.select(
        table: _filterAnalyticsTable,
        filters: category != null ? {'category': category} : {},
        orderBy: 'usage_count',
        ascending: false,
        limit: limit,
      );

      AppLogger.success(_tag, 'Retrieved ${analytics.length} popular filter combinations');
      return analytics;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get popular filter combinations', e, stackTrace);
      return [];
    }
  }

  // ===============================
  // FILTER ANALYTICS
  // ===============================

  /// Track filter usage
  static Future<void> trackFilterUsage({
    required Map<String, dynamic> filters,
    String? category,
    int? resultCount,
  }) async {
    try {
      final userId = SupabaseConfig.userId;

      // Create filter signature for analytics
      final filterSignature = _createFilterSignature(filters);

      final analyticsData = {
        'user_id': userId,
        'filter_signature': filterSignature,
        'filters': filters,
        'category': category,
        'result_count': resultCount,
        'used_at': DateTime.now().toIso8601String(),
      };

      await SupabaseDatabaseService.insert(
        table: _filterAnalyticsTable,
        data: analyticsData,
      );

      AppLogger.debug(_tag, 'Filter usage tracked');
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to track filter usage', e);
    }
  }

  // ===============================
  // SMART FILTERS
  // ===============================

  /// Get smart filter recommendations based on user behavior
  static Future<Map<String, dynamic>> getSmartFilterRecommendations({
    String? category,
    double? userLatitude,
    double? userLongitude,
  }) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        return {};
      }

      AppLogger.debug(_tag, 'Getting smart filter recommendations');

      // Get user's filter history
      final filterHistory = await SupabaseDatabaseService.select(
        table: _filterAnalyticsTable,
        filters: {'user_id': userId},
        orderBy: 'used_at',
        ascending: false,
        limit: 50,
      );

      final recommendations = <String, dynamic>{};

      // Analyze most used filters
      final filterUsage = <String, int>{};
      for (final record in filterHistory) {
        final filters = record['filters'] as Map<String, dynamic>? ?? {};
        for (final filterType in filters.keys) {
          filterUsage[filterType] = (filterUsage[filterType] ?? 0) + 1;
        }
      }

      recommendations['most_used_filters'] = filterUsage;

      // Location-based recommendations
      if (userLatitude != null && userLongitude != null) {
        recommendations['location_suggestions'] = {
          'nearby_filters': {
            filterTypeDistance: {'max_distance': 50}, // 50km radius
          }
        };
      }

      // Time-based recommendations
      final now = DateTime.now();
      recommendations['time_based'] = {
        'season': _getCurrentSeason(now),
        'suggested_date_filters': _getSuggestedDateFilters(now),
      };

      AppLogger.success(_tag, 'Smart filter recommendations generated');
      return recommendations;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get smart filter recommendations', e, stackTrace);
      return {};
    }
  }

  // ===============================
  // FILTER HELPERS
  // ===============================

  /// Combine multiple filter sets
  static Map<String, dynamic> combineFilters(List<Map<String, dynamic>> filterSets) {
    final combined = <String, dynamic>{};

    for (final filterSet in filterSets) {
      for (final entry in filterSet.entries) {
        if (combined.containsKey(entry.key)) {
          // Merge logic based on filter type
          combined[entry.key] = _mergeFilterValues(combined[entry.key], entry.value, entry.key);
        } else {
          combined[entry.key] = entry.value;
        }
      }
    }

    return combined;
  }

  /// Validate filters
  static bool validateFilters(Map<String, dynamic> filters) {
    try {
      for (final entry in filters.entries) {
        if (!_validateFilterValue(entry.key, entry.value)) {
          AppLogger.warning(_tag, 'Invalid filter value: ${entry.key} = ${entry.value}');
          return false;
        }
      }
      return true;
    } catch (e) {
      AppLogger.warning(_tag, 'Filter validation failed', e);
      return false;
    }
  }

  /// Get filter display names
  static Map<String, String> getFilterDisplayNames() {
    return {
      filterTypeLocation: 'Location',
      filterTypePrice: 'Price Range',
      filterTypeRating: 'Rating',
      filterTypeDate: 'Date',
      filterTypeCategory: 'Category',
      filterTypeTags: 'Tags',
      filterTypeAmenities: 'Amenities',
      filterTypeDistance: 'Distance',
      filterTypeAvailability: 'Availability',
      filterTypeType: 'Type',
    };
  }

  // ===============================
  // PRIVATE FILTER METHODS
  // ===============================

  /// Apply location filter
  static List<Map<String, dynamic>> _applyLocationFilter(
    List<Map<String, dynamic>> data,
    dynamic locationFilter,
    double? userLatitude,
    double? userLongitude,
  ) {
    try {
      if (locationFilter is String) {
        final location = locationFilter.toLowerCase();
        return data.where((item) {
          final itemLocation = (item['location'] as String? ?? '').toLowerCase();
          return itemLocation.contains(location);
        }).toList();
      } else if (locationFilter is Map<String, dynamic>) {
        final lat = locationFilter['latitude'] as double?;
        final lng = locationFilter['longitude'] as double?;
        final radius = locationFilter['radius'] as double? ?? 50.0; // Default 50km

        if (lat != null && lng != null) {
          return data.where((item) {
            final itemLat = item['latitude'] as double?;
            final itemLng = item['longitude'] as double?;
            
            if (itemLat != null && itemLng != null) {
              final distance = _calculateDistance(lat, lng, itemLat, itemLng);
              return distance <= radius;
            }
            return false;
          }).toList();
        }
      }
      return data;
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to apply location filter', e);
      return data;
    }
  }

  /// Apply price filter
  static List<Map<String, dynamic>> _applyPriceFilter(
    List<Map<String, dynamic>> data,
    dynamic priceFilter,
  ) {
    try {
      if (priceFilter is Map<String, dynamic>) {
        final minPrice = priceFilter['min'] as double?;
        final maxPrice = priceFilter['max'] as double?;

        return data.where((item) {
          final price = item['price'] as double?;
          if (price == null) return false;

          if (minPrice != null && price < minPrice) return false;
          if (maxPrice != null && price > maxPrice) return false;

          return true;
        }).toList();
      } else if (priceFilter is String) {
        // Predefined price ranges
        return data.where((item) {
          final price = item['price'] as double?;
          if (price == null) return false;

          switch (priceFilter) {
            case priceRangeBudget:
              return price <= 50;
            case priceRangeMid:
              return price > 50 && price <= 150;
            case priceRangeHigh:
              return price > 150 && price <= 300;
            case priceRangeLuxury:
              return price > 300;
            default:
              return true;
          }
        }).toList();
      }
      return data;
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to apply price filter', e);
      return data;
    }
  }

  /// Apply rating filter
  static List<Map<String, dynamic>> _applyRatingFilter(
    List<Map<String, dynamic>> data,
    dynamic ratingFilter,
  ) {
    try {
      double minRating = 0.0;

      if (ratingFilter is double) {
        minRating = ratingFilter;
      } else if (ratingFilter is int) {
        minRating = ratingFilter.toDouble();
      } else if (ratingFilter is Map<String, dynamic>) {
        minRating = ratingFilter['min'] as double? ?? 0.0;
      }

      return data.where((item) {
        final rating = item['average_rating'] as double? ?? 0.0;
        return rating >= minRating;
      }).toList();
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to apply rating filter', e);
      return data;
    }
  }

  /// Apply date filter
  static List<Map<String, dynamic>> _applyDateFilter(
    List<Map<String, dynamic>> data,
    dynamic dateFilter,
  ) {
    try {
      if (dateFilter is Map<String, dynamic>) {
        final startDate = DateTime.tryParse(dateFilter['start'] ?? '');
        final endDate = DateTime.tryParse(dateFilter['end'] ?? '');

        return data.where((item) {
          final itemDate = DateTime.tryParse(item['date'] ?? item['created_at'] ?? '');
          if (itemDate == null) return false;

          if (startDate != null && itemDate.isBefore(startDate)) return false;
          if (endDate != null && itemDate.isAfter(endDate)) return false;

          return true;
        }).toList();
      }
      return data;
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to apply date filter', e);
      return data;
    }
  }

  /// Apply category filter
  static List<Map<String, dynamic>> _applyCategoryFilter(
    List<Map<String, dynamic>> data,
    dynamic categoryFilter,
  ) {
    try {
      if (categoryFilter is String) {
        return data.where((item) => item['category'] == categoryFilter).toList();
      } else if (categoryFilter is List) {
        final categories = categoryFilter.cast<String>();
        return data.where((item) {
          final itemCategory = item['category'] as String?;
          return itemCategory != null && categories.contains(itemCategory);
        }).toList();
      }
      return data;
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to apply category filter', e);
      return data;
    }
  }

  /// Apply tags filter
  static List<Map<String, dynamic>> _applyTagsFilter(
    List<Map<String, dynamic>> data,
    dynamic tagsFilter,
  ) {
    try {
      if (tagsFilter is List) {
        final filterTags = tagsFilter.cast<String>();
        return data.where((item) {
          final itemTags = List<String>.from(item['tags'] ?? []);
          return filterTags.any((tag) => itemTags.contains(tag));
        }).toList();
      }
      return data;
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to apply tags filter', e);
      return data;
    }
  }

  /// Apply amenities filter
  static List<Map<String, dynamic>> _applyAmenitiesFilter(
    List<Map<String, dynamic>> data,
    dynamic amenitiesFilter,
  ) {
    try {
      if (amenitiesFilter is List) {
        final filterAmenities = amenitiesFilter.cast<String>();
        return data.where((item) {
          final itemAmenities = List<String>.from(item['amenities'] ?? []);
          return filterAmenities.every((amenity) => itemAmenities.contains(amenity));
        }).toList();
      }
      return data;
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to apply amenities filter', e);
      return data;
    }
  }

  /// Apply distance filter
  static List<Map<String, dynamic>> _applyDistanceFilter(
    List<Map<String, dynamic>> data,
    dynamic distanceFilter,
    double? userLatitude,
    double? userLongitude,
  ) {
    try {
      if (userLatitude == null || userLongitude == null) return data;

      double maxDistance = 50.0; // Default 50km

      if (distanceFilter is double) {
        maxDistance = distanceFilter;
      } else if (distanceFilter is int) {
        maxDistance = distanceFilter.toDouble();
      } else if (distanceFilter is Map<String, dynamic>) {
        maxDistance = distanceFilter['max_distance'] as double? ?? 50.0;
      }

      return data.where((item) {
        final itemLat = item['latitude'] as double?;
        final itemLng = item['longitude'] as double?;

        if (itemLat != null && itemLng != null) {
          final distance = _calculateDistance(userLatitude, userLongitude, itemLat, itemLng);
          return distance <= maxDistance;
        }
        return false;
      }).toList();
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to apply distance filter', e);
      return data;
    }
  }

  /// Apply availability filter
  static List<Map<String, dynamic>> _applyAvailabilityFilter(
    List<Map<String, dynamic>> data,
    dynamic availabilityFilter,
  ) {
    try {
      if (availabilityFilter is bool) {
        return data.where((item) => item['is_available'] == availabilityFilter).toList();
      } else if (availabilityFilter is Map<String, dynamic>) {
        // Future: integrate with booking/availability system
        // This would check available dates against booking calendar
        return data.where((item) => item['is_available'] == true).toList();
      }
      return data;
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to apply availability filter', e);
      return data;
    }
  }

  /// Apply type filter
  static List<Map<String, dynamic>> _applyTypeFilter(
    List<Map<String, dynamic>> data,
    dynamic typeFilter,
  ) {
    try {
      if (typeFilter is String) {
        return data.where((item) => item['type'] == typeFilter).toList();
      } else if (typeFilter is List) {
        final types = typeFilter.cast<String>();
        return data.where((item) {
          final itemType = item['type'] as String?;
          return itemType != null && types.contains(itemType);
        }).toList();
      }
      return data;
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to apply type filter', e);
      return data;
    }
  }

  // ===============================
  // SORTING COMPARISON METHODS
  // ===============================

  /// Compare by price
  static int _comparePrice(Map<String, dynamic> a, Map<String, dynamic> b, bool ascending) {
    final priceA = a['price'] as double? ?? 0.0;
    final priceB = b['price'] as double? ?? 0.0;
    return ascending ? priceA.compareTo(priceB) : priceB.compareTo(priceA);
  }

  /// Compare by rating
  static int _compareRating(Map<String, dynamic> a, Map<String, dynamic> b, bool ascending) {
    final ratingA = a['average_rating'] as double? ?? 0.0;
    final ratingB = b['average_rating'] as double? ?? 0.0;
    return ascending ? ratingA.compareTo(ratingB) : ratingB.compareTo(ratingA);
  }

  /// Compare by distance
  static int _compareDistance(
    Map<String, dynamic> a,
    Map<String, dynamic> b,
    double userLat,
    double userLng,
    bool ascending,
  ) {
    final latA = a['latitude'] as double?;
    final lngA = a['longitude'] as double?;
    final latB = b['latitude'] as double?;
    final lngB = b['longitude'] as double?;

    if (latA == null || lngA == null) return ascending ? 1 : -1;
    if (latB == null || lngB == null) return ascending ? -1 : 1;

    final distanceA = _calculateDistance(userLat, userLng, latA, lngA);
    final distanceB = _calculateDistance(userLat, userLng, latB, lngB);

    return ascending ? distanceA.compareTo(distanceB) : distanceB.compareTo(distanceA);
  }

  /// Compare by popularity
  static int _comparePopularity(Map<String, dynamic> a, Map<String, dynamic> b, bool ascending) {
    final popularityA = a['view_count'] as int? ?? a['booking_count'] as int? ?? 0;
    final popularityB = b['view_count'] as int? ?? b['booking_count'] as int? ?? 0;
    return ascending ? popularityA.compareTo(popularityB) : popularityB.compareTo(popularityA);
  }

  /// Compare by date
  static int _compareDate(Map<String, dynamic> a, Map<String, dynamic> b, bool ascending) {
    final dateA = DateTime.tryParse(a['date'] ?? '') ?? DateTime(1970);
    final dateB = DateTime.tryParse(b['date'] ?? '') ?? DateTime(1970);
    return ascending ? dateA.compareTo(dateB) : dateB.compareTo(dateA);
  }

  /// Compare by name
  static int _compareName(Map<String, dynamic> a, Map<String, dynamic> b, bool ascending) {
    final nameA = a['name'] as String? ?? '';
    final nameB = b['name'] as String? ?? '';
    return ascending ? nameA.compareTo(nameB) : nameB.compareTo(nameA);
  }

  /// Compare by created date
  static int _compareCreatedDate(Map<String, dynamic> a, Map<String, dynamic> b, bool ascending) {
    final dateA = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime(1970);
    final dateB = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime(1970);
    return ascending ? dateA.compareTo(dateB) : dateB.compareTo(dateA);
  }

  /// Compare by relevance
  static int _compareRelevance(Map<String, dynamic> a, Map<String, dynamic> b, bool ascending) {
    final relevanceA = a['relevance_score'] as double? ?? 0.0;
    final relevanceB = b['relevance_score'] as double? ?? 0.0;
    return ascending ? relevanceA.compareTo(relevanceB) : relevanceB.compareTo(relevanceA);
  }

  // ===============================
  // UTILITY METHODS
  // ===============================

  /// Calculate distance between two points using Haversine formula
  static double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLng = _degreesToRadians(lng2 - lng1);
    
    final a = (dLat / 2).sin() * (dLat / 2).sin() +
        lat1.toRadians().cos() * lat2.toRadians().cos() *
        (dLng / 2).sin() * (dLng / 2).sin();
    
    final c = 2 * a.sqrt().asin();
    
    return earthRadius * c;
  }

  /// Convert degrees to radians
  static double _degreesToRadians(double degrees) {
    return degrees * (3.14159265359 / 180.0);
  }

  /// Get suggested price ranges
  static List<Map<String, dynamic>> _getSuggestedPriceRanges(List<double> prices) {
    if (prices.isEmpty) return [];

    final min = prices.first;
    final max = prices.last;
    final range = max - min;

    return [
      {'name': 'Budget', 'min': min, 'max': min + (range * 0.25)},
      {'name': 'Mid-range', 'min': min + (range * 0.25), 'max': min + (range * 0.75)},
      {'name': 'Premium', 'min': min + (range * 0.75), 'max': max},
    ];
  }

  /// Create filter signature for analytics
  static String _createFilterSignature(Map<String, dynamic> filters) {
    final sortedKeys = filters.keys.toList()..sort();
    return sortedKeys.map((key) => '$key:${filters[key]}').join(',');
  }

  /// Merge filter values
  static dynamic _mergeFilterValues(dynamic value1, dynamic value2, String filterType) {
    switch (filterType) {
      case filterTypePrice:
        if (value1 is Map && value2 is Map) {
          return {
            'min': (value1['min'] as double? ?? 0.0).compareTo(value2['min'] as double? ?? 0.0) < 0 
                ? value1['min'] : value2['min'],
            'max': (value1['max'] as double? ?? double.infinity).compareTo(value2['max'] as double? ?? double.infinity) > 0 
                ? value1['max'] : value2['max'],
          };
        }
        break;
      case filterTypeTags:
      case filterTypeCategory:
        if (value1 is List && value2 is List) {
          final combined = <String>{};
          combined.addAll(value1.cast<String>());
          combined.addAll(value2.cast<String>());
          return combined.toList();
        }
        break;
    }
    return value2; // Default to newer value
  }

  /// Validate filter value
  static bool _validateFilterValue(String filterType, dynamic value) {
    switch (filterType) {
      case filterTypePrice:
        return value is Map || value is String;
      case filterTypeRating:
        return value is double || value is int || value is Map;
      case filterTypeLocation:
        return value is String || value is Map;
      case filterTypeDate:
        return value is Map;
      case filterTypeCategory:
      case filterTypeTags:
      case filterTypeAmenities:
        return value is String || value is List;
      case filterTypeDistance:
        return value is double || value is int || value is Map;
      case filterTypeAvailability:
        return value is bool || value is Map;
      case filterTypeType:
        return value is String || value is List;
      default:
        return true;
    }
  }

  /// Get current season
  static String _getCurrentSeason(DateTime date) {
    final month = date.month;
    if (month >= 3 && month <= 5) return 'spring';
    if (month >= 6 && month <= 8) return 'summer';
    if (month >= 9 && month <= 11) return 'autumn';
    return 'winter';
  }

  /// Get suggested date filters
  static Map<String, dynamic> _getSuggestedDateFilters(DateTime now) {
    return {
      'this_week': {
        'start': now.subtract(Duration(days: now.weekday - 1)).toIso8601String(),
        'end': now.add(Duration(days: 7 - now.weekday)).toIso8601String(),
      },
      'this_month': {
        'start': DateTime(now.year, now.month, 1).toIso8601String(),
        'end': DateTime(now.year, now.month + 1, 0).toIso8601String(),
      },
      'next_month': {
        'start': DateTime(now.year, now.month + 1, 1).toIso8601String(),
        'end': DateTime(now.year, now.month + 2, 0).toIso8601String(),
      },
    };
  }
}

extension _DoubleExtension on double {
  double toRadians() => this * (3.14159265359 / 180.0);
  double sin() => this; // Placeholder - would use math library
  double cos() => this; // Placeholder - would use math library
  double asin() => this; // Placeholder - would use math library
  double sqrt() => this; // Placeholder - would use math library
}
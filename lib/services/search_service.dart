import 'dart:async';
import '../core/utils/logger.dart';
import 'supabase_config.dart';
import 'supabase_database_service.dart';
import 'cache_service.dart';
import 'analytics_service.dart';

/// Search Service
/// Handles comprehensive search functionality across all content types
/// including destinations, accommodations, activities, users, communities, etc.
class SearchService {
  static const String _tag = 'SearchService';
  static const String _searchHistoryTable = 'search_history';
  static const String _searchAnalyticsTable = 'search_analytics';
  static const String _searchSuggestionsTable = 'search_suggestions';

  // Search categories
  static const String categoryAll = 'all';
  static const String categoryDestinations = 'destinations';
  static const String categoryAccommodations = 'accommodations';
  static const String categoryActivities = 'activities';
  static const String categoryUsers = 'users';
  static const String categoryCommunities = 'communities';
  static const String categoryPosts = 'posts';
  static const String categoryEvents = 'events';

  // Search filters
  static const String filterLocation = 'location';
  static const String filterPrice = 'price';
  static const String filterRating = 'rating';
  static const String filterDate = 'date';
  static const String filterCategory = 'category';
  static const String filterTags = 'tags';

  // Search result types
  static const String resultTypeExact = 'exact';
  static const String resultTypeFuzzy = 'fuzzy';
  static const String resultTypeRecommended = 'recommended';
  static const String resultTypePopular = 'popular';

  // ===============================
  // UNIVERSAL SEARCH
  // ===============================

  /// Perform universal search across all content types
  static Future<Map<String, dynamic>> universalSearch({
    required String query,
    String category = categoryAll,
    Map<String, dynamic>? filters,
    String? sortBy,
    double? latitude,
    double? longitude,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final userId = SupabaseConfig.userId;
      
      AppLogger.debug(_tag, 'Performing universal search: $query');

      // Sanitize query
      final sanitizedQuery = _sanitizeQuery(query);
      if (sanitizedQuery.isEmpty) {
        return _getEmptySearchResults();
      }

      // Track search
      await _trackSearch(query, category, filters, userId);

      // Get cached results first
      final cacheKey = _generateCacheKey(query, category, filters, sortBy, latitude, longitude);
      final cachedResults = await CacheService.get(cacheKey);
      if (cachedResults != null) {
        AppLogger.debug(_tag, 'Returning cached search results');
        return cachedResults;
      }

      final results = <String, dynamic>{
        'query': query,
        'category': category,
        'total_results': 0,
        'results': <Map<String, dynamic>>[],
        'suggestions': <String>[],
        'filters_applied': filters ?? {},
        'search_time': DateTime.now().toIso8601String(),
      };

      // Search based on category
      if (category == categoryAll) {
        // Search all categories
        final searchTasks = [
          _searchDestinations(sanitizedQuery, filters, sortBy, latitude, longitude, limit ~/ 6),
          _searchAccommodations(sanitizedQuery, filters, sortBy, latitude, longitude, limit ~/ 6),
          _searchActivities(sanitizedQuery, filters, sortBy, latitude, longitude, limit ~/ 6),
          _searchUsers(sanitizedQuery, filters, sortBy, limit ~/ 6),
          _searchCommunities(sanitizedQuery, filters, sortBy, limit ~/ 6),
          _searchPosts(sanitizedQuery, filters, sortBy, limit ~/ 6),
        ];

        final searchResults = await Future.wait(searchTasks);
        
        results['destinations'] = searchResults[0];
        results['accommodations'] = searchResults[1];
        results['activities'] = searchResults[2];
        results['users'] = searchResults[3];
        results['communities'] = searchResults[4];
        results['posts'] = searchResults[5];

        // Combine all results
        final allResults = <Map<String, dynamic>>[];
        for (final categoryResults in searchResults) {
          allResults.addAll(categoryResults);
        }
        
        // Sort combined results by relevance
        allResults.sort((a, b) => (b['relevance_score'] as double).compareTo(a['relevance_score'] as double));
        
        results['results'] = allResults.skip(offset).take(limit).toList();
        results['total_results'] = allResults.length;
      } else {
        // Search specific category
        List<Map<String, dynamic>> categoryResults;
        
        switch (category) {
          case categoryDestinations:
            categoryResults = await _searchDestinations(sanitizedQuery, filters, sortBy, latitude, longitude, limit + offset);
            break;
          case categoryAccommodations:
            categoryResults = await _searchAccommodations(sanitizedQuery, filters, sortBy, latitude, longitude, limit + offset);
            break;
          case categoryActivities:
            categoryResults = await _searchActivities(sanitizedQuery, filters, sortBy, latitude, longitude, limit + offset);
            break;
          case categoryUsers:
            categoryResults = await _searchUsers(sanitizedQuery, filters, sortBy, limit + offset);
            break;
          case categoryCommunities:
            categoryResults = await _searchCommunities(sanitizedQuery, filters, sortBy, limit + offset);
            break;
          case categoryPosts:
            categoryResults = await _searchPosts(sanitizedQuery, filters, sortBy, limit + offset);
            break;
          default:
            categoryResults = [];
        }

        results['results'] = categoryResults.skip(offset).take(limit).toList();
        results['total_results'] = categoryResults.length;
      }

      // Get search suggestions
      results['suggestions'] = await _getSearchSuggestions(query, category);

      // Cache results
      await CacheService.set(cacheKey, results, duration: const Duration(minutes: 15));

      // Track search results
      await _trackSearchResults(query, results['total_results'], userId);

      AppLogger.success(_tag, 'Search completed: ${results['total_results']} results');
      return results;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to perform universal search', e, stackTrace);
      rethrow;
    }
  }

  /// Quick search for autocomplete
  static Future<List<Map<String, dynamic>>> quickSearch({
    required String query,
    String category = categoryAll,
    int limit = 10,
  }) async {
    try {
      AppLogger.debug(_tag, 'Performing quick search: $query');

      final sanitizedQuery = _sanitizeQuery(query);
      if (sanitizedQuery.isEmpty) {
        return [];
      }

      // Get cached quick search results
      final cacheKey = 'quick_search_${sanitizedQuery}_$category';
      final cachedResults = await CacheService.get(cacheKey);
      if (cachedResults != null) {
        return List<Map<String, dynamic>>.from(cachedResults);
      }

      final results = <Map<String, dynamic>>[];

      // Quick search in different categories
      if (category == categoryAll || category == categoryDestinations) {
        final destinations = await _quickSearchDestinations(sanitizedQuery, limit ~/ 4);
        results.addAll(destinations);
      }

      if (category == categoryAll || category == categoryUsers) {
        final users = await _quickSearchUsers(sanitizedQuery, limit ~/ 4);
        results.addAll(users);
      }

      if (category == categoryAll || category == categoryCommunities) {
        final communities = await _quickSearchCommunities(sanitizedQuery, limit ~/ 4);
        results.addAll(communities);
      }

      // Sort by relevance and limit
      results.sort((a, b) => (b['relevance_score'] as double).compareTo(a['relevance_score'] as double));
      final limitedResults = results.take(limit).toList();

      // Cache for short duration
      await CacheService.set(cacheKey, limitedResults, duration: const Duration(minutes: 5));

      AppLogger.success(_tag, 'Quick search completed: ${limitedResults.length} results');
      return limitedResults;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to perform quick search', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // SEARCH SUGGESTIONS
  // ===============================

  /// Get search suggestions based on query
  static Future<List<String>> getSearchSuggestions({
    required String query,
    String category = categoryAll,
    int limit = 10,
  }) async {
    try {
      AppLogger.debug(_tag, 'Getting search suggestions for: $query');

      final sanitizedQuery = _sanitizeQuery(query);
      if (sanitizedQuery.isEmpty) {
        return await _getPopularSearches(category, limit);
      }

      return await _getSearchSuggestions(query, category, limit);
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get search suggestions', e, stackTrace);
      return [];
    }
  }

  /// Get trending searches
  static Future<List<Map<String, dynamic>>> getTrendingSearches({
    String category = categoryAll,
    Duration period = const Duration(days: 7),
    int limit = 20,
  }) async {
    try {
      AppLogger.debug(_tag, 'Getting trending searches');

      final cutoffDate = DateTime.now().subtract(period);

      final trending = await SupabaseDatabaseService.select(
        table: _searchAnalyticsTable,
        filters: {
          'created_at': '>=${cutoffDate.toIso8601String()}',
        },
        orderBy: 'search_count',
        ascending: false,
        limit: limit,
      );

      // Filter by category if specified
      var filteredTrending = trending;
      if (category != categoryAll) {
        filteredTrending = trending.where((trend) => trend['category'] == category).toList();
      }

      AppLogger.success(_tag, 'Retrieved ${filteredTrending.length} trending searches');
      return filteredTrending;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get trending searches', e, stackTrace);
      return [];
    }
  }

  // ===============================
  // SEARCH HISTORY
  // ===============================

  /// Get user's search history
  static Future<List<Map<String, dynamic>>> getSearchHistory({
    int limit = 50,
  }) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        return [];
      }

      AppLogger.debug(_tag, 'Getting search history for user');

      final history = await SupabaseDatabaseService.select(
        table: _searchHistoryTable,
        filters: {'user_id': userId},
        orderBy: 'searched_at',
        ascending: false,
        limit: limit,
      );

      AppLogger.success(_tag, 'Retrieved ${history.length} search history items');
      return history;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get search history', e, stackTrace);
      return [];
    }
  }

  /// Clear search history
  static Future<void> clearSearchHistory() async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Clearing search history');

      // Remove all records matching filters
      final recordsToDelete = await SupabaseDatabaseService.select(
        table: _searchHistoryTable,
        filters: {'user_id': userId},
      );

      for (final record in recordsToDelete) {
        await SupabaseDatabaseService.delete(
          table: _searchHistoryTable,
          id: record['id'],
        );
      }

      AppLogger.success(_tag, 'Search history cleared');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to clear search history', e, stackTrace);
      rethrow;
    }
  }

  /// Remove specific search from history
  static Future<void> removeFromSearchHistory(String searchId) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Removing search from history: $searchId');

      await SupabaseDatabaseService.delete(
        table: _searchHistoryTable,
        id: searchId,
      );

      AppLogger.success(_tag, 'Search removed from history');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to remove search from history', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // SEARCH FILTERS
  // ===============================

  /// Apply advanced filters to search results
  static List<Map<String, dynamic>> applyFilters({
    required List<Map<String, dynamic>> results,
    Map<String, dynamic>? filters,
  }) {
    if (filters == null || filters.isEmpty) {
      return results;
    }

    var filteredResults = results;

    // Apply location filter
    if (filters.containsKey(filterLocation)) {
      final location = filters[filterLocation] as Map<String, dynamic>?;
      if (location != null) {
        filteredResults = _applyLocationFilter(filteredResults, location);
      }
    }

    // Apply price filter
    if (filters.containsKey(filterPrice)) {
      final priceRange = filters[filterPrice] as Map<String, dynamic>?;
      if (priceRange != null) {
        filteredResults = _applyPriceFilter(filteredResults, priceRange);
      }
    }

    // Apply rating filter
    if (filters.containsKey(filterRating)) {
      final minRating = filters[filterRating] as double?;
      if (minRating != null) {
        filteredResults = _applyRatingFilter(filteredResults, minRating);
      }
    }

    // Apply date filter
    if (filters.containsKey(filterDate)) {
      final dateRange = filters[filterDate] as Map<String, dynamic>?;
      if (dateRange != null) {
        filteredResults = _applyDateFilter(filteredResults, dateRange);
      }
    }

    // Apply category filter
    if (filters.containsKey(filterCategory)) {
      final categories = filters[filterCategory] as List<String>?;
      if (categories != null && categories.isNotEmpty) {
        filteredResults = _applyCategoryFilter(filteredResults, categories);
      }
    }

    // Apply tags filter
    if (filters.containsKey(filterTags)) {
      final tags = filters[filterTags] as List<String>?;
      if (tags != null && tags.isNotEmpty) {
        filteredResults = _applyTagsFilter(filteredResults, tags);
      }
    }

    return filteredResults;
  }

  // ===============================
  // CATEGORY-SPECIFIC SEARCH
  // ===============================

  /// Search destinations
  static Future<List<Map<String, dynamic>>> _searchDestinations(
    String query,
    Map<String, dynamic>? filters,
    String? sortBy,
    double? latitude,
    double? longitude,
    int limit,
  ) async {
    try {
      final destinations = await SupabaseDatabaseService.select(
        table: 'destinations',
        filters: {'is_active': true},
        limit: limit * 2,
      );

      var results = destinations.where((dest) {
        final name = (dest['name'] as String? ?? '').toLowerCase();
        final description = (dest['description'] as String? ?? '').toLowerCase();
        final location = (dest['location'] as String? ?? '').toLowerCase();
        final searchQuery = query.toLowerCase();

        return name.contains(searchQuery) || 
               description.contains(searchQuery) || 
               location.contains(searchQuery);
      }).map((dest) {
        dest['type'] = 'destination';
        dest['relevance_score'] = _calculateRelevanceScore(dest, query, 'destination');
        return dest;
      }).toList();

      // Apply filters
      results = applyFilters(results: results, filters: filters);

      // Sort results
      _sortSearchResults(results, sortBy);

      return results.take(limit).toList();
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to search destinations', e);
      return [];
    }
  }

  /// Search accommodations
  static Future<List<Map<String, dynamic>>> _searchAccommodations(
    String query,
    Map<String, dynamic>? filters,
    String? sortBy,
    double? latitude,
    double? longitude,
    int limit,
  ) async {
    try {
      final accommodations = await SupabaseDatabaseService.select(
        table: 'accommodations',
        filters: {'is_active': true},
        limit: limit * 2,
      );

      var results = accommodations.where((acc) {
        final name = (acc['name'] as String? ?? '').toLowerCase();
        final description = (acc['description'] as String? ?? '').toLowerCase();
        final location = (acc['location'] as String? ?? '').toLowerCase();
        final searchQuery = query.toLowerCase();

        return name.contains(searchQuery) || 
               description.contains(searchQuery) || 
               location.contains(searchQuery);
      }).map((acc) {
        acc['type'] = 'accommodation';
        acc['relevance_score'] = _calculateRelevanceScore(acc, query, 'accommodation');
        return acc;
      }).toList();

      // Apply filters
      results = applyFilters(results: results, filters: filters);

      // Sort results
      _sortSearchResults(results, sortBy);

      return results.take(limit).toList();
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to search accommodations', e);
      return [];
    }
  }

  /// Search activities
  static Future<List<Map<String, dynamic>>> _searchActivities(
    String query,
    Map<String, dynamic>? filters,
    String? sortBy,
    double? latitude,
    double? longitude,
    int limit,
  ) async {
    try {
      final activities = await SupabaseDatabaseService.select(
        table: 'activities',
        filters: {'is_active': true},
        limit: limit * 2,
      );

      var results = activities.where((activity) {
        final name = (activity['name'] as String? ?? '').toLowerCase();
        final description = (activity['description'] as String? ?? '').toLowerCase();
        final location = (activity['location'] as String? ?? '').toLowerCase();
        final searchQuery = query.toLowerCase();

        return name.contains(searchQuery) || 
               description.contains(searchQuery) || 
               location.contains(searchQuery);
      }).map((activity) {
        activity['type'] = 'activity';
        activity['relevance_score'] = _calculateRelevanceScore(activity, query, 'activity');
        return activity;
      }).toList();

      // Apply filters
      results = applyFilters(results: results, filters: filters);

      // Sort results
      _sortSearchResults(results, sortBy);

      return results.take(limit).toList();
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to search activities', e);
      return [];
    }
  }

  /// Search users
  static Future<List<Map<String, dynamic>>> _searchUsers(
    String query,
    Map<String, dynamic>? filters,
    String? sortBy,
    int limit,
  ) async {
    try {
      final users = await SupabaseDatabaseService.select(
        table: 'users',
        filters: {'is_active': true},
        limit: limit * 2,
      );

      var results = users.where((user) {
        final name = (user['name'] as String? ?? '').toLowerCase();
        final username = (user['username'] as String? ?? '').toLowerCase();
        final bio = (user['bio'] as String? ?? '').toLowerCase();
        final searchQuery = query.toLowerCase();

        return name.contains(searchQuery) || 
               username.contains(searchQuery) || 
               bio.contains(searchQuery);
      }).map((user) {
        user['type'] = 'user';
        user['relevance_score'] = _calculateRelevanceScore(user, query, 'user');
        return user;
      }).toList();

      // Sort results
      _sortSearchResults(results, sortBy);

      return results.take(limit).toList();
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to search users', e);
      return [];
    }
  }

  /// Search communities
  static Future<List<Map<String, dynamic>>> _searchCommunities(
    String query,
    Map<String, dynamic>? filters,
    String? sortBy,
    int limit,
  ) async {
    try {
      final communities = await SupabaseDatabaseService.select(
        table: 'communities',
        filters: {'is_active': true},
        limit: limit * 2,
      );

      var results = communities.where((community) {
        final name = (community['name'] as String? ?? '').toLowerCase();
        final description = (community['description'] as String? ?? '').toLowerCase();
        final searchQuery = query.toLowerCase();

        return name.contains(searchQuery) || description.contains(searchQuery);
      }).map((community) {
        community['type'] = 'community';
        community['relevance_score'] = _calculateRelevanceScore(community, query, 'community');
        return community;
      }).toList();

      // Sort results
      _sortSearchResults(results, sortBy);

      return results.take(limit).toList();
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to search communities', e);
      return [];
    }
  }

  /// Search posts
  static Future<List<Map<String, dynamic>>> _searchPosts(
    String query,
    Map<String, dynamic>? filters,
    String? sortBy,
    int limit,
  ) async {
    try {
      final posts = await SupabaseDatabaseService.select(
        table: 'community_posts',
        filters: {'status': 'active'},
        limit: limit * 2,
      );

      var results = posts.where((post) {
        final title = (post['title'] as String? ?? '').toLowerCase();
        final content = (post['content'] as String? ?? '').toLowerCase();
        final searchQuery = query.toLowerCase();

        return title.contains(searchQuery) || content.contains(searchQuery);
      }).map((post) {
        post['type'] = 'post';
        post['relevance_score'] = _calculateRelevanceScore(post, query, 'post');
        return post;
      }).toList();

      // Sort results
      _sortSearchResults(results, sortBy);

      return results.take(limit).toList();
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to search posts', e);
      return [];
    }
  }

  // ===============================
  // QUICK SEARCH METHODS
  // ===============================

  /// Quick search destinations
  static Future<List<Map<String, dynamic>>> _quickSearchDestinations(String query, int limit) async {
    try {
      final destinations = await SupabaseDatabaseService.select(
        table: 'destinations',
        filters: {'is_active': true},
        limit: limit * 2,
      );

      return destinations.where((dest) {
        final name = (dest['name'] as String? ?? '').toLowerCase();
        return name.contains(query.toLowerCase());
      }).map((dest) {
        dest['type'] = 'destination';
        dest['relevance_score'] = _calculateQuickRelevanceScore(dest['name'], query);
        return dest;
      }).toList()..sort((a, b) => (b['relevance_score'] as double).compareTo(a['relevance_score'] as double));
    } catch (e) {
      return [];
    }
  }

  /// Quick search users
  static Future<List<Map<String, dynamic>>> _quickSearchUsers(String query, int limit) async {
    try {
      final users = await SupabaseDatabaseService.select(
        table: 'users',
        filters: {'is_active': true},
        limit: limit * 2,
      );

      return users.where((user) {
        final name = (user['name'] as String? ?? '').toLowerCase();
        final username = (user['username'] as String? ?? '').toLowerCase();
        final queryLower = query.toLowerCase();
        return name.contains(queryLower) || username.contains(queryLower);
      }).map((user) {
        user['type'] = 'user';
        user['relevance_score'] = _calculateQuickRelevanceScore('${user['name']} ${user['username']}', query);
        return user;
      }).toList()..sort((a, b) => (b['relevance_score'] as double).compareTo(a['relevance_score'] as double));
    } catch (e) {
      return [];
    }
  }

  /// Quick search communities
  static Future<List<Map<String, dynamic>>> _quickSearchCommunities(String query, int limit) async {
    try {
      final communities = await SupabaseDatabaseService.select(
        table: 'communities',
        filters: {'is_active': true},
        limit: limit * 2,
      );

      return communities.where((community) {
        final name = (community['name'] as String? ?? '').toLowerCase();
        return name.contains(query.toLowerCase());
      }).map((community) {
        community['type'] = 'community';
        community['relevance_score'] = _calculateQuickRelevanceScore(community['name'], query);
        return community;
      }).toList()..sort((a, b) => (b['relevance_score'] as double).compareTo(a['relevance_score'] as double));
    } catch (e) {
      return [];
    }
  }

  // ===============================
  // PRIVATE HELPER METHODS
  // ===============================

  /// Sanitize search query
  static String _sanitizeQuery(String query) {
    return query.trim()
        .replaceAll(RegExp(r'[^\w\s\-\.]'), '')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Generate cache key
  static String _generateCacheKey(
    String query,
    String category,
    Map<String, dynamic>? filters,
    String? sortBy,
    double? latitude,
    double? longitude,
  ) {
    final parts = [
      'search',
      query.replaceAll(' ', '_'),
      category,
      sortBy ?? 'relevance',
    ];

    if (filters != null && filters.isNotEmpty) {
      parts.add(filters.toString().hashCode.toString());
    }

    if (latitude != null && longitude != null) {
      parts.add('${latitude.toStringAsFixed(2)}_${longitude.toStringAsFixed(2)}');
    }

    return parts.join('_');
  }

  /// Get empty search results
  static Map<String, dynamic> _getEmptySearchResults() {
    return {
      'query': '',
      'category': categoryAll,
      'total_results': 0,
      'results': <Map<String, dynamic>>[],
      'suggestions': <String>[],
      'filters_applied': <String, dynamic>{},
      'search_time': DateTime.now().toIso8601String(),
    };
  }

  /// Calculate relevance score
  static double _calculateRelevanceScore(Map<String, dynamic> item, String query, String type) {
    double score = 0.0;
    final queryLower = query.toLowerCase();

    // Base score from name/title match
    final name = (item['name'] as String? ?? item['title'] as String? ?? '').toLowerCase();
    if (name.contains(queryLower)) {
      score += name.startsWith(queryLower) ? 1.0 : 0.7;
    }

    // Boost from description match
    final description = (item['description'] as String? ?? '').toLowerCase();
    if (description.contains(queryLower)) {
      score += 0.3;
    }

    // Type-specific scoring
    switch (type) {
      case 'destination':
      case 'accommodation':
      case 'activity':
        final rating = item['average_rating'] as double? ?? 0.0;
        score += rating * 0.1;
        break;
      case 'user':
        final followerCount = item['follower_count'] as int? ?? 0;
        score += (followerCount / 1000).clamp(0.0, 0.2);
        break;
      case 'community':
        final memberCount = item['member_count'] as int? ?? 0;
        score += (memberCount / 100).clamp(0.0, 0.2);
        break;
    }

    return score;
  }

  /// Calculate quick relevance score
  static double _calculateQuickRelevanceScore(String text, String query) {
    final textLower = text.toLowerCase();
    final queryLower = query.toLowerCase();

    if (textLower == queryLower) return 1.0;
    if (textLower.startsWith(queryLower)) return 0.9;
    if (textLower.contains(queryLower)) return 0.7;
    
    return 0.0;
  }

  /// Sort search results
  static void _sortSearchResults(List<Map<String, dynamic>> results, String? sortBy) {
    switch (sortBy) {
      case 'popularity':
        results.sort((a, b) {
          final aPopularity = a['view_count'] as int? ?? a['member_count'] as int? ?? 0;
          final bPopularity = b['view_count'] as int? ?? b['member_count'] as int? ?? 0;
          return bPopularity.compareTo(aPopularity);
        });
        break;
      case 'rating':
        results.sort((a, b) {
          final aRating = a['average_rating'] as double? ?? 0.0;
          final bRating = b['average_rating'] as double? ?? 0.0;
          return bRating.compareTo(aRating);
        });
        break;
      case 'date':
        results.sort((a, b) {
          final aDate = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime(1970);
          final bDate = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime(1970);
          return bDate.compareTo(aDate);
        });
        break;
      case 'relevance':
      default:
        results.sort((a, b) => (b['relevance_score'] as double).compareTo(a['relevance_score'] as double));
        break;
    }
  }

  /// Track search
  static Future<void> _trackSearch(
    String query,
    String category,
    Map<String, dynamic>? filters,
    String? userId,
  ) async {
    try {
      // Save to search history if user is logged in
      if (userId != null) {
        await SupabaseDatabaseService.insert(
          table: _searchHistoryTable,
          data: {
            'user_id': userId,
            'query': query,
            'category': category,
            'filters': filters ?? {},
            'searched_at': DateTime.now().toIso8601String(),
          },
        );
      }

      // Track in analytics
      await AnalyticsService.trackEvent('search_performed', {
        'query': query,
        'category': category,
        'has_filters': filters != null && filters.isNotEmpty,
        'user_id': userId,
      });
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to track search', e);
    }
  }

  /// Track search results
  static Future<void> _trackSearchResults(String query, int resultCount, String? userId) async {
    try {
      await AnalyticsService.trackEvent('search_results', {
        'query': query,
        'result_count': resultCount,
        'user_id': userId,
      });
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to track search results', e);
    }
  }

  /// Get search suggestions
  static Future<List<String>> _getSearchSuggestions(String query, String category, [int limit = 10]) async {
    try {
      // Get suggestions from database
      final suggestions = await SupabaseDatabaseService.select(
        table: _searchSuggestionsTable,
        filters: {
          'category': category,
          'is_active': true,
        },
        orderBy: 'popularity_score',
        ascending: false,
        limit: limit * 2,
      );

      final queryLower = query.toLowerCase();
      return suggestions
          .where((s) => (s['suggestion'] as String).toLowerCase().contains(queryLower))
          .map((s) => s['suggestion'] as String)
          .take(limit)
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get popular searches
  static Future<List<String>> _getPopularSearches(String category, int limit) async {
    try {
      final trending = await getTrendingSearches(category: category, limit: limit);
      return trending.map((t) => t['query'] as String).toList();
    } catch (e) {
      return [];
    }
  }

  // Filter application methods
  static List<Map<String, dynamic>> _applyLocationFilter(
    List<Map<String, dynamic>> results,
    Map<String, dynamic> location,
  ) {
    // Implement location-based filtering
    return results;
  }

  static List<Map<String, dynamic>> _applyPriceFilter(
    List<Map<String, dynamic>> results,
    Map<String, dynamic> priceRange,
  ) {
    final minPrice = priceRange['min'] as double?;
    final maxPrice = priceRange['max'] as double?;

    return results.where((result) {
      final price = result['price'] as double?;
      if (price == null) return true;
      
      if (minPrice != null && price < minPrice) return false;
      if (maxPrice != null && price > maxPrice) return false;
      
      return true;
    }).toList();
  }

  static List<Map<String, dynamic>> _applyRatingFilter(
    List<Map<String, dynamic>> results,
    double minRating,
  ) {
    return results.where((result) {
      final rating = result['average_rating'] as double? ?? 0.0;
      return rating >= minRating;
    }).toList();
  }

  static List<Map<String, dynamic>> _applyDateFilter(
    List<Map<String, dynamic>> results,
    Map<String, dynamic> dateRange,
  ) {
    // Implement date-based filtering
    return results;
  }

  static List<Map<String, dynamic>> _applyCategoryFilter(
    List<Map<String, dynamic>> results,
    List<String> categories,
  ) {
    return results.where((result) {
      final category = result['category'] as String?;
      return category != null && categories.contains(category);
    }).toList();
  }

  static List<Map<String, dynamic>> _applyTagsFilter(
    List<Map<String, dynamic>> results,
    List<String> tags,
  ) {
    return results.where((result) {
      final resultTags = List<String>.from(result['tags'] ?? []);
      return tags.any((tag) => resultTags.contains(tag));
    }).toList();
  }
}
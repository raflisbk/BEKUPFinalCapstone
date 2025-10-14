import 'dart:async';
import 'dart:convert';
import '../../core/utils/logger.dart';
import '../supabase_config.dart';
import '../supabase_database_service.dart';
import '../cache_service.dart';
import 'gemini_service.dart';

/// AI Recommendation Service
/// Provides personalized recommendations using AI analysis of user behavior and preferences
class AIRecommendationService {
  static const String _tag = 'AIRecommendationService';
  static const String _recommendationsTable = 'ai_recommendations';
  static const String _userPreferencesTable = 'user_preferences';
  static const String _userBehaviorTable = 'user_behavior_analytics';
  static const String _recommendationFeedbackTable = 'recommendation_feedback';

  // Recommendation types
  static const String typeDestination = 'destination';
  static const String typeActivity = 'activity';
  static const String typeAccommodation = 'accommodation';
  static const String typeRestaurant = 'restaurant';
  static const String typeBudget = 'budget';
  static const String typeTrip = 'trip';

  // Recommendation sources
  static const String sourceAI = 'ai_generated';
  static const String sourceCollaborative = 'collaborative_filtering';
  static const String sourceContentBased = 'content_based';
  static const String sourceHybrid = 'hybrid';

  // Confidence levels
  static const String confidenceHigh = 'high';
  static const String confidenceMedium = 'medium';
  static const String confidenceLow = 'low';

  // ===============================
  // PERSONALIZED RECOMMENDATIONS
  // ===============================

  /// Get personalized recommendations for user
  static Future<List<Map<String, dynamic>>> getPersonalizedRecommendations({
    String? userId,
    String? recommendationType,
    Map<String, dynamic>? context,
    int limit = 10,
    bool forceRefresh = false,
  }) async {
    try {
      final targetUserId = userId ?? SupabaseConfig.userId;
      if (targetUserId == null) {
        throw Exception('No user ID provided');
      }

      AppLogger.debug(_tag, 'Getting personalized recommendations for user: $targetUserId');

      // Check cache first
      final cacheKey = 'recommendations_${targetUserId}_${recommendationType ?? 'all'}';
      if (!forceRefresh) {
        final cached = await CacheService.get<List<dynamic>>(cacheKey);
        if (cached != null) {
          AppLogger.debug(_tag, 'Returning cached recommendations');
          return cached.cast<Map<String, dynamic>>();
        }
      }

      // Get user profile and behavior
      final userProfile = await _getUserProfile(targetUserId);
      final userBehavior = await _getUserBehavior(targetUserId);
      final userPreferences = await _getUserPreferences(targetUserId);

      // Generate AI recommendations
      final aiRecommendations = await _generateAIRecommendations(
        targetUserId,
        userProfile,
        userBehavior,
        userPreferences,
        recommendationType,
        context,
        limit,
      );

      // Enhance with collaborative filtering
      final enhancedRecommendations = await _enhanceWithCollaborativeFiltering(
        aiRecommendations,
        targetUserId,
        userProfile,
      );

      // Rank and filter results
      final finalRecommendations = await _rankAndFilterRecommendations(
        enhancedRecommendations,
        userPreferences,
        limit,
      );

      // Cache results
      await CacheService.set(
        cacheKey,
        finalRecommendations,
        duration: const Duration(hours: 6),
        category: 'recommendations',
      );

      // Store recommendations in database
      await _storeRecommendations(targetUserId, finalRecommendations);

      AppLogger.success(_tag, 'Generated ${finalRecommendations.length} personalized recommendations');
      return finalRecommendations;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get personalized recommendations', e, stackTrace);
      return [];
    }
  }

  /// Get destination recommendations
  static Future<List<Map<String, dynamic>>> getDestinationRecommendations({
    String? userId,
    String? currentLocation,
    double? budget,
    List<String>? interests,
    String? travelStyle,
    int limit = 5,
  }) async {
    try {
      AppLogger.debug(_tag, 'Getting destination recommendations');

      final context = {
        'type': typeDestination,
        'current_location': currentLocation,
        'budget': budget,
        'interests': interests,
        'travel_style': travelStyle,
      };

      return await getPersonalizedRecommendations(
        userId: userId,
        recommendationType: typeDestination,
        context: context,
        limit: limit,
      );
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get destination recommendations', e, stackTrace);
      return [];
    }
  }

  /// Get activity recommendations
  static Future<List<Map<String, dynamic>>> getActivityRecommendations({
    String? userId,
    required String destination,
    DateTime? date,
    String? weather,
    double? budget,
    int limit = 8,
  }) async {
    try {
      AppLogger.debug(_tag, 'Getting activity recommendations for: $destination');

      final context = {
        'type': typeActivity,
        'destination': destination,
        'date': date?.toIso8601String(),
        'weather': weather,
        'budget': budget,
      };

      return await getPersonalizedRecommendations(
        userId: userId,
        recommendationType: typeActivity,
        context: context,
        limit: limit,
      );
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get activity recommendations', e, stackTrace);
      return [];
    }
  }

  /// Get restaurant recommendations
  static Future<List<Map<String, dynamic>>> getRestaurantRecommendations({
    String? userId,
    required String location,
    String? cuisine,
    String? priceRange,
    List<String>? dietaryRestrictions,
    int limit = 6,
  }) async {
    try {
      AppLogger.debug(_tag, 'Getting restaurant recommendations for: $location');

      final context = {
        'type': typeRestaurant,
        'location': location,
        'cuisine': cuisine,
        'price_range': priceRange,
        'dietary_restrictions': dietaryRestrictions,
      };

      return await getPersonalizedRecommendations(
        userId: userId,
        recommendationType: typeRestaurant,
        context: context,
        limit: limit,
      );
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get restaurant recommendations', e, stackTrace);
      return [];
    }
  }

  /// Get accommodation recommendations
  static Future<List<Map<String, dynamic>>> getAccommodationRecommendations({
    String? userId,
    required String destination,
    DateTime? checkIn,
    DateTime? checkOut,
    int guests = 1,
    double? budget,
    List<String>? amenities,
    int limit = 5,
  }) async {
    try {
      AppLogger.debug(_tag, 'Getting accommodation recommendations for: $destination');

      final context = {
        'type': typeAccommodation,
        'destination': destination,
        'check_in': checkIn?.toIso8601String(),
        'check_out': checkOut?.toIso8601String(),
        'guests': guests,
        'budget': budget,
        'amenities': amenities,
      };

      return await getPersonalizedRecommendations(
        userId: userId,
        recommendationType: typeAccommodation,
        context: context,
        limit: limit,
      );
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get accommodation recommendations', e, stackTrace);
      return [];
    }
  }

  // ===============================
  // SMART SUGGESTIONS
  // ===============================

  /// Get smart trip suggestions based on user history
  static Future<List<Map<String, dynamic>>> getSmartTripSuggestions([String? userId]) async {
    try {
      final targetUserId = userId ?? SupabaseConfig.userId;
      if (targetUserId == null) {
        throw Exception('No user ID provided');
      }

      AppLogger.debug(_tag, 'Getting smart trip suggestions');

      // Analyze user's travel history
      final travelHistory = await _getTravelHistory(targetUserId);
      final preferences = await _getUserPreferences(targetUserId);

      // Generate AI suggestions
      final prompt = _buildTripSuggestionPrompt(travelHistory, preferences);
      
      final aiResponse = await GeminiService.generateContent(
        prompt: prompt,
        model: GeminiService.modelFlash,
        temperature: 0.8,
        maxOutputTokens: 2048,
      );

      // Parse suggestions
      final suggestions = _parseAISuggestions(aiResponse, typeTrip);

      AppLogger.success(_tag, 'Generated ${suggestions.length} smart trip suggestions');
      return suggestions;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get smart trip suggestions', e, stackTrace);
      return [];
    }
  }

  /// Get budget optimization suggestions
  static Future<Map<String, dynamic>> getBudgetOptimizationSuggestions({
    required double currentBudget,
    required String destination,
    required int duration,
    String? travelStyle,
  }) async {
    try {
      AppLogger.debug(_tag, 'Getting budget optimization suggestions');

      final prompt = _buildBudgetOptimizationPrompt(
        currentBudget,
        destination,
        duration,
        travelStyle,
      );

      final aiResponse = await GeminiService.generateContent(
        prompt: prompt,
        model: GeminiService.modelFlash,
        temperature: 0.7,
        maxOutputTokens: 1024,
      );

      final optimization = _parseBudgetOptimization(aiResponse);

      AppLogger.success(_tag, 'Generated budget optimization suggestions');
      return optimization;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get budget optimization suggestions', e, stackTrace);
      return {};
    }
  }

  // ===============================
  // FEEDBACK & LEARNING
  // ===============================

  /// Submit recommendation feedback
  static Future<void> submitRecommendationFeedback({
    required String recommendationId,
    required String action, // 'liked', 'disliked', 'clicked', 'ignored', 'booked'
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Submitting recommendation feedback');

      final feedbackData = {
        'recommendation_id': recommendationId,
        'user_id': userId,
        'action': action,
        'metadata': metadata ?? {},
        'created_at': DateTime.now().toIso8601String(),
      };

      await SupabaseDatabaseService.insert(
        table: _recommendationFeedbackTable,
        data: feedbackData,
      );

      // Update user preferences based on feedback
      await _updateUserPreferencesFromFeedback(userId, action, metadata);

      AppLogger.success(_tag, 'Recommendation feedback submitted');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to submit recommendation feedback', e, stackTrace);
    }
  }

  /// Get recommendation analytics
  static Future<Map<String, dynamic>> getRecommendationAnalytics([String? userId]) async {
    try {
      final targetUserId = userId ?? SupabaseConfig.userId;
      if (targetUserId == null) {
        throw Exception('No user ID provided');
      }

      AppLogger.debug(_tag, 'Getting recommendation analytics');

      final recommendations = await SupabaseDatabaseService.select(
        table: _recommendationsTable,
        filters: {'user_id': targetUserId},
      );

      final feedback = await SupabaseDatabaseService.select(
        table: _recommendationFeedbackTable,
        filters: {'user_id': targetUserId},
      );

      final analytics = {
        'total_recommendations': recommendations.length,
        'total_feedback': feedback.length,
        'engagement_rate': _calculateEngagementRate(recommendations, feedback),
        'recommendation_types': _getRecommendationTypeDistribution(recommendations),
        'feedback_distribution': _getFeedbackDistribution(feedback),
        'average_confidence': _calculateAverageConfidence(recommendations),
        'top_categories': _getTopCategories(recommendations),
      };

      AppLogger.success(_tag, 'Recommendation analytics generated');
      return analytics;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get recommendation analytics', e, stackTrace);
      return {};
    }
  }

  // ===============================
  // PRIVATE HELPER METHODS
  // ===============================

  /// Get user profile data
  static Future<Map<String, dynamic>> _getUserProfile(String userId) async {
    try {
      final users = await SupabaseDatabaseService.select(
        table: 'users',
        filters: {'id': userId},
      );

      return users.isNotEmpty ? users.first : {};
    } catch (e) {
      return {};
    }
  }

  /// Get user behavior analytics
  static Future<Map<String, dynamic>> _getUserBehavior(String userId) async {
    try {
      final behavior = await SupabaseDatabaseService.select(
        table: _userBehaviorTable,
        filters: {'user_id': userId},
        orderBy: 'created_at',
        ascending: false,
        limit: 100,
      );

      return _analyzeBehaviorPatterns(behavior);
    } catch (e) {
      return {};
    }
  }

  /// Get user preferences
  static Future<Map<String, dynamic>> _getUserPreferences(String userId) async {
    try {
      final preferences = await SupabaseDatabaseService.select(
        table: _userPreferencesTable,
        filters: {'user_id': userId},
      );

      return preferences.isNotEmpty ? preferences.first : {};
    } catch (e) {
      return {};
    }
  }

  /// Generate AI recommendations
  static Future<List<Map<String, dynamic>>> _generateAIRecommendations(
    String userId,
    Map<String, dynamic> userProfile,
    Map<String, dynamic> userBehavior,
    Map<String, dynamic> userPreferences,
    String? recommendationType,
    Map<String, dynamic>? context,
    int limit,
  ) async {
    try {
      final prompt = _buildRecommendationPrompt(
        userProfile,
        userBehavior,
        userPreferences,
        recommendationType,
        context,
        limit,
      );

      final aiResponse = await GeminiService.generateContent(
        prompt: prompt,
        model: GeminiService.modelPro,
        temperature: 0.7,
        maxOutputTokens: 4096,
      );

      return _parseAIRecommendations(aiResponse, recommendationType);
    } catch (e) {
      AppLogger.warning(_tag, 'AI recommendation generation failed', e);
      return [];
    }
  }

  /// Build recommendation prompt
  static String _buildRecommendationPrompt(
    Map<String, dynamic> userProfile,
    Map<String, dynamic> userBehavior,
    Map<String, dynamic> userPreferences,
    String? recommendationType,
    Map<String, dynamic>? context,
    int limit,
  ) {
    return '''
Generate personalized travel recommendations based on user profile and behavior.

**USER PROFILE:**
${jsonEncode(userProfile)}

**USER BEHAVIOR PATTERNS:**
${jsonEncode(userBehavior)}

**USER PREFERENCES:**
${jsonEncode(userPreferences)}

**RECOMMENDATION TYPE:** ${recommendationType ?? 'general'}

**CONTEXT:**
${jsonEncode(context ?? {})}

**REQUIREMENTS:**
- Generate $limit high-quality recommendations
- Consider user's past preferences and behavior
- Include confidence score (0.0-1.0) for each recommendation
- Provide detailed reasoning for each suggestion
- Consider budget constraints and practical factors

**OUTPUT FORMAT (JSON):**
{
  "recommendations": [
    {
      "id": "unique_id",
      "type": "recommendation_type",
      "title": "Recommendation title",
      "description": "Detailed description",
      "confidence": 0.85,
      "reasoning": "Why this is recommended for the user",
      "metadata": {
        "location": "Location if applicable",
        "price_range": "Budget estimate",
        "category": "Category",
        "tags": ["tag1", "tag2"],
        "rating": 4.5,
        "image_url": "https://example.com/image.jpg"
      },
      "action_url": "Deep link or booking URL"
    }
  ]
}

Provide only the JSON response, no additional text.
''';
  }

  /// Parse AI recommendations
  static List<Map<String, dynamic>> _parseAIRecommendations(
    String aiResponse,
    String? recommendationType,
  ) {
    try {
      final jsonStart = aiResponse.indexOf('{');
      final jsonEnd = aiResponse.lastIndexOf('}') + 1;
      
      if (jsonStart >= 0 && jsonEnd > jsonStart) {
        final jsonString = aiResponse.substring(jsonStart, jsonEnd);
        final parsed = jsonDecode(jsonString) as Map<String, dynamic>;
        final recommendations = parsed['recommendations'] as List? ?? [];
        
        return recommendations.map((rec) {
          final recommendation = rec as Map<String, dynamic>;
          // Add system metadata
          recommendation['source'] = sourceAI;
          recommendation['generated_at'] = DateTime.now().toIso8601String();
          recommendation['recommendation_type'] = recommendationType;
          
          return recommendation;
        }).toList();
      }
      
      return [];
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to parse AI recommendations', e);
      return [];
    }
  }

  /// Enhance with collaborative filtering
  static Future<List<Map<String, dynamic>>> _enhanceWithCollaborativeFiltering(
    List<Map<String, dynamic>> aiRecommendations,
    String userId,
    Map<String, dynamic> userProfile,
  ) async {
    try {
      // Find similar users based on preferences and behavior
      final similarUsers = await _findSimilarUsers(userId, userProfile);
      
      // Get recommendations that similar users liked
      final collaborativeRecs = await _getCollaborativeRecommendations(similarUsers);
      
      // Merge and enhance recommendations
      final enhancedRecs = [...aiRecommendations];
      
      for (final colabRec in collaborativeRecs) {
        // Boost confidence if recommended by similar users
        final existing = enhancedRecs.where(
          (rec) => rec['title'] == colabRec['title'],
        ).firstOrNull;
        
        if (existing != null) {
          final currentConfidence = existing['confidence'] as double? ?? 0.5;
          existing['confidence'] = (currentConfidence + 0.2).clamp(0.0, 1.0);
          existing['source'] = sourceHybrid;
        } else if (enhancedRecs.length < 20) {
          colabRec['source'] = sourceCollaborative;
          enhancedRecs.add(colabRec);
        }
      }
      
      return enhancedRecs;
    } catch (e) {
      AppLogger.warning(_tag, 'Collaborative filtering enhancement failed', e);
      return aiRecommendations;
    }
  }

  /// Rank and filter recommendations
  static Future<List<Map<String, dynamic>>> _rankAndFilterRecommendations(
    List<Map<String, dynamic>> recommendations,
    Map<String, dynamic> userPreferences,
    int limit,
  ) async {
    try {
      // Filter out already seen/disliked recommendations
      final filtered = recommendations.where((rec) {
        // Add filtering logic based on user history
        return true; // Placeholder
      }).toList();
      
      // Sort by confidence score and user preference alignment
      filtered.sort((a, b) {
        final confidenceA = a['confidence'] as double? ?? 0.0;
        final confidenceB = b['confidence'] as double? ?? 0.0;
        
        // Add preference alignment scoring
        final alignmentA = _calculatePreferenceAlignment(a, userPreferences);
        final alignmentB = _calculatePreferenceAlignment(b, userPreferences);
        
        final scoreA = (confidenceA * 0.7) + (alignmentA * 0.3);
        final scoreB = (confidenceB * 0.7) + (alignmentB * 0.3);
        
        return scoreB.compareTo(scoreA);
      });
      
      return filtered.take(limit).toList();
    } catch (e) {
      AppLogger.warning(_tag, 'Recommendation ranking failed', e);
      return recommendations.take(limit).toList();
    }
  }

  /// Store recommendations in database
  static Future<void> _storeRecommendations(
    String userId,
    List<Map<String, dynamic>> recommendations,
  ) async {
    try {
      for (final rec in recommendations) {
        final recommendationData = {
          'user_id': userId,
          'recommendation_type': rec['type'],
          'title': rec['title'],
          'description': rec['description'],
          'confidence': rec['confidence'],
          'reasoning': rec['reasoning'],
          'metadata': rec['metadata'],
          'source': rec['source'],
          'generated_at': rec['generated_at'],
          'is_active': true,
          'created_at': DateTime.now().toIso8601String(),
        };

        await SupabaseDatabaseService.insert(
          table: _recommendationsTable,
          data: recommendationData,
        );
      }
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to store recommendations', e);
    }
  }

  /// Other helper methods would go here...
  /// (Continuing with remaining methods to keep file length manageable)

  /// Analyze behavior patterns
  static Map<String, dynamic> _analyzeBehaviorPatterns(List<Map<String, dynamic>> behavior) {
    // Placeholder implementation
    return {
      'frequent_activities': ['sightseeing', 'food_tours'],
      'preferred_times': ['morning', 'afternoon'],
      'budget_range': 'medium',
      'travel_frequency': 'monthly',
    };
  }

  /// Calculate preference alignment
  static double _calculatePreferenceAlignment(
    Map<String, dynamic> recommendation,
    Map<String, dynamic> userPreferences,
  ) {
    // Placeholder implementation
    return 0.7; // Default alignment score
  }

  /// Find similar users
  static Future<List<String>> _findSimilarUsers(
    String userId,
    Map<String, dynamic> userProfile,
  ) async {
    // Placeholder implementation
    return [];
  }

  /// Get collaborative recommendations
  static Future<List<Map<String, dynamic>>> _getCollaborativeRecommendations(
    List<String> similarUsers,
  ) async {
    // Placeholder implementation
    return [];
  }

  /// Build trip suggestion prompt
  static String _buildTripSuggestionPrompt(
    Map<String, dynamic> travelHistory,
    Map<String, dynamic> preferences,
  ) {
    return '''
Based on user's travel history and preferences, suggest 5 new trip ideas.

**TRAVEL HISTORY:**
${jsonEncode(travelHistory)}

**PREFERENCES:**
${jsonEncode(preferences)}

Generate diverse, personalized trip suggestions in JSON format.
''';
  }

  /// Build budget optimization prompt
  static String _buildBudgetOptimizationPrompt(
    double currentBudget,
    String destination,
    int duration,
    String? travelStyle,
  ) {
    return '''
Optimize budget allocation for:
- Destination: $destination
- Duration: $duration days  
- Budget: Rp ${(currentBudget / 1000000).toStringAsFixed(1)} million
- Style: ${travelStyle ?? 'flexible'}

Provide budget optimization suggestions in JSON format.
''';
  }

  /// Parse AI suggestions
  static List<Map<String, dynamic>> _parseAISuggestions(String aiResponse, String type) {
    // Placeholder implementation
    return [];
  }

  /// Parse budget optimization
  static Map<String, dynamic> _parseBudgetOptimization(String aiResponse) {
    // Placeholder implementation
    return {};
  }

  /// Get travel history
  static Future<Map<String, dynamic>> _getTravelHistory(String userId) async {
    // Placeholder implementation
    return {};
  }

  /// Update user preferences from feedback
  static Future<void> _updateUserPreferencesFromFeedback(
    String userId,
    String action,
    Map<String, dynamic>? metadata,
  ) async {
    // Placeholder implementation
  }

  /// Calculate engagement rate
  static double _calculateEngagementRate(
    List<Map<String, dynamic>> recommendations,
    List<Map<String, dynamic>> feedback,
  ) {
    if (recommendations.isEmpty) return 0.0;
    return feedback.length / recommendations.length;
  }

  /// Get recommendation type distribution
  static Map<String, int> _getRecommendationTypeDistribution(
    List<Map<String, dynamic>> recommendations,
  ) {
    final distribution = <String, int>{};
    for (final rec in recommendations) {
      final type = rec['recommendation_type'] as String? ?? 'unknown';
      distribution[type] = (distribution[type] ?? 0) + 1;
    }
    return distribution;
  }

  /// Get feedback distribution
  static Map<String, int> _getFeedbackDistribution(
    List<Map<String, dynamic>> feedback,
  ) {
    final distribution = <String, int>{};
    for (final fb in feedback) {
      final action = fb['action'] as String? ?? 'unknown';
      distribution[action] = (distribution[action] ?? 0) + 1;
    }
    return distribution;
  }

  /// Calculate average confidence
  static double _calculateAverageConfidence(List<Map<String, dynamic>> recommendations) {
    if (recommendations.isEmpty) return 0.0;
    
    final total = recommendations.fold<double>(0, (sum, rec) {
      return sum + (rec['confidence'] as double? ?? 0.0);
    });
    
    return total / recommendations.length;
  }

  /// Get top categories
  static List<String> _getTopCategories(List<Map<String, dynamic>> recommendations) {
    final categories = <String, int>{};
    
    for (final rec in recommendations) {
      final metadata = rec['metadata'] as Map<String, dynamic>? ?? {};
      final category = metadata['category'] as String? ?? 'unknown';
      categories[category] = (categories[category] ?? 0) + 1;
    }
    
    final sorted = categories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sorted.take(5).map((e) => e.key).toList();
  }
}
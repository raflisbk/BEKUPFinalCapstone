import 'dart:async';
import 'dart:convert';
import '../../core/utils/logger.dart';
import '../supabase_config.dart';
import '../supabase_database_service.dart';
import 'gemini_service.dart';

/// AI Itinerary Service
/// Handles AI-powered trip planning and itinerary generation using Gemini AI
class AIItineraryService {
  static const String _tag = 'AIItineraryService';
  static const String _itineraryTable = 'ai_itineraries';
  static const String _itineraryRequestsTable = 'ai_itinerary_requests';
  static const String _itineraryFeedbackTable = 'ai_itinerary_feedback';

  // Generation types
  static const String typeQuick = 'quick';
  static const String typeDetailed = 'detailed';
  static const String typeCustom = 'custom';

  // Trip styles
  static const String styleAdventure = 'adventure';
  static const String styleCultural = 'cultural';
  static const String styleRelaxation = 'relaxation';
  static const String styleBudget = 'budget';
  static const String styleLuxury = 'luxury';
  static const String styleFamily = 'family';
  static const String styleSolo = 'solo';
  static const String styleRomantic = 'romantic';

  // Status
  static const String statusGenerating = 'generating';
  static const String statusCompleted = 'completed';
  static const String statusFailed = 'failed';

  // ===============================
  // AI ITINERARY GENERATION
  // ===============================

  /// Generate comprehensive AI itinerary
  static Future<Map<String, dynamic>> generateItinerary({
    required String destination,
    required DateTime startDate,
    required DateTime endDate,
    required double budget,
    required String tripStyle,
    String generationType = typeDetailed,
    List<String>? interests,
    List<String>? activities,
    Map<String, dynamic>? preferences,
    int groupSize = 1,
  }) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Generating AI itinerary for: $destination');

      final duration = endDate.difference(startDate).inDays;
      if (duration <= 0) {
        throw Exception('Invalid date range');
      }

      // Create request record
      final requestData = {
        'user_id': userId,
        'destination': destination,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        'duration_days': duration,
        'budget': budget,
        'trip_style': tripStyle,
        'generation_type': generationType,
        'group_size': groupSize,
        'interests': interests ?? [],
        'activities': activities ?? [],
        'preferences': preferences ?? {},
        'status': statusGenerating,
        'created_at': DateTime.now().toIso8601String(),
      };

      final request = await SupabaseDatabaseService.insert(
        table: _itineraryRequestsTable,
        data: requestData,
      );

      try {
        // Generate itinerary using AI
        final itinerary = await _generateAIItinerary(
          request['id'],
          destination,
          startDate,
          endDate,
          budget,
          tripStyle,
          generationType,
          interests: interests,
          activities: activities,
          preferences: preferences,
          groupSize: groupSize,
        );

        // Update request status
        await SupabaseDatabaseService.update(
          table: _itineraryRequestsTable,
          id: request['id'],
          data: {
            'status': statusCompleted,
            'completed_at': DateTime.now().toIso8601String(),
          },
        );

        AppLogger.success(_tag, 'AI itinerary generated successfully');
        return itinerary;
      } catch (e) {
        // Update request status as failed
        await SupabaseDatabaseService.update(
          table: _itineraryRequestsTable,
          id: request['id'],
          data: {
            'status': statusFailed,
            'error': e.toString(),
            'failed_at': DateTime.now().toIso8601String(),
          },
        );
        rethrow;
      }
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to generate AI itinerary', e, stackTrace);
      rethrow;
    }
  }

  /// Generate quick itinerary for day trip
  static Future<Map<String, dynamic>> generateQuickItinerary({
    required String destination,
    required DateTime date,
    required String tripStyle,
    double? budget,
    List<String>? interests,
  }) async {
    try {
      AppLogger.debug(_tag, 'Generating quick itinerary for: $destination');

      return await generateItinerary(
        destination: destination,
        startDate: date,
        endDate: date.add(const Duration(days: 1)),
        budget: budget ?? 500000, // Default budget
        tripStyle: tripStyle,
        generationType: typeQuick,
        interests: interests,
      );
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to generate quick itinerary', e, stackTrace);
      rethrow;
    }
  }

  /// Optimize existing itinerary
  static Future<Map<String, dynamic>> optimizeItinerary({
    required String itineraryId,
    Map<String, dynamic>? constraints,
    List<String>? feedback,
  }) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Optimizing itinerary: $itineraryId');

      // Get existing itinerary
      final itineraries = await SupabaseDatabaseService.select(
        table: _itineraryTable,
        filters: {'id': itineraryId, 'user_id': userId},
      );

      if (itineraries.isEmpty) {
        throw Exception('Itinerary not found');
      }

      final existingItinerary = itineraries.first;
      
      // Generate optimization prompt
      final optimizationPrompt = _buildOptimizationPrompt(
        existingItinerary,
        constraints,
        feedback,
      );

      // Get AI optimization suggestions
      final optimizationSuggestions = await GeminiService.generateContent(
        prompt: optimizationPrompt,
        model: GeminiService.modelPro,
        temperature: 0.8,
        maxOutputTokens: 4096,
      );

      // Parse and apply optimizations
      final optimizedItinerary = await _applyOptimizations(
        existingItinerary,
        optimizationSuggestions,
      );

      // Create new optimized version
      final optimizedData = {
        ...existingItinerary,
        'id': null, // Will get new ID
        'version': (existingItinerary['version'] as int? ?? 1) + 1,
        'parent_itinerary_id': itineraryId,
        'optimization_notes': optimizationSuggestions,
        'itinerary_data': optimizedItinerary,
        'is_optimized': true,
        'created_at': DateTime.now().toIso8601String(),
      };

      final result = await SupabaseDatabaseService.insert(
        table: _itineraryTable,
        data: optimizedData,
      );

      AppLogger.success(_tag, 'Itinerary optimized successfully');
      return result;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to optimize itinerary', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // ITINERARY MANAGEMENT
  // ===============================

  /// Get user's AI itineraries
  static Future<List<Map<String, dynamic>>> getUserItineraries({
    String? userId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final targetUserId = userId ?? SupabaseConfig.userId;
      if (targetUserId == null) {
        throw Exception('No user ID provided');
      }

      AppLogger.debug(_tag, 'Getting user itineraries');

      final itineraries = await SupabaseDatabaseService.select(
        table: _itineraryTable,
        filters: {'user_id': targetUserId},
        orderBy: 'created_at',
        ascending: false,
        limit: limit,
        offset: offset,
      );

      // Enrich with additional data
      for (final itinerary in itineraries) {
        await _enrichItineraryData(itinerary);
      }

      AppLogger.success(_tag, 'Retrieved ${itineraries.length} itineraries');
      return itineraries;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get user itineraries', e, stackTrace);
      return [];
    }
  }

  /// Get itinerary by ID
  static Future<Map<String, dynamic>?> getItinerary(String itineraryId) async {
    try {
      AppLogger.debug(_tag, 'Getting itinerary: $itineraryId');

      final itineraries = await SupabaseDatabaseService.select(
        table: _itineraryTable,
        filters: {'id': itineraryId},
      );

      if (itineraries.isEmpty) {
        AppLogger.warning(_tag, 'Itinerary not found: $itineraryId');
        return null;
      }

      final itinerary = itineraries.first;
      await _enrichItineraryData(itinerary);

      AppLogger.success(_tag, 'Retrieved itinerary: ${itinerary['destination']}');
      return itinerary;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get itinerary', e, stackTrace);
      return null;
    }
  }

  /// Update itinerary
  static Future<Map<String, dynamic>> updateItinerary({
    required String itineraryId,
    Map<String, dynamic>? itineraryData,
    Map<String, dynamic>? preferences,
    String? notes,
  }) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Updating itinerary: $itineraryId');

      // Verify ownership
      final itineraries = await SupabaseDatabaseService.select(
        table: _itineraryTable,
        filters: {'id': itineraryId, 'user_id': userId},
      );

      if (itineraries.isEmpty) {
        throw Exception('Itinerary not found or not owned by user');
      }

      final updateData = <String, dynamic>{};
      
      if (itineraryData != null) updateData['itinerary_data'] = itineraryData;
      if (preferences != null) updateData['preferences'] = preferences;
      if (notes != null) updateData['notes'] = notes;

      if (updateData.isEmpty) {
        throw Exception('No data provided for update');
      }

      updateData['updated_at'] = DateTime.now().toIso8601String();

      final result = await SupabaseDatabaseService.update(
        table: _itineraryTable,
        id: itineraryId,
        data: updateData,
      );

      AppLogger.success(_tag, 'Itinerary updated successfully');
      return result;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to update itinerary', e, stackTrace);
      rethrow;
    }
  }

  /// Delete itinerary
  static Future<void> deleteItinerary(String itineraryId) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Deleting itinerary: $itineraryId');

      // Verify ownership
      final itineraries = await SupabaseDatabaseService.select(
        table: _itineraryTable,
        filters: {'id': itineraryId, 'user_id': userId},
      );

      if (itineraries.isEmpty) {
        throw Exception('Itinerary not found or not owned by user');
      }

      await SupabaseDatabaseService.delete(
        table: _itineraryTable,
        id: itineraryId,
      );

      AppLogger.success(_tag, 'Itinerary deleted successfully');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to delete itinerary', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // FEEDBACK & IMPROVEMENT
  // ===============================

  /// Submit itinerary feedback
  static Future<void> submitFeedback({
    required String itineraryId,
    required int rating,
    required String feedback,
    List<String>? improvementSuggestions,
  }) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Submitting itinerary feedback');

      final feedbackData = {
        'itinerary_id': itineraryId,
        'user_id': userId,
        'rating': rating,
        'feedback': feedback,
        'improvement_suggestions': improvementSuggestions ?? [],
        'created_at': DateTime.now().toIso8601String(),
      };

      await SupabaseDatabaseService.insert(
        table: _itineraryFeedbackTable,
        data: feedbackData,
      );

      AppLogger.success(_tag, 'Feedback submitted successfully');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to submit feedback', e, stackTrace);
      rethrow;
    }
  }

  /// Get itinerary statistics
  static Future<Map<String, dynamic>> getItineraryStatistics([String? userId]) async {
    try {
      final targetUserId = userId ?? SupabaseConfig.userId;
      if (targetUserId == null) {
        throw Exception('No user ID provided');
      }

      AppLogger.debug(_tag, 'Getting itinerary statistics');

      final itineraries = await SupabaseDatabaseService.select(
        table: _itineraryTable,
        filters: {'user_id': targetUserId},
      );

      final requests = await SupabaseDatabaseService.select(
        table: _itineraryRequestsTable,
        filters: {'user_id': targetUserId},
      );

      final feedback = await SupabaseDatabaseService.select(
        table: _itineraryFeedbackTable,
        filters: {'user_id': targetUserId},
      );

      final statistics = {
        'total_itineraries': itineraries.length,
        'completed_requests': requests.where((r) => r['status'] == statusCompleted).length,
        'failed_requests': requests.where((r) => r['status'] == statusFailed).length,
        'average_rating': _calculateAverageRating(feedback),
        'popular_destinations': _getPopularDestinations(itineraries),
        'popular_trip_styles': _getPopularTripStyles(itineraries),
        'total_feedback': feedback.length,
        'optimization_count': itineraries.where((i) => i['is_optimized'] == true).length,
      };

      AppLogger.success(_tag, 'Itinerary statistics retrieved');
      return statistics;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get statistics', e, stackTrace);
      return {};
    }
  }

  // ===============================
  // PRIVATE HELPER METHODS
  // ===============================

  /// Generate AI itinerary using Gemini
  static Future<Map<String, dynamic>> _generateAIItinerary(
    String requestId,
    String destination,
    DateTime startDate,
    DateTime endDate,
    double budget,
    String tripStyle,
    String generationType,
    {
      List<String>? interests,
      List<String>? activities,
      Map<String, dynamic>? preferences,
      int groupSize = 1,
    }
  ) async {
    try {
      AppLogger.debug(_tag, 'Generating AI itinerary with Gemini');

      // Get destination data
      final destinationData = await _getDestinationContext(destination);
      
      // Get weather data
      final weatherData = await _getWeatherContext(destination, startDate, endDate);
      
      // Build comprehensive prompt
      final prompt = _buildItineraryPrompt(
        destination,
        startDate,
        endDate,
        budget,
        tripStyle,
        generationType,
        destinationData,
        weatherData,
        interests: interests,
        activities: activities,
        preferences: preferences,
        groupSize: groupSize,
      );

      // Generate itinerary with Gemini
      final aiResponse = await GeminiService.generateContent(
        prompt: prompt,
        model: GeminiService.modelPro,
        temperature: 0.8,
        maxOutputTokens: 8192,
      );

      // Parse AI response
      final parsedItinerary = _parseAIResponse(aiResponse);

      // Create itinerary record
      final itineraryData = {
        'request_id': requestId,
        'user_id': SupabaseConfig.userId,
        'destination': destination,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        'duration_days': endDate.difference(startDate).inDays,
        'budget': budget,
        'trip_style': tripStyle,
        'generation_type': generationType,
        'group_size': groupSize,
        'interests': interests ?? [],
        'activities': activities ?? [],
        'preferences': preferences ?? {},
        'itinerary_data': parsedItinerary,
        'ai_response': aiResponse,
        'weather_data': weatherData,
        'destination_context': destinationData,
        'version': 1,
        'is_optimized': false,
        'status': statusCompleted,
        'created_at': DateTime.now().toIso8601String(),
      };

      final result = await SupabaseDatabaseService.insert(
        table: _itineraryTable,
        data: itineraryData,
      );

      return result;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to generate AI itinerary', e, stackTrace);
      rethrow;
    }
  }

  /// Build comprehensive itinerary generation prompt
  static String _buildItineraryPrompt(
    String destination,
    DateTime startDate,
    DateTime endDate,
    double budget,
    String tripStyle,
    String generationType,
    Map<String, dynamic> destinationData,
    Map<String, dynamic> weatherData,
    {
      List<String>? interests,
      List<String>? activities,
      Map<String, dynamic>? preferences,
      int groupSize = 1,
    }
  ) {
    final duration = endDate.difference(startDate).inDays;
    final budgetFormatted = (budget / 1000000).toStringAsFixed(1);

    return '''
You are an expert travel planner specializing in Indonesian destinations. Create a comprehensive $duration-day itinerary for $destination.

**TRIP DETAILS:**
- Destination: $destination
- Dates: ${startDate.toLocal().toString().split(' ')[0]} to ${endDate.toLocal().toString().split(' ')[0]}
- Duration: $duration days
- Budget: Rp $budgetFormatted million (${(budget / duration / 1000000).toStringAsFixed(2)} million per day)
- Trip Style: $tripStyle
- Group Size: $groupSize ${groupSize == 1 ? 'person' : 'people'}
- Generation Type: $generationType

**DESTINATION CONTEXT:**
${_formatDestinationContext(destinationData)}

**WEATHER FORECAST:**
${_formatWeatherContext(weatherData)}

**PREFERENCES:**
- Interests: ${interests?.join(', ') ?? 'General sightseeing'}
- Activities: ${activities?.join(', ') ?? 'Flexible'}
- Special Requirements: ${preferences?.toString() ?? 'None'}

**INSTRUCTIONS:**
1. Create a detailed day-by-day itinerary
2. Include specific timings for each activity
3. Suggest accommodations within budget
4. Recommend local restaurants and food experiences
5. Include transportation between locations
6. Add cultural insights and local tips
7. Consider weather conditions for outdoor activities
8. Provide budget breakdown for each day
9. Include backup indoor activities for rainy weather
10. Suggest photo spots and memorable experiences

**OUTPUT FORMAT (JSON):**
{
  "itinerary_summary": {
    "destination": "$destination",
    "duration_days": $duration,
    "total_budget": $budget,
    "trip_style": "$tripStyle",
    "highlights": ["highlight1", "highlight2", "highlight3"]
  },
  "accommodation_recommendations": [
    {
      "name": "Hotel Name",
      "type": "hotel/guesthouse/homestay",
      "price_range": "budget/mid-range/luxury",
      "location": "Area name",
      "amenities": ["amenity1", "amenity2"],
      "estimated_cost_per_night": 000000
    }
  ],
  "daily_itinerary": [
    {
      "day": 1,
      "date": "YYYY-MM-DD",
      "theme": "Day theme",
      "weather_note": "Weather consideration",
      "activities": [
        {
          "time": "09:00",
          "activity": "Activity name",
          "location": "Specific location",
          "duration": "2 hours",
          "cost": 000000,
          "description": "Detailed description",
          "tips": "Local tips and insights",
          "backup_activity": "Indoor alternative if weather is bad"
        }
      ],
      "meals": [
        {
          "meal_type": "breakfast/lunch/dinner",
          "restaurant": "Restaurant name",
          "cuisine": "Cuisine type",
          "estimated_cost": 000000,
          "must_try_dishes": ["dish1", "dish2"]
        }
      ],
      "transportation": [
        {
          "from": "Location A",
          "to": "Location B",
          "method": "car/motorbike/bus/walk",
          "duration": "30 minutes",
          "cost": 000000
        }
      ],
      "daily_budget": {
        "activities": 000000,
        "meals": 000000,
        "transportation": 000000,
        "miscellaneous": 000000,
        "total": 000000
      }
    }
  ],
  "budget_breakdown": {
    "accommodation": 000000,
    "activities": 000000,
    "meals": 000000,
    "transportation": 000000,
    "miscellaneous": 000000,
    "total": 000000,
    "remaining_budget": 000000
  },
  "local_insights": {
    "cultural_tips": ["tip1", "tip2"],
    "language_phrases": {"phrase": "translation"},
    "local_customs": ["custom1", "custom2"],
    "safety_notes": ["safety1", "safety2"]
  },
  "packing_suggestions": ["item1", "item2", "item3"],
  "photo_spots": [
    {
      "location": "Photo spot name",
      "best_time": "Golden hour/Morning/Afternoon",
      "description": "What makes this spot special"
    }
  ]
}

Provide only the JSON response, no additional text.
''';
  }

  /// Format destination context for prompt
  static String _formatDestinationContext(Map<String, dynamic> data) {
    if (data.isEmpty) return 'Limited destination data available.';
    
    return '''
- Popular attractions: ${data['attractions'] ?? 'Exploring local sites'}
- Local specialties: ${data['specialties'] ?? 'Traditional Indonesian cuisine'}
- Cultural highlights: ${data['culture'] ?? 'Rich Indonesian heritage'}
- Transportation: ${data['transportation'] ?? 'Local transport options available'}
''';
  }

  /// Format weather context for prompt
  static String _formatWeatherContext(Map<String, dynamic> data) {
    if (data.isEmpty) return 'Weather data not available.';
    
    return '''
- Average temperature: ${data['avg_temp'] ?? 'Tropical climate'}°C
- Rain probability: ${data['rain_chance'] ?? 'Moderate'}%
- Best outdoor times: ${data['best_times'] ?? 'Morning and late afternoon'}
- Weather notes: ${data['notes'] ?? 'Pack for tropical weather'}
''';
  }

  /// Get destination context from database
  static Future<Map<String, dynamic>> _getDestinationContext(String destination) async {
    try {
      // This would normally fetch from destination service
      return {
        'attractions': 'Local landmarks and tourist sites',
        'specialties': 'Regional cuisine and local dishes',
        'culture': 'Local traditions and customs',
        'transportation': 'Available transport options',
      };
    } catch (e) {
      return {};
    }
  }

  /// Get weather context
  static Future<Map<String, dynamic>> _getWeatherContext(
    String destination,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      // This would normally fetch from weather service
      return {
        'avg_temp': 28,
        'rain_chance': 30,
        'best_times': 'Morning (6-10 AM) and late afternoon (4-6 PM)',
        'notes': 'Tropical climate with afternoon rain showers',
      };
    } catch (e) {
      return {};
    }
  }

  /// Parse AI response to structured data
  static Map<String, dynamic> _parseAIResponse(String aiResponse) {
    try {
      // Extract JSON from AI response
      final jsonStart = aiResponse.indexOf('{');
      final jsonEnd = aiResponse.lastIndexOf('}') + 1;
      
      if (jsonStart >= 0 && jsonEnd > jsonStart) {
        final jsonString = aiResponse.substring(jsonStart, jsonEnd);
        return jsonDecode(jsonString) as Map<String, dynamic>;
      } else {
        // Fallback parsing if JSON not found
        return {
          'itinerary_summary': {
            'destination': 'Generated Destination',
            'raw_response': aiResponse,
          },
          'parsing_note': 'AI response was not in expected JSON format',
        };
      }
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to parse AI response as JSON', e);
      return {
        'raw_response': aiResponse,
        'parsing_error': e.toString(),
      };
    }
  }

  /// Build optimization prompt
  static String _buildOptimizationPrompt(
    Map<String, dynamic> existingItinerary,
    Map<String, dynamic>? constraints,
    List<String>? feedback,
  ) {
    return '''
Optimize this existing travel itinerary based on user feedback and constraints.

**EXISTING ITINERARY:**
${jsonEncode(existingItinerary['itinerary_data'])}

**USER FEEDBACK:**
${feedback?.join('\n') ?? 'No specific feedback provided'}

**CONSTRAINTS:**
${constraints?.toString() ?? 'No additional constraints'}

**OPTIMIZATION GOALS:**
1. Address user feedback points
2. Improve time efficiency
3. Enhance budget allocation
4. Add more local experiences
5. Better activity sequencing

Provide optimized itinerary in the same JSON format as the original.
''';
  }

  /// Apply optimizations to existing itinerary
  static Future<Map<String, dynamic>> _applyOptimizations(
    Map<String, dynamic> existingItinerary,
    String optimizationSuggestions,
  ) async {
    try {
      // Parse optimization suggestions
      final optimizedData = _parseAIResponse(optimizationSuggestions);
      
      // Merge with existing data
      final originalData = existingItinerary['itinerary_data'] as Map<String, dynamic>;
      
      return {
        ...originalData,
        ...optimizedData,
        'optimization_applied': true,
        'optimization_timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to apply optimizations', e);
      return existingItinerary['itinerary_data'] as Map<String, dynamic>;
    }
  }

  /// Enrich itinerary data
  static Future<void> _enrichItineraryData(Map<String, dynamic> itinerary) async {
    try {
      // Add computed fields
      itinerary['is_past'] = DateTime.parse(itinerary['end_date']).isBefore(DateTime.now());
      itinerary['is_upcoming'] = DateTime.parse(itinerary['start_date']).isAfter(DateTime.now());
      itinerary['is_current'] = !itinerary['is_past'] && !itinerary['is_upcoming'];
      
      // Add trip duration
      final startDate = DateTime.parse(itinerary['start_date']);
      final endDate = DateTime.parse(itinerary['end_date']);
      itinerary['duration_text'] = '${endDate.difference(startDate).inDays} days';
      
      // Add budget per day
      final budget = itinerary['budget'] as double? ?? 0;
      final days = endDate.difference(startDate).inDays;
      itinerary['budget_per_day'] = days > 0 ? budget / days : 0;
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to enrich itinerary data', e);
    }
  }

  /// Calculate average rating from feedback
  static double _calculateAverageRating(List<Map<String, dynamic>> feedback) {
    if (feedback.isEmpty) return 0.0;
    
    final total = feedback.fold<int>(0, (sum, f) => sum + (f['rating'] as int? ?? 0));
    return total / feedback.length;
  }

  /// Get popular destinations
  static Map<String, int> _getPopularDestinations(List<Map<String, dynamic>> itineraries) {
    final destinations = <String, int>{};
    
    for (final itinerary in itineraries) {
      final destination = itinerary['destination'] as String? ?? 'Unknown';
      destinations[destination] = (destinations[destination] ?? 0) + 1;
    }

    return destinations;
  }

  /// Get popular trip styles
  static Map<String, int> _getPopularTripStyles(List<Map<String, dynamic>> itineraries) {
    final styles = <String, int>{};
    
    for (final itinerary in itineraries) {
      final style = itinerary['trip_style'] as String? ?? 'Unknown';
      styles[style] = (styles[style] ?? 0) + 1;
    }

    return styles;
  }
}
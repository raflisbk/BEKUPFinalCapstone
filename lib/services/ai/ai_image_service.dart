import 'dart:async';
import 'dart:convert';
import '../../core/utils/logger.dart';
import '../supabase_config.dart';
import '../supabase_database_service.dart';
import 'gemini_service.dart';

/// AI Image Service
/// Handles AI-powered image analysis, recognition, and processing for travel content
class AIImageService {
  static const String _tag = 'AIImageService';
  static const String _imageAnalysisTable = 'ai_image_analysis';
  static const String _imageTagsTable = 'ai_image_tags';
  static const String _landmarkRecognitionTable = 'ai_landmark_recognition';

  // Analysis types
  static const String analysisTypeGeneral = 'general';
  static const String analysisTypeLandmark = 'landmark';
  static const String analysisTypeFood = 'food';
  static const String analysisTypeActivity = 'activity';
  static const String analysisTypeAccommodation = 'accommodation';

  // Confidence levels
  static const String confidenceHigh = 'high';
  static const String confidenceMedium = 'medium';
  static const String confidenceLow = 'low';

  // ===============================
  // IMAGE ANALYSIS
  // ===============================

  /// Analyze image with AI
  static Future<Map<String, dynamic>> analyzeImage({
    required String imageUrl,
    required String imageBase64,
    String analysisType = analysisTypeGeneral,
    Map<String, dynamic>? context,
  }) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Analyzing image with AI: $analysisType');

      // Build analysis prompt
      final prompt = _buildImageAnalysisPrompt(analysisType, context);

      // Analyze image with Gemini Vision
      final aiResponse = await GeminiService.generateContentWithImage(
        prompt: prompt,
        imageBase64: imageBase64,
        model: GeminiService.modelPro,
        temperature: 0.7,
        maxOutputTokens: 2048,
      );

      // Parse AI response
      final analysisResult = _parseImageAnalysis(aiResponse, analysisType);

      // Save analysis to database
      final analysisData = {
        'user_id': userId,
        'image_url': imageUrl,
        'analysis_type': analysisType,
        'ai_response': aiResponse,
        'analysis_result': analysisResult,
        'context': context ?? {},
        'confidence_score': analysisResult['confidence_score'] ?? 0.5,
        'created_at': DateTime.now().toIso8601String(),
      };

      final analysis = await SupabaseDatabaseService.insert(
        table: _imageAnalysisTable,
        data: analysisData,
      );

      // Extract and save tags
      await _extractAndSaveTags(analysis['id'], analysisResult);

      AppLogger.success(_tag, 'Image analysis completed');
      return {
        'analysis_id': analysis['id'],
        'analysis_result': analysisResult,
        'ai_response': aiResponse,
        'confidence_score': analysisResult['confidence_score'],
      };
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to analyze image', e, stackTrace);
      rethrow;
    }
  }

  /// Recognize landmark in image
  static Future<Map<String, dynamic>> recognizeLandmark({
    required String imageUrl,
    required String imageBase64,
    String? location,
  }) async {
    try {
      AppLogger.debug(_tag, 'Recognizing landmark in image');

      final context = {
        'analysis_focus': 'landmark_recognition',
        'location': location,
      };

      final result = await analyzeImage(
        imageUrl: imageUrl,
        imageBase64: imageBase64,
        analysisType: analysisTypeLandmark,
        context: context,
      );

      // Save landmark recognition data
      final landmarkData = result['analysis_result'] as Map<String, dynamic>? ?? {};
      
      if (landmarkData.containsKey('landmark_name')) {
        await _saveLandmarkRecognition(
          result['analysis_id'],
          landmarkData,
          location,
        );
      }

      AppLogger.success(_tag, 'Landmark recognition completed');
      return result;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to recognize landmark', e, stackTrace);
      rethrow;
    }
  }

  /// Identify food in image
  static Future<Map<String, dynamic>> identifyFood({
    required String imageUrl,
    required String imageBase64,
    String? location,
  }) async {
    try {
      AppLogger.debug(_tag, 'Identifying food in image');

      final context = {
        'analysis_focus': 'food_identification',
        'location': location,
        'include_nutrition': true,
      };

      final result = await analyzeImage(
        imageUrl: imageUrl,
        imageBase64: imageBase64,
        analysisType: analysisTypeFood,
        context: context,
      );

      AppLogger.success(_tag, 'Food identification completed');
      return result;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to identify food', e, stackTrace);
      rethrow;
    }
  }

  /// Analyze travel activity in image
  static Future<Map<String, dynamic>> analyzeActivity({
    required String imageUrl,
    required String imageBase64,
    String? destination,
  }) async {
    try {
      AppLogger.debug(_tag, 'Analyzing activity in image');

      final context = {
        'analysis_focus': 'activity_analysis',
        'destination': destination,
        'include_recommendations': true,
      };

      final result = await analyzeImage(
        imageUrl: imageUrl,
        imageBase64: imageBase64,
        analysisType: analysisTypeActivity,
        context: context,
      );

      AppLogger.success(_tag, 'Activity analysis completed');
      return result;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to analyze activity', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // BATCH PROCESSING
  // ===============================

  /// Analyze multiple images
  static Future<List<Map<String, dynamic>>> analyzeMultipleImages({
    required List<Map<String, String>> images, // {imageUrl, imageBase64}
    String analysisType = analysisTypeGeneral,
    Map<String, dynamic>? commonContext,
    void Function(int current, int total)? onProgress,
  }) async {
    try {
      AppLogger.debug(_tag, 'Analyzing ${images.length} images');

      final results = <Map<String, dynamic>>[];

      for (int i = 0; i < images.length; i++) {
        try {
          onProgress?.call(i + 1, images.length);

          final image = images[i];
          final result = await analyzeImage(
            imageUrl: image['imageUrl']!,
            imageBase64: image['imageBase64']!,
            analysisType: analysisType,
            context: commonContext,
          );

          results.add(result);

          // Small delay to respect rate limits
          if (i < images.length - 1) {
            await Future.delayed(const Duration(seconds: 1));
          }
        } catch (e) {
          AppLogger.warning(_tag, 'Failed to analyze image ${i + 1}', e);
          results.add({
            'error': e.toString(),
            'image_index': i,
          });
        }
      }

      AppLogger.success(_tag, 'Batch analysis completed: ${results.length} results');
      return results;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to analyze multiple images', e, stackTrace);
      return [];
    }
  }

  /// Generate image captions
  static Future<List<String>> generateImageCaptions({
    required List<Map<String, String>> images,
    String? style, // 'descriptive', 'creative', 'travel_blog'
  }) async {
    try {
      AppLogger.debug(_tag, 'Generating captions for ${images.length} images');

      final captions = <String>[];

      for (final image in images) {
        try {
          final prompt = _buildCaptionPrompt(style);
          
          final caption = await GeminiService.generateContentWithImage(
            prompt: prompt,
            imageBase64: image['imageBase64']!,
            model: GeminiService.modelFlash,
            temperature: 0.8,
            maxOutputTokens: 256,
          );

          captions.add(caption.trim());
          
          // Small delay for rate limiting
          await Future.delayed(const Duration(milliseconds: 500));
        } catch (e) {
          AppLogger.warning(_tag, 'Failed to generate caption', e);
          captions.add('Caption could not be generated');
        }
      }

      AppLogger.success(_tag, 'Generated ${captions.length} captions');
      return captions;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to generate image captions', e, stackTrace);
      return [];
    }
  }

  // ===============================
  // ANALYSIS HISTORY
  // ===============================

  /// Get user's image analysis history
  static Future<List<Map<String, dynamic>>> getAnalysisHistory({
    String? userId,
    String? analysisType,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final targetUserId = userId ?? SupabaseConfig.userId;
      if (targetUserId == null) {
        throw Exception('No user ID provided');
      }

      AppLogger.debug(_tag, 'Getting analysis history for user: $targetUserId');

      final filters = <String, dynamic>{'user_id': targetUserId};
      if (analysisType != null) filters['analysis_type'] = analysisType;

      final analyses = await SupabaseDatabaseService.select(
        table: _imageAnalysisTable,
        filters: filters,
        orderBy: 'created_at',
        ascending: false,
        limit: limit,
        offset: offset,
      );

      // Enrich with tags
      for (final analysis in analyses) {
        await _enrichAnalysisData(analysis);
      }

      AppLogger.success(_tag, 'Retrieved ${analyses.length} analysis records');
      return analyses;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get analysis history', e, stackTrace);
      return [];
    }
  }

  /// Get analysis by ID
  static Future<Map<String, dynamic>?> getAnalysis(String analysisId) async {
    try {
      AppLogger.debug(_tag, 'Getting analysis: $analysisId');

      final analyses = await SupabaseDatabaseService.select(
        table: _imageAnalysisTable,
        filters: {'id': analysisId},
      );

      if (analyses.isEmpty) {
        AppLogger.warning(_tag, 'Analysis not found: $analysisId');
        return null;
      }

      final analysis = analyses.first;
      await _enrichAnalysisData(analysis);

      AppLogger.success(_tag, 'Retrieved analysis');
      return analysis;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get analysis', e, stackTrace);
      return null;
    }
  }

  /// Get landmark recognition results
  static Future<List<Map<String, dynamic>>> getLandmarkRecognitions({
    String? location,
    int limit = 10,
  }) async {
    try {
      AppLogger.debug(_tag, 'Getting landmark recognitions');

      final filters = <String, dynamic>{};
      if (location != null) filters['location'] = location;

      final landmarks = await SupabaseDatabaseService.select(
        table: _landmarkRecognitionTable,
        filters: filters,
        orderBy: 'confidence_score',
        ascending: false,
        limit: limit,
      );

      AppLogger.success(_tag, 'Retrieved ${landmarks.length} landmark recognitions');
      return landmarks;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get landmark recognitions', e, stackTrace);
      return [];
    }
  }

  // ===============================
  // ANALYTICS
  // ===============================

  /// Get image analysis statistics
  static Future<Map<String, dynamic>> getAnalysisStatistics([String? userId]) async {
    try {
      final targetUserId = userId ?? SupabaseConfig.userId;
      if (targetUserId == null) {
        throw Exception('No user ID provided');
      }

      AppLogger.debug(_tag, 'Getting analysis statistics');

      final analyses = await SupabaseDatabaseService.select(
        table: _imageAnalysisTable,
        filters: {'user_id': targetUserId},
      );

      final statistics = {
        'total_analyses': analyses.length,
        'analysis_types': _getAnalysisTypeDistribution(analyses),
        'average_confidence': _calculateAverageConfidence(analyses),
        'high_confidence_count': analyses.where((a) => 
          (a['confidence_score'] as double? ?? 0.0) > 0.8).length,
        'recent_analyses': analyses.take(5).toList(),
        'popular_tags': await _getPopularTags(targetUserId),
      };

      AppLogger.success(_tag, 'Analysis statistics retrieved');
      return statistics;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get analysis statistics', e, stackTrace);
      return {};
    }
  }

  // ===============================
  // PRIVATE HELPER METHODS
  // ===============================

  /// Build image analysis prompt
  static String _buildImageAnalysisPrompt(
    String analysisType,
    Map<String, dynamic>? context,
  ) {
    const basePrompt = '''
Analyze this image as a travel and tourism expert. Provide detailed insights that would be helpful for travelers.
''';

    switch (analysisType) {
      case analysisTypeLandmark:
        return '''$basePrompt

Focus on identifying landmarks, monuments, or famous tourist attractions.

Provide analysis in JSON format:
{
  "landmark_name": "Name of landmark or 'Unknown' if not identifiable",
  "location": "City/region/country",
  "description": "Detailed description of what you see",
  "historical_significance": "Historical or cultural importance",
  "visitor_tips": ["tip1", "tip2", "tip3"],
  "best_time_to_visit": "Timing recommendations",
  "confidence_score": 0.85,
  "tags": ["tag1", "tag2", "tag3"]
}

Context: ${jsonEncode(context ?? {})}
''';

      case analysisTypeFood:
        return '''$basePrompt

Focus on identifying food, dishes, and culinary experiences.

Provide analysis in JSON format:
{
  "food_name": "Name of dish or cuisine type",
  "cuisine_type": "Indonesian/Western/Asian etc",
  "ingredients": ["ingredient1", "ingredient2"],
  "description": "Detailed description of the food",
  "cultural_significance": "Cultural context of the dish",
  "where_to_find": "Where travelers can find this food",
  "price_range": "budget/mid-range/expensive",
  "confidence_score": 0.85,
  "tags": ["tag1", "tag2", "tag3"]
}

Context: ${jsonEncode(context ?? {})}
''';

      case analysisTypeActivity:
        return '''$basePrompt

Focus on identifying activities, experiences, and travel opportunities.

Provide analysis in JSON format:
{
  "activity_type": "Type of activity (adventure/cultural/relaxation etc)",
  "activity_name": "Specific activity name",
  "description": "What the activity involves",
  "difficulty_level": "easy/moderate/challenging",
  "duration": "Typical time needed",
  "best_season": "When to do this activity",
  "equipment_needed": ["item1", "item2"],
  "similar_activities": ["activity1", "activity2"],
  "confidence_score": 0.85,
  "tags": ["tag1", "tag2", "tag3"]
}

Context: ${jsonEncode(context ?? {})}
''';

      case analysisTypeAccommodation:
        return '''$basePrompt

Focus on identifying accommodation types and travel lodging.

Provide analysis in JSON format:
{
  "accommodation_type": "hotel/resort/homestay/hostel etc",
  "style": "luxury/budget/boutique/traditional etc",
  "description": "Description of the accommodation",
  "amenities": ["amenity1", "amenity2"],
  "target_traveler": "solo/couple/family/group",
  "price_estimate": "Rough price range",
  "booking_tips": ["tip1", "tip2"],
  "confidence_score": 0.85,
  "tags": ["tag1", "tag2", "tag3"]
}

Context: ${jsonEncode(context ?? {})}
''';

      default:
        return '''$basePrompt

Provide comprehensive travel-focused analysis of this image.

Provide analysis in JSON format:
{
  "description": "Detailed description of what you see",
  "travel_relevance": "How this relates to travel and tourism",
  "location_guess": "Best guess of location or region",
  "activity_suggestions": ["suggestion1", "suggestion2"],
  "photo_tips": "Photography tips for this type of scene",
  "best_time": "Best time of day/season for this",
  "travel_tips": ["tip1", "tip2", "tip3"],
  "confidence_score": 0.85,
  "tags": ["tag1", "tag2", "tag3"]
}

Context: ${jsonEncode(context ?? {})}
''';
    }
  }

  /// Build caption generation prompt
  static String _buildCaptionPrompt(String? style) {
    switch (style) {
      case 'creative':
        return '''
Generate a creative, engaging caption for this travel photo. 
Make it inspiring and shareable for social media.
Keep it under 100 characters.
Use emojis appropriately.
''';

      case 'travel_blog':
        return '''
Generate a descriptive caption suitable for a travel blog.
Include specific details about the location and experience.
Make it informative yet engaging.
Keep it under 150 characters.
''';

      case 'descriptive':
      default:
        return '''
Generate a clear, descriptive caption for this image.
Focus on what can be seen and the travel context.
Keep it informative and concise.
Keep it under 100 characters.
''';
    }
  }

  /// Parse image analysis response
  static Map<String, dynamic> _parseImageAnalysis(
    String aiResponse,
    String analysisType,
  ) {
    try {
      final jsonStart = aiResponse.indexOf('{');
      final jsonEnd = aiResponse.lastIndexOf('}') + 1;
      
      if (jsonStart >= 0 && jsonEnd > jsonStart) {
        final jsonString = aiResponse.substring(jsonStart, jsonEnd);
        final parsed = jsonDecode(jsonString) as Map<String, dynamic>;
        
        // Add metadata
        parsed['analysis_type'] = analysisType;
        parsed['parsed_at'] = DateTime.now().toIso8601String();
        
        return parsed;
      } else {
        // Fallback if JSON parsing fails
        return {
          'description': aiResponse,
          'analysis_type': analysisType,
          'confidence_score': 0.5,
          'tags': ['ai_analysis'],
          'parsing_error': 'Could not parse as JSON',
        };
      }
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to parse AI response', e);
      return {
        'raw_response': aiResponse,
        'analysis_type': analysisType,
        'confidence_score': 0.3,
        'tags': ['parsing_failed'],
        'error': e.toString(),
      };
    }
  }

  /// Extract and save tags
  static Future<void> _extractAndSaveTags(
    String analysisId,
    Map<String, dynamic> analysisResult,
  ) async {
    try {
      final tags = analysisResult['tags'] as List<dynamic>? ?? [];
      
      for (final tag in tags) {
        if (tag is String && tag.isNotEmpty) {
          await SupabaseDatabaseService.insert(
            table: _imageTagsTable,
            data: {
              'analysis_id': analysisId,
              'tag': tag.toLowerCase(),
              'confidence': analysisResult['confidence_score'] ?? 0.5,
              'created_at': DateTime.now().toIso8601String(),
            },
          );
        }
      }
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to save tags', e);
    }
  }

  /// Save landmark recognition data
  static Future<void> _saveLandmarkRecognition(
    String analysisId,
    Map<String, dynamic> landmarkData,
    String? location,
  ) async {
    try {
      final recognitionData = {
        'analysis_id': analysisId,
        'landmark_name': landmarkData['landmark_name'],
        'location': landmarkData['location'] ?? location,
        'description': landmarkData['description'],
        'confidence_score': landmarkData['confidence_score'],
        'metadata': landmarkData,
        'created_at': DateTime.now().toIso8601String(),
      };

      await SupabaseDatabaseService.insert(
        table: _landmarkRecognitionTable,
        data: recognitionData,
      );
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to save landmark recognition', e);
    }
  }

  /// Enrich analysis data
  static Future<void> _enrichAnalysisData(Map<String, dynamic> analysis) async {
    try {
      // Get tags for this analysis
      final tags = await SupabaseDatabaseService.select(
        table: _imageTagsTable,
        filters: {'analysis_id': analysis['id']},
      );

      analysis['tags'] = tags.map((tag) => tag['tag']).toList();
      
      // Add computed fields
      final confidenceScore = analysis['confidence_score'] as double? ?? 0.0;
      analysis['confidence_level'] = confidenceScore > 0.8 
          ? confidenceHigh 
          : confidenceScore > 0.5 
              ? confidenceMedium 
              : confidenceLow;
              
      analysis['age_days'] = DateTime.now().difference(
        DateTime.parse(analysis['created_at']),
      ).inDays;
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to enrich analysis data', e);
    }
  }

  /// Get analysis type distribution
  static Map<String, int> _getAnalysisTypeDistribution(
    List<Map<String, dynamic>> analyses,
  ) {
    final distribution = <String, int>{};
    
    for (final analysis in analyses) {
      final type = analysis['analysis_type'] as String? ?? 'unknown';
      distribution[type] = (distribution[type] ?? 0) + 1;
    }

    return distribution;
  }

  /// Calculate average confidence
  static double _calculateAverageConfidence(List<Map<String, dynamic>> analyses) {
    if (analyses.isEmpty) return 0.0;
    
    final total = analyses.fold<double>(0, (sum, analysis) {
      return sum + (analysis['confidence_score'] as double? ?? 0.0);
    });
    
    return total / analyses.length;
  }

  /// Get popular tags
  static Future<List<Map<String, dynamic>>> _getPopularTags(String userId) async {
    try {
      // Get analyses for user
      final analyses = await SupabaseDatabaseService.select(
        table: _imageAnalysisTable,
        filters: {'user_id': userId},
      );

      final analysisIds = analyses.map((a) => a['id']).toList();
      
      if (analysisIds.isEmpty) return [];

      // Get tags for user's analyses
      final tags = await SupabaseDatabaseService.select(
        table: _imageTagsTable,
        filters: {'analysis_id': analysisIds},
      );

      // Count tag frequency
      final tagCounts = <String, int>{};
      for (final tag in tags) {
        final tagName = tag['tag'] as String;
        tagCounts[tagName] = (tagCounts[tagName] ?? 0) + 1;
      }

      // Sort by frequency
      final sortedTags = tagCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sortedTags.take(10).map((entry) => {
        'tag': entry.key,
        'count': entry.value,
      }).toList();
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to get popular tags', e);
      return [];
    }
  }
}
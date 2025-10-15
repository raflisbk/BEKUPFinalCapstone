import 'dart:async';
import '../core/utils/logger.dart';
import 'supabase_config.dart';
import 'supabase_database_service.dart';
import 'ai_service.dart';

/// Content Generation Service
/// Handles automated content generation for various app features
class ContentGenerationService {
  static const String _tag = 'ContentGenerationService';
  static const String _generatedContentTable = 'generated_content';
  static const String _contentTemplatesTable = 'content_templates';
  static const String _contentRequestsTable = 'content_requests';

  // Singleton pattern
  static ContentGenerationService? _instance;
  static ContentGenerationService get instance => _instance ??= ContentGenerationService._internal();
  
  ContentGenerationService._internal();

  // AI Service instance
  final AIService _aiService = AIService();

  // Content types
  static const String typeDestinationDescription = 'destination_description';
  static const String typeItinerary = 'travel_itinerary';
  static const String typeTravelTips = 'travel_tips';
  static const String typeReviewSummary = 'review_summary';
  static const String typeBlogPost = 'blog_post';
  static const String typeSocialPost = 'social_post';
  static const String typeGuideContent = 'guide_content';

  // ===============================
  // CONTENT GENERATION
  // ===============================

  /// Generate destination content
  Future<Map<String, dynamic>> generateDestinationContent({
    required String destinationId,
    required String destinationName,
    required String location,
    String? category,
    List<String>? highlights,
    bool saveToDatabase = true,
  }) async {
    try {
      AppLogger.debug(_tag, 'Generating content for destination: $destinationName');

      // Check if content already exists
      if (saveToDatabase) {
        final existingContent = await _getExistingContent(
          type: typeDestinationDescription,
          entityId: destinationId,
        );
        
        if (existingContent != null) {
          AppLogger.info(_tag, 'Content already exists for destination');
          return existingContent;
        }
      }

      // Generate description
      final description = await _aiService.generateDestinationDescription(
        destinationName: destinationName,
        location: location,
        category: category,
        highlights: highlights,
      );

      // Generate travel tips
      final tips = await _aiService.generateTravelTips(
        destination: destinationName,
        travelType: 'general',
      );

      final content = {
        'description': description,
        'travel_tips': tips,
        'highlights': highlights ?? [],
        'category': category,
        'generated_at': DateTime.now().toIso8601String(),
      };

      // Save to database if requested
      if (saveToDatabase) {
        final savedContent = await _saveGeneratedContent(
          type: typeDestinationDescription,
          entityId: destinationId,
          content: content,
          metadata: {
            'destination_name': destinationName,
            'location': location,
            'category': category,
          },
        );
        
        return savedContent;
      }

      AppLogger.success(_tag, 'Destination content generated successfully');
      return {'content': content};
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to generate destination content', e, stackTrace);
      rethrow;
    }
  }

  /// Generate itinerary content
  Future<Map<String, dynamic>> generateItineraryContent({
    required String tripId,
    required String destination,
    required int days,
    required String budget,
    required List<String> interests,
    String? travelStyle,
    String? groupSize,
    bool saveToDatabase = true,
  }) async {
    try {
      AppLogger.debug(_tag, 'Generating itinerary for trip: $tripId');

      // Check if content already exists
      if (saveToDatabase) {
        final existingContent = await _getExistingContent(
          type: typeItinerary,
          entityId: tripId,
        );
        
        if (existingContent != null) {
          AppLogger.info(_tag, 'Itinerary already exists for trip');
          return existingContent;
        }
      }

      // Generate itinerary
      final itinerary = await _aiService.generateTravelItinerary(
        destination: destination,
        days: days,
        budget: budget,
        interests: interests,
        travelStyle: travelStyle,
        groupSize: groupSize,
      );

      final content = {
        'itinerary': itinerary,
        'destination': destination,
        'days': days,
        'budget': budget,
        'interests': interests,
        'travel_style': travelStyle,
        'group_size': groupSize,
        'generated_at': DateTime.now().toIso8601String(),
      };

      // Save to database if requested
      if (saveToDatabase) {
        final savedContent = await _saveGeneratedContent(
          type: typeItinerary,
          entityId: tripId,
          content: content,
          metadata: {
            'destination': destination,
            'days': days,
            'budget': budget,
          },
        );
        
        return savedContent;
      }

      AppLogger.success(_tag, 'Itinerary content generated successfully');
      return {'content': content};
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to generate itinerary content', e, stackTrace);
      rethrow;
    }
  }

  /// Generate blog post from trip data
  Future<Map<String, dynamic>> generateBlogPost({
    required String tripId,
    String? title,
    String? style, // 'casual', 'formal', 'adventurous', 'luxury'
    List<String>? focusAreas,
    bool includePhotos = true,
    bool saveToDatabase = true,
  }) async {
    try {
      AppLogger.debug(_tag, 'Generating blog post for trip: $tripId');

      // Get trip data (this would normally fetch from trip service)
      // For now, we'll use placeholder data
      final tripData = await _getTripData(tripId);
      
      final prompt = '''
Write an engaging travel blog post based on this trip:

Destination: ${tripData['destination']}
Duration: ${tripData['duration']} days
Highlights: ${tripData['highlights']?.join(', ') ?? 'N/A'}
Activities: ${tripData['activities']?.join(', ') ?? 'N/A'}

Style: ${style ?? 'casual'}
Focus areas: ${focusAreas?.join(', ') ?? 'general experience'}

Please include:
1. Engaging title and introduction
2. Day-by-day highlights
3. Personal experiences and insights
4. Practical tips for future travelers
5. Cultural observations
6. Food and dining experiences
7. Transportation insights
8. Accommodation recommendations
9. Photography tips
10. Final thoughts and recommendations

Write in first person as if the traveler is sharing their experience. Make it engaging, informative, and inspiring for other travelers.
''';

      final blogContent = await _aiService.generateText(
        prompt: prompt,
        temperature: 0.8,
        maxTokens: 2000,
      );

      final content = {
        'title': title ?? 'My Amazing Journey to ${tripData['destination']}',
        'content': blogContent,
        'style': style,
        'focus_areas': focusAreas ?? [],
        'trip_data': tripData,
        'generated_at': DateTime.now().toIso8601String(),
      };

      // Save to database if requested
      if (saveToDatabase) {
        final savedContent = await _saveGeneratedContent(
          type: typeBlogPost,
          entityId: tripId,
          content: content,
          metadata: {
            'style': style,
            'include_photos': includePhotos,
          },
        );
        
        return savedContent;
      }

      AppLogger.success(_tag, 'Blog post generated successfully');
      return {'content': content};
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to generate blog post', e, stackTrace);
      rethrow;
    }
  }

  /// Generate social media posts
  Future<List<Map<String, dynamic>>> generateSocialPosts({
    required String tripId,
    required List<String> platforms, // 'instagram', 'facebook', 'twitter'
    String? mood, // 'excited', 'relaxed', 'adventurous', 'grateful'
    bool includeHashtags = true,
    bool saveToDatabase = true,
  }) async {
    try {
      AppLogger.debug(_tag, 'Generating social posts for trip: $tripId');

      final tripData = await _getTripData(tripId);
      final posts = <Map<String, dynamic>>[];

      for (final platform in platforms) {
        final prompt = '''
Create an engaging $platform post about this travel experience:

Destination: ${tripData['destination']}
Highlights: ${tripData['highlights']?.join(', ') ?? 'N/A'}
Mood: ${mood ?? 'excited'}

Requirements for $platform:
${_getPlatformRequirements(platform)}

${includeHashtags ? 'Include relevant hashtags' : 'No hashtags needed'}

Make it authentic, engaging, and platform-appropriate.
''';

        final postContent = await _aiService.generateText(
          prompt: prompt,
          temperature: 0.9,
          maxTokens: 300,
        );

        final post = {
          'platform': platform,
          'content': postContent,
          'mood': mood,
          'include_hashtags': includeHashtags,
          'trip_data': tripData,
          'generated_at': DateTime.now().toIso8601String(),
        };

        posts.add(post);

        // Save to database if requested
        if (saveToDatabase) {
          await _saveGeneratedContent(
            type: typeSocialPost,
            entityId: '${tripId}_$platform',
            content: post,
            metadata: {
              'platform': platform,
              'mood': mood,
            },
          );
        }
      }

      AppLogger.success(_tag, 'Social posts generated for ${platforms.length} platforms');
      return posts;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to generate social posts', e, stackTrace);
      rethrow;
    }
  }

  /// Generate review summary
  Future<Map<String, dynamic>> generateReviewSummary({
    required String entityId,
    required String entityType, // 'destination', 'hotel', 'restaurant', 'activity'
    required List<Map<String, dynamic>> reviews,
    bool saveToDatabase = true,
  }) async {
    try {
      AppLogger.debug(_tag, 'Generating review summary for: $entityType $entityId');

      if (reviews.isEmpty) {
        throw Exception('No reviews provided for summary generation');
      }

      // Prepare reviews text
      final reviewsText = reviews.map((review) {
        return 'Rating: ${review['rating']}/5 - ${review['comment'] ?? ''}';
      }).join('\n\n');

      final prompt = '''
Analyze and summarize these reviews for a $entityType:

$reviewsText

Please provide:
1. Overall sentiment and rating summary
2. Most frequently mentioned positives
3. Most frequently mentioned negatives
4. Key themes and patterns
5. Recommendations for improvement
6. Notable quotes or highlights
7. Summary for potential visitors

Total reviews analyzed: ${reviews.length}

Provide a balanced, helpful summary that would assist potential visitors in making decisions.
''';

      final summary = await _aiService.generateText(
        prompt: prompt,
        temperature: 0.6,
        maxTokens: 800,
      );

      // Calculate statistics
      final ratings = reviews.map((r) => r['rating'] as num).toList();
      final averageRating = ratings.isNotEmpty 
          ? ratings.reduce((a, b) => a + b) / ratings.length 
          : 0.0;

      final content = {
        'summary': summary,
        'review_count': reviews.length,
        'average_rating': averageRating,
        'rating_distribution': _calculateRatingDistribution(ratings),
        'entity_type': entityType,
        'generated_at': DateTime.now().toIso8601String(),
      };

      // Save to database if requested
      if (saveToDatabase) {
        final savedContent = await _saveGeneratedContent(
          type: typeReviewSummary,
          entityId: entityId,
          content: content,
          metadata: {
            'entity_type': entityType,
            'review_count': reviews.length,
          },
        );
        
        return savedContent;
      }

      AppLogger.success(_tag, 'Review summary generated successfully');
      return {'content': content};
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to generate review summary', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // CONTENT TEMPLATES
  // ===============================

  /// Create content template
  Future<Map<String, dynamic>> createContentTemplate({
    required String name,
    required String type,
    required String template,
    String? description,
    Map<String, dynamic>? variables,
    List<String>? tags,
  }) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Creating content template: $name');

      final templateData = {
        'name': name,
        'type': type,
        'template': template,
        'description': description,
        'variables': variables ?? {},
        'tags': tags ?? [],
        'created_by': userId,
        'is_active': true,
        'usage_count': 0,
      };

      final result = await SupabaseDatabaseService.insert(
        table: _contentTemplatesTable,
        data: templateData,
      );

      AppLogger.success(_tag, 'Content template created successfully');
      return result;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to create content template', e, stackTrace);
      rethrow;
    }
  }

  /// Get content templates
  Future<List<Map<String, dynamic>>> getContentTemplates({
    String? type,
    List<String>? tags,
    bool? isActive,
    int limit = 50,
  }) async {
    try {
      AppLogger.debug(_tag, 'Getting content templates');

      final filters = <String, dynamic>{};
      if (type != null) filters['type'] = type;
      if (isActive != null) filters['is_active'] = isActive;

      var templates = await SupabaseDatabaseService.select(
        table: _contentTemplatesTable,
        filters: filters,
        orderBy: 'usage_count',
        ascending: false,
        limit: limit,
      );

      // Filter by tags if provided
      if (tags != null && tags.isNotEmpty) {
        templates = templates.where((template) {
          final templateTags = List<String>.from(template['tags'] ?? []);
          return tags.any((tag) => templateTags.contains(tag));
        }).toList();
      }

      AppLogger.success(_tag, 'Retrieved ${templates.length} content templates');
      return templates;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get content templates', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // CONTENT REQUESTS & QUEUE
  // ===============================

  /// Request content generation
  Future<Map<String, dynamic>> requestContentGeneration({
    required String type,
    required String entityId,
    required Map<String, dynamic> parameters,
    String? priority, // 'low', 'normal', 'high'
    DateTime? scheduledFor,
  }) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Requesting content generation: $type for $entityId');

      final requestData = {
        'type': type,
        'entity_id': entityId,
        'parameters': parameters,
        'priority': priority ?? 'normal',
        'status': 'pending',
        'requested_by': userId,
        'scheduled_for': scheduledFor?.toIso8601String(),
      };

      final request = await SupabaseDatabaseService.insert(
        table: _contentRequestsTable,
        data: requestData,
      );

      AppLogger.success(_tag, 'Content generation request created');
      return request;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to request content generation', e, stackTrace);
      rethrow;
    }
  }

  /// Process pending content requests
  Future<void> processPendingRequests({int limit = 10}) async {
    try {
      AppLogger.debug(_tag, 'Processing pending content requests');

      final requests = await SupabaseDatabaseService.select(
        table: _contentRequestsTable,
        filters: {'status': 'pending'},
        orderBy: 'priority',
        limit: limit,
      );

      for (final request in requests) {
        try {
          // Update status to processing
          await SupabaseDatabaseService.update(
            table: _contentRequestsTable,
            id: request['id'],
            data: {
              'status': 'processing',
              'started_at': DateTime.now().toIso8601String(),
            },
          );

          // Process based on type
          await _processContentRequest(request);

          // Update status to completed
          await SupabaseDatabaseService.update(
            table: _contentRequestsTable,
            id: request['id'],
            data: {
              'status': 'completed',
              'completed_at': DateTime.now().toIso8601String(),
            },
          );
        } catch (e) {
          // Update status to failed
          await SupabaseDatabaseService.update(
            table: _contentRequestsTable,
            id: request['id'],
            data: {
              'status': 'failed',
              'error_message': e.toString(),
              'failed_at': DateTime.now().toIso8601String(),
            },
          );
        }
      }

      AppLogger.success(_tag, 'Processed ${requests.length} content requests');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to process content requests', e, stackTrace);
    }
  }

  // ===============================
  // PRIVATE HELPER METHODS
  // ===============================

  /// Get existing generated content
  Future<Map<String, dynamic>?> _getExistingContent({
    required String type,
    required String entityId,
  }) async {
    try {
      final content = await SupabaseDatabaseService.select(
        table: _generatedContentTable,
        filters: {'type': type, 'entity_id': entityId, 'is_active': true},
        orderBy: 'created_at',
        ascending: false,
        limit: 1,
      );

      return content.isNotEmpty ? content.first : null;
    } catch (e) {
      return null;
    }
  }

  /// Save generated content
  Future<Map<String, dynamic>> _saveGeneratedContent({
    required String type,
    required String entityId,
    required Map<String, dynamic> content,
    Map<String, dynamic>? metadata,
  }) async {
    final userId = SupabaseConfig.userId;

    final contentData = {
      'type': type,
      'entity_id': entityId,
      'content': content,
      'metadata': metadata ?? {},
      'generated_by': userId,
      'is_active': true,
      'version': 1,
    };

    return await SupabaseDatabaseService.insert(
      table: _generatedContentTable,
      data: contentData,
    );
  }

  /// Get trip data (placeholder implementation)
  Future<Map<String, dynamic>> _getTripData(String tripId) async {
    // This would normally fetch from trip service
    // Returning placeholder data for now
    return {
      'destination': 'Bali, Indonesia',
      'duration': 7,
      'highlights': ['Temple visits', 'Beach relaxation', 'Local cuisine'],
      'activities': ['Surfing', 'Cultural tours', 'Spa treatments'],
    };
  }

  /// Get platform-specific requirements
  static String _getPlatformRequirements(String platform) {
    switch (platform.toLowerCase()) {
      case 'instagram':
        return '- Keep it visual and inspiring\n- Use emojis\n- 2200 character limit\n- Include relevant hashtags';
      case 'facebook':
        return '- More detailed storytelling allowed\n- Can be longer format\n- Include call-to-action\n- Tag locations';
      case 'twitter':
        return '- Keep it concise (280 characters)\n- Use engaging language\n- Include hashtags\n- Consider thread if needed';
      default:
        return '- Be engaging and authentic\n- Follow platform best practices';
    }
  }

  /// Calculate rating distribution
  static Map<String, int> _calculateRatingDistribution(List<num> ratings) {
    final distribution = <String, int>{
      '1': 0, '2': 0, '3': 0, '4': 0, '5': 0,
    };

    for (final rating in ratings) {
      final key = rating.round().toString();
      if (distribution.containsKey(key)) {
        distribution[key] = distribution[key]! + 1;
      }
    }

    return distribution;
  }

  /// Process individual content request
  Future<void> _processContentRequest(Map<String, dynamic> request) async {
    final type = request['type'] as String;
    final entityId = request['entity_id'] as String;
    final parameters = request['parameters'] as Map<String, dynamic>;

    switch (type) {
      case typeDestinationDescription:
        await generateDestinationContent(
          destinationId: entityId,
          destinationName: parameters['name'] ?? 'Unknown',
          location: parameters['location'] ?? 'Unknown',
          category: parameters['category'],
          highlights: List<String>.from(parameters['highlights'] ?? []),
        );
        break;
      case typeItinerary:
        await generateItineraryContent(
          tripId: entityId,
          destination: parameters['destination'] ?? 'Unknown',
          days: parameters['days'] ?? 3,
          budget: parameters['budget'] ?? 'moderate',
          interests: List<String>.from(parameters['interests'] ?? []),
          travelStyle: parameters['travel_style'],
          groupSize: parameters['group_size'],
        );
        break;
      default:
        throw Exception('Unknown content type: $type');
    }
  }
}
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../core/interfaces/i_ai_service.dart';
import '../core/utils/logger.dart';
import 'supabase_config.dart';
import 'supabase_database_service.dart';

/// AI Service
/// Handles Gemini AI integration for content generation, analysis, and AI-powered features
class AIService implements IAIService {
  static const String _tag = 'AIService';
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta';
  static const String _aiRequestsTable = 'ai_requests';
  static const String _aiResponsesTable = 'ai_responses';
  static const String _aiConfigTable = 'ai_config';

  // AI Models
  static const String _geminiProModel = 'gemini-1.5-pro-latest';
  static const String _geminiFlashModel = 'gemini-1.5-flash-latest';

  // Rate limiting (instance variables)
  int _requestCount = 0;
  DateTime _lastResetTime = DateTime.now();
  static const int _maxRequestsPerMinute = 15; // Gemini free tier limit

  // ===============================
  // CONFIGURATION
  // ===============================

  /// Get Gemini API key from environment or database
  Future<String?> _getApiKey() async {
    try {
      // Try environment variable first
      final envKey = Platform.environment['GEMINI_API_KEY'];
      if (envKey != null && envKey.isNotEmpty) {
        return envKey;
      }

      // Try from database config
      final configs = await SupabaseDatabaseService.select(
        table: _aiConfigTable,
        filters: {'key': 'gemini_api_key', 'is_active': true},
      );

      if (configs.isNotEmpty) {
        return configs.first['value'] as String?;
      }

      AppLogger.error(_tag, 'No Gemini API key found');
      return null;
    } catch (e) {
      AppLogger.error(_tag, 'Failed to get API key', e);
      return null;
    }
  }

  /// Check rate limiting
  bool _checkRateLimit() {
    final now = DateTime.now();
    
    // Reset counter if more than a minute has passed
    if (now.difference(_lastResetTime).inMinutes >= 1) {
      _requestCount = 0;
      _lastResetTime = now;
    }

    if (_requestCount >= _maxRequestsPerMinute) {
      AppLogger.warning(_tag, 'Rate limit exceeded');
      return false;
    }

    _requestCount++;
    return true;
  }

  // ===============================
  // TEXT GENERATION
  // ===============================

  /// Generate text content using Gemini AI
  @override
  Future<String> generateText({
    required String prompt,
    String? model,
    double temperature = 0.7,
    int maxTokens = 1000,
    List<String>? stopSequences,
    Map<String, dynamic>? context,
  }) async {
    try {
      if (!_checkRateLimit()) {
        throw Exception('Rate limit exceeded. Please wait before making another request.');
      }

      final userId = SupabaseConfig.userId;
      AppLogger.debug(_tag, 'Generating text with Gemini AI');

      final apiKey = await _getApiKey();
      if (apiKey == null) {
        throw Exception('Gemini API key not configured');
      }

      final modelName = model ?? _geminiFlashModel;
      final url = '$_baseUrl/models/$modelName:generateContent?key=$apiKey';

      // Build request payload
      final payload = {
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': temperature,
          'maxOutputTokens': maxTokens,
          if (stopSequences != null) 'stopSequences': stopSequences,
        },
        'safetySettings': [
          {
            'category': 'HARM_CATEGORY_HARASSMENT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          },
          {
            'category': 'HARM_CATEGORY_HATE_SPEECH',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          },
          {
            'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          },
          {
            'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          }
        ]
      };

      // Log AI request
      final requestId = await _logAIRequest(
        userId: userId,
        model: modelName,
        prompt: prompt,
        parameters: {
          'temperature': temperature,
          'maxTokens': maxTokens,
          'context': context,
        },
      );

      // Make API request
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(payload),
      );

      if (response.statusCode != 200) {
        final errorBody = json.decode(response.body);
        final errorMessage = errorBody['error']?['message'] ?? 'Unknown error';
        throw Exception('Gemini API error: $errorMessage');
      }

      final responseData = json.decode(response.body);
      final candidates = responseData['candidates'] as List<dynamic>?;
      
      if (candidates == null || candidates.isEmpty) {
        throw Exception('No content generated by AI');
      }

      final content = candidates.first['content'];
      final parts = content['parts'] as List<dynamic>;
      final generatedText = parts.first['text'] as String;

      // Log AI response
      await _logAIResponse(
        requestId: requestId,
        response: generatedText,
        metadata: {
          'candidates_count': candidates.length,
          'finish_reason': candidates.first['finishReason'],
          'safety_ratings': candidates.first['safetyRatings'],
        },
      );

      AppLogger.success(_tag, 'Text generated successfully');
      return generatedText;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to generate text', e, stackTrace);
      rethrow;
    }
  }

  /// Generate travel itinerary
  @override
  Future<String> generateTravelItinerary({
    required String destination,
    required int days,
    required String budget,
    required List<String> interests,
    String? travelStyle,
    String? groupSize,
  }) async {
    try {
      AppLogger.debug(_tag, 'Generating travel itinerary for: $destination');

      final prompt = '''
Create a detailed $days-day travel itinerary for $destination.

Requirements:
- Budget: $budget
- Interests: ${interests.join(', ')}
- Travel style: ${travelStyle ?? 'Moderate'}
- Group size: ${groupSize ?? 'Solo'}

Please include:
1. Daily activities with time schedules
2. Recommended restaurants and local cuisine
3. Transportation options
4. Estimated costs for activities
5. Cultural tips and local customs
6. Weather considerations
7. Must-visit attractions
8. Hidden gems and local experiences
9. Safety tips
10. Packing suggestions

Format the response in a clear, day-by-day structure with practical details.
''';

      return await generateText(
        prompt: prompt,
        model: _geminiProModel,
        temperature: 0.8,
        maxTokens: 2000,
        context: {
          'type': 'travel_itinerary',
          'destination': destination,
          'days': days,
          'budget': budget,
        },
      );
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to generate travel itinerary', e, stackTrace);
      rethrow;
    }
  }

  /// Generate destination description
  @override
  Future<String> generateDestinationDescription({
    required String destinationName,
    required String location,
    String? category,
    List<String>? highlights,
  }) async {
    try {
      AppLogger.debug(_tag, 'Generating description for: $destinationName');

      final prompt = '''
Write an engaging and informative description for $destinationName, located in $location.

${category != null ? 'Category: $category' : ''}
${highlights != null ? 'Key highlights: ${highlights.join(', ')}' : ''}

Please include:
1. Brief overview and what makes it special
2. Main attractions and activities
3. Best time to visit
4. Cultural significance
5. What visitors can expect
6. Unique features or experiences
7. Historical context if relevant
8. Practical visitor information

Keep it engaging, informative, and around 300-400 words. Focus on what would interest travelers.
''';

      return await generateText(
        prompt: prompt,
        temperature: 0.7,
        maxTokens: 600,
        context: {
          'type': 'destination_description',
          'destination': destinationName,
          'location': location,
        },
      );
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to generate destination description', e, stackTrace);
      rethrow;
    }
  }

  /// Generate travel tips
  @override
  Future<String> generateTravelTips({
    required String destination,
    required String travelType, // 'solo', 'family', 'business', 'adventure'
    String? season,
  }) async {
    try {
      AppLogger.debug(_tag, 'Generating travel tips for: $destination');

      final prompt = '''
Generate comprehensive travel tips for $destination, specifically for $travelType travel${season != null ? ' during $season' : ''}.

Please cover:
1. Safety and security tips
2. Cultural do's and don'ts
3. Transportation advice
4. Money and payment methods
5. Language tips and useful phrases
6. Health and medical considerations
7. Packing recommendations
8. Local customs and etiquette
9. Emergency contacts and procedures
10. Connectivity and communication
11. Food and dining tips
12. Shopping and bargaining advice

Make it practical, specific to the destination, and actionable.
''';

      return await generateText(
        prompt: prompt,
        temperature: 0.6,
        maxTokens: 1500,
        context: {
          'type': 'travel_tips',
          'destination': destination,
          'travel_type': travelType,
        },
      );
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to generate travel tips', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // CONTENT ANALYSIS
  // ===============================

  /// Analyze content sentiment
  @override
  Future<Map<String, dynamic>> analyzeSentiment(String text) async {
    try {
      AppLogger.debug(_tag, 'Analyzing sentiment');

      final prompt = '''
Analyze the sentiment of the following text and provide a detailed analysis:

"$text"

Please respond in JSON format with:
{
  "sentiment": "positive|negative|neutral",
  "confidence": 0.0-1.0,
  "emotions": ["happy", "sad", "angry", "excited", etc.],
  "key_phrases": ["phrase1", "phrase2"],
  "summary": "Brief explanation of the analysis"
}
''';

      final response = await generateText(
        prompt: prompt,
        temperature: 0.3,
        maxTokens: 500,
      );

      // Parse JSON response
      try {
        final jsonStart = response.indexOf('{');
        final jsonEnd = response.lastIndexOf('}') + 1;
        if (jsonStart != -1 && jsonEnd != -1) {
          final jsonString = response.substring(jsonStart, jsonEnd);
          return json.decode(jsonString);
        }
      } catch (e) {
        AppLogger.warning(_tag, 'Failed to parse sentiment JSON', e);
      }

      // Fallback if JSON parsing fails
      return {
        'sentiment': 'neutral',
        'confidence': 0.5,
        'emotions': [],
        'key_phrases': [],
        'summary': response,
      };
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to analyze sentiment', e, stackTrace);
      rethrow;
    }
  }

  /// Extract key information from text
  @override
  Future<Map<String, dynamic>> extractInformation(String text) async {
    try {
      AppLogger.debug(_tag, 'Extracting information from text');

      final prompt = '''
Extract key information from the following text:

"$text"

Please respond in JSON format with:
{
  "locations": ["location1", "location2"],
  "dates": ["2024-01-01", "2024-01-02"],
  "people": ["person1", "person2"],
  "organizations": ["org1", "org2"],
  "activities": ["activity1", "activity2"],
  "costs": ["amount1", "amount2"],
  "keywords": ["keyword1", "keyword2"],
  "summary": "Brief summary of the content"
}
''';

      final response = await generateText(
        prompt: prompt,
        temperature: 0.2,
        maxTokens: 600,
      );

      // Parse JSON response
      try {
        final jsonStart = response.indexOf('{');
        final jsonEnd = response.lastIndexOf('}') + 1;
        if (jsonStart != -1 && jsonEnd != -1) {
          final jsonString = response.substring(jsonStart, jsonEnd);
          return json.decode(jsonString);
        }
      } catch (e) {
        AppLogger.warning(_tag, 'Failed to parse information JSON', e);
      }

      return {
        'locations': [],
        'dates': [],
        'people': [],
        'organizations': [],
        'activities': [],
        'costs': [],
        'keywords': [],
        'summary': response,
      };
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to extract information', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // CHAT & CONVERSATIONAL AI
  // ===============================

  /// Chat with AI assistant
  @override
  Future<String> chatWithAssistant({
    required String message,
    List<Map<String, String>>? conversationHistory,
    String? context,
  }) async {
    try {
      AppLogger.debug(_tag, 'Chatting with AI assistant');

      final systemPrompt = '''
You are RelinkAI, a helpful travel assistant for the Relink travel app. You help users with:
- Travel planning and recommendations
- Destination information
- Cultural insights
- Safety tips
- Local customs and etiquette
- Transportation advice
- Budget planning
- Activity suggestions

Be friendly, informative, and practical. Always consider safety and cultural sensitivity.
${context != null ? '\nContext: $context' : ''}
''';

      var fullPrompt = systemPrompt;

      // Add conversation history
      if (conversationHistory != null && conversationHistory.isNotEmpty) {
        fullPrompt += '\n\nConversation history:';
        for (final exchange in conversationHistory) {
          fullPrompt += '\nUser: ${exchange['user']}';
          fullPrompt += '\nAssistant: ${exchange['assistant']}';
        }
      }

      fullPrompt += '\n\nUser: $message\nAssistant:';

      return await generateText(
        prompt: fullPrompt,
        temperature: 0.8,
        maxTokens: 800,
        context: {
          'type': 'chat_assistant',
          'context': context,
        },
      );
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to chat with assistant', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // LOGGING & ANALYTICS
  // ===============================

  /// Log AI request
  Future<String> _logAIRequest({
    String? userId,
    required String model,
    required String prompt,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      final requestData = {
        'user_id': userId,
        'model': model,
        'prompt': prompt,
        'parameters': parameters ?? {},
        'status': 'pending',
        'request_timestamp': DateTime.now().toIso8601String(),
      };

      final result = await SupabaseDatabaseService.insert(
        table: _aiRequestsTable,
        data: requestData,
      );

      return result['id'] as String;
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to log AI request', e);
      return '';
    }
  }

  /// Log AI response
  Future<void> _logAIResponse({
    required String requestId,
    required String response,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Update request status
      await SupabaseDatabaseService.update(
        table: _aiRequestsTable,
        id: requestId,
        data: {
          'status': 'completed',
          'response_timestamp': DateTime.now().toIso8601String(),
        },
      );

      // Log response
      final responseData = {
        'request_id': requestId,
        'response': response,
        'metadata': metadata ?? {},
        'response_length': response.length,
        'created_at': DateTime.now().toIso8601String(),
      };

      await SupabaseDatabaseService.insert(
        table: _aiResponsesTable,
        data: responseData,
      );
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to log AI response', e);
    }
  }

  /// Get AI usage statistics
  @override
  Future<Map<String, dynamic>> getUsageStatistics({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      AppLogger.debug(_tag, 'Getting AI usage statistics');

      final filters = <String, dynamic>{};
      if (userId != null) filters['user_id'] = userId;

      final requests = await SupabaseDatabaseService.select(
        table: _aiRequestsTable,
        filters: filters,
      );

      // Filter by date range if provided
      var filteredRequests = requests;
      if (startDate != null || endDate != null) {
        filteredRequests = requests.where((request) {
          final timestamp = DateTime.parse(request['request_timestamp']);
          if (startDate != null && timestamp.isBefore(startDate)) return false;
          if (endDate != null && timestamp.isAfter(endDate)) return false;
          return true;
        }).toList();
      }

      // Calculate statistics
      final totalRequests = filteredRequests.length;
      final completedRequests = filteredRequests.where((r) => r['status'] == 'completed').length;
      final failedRequests = filteredRequests.where((r) => r['status'] == 'failed').length;

      final modelUsage = <String, int>{};
      for (final request in filteredRequests) {
        final model = request['model'] as String;
        modelUsage[model] = (modelUsage[model] ?? 0) + 1;
      }

      return {
        'total_requests': totalRequests,
        'completed_requests': completedRequests,
        'failed_requests': failedRequests,
        'success_rate': totalRequests > 0 ? completedRequests / totalRequests : 0.0,
        'model_usage': modelUsage,
        'period': {
          'start_date': startDate?.toIso8601String(),
          'end_date': endDate?.toIso8601String(),
        }
      };
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get usage statistics', e, stackTrace);
      rethrow;
    }
  }
}
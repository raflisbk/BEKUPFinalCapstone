import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../core/utils/logger.dart';
import '../supabase_database_service.dart';

/// Gemini AI Service
/// Core service for Google Gemini AI integration and API management
class GeminiService {
  static const String _tag = 'GeminiService';
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta';
  static const String _configTable = 'api_configurations';

  // Gemini models
  static const String modelPro = 'gemini-1.5-pro-latest';
  static const String modelFlash = 'gemini-1.5-flash-latest';
  static const String modelFlash8b = 'gemini-1.5-flash-8b-latest';

  // Rate limiting
  static const int maxRequestsPerMinute = 15; // Free tier limit
  static const int maxTokensPerRequest = 32768; // Input token limit
  static const int maxOutputTokens = 8192; // Output token limit

  // Request tracking
  static final List<DateTime> _requestHistory = [];
  static Timer? _cleanupTimer;

  static String? _cachedApiKey;
  static DateTime? _keyExpiryTime;

  // ===============================
  // API KEY MANAGEMENT
  // ===============================

  /// Get Gemini API key with caching
  static Future<String?> getApiKey() async {
    try {
      // Return cached key if still valid
      if (_cachedApiKey != null && 
          _keyExpiryTime != null && 
          DateTime.now().isBefore(_keyExpiryTime!)) {
        return _cachedApiKey;
      }

      AppLogger.debug(_tag, 'Fetching Gemini API key');

      // Try environment variable first
      final envKey = Platform.environment['GEMINI_API_KEY'];
      if (envKey != null && envKey.isNotEmpty) {
        _cachedApiKey = envKey;
        _keyExpiryTime = DateTime.now().add(const Duration(hours: 1));
        return envKey;
      }

      // Try database configuration
      final configs = await SupabaseDatabaseService.select(
        table: _configTable,
        filters: {'key': 'gemini_api_key', 'is_active': true},
      );

      if (configs.isNotEmpty) {
        final apiKey = configs.first['value'] as String;
        _cachedApiKey = apiKey;
        _keyExpiryTime = DateTime.now().add(const Duration(hours: 1));
        return apiKey;
      }

      AppLogger.error(_tag, 'No Gemini API key found');
      return null;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get API key', e, stackTrace);
      return null;
    }
  }

  /// Update API key in database
  static Future<void> updateApiKey(String apiKey) async {
    try {
      AppLogger.debug(_tag, 'Updating Gemini API key');

      // Try to update existing record first
      final existingConfigs = await SupabaseDatabaseService.select(
        table: _configTable,
        filters: {'key': 'gemini_api_key'},
      );

      if (existingConfigs.isNotEmpty) {
        await SupabaseDatabaseService.update(
          table: _configTable,
          id: existingConfigs.first['id'],
          data: {
            'value': apiKey,
            'is_active': true,
            'updated_at': DateTime.now().toIso8601String(),
          },
        );
      } else {
        await SupabaseDatabaseService.insert(
          table: _configTable,
          data: {
            'key': 'gemini_api_key',
            'value': apiKey,
            'is_active': true,
            'created_at': DateTime.now().toIso8601String(),
          },
        );
      }

      // Clear cached key to force refresh
      _cachedApiKey = null;
      _keyExpiryTime = null;

      AppLogger.success(_tag, 'API key updated successfully');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to update API key', e, stackTrace);
      rethrow;
    }
  }

  /// Validate API key
  static Future<bool> validateApiKey([String? apiKey]) async {
    try {
      final key = apiKey ?? await getApiKey();
      if (key == null) return false;

      AppLogger.debug(_tag, 'Validating Gemini API key');

      const testPrompt = 'Hello, are you working?';
      final response = await _makeRequest(
        endpoint: 'models/$modelFlash:generateContent',
        data: {
          'contents': [
            {
              'parts': [
                {'text': testPrompt}
              ]
            }
          ],
          'generationConfig': {
            'maxOutputTokens': 10,
            'temperature': 0.1,
          }
        },
        apiKey: key,
      );

      final isValid = response['error'] == null;
      AppLogger.info(_tag, 'API key validation: ${isValid ? 'VALID' : 'INVALID'}');
      return isValid;
    } catch (e) {
      AppLogger.warning(_tag, 'API key validation failed', e);
      return false;
    }
  }

  // ===============================
  // RATE LIMITING
  // ===============================

  /// Check if request is allowed under rate limits
  static bool _isRequestAllowed() {
    final now = DateTime.now();
    
    // Clean old requests (older than 1 minute)
    _requestHistory.removeWhere(
      (time) => now.difference(time).inMinutes > 1,
    );

    // Check if under limit
    if (_requestHistory.length >= maxRequestsPerMinute) {
      AppLogger.warning(_tag, 'Rate limit exceeded: ${_requestHistory.length} requests in last minute');
      return false;
    }

    return true;
  }

  /// Add request to history
  static void _recordRequest() {
    _requestHistory.add(DateTime.now());
    
    // Start cleanup timer if not already running
    _cleanupTimer ??= Timer.periodic(const Duration(minutes: 1), (timer) {
      final now = DateTime.now();
      _requestHistory.removeWhere(
        (time) => now.difference(time).inMinutes > 1,
      );
      
      // Stop timer if no recent requests
      if (_requestHistory.isEmpty) {
        timer.cancel();
        _cleanupTimer = null;
      }
    });
  }

  /// Get current rate limit status
  static Map<String, dynamic> getRateLimitStatus() {
    final now = DateTime.now();
    final recentRequests = _requestHistory.where(
      (time) => now.difference(time).inMinutes <= 1,
    ).length;

    return {
      'requests_in_last_minute': recentRequests,
      'max_requests_per_minute': maxRequestsPerMinute,
      'remaining_requests': maxRequestsPerMinute - recentRequests,
      'is_rate_limited': recentRequests >= maxRequestsPerMinute,
      'reset_time': _requestHistory.isNotEmpty 
          ? _requestHistory.first.add(const Duration(minutes: 1))
          : now,
    };
  }

  // ===============================
  // CORE API METHODS
  // ===============================

  /// Make authenticated request to Gemini API
  static Future<Map<String, dynamic>> _makeRequest({
    required String endpoint,
    required Map<String, dynamic> data,
    String? apiKey,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      final key = apiKey ?? await getApiKey();
      if (key == null) {
        throw Exception('Gemini API key not configured');
      }

      final url = Uri.parse('$_baseUrl/$endpoint?key=$key');
      
      AppLogger.debug(_tag, 'Making request to: $endpoint');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data),
      ).timeout(timeout);

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        AppLogger.debug(_tag, 'Request successful');
        return responseData;
      } else {
        final errorMessage = responseData['error']?['message'] ?? 'Unknown error';
        AppLogger.error(_tag, 'API error: $errorMessage (${response.statusCode})');
        throw Exception('Gemini API error: $errorMessage');
      }
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Request failed', e, stackTrace);
      rethrow;
    }
  }

  /// Generate content using Gemini
  static Future<String> generateContent({
    required String prompt,
    String model = modelFlash,
    double temperature = 0.7,
    int maxOutputTokens = 2048,
    List<String>? stopSequences,
    Map<String, dynamic>? systemInstruction,
  }) async {
    try {
      // Check rate limit
      if (!_isRequestAllowed()) {
        throw Exception('Rate limit exceeded. Please wait before making another request.');
      }

      AppLogger.debug(_tag, 'Generating content with model: $model');

      final data = {
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': temperature,
          'maxOutputTokens': maxOutputTokens,
          if (stopSequences != null) 'stopSequences': stopSequences,
        },
        if (systemInstruction != null) 'systemInstruction': systemInstruction,
      };

      final response = await _makeRequest(
        endpoint: 'models/$model:generateContent',
        data: data,
      );

      // Record request for rate limiting
      _recordRequest();

      // Extract generated text
      final candidates = response['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        throw Exception('No content generated');
      }

      final content = candidates.first['content'];
      final parts = content['parts'] as List;
      if (parts.isEmpty) {
        throw Exception('No text parts in response');
      }

      final generatedText = parts.first['text'] as String;
      
      AppLogger.success(_tag, 'Content generated successfully');
      return generatedText;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to generate content', e, stackTrace);
      rethrow;
    }
  }

  /// Generate content with image input
  static Future<String> generateContentWithImage({
    required String prompt,
    required String imageBase64,
    String mimeType = 'image/jpeg',
    String model = modelFlash,
    double temperature = 0.7,
    int maxOutputTokens = 2048,
  }) async {
    try {
      // Check rate limit
      if (!_isRequestAllowed()) {
        throw Exception('Rate limit exceeded. Please wait before making another request.');
      }

      AppLogger.debug(_tag, 'Generating content with image input');

      final data = {
        'contents': [
          {
            'parts': [
              {'text': prompt},
              {
                'inlineData': {
                  'mimeType': mimeType,
                  'data': imageBase64,
                }
              }
            ]
          }
        ],
        'generationConfig': {
          'temperature': temperature,
          'maxOutputTokens': maxOutputTokens,
        },
      };

      final response = await _makeRequest(
        endpoint: 'models/$model:generateContent',
        data: data,
      );

      // Record request for rate limiting
      _recordRequest();

      // Extract generated text
      final candidates = response['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        throw Exception('No content generated');
      }

      final content = candidates.first['content'];
      final parts = content['parts'] as List;
      if (parts.isEmpty) {
        throw Exception('No text parts in response');
      }

      final generatedText = parts.first['text'] as String;
      
      AppLogger.success(_tag, 'Content with image generated successfully');
      return generatedText;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to generate content with image', e, stackTrace);
      rethrow;
    }
  }

  /// Start chat session
  static Future<Map<String, dynamic>> startChatSession({
    String model = modelFlash,
    List<Map<String, dynamic>>? history,
    Map<String, dynamic>? systemInstruction,
    Map<String, dynamic>? generationConfig,
  }) async {
    try {
      AppLogger.debug(_tag, 'Starting chat session');

      final data = <String, dynamic>{
        if (history != null) 'history': history,
        if (systemInstruction != null) 'systemInstruction': systemInstruction,
        if (generationConfig != null) 'generationConfig': generationConfig,
      };

      final response = await _makeRequest(
        endpoint: 'models/$model:startChat',
        data: data,
      );

      AppLogger.success(_tag, 'Chat session started');
      return response;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to start chat session', e, stackTrace);
      rethrow;
    }
  }

  /// Send message in chat session
  static Future<String> sendChatMessage({
    required String message,
    required String sessionId,
    String model = modelFlash,
    double temperature = 0.7,
    int maxOutputTokens = 2048,
  }) async {
    try {
      // Check rate limit
      if (!_isRequestAllowed()) {
        throw Exception('Rate limit exceeded. Please wait before making another request.');
      }

      AppLogger.debug(_tag, 'Sending chat message');

      final data = {
        'contents': [
          {
            'parts': [
              {'text': message}
            ]
          }
        ],
        'generationConfig': {
          'temperature': temperature,
          'maxOutputTokens': maxOutputTokens,
        },
      };

      final response = await _makeRequest(
        endpoint: 'models/$model:generateContent',
        data: data,
      );

      // Record request for rate limiting
      _recordRequest();

      // Extract response text
      final candidates = response['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        throw Exception('No response generated');
      }

      final content = candidates.first['content'];
      final parts = content['parts'] as List;
      if (parts.isEmpty) {
        throw Exception('No text parts in response');
      }

      final responseText = parts.first['text'] as String;
      
      AppLogger.success(_tag, 'Chat message sent successfully');
      return responseText;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to send chat message', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // UTILITY METHODS
  // ===============================

  /// Get available models
  static Future<List<Map<String, dynamic>>> getAvailableModels() async {
    try {
      AppLogger.debug(_tag, 'Getting available models');

      final response = await _makeRequest(
        endpoint: 'models',
        data: {},
      );

      final models = response['models'] as List? ?? [];
      final modelList = models.cast<Map<String, dynamic>>();

      AppLogger.success(_tag, 'Retrieved ${modelList.length} models');
      return modelList;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get models', e, stackTrace);
      return [];
    }
  }

  /// Get model information
  static Future<Map<String, dynamic>?> getModelInfo(String modelName) async {
    try {
      AppLogger.debug(_tag, 'Getting model info: $modelName');

      final response = await _makeRequest(
        endpoint: 'models/$modelName',
        data: {},
      );

      AppLogger.success(_tag, 'Model info retrieved');
      return response;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get model info', e, stackTrace);
      return null;
    }
  }

  /// Count tokens in text
  static Future<int> countTokens({
    required String text,
    String model = modelFlash,
  }) async {
    try {
      AppLogger.debug(_tag, 'Counting tokens');

      final data = {
        'contents': [
          {
            'parts': [
              {'text': text}
            ]
          }
        ],
      };

      final response = await _makeRequest(
        endpoint: 'models/$model:countTokens',
        data: data,
      );

      final tokenCount = response['totalTokens'] as int? ?? 0;
      
      AppLogger.debug(_tag, 'Token count: $tokenCount');
      return tokenCount;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to count tokens', e, stackTrace);
      return 0;
    }
  }

  /// Check service health
  static Future<bool> checkHealth() async {
    try {
      AppLogger.debug(_tag, 'Checking service health');

      final models = await getAvailableModels();
      final isHealthy = models.isNotEmpty;

      AppLogger.info(_tag, 'Service health: ${isHealthy ? 'HEALTHY' : 'UNHEALTHY'}');
      return isHealthy;
    } catch (e) {
      AppLogger.warning(_tag, 'Health check failed', e);
      return false;
    }
  }

  /// Get service statistics
  static Map<String, dynamic> getServiceStatistics() {
    final rateLimitStatus = getRateLimitStatus();
    
    return {
      'api_key_cached': _cachedApiKey != null,
      'key_expiry': _keyExpiryTime?.toIso8601String(),
      'total_requests_tracked': _requestHistory.length,
      'rate_limit_status': rateLimitStatus,
      'available_models': [modelPro, modelFlash, modelFlash8b],
      'max_tokens_per_request': maxTokensPerRequest,
      'max_output_tokens': maxOutputTokens,
    };
  }

  /// Clear cached data
  static void clearCache() {
    AppLogger.debug(_tag, 'Clearing cached data');
    
    _cachedApiKey = null;
    _keyExpiryTime = null;
    _requestHistory.clear();
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
  }

  /// Dispose resources
  static void dispose() {
    AppLogger.debug(_tag, 'Disposing resources');
    
    clearCache();
  }
}
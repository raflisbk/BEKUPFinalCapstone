import 'dart:convert';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Service for managing Google Gemini AI operations
class GeminiService {
  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;
  GeminiService._internal();

  late final GenerativeModel _model;
  late final GenerativeModel _visionModel;
  bool _isInitialized = false;

  /// Initialize Gemini AI with API key from environment
  Future<void> initialize() async {
    if (_isInitialized) {
      print('[GeminiService] Already initialized');
      return;
    }

    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('GEMINI_API_KEY not found in .env file');
      }

      // Initialize text model (Gemini 2.0 Flash - newest & fastest)
      _model = GenerativeModel(
        model: 'gemini-2.0-flash-exp',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.7,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 8192,
        ),
        safetySettings: [
          SafetySetting(
            HarmCategory.harassment,
            HarmBlockThreshold.medium,
          ),
          SafetySetting(
            HarmCategory.hateSpeech,
            HarmBlockThreshold.medium,
          ),
          SafetySetting(
            HarmCategory.sexuallyExplicit,
            HarmBlockThreshold.medium,
          ),
          SafetySetting(
            HarmCategory.dangerousContent,
            HarmBlockThreshold.medium,
          ),
        ],
      );

      // Initialize vision model for image analysis
      _visionModel = GenerativeModel(
        model: 'gemini-2.0-flash-exp',
        apiKey: apiKey,
      );

      _isInitialized = true;
      print('[GeminiService] ✅ Initialized successfully');
    } catch (e) {
      print('[GeminiService] ❌ Initialization failed: $e');
      rethrow;
    }
  }

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Generate text response from prompt
  Future<String> generateText(String prompt) async {
    _ensureInitialized();

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      if (response.text == null || response.text!.isEmpty) {
        throw Exception('Empty response from Gemini API');
      }

      return response.text!;
    } catch (e) {
      print('[GeminiService] Error generating text: $e');
      rethrow;
    }
  }

  /// Generate response with chat history (for conversational AI)
  Future<String> generateChat({
    required String prompt,
    required List<Map<String, String>> history,
  }) async {
    _ensureInitialized();

    try {
      // Convert history to Gemini format
      final chatHistory = history.map((msg) {
        return Content(
          msg['role'] == 'user' ? 'user' : 'model',
          [TextPart(msg['content']!)],
        );
      }).toList();

      // Start chat session
      final chat = _model.startChat(history: chatHistory);

      // Send message
      final response = await chat.sendMessage(
        Content.text(prompt),
      );

      if (response.text == null || response.text!.isEmpty) {
        throw Exception('Empty response from Gemini API');
      }

      return response.text!;
    } catch (e) {
      print('[GeminiService] Error in chat: $e');
      rethrow;
    }
  }

  /// Generate structured JSON response
  Future<Map<String, dynamic>> generateJSON(String prompt) async {
    _ensureInitialized();

    try {
      // Add JSON formatting instruction to prompt
      final jsonPrompt = '''
$prompt

IMPORTANT: Respond ONLY with valid JSON. No markdown, no explanations, just pure JSON.
''';

      final response = await generateText(jsonPrompt);

      // Clean response (remove markdown if present)
      String cleanedResponse = response.trim();
      if (cleanedResponse.startsWith('```json')) {
        cleanedResponse = cleanedResponse.substring(7);
      }
      if (cleanedResponse.startsWith('```')) {
        cleanedResponse = cleanedResponse.substring(3);
      }
      if (cleanedResponse.endsWith('```')) {
        cleanedResponse = cleanedResponse.substring(0, cleanedResponse.length - 3);
      }
      cleanedResponse = cleanedResponse.trim();

      // Parse JSON
      final jsonResponse = parseJSON(cleanedResponse);
      return jsonResponse;
    } catch (e) {
      print('[GeminiService] Error generating JSON: $e');
      rethrow;
    }
  }

  /// Analyze image and generate description
  Future<String> analyzeImage({
    required Uint8List imageBytes,
    required String prompt,
  }) async {
    _ensureInitialized();

    try {
      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ])
      ];

      final response = await _visionModel.generateContent(content);

      if (response.text == null || response.text!.isEmpty) {
        throw Exception('Empty response from Gemini Vision API');
      }

      return response.text!;
    } catch (e) {
      print('[GeminiService] Error analyzing image: $e');
      rethrow;
    }
  }

  /// Generate response with streaming (for real-time chat)
  Stream<String> generateStream(String prompt) async* {
    _ensureInitialized();

    try {
      final content = [Content.text(prompt)];
      final response = _model.generateContentStream(content);

      await for (final chunk in response) {
        if (chunk.text != null && chunk.text!.isNotEmpty) {
          yield chunk.text!;
        }
      }
    } catch (e) {
      print('[GeminiService] Error in streaming: $e');
      rethrow;
    }
  }

  /// Count tokens in text (for cost estimation)
  Future<int> countTokens(String text) async {
    _ensureInitialized();

    try {
      final content = [Content.text(text)];
      final response = await _model.countTokens(content);
      return response.totalTokens;
    } catch (e) {
      print('[GeminiService] Error counting tokens: $e');
      return 0;
    }
  }

  /// Parse JSON safely
  Map<String, dynamic> parseJSON(String jsonString) {
    try {
      // Try direct parse
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      // Try to extract JSON from text
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(jsonString);
      if (jsonMatch != null) {
        try {
          return jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
        } catch (e2) {
          throw Exception('Failed to parse JSON: $e2');
        }
      }
      throw Exception('No valid JSON found in response');
    }
  }

  /// Ensure service is initialized before use
  void _ensureInitialized() {
    if (!_isInitialized) {
      throw Exception('GeminiService not initialized. Call initialize() first.');
    }
  }

  /// Dispose resources
  void dispose() {
    _isInitialized = false;
    print('[GeminiService] Disposed');
  }
}

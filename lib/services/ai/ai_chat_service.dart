import 'dart:async';
import 'dart:convert';
import '../../core/utils/logger.dart';
import '../supabase_config.dart';
import '../supabase_database_service.dart';
import 'gemini_service.dart';

/// AI Chat Service  
/// Handles AI-powered chat assistant for travel planning and support
class AIChatService {
  static const String _tag = 'AIChatService';
  static const String _chatSessionsTable = 'ai_chat_sessions';
  static const String _chatMessagesTable = 'ai_chat_messages';

  // Message types
  static const String messageTypeUser = 'user';
  static const String messageTypeAssistant = 'assistant';
  static const String messageTypeSystem = 'system';

  // Session types
  static const String sessionTypePlanning = 'trip_planning';
  static const String sessionTypeSupport = 'customer_support';
  static const String sessionTypeGeneral = 'general_chat';
  static const String sessionTypeRecommendation = 'recommendation';

  // Context types
  static const String contextTrip = 'trip_data';
  static const String contextUser = 'user_profile';
  static const String contextDestination = 'destination_info';
  static const String contextWeather = 'weather_data';

  // ===============================
  // CHAT SESSION MANAGEMENT
  // ===============================

  /// Start new AI chat session
  static Future<Map<String, dynamic>> startChatSession({
    String sessionType = sessionTypeGeneral,
    String? title,
    Map<String, dynamic>? initialContext,
  }) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Starting AI chat session: $sessionType');

      // Create session record
      final sessionData = {
        'user_id': userId,
        'session_type': sessionType,
        'title': title ?? _generateSessionTitle(sessionType),
        'status': 'active',
        'message_count': 0,
        'context': initialContext ?? {},
        'created_at': DateTime.now().toIso8601String(),
      };

      final session = await SupabaseDatabaseService.insert(
        table: _chatSessionsTable,
        data: sessionData,
      );

      // Add system message with context
      await _addSystemMessage(
        session['id'],
        _buildSystemPrompt(sessionType, initialContext),
      );

      // Send welcome message
      await _sendWelcomeMessage(session['id'], sessionType);

      AppLogger.success(_tag, 'AI chat session started: ${session['id']}');
      return session;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to start chat session', e, stackTrace);
      rethrow;
    }
  }

  /// Get user's chat sessions
  static Future<List<Map<String, dynamic>>> getChatSessions({
    String? userId,
    String? sessionType,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final targetUserId = userId ?? SupabaseConfig.userId;
      if (targetUserId == null) {
        throw Exception('No user ID provided');
      }

      AppLogger.debug(_tag, 'Getting chat sessions for user: $targetUserId');

      final filters = <String, dynamic>{'user_id': targetUserId};
      if (sessionType != null) filters['session_type'] = sessionType;

      final sessions = await SupabaseDatabaseService.select(
        table: _chatSessionsTable,
        filters: filters,
        orderBy: 'updated_at',
        ascending: false,
        limit: limit,
        offset: offset,
      );

      // Enrich with last message
      for (final session in sessions) {
        await _enrichSessionData(session);
      }

      AppLogger.success(_tag, 'Retrieved ${sessions.length} chat sessions');
      return sessions;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get chat sessions', e, stackTrace);
      return [];
    }
  }

  /// Get chat session by ID
  static Future<Map<String, dynamic>?> getChatSession(String sessionId) async {
    try {
      AppLogger.debug(_tag, 'Getting chat session: $sessionId');

      final sessions = await SupabaseDatabaseService.select(
        table: _chatSessionsTable,
        filters: {'id': sessionId},
      );

      if (sessions.isEmpty) {
        AppLogger.warning(_tag, 'Chat session not found: $sessionId');
        return null;
      }

      final session = sessions.first;
      await _enrichSessionData(session);

      AppLogger.success(_tag, 'Retrieved chat session: ${session['title']}');
      return session;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get chat session', e, stackTrace);
      return null;
    }
  }

  // ===============================
  // MESSAGE HANDLING
  // ===============================

  /// Send message to AI assistant
  static Future<Map<String, dynamic>> sendMessage({
    required String sessionId,
    required String message,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Sending message to AI: $sessionId');

      // Verify session ownership
      final session = await getChatSession(sessionId);
      if (session == null || session['user_id'] != userId) {
        throw Exception('Session not found or not owned by user');
      }

      // Save user message
      final userMessage = await _saveMessage(
        sessionId,
        messageTypeUser,
        message,
        metadata,
      );

      // Get conversation history
      final conversationHistory = await _getConversationHistory(sessionId);

      // Generate AI response
      final aiResponse = await _generateAIResponse(
        sessionId,
        message,
        conversationHistory,
        session['context'] as Map<String, dynamic>? ?? {},
      );

      // Save AI response
      final assistantMessage = await _saveMessage(
        sessionId,
        messageTypeAssistant,
        aiResponse,
        {'generated_at': DateTime.now().toIso8601String()},
      );

      // Update session
      await _updateSessionActivity(sessionId);

      AppLogger.success(_tag, 'AI message exchange completed');
      return {
        'user_message': userMessage,
        'assistant_message': assistantMessage,
        'session_updated': true,
      };
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to send message', e, stackTrace);
      rethrow;
    }
  }

  /// Get chat messages
  static Future<List<Map<String, dynamic>>> getChatMessages({
    required String sessionId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      AppLogger.debug(_tag, 'Getting chat messages: $sessionId');

      final messages = await SupabaseDatabaseService.select(
        table: _chatMessagesTable,
        filters: {'session_id': sessionId},
        orderBy: 'created_at',
        ascending: true,
        limit: limit,
        offset: offset,
      );

      // Filter out system messages for user view
      final userMessages = messages.where(
        (msg) => msg['message_type'] != messageTypeSystem,
      ).toList();

      AppLogger.success(_tag, 'Retrieved ${userMessages.length} chat messages');
      return userMessages;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get chat messages', e, stackTrace);
      return [];
    }
  }

  /// Clear chat history
  static Future<void> clearChatHistory(String sessionId) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Clearing chat history: $sessionId');

      // Verify ownership
      final session = await getChatSession(sessionId);
      if (session == null || session['user_id'] != userId) {
        throw Exception('Session not found or not owned by user');
      }

      // Delete all non-system messages
      final messages = await SupabaseDatabaseService.select(
        table: _chatMessagesTable,
        filters: {'session_id': sessionId},
      );

      for (final message in messages) {
        if (message['message_type'] != messageTypeSystem) {
          await SupabaseDatabaseService.delete(
            table: _chatMessagesTable,
            id: message['id'],
          );
        }
      }

      // Reset session message count
      await SupabaseDatabaseService.update(
        table: _chatSessionsTable,
        id: sessionId,
        data: {
          'message_count': 0,
          'updated_at': DateTime.now().toIso8601String(),
        },
      );

      AppLogger.success(_tag, 'Chat history cleared');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to clear chat history', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // CONTEXT MANAGEMENT
  // ===============================

  /// Update chat context
  static Future<void> updateChatContext({
    required String sessionId,
    required Map<String, dynamic> context,
  }) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Updating chat context: $sessionId');

      // Verify ownership
      final session = await getChatSession(sessionId);
      if (session == null || session['user_id'] != userId) {
        throw Exception('Session not found or not owned by user');
      }

      // Merge with existing context
      final existingContext = session['context'] as Map<String, dynamic>? ?? {};
      final mergedContext = {...existingContext, ...context};

      await SupabaseDatabaseService.update(
        table: _chatSessionsTable,
        id: sessionId,
        data: {
          'context': mergedContext,
          'updated_at': DateTime.now().toIso8601String(),
        },
      );

      AppLogger.success(_tag, 'Chat context updated');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to update chat context', e, stackTrace);
      rethrow;
    }
  }

  /// Add trip context to chat
  static Future<void> addTripContext({
    required String sessionId,
    required Map<String, dynamic> tripData,
  }) async {
    try {
      AppLogger.debug(_tag, 'Adding trip context to chat');

      await updateChatContext(
        sessionId: sessionId,
        context: {contextTrip: tripData},
      );

      // Add context message for AI
      await _addSystemMessage(
        sessionId,
        'Trip context updated: ${tripData['destination']} for ${tripData['duration']} days',
      );

      AppLogger.success(_tag, 'Trip context added');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to add trip context', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // SPECIALIZED CHAT FUNCTIONS
  // ===============================

  /// Start trip planning chat
  static Future<Map<String, dynamic>> startTripPlanningChat({
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    double? budget,
  }) async {
    try {
      AppLogger.debug(_tag, 'Starting trip planning chat');

      final context = <String, dynamic>{};
      if (destination != null) context['destination'] = destination;
      if (startDate != null) context['start_date'] = startDate.toIso8601String();
      if (endDate != null) context['end_date'] = endDate.toIso8601String();
      if (budget != null) context['budget'] = budget;

      return await startChatSession(
        sessionType: sessionTypePlanning,
        title: 'Trip Planning: ${destination ?? 'New Trip'}',
        initialContext: context,
      );
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to start trip planning chat', e, stackTrace);
      rethrow;
    }
  }

  /// Start recommendation chat
  static Future<Map<String, dynamic>> startRecommendationChat({
    String? location,
    String? category,
  }) async {
    try {
      AppLogger.debug(_tag, 'Starting recommendation chat');

      final context = <String, dynamic>{};
      if (location != null) context['location'] = location;
      if (category != null) context['category'] = category;

      return await startChatSession(
        sessionType: sessionTypeRecommendation,
        title: 'Recommendations: ${location ?? 'Travel Advice'}',
        initialContext: context,
      );
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to start recommendation chat', e, stackTrace);
      rethrow;
    }
  }

  /// Get quick travel advice
  static Future<String> getQuickAdvice({
    required String question,
    String? location,
    Map<String, dynamic>? context,
  }) async {
    try {
      AppLogger.debug(_tag, 'Getting quick travel advice');

      final prompt = _buildQuickAdvicePrompt(question, location, context);

      final response = await GeminiService.generateContent(
        prompt: prompt,
        model: GeminiService.modelFlash,
        temperature: 0.7,
        maxOutputTokens: 1024,
      );

      AppLogger.success(_tag, 'Quick advice generated');
      return response;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get quick advice', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // PRIVATE HELPER METHODS
  // ===============================

  /// Generate session title
  static String _generateSessionTitle(String sessionType) {
    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    
    switch (sessionType) {
      case sessionTypePlanning:
        return 'Trip Planning - $timeStr';
      case sessionTypeSupport:
        return 'Support Chat - $timeStr';
      case sessionTypeRecommendation:
        return 'Travel Advice - $timeStr';
      default:
        return 'Chat Session - $timeStr';
    }
  }

  /// Build system prompt based on session type
  static String _buildSystemPrompt(
    String sessionType,
    Map<String, dynamic>? context,
  ) {
    const basePrompt = '''
You are ReLink AI, a friendly and knowledgeable travel assistant for Indonesia. You help users plan trips, find destinations, get recommendations, and solve travel-related problems.

PERSONALITY:
- Friendly, helpful, and enthusiastic about travel
- Expert knowledge of Indonesian destinations, culture, and travel
- Practical and budget-conscious advice
- Cultural sensitivity and local insights

CAPABILITIES:
- Trip planning and itinerary creation
- Destination recommendations
- Budget optimization
- Cultural guidance and local tips
- Weather and timing advice
- Transportation and accommodation suggestions
''';

    switch (sessionType) {
      case sessionTypePlanning:
        return '''$basePrompt

CURRENT SESSION: Trip Planning
Focus on helping the user create a comprehensive travel plan.
Context: ${jsonEncode(context ?? {})}
''';

      case sessionTypeRecommendation:
        return '''$basePrompt

CURRENT SESSION: Travel Recommendations
Provide personalized suggestions based on user preferences.
Context: ${jsonEncode(context ?? {})}
''';

      case sessionTypeSupport:
        return '''$basePrompt

CURRENT SESSION: Customer Support
Help resolve issues and answer questions about using ReLink.
Context: ${jsonEncode(context ?? {})}
''';

      default:
        return '''$basePrompt

CURRENT SESSION: General Chat
Be helpful with any travel-related questions or conversations.
Context: ${jsonEncode(context ?? {})}
''';
    }
  }

  /// Send welcome message
  static Future<void> _sendWelcomeMessage(String sessionId, String sessionType) async {
    try {
      String welcomeMessage;
      
      switch (sessionType) {
        case sessionTypePlanning:
          welcomeMessage = '''
🗺️ Halo! Saya ReLink AI, asisten perjalanan Anda!

Saya siap membantu merencanakan trip yang amazing! ✈️

Ceritakan rencana perjalanan Anda:
• Mau ke mana?
• Kapan berangkat?
• Berapa lama?
• Budget berapa?

Mari kita buat itinerary yang perfect! 🌟
''';
          break;

        case sessionTypeRecommendation:
          welcomeMessage = '''
🌟 Halo! Saya di sini untuk memberikan rekomendasi travel terbaik!

Saya bisa bantu dengan:
• Destinasi wisata menarik
• Tempat makan enak
• Aktivitas seru
• Tips hemat budget
• Insight lokal

Ada yang ingin ditanyakan? 😊
''';
          break;

        case sessionTypeSupport:
          welcomeMessage = '''
🤝 Halo! Saya tim support ReLink AI.

Saya siap membantu dengan:
• Masalah aplikasi
• Pertanyaan fitur
• Panduan penggunaan
• Feedback dan saran

Bagaimana saya bisa membantu Anda hari ini?
''';
          break;

        default:
          welcomeMessage = '''
👋 Halo! Saya ReLink AI, teman perjalanan Indonesia Anda!

Saya bisa membantu dengan semua hal travel:
• Rencana perjalanan
• Rekomendasi destinasi  
• Tips dan insight lokal
• Solusi masalah travel

Ada yang bisa saya bantu? 😊
''';
      }

      await _saveMessage(
        sessionId,
        messageTypeAssistant,
        welcomeMessage,
        {'is_welcome': true},
      );
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to send welcome message', e);
    }
  }

  /// Add system message
  static Future<void> _addSystemMessage(String sessionId, String content) async {
    try {
      await _saveMessage(
        sessionId,
        messageTypeSystem,
        content,
        {'system_timestamp': DateTime.now().toIso8601String()},
      );
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to add system message', e);
    }
  }

  /// Save message to database
  static Future<Map<String, dynamic>> _saveMessage(
    String sessionId,
    String messageType,
    String content,
    Map<String, dynamic>? metadata,
  ) async {
    try {
      final messageData = {
        'session_id': sessionId,
        'message_type': messageType,
        'content': content,
        'metadata': metadata ?? {},
        'created_at': DateTime.now().toIso8601String(),
      };

      final message = await SupabaseDatabaseService.insert(
        table: _chatMessagesTable,
        data: messageData,
      );

      return message;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to save message', e, stackTrace);
      rethrow;
    }
  }

  /// Get conversation history
  static Future<List<Map<String, dynamic>>> _getConversationHistory(
    String sessionId,
    {int limit = 20}
  ) async {
    try {
      final messages = await SupabaseDatabaseService.select(
        table: _chatMessagesTable,
        filters: {'session_id': sessionId},
        orderBy: 'created_at',
        ascending: false,
        limit: limit,
      );

      return messages.reversed.toList();
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to get conversation history', e);
      return [];
    }
  }

  /// Generate AI response
  static Future<String> _generateAIResponse(
    String sessionId,
    String userMessage,
    List<Map<String, dynamic>> conversationHistory,
    Map<String, dynamic> context,
  ) async {
    try {
      final prompt = _buildConversationPrompt(
        userMessage,
        conversationHistory,
        context,
      );

      final response = await GeminiService.generateContent(
        prompt: prompt,
        model: GeminiService.modelPro,
        temperature: 0.8,
        maxOutputTokens: 2048,
      );

      return response;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to generate AI response', e, stackTrace);
      return 'Maaf, saya mengalami kendala teknis. Coba tanyakan lagi dalam beberapa saat ya! 😅';
    }
  }

  /// Build conversation prompt
  static String _buildConversationPrompt(
    String userMessage,
    List<Map<String, dynamic>> conversationHistory,
    Map<String, dynamic> context,
  ) {
    final historyText = conversationHistory.map((msg) {
      final type = msg['message_type'] as String;
      final content = msg['content'] as String;
      
      if (type == messageTypeSystem) return 'SYSTEM: $content';
      if (type == messageTypeUser) return 'USER: $content';
      if (type == messageTypeAssistant) return 'ASSISTANT: $content';
      
      return '';
    }).where((text) => text.isNotEmpty).join('\n');

    return '''
Continue this conversation as ReLink AI, the Indonesian travel assistant.

CONVERSATION HISTORY:
$historyText

CURRENT CONTEXT:
${jsonEncode(context)}

CURRENT USER MESSAGE:
$userMessage

INSTRUCTIONS:
- Respond in Bahasa Indonesia (friendly, casual tone)
- Use emojis appropriately
- Provide specific, actionable travel advice
- Reference context when relevant
- Ask follow-up questions to better help
- Keep responses conversational but informative

RESPONSE:
''';
  }

  /// Build quick advice prompt
  static String _buildQuickAdvicePrompt(
    String question,
    String? location,
    Map<String, dynamic>? context,
  ) {
    return '''
Provide quick travel advice as ReLink AI assistant.

QUESTION: $question
LOCATION: ${location ?? 'Not specified'}
CONTEXT: ${jsonEncode(context ?? {})}

Instructions:
- Answer in Bahasa Indonesia
- Be concise but helpful (max 3 paragraphs)
- Include practical tips
- Use friendly tone with emojis

ANSWER:
''';
  }

  /// Enrich session data
  static Future<void> _enrichSessionData(Map<String, dynamic> session) async {
    try {
      // Get last message
      final lastMessages = await SupabaseDatabaseService.select(
        table: _chatMessagesTable,
        filters: {'session_id': session['id']},
        orderBy: 'created_at',
        ascending: false,
        limit: 1,
      );

      if (lastMessages.isNotEmpty) {
        session['last_message'] = lastMessages.first;
      }

      // Add computed fields
      session['is_active'] = session['status'] == 'active';
      session['age'] = DateTime.now().difference(
        DateTime.parse(session['created_at']),
      ).inDays;
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to enrich session data', e);
    }
  }

  /// Update session activity
  static Future<void> _updateSessionActivity(String sessionId) async {
    try {
      // Get current message count
      final messages = await SupabaseDatabaseService.select(
        table: _chatMessagesTable,
        filters: {'session_id': sessionId},
      );

      final messageCount = messages.where(
        (msg) => msg['message_type'] != messageTypeSystem,
      ).length;

      await SupabaseDatabaseService.update(
        table: _chatSessionsTable,
        id: sessionId,
        data: {
          'message_count': messageCount,
          'updated_at': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to update session activity', e);
    }
  }
}
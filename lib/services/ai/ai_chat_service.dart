import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/trip_model.dart';
import '../../core/models/destination_model.dart';
import 'gemini_service.dart';

/// Service for AI-powered chat assistant
class AIChatService {
  final GeminiService _geminiService = GeminiService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Start a new chat session with context
  Future<ChatSession> startChatSession({
    required String userId,
    Trip? currentTrip,
    Destination? currentDestination,
  }) async {
    final session = ChatSession(
      sessionId: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      startedAt: DateTime.now(),
      messages: [],
      context: ChatContext(
        currentTrip: currentTrip,
        currentDestination: currentDestination,
      ),
    );

    // Save session to Firestore
    await _firestore
        .collection('chat_sessions')
        .doc(session.sessionId)
        .set(session.toMap());

    return session;
  }

  /// Send message and get AI response
  Future<ChatMessage> sendMessage({
    required ChatSession session,
    required String userMessage,
  }) async {
    try {
      // Add user message
      final userMsg = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: ChatRole.user,
        content: userMessage,
        timestamp: DateTime.now(),
      );

      session.messages.add(userMsg);

      // Build context-aware prompt
      final systemPrompt = _buildSystemPrompt(session.context);
      final conversationHistory = _buildConversationHistory(session.messages);

      // Get AI response
      final aiResponse = await _geminiService.generateChat(
        prompt: '$systemPrompt\n\nUser: $userMessage',
        history: conversationHistory,
      );

      // Create AI message
      final aiMsg = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: ChatRole.assistant,
        content: aiResponse,
        timestamp: DateTime.now(),
      );

      session.messages.add(aiMsg);

      // Save updated session
      await _updateSession(session);

      return aiMsg;
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  /// Get chat suggestions based on context
  Future<List<String>> getChatSuggestions(ChatContext context) async {
    if (context.currentDestination != null) {
      return _getDestinationSuggestions(context.currentDestination!);
    } else if (context.currentTrip != null) {
      return _getTripSuggestions(context.currentTrip!);
    } else {
      return _getGeneralSuggestions();
    }
  }

  /// Get past chat sessions
  Future<List<ChatSession>> getChatHistory(String userId) async {
    final snapshot = await _firestore
        .collection('chat_sessions')
        .where('userId', isEqualTo: userId)
        .orderBy('startedAt', descending: true)
        .limit(10)
        .get();

    return snapshot.docs.map((doc) => ChatSession.fromMap(doc.data())).toList();
  }

  /// Build system prompt with context
  String _buildSystemPrompt(ChatContext context) {
    final buffer = StringBuffer();

    buffer.write('''
You are an expert travel assistant for a travel planning app called Relink. Your role is to:
1. Answer travel-related questions accurately and helpfully
2. Provide practical tips and recommendations
3. Help with trip planning and itinerary suggestions
4. Share local insights and cultural information
5. Assist with budget planning and travel logistics

Be friendly, conversational, and enthusiastic about travel. Keep responses concise (2-3 paragraphs max) unless specifically asked for detailed information.
''');

    // Add trip context
    if (context.currentTrip != null) {
      final trip = context.currentTrip!;
      buffer.write('''

CURRENT TRIP CONTEXT:
- Trip: ${trip.title}
- Destination: ${trip.destinations.map((d) => d.name).join(', ')}
- Duration: ${trip.startDate.toString().split(' ')[0]} to ${trip.endDate.toString().split(' ')[0]}
- Budget: \$${trip.budget?.totalBudget ?? 0}
- Participants: ${trip.participantIds.length}

Use this context to provide personalized advice specific to their trip.
''');
    }

    // Add destination context
    if (context.currentDestination != null) {
      final dest = context.currentDestination!;
      buffer.write('''

CURRENT DESTINATION CONTEXT:
- Destination: ${dest.name}
- Location: ${dest.location}
- Category: ${dest.category}
- Rating: ${dest.rating}/5 (${dest.reviewCount} reviews)
- Price range: ${dest.priceRangeText}
- Best time to visit: ${dest.bestTimeToVisit}
- Activities: ${dest.activities.join(', ')}

Provide specific information about this destination when relevant.
''');
    }

    return buffer.toString();
  }

  /// Build conversation history
  List<Map<String, String>> _buildConversationHistory(List<ChatMessage> messages) {
    return messages.map((msg) {
      return {
        'role': msg.role == ChatRole.user ? 'user' : 'model',
        'content': msg.content,
      };
    }).toList();
  }

  /// Get destination-specific suggestions
  List<String> _getDestinationSuggestions(Destination dest) {
    return [
      'What are the must-see attractions in ${dest.name}?',
      'What\'s the best time to visit ${dest.name}?',
      'Any local food recommendations?',
      'What should I pack for ${dest.name}?',
      'How many days do I need in ${dest.name}?',
    ];
  }

  /// Get trip-specific suggestions
  List<String> _getTripSuggestions(Trip trip) {
    final destName = trip.destinations.isNotEmpty 
        ? trip.destinations.first.name 
        : 'your destination';
    final budget = trip.budget?.totalBudget ?? 1000;
    
    return [
      'Help me plan a day-by-day itinerary',
      'What are the best restaurants in $destName?',
      'Tips for traveling on a budget of \$$budget?',
      'What should I know about local customs?',
      'How do I get around in $destName?',
    ];
  }

  /// Get general travel suggestions
  List<String> _getGeneralSuggestions() {
    return [
      'What are the best travel destinations for 2025?',
      'Tips for budget travel in Southeast Asia',
      'How to pack light for a 2-week trip',
      'Best travel apps for navigation',
      'How to find cheap flights',
    ];
  }

  /// Update chat session in Firestore
  Future<void> _updateSession(ChatSession session) async {
    await _firestore
        .collection('chat_sessions')
        .doc(session.sessionId)
        .update(session.toMap());
  }
}

/// Chat session model
class ChatSession {
  final String sessionId;
  final String userId;
  final DateTime startedAt;
  final List<ChatMessage> messages;
  final ChatContext context;

  ChatSession({
    required this.sessionId,
    required this.userId,
    required this.startedAt,
    required this.messages,
    required this.context,
  });

  Map<String, dynamic> toMap() {
    return {
      'sessionId': sessionId,
      'userId': userId,
      'startedAt': Timestamp.fromDate(startedAt),
      'messages': messages.map((m) => m.toMap()).toList(),
      'context': context.toMap(),
    };
  }

  factory ChatSession.fromMap(Map<String, dynamic> map) {
    return ChatSession(
      sessionId: map['sessionId'] ?? '',
      userId: map['userId'] ?? '',
      startedAt: (map['startedAt'] as Timestamp).toDate(),
      messages: (map['messages'] as List? ?? [])
          .map((m) => ChatMessage.fromMap(m))
          .toList(),
      context: ChatContext.fromMap(map['context'] ?? {}),
    );
  }

  String get title {
    if (messages.isEmpty) return 'New Chat';
    final firstUserMessage = messages.firstWhere(
      (m) => m.role == ChatRole.user,
      orElse: () => messages.first,
    );
    return firstUserMessage.content.substring(
      0,
      firstUserMessage.content.length > 50 ? 50 : firstUserMessage.content.length,
    );
  }
}

/// Chat message model
class ChatMessage {
  final String id;
  final ChatRole role;
  final String content;
  final DateTime timestamp;
  final bool? isError;

  ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.isError,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'role': role.toString(),
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
      'isError': isError,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] ?? '',
      role: ChatRole.values.firstWhere(
        (e) => e.toString() == map['role'],
        orElse: () => ChatRole.user,
      ),
      content: map['content'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      isError: map['isError'],
    );
  }
}

/// Chat role enum
enum ChatRole {
  user,
  assistant,
}

/// Chat context for personalization
class ChatContext {
  final Trip? currentTrip;
  final Destination? currentDestination;

  ChatContext({
    this.currentTrip,
    this.currentDestination,
  });

  Map<String, dynamic> toMap() {
    return {
      'currentTrip': currentTrip?.toMap(),
      'currentDestination': currentDestination?.toMap(),
    };
  }

  factory ChatContext.fromMap(Map<String, dynamic> map) {
    return ChatContext(
      currentTrip: map['currentTrip'] != null 
          ? Trip.fromMap(map['currentTrip'])
          : null,
      currentDestination: map['currentDestination'] != null
          ? Destination.fromMap(map['currentDestination'])
          : null,
    );
  }

  bool get hasContext => currentTrip != null || currentDestination != null;
}

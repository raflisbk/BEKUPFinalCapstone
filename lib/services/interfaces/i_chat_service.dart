/// Chat Service Interface
/// Defines contract for chat functionality, real-time messaging, and conversation management
abstract class IChatService {
  // ===============================
  // CONVERSATION MANAGEMENT
  // ===============================

  /// Create new conversation
  Future<Map<String, dynamic>> createConversation({
    required List<String> participantIds,
    String? title,
    String? description,
    String? type, // 'direct', 'group', 'trip'
    String? tripId,
    Map<String, dynamic>? metadata,
  });

  /// Get user conversations
  Future<List<Map<String, dynamic>>> getUserConversations({
    String? userId,
    String? type,
    bool includeArchived = false,
    int limit = 50,
  });

  /// Get conversation by ID
  Future<Map<String, dynamic>?> getConversation(String conversationId);

  /// Update conversation
  Future<Map<String, dynamic>> updateConversation({
    required String conversationId,
    String? title,
    String? description,
    Map<String, dynamic>? metadata,
  });

  // ===============================
  // PARTICIPANT MANAGEMENT
  // ===============================

  /// Add participant to conversation
  Future<Map<String, dynamic>> addParticipantToConversation({
    required String conversationId,
    required String userId,
    String? role,
  });

  /// Remove participant from conversation
  Future<void> removeParticipantFromConversation({
    required String conversationId,
    required String userId,
  });

  /// Get conversation participants
  Future<List<Map<String, dynamic>>> getConversationParticipants(String conversationId);

  // ===============================
  // MESSAGE MANAGEMENT
  // ===============================

  /// Send message
  Future<Map<String, dynamic>> sendMessage({
    required String conversationId,
    required String content,
    String? messageType, // 'text', 'image', 'file', 'system', 'location'
    String? replyToMessageId,
    Map<String, dynamic>? attachments,
    Map<String, dynamic>? metadata,
  });

  /// Get messages for conversation
  Future<List<Map<String, dynamic>>> getMessages({
    required String conversationId,
    String? beforeMessageId,
    int limit = 50,
  });

  /// Update message
  Future<Map<String, dynamic>> updateMessage({
    required String messageId,
    required String newContent,
  });

  /// Delete message
  Future<void> deleteMessage(String messageId);

  // ===============================
  // READ RECEIPTS
  // ===============================

  /// Mark message as read
  Future<void> markMessageAsRead({
    required String messageId,
    String? userId,
  });

  /// Mark all messages in conversation as read
  Future<void> markConversationAsRead({
    required String conversationId,
    String? userId,
  });

  /// Get unread message count for conversation
  Future<int> getUnreadMessageCount(String conversationId, String userId);

  // ===============================
  // REAL-TIME SUBSCRIPTIONS
  // ===============================

  /// Subscribe to conversation updates
  Stream<Map<String, dynamic>> subscribeToConversation(String conversationId);

  /// Subscribe to user conversations
  Stream<Map<String, dynamic>> subscribeToUserConversations(String userId);
}
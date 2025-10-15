/// Interface for Messaging Service
/// Handles high-level messaging operations, message templates, and automated messaging
abstract class IMessagingService {
  // ===============================
  // MESSAGE TEMPLATES
  // ===============================

  /// Create message template
  Future<Map<String, dynamic>> createMessageTemplate({
    required String name,
    required String content,
    String? category,
    String? description,
    Map<String, dynamic>? variables,
    bool isActive = true,
  });

  /// Get message templates
  Future<List<Map<String, dynamic>>> getMessageTemplates({
    String? category,
    bool? isActive,
  });

  /// Render message template with variables
  Future<String> renderMessageTemplate({
    required String templateId,
    required Map<String, dynamic> variables,
  });

  // ===============================
  // SCHEDULED MESSAGES
  // ===============================

  /// Schedule a message to be sent later
  Future<Map<String, dynamic>> scheduleMessage({
    required String recipientId,
    required String content,
    required DateTime scheduledTime,
    String? conversationId,
    Map<String, dynamic>? metadata,
    bool isRecurring = false,
    String? recurringPattern,
  });

  /// Get scheduled messages
  Future<List<Map<String, dynamic>>> getScheduledMessages({
    String? status,
    DateTime? fromDate,
    DateTime? toDate,
  });

  /// Cancel scheduled message
  Future<void> cancelScheduledMessage(String messageId);

  /// Process pending scheduled messages
  Future<void> processPendingScheduledMessages();

  // ===============================
  // MESSAGE THREADS
  // ===============================

  /// Create message thread
  Future<Map<String, dynamic>> createMessageThread({
    required String title,
    required List<String> participantIds,
    String? description,
    Map<String, dynamic>? metadata,
  });

  /// Get message threads
  Future<List<Map<String, dynamic>>> getMessageThreads({
    bool? isActive,
    int? limit,
    int? offset,
  });

  // ===============================
  // MESSAGE REACTIONS
  // ===============================

  /// Add reaction to message
  Future<Map<String, dynamic>> addMessageReaction({
    required String messageId,
    required String emoji,
  });

  /// Remove reaction from message
  Future<void> removeMessageReaction({
    required String messageId,
    required String emoji,
  });

  /// Get message reactions
  Future<List<Map<String, dynamic>>> getMessageReactions(String messageId);

  // ===============================
  // BULK & BROADCAST MESSAGING
  // ===============================

  /// Send bulk messages to multiple recipients
  Future<List<Map<String, dynamic>>> sendBulkMessage({
    required List<String> recipientIds,
    required String content,
    String? templateId,
    Map<String, dynamic>? metadata,
  });

  /// Broadcast message to all users or specific groups
  Future<List<Map<String, dynamic>>> broadcastMessage({
    required String content,
    List<String>? userGroups,
    List<String>? excludeUserIds,
    Map<String, dynamic>? metadata,
  });

  // ===============================
  // STATISTICS & ANALYTICS
  // ===============================

  /// Get messaging statistics
  Future<Map<String, dynamic>> getMessagingStatistics({
    DateTime? startDate,
    DateTime? endDate,
    String? userId,
  });
}

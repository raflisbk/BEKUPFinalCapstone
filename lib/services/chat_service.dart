import 'dart:async';
import '../core/utils/logger.dart';
import 'supabase_config.dart';
import 'supabase_database_service.dart';
import 'notification_service.dart';

/// Chat Service
/// Handles real-time chat functionality, conversations, and message management
class ChatService {
  static const String _tag = 'ChatService';
  static const String _conversationsTable = 'conversations';
  static const String _messagesTable = 'messages';
  static const String _participantsTable = 'conversation_participants';
  static const String _readReceiptsTable = 'message_read_receipts';

  // Real-time subscriptions
  static final Map<String, StreamController<Map<String, dynamic>>> _conversationStreams = {};
  static final Map<String, StreamController<Map<String, dynamic>>> _userConversationStreams = {};

  // ===============================
  // CONVERSATION MANAGEMENT
  // ===============================

  /// Create new conversation
  static Future<Map<String, dynamic>> createConversation({
    required List<String> participantIds,
    String? title,
    String? description,
    String? type, // 'direct', 'group', 'trip'
    String? tripId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Creating conversation with ${participantIds.length} participants');

      // Include current user in participants
      final allParticipants = [...participantIds];
      if (!allParticipants.contains(userId)) {
        allParticipants.add(userId);
      }

      // Determine conversation type
      final conversationType = type ?? (allParticipants.length == 2 ? 'direct' : 'group');

      // For direct conversations, check if already exists
      if (conversationType == 'direct') {
        final existingConversation = await _findDirectConversation(userId, participantIds.first);
        if (existingConversation != null) {
          AppLogger.info(_tag, 'Direct conversation already exists');
          return existingConversation;
        }
      }

      // Create conversation
      final conversationData = {
        'created_by': userId,
        'title': title,
        'description': description,
        'type': conversationType,
        'trip_id': tripId,
        'metadata': metadata ?? {},
        'participant_count': allParticipants.length,
        'message_count': 0,
        'last_message_at': DateTime.now().toIso8601String(),
        'is_active': true,
      };

      final conversation = await SupabaseDatabaseService.insert(
        table: _conversationsTable,
        data: conversationData,
      );

      // Add participants
      for (final participantId in allParticipants) {
        await _addParticipant(conversation['id'], participantId, userId);
      }

      AppLogger.success(_tag, 'Conversation created successfully: ${conversation['id']}');
      return conversation;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to create conversation', e, stackTrace);
      rethrow;
    }
  }

  /// Get user conversations
  static Future<List<Map<String, dynamic>>> getUserConversations({
    String? userId,
    String? type,
    bool includeArchived = false,
    int limit = 50,
  }) async {
    try {
      final currentUserId = userId ?? SupabaseConfig.userId;
      if (currentUserId == null) {
        throw Exception('No user ID provided');
      }

      AppLogger.debug(_tag, 'Getting conversations for user: $currentUserId');

      // Get participant records for user
      final participantRecords = await SupabaseDatabaseService.select(
        table: _participantsTable,
        filters: {'user_id': currentUserId, 'is_active': true},
        orderBy: 'joined_at',
        ascending: false,
      );

      if (participantRecords.isEmpty) {
        AppLogger.info(_tag, 'No conversations found for user');
        return [];
      }

      // Get conversation IDs
      final conversationIds = participantRecords
          .map((p) => p['conversation_id'] as String)
          .toList();

      // Get conversations
      final filters = <String, dynamic>{'is_active': true};
      if (type != null) filters['type'] = type;

      var conversations = await SupabaseDatabaseService.select(
        table: _conversationsTable,
        filters: filters,
        orderBy: 'last_message_at',
        ascending: false,
        limit: limit,
      );

      // Filter by conversation IDs
      conversations = conversations.where((conv) {
        return conversationIds.contains(conv['id']);
      }).toList();

      // Enrich conversations with additional data
      for (final conversation in conversations) {
        // Get participants
        conversation['participants'] = await getConversationParticipants(conversation['id']);
        
        // Get last message
        conversation['last_message'] = await _getLastMessage(conversation['id']);
        
        // Get unread count for user
        conversation['unread_count'] = await getUnreadMessageCount(
          conversation['id'], 
          currentUserId,
        );
      }

      AppLogger.success(_tag, 'Retrieved ${conversations.length} conversations');
      return conversations;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get user conversations', e, stackTrace);
      rethrow;
    }
  }

  /// Get conversation by ID
  static Future<Map<String, dynamic>?> getConversation(String conversationId) async {
    try {
      AppLogger.debug(_tag, 'Getting conversation: $conversationId');

      final conversations = await SupabaseDatabaseService.select(
        table: _conversationsTable,
        filters: {'id': conversationId, 'is_active': true},
      );

      if (conversations.isEmpty) {
        AppLogger.warning(_tag, 'Conversation not found: $conversationId');
        return null;
      }

      final conversation = conversations.first;
      
      // Get participants
      conversation['participants'] = await getConversationParticipants(conversationId);
      
      // Get recent messages
      conversation['recent_messages'] = await getMessages(
        conversationId: conversationId,
        limit: 20,
      );

      AppLogger.success(_tag, 'Retrieved conversation: ${conversation['title'] ?? conversationId}');
      return conversation;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get conversation', e, stackTrace);
      rethrow;
    }
  }

  /// Update conversation
  static Future<Map<String, dynamic>> updateConversation({
    required String conversationId,
    String? title,
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      AppLogger.debug(_tag, 'Updating conversation: $conversationId');

      final updateData = <String, dynamic>{};
      
      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (metadata != null) updateData['metadata'] = metadata;

      if (updateData.isEmpty) {
        throw Exception('No data provided for update');
      }

      final result = await SupabaseDatabaseService.update(
        table: _conversationsTable,
        id: conversationId,
        data: updateData,
      );

      AppLogger.success(_tag, 'Conversation updated successfully');
      return result;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to update conversation', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // PARTICIPANT MANAGEMENT
  // ===============================

  /// Add participant to conversation
  static Future<Map<String, dynamic>> addParticipantToConversation({
    required String conversationId,
    required String userId,
    String? role,
  }) async {
    try {
      final currentUserId = SupabaseConfig.userId;
      if (currentUserId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Adding participant to conversation: $conversationId');

      // Check if user is already a participant
      final existingParticipants = await SupabaseDatabaseService.select(
        table: _participantsTable,
        filters: {
          'conversation_id': conversationId,
          'user_id': userId,
          'is_active': true,
        },
      );

      if (existingParticipants.isNotEmpty) {
        throw Exception('User is already a participant');
      }

      // Add participant
      final participant = await _addParticipant(conversationId, userId, currentUserId, role);

      // Update participant count
      await _updateParticipantCount(conversationId);

      // Send system message
      await sendMessage(
        conversationId: conversationId,
        content: 'added a new participant',
        messageType: 'system',
      );

      AppLogger.success(_tag, 'Participant added successfully');
      return participant;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to add participant', e, stackTrace);
      rethrow;
    }
  }

  /// Remove participant from conversation
  static Future<void> removeParticipantFromConversation({
    required String conversationId,
    required String userId,
  }) async {
    try {
      AppLogger.debug(_tag, 'Removing participant from conversation: $conversationId');

      // Update participant status
      final participants = await SupabaseDatabaseService.select(
        table: _participantsTable,
        filters: {
          'conversation_id': conversationId,
          'user_id': userId,
          'is_active': true,
        },
      );

      for (final participant in participants) {
        await SupabaseDatabaseService.update(
          table: _participantsTable,
          id: participant['id'],
          data: {
            'is_active': false,
            'left_at': DateTime.now().toIso8601String(),
          },
        );
      }

      // Update participant count
      await _updateParticipantCount(conversationId);

      // Send system message
      await sendMessage(
        conversationId: conversationId,
        content: 'left the conversation',
        messageType: 'system',
      );

      AppLogger.success(_tag, 'Participant removed successfully');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to remove participant', e, stackTrace);
      rethrow;
    }
  }

  /// Get conversation participants
  static Future<List<Map<String, dynamic>>> getConversationParticipants(String conversationId) async {
    try {
      AppLogger.debug(_tag, 'Getting participants for conversation: $conversationId');

      final participants = await SupabaseDatabaseService.select(
        table: _participantsTable,
        filters: {'conversation_id': conversationId, 'is_active': true},
        orderBy: 'joined_at',
      );

      AppLogger.success(_tag, 'Retrieved ${participants.length} participants');
      return participants;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get conversation participants', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // MESSAGE MANAGEMENT
  // ===============================

  /// Send message
  static Future<Map<String, dynamic>> sendMessage({
    required String conversationId,
    required String content,
    String? messageType, // 'text', 'image', 'file', 'system', 'location'
    String? replyToMessageId,
    Map<String, dynamic>? attachments,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Sending message to conversation: $conversationId');

      // Verify user is participant
      final isParticipant = await _isUserParticipant(conversationId, userId);
      if (!isParticipant) {
        throw Exception('User is not a participant in this conversation');
      }

      // Create message
      final messageData = {
        'conversation_id': conversationId,
        'sender_id': userId,
        'content': content,
        'type': messageType ?? 'text',
        'reply_to_message_id': replyToMessageId,
        'attachments': attachments ?? {},
        'metadata': metadata ?? {},
        'is_edited': false,
        'is_deleted': false,
        'read_count': 0,
      };

      final message = await SupabaseDatabaseService.insert(
        table: _messagesTable,
        data: messageData,
      );

      // Update conversation last message time
      await SupabaseDatabaseService.update(
        table: _conversationsTable,
        id: conversationId,
        data: {
          'last_message_at': DateTime.now().toIso8601String(),
          'message_count': await _getMessageCount(conversationId),
        },
      );

      // Create read receipt for sender
      await _createReadReceipt(message['id'], userId);

      // Send push notifications to other participants
      if (messageType != 'system') {
        await _sendMessageNotifications(conversationId, userId, content);
      }

      AppLogger.success(_tag, 'Message sent successfully: ${message['id']}');
      return message;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to send message', e, stackTrace);
      rethrow;
    }
  }

  /// Get messages for conversation
  static Future<List<Map<String, dynamic>>> getMessages({
    required String conversationId,
    String? beforeMessageId,
    int limit = 50,
  }) async {
    try {
      AppLogger.debug(_tag, 'Getting messages for conversation: $conversationId');

      final filters = <String, dynamic>{
        'conversation_id': conversationId,
        'is_deleted': false,
      };

      var messages = await SupabaseDatabaseService.select(
        table: _messagesTable,
        filters: filters,
        orderBy: 'created_at',
        ascending: false,
        limit: limit,
      );

      // Filter by before message ID if provided
      if (beforeMessageId != null) {
        final beforeMessage = await SupabaseDatabaseService.select(
          table: _messagesTable,
          filters: {'id': beforeMessageId},
        );
        
        if (beforeMessage.isNotEmpty) {
          final beforeTimestamp = DateTime.parse(beforeMessage.first['created_at']);
          messages = messages.where((msg) {
            final msgTimestamp = DateTime.parse(msg['created_at']);
            return msgTimestamp.isBefore(beforeTimestamp);
          }).toList();
        }
      }

      // Enrich messages with read receipts
      for (final message in messages) {
        message['read_receipts'] = await _getMessageReadReceipts(message['id']);
      }

      AppLogger.success(_tag, 'Retrieved ${messages.length} messages');
      return messages;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get messages', e, stackTrace);
      rethrow;
    }
  }

  /// Update message
  static Future<Map<String, dynamic>> updateMessage({
    required String messageId,
    required String newContent,
  }) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Updating message: $messageId');

      // Get message to verify ownership
      final messages = await SupabaseDatabaseService.select(
        table: _messagesTable,
        filters: {'id': messageId},
      );

      if (messages.isEmpty) {
        throw Exception('Message not found');
      }

      final message = messages.first;
      if (message['sender_id'] != userId) {
        throw Exception('Not authorized to edit this message');
      }

      // Update message
      final result = await SupabaseDatabaseService.update(
        table: _messagesTable,
        id: messageId,
        data: {
          'content': newContent,
          'is_edited': true,
          'edited_at': DateTime.now().toIso8601String(),
        },
      );

      AppLogger.success(_tag, 'Message updated successfully');
      return result;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to update message', e, stackTrace);
      rethrow;
    }
  }

  /// Delete message
  static Future<void> deleteMessage(String messageId) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.warning(_tag, 'Deleting message: $messageId');

      // Get message to verify ownership
      final messages = await SupabaseDatabaseService.select(
        table: _messagesTable,
        filters: {'id': messageId},
      );

      if (messages.isEmpty) {
        throw Exception('Message not found');
      }

      final message = messages.first;
      if (message['sender_id'] != userId) {
        throw Exception('Not authorized to delete this message');
      }

      // Soft delete message
      await SupabaseDatabaseService.update(
        table: _messagesTable,
        id: messageId,
        data: {
          'is_deleted': true,
          'deleted_at': DateTime.now().toIso8601String(),
          'content': 'This message was deleted',
        },
      );

      AppLogger.success(_tag, 'Message deleted successfully');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to delete message', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // READ RECEIPTS
  // ===============================

  /// Mark message as read
  static Future<void> markMessageAsRead({
    required String messageId,
    String? userId,
  }) async {
    try {
      final currentUserId = userId ?? SupabaseConfig.userId;
      if (currentUserId == null) {
        throw Exception('No user ID provided');
      }

      AppLogger.debug(_tag, 'Marking message as read: $messageId');

      // Check if already read
      final existingReceipts = await SupabaseDatabaseService.select(
        table: _readReceiptsTable,
        filters: {'message_id': messageId, 'user_id': currentUserId},
      );

      if (existingReceipts.isEmpty) {
        await _createReadReceipt(messageId, currentUserId);
        await _updateMessageReadCount(messageId);
      }

      AppLogger.success(_tag, 'Message marked as read');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to mark message as read', e, stackTrace);
      rethrow;
    }
  }

  /// Mark all messages in conversation as read
  static Future<void> markConversationAsRead({
    required String conversationId,
    String? userId,
  }) async {
    try {
      final currentUserId = userId ?? SupabaseConfig.userId;
      if (currentUserId == null) {
        throw Exception('No user ID provided');
      }

      AppLogger.debug(_tag, 'Marking conversation as read: $conversationId');

      // Get unread messages
      final messages = await SupabaseDatabaseService.select(
        table: _messagesTable,
        filters: {'conversation_id': conversationId, 'is_deleted': false},
      );

      for (final message in messages) {
        // Check if user has read receipt
        final existingReceipts = await SupabaseDatabaseService.select(
          table: _readReceiptsTable,
          filters: {'message_id': message['id'], 'user_id': currentUserId},
        );

        if (existingReceipts.isEmpty) {
          await _createReadReceipt(message['id'], currentUserId);
          await _updateMessageReadCount(message['id']);
        }
      }

      AppLogger.success(_tag, 'Conversation marked as read');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to mark conversation as read', e, stackTrace);
      rethrow;
    }
  }

  /// Get unread message count for conversation
  static Future<int> getUnreadMessageCount(String conversationId, String userId) async {
    try {
      AppLogger.debug(_tag, 'Getting unread message count: $conversationId');

      // Get all messages in conversation
      final messages = await SupabaseDatabaseService.select(
        table: _messagesTable,
        filters: {
          'conversation_id': conversationId,
          'is_deleted': false,
        },
      );

      int unreadCount = 0;

      for (final message in messages) {
        // Skip messages sent by user
        if (message['sender_id'] == userId) continue;

        // Check if user has read receipt
        final readReceipts = await SupabaseDatabaseService.select(
          table: _readReceiptsTable,
          filters: {'message_id': message['id'], 'user_id': userId},
        );

        if (readReceipts.isEmpty) {
          unreadCount++;
        }
      }

      AppLogger.success(_tag, 'Unread message count: $unreadCount');
      return unreadCount;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get unread message count', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // REAL-TIME SUBSCRIPTIONS
  // ===============================

  /// Subscribe to conversation updates
  static Stream<Map<String, dynamic>> subscribeToConversation(String conversationId) {
    AppLogger.debug(_tag, 'Subscribing to conversation: $conversationId');
    
    // Check if stream already exists
    if (_conversationStreams.containsKey(conversationId)) {
      return _conversationStreams[conversationId]!.stream;
    }

    // Create new stream controller
    final controller = StreamController<Map<String, dynamic>>.broadcast();
    _conversationStreams[conversationId] = controller;

    // Setup Supabase subscription
    final subscription = SupabaseDatabaseService.subscribeToTable(
      table: _messagesTable,
      onInsert: (payload) {
        final record = payload.newRecord;
        if (record['conversation_id'] == conversationId) {
          controller.add({
            'type': 'message_insert',
            'data': record,
          });
        }
      },
      onUpdate: (payload) {
        final record = payload.newRecord;
        if (record['conversation_id'] == conversationId) {
          controller.add({
            'type': 'message_update',
            'data': record,
          });
        }
      },
      onDelete: (payload) {
        final record = payload.oldRecord;
        if (record['conversation_id'] == conversationId) {
          controller.add({
            'type': 'message_delete',
            'data': record,
          });
        }
      },
    );

    // Clean up on stream close
    controller.onCancel = () {
      subscription.unsubscribe();
      _conversationStreams.remove(conversationId);
    };

    return controller.stream;
  }

  /// Subscribe to user conversations
  static Stream<Map<String, dynamic>> subscribeToUserConversations(String userId) {
    AppLogger.debug(_tag, 'Subscribing to user conversations: $userId');
    
    // Check if stream already exists
    if (_userConversationStreams.containsKey(userId)) {
      return _userConversationStreams[userId]!.stream;
    }

    // Create new stream controller
    final controller = StreamController<Map<String, dynamic>>.broadcast();
    _userConversationStreams[userId] = controller;

    // Setup Supabase subscription for conversations
    final conversationSubscription = SupabaseDatabaseService.subscribeToTable(
      table: _conversationsTable,
      onInsert: (payload) {
        final record = payload.newRecord;
        controller.add({
          'type': 'conversation_insert',
          'data': record,
        });
      },
      onUpdate: (payload) {
        final record = payload.newRecord;
        controller.add({
          'type': 'conversation_update',
          'data': record,
        });
      },
      onDelete: (payload) {
        final record = payload.oldRecord;
        controller.add({
          'type': 'conversation_delete',
          'data': record,
        });
      },
    );

    // Setup Supabase subscription for participants
    final participantSubscription = SupabaseDatabaseService.subscribeToTable(
      table: _participantsTable,
      onInsert: (payload) {
        final record = payload.newRecord;
        if (record['user_id'] == userId) {
          controller.add({
            'type': 'participant_insert',
            'data': record,
          });
        }
      },
      onUpdate: (payload) {
        final record = payload.newRecord;
        if (record['user_id'] == userId) {
          controller.add({
            'type': 'participant_update',
            'data': record,
          });
        }
      },
      onDelete: (payload) {
        final record = payload.oldRecord;
        if (record['user_id'] == userId) {
          controller.add({
            'type': 'participant_delete',
            'data': record,
          });
        }
      },
    );

    // Clean up on stream close
    controller.onCancel = () {
      conversationSubscription.unsubscribe();
      participantSubscription.unsubscribe();
      _userConversationStreams.remove(userId);
    };

    return controller.stream;
  }

  // ===============================
  // PRIVATE HELPER METHODS
  // ===============================

  /// Find existing direct conversation between two users
  static Future<Map<String, dynamic>?> _findDirectConversation(String user1Id, String user2Id) async {
    try {
      // Get conversations where both users are participants
      final user1Participants = await SupabaseDatabaseService.select(
        table: _participantsTable,
        filters: {'user_id': user1Id, 'is_active': true},
      );

      final user2Participants = await SupabaseDatabaseService.select(
        table: _participantsTable,
        filters: {'user_id': user2Id, 'is_active': true},
      );

      final user1ConversationIds = user1Participants.map((p) => p['conversation_id']).toSet();
      final user2ConversationIds = user2Participants.map((p) => p['conversation_id']).toSet();

      final commonConversationIds = user1ConversationIds.intersection(user2ConversationIds);

      for (final conversationId in commonConversationIds) {
        final conversations = await SupabaseDatabaseService.select(
          table: _conversationsTable,
          filters: {'id': conversationId, 'type': 'direct', 'is_active': true},
        );

        if (conversations.isNotEmpty) {
          return conversations.first;
        }
      }

      return null;
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to find direct conversation', e);
      return null;
    }
  }

  /// Add participant to conversation
  static Future<Map<String, dynamic>> _addParticipant(
    String conversationId,
    String userId,
    String addedBy, [
    String? role,
  ]) async {
    final participantData = {
      'conversation_id': conversationId,
      'user_id': userId,
      'added_by': addedBy,
      'role': role ?? 'member',
      'is_active': true,
      'joined_at': DateTime.now().toIso8601String(),
    };

    return await SupabaseDatabaseService.insert(
      table: _participantsTable,
      data: participantData,
    );
  }

  /// Check if user is participant in conversation
  static Future<bool> _isUserParticipant(String conversationId, String userId) async {
    try {
      final participants = await SupabaseDatabaseService.select(
        table: _participantsTable,
        filters: {
          'conversation_id': conversationId,
          'user_id': userId,
          'is_active': true,
        },
      );

      return participants.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get last message in conversation
  static Future<Map<String, dynamic>?> _getLastMessage(String conversationId) async {
    try {
      final messages = await SupabaseDatabaseService.select(
        table: _messagesTable,
        filters: {'conversation_id': conversationId, 'is_deleted': false},
        orderBy: 'created_at',
        ascending: false,
        limit: 1,
      );

      return messages.isNotEmpty ? messages.first : null;
    } catch (e) {
      return null;
    }
  }

  /// Get message count for conversation
  static Future<int> _getMessageCount(String conversationId) async {
    try {
      final messages = await SupabaseDatabaseService.select(
        table: _messagesTable,
        filters: {'conversation_id': conversationId, 'is_deleted': false},
      );

      return messages.length;
    } catch (e) {
      return 0;
    }
  }

  /// Update participant count
  static Future<void> _updateParticipantCount(String conversationId) async {
    try {
      final participants = await SupabaseDatabaseService.select(
        table: _participantsTable,
        filters: {'conversation_id': conversationId, 'is_active': true},
      );

      await SupabaseDatabaseService.update(
        table: _conversationsTable,
        id: conversationId,
        data: {'participant_count': participants.length},
      );
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to update participant count', e);
    }
  }

  /// Create read receipt
  static Future<void> _createReadReceipt(String messageId, String userId) async {
    try {
      await SupabaseDatabaseService.insert(
        table: _readReceiptsTable,
        data: {
          'message_id': messageId,
          'user_id': userId,
          'read_at': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to create read receipt', e);
    }
  }

  /// Get message read receipts
  static Future<List<Map<String, dynamic>>> _getMessageReadReceipts(String messageId) async {
    try {
      return await SupabaseDatabaseService.select(
        table: _readReceiptsTable,
        filters: {'message_id': messageId},
        orderBy: 'read_at',
      );
    } catch (e) {
      return [];
    }
  }

  /// Update message read count
  static Future<void> _updateMessageReadCount(String messageId) async {
    try {
      final readReceipts = await _getMessageReadReceipts(messageId);
      
      await SupabaseDatabaseService.update(
        table: _messagesTable,
        id: messageId,
        data: {'read_count': readReceipts.length},
      );
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to update message read count', e);
    }
  }

  /// Send message notifications to participants
  static Future<void> _sendMessageNotifications(
    String conversationId,
    String senderId,
    String content,
  ) async {
    try {
      // Get conversation participants (excluding sender)
      final participants = await SupabaseDatabaseService.select(
        table: _participantsTable,
        filters: {'conversation_id': conversationId, 'is_active': true},
      );

      final recipientIds = participants
          .where((p) => p['user_id'] != senderId)
          .map((p) => p['user_id'] as String)
          .toList();

      if (recipientIds.isNotEmpty) {
        // Get conversation info
        final conversations = await SupabaseDatabaseService.select(
          table: _conversationsTable,
          filters: {'id': conversationId},
        );

        if (conversations.isNotEmpty) {
          final conversation = conversations.first;
          final title = conversation['title'] ?? 'New Message';

          // Send notifications
          await NotificationService.sendNotificationToUsers(
            userIds: recipientIds,
            title: title,
            message: content.length > 50 ? '${content.substring(0, 50)}...' : content,
            data: {
              'type': 'chat_message',
              'conversation_id': conversationId,
              'sender_id': senderId,
            },
          );
        }
      }
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to send message notifications', e);
    }
  }
}
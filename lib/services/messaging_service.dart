import 'dart:async';
import '../core/interfaces/i_messaging_service.dart';
import '../core/utils/logger.dart';
import 'supabase_config.dart';
import 'supabase_database_service.dart';
import 'chat_service.dart';

/// Messaging Service
/// Handles high-level messaging operations, message templates, and automated messaging
class MessagingService implements IMessagingService {
  static const String _tag = 'MessagingService';
  static const String _templatesTable = 'message_templates';
  static const String _scheduledMessagesTable = 'scheduled_messages';
  static const String _messageThreadsTable = 'message_threads';
  static const String _messageReactionsTable = 'message_reactions';

  // Chat service instance
  final ChatService _chatService = ChatService();

  // ===============================
  // MESSAGE TEMPLATES
  // ===============================

  /// Create message template
  @override
  Future<Map<String, dynamic>> createMessageTemplate({
    required String name,
    required String content,
    String? category,
    String? description,
    Map<String, dynamic>? variables,
    bool isActive = true,
  }) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Creating message template: $name');

      final templateData = {
        'name': name,
        'content': content,
        'category': category,
        'description': description,
        'variables': variables ?? {},
        'created_by': userId,
        'is_active': isActive,
        'usage_count': 0,
      };

      final template = await SupabaseDatabaseService.insert(
        table: _templatesTable,
        data: templateData,
      );

      AppLogger.success(_tag, 'Message template created: $name');
      return template;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to create message template', e, stackTrace);
      rethrow;
    }
  }

  /// Get message templates
  @override
  Future<List<Map<String, dynamic>>> getMessageTemplates({
    String? category,
    bool? isActive,
  }) async {
    try {
      AppLogger.debug(_tag, 'Getting message templates');

      final filters = <String, dynamic>{};
      if (category != null) filters['category'] = category;
      if (isActive != null) filters['is_active'] = isActive;

      final templates = await SupabaseDatabaseService.select(
        table: _templatesTable,
        filters: filters,
        orderBy: 'usage_count',
        ascending: false,
        limit: 50,
      );

      AppLogger.success(_tag, 'Retrieved ${templates.length} message templates');
      return templates;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get message templates', e, stackTrace);
      rethrow;
    }
  }

  /// Use message template
  @override
  Future<String> renderMessageTemplate({
    required String templateId,
    required Map<String, dynamic> variables,
  }) async {
    try {
      AppLogger.debug(_tag, 'Rendering message template: $templateId');

      // Get template
      final templates = await SupabaseDatabaseService.select(
        table: _templatesTable,
        filters: {'id': templateId, 'is_active': true},
      );

      if (templates.isEmpty) {
        throw Exception('Template not found or inactive');
      }

      final template = templates.first;
      var content = template['content'] as String;

      // Replace variables
      variables.forEach((key, value) {
        content = content.replaceAll('{{$key}}', value.toString());
      });

      // Update usage count
      await SupabaseDatabaseService.update(
        table: _templatesTable,
        id: templateId,
        data: {
          'usage_count': (template['usage_count'] as int? ?? 0) + 1,
          'last_used_at': DateTime.now().toIso8601String(),
        },
      );

      AppLogger.success(_tag, 'Message template rendered successfully');
      return content;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to render message template', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // SCHEDULED MESSAGES
  // ===============================

  /// Schedule message
  @override
  Future<Map<String, dynamic>> scheduleMessage({
    required String recipientId,
    required String content,
    required DateTime scheduledTime,
    String? conversationId,
    Map<String, dynamic>? metadata,
    bool isRecurring = false,
    String? recurringPattern,
  }) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Scheduling message for: ${scheduledTime.toIso8601String()}');

      final scheduledMessageData = {
        'conversation_id': conversationId,
        'recipient_id': recipientId,
        'sender_id': userId,
        'content': content,
        'scheduled_at': scheduledTime.toIso8601String(),
        'is_recurring': isRecurring,
        'recurring_pattern': recurringPattern,
        'metadata': metadata ?? {},
        'status': 'pending',
        'attempts': 0,
      };

      final scheduledMessage = await SupabaseDatabaseService.insert(
        table: _scheduledMessagesTable,
        data: scheduledMessageData,
      );

      AppLogger.success(_tag, 'Message scheduled successfully: ${scheduledMessage['id']}');
      return scheduledMessage;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to schedule message', e, stackTrace);
      rethrow;
    }
  }

  /// Get scheduled messages
  @override
  Future<List<Map<String, dynamic>>> getScheduledMessages({
    String? status,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Getting scheduled messages');

      final filters = <String, dynamic>{'sender_id': userId};
      if (status != null) filters['status'] = status;

      var messages = await SupabaseDatabaseService.select(
        table: _scheduledMessagesTable,
        filters: filters,
        orderBy: 'scheduled_at',
        limit: 50,
      );

      // Filter by date range if provided
      if (fromDate != null || toDate != null) {
        messages = messages.where((message) {
          final scheduledAt = DateTime.parse(message['scheduled_at']);
          if (fromDate != null && scheduledAt.isBefore(fromDate)) return false;
          if (toDate != null && scheduledAt.isAfter(toDate)) return false;
          return true;
        }).toList();
      }

      AppLogger.success(_tag, 'Retrieved ${messages.length} scheduled messages');
      return messages;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get scheduled messages', e, stackTrace);
      rethrow;
    }
  }

  /// Cancel scheduled message
  @override
  Future<void> cancelScheduledMessage(String messageId) async {
    try {
      AppLogger.warning(_tag, 'Canceling scheduled message: $messageId');

      await SupabaseDatabaseService.update(
        table: _scheduledMessagesTable,
        id: messageId,
        data: {
          'status': 'cancelled',
          'cancelled_at': DateTime.now().toIso8601String(),
        },
      );

      AppLogger.success(_tag, 'Scheduled message cancelled');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to cancel scheduled message', e, stackTrace);
      rethrow;
    }
  }

  /// Process pending scheduled messages
  @override
  Future<void> processPendingScheduledMessages() async {
    try {
      AppLogger.debug(_tag, 'Processing pending scheduled messages');

      final now = DateTime.now();
      final pendingMessages = await SupabaseDatabaseService.select(
        table: _scheduledMessagesTable,
        filters: {'status': 'pending'},
      );

      int processed = 0;
      for (final message in pendingMessages) {
        final scheduledAt = DateTime.parse(message['scheduled_at']);
        
        if (scheduledAt.isBefore(now) || scheduledAt.isAtSameMomentAs(now)) {
          try {
            // Send the message
            await _chatService.sendMessage(
              conversationId: message['conversation_id'],
              content: message['content'],
            );

            // Update status
            await SupabaseDatabaseService.update(
              table: _scheduledMessagesTable,
              id: message['id'],
              data: {
                'status': 'sent',
                'sent_at': DateTime.now().toIso8601String(),
              },
            );

            // Handle recurring messages
            if (message['is_recurring'] == true) {
              await _createNextRecurringMessage(message);
            }

            processed++;
          } catch (e) {
            // Update failed status
            await SupabaseDatabaseService.update(
              table: _scheduledMessagesTable,
              id: message['id'],
              data: {
                'status': 'failed',
                'attempts': (message['attempts'] as int? ?? 0) + 1,
                'error_message': e.toString(),
              },
            );
          }
        }
      }

      AppLogger.success(_tag, 'Processed $processed scheduled messages');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to process scheduled messages', e, stackTrace);
    }
  }

  // ===============================
  // MESSAGE THREADS
  // ===============================

  /// Create message thread
  @override
  Future<Map<String, dynamic>> createMessageThread({
    required String title,
    required List<String> participantIds,
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Creating message thread: $title');

      final threadData = {
        'title': title,
        'description': description,
        'participant_ids': participantIds,
        'metadata': metadata ?? {},
        'created_by': userId,
        'message_count': 0,
        'participant_count': participantIds.length,
        'is_active': true,
      };

      final thread = await SupabaseDatabaseService.insert(
        table: _messageThreadsTable,
        data: threadData,
      );

      AppLogger.success(_tag, 'Message thread created: $title');
      return thread;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to create message thread', e, stackTrace);
      rethrow;
    }
  }

  /// Get message threads
  @override
  Future<List<Map<String, dynamic>>> getMessageThreads({
    bool? isActive,
    int? limit,
    int? offset,
  }) async {
    try {
      AppLogger.debug(_tag, 'Getting message threads');

      final filters = <String, dynamic>{};
      if (isActive != null) filters['is_active'] = isActive;

      final threads = await SupabaseDatabaseService.select(
        table: _messageThreadsTable,
        filters: filters,
        orderBy: 'created_at',
        ascending: false,
        limit: limit ?? 20,
        offset: offset,
      );

      AppLogger.success(_tag, 'Retrieved ${threads.length} message threads');
      return threads;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get message threads', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // MESSAGE REACTIONS
  // ===============================

  /// Add reaction to message
  @override
  Future<Map<String, dynamic>> addMessageReaction({
    required String messageId,
    required String emoji,
  }) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Adding reaction to message: $messageId');

      // Check if user already reacted with this emoji
      final existingReactions = await SupabaseDatabaseService.select(
        table: _messageReactionsTable,
        filters: {
          'message_id': messageId,
          'user_id': userId,
          'emoji': emoji,
        },
      );

      if (existingReactions.isNotEmpty) {
        throw Exception('User already reacted with this emoji');
      }

      final reactionData = {
        'message_id': messageId,
        'user_id': userId,
        'emoji': emoji,
      };

      final reaction = await SupabaseDatabaseService.insert(
        table: _messageReactionsTable,
        data: reactionData,
      );

      AppLogger.success(_tag, 'Reaction added successfully');
      return reaction;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to add message reaction', e, stackTrace);
      rethrow;
    }
  }

  /// Remove reaction from message
  @override
  Future<void> removeMessageReaction({
    required String messageId,
    required String emoji,
  }) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Removing reaction from message: $messageId');

      final reactions = await SupabaseDatabaseService.select(
        table: _messageReactionsTable,
        filters: {
          'message_id': messageId,
          'user_id': userId,
          'emoji': emoji,
        },
      );

      for (final reaction in reactions) {
        await SupabaseDatabaseService.delete(
          table: _messageReactionsTable,
          id: reaction['id'],
        );
      }

      AppLogger.success(_tag, 'Reaction removed successfully');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to remove message reaction', e, stackTrace);
      rethrow;
    }
  }

  /// Get message reactions
  @override
  Future<List<Map<String, dynamic>>> getMessageReactions(String messageId) async {
    try {
      AppLogger.debug(_tag, 'Getting reactions for message: $messageId');

      final reactions = await SupabaseDatabaseService.select(
        table: _messageReactionsTable,
        filters: {'message_id': messageId},
        orderBy: 'created_at',
      );

      // Group reactions by emoji
      final groupedReactions = <String, List<Map<String, dynamic>>>{};
      for (final reaction in reactions) {
        final emoji = reaction['emoji'] as String;
        if (!groupedReactions.containsKey(emoji)) {
          groupedReactions[emoji] = [];
        }
        groupedReactions[emoji]!.add(reaction);
      }

      // Convert to list format
      final result = groupedReactions.entries.map((entry) {
        return {
          'emoji': entry.key,
          'count': entry.value.length,
          'users': entry.value.map((r) => r['user_id']).toList(),
          'reactions': entry.value,
        };
      }).toList();

      AppLogger.success(_tag, 'Retrieved reactions for message');
      return result;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get message reactions', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // BULK MESSAGING
  // ===============================

  /// Send bulk message to multiple conversations
  @override
  Future<List<Map<String, dynamic>>> sendBulkMessage({
    required List<String> recipientIds,
    required String content,
    String? templateId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Sending bulk message to ${recipientIds.length} recipients');

      final results = <Map<String, dynamic>>[];

      for (final recipientId in recipientIds) {
        try {
          final message = await _chatService.sendMessage(
            conversationId: recipientId, // Simplified for now
            content: content,
          );

          results.add({
            'recipient_id': recipientId,
            'status': 'success',
            'message': message,
          });
        } catch (e) {
          results.add({
            'recipient_id': recipientId,
            'status': 'error',
            'error': e.toString(),
          });
        }
      }

      AppLogger.success(_tag, 'Bulk message sent to ${results.length} conversations');
      return results;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to send bulk message', e, stackTrace);
      rethrow;
    }
  }

  /// Send message to all user conversations
  @override
  Future<List<Map<String, dynamic>>> broadcastMessage({
    required String content,
    List<String>? userGroups,
    List<String>? excludeUserIds,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Broadcasting message to all conversations');

      // Get user conversations
      final conversations = await _chatService.getUserConversations(
        userId: userId,
      );

      final conversationIds = conversations.map((c) => c['id'] as String).toList();

      return await sendBulkMessage(
        recipientIds: conversationIds,
        content: content,
        metadata: metadata,
      );
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to broadcast message', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // MESSAGE ANALYTICS
  // ===============================

  /// Get messaging statistics
  @override
  Future<Map<String, dynamic>> getMessagingStatistics({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final currentUserId = userId ?? SupabaseConfig.userId;
      if (currentUserId == null) {
        throw Exception('No user ID provided');
      }

      AppLogger.debug(_tag, 'Getting messaging statistics');

      // Get user conversations
      final conversations = await _chatService.getUserConversations(userId: currentUserId);
      final conversationIds = conversations.map((c) => c['id'] as String).toList();

      if (conversationIds.isEmpty) {
        return {
          'total_messages_sent': 0,
          'total_messages_received': 0,
          'total_conversations': 0,
          'active_conversations': 0,
          'average_response_time': 0,
          'most_active_conversation': null,
        };
      }

      // Count messages sent and received
      // This would require more complex queries in a real implementation
      // For now, returning placeholder data structure

      final stats = {
        'total_messages_sent': 0,
        'total_messages_received': 0,
        'total_conversations': conversations.length,
        'active_conversations': conversations.where((c) => c['is_active'] == true).length,
        'average_response_time': 0,
        'most_active_conversation': conversations.isNotEmpty ? conversations.first : null,
        'message_types': <String, int>{},
        'hourly_activity': <int, int>{},
        'daily_activity': <String, int>{},
      };

      AppLogger.success(_tag, 'Retrieved messaging statistics');
      return stats;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get messaging statistics', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // PRIVATE HELPER METHODS
  // ===============================

  /// Create next recurring message
  Future<void> _createNextRecurringMessage(Map<String, dynamic> originalMessage) async {
    try {
      final recurringSettings = originalMessage['metadata'] as Map<String, dynamic>? ?? {};
      final interval = recurringSettings['interval'] as String?;
      final intervalValue = recurringSettings['interval_value'] as int? ?? 1;

      if (interval == null) return;

      final lastScheduledAt = DateTime.parse(originalMessage['scheduled_at']);
      DateTime nextScheduledAt;

      switch (interval) {
        case 'minutes':
          nextScheduledAt = lastScheduledAt.add(Duration(minutes: intervalValue));
          break;
        case 'hours':
          nextScheduledAt = lastScheduledAt.add(Duration(hours: intervalValue));
          break;
        case 'days':
          nextScheduledAt = lastScheduledAt.add(Duration(days: intervalValue));
          break;
        case 'weeks':
          nextScheduledAt = lastScheduledAt.add(Duration(days: intervalValue * 7));
          break;
        case 'months':
          nextScheduledAt = DateTime(
            lastScheduledAt.year,
            lastScheduledAt.month + intervalValue,
            lastScheduledAt.day,
            lastScheduledAt.hour,
            lastScheduledAt.minute,
          );
          break;
        default:
          return;
      }

      // Check if we should continue recurring
      final endDate = recurringSettings['end_date'] as String?;
      if (endDate != null) {
        final endDateTime = DateTime.parse(endDate);
        if (nextScheduledAt.isAfter(endDateTime)) {
          return;
        }
      }

      // Create next recurring message
      await scheduleMessage(
        recipientId: originalMessage['recipient_id'] ?? '',
        conversationId: originalMessage['conversation_id'],
        content: originalMessage['content'],
        scheduledTime: nextScheduledAt,
        isRecurring: true,
        recurringPattern: originalMessage['recurring_pattern'],
        metadata: originalMessage['metadata'],
      );
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to create next recurring message', e);
    }
  }
}

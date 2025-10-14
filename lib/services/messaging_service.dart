import 'dart:async';
import '../core/utils/logger.dart';
import 'supabase_config.dart';
import 'supabase_database_service.dart';
import 'chat_service.dart';

/// Messaging Service
/// Handles high-level messaging operations, message templates, and automated messaging
class MessagingService {
  static const String _tag = 'MessagingService';
  static const String _templatesTable = 'message_templates';
  static const String _scheduledMessagesTable = 'scheduled_messages';
  static const String _messageThreadsTable = 'message_threads';
  static const String _messageReactionsTable = 'message_reactions';

  // Singleton pattern
  static MessagingService? _instance;
  static MessagingService get instance => _instance ??= MessagingService._internal();
  
  MessagingService._internal();

  // ===============================
  // MESSAGE TEMPLATES
  // ===============================

  /// Create message template
  static Future<Map<String, dynamic>> createMessageTemplate({
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
  static Future<List<Map<String, dynamic>>> getMessageTemplates({
    String? category,
    bool? isActive,
    String? userId,
    int limit = 50,
  }) async {
    try {
      AppLogger.debug(_tag, 'Getting message templates');

      final filters = <String, dynamic>{};
      if (category != null) filters['category'] = category;
      if (isActive != null) filters['is_active'] = isActive;
      if (userId != null) filters['created_by'] = userId;

      final templates = await SupabaseDatabaseService.select(
        table: _templatesTable,
        filters: filters,
        orderBy: 'usage_count',
        ascending: false,
        limit: limit,
      );

      AppLogger.success(_tag, 'Retrieved ${templates.length} message templates');
      return templates;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get message templates', e, stackTrace);
      rethrow;
    }
  }

  /// Use message template
  static Future<String> renderMessageTemplate({
    required String templateId,
    Map<String, dynamic>? variables,
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
      if (variables != null) {
        variables.forEach((key, value) {
          content = content.replaceAll('{{$key}}', value.toString());
        });
      }

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
  static Future<Map<String, dynamic>> scheduleMessage({
    required String conversationId,
    required String content,
    required DateTime scheduledAt,
    String? messageType,
    Map<String, dynamic>? attachments,
    bool recurring = false,
    Map<String, dynamic>? recurringSettings,
  }) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Scheduling message for: ${scheduledAt.toIso8601String()}');

      final scheduledMessageData = {
        'conversation_id': conversationId,
        'sender_id': userId,
        'content': content,
        'message_type': messageType ?? 'text',
        'attachments': attachments ?? {},
        'scheduled_at': scheduledAt.toIso8601String(),
        'is_recurring': recurring,
        'recurring_settings': recurringSettings ?? {},
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
  static Future<List<Map<String, dynamic>>> getScheduledMessages({
    String? conversationId,
    String? status,
    int limit = 50,
  }) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Getting scheduled messages');

      final filters = <String, dynamic>{'sender_id': userId};
      if (conversationId != null) filters['conversation_id'] = conversationId;
      if (status != null) filters['status'] = status;

      final messages = await SupabaseDatabaseService.select(
        table: _scheduledMessagesTable,
        filters: filters,
        orderBy: 'scheduled_at',
        limit: limit,
      );

      AppLogger.success(_tag, 'Retrieved ${messages.length} scheduled messages');
      return messages;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get scheduled messages', e, stackTrace);
      rethrow;
    }
  }

  /// Cancel scheduled message
  static Future<void> cancelScheduledMessage(String messageId) async {
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
  static Future<void> processPendingScheduledMessages() async {
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
            await ChatService.sendMessage(
              conversationId: message['conversation_id'],
              content: message['content'],
              messageType: message['message_type'],
              attachments: message['attachments'],
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
  static Future<Map<String, dynamic>> createMessageThread({
    required String originalMessageId,
    required String title,
    String? description,
  }) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Creating message thread: $title');

      final threadData = {
        'original_message_id': originalMessageId,
        'title': title,
        'description': description,
        'created_by': userId,
        'message_count': 0,
        'participant_count': 1,
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
  static Future<List<Map<String, dynamic>>> getMessageThreads({
    String? originalMessageId,
    int limit = 20,
  }) async {
    try {
      AppLogger.debug(_tag, 'Getting message threads');

      final filters = <String, dynamic>{'is_active': true};
      if (originalMessageId != null) {
        filters['original_message_id'] = originalMessageId;
      }

      final threads = await SupabaseDatabaseService.select(
        table: _messageThreadsTable,
        filters: filters,
        orderBy: 'created_at',
        ascending: false,
        limit: limit,
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
  static Future<Map<String, dynamic>> addMessageReaction({
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
  static Future<void> removeMessageReaction({
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
  static Future<List<Map<String, dynamic>>> getMessageReactions(String messageId) async {
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
  static Future<List<Map<String, dynamic>>> sendBulkMessage({
    required List<String> conversationIds,
    required String content,
    String? messageType,
    Map<String, dynamic>? attachments,
    bool skipIfNotParticipant = true,
  }) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Sending bulk message to ${conversationIds.length} conversations');

      final results = <Map<String, dynamic>>[];

      for (final conversationId in conversationIds) {
        try {
          final message = await ChatService.sendMessage(
            conversationId: conversationId,
            content: content,
            messageType: messageType,
            attachments: attachments,
          );

          results.add({
            'conversation_id': conversationId,
            'status': 'success',
            'message': message,
          });
        } catch (e) {
          if (skipIfNotParticipant && e.toString().contains('not a participant')) {
            continue;
          }

          results.add({
            'conversation_id': conversationId,
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
  static Future<List<Map<String, dynamic>>> broadcastMessage({
    required String content,
    String? messageType,
    Map<String, dynamic>? attachments,
    String? conversationType, // Filter by conversation type
  }) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Broadcasting message to all conversations');

      // Get user conversations
      final conversations = await ChatService.getUserConversations(
        userId: userId,
        type: conversationType,
      );

      final conversationIds = conversations.map((c) => c['id'] as String).toList();

      return await sendBulkMessage(
        conversationIds: conversationIds,
        content: content,
        messageType: messageType,
        attachments: attachments,
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
  static Future<Map<String, dynamic>> getMessagingStatistics({
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

      // Get user's conversations
      final conversations = await ChatService.getUserConversations(userId: currentUserId);
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
  static Future<void> _createNextRecurringMessage(Map<String, dynamic> originalMessage) async {
    try {
      final recurringSettings = originalMessage['recurring_settings'] as Map<String, dynamic>? ?? {};
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
        conversationId: originalMessage['conversation_id'],
        content: originalMessage['content'],
        scheduledAt: nextScheduledAt,
        messageType: originalMessage['message_type'],
        attachments: originalMessage['attachments'],
        recurring: true,
        recurringSettings: recurringSettings,
      );
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to create next recurring message', e);
    }
  }
}
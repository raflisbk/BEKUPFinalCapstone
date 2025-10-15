import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/utils/logger.dart';
import 'supabase_config.dart';
import 'supabase_database_service.dart';

/// Notification Service
/// Handles OneSignal push notifications, in-app notifications, and notification preferences
class NotificationService {
  static const String _tag = 'NotificationService';
  static const String _notificationsTable = 'notifications';
  static const String _preferencesTable = 'notification_preferences';
  static const String _devicesTable = 'user_devices';

  // Singleton pattern
  static NotificationService? _instance;
  static NotificationService get instance => _instance ??= NotificationService._internal();
  
  NotificationService._internal();

  // OneSignal configuration (TODO: Add to EnvConfig)
  static String get _appId => 'your-onesignal-app-id';
  static String get _restApiKey => 'your-onesignal-rest-api-key';
  static const String _baseUrl = 'https://onesignal.com/api/v1';

  // ===============================
  // PUSH NOTIFICATION SENDING
  // ===============================

  /// Send push notification to specific user
  Future<Map<String, dynamic>> sendNotificationToUser({
    required String userId,
    required String title,
    required String message,
    Map<String, dynamic>? data,
    String? imageUrl,
    String? actionUrl,
    DateTime? scheduleAt,
  }) async {
    try {
      AppLogger.debug(_tag, 'Sending notification to user: $userId');

      // Get user's OneSignal player ID
      final playerIds = await _getUserPlayerIds(userId);
      if (playerIds.isEmpty) {
        AppLogger.warning(_tag, 'No OneSignal player IDs found for user: $userId');
        // Still save notification for in-app display
        return await _saveNotificationRecord(
          userId: userId,
          title: title,
          message: message,
          data: data,
          imageUrl: imageUrl,
          actionUrl: actionUrl,
          status: 'no_device',
        );
      }

      // Send to OneSignal
      final oneSignalResponse = await _sendOneSignalNotification(
        playerIds: playerIds,
        title: title,
        message: message,
        data: data,
        imageUrl: imageUrl,
        actionUrl: actionUrl,
        scheduleAt: scheduleAt,
      );

      // Save notification record
      final notificationRecord = await _saveNotificationRecord(
        userId: userId,
        title: title,
        message: message,
        data: data,
        imageUrl: imageUrl,
        actionUrl: actionUrl,
        oneSignalId: oneSignalResponse['id'],
        status: 'sent',
      );

      AppLogger.success(_tag, 'Notification sent successfully to user: $userId');
      return {
        'notification_id': notificationRecord['id'],
        'onesignal_id': oneSignalResponse['id'],
        'recipients': oneSignalResponse['recipients'],
      };
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to send notification to user', e, stackTrace);
      rethrow;
    }
  }

  /// Send push notification to multiple users
  static Future<Map<String, dynamic>> sendNotificationToUsers({
    required List<String> userIds,
    required String title,
    required String message,
    Map<String, dynamic>? data,
    String? imageUrl,
    String? actionUrl,
    DateTime? scheduleAt,
  }) async {
    try {
      AppLogger.debug(_tag, 'Sending notification to ${userIds.length} users');

      // Get all player IDs
      final allPlayerIds = <String>[];
      final validUserIds = <String>[];

      for (final userId in userIds) {
        final notificationService = NotificationService.instance;
        final playerIds = await notificationService._getUserPlayerIds(userId);
        if (playerIds.isNotEmpty) {
          allPlayerIds.addAll(playerIds);
          validUserIds.add(userId);
        }
      }

      if (allPlayerIds.isEmpty) {
        AppLogger.warning(_tag, 'No OneSignal player IDs found for provided users');
        return {'sent_count': 0, 'failed_count': userIds.length};
      }

      // Send to OneSignal
      final oneSignalResponse = await _sendOneSignalNotification(
        playerIds: allPlayerIds,
        title: title,
        message: message,
        data: data,
        imageUrl: imageUrl,
        actionUrl: actionUrl,
        scheduleAt: scheduleAt,
      );

      // Save notification records for all users
      final notificationIds = <String>[];
      for (final userId in validUserIds) {
        final record = await _saveNotificationRecord(
          userId: userId,
          title: title,
          message: message,
          data: data,
          imageUrl: imageUrl,
          actionUrl: actionUrl,
          oneSignalId: oneSignalResponse['id'],
          status: 'sent',
        );
        notificationIds.add(record['id']);
      }

      AppLogger.success(_tag, 'Notification sent to ${validUserIds.length} users');
      return {
        'notification_ids': notificationIds,
        'onesignal_id': oneSignalResponse['id'],
        'sent_count': validUserIds.length,
        'failed_count': userIds.length - validUserIds.length,
        'recipients': oneSignalResponse['recipients'],
      };
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to send notification to users', e, stackTrace);
      rethrow;
    }
  }

  /// Send notification to all users with tags
  static Future<Map<String, dynamic>> sendNotificationWithTags({
    required String title,
    required String message,
    required List<Map<String, String>> tags, // [{"key": "user_type", "relation": "=", "value": "premium"}]
    Map<String, dynamic>? data,
    String? imageUrl,
    String? actionUrl,
    DateTime? scheduleAt,
  }) async {
    try {
      AppLogger.debug(_tag, 'Sending notification with tags: $tags');

      // Send to OneSignal with tag filters
      final oneSignalResponse = await _sendOneSignalNotificationWithTags(
        tags: tags,
        title: title,
        message: message,
        data: data,
        imageUrl: imageUrl,
        actionUrl: actionUrl,
        scheduleAt: scheduleAt,
      );

      AppLogger.success(_tag, 'Tagged notification sent successfully');
      return {
        'onesignal_id': oneSignalResponse['id'],
        'recipients': oneSignalResponse['recipients'],
      };
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to send notification with tags', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // IN-APP NOTIFICATIONS
  // ===============================

  /// Get user notifications
  Future<List<Map<String, dynamic>>> getUserNotifications({
    String? userId,
    bool? isRead,
    String? type,
    int limit = 50,
  }) async {
    try {
      final currentUserId = userId ?? SupabaseConfig.userId;
      if (currentUserId == null) {
        throw Exception('No user ID provided');
      }

      AppLogger.debug(_tag, 'Getting notifications for user: $currentUserId');

      final filters = <String, dynamic>{'user_id': currentUserId};
      if (isRead != null) filters['is_read'] = isRead;
      if (type != null) filters['type'] = type;

      final notifications = await SupabaseDatabaseService.select(
        table: _notificationsTable,
        filters: filters,
        orderBy: 'created_at',
        ascending: false,
        limit: limit,
      );

      AppLogger.success(_tag, 'Retrieved ${notifications.length} notifications');
      return notifications;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get user notifications', e, stackTrace);
      rethrow;
    }
  }

  /// Mark notification as read
  static Future<void> markNotificationAsRead(String notificationId) async {
    try {
      AppLogger.debug(_tag, 'Marking notification as read: $notificationId');

      await SupabaseDatabaseService.update(
        table: _notificationsTable,
        id: notificationId,
        data: {
          'is_read': true,
          'read_at': DateTime.now().toIso8601String(),
        },
      );

      AppLogger.success(_tag, 'Notification marked as read');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to mark notification as read', e, stackTrace);
      rethrow;
    }
  }

  /// Mark all notifications as read for user
  static Future<void> markAllNotificationsAsRead({String? userId}) async {
    try {
      final currentUserId = userId ?? SupabaseConfig.userId;
      if (currentUserId == null) {
        throw Exception('No user ID provided');
      }

      AppLogger.debug(_tag, 'Marking all notifications as read for user: $currentUserId');

      final unreadNotifications = await SupabaseDatabaseService.select(
        table: _notificationsTable,
        filters: {'user_id': currentUserId, 'is_read': false},
      );

      for (final notification in unreadNotifications) {
        await SupabaseDatabaseService.update(
          table: _notificationsTable,
          id: notification['id'],
          data: {
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          },
        );
      }

      AppLogger.success(_tag, 'All notifications marked as read');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to mark all notifications as read', e, stackTrace);
      rethrow;
    }
  }

  /// Get unread notification count
  Future<int> getUnreadNotificationCount({String? userId}) async {
    try {
      final currentUserId = userId ?? SupabaseConfig.userId;
      if (currentUserId == null) {
        throw Exception('No user ID provided');
      }

      AppLogger.debug(_tag, 'Getting unread notification count for user: $currentUserId');

      final unreadNotifications = await SupabaseDatabaseService.select(
        table: _notificationsTable,
        filters: {'user_id': currentUserId, 'is_read': false},
      );

      final count = unreadNotifications.length;
      AppLogger.success(_tag, 'Unread notification count: $count');
      return count;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get unread notification count', e, stackTrace);
      rethrow;
    }
  }

  /// Delete notification
  static Future<void> deleteNotification(String notificationId) async {
    try {
      AppLogger.warning(_tag, 'Deleting notification: $notificationId');

      await SupabaseDatabaseService.delete(
        table: _notificationsTable,
        id: notificationId,
      );

      AppLogger.success(_tag, 'Notification deleted successfully');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to delete notification', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // DEVICE MANAGEMENT
  // ===============================

  /// Register device for push notifications
  static Future<Map<String, dynamic>> registerDevice({
    required String oneSignalPlayerId,
    String? deviceType, // 'ios', 'android', 'web'
    String? deviceModel,
    String? osVersion,
    String? appVersion,
    Map<String, dynamic>? tags,
  }) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Registering device for user: $userId');

      // Check if device already exists
      final existingDevices = await SupabaseDatabaseService.select(
        table: _devicesTable,
        filters: {
          'user_id': userId,
          'onesignal_player_id': oneSignalPlayerId,
        },
      );

      Map<String, dynamic> deviceData = {
        'user_id': userId,
        'onesignal_player_id': oneSignalPlayerId,
        'device_type': deviceType,
        'device_model': deviceModel,
        'os_version': osVersion,
        'app_version': appVersion,
        'tags': tags ?? {},
        'is_active': true,
        'last_seen': DateTime.now().toIso8601String(),
      };

      Map<String, dynamic> result;

      if (existingDevices.isNotEmpty) {
        // Update existing device
        result = await SupabaseDatabaseService.update(
          table: _devicesTable,
          id: existingDevices.first['id'],
          data: deviceData,
        );
      } else {
        // Register new device
        result = await SupabaseDatabaseService.insert(
          table: _devicesTable,
          data: deviceData,
        );
      }

      // Update tags in OneSignal
      if (tags != null && tags.isNotEmpty) {
        await _updateOneSignalTags(oneSignalPlayerId, tags);
      }

      AppLogger.success(_tag, 'Device registered successfully');
      return result;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to register device', e, stackTrace);
      rethrow;
    }
  }

  /// Unregister device
  static Future<void> unregisterDevice(String oneSignalPlayerId) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Unregistering device: $oneSignalPlayerId');

      // Deactivate device in database
      final devices = await SupabaseDatabaseService.select(
        table: _devicesTable,
        filters: {
          'user_id': userId,
          'onesignal_player_id': oneSignalPlayerId,
        },
      );

      for (final device in devices) {
        await SupabaseDatabaseService.update(
          table: _devicesTable,
          id: device['id'],
          data: {'is_active': false},
        );
      }

      AppLogger.success(_tag, 'Device unregistered successfully');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to unregister device', e, stackTrace);
      rethrow;
    }
  }

  /// Get user devices
  static Future<List<Map<String, dynamic>>> getUserDevices({String? userId}) async {
    try {
      final currentUserId = userId ?? SupabaseConfig.userId;
      if (currentUserId == null) {
        throw Exception('No user ID provided');
      }

      AppLogger.debug(_tag, 'Getting devices for user: $currentUserId');

      final devices = await SupabaseDatabaseService.select(
        table: _devicesTable,
        filters: {'user_id': currentUserId, 'is_active': true},
        orderBy: 'last_seen',
        ascending: false,
      );

      AppLogger.success(_tag, 'Retrieved ${devices.length} devices');
      return devices;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get user devices', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // NOTIFICATION PREFERENCES
  // ===============================

  /// Set notification preferences
  static Future<Map<String, dynamic>> setNotificationPreferences({
    String? userId,
    bool? pushEnabled,
    bool? emailEnabled,
    bool? tripUpdates,
    bool? socialNotifications,
    bool? marketingMessages,
    bool? securityAlerts,
    Map<String, bool>? customPreferences,
  }) async {
    try {
      final currentUserId = userId ?? SupabaseConfig.userId;
      if (currentUserId == null) {
        throw Exception('No user ID provided');
      }

      AppLogger.debug(_tag, 'Setting notification preferences for user: $currentUserId');

      final preferences = {
        'user_id': currentUserId,
        'push_enabled': pushEnabled ?? true,
        'email_enabled': emailEnabled ?? true,
        'trip_updates': tripUpdates ?? true,
        'social_notifications': socialNotifications ?? true,
        'marketing_messages': marketingMessages ?? false,
        'security_alerts': securityAlerts ?? true,
        'custom_preferences': customPreferences ?? {},
      };

      // Check if preferences exist
      final existingPreferences = await SupabaseDatabaseService.select(
        table: _preferencesTable,
        filters: {'user_id': currentUserId},
      );

      Map<String, dynamic> result;

      if (existingPreferences.isNotEmpty) {
        // Update existing preferences
        result = await SupabaseDatabaseService.update(
          table: _preferencesTable,
          id: existingPreferences.first['id'],
          data: preferences,
        );
      } else {
        // Create new preferences
        result = await SupabaseDatabaseService.insert(
          table: _preferencesTable,
          data: preferences,
        );
      }

      AppLogger.success(_tag, 'Notification preferences updated successfully');
      return result;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to set notification preferences', e, stackTrace);
      rethrow;
    }
  }

  /// Get notification preferences
  static Future<Map<String, dynamic>?> getNotificationPreferences({String? userId}) async {
    try {
      final currentUserId = userId ?? SupabaseConfig.userId;
      if (currentUserId == null) {
        throw Exception('No user ID provided');
      }

      AppLogger.debug(_tag, 'Getting notification preferences for user: $currentUserId');

      final preferences = await SupabaseDatabaseService.select(
        table: _preferencesTable,
        filters: {'user_id': currentUserId},
      );

      if (preferences.isEmpty) {
        // Return default preferences
        return {
          'user_id': currentUserId,
          'push_enabled': true,
          'email_enabled': true,
          'trip_updates': true,
          'social_notifications': true,
          'marketing_messages': false,
          'security_alerts': true,
          'custom_preferences': {},
        };
      }

      AppLogger.success(_tag, 'Retrieved notification preferences');
      return preferences.first;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get notification preferences', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // NOTIFICATION TEMPLATES
  // ===============================

  /// Send trip update notification
  static Future<Map<String, dynamic>> sendTripUpdateNotification({
    required String userId,
    required String tripTitle,
    required String updateType, // 'created', 'updated', 'cancelled', etc.
    String? tripId,
  }) async {
    try {
      final templates = {
        'created': {
          'title': 'Trip Created!',
          'message': 'Your trip "$tripTitle" has been created successfully.',
        },
        'updated': {
          'title': 'Trip Updated',
          'message': 'Your trip "$tripTitle" has been updated.',
        },
        'cancelled': {
          'title': 'Trip Cancelled',
          'message': 'Your trip "$tripTitle" has been cancelled.',
        },
        'reminder': {
          'title': 'Trip Reminder',
          'message': 'Don\'t forget about your upcoming trip "$tripTitle"!',
        },
      };

      final template = templates[updateType];
      if (template == null) {
        throw Exception('Unknown trip update type: $updateType');
      }

      return await NotificationService.instance.sendNotificationToUser(
        userId: userId,
        title: template['title']!,
        message: template['message']!,
        data: {
          'type': 'trip_update',
          'trip_id': tripId,
          'update_type': updateType,
        },
        actionUrl: tripId != null ? '/trip/$tripId' : null,
      );
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to send trip update notification', e, stackTrace);
      rethrow;
    }
  }

  /// Send social notification
  static Future<Map<String, dynamic>> sendSocialNotification({
    required String userId,
    required String fromUserName,
    required String actionType, // 'follow', 'like', 'comment', etc.
    String? entityId,
    String? entityType,
  }) async {
    try {
      final templates = {
        'follow': {
          'title': 'New Follower!',
          'message': '$fromUserName started following you.',
        },
        'like': {
          'title': 'Your post was liked!',
          'message': '$fromUserName liked your post.',
        },
        'comment': {
          'title': 'New Comment',
          'message': '$fromUserName commented on your post.',
        },
        'trip_invite': {
          'title': 'Trip Invitation',
          'message': '$fromUserName invited you to join a trip.',
        },
      };

      final template = templates[actionType];
      if (template == null) {
        throw Exception('Unknown social action type: $actionType');
      }

      return await NotificationService.instance.sendNotificationToUser(
        userId: userId,
        title: template['title']!,
        message: template['message']!,
        data: {
          'type': 'social',
          'action_type': actionType,
          'from_user': fromUserName,
          'entity_id': entityId,
          'entity_type': entityType,
        },
      );
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to send social notification', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // PRIVATE HELPER METHODS
  // ===============================

  /// Get user's OneSignal player IDs
  Future<List<String>> _getUserPlayerIds(String userId) async {
    try {
      final devices = await SupabaseDatabaseService.select(
        table: _devicesTable,
        filters: {'user_id': userId, 'is_active': true},
      );

      return devices
          .map((device) => device['onesignal_player_id'] as String)
          .toList();
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to get user player IDs', e);
      return [];
    }
  }

  /// Save notification record to database
  static Future<Map<String, dynamic>> _saveNotificationRecord({
    required String userId,
    required String title,
    required String message,
    Map<String, dynamic>? data,
    String? imageUrl,
    String? actionUrl,
    String? oneSignalId,
    String status = 'pending',
  }) async {
    try {
      final notificationData = {
        'user_id': userId,
        'title': title,
        'message': message,
        'data': data ?? {},
        'image_url': imageUrl,
        'action_url': actionUrl,
        'onesignal_id': oneSignalId,
        'status': status,
        'type': data?['type'] ?? 'general',
        'is_read': false,
        'sent_at': DateTime.now().toIso8601String(),
      };

      return await SupabaseDatabaseService.insert(
        table: _notificationsTable,
        data: notificationData,
      );
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to save notification record', e, stackTrace);
      rethrow;
    }
  }

  /// Send notification via OneSignal API
  static Future<Map<String, dynamic>> _sendOneSignalNotification({
    required List<String> playerIds,
    required String title,
    required String message,
    Map<String, dynamic>? data,
    String? imageUrl,
    String? actionUrl,
    DateTime? scheduleAt,
  }) async {
    try {
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Basic $_restApiKey',
      };

      final body = {
        'app_id': _appId,
        'include_player_ids': playerIds,
        'headings': {'en': title},
        'contents': {'en': message},
        'data': data ?? {},
      };

      if (imageUrl != null) {
        body['big_picture'] = imageUrl;
        body['large_icon'] = imageUrl;
      }

      if (actionUrl != null) {
        body['url'] = actionUrl;
      }

      if (scheduleAt != null) {
        body['send_after'] = scheduleAt.toIso8601String();
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/notifications'),
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception('OneSignal API error: ${error['errors']}');
      }
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to send OneSignal notification', e, stackTrace);
      rethrow;
    }
  }

  /// Send notification with tags via OneSignal API
  static Future<Map<String, dynamic>> _sendOneSignalNotificationWithTags({
    required List<Map<String, String>> tags,
    required String title,
    required String message,
    Map<String, dynamic>? data,
    String? imageUrl,
    String? actionUrl,
    DateTime? scheduleAt,
  }) async {
    try {
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Basic $_restApiKey',
      };

      final body = {
        'app_id': _appId,
        'filters': tags,
        'headings': {'en': title},
        'contents': {'en': message},
        'data': data ?? {},
      };

      if (imageUrl != null) {
        body['big_picture'] = imageUrl;
        body['large_icon'] = imageUrl;
      }

      if (actionUrl != null) {
        body['url'] = actionUrl;
      }

      if (scheduleAt != null) {
        body['send_after'] = scheduleAt.toIso8601String();
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/notifications'),
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception('OneSignal API error: ${error['errors']}');
      }
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to send OneSignal notification with tags', e, stackTrace);
      rethrow;
    }
  }

  /// Update OneSignal player tags
  static Future<void> _updateOneSignalTags(
    String playerId,
    Map<String, dynamic> tags,
  ) async {
    try {
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Basic $_restApiKey',
      };

      final body = {
        'app_id': _appId,
        'tags': tags,
      };

      await http.put(
        Uri.parse('$_baseUrl/players/$playerId'),
        headers: headers,
        body: json.encode(body),
      );
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to update OneSignal tags', e);
      // Don't throw error as this is not critical
    }
  }
}
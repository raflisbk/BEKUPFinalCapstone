import 'package:flutter/foundation.dart';
import '../utils/logger.dart';
import '../../services/notification_service.dart';
import '../config/service_locator.dart';

/// Provider for Notification management
class NotificationProvider with ChangeNotifier {
  static const String _tag = 'NotificationProvider';

  // Service instance with dependency injection
  final NotificationService _notificationService;

  List<Map<String, dynamic>> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic> _preferences = {};

  // Constructor with dependency injection
  NotificationProvider({NotificationService? notificationService})
      : _notificationService = notificationService ?? ServiceLocator.notificationService;

  // Getters
  List<Map<String, dynamic>> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic> get preferences => _preferences;

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Set error state
  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _setError(null);
  }

  /// Load user notifications
  Future<void> loadNotifications() async {
    try {
      AppLogger.debug(_tag, 'Loading notifications');
      _setLoading(true);
      _setError(null);

      // Note: This method needs to be implemented in NotificationService
      // For now, we'll use placeholder
      _notifications = [];
      _unreadCount = 0;

      AppLogger.success(_tag, 'Loaded ${_notifications.length} notifications');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to load notifications', e, stackTrace);
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Send notification to user
  Future<bool> sendNotificationToUser({
    required String userId,
    required String title,
    required String message,
    Map<String, dynamic>? data,
    String? imageUrl,
    String? actionUrl,
  }) async {
    try {
      AppLogger.debug(_tag, 'Sending notification to user: $userId');
      _setError(null);

      await _notificationService.sendNotificationToUser(
        userId: userId,
        title: title,
        message: message,
        data: data,
        imageUrl: imageUrl,
        actionUrl: actionUrl,
      );

      AppLogger.success(_tag, 'Notification sent successfully');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to send notification', e, stackTrace);
      _setError(e.toString());
      return false;
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      AppLogger.debug(_tag, 'Marking notification as read: $notificationId');

      // Update local state
      final index = _notifications.indexWhere((n) => n['id'] == notificationId);
      if (index != -1) {
        _notifications[index]['read'] = true;
        _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
        notifyListeners();
      }

      // Note: Update in database would be done here
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to mark notification as read', e, stackTrace);
      _setError(e.toString());
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      AppLogger.debug(_tag, 'Marking all notifications as read');

      // Update local state
      for (final notification in _notifications) {
        notification['read'] = true;
      }
      _unreadCount = 0;
      notifyListeners();

      // Note: Update in database would be done here
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to mark all notifications as read', e, stackTrace);
      _setError(e.toString());
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      AppLogger.debug(_tag, 'Deleting notification: $notificationId');

      // Update local state
      final index = _notifications.indexWhere((n) => n['id'] == notificationId);
      if (index != -1) {
        final wasUnread = !(_notifications[index]['read'] as bool? ?? false);
        _notifications.removeAt(index);
        if (wasUnread) {
          _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
        }
        notifyListeners();
      }

      // Note: Delete from database would be done here
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to delete notification', e, stackTrace);
      _setError(e.toString());
    }
  }

  /// Update notification preferences
  Future<void> updatePreferences(Map<String, dynamic> newPreferences) async {
    try {
      AppLogger.debug(_tag, 'Updating notification preferences');
      _setError(null);

      _preferences = {..._preferences, ...newPreferences};
      notifyListeners();

      // Note: Save to database would be done here
      AppLogger.success(_tag, 'Notification preferences updated');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to update preferences', e, stackTrace);
      _setError(e.toString());
    }
  }

  /// Add new notification to local list
  void addNotification(Map<String, dynamic> notification) {
    _notifications.insert(0, notification);
    if (!(notification['read'] as bool? ?? false)) {
      _unreadCount++;
    }
    notifyListeners();
  }

  /// Clear all notifications
  void clearNotifications() {
    _notifications.clear();
    _unreadCount = 0;
    notifyListeners();
  }

  /// Refresh notifications
  Future<void> refresh() async {
    await loadNotifications();
  }
}
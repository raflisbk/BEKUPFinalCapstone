import 'package:flutter/foundation.dart';
import '../models/chat_models.dart';
import '../../services/chat_service.dart';
import '../utils/logger.dart';

/// Provider for chat state management
class ChatProvider with ChangeNotifier {
  static const String _tag = 'ChatProvider';

  String? _currentUserId;
  List<ChatConversation> _conversations = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  String? get currentUserId => _currentUserId;
  List<ChatConversation> get conversations => _conversations;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Initialize chat provider with user ID
  void initialize(String userId) {
    AppLogger.debug(_tag, 'Initializing chat provider', {
      'userId': userId,
    });

    _currentUserId = userId;
    _loadConversations();
    _updateOnlineStatus(true);
  }

  /// Load conversations for current user
  void _loadConversations() {
    if (_currentUserId == null) return;

    AppLogger.debug(_tag, 'Loading conversations');

    // Subscribe to user conversations stream
    ChatService.subscribeToUserConversations(_currentUserId!).listen(
      (update) {
        AppLogger.debug(_tag, 'Conversation update received', {
          'type': update['type'],
        });
        
        // Reload conversations when updates occur
        _refreshConversations();
      },
      onError: (error, stackTrace) {
        AppLogger.error(_tag, 'Failed to load conversations', error, stackTrace);
        _errorMessage = error.toString();
        notifyListeners();
      },
    );

    // Initial load
    _refreshConversations();
  }

  /// Refresh conversations from service
  Future<void> _refreshConversations() async {
    try {
      final conversationsData = await ChatService.getUserConversations(
        userId: _currentUserId!,
      );

      _conversations = conversationsData.map((data) => _convertToConversationModel(data)).toList();
      notifyListeners();
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to refresh conversations', e, stackTrace);
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Convert service data to ChatConversation model
  ChatConversation _convertToConversationModel(Map<String, dynamic> data) {
    final participants = data['participants'] as List<dynamic>? ?? [];
    final participantIds = participants.map((p) => p['user_id'] as String).toList();
    
    // Create participant data map
    final participantData = <String, dynamic>{};
    for (final participant in participants) {
      participantData[participant['user_id']] = {
        'name': participant['name'] ?? 'Unknown',
        'photoUrl': participant['photo_url'],
      };
    }

    final lastMessage = data['last_message'] as Map<String, dynamic>?;
    final unreadCount = <String, int>{};
    if (_currentUserId != null) {
      unreadCount[_currentUserId!] = data['unread_count'] as int? ?? 0;
    }

    return ChatConversation(
      id: data['id'],
      participantIds: participantIds,
      participantData: participantData,
      lastMessage: lastMessage?['content'],
      lastMessageTime: lastMessage != null 
          ? DateTime.parse(lastMessage['created_at'])
          : DateTime.parse(data['created_at']),
      lastMessageSenderId: lastMessage?['sender_id'],
      unreadCount: unreadCount,
      createdAt: DateTime.parse(data['created_at']),
      updatedAt: DateTime.parse(data['updated_at'] ?? data['created_at']),
      isGroupChat: data['type'] == 'group',
      groupName: data['title'],
      groupPhotoUrl: null, // Not supported in current service
      adminId: data['created_by'],
    );
  }

  /// Get or create conversation with another user
  Future<ChatConversation?> getOrCreateConversation({
    required String otherUserId,
    required String currentUserName,
    required String otherUserName,
    String? currentUserPhotoUrl,
    String? otherUserPhotoUrl,
  }) async {
    if (_currentUserId == null) {
      AppLogger.warning(_tag, 'Cannot create conversation - user not initialized');
      return null;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    AppLogger.debug(_tag, 'Getting or creating conversation', {
      'otherUserId': otherUserId,
    });

    try {
      final conversationData = await ChatService.createConversation(
        participantIds: [otherUserId],
        type: 'direct',
      );

      final conversation = _convertToConversationModel(conversationData);
      
      _isLoading = false;
      notifyListeners();

      AppLogger.info(_tag, 'Conversation ready', {
        'conversationId': conversation.id,
      });

      return conversation;
    } catch (e, stackTrace) {
      _isLoading = false;
      _errorMessage = 'Failed to create conversation';
      AppLogger.error(_tag, 'Failed to get or create conversation', e, stackTrace);
      notifyListeners();
      return null;
    }
  }

  /// Send a message
  Future<bool> sendMessage({
    required String conversationId,
    required String text,
    required String senderName,
    required String recipientId,
    String? senderPhotoUrl,
  }) async {
    if (_currentUserId == null) {
      AppLogger.warning(_tag, 'Cannot send message - user not initialized');
      return false;
    }

    AppLogger.debug(_tag, 'Sending message', {
      'conversationId': conversationId,
    });

    try {
      await ChatService.sendMessage(
        conversationId: conversationId,
        content: text,
        messageType: 'text',
      );

      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to send message', e, stackTrace);
      _errorMessage = 'Failed to send message';
      notifyListeners();
      return false;
    }
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead(String conversationId) async {
    if (_currentUserId == null) return;

    AppLogger.debug(_tag, 'Marking messages as read', {
      'conversationId': conversationId,
    });

    try {
      await ChatService.markConversationAsRead(
        conversationId: conversationId,
        userId: _currentUserId!,
      );
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to mark messages as read', e, stackTrace);
    }
  }

  /// Delete a conversation
  Future<bool> deleteConversation(String conversationId) async {
    AppLogger.debug(_tag, 'Deleting conversation', {
      'conversationId': conversationId,
    });

    _isLoading = true;
    notifyListeners();

    try {
      // Note: ChatService doesn't have a direct delete method,
      // so we'll remove the current user from the conversation
      await ChatService.removeParticipantFromConversation(
        conversationId: conversationId,
        userId: _currentUserId!,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to delete conversation', e, stackTrace);
      _isLoading = false;
      _errorMessage = 'Failed to delete conversation';
      notifyListeners();
      return false;
    }
  }

  /// Update user online status
  void _updateOnlineStatus(bool isOnline) {
    if (_currentUserId == null) return;

    AppLogger.debug(_tag, 'Updating online status', {
      'isOnline': isOnline,
    });

    // Note: ChatService doesn't have online status functionality yet
    // This would need to be implemented in the service
    AppLogger.info(_tag, 'Online status update not implemented in service');
  }

  /// Get total unread messages count
  Future<int> getTotalUnreadCount() async {
    if (_currentUserId == null) return 0;

    try {
      // Calculate total unread count from all conversations
      int totalUnread = 0;
      for (final conversation in _conversations) {
        totalUnread += conversation.getUnreadCount(_currentUserId!);
      }
      return totalUnread;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get total unread count', e, stackTrace);
      return 0;
    }
  }

  /// Set user offline when logging out
  void setOffline() {
    AppLogger.debug(_tag, 'Setting user offline');
    _updateOnlineStatus(false);
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    AppLogger.debug(_tag, 'Disposing chat provider');
    setOffline();
    super.dispose();
  }
}

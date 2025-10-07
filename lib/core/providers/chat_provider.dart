import 'package:flutter/foundation.dart';
import '../models/chat_models.dart';
import '../../services/chat_service.dart';
import '../utils/logger.dart';

/// Provider for chat state management
class ChatProvider with ChangeNotifier {
  static const String _tag = 'ChatProvider';

  final ChatService _chatService = ChatService();

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

    _chatService.getConversationsStream(_currentUserId!).listen(
      (conversations) {
        AppLogger.debug(_tag, 'Conversations updated', {
          'count': conversations.length,
        });

        _conversations = conversations;
        notifyListeners();
      },
      onError: (error, stackTrace) {
        AppLogger.error(_tag, 'Failed to load conversations', error, stackTrace);
        _errorMessage = error.toString();
        notifyListeners();
      },
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

    final conversation = await _chatService.getOrCreateConversation(
      currentUserId: _currentUserId!,
      otherUserId: otherUserId,
      currentUserName: currentUserName,
      otherUserName: otherUserName,
      currentUserPhotoUrl: currentUserPhotoUrl,
      otherUserPhotoUrl: otherUserPhotoUrl,
    );

    _isLoading = false;

    if (conversation == null) {
      _errorMessage = 'Failed to create conversation';
      AppLogger.warning(_tag, 'Failed to get or create conversation');
    } else {
      AppLogger.info(_tag, 'Conversation ready', {
        'conversationId': conversation.id,
      });
    }

    notifyListeners();
    return conversation;
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

    final success = await _chatService.sendMessage(
      conversationId: conversationId,
      senderId: _currentUserId!,
      senderName: senderName,
      senderPhotoUrl: senderPhotoUrl,
      text: text,
      recipientId: recipientId,
    );

    if (!success) {
      _errorMessage = 'Failed to send message';
      notifyListeners();
    }

    return success;
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead(String conversationId) async {
    if (_currentUserId == null) return;

    AppLogger.debug(_tag, 'Marking messages as read', {
      'conversationId': conversationId,
    });

    await _chatService.markMessagesAsRead(
      conversationId: conversationId,
      currentUserId: _currentUserId!,
    );
  }

  /// Delete a conversation
  Future<bool> deleteConversation(String conversationId) async {
    AppLogger.debug(_tag, 'Deleting conversation', {
      'conversationId': conversationId,
    });

    _isLoading = true;
    notifyListeners();

    final success = await _chatService.deleteConversation(conversationId);

    _isLoading = false;

    if (!success) {
      _errorMessage = 'Failed to delete conversation';
    }

    notifyListeners();
    return success;
  }

  /// Update user online status
  void _updateOnlineStatus(bool isOnline) {
    if (_currentUserId == null) return;

    AppLogger.debug(_tag, 'Updating online status', {
      'isOnline': isOnline,
    });

    _chatService.updateOnlineStatus(
      userId: _currentUserId!,
      isOnline: isOnline,
    );
  }

  /// Get total unread messages count
  Future<int> getTotalUnreadCount() async {
    if (_currentUserId == null) return 0;

    return await _chatService.getTotalUnreadCount(_currentUserId!);
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

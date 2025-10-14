import 'package:flutter/foundation.dart';
import '../models/chat_model.dart';
import '../models/conversation_model.dart';
import '../models/user_model.dart';
import '../../services/messaging_service.dart';
import '../../services/chat_service.dart';

/// Provider for managing messaging and chat functionality
class MessagingProvider with ChangeNotifier {
  final MessagingService _messagingService = MessagingService.instance;
  final ChatService _chatService = ChatService.instance;

  List<Conversation> _conversations = [];
  Map<String, List<ChatMessage>> _conversationMessages = {};
  bool _isLoading = false;
  String? _error;

  Conversation? _activeConversation;
  String? _newMessageText;
  List<UserProfile> _searchResults = [];
  bool _isSearching = false;

  // Getters
  List<Conversation> get conversations => _conversations;
  Map<String, List<ChatMessage>> get conversationMessages => _conversationMessages;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Conversation? get activeConversation => _activeConversation;
  String? get newMessageText => _newMessageText;
  List<UserProfile> get searchResults => _searchResults;
  bool get isSearching => _isSearching;

  /// Load all conversations for the current user
  Future<void> loadConversations() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final conversationsData = await _messagingService.getConversations();
      _conversations = conversationsData.map((data) => Conversation.fromMap(data)).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load messages for a specific conversation
  Future<void> loadConversationMessages(String conversationId) async {
    try {
      final messagesData = await _messagingService.getConversationMessages(conversationId);
      _conversationMessages[conversationId] = messagesData.map((data) => ChatMessage.fromMap(data)).toList();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Send a message to a conversation
  Future<void> sendMessage({
    required String conversationId,
    required String message,
    String? messageType,
  }) async {
    try {
      final messageData = await _messagingService.sendMessage(
        conversationId: conversationId,
        message: message,
        messageType: messageType ?? 'text',
      );

      // Add the new message to local state
      final newMessage = ChatMessage.fromMap(messageData);
      if (_conversationMessages.containsKey(conversationId)) {
        _conversationMessages[conversationId]!.add(newMessage);
      } else {
        _conversationMessages[conversationId] = [newMessage];
      }

      // Update conversation's last message
      final conversationIndex = _conversations.indexWhere((c) => c.id == conversationId);
      if (conversationIndex != -1) {
        _conversations[conversationIndex] = _conversations[conversationIndex].copyWith(
          lastMessage: newMessage,
          updatedAt: DateTime.now(),
        );
      }

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Create a new conversation
  Future<Conversation?> createConversation({
    required List<String> participantIds,
    String? conversationName,
    bool isGroup = false,
  }) async {
    try {
      final conversationData = await _messagingService.createConversation(
        participantIds: participantIds,
        conversationName: conversationName,
        isGroup: isGroup,
      );

      final newConversation = Conversation.fromMap(conversationData);
      _conversations.insert(0, newConversation);
      notifyListeners();

      return newConversation;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Search users for starting new conversations
  Future<void> searchUsers(String query) async {
    if (query.isEmpty) {
      _searchResults = [];
      _isSearching = false;
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();

    try {
      final usersData = await _messagingService.searchUsers(query);
      _searchResults = usersData.map((data) => UserProfile.fromMap(data)).toList();
      _isSearching = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isSearching = false;
      notifyListeners();
    }
  }

  /// Mark conversation as read
  Future<void> markConversationAsRead(String conversationId) async {
    try {
      await _messagingService.markConversationAsRead(conversationId);
      
      // Update local state
      final conversationIndex = _conversations.indexWhere((c) => c.id == conversationId);
      if (conversationIndex != -1) {
        _conversations[conversationIndex] = _conversations[conversationIndex].copyWith(
          unreadCount: 0,
        );
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Delete a conversation
  Future<void> deleteConversation(String conversationId) async {
    try {
      await _messagingService.deleteConversation(conversationId);
      
      // Remove from local state
      _conversations.removeWhere((c) => c.id == conversationId);
      _conversationMessages.remove(conversationId);
      
      if (_activeConversation?.id == conversationId) {
        _activeConversation = null;
      }
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Send an image message
  Future<void> sendImageMessage({
    required String conversationId,
    required String imagePath,
    String? caption,
  }) async {
    try {
      final messageData = await _messagingService.sendImageMessage(
        conversationId: conversationId,
        imagePath: imagePath,
        caption: caption,
      );

      // Add the new message to local state
      final newMessage = ChatMessage.fromMap(messageData);
      if (_conversationMessages.containsKey(conversationId)) {
        _conversationMessages[conversationId]!.add(newMessage);
      } else {
        _conversationMessages[conversationId] = [newMessage];
      }

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Get conversation statistics
  Future<Map<String, dynamic>?> getConversationStats(String conversationId) async {
    try {
      return await _messagingService.getConversationStats(conversationId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Update conversation settings
  Future<void> updateConversationSettings({
    required String conversationId,
    bool? muteNotifications,
    String? conversationName,
  }) async {
    try {
      await _messagingService.updateConversationSettings(
        conversationId: conversationId,
        muteNotifications: muteNotifications,
        conversationName: conversationName,
      );

      // Update local state
      final conversationIndex = _conversations.indexWhere((c) => c.id == conversationId);
      if (conversationIndex != -1) {
        _conversations[conversationIndex] = _conversations[conversationIndex].copyWith(
          name: conversationName ?? _conversations[conversationIndex].name,
          isMuted: muteNotifications ?? _conversations[conversationIndex].isMuted,
        );
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // State management methods
  void setActiveConversation(Conversation? conversation) {
    _activeConversation = conversation;
    notifyListeners();
  }

  void setNewMessageText(String? text) {
    _newMessageText = text;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearSearchResults() {
    _searchResults = [];
    _isSearching = false;
    notifyListeners();
  }

  /// Get unread message count
  int get totalUnreadCount {
    return _conversations.fold(0, (sum, conversation) => sum + conversation.unreadCount);
  }

  /// Get active conversations (recent activity)
  List<Conversation> get activeConversations {
    final sorted = List<Conversation>.from(_conversations);
    sorted.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return sorted.take(10).toList();
  }

  /// Refresh conversations
  Future<void> refresh() async {
    await loadConversations();
  }
}
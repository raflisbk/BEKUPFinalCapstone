import 'package:flutter/foundation.dart';
import '../models/chat_models.dart';
import '../models/user_model.dart';
import '../../services/chat_service.dart';
import '../utils/service_locator.dart';

/// Provider for managing messaging and chat functionality
class MessagingProvider with ChangeNotifier {
  // Access services through ServiceLocator for dependency injection
  ChatService get _chatService => ServiceLocator.instance.get<ChatService>();

  List<ChatConversation> _conversations = [];
  // ignore: prefer_final_fields - Map is modified throughout the provider lifecycle
  Map<String, List<ChatMessage>> _conversationMessages = {};
  bool _isLoading = false;
  String? _error;

  ChatConversation? _activeConversation;
  String? _newMessageText;
  List<UserModel> _searchResults = [];
  bool _isSearching = false;

  // Getters
  List<ChatConversation> get conversations => _conversations;
  Map<String, List<ChatMessage>> get conversationMessages => _conversationMessages;
  bool get isLoading => _isLoading;
  String? get error => _error;
  ChatConversation? get activeConversation => _activeConversation;
  String? get newMessageText => _newMessageText;
  List<UserModel> get searchResults => _searchResults;
  bool get isSearching => _isSearching;

  /// Load all conversations for the current user
  Future<void> loadConversations() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final conversationsData = await _chatService.getUserConversations();
      _conversations = conversationsData.map((data) => _convertToConversation(data)).toList();
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
      final messagesData = await _chatService.getMessages(conversationId: conversationId);
      _conversationMessages[conversationId] = messagesData.map((data) => _convertToMessage(data)).toList();
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
      final messageData = await _chatService.sendMessage(
        conversationId: conversationId,
        content: message,
      );

      // Add the new message to local state
      final newMessage = _convertToMessage(messageData);
      if (_conversationMessages.containsKey(conversationId)) {
        _conversationMessages[conversationId]!.add(newMessage);
      } else {
        _conversationMessages[conversationId] = [newMessage];
      }

      // Update conversation's last message
      final conversationIndex = _conversations.indexWhere((c) => c.id == conversationId);
      if (conversationIndex != -1) {
        // Create updated conversation with new data
        final oldConversation = _conversations[conversationIndex];
        _conversations[conversationIndex] = ChatConversation(
          id: oldConversation.id,
          participantIds: oldConversation.participantIds,
          participantData: oldConversation.participantData,
          lastMessage: newMessage.text,
          lastMessageTime: newMessage.sentAt,
          lastMessageSenderId: newMessage.senderId,
          unreadCount: oldConversation.unreadCount,
          createdAt: oldConversation.createdAt,
          updatedAt: DateTime.now(),
          isGroupChat: oldConversation.isGroupChat,
          groupName: oldConversation.groupName,
          groupPhotoUrl: oldConversation.groupPhotoUrl,
          adminId: oldConversation.adminId,
        );
      }

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Create a new conversation
  Future<ChatConversation?> createConversation({
    required List<String> participantIds,
    String? conversationName,
    bool isGroup = false,
  }) async {
    try {
      final conversationData = await _chatService.createConversation(
        participantIds: participantIds,
        title: conversationName,
        type: isGroup ? 'group' : 'direct',
      );

      final newConversation = _convertToConversation(conversationData);
      _conversations.insert(0, newConversation);
      notifyListeners();

      return newConversation;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Search users for starting new conversations (stub implementation)
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
      // Stub implementation - no user search service available
      _searchResults = [];
      _isSearching = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isSearching = false;
      notifyListeners();
    }
  }

  /// Mark conversation as read (stub implementation)
  Future<void> markConversationAsRead(String conversationId) async {
    try {
      // Stub implementation - mark as read in local state
      final conversationIndex = _conversations.indexWhere((c) => c.id == conversationId);
      if (conversationIndex != -1) {
        final oldConversation = _conversations[conversationIndex];
        final newUnreadCount = Map<String, int>.from(oldConversation.unreadCount);
        // Clear unread count for current user (would need actual user ID)
        newUnreadCount.clear();
        
        _conversations[conversationIndex] = ChatConversation(
          id: oldConversation.id,
          participantIds: oldConversation.participantIds,
          participantData: oldConversation.participantData,
          lastMessage: oldConversation.lastMessage,
          lastMessageTime: oldConversation.lastMessageTime,
          lastMessageSenderId: oldConversation.lastMessageSenderId,
          unreadCount: newUnreadCount,
          createdAt: oldConversation.createdAt,
          updatedAt: oldConversation.updatedAt,
          isGroupChat: oldConversation.isGroupChat,
          groupName: oldConversation.groupName,
          groupPhotoUrl: oldConversation.groupPhotoUrl,
          adminId: oldConversation.adminId,
        );
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Delete a conversation (stub implementation)
  Future<void> deleteConversation(String conversationId) async {
    try {
      // Stub implementation - no delete method available, just remove from local state
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

  /// Send an image message (stub implementation)
  Future<void> sendImageMessage({
    required String conversationId,
    required String imagePath,
    String? caption,
  }) async {
    try {
      // Stub implementation - send as text message with image indicator
      await sendMessage(
        conversationId: conversationId,
        message: caption ?? 'Image shared',
        messageType: 'image',
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Get conversation statistics (stub implementation)
  Future<Map<String, dynamic>?> getConversationStats(String conversationId) async {
    try {
      // Stub implementation - return basic stats
      final messages = _conversationMessages[conversationId] ?? [];
      return {
        'message_count': messages.length,
        'participant_count': _conversations.any((c) => c.id == conversationId) 
            ? _conversations.firstWhere((c) => c.id == conversationId).participantCount
            : 0,
      };
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Update conversation settings (stub implementation)
  Future<void> updateConversationSettings({
    required String conversationId,
    bool? muteNotifications,
    String? conversationName,
  }) async {
    try {
      // Stub implementation - update local state only
      final conversationIndex = _conversations.indexWhere((c) => c.id == conversationId);
      if (conversationIndex != -1) {
        final oldConversation = _conversations[conversationIndex];
        _conversations[conversationIndex] = ChatConversation(
          id: oldConversation.id,
          participantIds: oldConversation.participantIds,
          participantData: oldConversation.participantData,
          lastMessage: oldConversation.lastMessage,
          lastMessageTime: oldConversation.lastMessageTime,
          lastMessageSenderId: oldConversation.lastMessageSenderId,
          unreadCount: oldConversation.unreadCount,
          createdAt: oldConversation.createdAt,
          updatedAt: DateTime.now(),
          isGroupChat: oldConversation.isGroupChat,
          groupName: conversationName ?? oldConversation.groupName,
          groupPhotoUrl: oldConversation.groupPhotoUrl,
          adminId: oldConversation.adminId,
        );
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // State management methods
  void setActiveConversation(ChatConversation? conversation) {
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
    int total = 0;
    for (final conversation in _conversations) {
      // Sum all unread counts for all users in each conversation
      total += conversation.unreadCount.values.fold<int>(0, (sum, count) => sum + count);
    }
    return total;
  }

  /// Get active conversations (recent activity)
  List<ChatConversation> get activeConversations {
    final sorted = List<ChatConversation>.from(_conversations);
    sorted.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return sorted.take(10).toList();
  }

  /// Refresh conversations
  Future<void> refresh() async {
    await loadConversations();
  }

  /// Helper method to convert raw data to ChatConversation
  ChatConversation _convertToConversation(Map<String, dynamic> data) {
    return ChatConversation(
      id: data['id'] ?? '',
      participantIds: List<String>.from(data['participant_ids'] ?? []),
      participantData: Map<String, dynamic>.from(data['participant_data'] ?? {}),
      lastMessage: data['last_message'],
      lastMessageTime: data['last_message_at'] != null 
          ? DateTime.parse(data['last_message_at']) 
          : null,
      lastMessageSenderId: data['last_message_sender_id'],
      unreadCount: Map<String, int>.from(data['unread_count'] ?? {}),
      createdAt: DateTime.parse(data['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(data['updated_at'] ?? DateTime.now().toIso8601String()),
      isGroupChat: data['type'] == 'group',
      groupName: data['title'],
      groupPhotoUrl: data['group_photo_url'],
      adminId: data['created_by'],
    );
  }

  /// Helper method to convert raw data to ChatMessage
  ChatMessage _convertToMessage(Map<String, dynamic> data) {
    return ChatMessage(
      id: data['id'] ?? '',
      conversationId: data['conversation_id'] ?? '',
      senderId: data['sender_id'] ?? '',
      senderName: data['sender_name'] ?? '',
      senderPhotoUrl: data['sender_photo_url'],
      text: data['content'] ?? '',
      type: _parseMessageType(data['type']),
      imageUrl: data['image_url'],
      sentAt: DateTime.parse(data['sent_at'] ?? DateTime.now().toIso8601String()),
      isRead: data['is_read'] ?? false,
      readAt: data['read_at'] != null ? DateTime.parse(data['read_at']) : null,
    );
  }

  /// Helper method to parse message type
  MessageType _parseMessageType(String? type) {
    switch (type) {
      case 'image':
        return MessageType.image;
      case 'system':
        return MessageType.system;
      default:
        return MessageType.text;
    }
  }
}
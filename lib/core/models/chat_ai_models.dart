/// Chat-related models
/// This file contains model classes for chat functionality
library chat_ai_models;

/// Chat roles for AI chat
enum ChatRole {
  user,
  assistant,
  system,
}

/// Chat Message
class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String content;
  final String type; // 'text', 'image', 'file', 'location'
  final ChatRole? role; // For AI chat compatibility
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;
  final bool isRead;
  final bool isEdited;
  final String? replyToId;

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.type,
    this.role,
    this.metadata,
    required this.timestamp,
    required this.isRead,
    required this.isEdited,
    this.replyToId,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] ?? '',
      conversationId: map['conversation_id'] ?? '',
      senderId: map['sender_id'] ?? '',
      senderName: map['sender_name'] ?? '',
      content: map['content'] ?? '',
      type: map['type'] ?? 'text',
      role: map['role'] != null ? ChatRole.values.firstWhere(
        (r) => r.name == map['role'],
        orElse: () => ChatRole.user,
      ) : null,
      metadata: map['metadata'],
      timestamp: DateTime.parse(map['timestamp'] ?? DateTime.now().toIso8601String()),
      isRead: map['is_read'] ?? false,
      isEdited: map['is_edited'] ?? false,
      replyToId: map['reply_to_id'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'sender_name': senderName,
      'content': content,
      'type': type,
      'role': role?.name,
      'metadata': metadata,
      'timestamp': timestamp.toIso8601String(),
      'is_read': isRead,
      'is_edited': isEdited,
      'reply_to_id': replyToId,
    };
  }

  ChatMessage copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? senderName,
    String? content,
    String? type,
    ChatRole? role,
    Map<String, dynamic>? metadata,
    DateTime? timestamp,
    bool? isRead,
    bool? isEdited,
    String? replyToId,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      content: content ?? this.content,
      type: type ?? this.type,
      role: role ?? this.role,
      metadata: metadata ?? this.metadata,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      isEdited: isEdited ?? this.isEdited,
      replyToId: replyToId ?? this.replyToId,
    );
  }
}

/// Chat Session
class ChatSession {
  final String id;
  final String userId;
  final String type; // 'ai_assistant', 'trip_planning', 'general'
  final String title;
  final Map<String, dynamic> context;
  final List<ChatMessage> messages; // Add messages list
  final DateTime startedAt;
  final DateTime? endedAt;
  final bool isActive;
  final Map<String, dynamic> settings;

  const ChatSession({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.context,
    required this.messages,
    required this.startedAt,
    this.endedAt,
    required this.isActive,
    required this.settings,
  });

  factory ChatSession.fromMap(Map<String, dynamic> map) {
    return ChatSession(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      type: map['type'] ?? 'general',
      title: map['title'] ?? '',
      context: Map<String, dynamic>.from(map['context'] ?? {}),
      messages: (map['messages'] as List<dynamic>?)
          ?.map((messageMap) => ChatMessage.fromMap(messageMap))
          .toList() ?? [],
      startedAt: DateTime.parse(map['started_at'] ?? DateTime.now().toIso8601String()),
      endedAt: map['ended_at'] != null ? DateTime.parse(map['ended_at']) : null,
      isActive: map['is_active'] ?? true,
      settings: Map<String, dynamic>.from(map['settings'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'title': title,
      'context': context,
      'messages': messages.map((message) => message.toMap()).toList(),
      'started_at': startedAt.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
      'is_active': isActive,
      'settings': settings,
    };
  }

  ChatSession copyWith({
    String? id,
    String? userId,
    String? type,
    String? title,
    Map<String, dynamic>? context,
    List<ChatMessage>? messages,
    DateTime? startedAt,
    DateTime? endedAt,
    bool? isActive,
    Map<String, dynamic>? settings,
  }) {
    return ChatSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      context: context ?? this.context,
      messages: messages ?? this.messages,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      isActive: isActive ?? this.isActive,
      settings: settings ?? this.settings,
    );
  }
}
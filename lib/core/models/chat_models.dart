import 'package:cloud_firestore/cloud_firestore.dart';

/// Chat conversation model
class ChatConversation {
  final String id;
  final List<String> participantIds;
  final Map<String, dynamic> participantData; // uid -> {name, photoUrl}
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final String? lastMessageSenderId;
  final Map<String, int> unreadCount; // uid -> count
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatConversation({
    required this.id,
    required this.participantIds,
    required this.participantData,
    this.lastMessage,
    this.lastMessageTime,
    this.lastMessageSenderId,
    required this.unreadCount,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from Firestore document
  factory ChatConversation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ChatConversation(
      id: doc.id,
      participantIds: List<String>.from(data['participantIds'] ?? []),
      participantData: Map<String, dynamic>.from(data['participantData'] ?? {}),
      lastMessage: data['lastMessage'],
      lastMessageTime: (data['lastMessageTime'] as Timestamp?)?.toDate(),
      lastMessageSenderId: data['lastMessageSenderId'],
      unreadCount: Map<String, int>.from(data['unreadCount'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'participantIds': participantIds,
      'participantData': participantData,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime != null
          ? Timestamp.fromDate(lastMessageTime!)
          : null,
      'lastMessageSenderId': lastMessageSenderId,
      'unreadCount': unreadCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Get other participant's data
  Map<String, dynamic>? getOtherParticipant(String currentUserId) {
    final otherUserId = participantIds.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );

    if (otherUserId.isEmpty) return null;

    return participantData[otherUserId];
  }

  /// Get unread count for user
  int getUnreadCount(String userId) {
    return unreadCount[userId] ?? 0;
  }
}

/// Chat message model
class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String? senderPhotoUrl;
  final String text;
  final MessageType type;
  final String? imageUrl;
  final DateTime sentAt;
  final bool isRead;
  final DateTime? readAt;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    this.senderPhotoUrl,
    required this.text,
    this.type = MessageType.text,
    this.imageUrl,
    required this.sentAt,
    this.isRead = false,
    this.readAt,
  });

  /// Create from Firestore document
  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ChatMessage(
      id: doc.id,
      conversationId: data['conversationId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      senderPhotoUrl: data['senderPhotoUrl'],
      text: data['text'] ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.toString() == 'MessageType.${data['type']}',
        orElse: () => MessageType.text,
      ),
      imageUrl: data['imageUrl'],
      sentAt: (data['sentAt'] as Timestamp).toDate(),
      isRead: data['isRead'] ?? false,
      readAt: (data['readAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'conversationId': conversationId,
      'senderId': senderId,
      'senderName': senderName,
      'senderPhotoUrl': senderPhotoUrl,
      'text': text,
      'type': type.toString().split('.').last,
      'imageUrl': imageUrl,
      'sentAt': Timestamp.fromDate(sentAt),
      'isRead': isRead,
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
    };
  }

  /// Create a copy with updated fields
  ChatMessage copyWith({
    bool? isRead,
    DateTime? readAt,
  }) {
    return ChatMessage(
      id: id,
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName,
      senderPhotoUrl: senderPhotoUrl,
      text: text,
      type: type,
      imageUrl: imageUrl,
      sentAt: sentAt,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
    );
  }
}

/// Message type enum
enum MessageType {
  text,
  image,
  system,
}

/// Online status model
class UserOnlineStatus {
  final String userId;
  final bool isOnline;
  final DateTime lastSeen;

  UserOnlineStatus({
    required this.userId,
    required this.isOnline,
    required this.lastSeen,
  });

  /// Create from Firestore document
  factory UserOnlineStatus.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return UserOnlineStatus(
      userId: doc.id,
      isOnline: data['isOnline'] ?? false,
      lastSeen: (data['lastSeen'] as Timestamp).toDate(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'isOnline': isOnline,
      'lastSeen': Timestamp.fromDate(lastSeen),
    };
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/models/chat_models.dart';
import '../core/utils/logger.dart';

/// Service for managing chat operations
class ChatService {
  static const String _tag = 'ChatService';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _conversationsCollection =>
      _firestore.collection('conversations');
  CollectionReference get _messagesCollection =>
      _firestore.collection('messages');
  CollectionReference get _userStatusCollection =>
      _firestore.collection('user_status');

  /// Get or create a conversation between two users
  Future<ChatConversation?> getOrCreateConversation({
    required String currentUserId,
    required String otherUserId,
    required String currentUserName,
    required String otherUserName,
    String? currentUserPhotoUrl,
    String? otherUserPhotoUrl,
  }) async {
    try {
      AppLogger.debug(_tag, 'Getting or creating conversation', {
        'currentUserId': currentUserId,
        'otherUserId': otherUserId,
      });

      // Check if conversation already exists
      final querySnapshot = await _conversationsCollection
          .where('participantIds', arrayContains: currentUserId)
          .get();

      for (var doc in querySnapshot.docs) {
        final conversation = ChatConversation.fromFirestore(doc);
        if (conversation.participantIds.contains(otherUserId)) {
          AppLogger.info(_tag, 'Found existing conversation', {
            'conversationId': conversation.id,
          });
          return conversation;
        }
      }

      // Create new conversation
      AppLogger.debug(_tag, 'Creating new conversation');

      final now = DateTime.now();
      final conversationData = {
        'participantIds': [currentUserId, otherUserId],
        'participantData': {
          currentUserId: {
            'name': currentUserName,
            'photoUrl': currentUserPhotoUrl,
          },
          otherUserId: {
            'name': otherUserName,
            'photoUrl': otherUserPhotoUrl,
          },
        },
        'lastMessage': null,
        'lastMessageTime': null,
        'lastMessageSenderId': null,
        'unreadCount': {
          currentUserId: 0,
          otherUserId: 0,
        },
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      };

      final docRef = await _conversationsCollection.add(conversationData);

      AppLogger.info(_tag, 'Conversation created successfully', {
        'conversationId': docRef.id,
      });

      return ChatConversation.fromFirestore(await docRef.get());
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get or create conversation', e, stackTrace);
      return null;
    }
  }

  /// Send a text message
  Future<bool> sendMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    String? senderPhotoUrl,
    required String text,
    required String recipientId,
  }) async {
    try {
      AppLogger.debug(_tag, 'Sending message', {
        'conversationId': conversationId,
        'textLength': text.length,
      });

      final now = DateTime.now();

      // Create message
      final message = ChatMessage(
        id: '',
        conversationId: conversationId,
        senderId: senderId,
        senderName: senderName,
        senderPhotoUrl: senderPhotoUrl,
        text: text,
        type: MessageType.text,
        sentAt: now,
      );

      // Add message to messages collection
      await _messagesCollection.add(message.toFirestore());

      // Update conversation with last message
      await _conversationsCollection.doc(conversationId).update({
        'lastMessage': text,
        'lastMessageTime': Timestamp.fromDate(now),
        'lastMessageSenderId': senderId,
        'updatedAt': Timestamp.fromDate(now),
        'unreadCount.$recipientId': FieldValue.increment(1),
      });

      AppLogger.info(_tag, 'Message sent successfully', {
        'conversationId': conversationId,
      });

      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to send message', e, stackTrace);
      return false;
    }
  }

  /// Get conversations for a user (real-time stream)
  Stream<List<ChatConversation>> getConversationsStream(String userId) {
    AppLogger.debug(_tag, 'Getting conversations stream', {
      'userId': userId,
    });

    return _conversationsCollection
        .where('participantIds', arrayContains: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      AppLogger.debug(_tag, 'Conversations stream update', {
        'count': snapshot.docs.length,
      });

      return snapshot.docs
          .map((doc) => ChatConversation.fromFirestore(doc))
          .toList();
    });
  }

  /// Get messages for a conversation (real-time stream)
  Stream<List<ChatMessage>> getMessagesStream(String conversationId) {
    AppLogger.debug(_tag, 'Getting messages stream', {
      'conversationId': conversationId,
    });

    return _messagesCollection
        .where('conversationId', isEqualTo: conversationId)
        .orderBy('sentAt', descending: false)
        .snapshots()
        .map((snapshot) {
      AppLogger.debug(_tag, 'Messages stream update', {
        'count': snapshot.docs.length,
      });

      return snapshot.docs
          .map((doc) => ChatMessage.fromFirestore(doc))
          .toList();
    });
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead({
    required String conversationId,
    required String currentUserId,
  }) async {
    try {
      AppLogger.debug(_tag, 'Marking messages as read', {
        'conversationId': conversationId,
      });

      // Get unread messages
      final snapshot = await _messagesCollection
          .where('conversationId', isEqualTo: conversationId)
          .where('senderId', isNotEqualTo: currentUserId)
          .where('isRead', isEqualTo: false)
          .get();

      // Mark as read
      final batch = _firestore.batch();
      final now = DateTime.now();

      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': Timestamp.fromDate(now),
        });
      }

      await batch.commit();

      // Reset unread count in conversation
      await _conversationsCollection.doc(conversationId).update({
        'unreadCount.$currentUserId': 0,
      });

      AppLogger.info(_tag, 'Messages marked as read', {
        'count': snapshot.docs.length,
      });
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to mark messages as read', e, stackTrace);
    }
  }

  /// Update user online status
  Future<void> updateOnlineStatus({
    required String userId,
    required bool isOnline,
  }) async {
    try {
      AppLogger.debug(_tag, 'Updating online status', {
        'userId': userId,
        'isOnline': isOnline,
      });

      final status = UserOnlineStatus(
        userId: userId,
        isOnline: isOnline,
        lastSeen: DateTime.now(),
      );

      await _userStatusCollection.doc(userId).set(status.toFirestore());

      AppLogger.debug(_tag, 'Online status updated');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to update online status', e, stackTrace);
    }
  }

  /// Get user online status (real-time stream)
  Stream<UserOnlineStatus?> getUserOnlineStatusStream(String userId) {
    return _userStatusCollection.doc(userId).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return UserOnlineStatus.fromFirestore(snapshot);
    });
  }

  /// Delete a conversation
  Future<bool> deleteConversation(String conversationId) async {
    try {
      AppLogger.debug(_tag, 'Deleting conversation', {
        'conversationId': conversationId,
      });

      // Delete all messages in conversation
      final messagesSnapshot = await _messagesCollection
          .where('conversationId', isEqualTo: conversationId)
          .get();

      final batch = _firestore.batch();

      for (var doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete conversation
      batch.delete(_conversationsCollection.doc(conversationId));

      await batch.commit();

      AppLogger.info(_tag, 'Conversation deleted successfully', {
        'messagesDeleted': messagesSnapshot.docs.length,
      });

      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to delete conversation', e, stackTrace);
      return false;
    }
  }

  /// Get total unread messages count for user
  Future<int> getTotalUnreadCount(String userId) async {
    try {
      final snapshot = await _conversationsCollection
          .where('participantIds', arrayContains: userId)
          .get();

      int total = 0;
      for (var doc in snapshot.docs) {
        final conversation = ChatConversation.fromFirestore(doc);
        total += conversation.getUnreadCount(userId);
      }

      return total;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get total unread count', e, stackTrace);
      return 0;
    }
  }
}

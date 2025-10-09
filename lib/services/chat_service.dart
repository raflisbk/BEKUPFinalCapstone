import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart' as img;
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

  /// Send an image message with optimization
  Future<String?> sendImageMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    String? senderPhotoUrl,
    required File imageFile,
    required String recipientId,
  }) async {
    try {
      AppLogger.debug(_tag, 'Sending image message', {
        'conversationId': conversationId,
        'fileSize': imageFile.lengthSync(),
      });

      // Optimize image before upload (max 1280x1280, 80% quality)
      final optimizedImage = await _optimizeImage(imageFile);

      if (optimizedImage == null) {
        AppLogger.error(_tag, 'Failed to optimize image');
        return null;
      }

      // Upload to Firebase Storage
      final fileName = 'chat_images/$conversationId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = FirebaseStorage.instance.ref().child(fileName);

      AppLogger.debug(_tag, 'Uploading image', {'path': fileName});

      final uploadTask = await storageRef.putFile(
        optimizedImage,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final imageUrl = await uploadTask.ref.getDownloadURL();

      AppLogger.info(_tag, 'Image uploaded successfully', {
        'url': imageUrl,
        'optimizedSize': optimizedImage.lengthSync(),
      });

      // Create image message
      final now = DateTime.now();
      final message = ChatMessage(
        id: '',
        conversationId: conversationId,
        senderId: senderId,
        senderName: senderName,
        senderPhotoUrl: senderPhotoUrl,
        text: imageUrl,
        type: MessageType.image,
        sentAt: now,
      );

      // Add message to messages collection
      await _messagesCollection.add(message.toFirestore());

      // Update conversation with last message
      await _conversationsCollection.doc(conversationId).update({
        'lastMessage': '[Image]',
        'lastMessageTime': Timestamp.fromDate(now),
        'lastMessageSenderId': senderId,
        'updatedAt': Timestamp.fromDate(now),
        'unreadCount.$recipientId': FieldValue.increment(1),
      });

      AppLogger.success(_tag, 'Image message sent successfully');

      // Clean up optimized file
      await optimizedImage.delete();

      return imageUrl;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to send image message', e, stackTrace);
      return null;
    }
  }

  /// Optimize image for chat (reduce size and quality)
  Future<File?> _optimizeImage(File imageFile) async {
    try {
      AppLogger.debug(_tag, 'Optimizing image', {
        'originalSize': imageFile.lengthSync(),
      });

      // Read image
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) {
        AppLogger.error(_tag, 'Failed to decode image');
        return null;
      }

      // Resize if needed (max 1280x1280)
      final resized = image.width > 1280 || image.height > 1280
          ? img.copyResize(
              image,
              width: image.width > image.height ? 1280 : null,
              height: image.height > image.width ? 1280 : null,
            )
          : image;

      // Compress to JPEG with 80% quality
      final compressed = img.encodeJpg(resized, quality: 80);

      // Write to temporary file
      final tempDir = await Directory.systemTemp.createTemp('chat_image_');
      final tempFile = File('${tempDir.path}/optimized.jpg');
      await tempFile.writeAsBytes(compressed);

      AppLogger.info(_tag, 'Image optimized', {
        'originalSize': imageFile.lengthSync(),
        'optimizedSize': tempFile.lengthSync(),
        'reduction': '${((1 - tempFile.lengthSync() / imageFile.lengthSync()) * 100).toStringAsFixed(1)}%',
      });

      return tempFile;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to optimize image', e, stackTrace);
      return null;
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

      // Get unread messages (optimized: single where clause + client-side filter)
      final snapshot = await _messagesCollection
          .where('conversationId', isEqualTo: conversationId)
          .where('isRead', isEqualTo: false)
          .get();

      // Mark as read (filter out own messages on client side)
      final batch = _firestore.batch();
      final now = DateTime.now();

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['senderId'] != currentUserId) {
          batch.update(doc.reference, {
            'isRead': true,
            'readAt': Timestamp.fromDate(now),
          });
        }
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

  /// Create a group chat
  Future<ChatConversation?> createGroupChat({
    required String adminId,
    required String adminName,
    String? adminPhotoUrl,
    required List<String> participantIds,
    required Map<String, Map<String, dynamic>> participantData,
    required String groupName,
    String? groupPhotoUrl,
  }) async {
    try {
      AppLogger.debug(_tag, 'Creating group chat', {
        'adminId': adminId,
        'participantCount': participantIds.length,
        'groupName': groupName,
      });

      final now = DateTime.now();

      // Initialize unread count for all participants
      final unreadCount = <String, int>{};
      for (var id in participantIds) {
        unreadCount[id] = 0;
      }

      final conversationData = {
        'participantIds': participantIds,
        'participantData': participantData,
        'lastMessage': null,
        'lastMessageTime': null,
        'lastMessageSenderId': null,
        'unreadCount': unreadCount,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'isGroupChat': true,
        'groupName': groupName,
        'groupPhotoUrl': groupPhotoUrl,
        'adminId': adminId,
      };

      final docRef = await _conversationsCollection.add(conversationData);

      AppLogger.info(_tag, 'Group chat created successfully', {
        'conversationId': docRef.id,
        'participantCount': participantIds.length,
      });

      // Send system message
      await _sendSystemMessage(
        conversationId: docRef.id,
        text: '$adminName created the group',
      );

      return ChatConversation.fromFirestore(await docRef.get());
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to create group chat', e, stackTrace);
      return null;
    }
  }

  /// Send a system message (for group notifications)
  Future<void> _sendSystemMessage({
    required String conversationId,
    required String text,
  }) async {
    try {
      final now = DateTime.now();

      final message = ChatMessage(
        id: '',
        conversationId: conversationId,
        senderId: 'system',
        senderName: 'System',
        text: text,
        type: MessageType.system,
        sentAt: now,
      );

      await _messagesCollection.add(message.toFirestore());

      await _conversationsCollection.doc(conversationId).update({
        'lastMessage': text,
        'lastMessageTime': Timestamp.fromDate(now),
        'lastMessageSenderId': 'system',
        'updatedAt': Timestamp.fromDate(now),
      });

      AppLogger.debug(_tag, 'System message sent', {'text': text});
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to send system message', e, stackTrace);
    }
  }

  /// Add participants to group chat
  Future<bool> addParticipantsToGroup({
    required String conversationId,
    required String adminId,
    required String adminName,
    required List<String> newParticipantIds,
    required Map<String, Map<String, dynamic>> newParticipantData,
  }) async {
    try {
      AppLogger.debug(_tag, 'Adding participants to group', {
        'conversationId': conversationId,
        'newParticipantCount': newParticipantIds.length,
      });

      final doc = await _conversationsCollection.doc(conversationId).get();
      if (!doc.exists) {
        AppLogger.warning(_tag, 'Conversation not found');
        return false;
      }

      final conversation = ChatConversation.fromFirestore(doc);

      // Check if user is admin
      if (conversation.adminId != adminId) {
        AppLogger.warning(_tag, 'User is not admin');
        return false;
      }

      // Update participant lists
      final updatedParticipantIds = [...conversation.participantIds, ...newParticipantIds];
      final updatedParticipantData = {...conversation.participantData, ...newParticipantData};
      final updatedUnreadCount = {...conversation.unreadCount};

      // Initialize unread count for new participants
      for (var id in newParticipantIds) {
        updatedUnreadCount[id] = 0;
      }

      await _conversationsCollection.doc(conversationId).update({
        'participantIds': updatedParticipantIds,
        'participantData': updatedParticipantData,
        'unreadCount': updatedUnreadCount,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Send system message
      final names = newParticipantData.values.map((d) => d['name']).join(', ');
      await _sendSystemMessage(
        conversationId: conversationId,
        text: '$adminName added $names',
      );

      AppLogger.info(_tag, 'Participants added successfully');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to add participants', e, stackTrace);
      return false;
    }
  }

  /// Remove participant from group chat
  Future<bool> removeParticipantFromGroup({
    required String conversationId,
    required String adminId,
    required String adminName,
    required String participantIdToRemove,
    required String participantNameToRemove,
  }) async {
    try {
      AppLogger.debug(_tag, 'Removing participant from group', {
        'conversationId': conversationId,
        'participantId': participantIdToRemove,
      });

      final doc = await _conversationsCollection.doc(conversationId).get();
      if (!doc.exists) {
        AppLogger.warning(_tag, 'Conversation not found');
        return false;
      }

      final conversation = ChatConversation.fromFirestore(doc);

      // Check if user is admin
      if (conversation.adminId != adminId) {
        AppLogger.warning(_tag, 'User is not admin');
        return false;
      }

      // Update participant lists
      final updatedParticipantIds = conversation.participantIds
          .where((id) => id != participantIdToRemove)
          .toList();
      final updatedParticipantData = {...conversation.participantData};
      updatedParticipantData.remove(participantIdToRemove);
      final updatedUnreadCount = {...conversation.unreadCount};
      updatedUnreadCount.remove(participantIdToRemove);

      await _conversationsCollection.doc(conversationId).update({
        'participantIds': updatedParticipantIds,
        'participantData': updatedParticipantData,
        'unreadCount': updatedUnreadCount,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Send system message
      await _sendSystemMessage(
        conversationId: conversationId,
        text: '$adminName removed $participantNameToRemove',
      );

      AppLogger.info(_tag, 'Participant removed successfully');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to remove participant', e, stackTrace);
      return false;
    }
  }

  /// Leave group chat
  Future<bool> leaveGroupChat({
    required String conversationId,
    required String userId,
    required String userName,
  }) async {
    try {
      AppLogger.debug(_tag, 'User leaving group', {
        'conversationId': conversationId,
        'userId': userId,
      });

      final doc = await _conversationsCollection.doc(conversationId).get();
      if (!doc.exists) {
        AppLogger.warning(_tag, 'Conversation not found');
        return false;
      }

      final conversation = ChatConversation.fromFirestore(doc);

      // If user is admin and there are other participants, transfer admin rights
      if (conversation.adminId == userId && conversation.participantIds.length > 1) {
        final newAdminId = conversation.participantIds.firstWhere((id) => id != userId);
        await _conversationsCollection.doc(conversationId).update({
          'adminId': newAdminId,
        });
      }

      // Remove user from participant lists
      final updatedParticipantIds = conversation.participantIds
          .where((id) => id != userId)
          .toList();

      // If no participants left, delete conversation
      if (updatedParticipantIds.isEmpty) {
        await deleteConversation(conversationId);
        return true;
      }

      final updatedParticipantData = {...conversation.participantData};
      updatedParticipantData.remove(userId);
      final updatedUnreadCount = {...conversation.unreadCount};
      updatedUnreadCount.remove(userId);

      await _conversationsCollection.doc(conversationId).update({
        'participantIds': updatedParticipantIds,
        'participantData': updatedParticipantData,
        'unreadCount': updatedUnreadCount,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Send system message
      await _sendSystemMessage(
        conversationId: conversationId,
        text: '$userName left the group',
      );

      AppLogger.info(_tag, 'User left group successfully');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to leave group', e, stackTrace);
      return false;
    }
  }

  /// Update group chat info
  Future<bool> updateGroupInfo({
    required String conversationId,
    required String adminId,
    String? groupName,
    String? groupPhotoUrl,
  }) async {
    try {
      AppLogger.debug(_tag, 'Updating group info', {
        'conversationId': conversationId,
      });

      final doc = await _conversationsCollection.doc(conversationId).get();
      if (!doc.exists) {
        AppLogger.warning(_tag, 'Conversation not found');
        return false;
      }

      final conversation = ChatConversation.fromFirestore(doc);

      // Check if user is admin
      if (conversation.adminId != adminId) {
        AppLogger.warning(_tag, 'User is not admin');
        return false;
      }

      final updates = <String, dynamic>{
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (groupName != null) {
        updates['groupName'] = groupName;
      }

      if (groupPhotoUrl != null) {
        updates['groupPhotoUrl'] = groupPhotoUrl;
      }

      await _conversationsCollection.doc(conversationId).update(updates);

      AppLogger.info(_tag, 'Group info updated successfully');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to update group info', e, stackTrace);
      return false;
    }
  }
}

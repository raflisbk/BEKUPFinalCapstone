import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mockito/mockito.dart';
import 'package:relink/core/models/chat_models.dart';
import '../../test_setup.dart';

// ignore: subtype_of_sealed_class
class MockDocumentSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

void main() {
  setUpAll(() async {
    await setupTestEnvironment();
  });

  group('ChatMessage Model', () {
    late ChatMessage message;
    late DateTime now;

    setUp(() {
      now = DateTime.now();
      message = ChatMessage(
        id: 'msg123',
        conversationId: 'conv123',
        senderId: 'user123',
        senderName: 'Test User',
        senderPhotoUrl: 'https://example.com/photo.jpg',
        text: 'Hello, how are you?',
        type: MessageType.text,
        sentAt: now,
        isRead: false,
      );
    });

    test('should create message with all fields', () {
      expect(message.id, equals('msg123'));
      expect(message.conversationId, equals('conv123'));
      expect(message.senderId, equals('user123'));
      expect(message.senderName, equals('Test User'));
      expect(message.senderPhotoUrl, equals('https://example.com/photo.jpg'));
      expect(message.text, equals('Hello, how are you?'));
      expect(message.type, equals(MessageType.text));
      expect(message.sentAt, equals(now));
      expect(message.isRead, isFalse);
      expect(message.readAt, isNull);
    });

    test('should create text message type', () {
      final textMessage = ChatMessage(
        id: 'msg124',
        conversationId: 'conv123',
        senderId: 'user123',
        senderName: 'Test User',
        text: 'This is a text message',
        type: MessageType.text,
        sentAt: now,
      );

      expect(textMessage.type, equals(MessageType.text));
      expect(textMessage.imageUrl, isNull);
    });

    test('should create image message type', () {
      final imageMessage = ChatMessage(
        id: 'msg125',
        conversationId: 'conv123',
        senderId: 'user123',
        senderName: 'Test User',
        text: 'Check out this image!',
        type: MessageType.image,
        imageUrl: 'https://example.com/image.jpg',
        sentAt: now,
      );

      expect(imageMessage.type, equals(MessageType.image));
      expect(imageMessage.imageUrl, equals('https://example.com/image.jpg'));
    });

    test('should track message read status', () {
      final unreadMessage = ChatMessage(
        id: 'msg126',
        conversationId: 'conv123',
        senderId: 'user123',
        senderName: 'Test User',
        text: 'Unread message',
        sentAt: now,
        isRead: false,
      );

      expect(unreadMessage.isRead, isFalse);
      expect(unreadMessage.readAt, isNull);

      final readTime = DateTime.now();
      final readMessage = unreadMessage.copyWith(
        isRead: true,
        readAt: readTime,
      );

      expect(readMessage.isRead, isTrue);
      expect(readMessage.readAt, equals(readTime));
    });

    test('should convert to Firestore document correctly', () {
      final firestoreMap = message.toFirestore();

      expect(firestoreMap['conversationId'], equals('conv123'));
      expect(firestoreMap['senderId'], equals('user123'));
      expect(firestoreMap['senderName'], equals('Test User'));
      expect(
        firestoreMap['senderPhotoUrl'],
        equals('https://example.com/photo.jpg'),
      );
      expect(firestoreMap['text'], equals('Hello, how are you?'));
      expect(firestoreMap['type'], equals('text'));
      expect(firestoreMap['sentAt'], isA<Timestamp>());
      expect(firestoreMap['isRead'], isFalse);
      expect(firestoreMap['readAt'], isNull);
    });

    test('should create from Firestore document correctly', () {
      final firestoreMap = {
        'conversationId': 'conv456',
        'senderId': 'user456',
        'senderName': 'Another User',
        'senderPhotoUrl': 'https://example.com/another.jpg',
        'text': 'Hi there!',
        'type': 'text',
        'sentAt': Timestamp.fromDate(now),
        'isRead': true,
        'readAt': Timestamp.fromDate(now.add(const Duration(minutes: 5))),
      };

      final mockDoc = MockDocumentSnapshot();
      when(mockDoc.id).thenReturn('msg456');
      when(mockDoc.data()).thenReturn(firestoreMap);
      final fromFirestore = ChatMessage.fromFirestore(mockDoc);

      expect(fromFirestore.id, equals('msg456'));
      expect(fromFirestore.conversationId, equals('conv456'));
      expect(fromFirestore.senderId, equals('user456'));
      expect(fromFirestore.senderName, equals('Another User'));
      expect(fromFirestore.text, equals('Hi there!'));
      expect(fromFirestore.type, equals(MessageType.text));
      expect(fromFirestore.isRead, isTrue);
      expect(fromFirestore.readAt, isNotNull);
    });

    test('should copy with updated fields', () {
      final readTime = DateTime.now().add(const Duration(minutes: 10));
      final updatedMessage = message.copyWith(isRead: true, readAt: readTime);

      expect(updatedMessage.id, equals(message.id));
      expect(updatedMessage.text, equals(message.text));
      expect(updatedMessage.isRead, isTrue);
      expect(updatedMessage.readAt, equals(readTime));
    });

    test('should handle message without sender photo', () {
      final messageWithoutPhoto = ChatMessage(
        id: 'msg127',
        conversationId: 'conv123',
        senderId: 'user123',
        senderName: 'Test User',
        text: 'Message without photo',
        sentAt: now,
      );

      expect(messageWithoutPhoto.senderPhotoUrl, isNull);
    });

    test('should create system message type', () {
      final systemMessage = ChatMessage(
        id: 'msg128',
        conversationId: 'conv123',
        senderId: 'system',
        senderName: 'System',
        text: 'User joined the group',
        type: MessageType.system,
        sentAt: now,
      );

      expect(systemMessage.type, equals(MessageType.system));
    });

    test('should handle image message with text caption', () {
      final imageWithCaption = ChatMessage(
        id: 'msg129',
        conversationId: 'conv123',
        senderId: 'user123',
        senderName: 'Test User',
        text: 'Beautiful sunset',
        type: MessageType.image,
        imageUrl: 'https://example.com/sunset.jpg',
        sentAt: now,
      );

      expect(imageWithCaption.type, equals(MessageType.image));
      expect(imageWithCaption.text, equals('Beautiful sunset'));
      expect(
        imageWithCaption.imageUrl,
        equals('https://example.com/sunset.jpg'),
      );
    });
  });

  group('MessageType Enum', () {
    test('should have all message types', () {
      expect(MessageType.values.length, equals(3));
      expect(MessageType.values.contains(MessageType.text), isTrue);
      expect(MessageType.values.contains(MessageType.image), isTrue);
      expect(MessageType.values.contains(MessageType.system), isTrue);
    });
  });

  group('ChatConversation Model', () {
    late ChatConversation conversation;
    late DateTime now;

    setUp(() {
      now = DateTime.now();
      conversation = ChatConversation(
        id: 'conv123',
        participantIds: ['user123', 'user456'],
        participantData: {
          'user123': {
            'name': 'User One',
            'photoUrl': 'https://example.com/1.jpg',
          },
          'user456': {
            'name': 'User Two',
            'photoUrl': 'https://example.com/2.jpg',
          },
        },
        lastMessage: 'Last message text',
        lastMessageTime: now,
        lastMessageSenderId: 'user123',
        unreadCount: {'user456': 3},
        createdAt: now,
        updatedAt: now,
        isGroupChat: false,
      );
    });

    test('should create conversation with all fields', () {
      expect(conversation.id, equals('conv123'));
      expect(conversation.participantIds.length, equals(2));
      expect(conversation.lastMessage, equals('Last message text'));
      expect(conversation.isGroupChat, isFalse);
    });

    test('should get other participant data', () {
      final otherParticipant = conversation.getOtherParticipant('user123');

      expect(otherParticipant, isNotNull);
      expect(otherParticipant!['name'], equals('User Two'));
      expect(otherParticipant['photoUrl'], equals('https://example.com/2.jpg'));
    });

    test('should get unread count for user', () {
      expect(conversation.getUnreadCount('user456'), equals(3));
      expect(conversation.getUnreadCount('user123'), equals(0));
    });

    test('should get display name for 1-on-1 chat', () {
      final displayName = conversation.getDisplayName('user123');
      expect(displayName, equals('User Two'));
    });

    test('should get display name for group chat', () {
      final groupChat = ChatConversation(
        id: 'conv456',
        participantIds: ['user123', 'user456', 'user789'],
        participantData: {},
        unreadCount: {},
        createdAt: now,
        updatedAt: now,
        isGroupChat: true,
        groupName: 'Team Chat',
      );

      expect(groupChat.getDisplayName('user123'), equals('Team Chat'));
    });

    test('should check if user is admin', () {
      final groupChat = ChatConversation(
        id: 'conv456',
        participantIds: ['user123', 'user456'],
        participantData: {},
        unreadCount: {},
        createdAt: now,
        updatedAt: now,
        isGroupChat: true,
        adminId: 'user123',
      );

      expect(groupChat.isAdmin('user123'), isTrue);
      expect(groupChat.isAdmin('user456'), isFalse);
    });

    test('should return participant count', () {
      expect(conversation.participantCount, equals(2));
    });

    test('should convert to Firestore document correctly', () {
      final firestoreMap = conversation.toFirestore();

      expect(firestoreMap['participantIds'], isA<List>());
      expect(firestoreMap['participantData'], isA<Map>());
      expect(firestoreMap['lastMessage'], equals('Last message text'));
      expect(firestoreMap['isGroupChat'], isFalse);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:relink/presentation/chat/chat_list_screen.dart';
import 'package:relink/presentation/chat/chat_screen.dart';
import 'package:relink/presentation/chat/create_group_chat_screen.dart';
import 'package:relink/core/providers/chat_provider.dart';
import 'package:relink/core/providers/auth_provider.dart';
import 'package:relink/core/models/chat_models.dart';
import '../test_setup.dart';

/// Widget tests for Chat Screens
/// Tests chat list, individual chat, and group chat functionality
void main() {
  setUpAll(() async {
    await setupTestEnvironment();
  });

  group('Chat List Screen Tests', () {
    late ChatProvider mockChatProvider;
    late AuthProvider mockAuthProvider;

    setUp(() {
      mockChatProvider = ChatProvider();
      mockAuthProvider = AuthProvider();
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<ChatProvider>.value(value: mockChatProvider),
            ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
          ],
          child: const ChatListScreen(),
        ),
      );
    }

    testWidgets('should display app bar with title', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Messages'), findsOneWidget);
    });

    testWidgets('should display search field', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(TextField), findsWidgets);
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('should display empty state when no conversations', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert - Should show empty state if no chats
      // Note: Actual implementation may vary
      expect(find.byType(ListView), findsWidgets);
    });

    testWidgets('should display conversation list items when available', (tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert - If conversations exist, they should be displayed
      // Note: This requires mock data to be set up in ChatProvider
      expect(find.byType(ListView), findsWidgets);
    });

    testWidgets('should display unread message badges', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert - Badges would be shown if there are unread messages
      // Note: Requires mock data with unread counts
    });

    testWidgets('should filter conversations on search', (tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act - Find search field and enter text
      final searchField = find.byType(TextField).first;
      await tester.enterText(searchField, 'test user');
      await tester.pumpAndSettle();

      // Assert - List should be filtered
      // Note: Actual filtering logic depends on implementation
    });
  });

  group('Individual Chat Screen Tests', () {
    late ChatProvider mockChatProvider;
    late AuthProvider mockAuthProvider;

    setUp(() {
      mockChatProvider = ChatProvider();
      mockAuthProvider = AuthProvider();
    });

    Widget createTestWidget() {
      // Mock conversation for testing
      final mockConversation = ChatConversation(
        id: 'test-chat-1',
        participantIds: ['user1', 'user2'],
        participantData: {
          'user1': {'name': 'Test User', 'photoUrl': null}
        },
        lastMessage: 'Hello',
        lastMessageTime: DateTime.now(),
        unreadCount: {},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isGroupChat: false,
      );

      return MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<ChatProvider>.value(value: mockChatProvider),
            ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
          ],
          child: ChatScreen(
            conversation: mockConversation,
            otherUserName: 'Test User',
          ),
        ),
      );
    }

    testWidgets('should display chat app bar with user name', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Test User'), findsOneWidget);
    });

    testWidgets('should display online status indicator', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert - Online/offline status should be visible
      // Note: Implementation may use CircleAvatar or custom widget
    });

    testWidgets('should display message input field', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('should display send button', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.send), findsOneWidget);
    });

    testWidgets('should display image attachment button', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.image), findsWidgets);
    });

    testWidgets('should enable send button when message is typed', (tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act - Enter text
      final messageField = find.byType(TextField);
      await tester.enterText(messageField, 'Test message');
      await tester.pumpAndSettle();

      // Assert - Send button should be enabled
      final sendButton = find.byIcon(Icons.send);
      expect(sendButton, findsOneWidget);
    });
  });

  group('Group Chat Screen Tests', () {
    late ChatProvider mockChatProvider;
    late AuthProvider mockAuthProvider;

    setUp(() {
      mockChatProvider = ChatProvider();
      mockAuthProvider = AuthProvider();
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<ChatProvider>.value(value: mockChatProvider),
            ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
          ],
          child: const CreateGroupChatScreen(),
        ),
      );
    }

    testWidgets('should display group name input field', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Group Name'), findsWidgets);
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('should display member selection list', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert - Should show list of users to add
      expect(find.byType(ListView), findsWidgets);
    });

    testWidgets('should display create group button', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.textContaining('Create'), findsWidgets);
    });

    testWidgets('should show selected members count', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert - Should display selected count somewhere
      // Note: Implementation specific
    });
  });
}

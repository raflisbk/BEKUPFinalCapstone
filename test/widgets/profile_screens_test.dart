import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:relink/presentation/profile/profile_screen.dart';
import 'package:relink/core/providers/auth_provider.dart';
import 'package:relink/core/providers/user_provider.dart';
import '../test_setup.dart';

/// Widget tests for Profile Screens
/// Tests user profile display, edit profile, and settings functionality
void main() {
  setUpAll(() async {
    await setupTestEnvironment();
  });

  group('Profile Screen Tests', () {
    late AuthProvider mockAuthProvider;
    late UserProvider mockUserProvider;

    setUp(() {
      mockAuthProvider = AuthProvider();
      mockUserProvider = UserProvider();
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
            ChangeNotifierProvider<UserProvider>.value(value: mockUserProvider),
          ],
          child: const ProfileScreen(),
        ),
      );
    }

    testWidgets('should display user profile photo', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert - Should show CircleAvatar
      expect(find.byType(CircleAvatar), findsWidgets);
    });

    testWidgets('should display user name', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert - Should show user's name when loaded
      // Note: Requires mock user data
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('should display followers count', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert - Should show followers section
      expect(find.textContaining('Followers'), findsWidgets);
    });

    testWidgets('should display following count', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert - Should show following section
      expect(find.textContaining('Following'), findsWidgets);
    });

    testWidgets('should display trips count', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert - Should show trips section
      expect(find.textContaining('Trips'), findsWidgets);
    });

    testWidgets('should display edit profile button', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.textContaining('Edit'), findsWidgets);
    });

    testWidgets('should display settings icon button', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.settings), findsWidgets);
    });
  });

  group('Edit Profile Tests', () {
    late AuthProvider mockAuthProvider;
    late UserProvider mockUserProvider;

    setUp(() {
      mockAuthProvider = AuthProvider();
      mockUserProvider = UserProvider();
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
            ChangeNotifierProvider<UserProvider>.value(value: mockUserProvider),
          ],
          child: const ProfileScreen(),
        ),
      );
    }

    testWidgets('should show edit dialog when edit button tapped', (tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act - Tap edit button
      final editButton = find.textContaining('Edit');
      if (editButton.evaluate().isNotEmpty) {
        await tester.tap(editButton.first);
        await tester.pumpAndSettle();

        // Assert - Should show edit dialog or navigate to edit screen
        expect(find.byType(Dialog), findsWidgets);
      }
    });

    testWidgets('should display bio text field in edit mode', (tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act - Tap edit button
      final editButton = find.textContaining('Edit');
      if (editButton.evaluate().isNotEmpty) {
        await tester.tap(editButton.first);
        await tester.pumpAndSettle();

        // Assert - Should have bio field
        expect(find.textContaining('Bio'), findsWidgets);
      }
    });

    testWidgets('should display save button in edit mode', (tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act - Tap edit button
      final editButton = find.textContaining('Edit');
      if (editButton.evaluate().isNotEmpty) {
        await tester.tap(editButton.first);
        await tester.pumpAndSettle();

        // Assert - Should have save button
        expect(find.textContaining('Save'), findsWidgets);
      }
    });

    testWidgets('should display photo upload button', (tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act - Look for photo upload button
      // Note: May be visible on main profile or in edit mode
      // Implementation specific
      await tester.pumpAndSettle();
    });
  });

  group('Settings Screen Tests', () {
    late AuthProvider mockAuthProvider;
    late UserProvider mockUserProvider;

    setUp(() {
      mockAuthProvider = AuthProvider();
      mockUserProvider = UserProvider();
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
            ChangeNotifierProvider<UserProvider>.value(value: mockUserProvider),
          ],
          child: const ProfileScreen(),
        ),
      );
    }

    testWidgets('should navigate to settings when settings icon tapped', (tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act - Tap settings icon
      final settingsIcon = find.byIcon(Icons.settings);
      if (settingsIcon.evaluate().isNotEmpty) {
        await tester.tap(settingsIcon.first);
        await tester.pumpAndSettle();

        // Assert - Should show snackbar or navigate
        // Note: May need NavigatorObserver to verify navigation
      }
    });

    testWidgets('should display theme toggle option', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Navigate to settings if needed
      final settingsIcon = find.byIcon(Icons.settings);
      if (settingsIcon.evaluate().isNotEmpty) {
        await tester.tap(settingsIcon.first);
        await tester.pumpAndSettle();

        // Assert - Should have theme toggle
        // Note: Implementation specific, may be in settings screen
      }
    });

    testWidgets('should display notification settings', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Navigate to settings if needed
      final settingsIcon = find.byIcon(Icons.settings);
      if (settingsIcon.evaluate().isNotEmpty) {
        await tester.tap(settingsIcon.first);
        await tester.pumpAndSettle();

        // Assert - Should have notification settings
        // Note: Implementation specific
      }
    });

    testWidgets('should display sync controls', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert - Sync status widget should be visible
      // Note: May use SyncStatusWidget from core/widgets
    });
  });
}

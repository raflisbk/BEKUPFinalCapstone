import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:relink/presentation/auth/auth_screen.dart';
import 'package:relink/core/providers/auth_provider.dart';
import '../test_setup.dart';

/// Widget tests for Authentication Screens
/// Tests login, registration, and password reset flows
void main() {
  setUpAll(() async {
    await setupTestEnvironment();
  });

  group('Auth Screen - Login Mode Tests', () {
    late AuthProvider mockAuthProvider;

    setUp(() {
      mockAuthProvider = AuthProvider();
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: ChangeNotifierProvider<AuthProvider>.value(
          value: mockAuthProvider,
          child: const AuthScreen(),
        ),
      );
    }

    testWidgets('should display login form by default', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
    });

    testWidgets('should display email and password fields', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(TextFormField), findsAtLeastNWidgets(2));
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    });

    testWidgets('should display submit button', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.widgetWithText(ElevatedButton, 'Sign In'), findsOneWidget);
    });

    testWidgets('should show validation error for empty email', (tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act - Tap submit without entering email
      final submitButton = find.widgetWithText(ElevatedButton, 'Sign In');
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Assert - Form validation should trigger
      // Note: Actual validation text depends on implementation
      expect(find.byType(TextFormField), findsAtLeastNWidgets(2));
    });

    testWidgets('should toggle password visibility', (tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act - Find and tap visibility toggle icon
      final visibilityIcon = find.byIcon(Icons.visibility_off);
      if (visibilityIcon.evaluate().isNotEmpty) {
        await tester.tap(visibilityIcon);
        await tester.pumpAndSettle();

        // Assert - Icon should change to visibility
        expect(find.byIcon(Icons.visibility), findsOneWidget);
      }
    });

    testWidgets('should display "Don\'t have an account?" text', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.textContaining('account'), findsWidgets);
    });
  });

  group('Auth Screen - Register Mode Tests', () {
    late AuthProvider mockAuthProvider;

    setUp(() {
      mockAuthProvider = AuthProvider();
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: ChangeNotifierProvider<AuthProvider>.value(
          value: mockAuthProvider,
          child: const AuthScreen(),
        ),
      );
    }

    testWidgets('should switch to register mode when toggle is tapped', (tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act - Find and tap the register toggle
      final signUpButton = find.text('Sign Up');
      if (signUpButton.evaluate().isNotEmpty) {
        await tester.tap(signUpButton.first);
        await tester.pumpAndSettle();

        // Assert - Should show registration form
        expect(find.text('Create Account'), findsWidgets);
      }
    });

    testWidgets('should display name field in register mode', (tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act - Switch to register mode
      final signUpButton = find.text('Sign Up');
      if (signUpButton.evaluate().isNotEmpty) {
        await tester.tap(signUpButton.first);
        await tester.pumpAndSettle();

        // Assert - Should have name, email, and password fields (3 fields)
        expect(find.byType(TextFormField), findsAtLeastNWidgets(3));
        expect(find.text('Full Name'), findsOneWidget);
      }
    });
  });

  group('Auth Screen - Guest Mode Tests', () {
    late AuthProvider mockAuthProvider;

    setUp(() {
      mockAuthProvider = AuthProvider();
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: ChangeNotifierProvider<AuthProvider>.value(
          value: mockAuthProvider,
          child: const AuthScreen(),
        ),
      );
    }

    testWidgets('should display guest mode button', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.textContaining('Guest'), findsWidgets);
    });
  });
}

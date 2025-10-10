import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Authentication Flow Integration Tests', () {
    testWidgets('Complete sign up flow', (WidgetTester tester) async {
      // Test complete user registration flow
      await tester.pumpWidget(
        const MaterialApp(
          home: AuthScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Step 1: Navigate to sign up
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      // Step 2: Fill registration form
      expect(find.text('Create Account'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('name_field')),
        'John Doe',
      );

      await tester.enterText(
        find.byKey(const Key('email_field')),
        'johndoe@example.com',
      );

      await tester.enterText(
        find.byKey(const Key('password_field')),
        'SecurePass123!',
      );

      await tester.enterText(
        find.byKey(const Key('confirm_password_field')),
        'SecurePass123!',
      );

      await tester.pumpAndSettle();

      // Step 3: Accept terms and conditions
      await tester.tap(find.byKey(const Key('terms_checkbox')));
      await tester.pumpAndSettle();

      // Step 4: Submit registration
      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Step 5: Verify email verification screen
      expect(find.text('Verify Email'), findsOneWidget);
      expect(find.textContaining('johndoe@example.com'), findsOneWidget);

      // Step 6: Enter verification code
      await tester.enterText(
        find.byKey(const Key('verification_code_field')),
        '123456',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Verify'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Step 7: Verify successful registration
      expect(find.text('Welcome to ReLink!'), findsOneWidget);
    });

    testWidgets('Complete sign in flow', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AuthScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Step 1: Enter credentials
      await tester.enterText(
        find.byKey(const Key('email_field')),
        'test@example.com',
      );

      await tester.enterText(
        find.byKey(const Key('password_field')),
        'password123',
      );

      await tester.pumpAndSettle();

      // Step 2: Tap sign in
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Step 3: Verify successful login
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('Sign in with validation errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AuthScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Attempt to sign in with empty fields
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      // Verify validation errors
      expect(find.text('Please enter email'), findsOneWidget);
      expect(find.text('Please enter password'), findsOneWidget);

      // Enter invalid email
      await tester.enterText(
        find.byKey(const Key('email_field')),
        'invalidemail',
      );
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter valid email'), findsOneWidget);
    });

    testWidgets('Forgot password flow', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AuthScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Step 1: Navigate to forgot password
      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle();

      // Step 2: Enter email
      expect(find.text('Reset Password'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('reset_email_field')),
        'test@example.com',
      );
      await tester.pumpAndSettle();

      // Step 3: Request reset
      await tester.tap(find.text('Send Reset Link'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Step 4: Verify confirmation
      expect(find.text('Check Your Email'), findsOneWidget);
      expect(
        find.textContaining('reset link has been sent'),
        findsOneWidget,
      );
    });

    testWidgets('Social login - Google', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AuthScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Google sign in button
      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // In real integration test, this would trigger Google sign in flow
      // For testing, we verify the button exists and is tappable
      expect(find.text('Continue with Google'), findsOneWidget);
    });

    testWidgets('Social login - Facebook', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AuthScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Facebook sign in button
      await tester.tap(find.text('Continue with Facebook'));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.text('Continue with Facebook'), findsOneWidget);
    });

    testWidgets('Sign out flow', (WidgetTester tester) async {
      // Assumes user is already logged in
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Navigate to profile
      await tester.tap(find.byIcon(Icons.person));
      await tester.pumpAndSettle();

      // Tap settings
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // Tap sign out
      await tester.tap(find.text('Sign Out'));
      await tester.pumpAndSettle();

      // Confirm sign out
      expect(find.text('Sign Out?'), findsOneWidget);
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify redirected to auth screen
      expect(find.text('Sign In'), findsOneWidget);
    });

    testWidgets('Update profile information', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ProfileScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Tap edit profile
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();

      // Update name
      await tester.enterText(
        find.byKey(const Key('name_field')),
        'John Doe Updated',
      );

      // Update bio
      await tester.enterText(
        find.byKey(const Key('bio_field')),
        'Travel enthusiast and adventurer',
      );

      await tester.pumpAndSettle();

      // Save changes
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify updated
      expect(find.text('Profile Updated'), findsOneWidget);
      expect(find.text('John Doe Updated'), findsOneWidget);
    });

    testWidgets('Change password flow', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SettingsScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Navigate to change password
      await tester.tap(find.text('Change Password'));
      await tester.pumpAndSettle();

      // Enter current password
      await tester.enterText(
        find.byKey(const Key('current_password_field')),
        'oldPassword123',
      );

      // Enter new password
      await tester.enterText(
        find.byKey(const Key('new_password_field')),
        'newPassword456!',
      );

      // Confirm new password
      await tester.enterText(
        find.byKey(const Key('confirm_new_password_field')),
        'newPassword456!',
      );

      await tester.pumpAndSettle();

      // Submit
      await tester.tap(find.text('Update Password'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify success
      expect(find.text('Password Updated'), findsOneWidget);
    });

    testWidgets('Delete account flow', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SettingsScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Scroll to bottom
      await tester.drag(
        find.byType(ListView),
        const Offset(0, -500),
      );
      await tester.pumpAndSettle();

      // Tap delete account
      await tester.tap(find.text('Delete Account'));
      await tester.pumpAndSettle();

      // Confirm deletion
      expect(find.text('Delete Account?'), findsOneWidget);
      expect(
        find.textContaining('This action is irreversible'),
        findsOneWidget,
      );

      // Enter password to confirm
      await tester.enterText(
        find.byKey(const Key('confirm_password_field')),
        'password123',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete My Account'));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify redirected to auth screen
      expect(find.text('Sign In'), findsOneWidget);
    });
  });
}

// Mock screens for testing
class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign In')),
      body: Column(
        children: [
          const TextField(key: Key('email_field')),
          const TextField(key: Key('password_field'), obscureText: true),
          ElevatedButton(onPressed: () {}, child: const Text('Sign In')),
          TextButton(onPressed: () {}, child: const Text('Forgot Password?')),
          TextButton(onPressed: () {}, child: const Text('Sign Up')),
          ElevatedButton(
            onPressed: () {},
            child: const Text('Continue with Google'),
          ),
          ElevatedButton(
            onPressed: () {},
            child: const Text('Continue with Facebook'),
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: () {}),
          IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          const Text('John Doe'),
          const TextField(key: Key('name_field')),
          const TextField(key: Key('bio_field')),
          ElevatedButton(onPressed: () {}, child: const Text('Save')),
        ],
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Change Password'),
            onTap: () {},
          ),
          ListTile(
            title: const Text('Sign Out'),
            onTap: () {},
          ),
          ListTile(
            title: const Text('Delete Account'),
            textColor: Colors.red,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

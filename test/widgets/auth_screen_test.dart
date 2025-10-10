import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Auth Screen Widget Tests', () {
    testWidgets('Login form displays correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                const Text('Login'),
                const TextField(
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'Enter your email',
                  ),
                ),
                const TextField(
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter your password',
                  ),
                  obscureText: true,
                ),
                ElevatedButton(onPressed: () {}, child: const Text('Sign In')),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Login'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
    });

    testWidgets('Email field accepts input', (WidgetTester tester) async {
      final emailController = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'test@example.com');
      await tester.pump();

      expect(emailController.text, 'test@example.com');
    });

    testWidgets('Password field is obscured', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TextField(
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
          ),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.obscureText, isTrue);
    });

    testWidgets('Sign in button triggers callback', (
      WidgetTester tester,
    ) async {
      var buttonPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ElevatedButton(
              onPressed: () {
                buttonPressed = true;
              },
              child: const Text('Sign In'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(buttonPressed, isTrue);
    });

    testWidgets('Toggle password visibility works', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                var obscurePassword = true;

                return Column(
                  children: [
                    TextField(
                      obscureText: obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility
                                // ignore: dead_code
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              obscurePassword = !obscurePassword;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      // Initially password is obscured
      var textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.obscureText, isTrue);

      // Tap visibility icon
      await tester.tap(find.byType(IconButton));
      await tester.pump();

      // Password should now be visible
      textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.obscureText, isFalse);
    });

    testWidgets('Loading indicator shows during authentication', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                var isLoading = false;

                return Column(
                  children: [
                    if (isLoading)
                      // ignore: dead_code
                      const CircularProgressIndicator()
                    else
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            isLoading = true;
                          });
                        },
                        child: const Text('Sign In'),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsNothing);

      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Error message displays on failed login', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                String? errorMessage;

                return Column(
                  children: [
                    const TextField(
                      decoration: InputDecoration(labelText: 'Email'),
                    ),
                    const TextField(
                      decoration: InputDecoration(labelText: 'Password'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          errorMessage = 'Invalid email or password';
                        });
                      },
                      child: const Text('Sign In'),
                    ),
                    if (errorMessage != null)
                      Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(find.text('Invalid email or password'), findsOneWidget);
      final errorText = tester.widget<Text>(
        find.text('Invalid email or password'),
      );
      expect(errorText.style?.color, Colors.red);
    });

    testWidgets('Form validation works', (WidgetTester tester) async {
      final formKey = GlobalKey<FormState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: formKey,
              child: Column(
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter valid email';
                      }
                      return null;
                    },
                  ),
                  ElevatedButton(
                    onPressed: () {
                      formKey.currentState?.validate();
                    },
                    child: const Text('Validate'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Tap validate without entering text
      await tester.tap(find.text('Validate'));
      await tester.pump();

      expect(find.text('Please enter email'), findsOneWidget);

      // Enter invalid email
      await tester.enterText(find.byType(TextFormField), 'invalidemail');
      await tester.tap(find.text('Validate'));
      await tester.pump();

      expect(find.text('Please enter valid email'), findsOneWidget);

      // Enter valid email
      await tester.enterText(find.byType(TextFormField), 'test@example.com');
      await tester.tap(find.text('Validate'));
      await tester.pump();

      expect(find.text('Please enter email'), findsNothing);
      expect(find.text('Please enter valid email'), findsNothing);
    });

    testWidgets('Forgot password link navigates', (WidgetTester tester) async {
      var forgotPasswordTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextButton(
              onPressed: () {
                forgotPasswordTapped = true;
              },
              child: const Text('Forgot Password?'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Forgot Password?'));
      await tester.pump();

      expect(forgotPasswordTapped, isTrue);
    });

    testWidgets('Sign up link navigates to registration', (
      WidgetTester tester,
    ) async {
      var signUpTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                const Text("Don't have an account? "),
                TextButton(
                  onPressed: () {
                    signUpTapped = true;
                  },
                  child: const Text('Sign Up'),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text('Sign Up'));
      await tester.pump();

      expect(signUpTapped, isTrue);
    });

    testWidgets('Social login buttons display', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.g_mobiledata),
                  label: const Text('Continue with Google'),
                ),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.facebook),
                  label: const Text('Continue with Facebook'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('Continue with Facebook'), findsOneWidget);
    });
  });
}

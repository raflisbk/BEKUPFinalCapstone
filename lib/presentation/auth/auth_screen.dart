import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/logger.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/auth_ui_provider.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  static const String _tag = 'AuthScreen';

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final authUIProvider = Provider.of<AuthUIProvider>(context, listen: false);
    AppLogger.debug(_tag, 'Auth screen initialized', {
      'mode': authUIProvider.isLogin ? 'login' : 'signup',
    });
  }

  void _toggleAuthMode(BuildContext context) {
    final authUIProvider = Provider.of<AuthUIProvider>(context, listen: false);
    authUIProvider.toggleAuthMode();
    // Clear form when switching modes
    _formKey.currentState?.reset();
    AppLogger.action('User toggled auth mode', {
      'newMode': authUIProvider.isLogin ? 'login' : 'signup',
    });
  }

  Future<void> _handleGuestMode(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    AppLogger.action('User selected guest mode');

    final success = await authProvider.signInAsGuest();

    if (!mounted) return;

    if (success) {
      AppLogger.navigation(_tag, '/main', {'mode': 'guest'});
      navigator.pushReplacementNamed('/main');
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            authProvider.errorMessage ?? 'Failed to continue as guest',
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handleAuth(BuildContext context) async {
    if (!_formKey.currentState!.validate()) {
      AppLogger.warning(_tag, 'Form validation failed');
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final authUIProvider = Provider.of<AuthUIProvider>(context, listen: false);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final mode = authUIProvider.isLogin ? 'login' : 'signup';
    AppLogger.action('User tapped $mode button');

    bool success;

    if (authUIProvider.isLogin) {
      success = await authProvider.signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } else {
      success = await authProvider.registerWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
      );
    }

    if (!mounted) return;

    if (success) {
      AppLogger.info(_tag, 'Navigating to main screen after $mode');
      AppLogger.navigation(_tag, '/main', {'authMode': mode});
      navigator.pushReplacementNamed('/main');
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            authProvider.errorMessage ?? 'Authentication failed',
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handleGoogleSignIn(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    AppLogger.action('User tapped Google Sign-In button');

    final success = await authProvider.signInWithGoogle();

    if (!mounted) return;

    if (success) {
      AppLogger.navigation(_tag, '/main', {'authMode': 'google'});
      navigator.pushReplacementNamed('/main');
    } else if (authProvider.errorMessage != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage!),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handleForgotPassword(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    AppLogger.action('User tapped forgot password');

    if (_emailController.text.trim().isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Please enter your email address first'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.resetPassword(
      _emailController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Password reset email sent. Check your inbox.'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (authProvider.errorMessage != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage!),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  @override
  void dispose() {
    AppLogger.debug(_tag, 'Disposing auth screen resources');
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, AuthUIProvider>(
      builder: (context, authProvider, authUIProvider, child) {
        return Scaffold(
          backgroundColor: AppColors.white,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 60),

                    // Logo
                    FadeInDown(
                      duration: const Duration(milliseconds: 600),
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.black,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Text(
                            'R',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: AppColors.white,
                              letterSpacing: -1,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Title
                    FadeInDown(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 100),
                      child: Text(
                        authUIProvider.isLogin
                            ? 'Welcome\nback'
                            : 'Create\naccount',
                        style: AppTextStyles.displaySmall.copyWith(
                          fontSize: 48,
                          height: 1.1,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Subtitle
                    FadeInDown(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 200),
                      child: Text(
                        authUIProvider.isLogin
                            ? 'Sign in to continue your journey'
                            : 'Start your travel adventure today',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),

                    const SizedBox(height: 60),

                    // Guest Mode Button
                    FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 300),
                      child: _GuestModeCard(
                        onTap: authProvider.isLoading
                            ? () {}
                            : () => _handleGuestMode(context),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Divider
                    FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 400),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Divider(color: AppColors.divider),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            child: Text(
                              'or continue with',
                              style: AppTextStyles.labelMedium.copyWith(
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ),
                          const Expanded(
                            child: Divider(color: AppColors.divider),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Name Field (Register only)
                    if (!authUIProvider.isLogin) ...[
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 500),
                        child: TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                            hintText: 'Enter your full name',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: _validateName,
                          enabled: !authProvider.isLoading,
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Email Field
                    FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      delay: Duration(
                        milliseconds: authUIProvider.isLogin ? 500 : 600,
                      ),
                      child: TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          hintText: 'Enter your email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: _validateEmail,
                        enabled: !authProvider.isLoading,
                        textInputAction: TextInputAction.next,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Password Field
                    FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      delay: Duration(
                        milliseconds: authUIProvider.isLogin ? 600 : 700,
                      ),
                      child: TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          hintText: 'Enter your password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              authUIProvider.isPasswordVisible
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: authProvider.isLoading
                                ? null
                                : authUIProvider.togglePasswordVisibility,
                          ),
                        ),
                        obscureText: !authUIProvider.isPasswordVisible,
                        validator: _validatePassword,
                        enabled: !authProvider.isLoading,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _handleAuth(context),
                      ),
                    ),

                    if (authUIProvider.isLogin) ...[
                      const SizedBox(height: 16),
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 700),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: authProvider.isLoading
                                ? null
                                : () => _handleForgotPassword(context),
                            child: const Text('Forgot password?'),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),

                    // Sign In/Up Button
                    FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      delay: Duration(
                        milliseconds: authUIProvider.isLogin ? 800 : 800,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: authProvider.isLoading
                              ? null
                              : () => _handleAuth(context),
                          child: authProvider.isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  authUIProvider.isLogin
                                      ? 'Sign In'
                                      : 'Create Account',
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Google Sign In
                    FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      delay: Duration(
                        milliseconds: authUIProvider.isLogin ? 900 : 900,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton.icon(
                          onPressed: authProvider.isLoading
                              ? null
                              : () => _handleGoogleSignIn(context),
                          icon: const Icon(Icons.g_mobiledata, size: 28),
                          label: const Text('Continue with Google'),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Toggle Login/Signup
                    FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      delay: Duration(
                        milliseconds: authUIProvider.isLogin ? 1000 : 1000,
                      ),
                      child: Center(
                        child: TextButton(
                          onPressed: authProvider.isLoading
                              ? null
                              : () => _toggleAuthMode(context),
                          child: RichText(
                            text: TextSpan(
                              text: authUIProvider.isLogin
                                  ? "Don't have an account? "
                                  : "Already have an account? ",
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              children: [
                                TextSpan(
                                  text: authUIProvider.isLogin
                                      ? 'Sign Up'
                                      : 'Sign In',
                                  style: const TextStyle(
                                    color: AppColors.black,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GuestModeCard extends StatelessWidget {
  final VoidCallback onTap;

  const _GuestModeCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.grey50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.person_outline,
                color: AppColors.black,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Continue as Guest',
                    style: AppTextStyles.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Explore without an account',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

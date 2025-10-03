import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/logger.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  static const String _tag = 'AuthScreen';
  bool _isLogin = true;

  @override
  void initState() {
    super.initState();
    AppLogger.debug(_tag, 'Auth screen initialized', {'mode': _isLogin ? 'login' : 'signup'});
  }

  void _toggleAuthMode() {
    setState(() {
      _isLogin = !_isLogin;
    });
    AppLogger.action('User toggled auth mode', {'newMode': _isLogin ? 'login' : 'signup'});
  }

  void _handleGuestMode(BuildContext context) {
    AppLogger.action('User selected guest mode');
    AppLogger.navigation(_tag, '/main', {'mode': 'guest'});
    Navigator.pushReplacementNamed(context, '/main');
  }

  void _handleAuth(BuildContext context) {
    final mode = _isLogin ? 'login' : 'signup';
    AppLogger.action('User tapped $mode button');
    // TODO: Implement actual authentication logic
    AppLogger.info(_tag, 'Navigating to main screen after $mode');
    AppLogger.navigation(_tag, '/main', {'authMode': mode});
    Navigator.pushReplacementNamed(context, '/main');
  }

  void _handleGoogleSignIn() {
    AppLogger.action('User tapped Google Sign-In button');
    // TODO: Implement Google Sign-In logic
    AppLogger.warning(_tag, 'Google Sign-In not implemented yet');
  }

  void _handleForgotPassword() {
    AppLogger.action('User tapped forgot password');
    // TODO: Implement forgot password logic
    AppLogger.warning(_tag, 'Forgot password not implemented yet');
  }

  @override
  void dispose() {
    AppLogger.debug(_tag, 'Disposing auth screen resources');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
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
                    _isLogin ? 'Welcome\nback' : 'Create\naccount',
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
                    _isLogin
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
                    onTap: () => _handleGuestMode(context),
                  ),
                ),

                const SizedBox(height: 32),

                // Divider
                FadeInUp(
                  duration: const Duration(milliseconds: 600),
                  delay: const Duration(milliseconds: 400),
                  child: Row(
                    children: [
                      const Expanded(child: Divider(color: AppColors.divider)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          'or continue with',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider(color: AppColors.divider)),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Email Field
                if (!_isLogin) ...[
                  FadeInUp(
                    duration: const Duration(milliseconds: 600),
                    delay: const Duration(milliseconds: 500),
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        hintText: 'Enter your full name',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                FadeInUp(
                  duration: const Duration(milliseconds: 600),
                  delay: Duration(milliseconds: _isLogin ? 500 : 600),
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'Enter your email',
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                ),

                const SizedBox(height: 16),

                // Password Field
                FadeInUp(
                  duration: const Duration(milliseconds: 600),
                  delay: Duration(milliseconds: _isLogin ? 600 : 700),
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      hintText: 'Enter your password',
                    ),
                    obscureText: true,
                  ),
                ),

                if (_isLogin) ...[
                  const SizedBox(height: 16),
                  FadeInUp(
                    duration: const Duration(milliseconds: 600),
                    delay: const Duration(milliseconds: 700),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _handleForgotPassword,
                        child: const Text('Forgot password?'),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // Sign In/Up Button
                FadeInUp(
                  duration: const Duration(milliseconds: 600),
                  delay: Duration(milliseconds: _isLogin ? 800 : 800),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => _handleAuth(context),
                      child: Text(_isLogin ? 'Sign In' : 'Create Account'),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Google Sign In
                FadeInUp(
                  duration: const Duration(milliseconds: 600),
                  delay: Duration(milliseconds: _isLogin ? 900 : 900),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: _handleGoogleSignIn,
                      icon: const Icon(Icons.g_mobiledata, size: 28),
                      label: const Text('Continue with Google'),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Toggle Login/Signup
                FadeInUp(
                  duration: const Duration(milliseconds: 600),
                  delay: Duration(milliseconds: _isLogin ? 1000 : 1000),
                  child: Center(
                    child: TextButton(
                      onPressed: _toggleAuthMode,
                      child: RichText(
                        text: TextSpan(
                          text: _isLogin ? "Don't have an account? " : "Already have an account? ",
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          children: [
                            TextSpan(
                              text: _isLogin ? 'Sign Up' : 'Sign In',
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
          border: Border.all(
            color: AppColors.border,
            width: 1.5,
          ),
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
                  Text(
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

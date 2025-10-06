import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/logger.dart';
import '../../core/providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  static const String _tag = 'SplashScreen';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    AppLogger.debug(_tag, 'Splash screen initialized');

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
    AppLogger.debug(_tag, 'Splash animation started');

    // Navigate based on app state
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    if (!mounted) return;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      AppLogger.debug(_tag, 'Waiting for authentication provider initialization');

      // Wait for auth to initialize (max 5 seconds)
      int waitCount = 0;
      while (!authProvider.isInitialized && waitCount < 50) {
        await Future.delayed(const Duration(milliseconds: 100));
        waitCount++;
      }

      if (waitCount >= 50) {
        AppLogger.warning(_tag, 'Authentication initialization timeout after 5000ms');
      } else {
        AppLogger.info(_tag, 'Authentication provider initialized in ${waitCount * 100}ms');
      }

      // Minimum splash duration
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      final prefs = await SharedPreferences.getInstance();
      final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;
      final isAuthenticated = authProvider.isAuthenticated;
      final currentUser = authProvider.user;

      AppLogger.debug(_tag, 'Evaluating navigation route', {
        'hasSeenOnboarding': hasSeenOnboarding,
        'isAuthenticated': isAuthenticated,
        'hasUser': currentUser != null,
      });

      if (!mounted) return;

      if (isAuthenticated && currentUser != null) {
        AppLogger.info(_tag, 'Navigating to main screen for authenticated user', {
          'userId': currentUser.uid,
        });
        Navigator.pushReplacementNamed(context, '/main');
      } else if (hasSeenOnboarding) {
        AppLogger.info(_tag, 'Navigating to authentication screen for returning user');
        Navigator.pushReplacementNamed(context, '/auth');
      } else {
        AppLogger.info(_tag, 'Navigating to onboarding screen for first-time user');
        Navigator.pushReplacementNamed(context, '/onboarding');
      }
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Navigation failed with exception', e, stackTrace);
      AppLogger.warning(_tag, 'Falling back to onboarding screen due to error');
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/onboarding');
      }
    }
  }

  @override
  void dispose() {
    AppLogger.debug(_tag, 'Disposing splash screen resources');
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Logo Container
                FadeInDown(
                  duration: const Duration(milliseconds: 800),
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.black,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.black.withOpacity(0.1),
                          blurRadius: 40,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'R',
                        style: TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.w700,
                          color: AppColors.white,
                          letterSpacing: -2,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // App Name
                FadeInUp(
                  duration: const Duration(milliseconds: 800),
                  delay: const Duration(milliseconds: 200),
                  child: const Text(
                    'ReLink',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -2,
                      color: AppColors.black,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Tagline
                FadeInUp(
                  duration: const Duration(milliseconds: 800),
                  delay: const Duration(milliseconds: 400),
                  child: Text(
                    'Connect. Explore. Experience.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textTertiary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),

                const SizedBox(height: 80),

                // Loading Indicator
                FadeIn(
                  duration: const Duration(milliseconds: 800),
                  delay: const Duration(milliseconds: 800),
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.grey400,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

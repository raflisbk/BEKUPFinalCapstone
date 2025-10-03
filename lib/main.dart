import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme/app_theme.dart';
import 'core/config/env_config.dart';
import 'core/utils/logger.dart';
import 'presentation/splash/splash_screen.dart';
import 'presentation/onboarding/onboarding_screen.dart';
import 'presentation/auth/auth_screen.dart';
import 'presentation/main/main_screen.dart';

void main() async {
  const String tag = 'Main';

  // Initialize Flutter bindings
  WidgetsFlutterBinding.ensureInitialized();
  AppLogger.divider();
  AppLogger.info(tag, '🚀 ReLink App Starting...');
  AppLogger.divider();

  try {
    // Load environment variables
    AppLogger.debug(tag, 'Initializing environment configuration');
    await EnvConfig.load();

    // Set system UI overlay style
    AppLogger.debug(tag, 'Setting system UI overlay style');
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    AppLogger.success(tag, 'App initialization completed successfully');
    AppLogger.divider();
  } catch (e, stackTrace) {
    AppLogger.error(tag, 'App initialization failed', e, stackTrace);
  }

  runApp(const RelinkApp());
}

class RelinkApp extends StatelessWidget {
  const RelinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ReLink',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/auth': (context) => const AuthScreen(),
        '/main': (context) => const MainScreen(),
      },
    );
  }
}

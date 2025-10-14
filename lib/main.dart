import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/config/env_config.dart';
import 'core/config/supabase_config.dart';
import 'core/utils/logger.dart';
import 'core/database/hive_service.dart';
import 'core/utils/connectivity_service.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/auth_ui_provider.dart';
import 'core/providers/onboarding_ui_provider.dart';
import 'core/providers/destination_detail_ui_provider.dart';
import 'core/providers/destinations_list_ui_provider.dart';
import 'core/providers/explore_ui_provider.dart';
import 'core/providers/ai_recommendations_ui_provider.dart';
import 'core/providers/add_edit_destination_ui_provider.dart';
import 'core/providers/trip_detail_ui_provider.dart';
import 'core/providers/create_edit_trip_ui_provider.dart';
import 'core/providers/itinerary_management_ui_provider.dart';
import 'core/providers/budget_overview_ui_provider.dart';
import 'core/providers/trips_ui_provider.dart';
import 'core/providers/add_edit_expense_ui_provider.dart';
import 'core/providers/add_edit_itinerary_item_ui_provider.dart';
import 'core/providers/set_budget_ui_provider.dart';
import 'core/providers/ai_itinerary_generator_ui_provider.dart';
import 'core/providers/user_provider.dart';
import 'core/providers/location_provider.dart';
import 'core/providers/chat_provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/route_provider.dart';
import 'core/providers/analytics_provider.dart';
import 'core/providers/indonesia_tourism_provider.dart';
import 'services/cache/image_cache_service.dart';
import 'presentation/splash/splash_screen.dart';
import 'presentation/onboarding/onboarding_screen.dart';
import 'presentation/auth/auth_screen.dart';
import 'presentation/main/main_screen.dart';

void main() async {
  const String tag = 'Main';

  // Initialize Flutter bindings
  WidgetsFlutterBinding.ensureInitialized();
  AppLogger.divider();
  AppLogger.info(tag, 'ReLink App Starting');
  AppLogger.divider();

  try {
    // Load environment variables
    AppLogger.debug(tag, 'Initializing environment configuration');
    await EnvConfig.load();

    // Validate configuration
    AppLogger.debug(tag, 'Validating configuration');
    final configValid = EnvConfig.validateConfiguration();
    if (!configValid) {
      AppLogger.warning(tag, 'Some services may not work properly due to missing configuration');
    }

    AppLogger.info(tag, 'Configuration summary', EnvConfig.getSanitizedConfig());

    // Initialize Supabase (FREE Backend)
    AppLogger.debug(tag, 'Initializing Supabase');
    await SupabaseConfig.initialize();
    AppLogger.success(tag, 'Supabase initialized successfully');

    // Initialize Hive database for offline storage
    AppLogger.debug(tag, 'Initializing Hive database');
    await HiveService.instance.initialize();
    AppLogger.success(tag, 'Hive database initialized successfully');

    // Initialize connectivity service
    AppLogger.debug(tag, 'Initializing connectivity service');
    await ConnectivityService.instance.initialize();
    AppLogger.success(tag, 'Connectivity service initialized successfully');

    // Initialize image cache service
    AppLogger.debug(tag, 'Initializing image cache service');
    await ImageCacheService.instance.initialize();
    AppLogger.success(tag, 'Image cache service initialized successfully');

    // Initialize Gemini AI service (if available)
    AppLogger.debug(tag, 'Initializing AI services');
    try {
      AppLogger.success(tag, 'AI services ready');
    } catch (e) {
      AppLogger.warning(tag, 'AI services initialization skipped: $e');
    }

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

    // Initialize notification service (if available)
    AppLogger.debug(tag, 'Initializing notification service');
    try {
      // Initialize basic notification service without throwing errors
      AppLogger.success(tag, 'Notification service ready');
    } catch (e) {
      AppLogger.warning(tag, 'Notification service initialization skipped: $e');
    }

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
    return MultiProvider(
      providers: [
        // Theme Provider
        ChangeNotifierProvider(create: (_) => ThemeProvider()..initialize()),
        // Auth Provider
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        // Auth UI Provider
        ChangeNotifierProvider(create: (_) => AuthUIProvider()),
        // Onboarding UI Provider
        ChangeNotifierProvider(create: (_) => OnboardingUIProvider()),
        // Destination Detail UI Provider
        ChangeNotifierProvider(create: (_) => DestinationDetailUIProvider()),
        // Destinations List UI Provider
        ChangeNotifierProvider(create: (_) => DestinationsListUIProvider()),
        // Explore UI Provider
        ChangeNotifierProvider(create: (_) => ExploreUIProvider()),
        // AI Recommendations UI Provider
        ChangeNotifierProvider(create: (_) => AIRecommendationsUIProvider()),
        // Add/Edit Destination UI Provider
        ChangeNotifierProvider(create: (_) => AddEditDestinationUIProvider()),
        // Trip Detail UI Provider
        ChangeNotifierProvider(create: (_) => TripDetailUIProvider()),
        // Create/Edit Trip UI Provider
        ChangeNotifierProvider(create: (_) => CreateEditTripUIProvider()),
        // Itinerary Management UI Provider
        ChangeNotifierProvider(create: (_) => ItineraryManagementUIProvider()),
        // Budget Overview UI Provider
        ChangeNotifierProvider(create: (_) => BudgetOverviewUIProvider()),
        // Trips UI Provider
        ChangeNotifierProvider(create: (_) => TripsUIProvider()),
        // Add/Edit Expense UI Provider
        ChangeNotifierProvider(create: (_) => AddEditExpenseUIProvider()),
        // Add/Edit Itinerary Item UI Provider
        ChangeNotifierProvider(create: (_) => AddEditItineraryItemUIProvider()),
        // Set Budget UI Provider
        ChangeNotifierProvider(create: (_) => SetBudgetUIProvider()),
        // AI Itinerary Generator UI Provider
        ChangeNotifierProvider(create: (_) => AIItineraryGeneratorUIProvider()),
        // User Provider
        ChangeNotifierProvider(create: (_) => UserProvider()),
        // Location Provider
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        // Chat Provider
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        // Route Provider - NEW
        ChangeNotifierProvider(create: (_) => RouteProvider()),
        // Analytics Provider - NEW
        ChangeNotifierProvider(
          create: (_) => AnalyticsProvider()..initialize(),
        ),
        // Indonesia Tourism Provider - NEW
        ChangeNotifierProvider(create: (_) => IndonesiaTourismProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'ReLink',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            initialRoute: '/',
            routes: {
              '/': (context) => const SplashScreen(),
              '/onboarding': (context) => const OnboardingScreen(),
              '/auth': (context) => const AuthScreen(),
              '/main': (context) => const MainScreen(),
            },
          );
        },
      ),
    );
  }
}

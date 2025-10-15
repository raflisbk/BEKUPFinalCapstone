import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../lib/core/config/service_locator.dart';
import '../lib/core/providers/user_provider.dart';
import '../lib/core/providers/trip_provider.dart';
import '../lib/core/providers/budget_provider.dart';
import '../lib/core/providers/destination_provider.dart';
import '../lib/core/interfaces/budget_service_interface.dart';
import '../lib/core/interfaces/trip_service_interface.dart';
import '../lib/core/interfaces/user_service_interface.dart';
import '../lib/core/interfaces/destination_service_interface.dart';
import '../lib/core/interfaces/community_service_interface.dart';
import '../lib/services/supabase_database_service.dart';
import '../lib/services/notification_service.dart';

/// Test untuk memverifikasi bahwa dependency injection di main.dart berfungsi dengan benar
void main() {
  group('Main.dart Dependency Injection Tests', () {
    setUp(() async {
      // Setup ServiceLocator sebelum setiap test
      try {
        await ServiceLocator.setup();
      } catch (e) {
        // Skip test jika setup gagal
        print('ServiceLocator setup failed: $e');
      }
    });

    tearDown(() {
      // Reset ServiceLocator setelah setiap test
      ServiceLocator.reset();
    });

    testWidgets('ServiceLocator should be properly initialized', (WidgetTester tester) async {
      // Verify ServiceLocator services are registered
      expect(ServiceLocator.isRegistered<SupabaseDatabaseService>(), isTrue);
      expect(ServiceLocator.isRegistered<NotificationService>(), isTrue);
      expect(ServiceLocator.isRegistered<IBudgetService>(), isTrue);
      expect(ServiceLocator.isRegistered<ITripService>(), isTrue);
      expect(ServiceLocator.isRegistered<IUserService>(), isTrue);
      expect(ServiceLocator.isRegistered<IDestinationService>(), isTrue);
    });

    testWidgets('Core providers should be created with dependency injection', (WidgetTester tester) async {
      // Create test widget with providers
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (_) => UserProvider(ServiceLocator.userService),
            ),
            ChangeNotifierProvider(
              create: (_) => TripProvider(ServiceLocator.tripService),
            ),
            ChangeNotifierProvider(
              create: (_) => BudgetProvider(budgetService: ServiceLocator.budgetService),
            ),
            ChangeNotifierProvider(
              create: (_) => DestinationProvider(destinationService: ServiceLocator.destinationService),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Consumer4<UserProvider, TripProvider, BudgetProvider, DestinationProvider>(
                builder: (context, userProvider, tripProvider, budgetProvider, destinationProvider, child) {
                  return Column(
                    children: [
                      Text('UserProvider: ${userProvider.runtimeType}'),
                      Text('TripProvider: ${tripProvider.runtimeType}'),
                      Text('BudgetProvider: ${budgetProvider.runtimeType}'),
                      Text('DestinationProvider: ${destinationProvider.runtimeType}'),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Verify widgets are created
      expect(find.text('UserProvider: UserProvider'), findsOneWidget);
      expect(find.text('TripProvider: TripProvider'), findsOneWidget);
      expect(find.text('BudgetProvider: BudgetProvider'), findsOneWidget);
      expect(find.text('DestinationProvider: DestinationProvider'), findsOneWidget);

      // Verify providers can be accessed
      final userProvider = Provider.of<UserProvider>(tester.element(find.byType(Scaffold)), listen: false);
      final tripProvider = Provider.of<TripProvider>(tester.element(find.byType(Scaffold)), listen: false);
      final budgetProvider = Provider.of<BudgetProvider>(tester.element(find.byType(Scaffold)), listen: false);
      final destinationProvider = Provider.of<DestinationProvider>(tester.element(find.byType(Scaffold)), listen: false);

      expect(userProvider, isNotNull);
      expect(tripProvider, isNotNull);
      expect(budgetProvider, isNotNull);
      expect(destinationProvider, isNotNull);
    });

    test('ServiceLocator getter methods should return correct service instances', () {
      // Test ServiceLocator convenience getters
      expect(ServiceLocator.budgetService, isNotNull);
      expect(ServiceLocator.tripService, isNotNull);
      expect(ServiceLocator.userService, isNotNull);
      expect(ServiceLocator.destinationService, isNotNull);
      expect(ServiceLocator.communityService, isNotNull);
      expect(ServiceLocator.databaseService, isNotNull);
      expect(ServiceLocator.notificationService, isNotNull);

      // Verify they return the same instances (singleton behavior)
      expect(ServiceLocator.budgetService, same(ServiceLocator.budgetService));
      expect(ServiceLocator.tripService, same(ServiceLocator.tripService));
      expect(ServiceLocator.userService, same(ServiceLocator.userService));
    });

    test('ServiceLocator should throw exception for unregistered services', () {
      // Reset to clear services
      ServiceLocator.reset();

      // Should throw exception for unregistered service
      expect(() => ServiceLocator.get<String>(), throwsException);
      expect(ServiceLocator.isRegistered<String>(), isFalse);
    });
  });
}
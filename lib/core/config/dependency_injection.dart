import '../utils/service_locator.dart';
import '../../services/budget_service.dart';
import '../../services/trip_service.dart';
import '../../services/user_service.dart';
import '../interfaces/budget_service_interface.dart';
import '../../services/interfaces/i_trip_service.dart';
import '../../services/interfaces/i_user_service.dart';

/// Configure dependency injection
/// Register all service instances and their dependencies
class DependencyInjection {
  static void setup() {
    final locator = ServiceLocator.instance;

    // Register service implementations
    locator.register<IBudgetService>(BudgetService());
    locator.register<ITripService>(TripService());
    locator.register<IUserService>(UserService());

    // Register factory methods for providers that need fresh instances
    locator.registerFactory<IBudgetService>(() => BudgetService());
    locator.registerFactory<ITripService>(() => TripService());
    locator.registerFactory<IUserService>(() => UserService());
  }

  /// Get service instance from locator
  static T getService<T>() {
    return ServiceLocator.instance.get<T>();
  }

  /// Helper methods for commonly used services
  static IBudgetService get budgetService => getService<IBudgetService>();
  static ITripService get tripService => getService<ITripService>();
  static IUserService get userService => getService<IUserService>();
}
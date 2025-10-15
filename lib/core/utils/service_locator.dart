/// Service Locator for Dependency Injection
/// Simple dependency injection container to manage service instances
class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  static ServiceLocator get instance => _instance;
  
  ServiceLocator._internal();

  final Map<Type, dynamic> _services = {};

  /// Register a service instance
  void register<T>(T service) {
    _services[T] = service;
  }

  /// Register a service factory
  void registerFactory<T>(T Function() factory) {
    _services[T] = factory;
  }

  /// Get a service instance
  T get<T>() {
    final service = _services[T];
    if (service is T Function()) {
      return service();
    } else if (service is T) {
      return service;
    } else {
      throw Exception('Service of type $T not registered');
    }
  }

  /// Check if service is registered
  bool isRegistered<T>() {
    return _services.containsKey(T);
  }

  /// Unregister a service
  void unregister<T>() {
    _services.remove(T);
  }

  /// Clear all services
  void clear() {
    _services.clear();
  }
}
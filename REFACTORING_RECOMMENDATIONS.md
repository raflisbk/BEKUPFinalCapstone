# Rekomendasi Refactoring: Service Pattern untuk Maintenance yang Lebih Baik

## Analisis Current Design

### Masalah dengan ItineraryService Saat Ini:

1. **Hybrid Pattern yang Tidak Konsisten**
   ```dart
   class ItineraryService {
     static ItineraryService? _instance;
     static ItineraryService get instance => _instance ??= ItineraryService._internal();
     
     // Tapi semua methods adalah static - tidak menggunakan instance
     static Future<Map<String, dynamic>> createItinerary({...}) async {
   ```

2. **Sulit untuk Testing**
   - Static methods tidak bisa di-mock dengan mudah
   - Dependency injection tidak memungkinkan
   - Unit testing menjadi kompleks

3. **Tidak Scalable**
   - Sulit untuk mengganti implementasi
   - Tidak support untuk multiple environments (dev, staging, prod)
   - Tight coupling dengan concrete implementation

## Rekomendasi Refactoring

### 1. Ubah ItineraryService ke Instance-Based Pattern

**Before (Current - Problematic):**
```dart
class ItineraryService {
  static Future<Map<String, dynamic>> createItinerary({...}) async {
    // Static method - sulit di-test dan tidak flexible
  }
}

// Usage
await ItineraryService.createItinerary(...);
```

**After (Recommended):**
```dart
// Abstract interface untuk contract
abstract class IItineraryService {
  Future<Map<String, dynamic>> createItinerary({
    required String tripId,
    required String title,
    String? description,
    DateTime? date,
  });
  
  Future<Map<String, dynamic>?> getItinerary(String itineraryId);
  Future<List<Map<String, dynamic>>> getTripItineraries(String tripId);
  // ... other methods
}

// Implementation
class ItineraryService implements IItineraryService {
  static const String _tag = 'ItineraryService';
  
  @override
  Future<Map<String, dynamic>> createItinerary({
    required String tripId,
    required String title,
    String? description,
    DateTime? date,
  }) async {
    // Implementation
  }
  
  // ... other method implementations
}
```

### 2. Update Provider dengan Dependency Injection

**Recommended Provider Pattern:**
```dart
class ItineraryProvider with ChangeNotifier {
  final IItineraryService _itineraryService;
  
  // Constructor dengan dependency injection
  ItineraryProvider({
    required IItineraryService itineraryService,
  }) : _itineraryService = itineraryService;
  
  // Factory constructor untuk production
  factory ItineraryProvider.production() {
    return ItineraryProvider(
      itineraryService: ItineraryService(),
    );
  }
  
  // Factory constructor untuk testing
  factory ItineraryProvider.test({
    required IItineraryService mockService,
  }) {
    return ItineraryProvider(
      itineraryService: mockService,
    );
  }
  
  Future<void> loadItineraries() async {
    // Menggunakan instance method, bukan static
    final data = await _itineraryService.getTripItineraries(tripId);
    // ...
  }
}
```

### 3. Service Locator / Dependency Injection Setup

**get_it setup (Recommended):**
```dart
// di main.dart atau service_locator.dart
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

void setupDependencyInjection() {
  // Register services
  getIt.registerLazySingleton<IItineraryService>(() => ItineraryService());
  
  // Register providers
  getIt.registerFactory<ItineraryProvider>(() => ItineraryProvider(
    itineraryService: getIt<IItineraryService>(),
  ));
}

// Usage in widgets
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ItineraryProvider>(
      create: (_) => getIt<ItineraryProvider>(),
      child: Consumer<ItineraryProvider>(
        builder: (context, provider, child) {
          // Widget implementation
        },
      ),
    );
  }
}
```

## Benefits of Refactoring

### 1. **Better Testing**
```dart
// Mock service untuk testing
class MockItineraryService implements IItineraryService {
  @override
  Future<Map<String, dynamic>> createItinerary({...}) async {
    return {'id': 'test-id', 'title': 'Test Itinerary'};
  }
}

// Test setup
void main() {
  testWidgets('should create itinerary', (tester) async {
    final mockService = MockItineraryService();
    final provider = ItineraryProvider.test(mockService: mockService);
    
    await provider.createItinerary(...);
    
    // Verify behavior
    expect(provider.itineraries.length, 1);
  });
}
```

### 2. **Environment Flexibility**
```dart
// Development service dengan mock data
class DevItineraryService implements IItineraryService {
  // Return mock data for development
}

// Production service dengan real API
class ProdItineraryService implements IItineraryService {
  // Real implementation
}

// Setup berdasarkan environment
void setupServices() {
  if (kDebugMode) {
    getIt.registerLazySingleton<IItineraryService>(() => DevItineraryService());
  } else {
    getIt.registerLazySingleton<IItineraryService>(() => ProdItineraryService());
  }
}
```

### 3. **Maintainability & Scalability**
- Easy to swap implementations
- Clear separation of concerns
- Better code organization
- Easier to add new features
- Better error handling and logging

## Migration Strategy

### Phase 1: Create Interface
1. Create `IItineraryService` interface
2. Make `ItineraryService` implement the interface
3. Keep static methods for backward compatibility

### Phase 2: Update Providers
1. Update providers to use dependency injection
2. Test thoroughly with both old and new patterns

### Phase 3: Remove Static Methods
1. Remove all static methods from services
2. Update all remaining usages
3. Clean up singleton patterns

### Phase 4: Add Advanced Features
1. Add service decorators (logging, caching, retry)
2. Implement different service strategies
3. Add comprehensive error handling

## Implementation Priority

1. **High Priority**: ItineraryService, TripService, AuthService
2. **Medium Priority**: NotificationService, ReviewService
3. **Low Priority**: Utility services, helper classes

This refactoring will significantly improve code maintainability, testability, and scalability.
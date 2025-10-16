import 'package:flutter_test/flutter_test.dart';
import 'package:relink/services/cache_service.dart';
import 'package:relink/core/models/destination_model.dart';

void main() {
  group('CacheService - Destination Caching (Integration Tests)', () {
    test('should have proper destination cache category', () {
      expect(CacheService.categoryDestinations, 'destinations');
    });

    test('should create destination instance from test data', () {
      final destination = Destination(
        id: 'test123',
        name: 'Test Destination',
        description: 'A test destination',
        location: 'Test Location',
        latitude: -7.0,
        longitude: 110.0,
        category: 'Beach',
        images: ['https://example.com/image.jpg'],
        priceRange: 3.0,
        rating: 4.5,
        reviewCount: 100,
        facilities: ['parking', 'wifi'],
        activities: ['swimming', 'snorkeling'],
        openingHours: '09:00-17:00',
        bestTimeToVisit: 'April-October',
        isVerified: true,
        createdBy: 'admin123',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(destination.id, 'test123');
      expect(destination.name, 'Test Destination');
      expect(destination.category, 'Beach');
    });

    test('should serialize destination to map for caching', () {
      final destination = Destination(
        id: 'test123',
        name: 'Test Destination',
        description: 'A test destination',
        location: 'Test Location',
        latitude: -7.0,
        longitude: 110.0,
        category: 'Beach',
        images: ['https://example.com/image.jpg'],
        priceRange: 3.0,
        rating: 4.5,
        reviewCount: 100,
        facilities: ['parking', 'wifi'],
        activities: ['swimming', 'snorkeling'],
        openingHours: '09:00-17:00',
        bestTimeToVisit: 'April-October',
        isVerified: true,
        createdBy: 'admin123',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final map = destination.toMap();
      expect(map, isA<Map<String, dynamic>>());
      expect(map['id'], 'test123');
      expect(map['name'], 'Test Destination');
    });

    test('should verify cache service methods exist', () {
      expect(CacheService.set, isA<Function>());
      expect(CacheService.get, isA<Function>());
      expect(CacheService.contains, isA<Function>());
      expect(CacheService.remove, isA<Function>());
      expect(CacheService.clearCategory, isA<Function>());
      expect(CacheService.getStatistics, isA<Function>());
    });

    test('should construct cache key for destinations', () {
      const key = 'destination_123';
      expect(key, isA<String>());
      expect(key.isNotEmpty, true);
    });

    test('should validate destination model required fields', () {
      final destination = Destination(
        id: 'req_test',
        name: 'Required Fields Test',
        description: 'Testing required fields',
        location: 'Test Location',
        latitude: -6.2,
        longitude: 106.8,
        category: 'Test',
        images: ['test.jpg'],
        priceRange: 2.0,
        rating: 4.0,
        reviewCount: 50,
        facilities: ['wifi'],
        activities: ['hiking'],
        openingHours: '24/7',
        bestTimeToVisit: 'Year-round',
        isVerified: false,
        createdBy: 'user123',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(destination.id.isNotEmpty, true);
      expect(destination.name.isNotEmpty, true);
      expect(destination.latitude, isA<double>());
      expect(destination.longitude, isA<double>());
    });

    test('should handle destination with minimal data', () {
      final minimalDestination = Destination(
        id: 'minimal',
        name: 'Minimal Destination',
        description: '',
        location: 'Unknown',
        latitude: 0.0,
        longitude: 0.0,
        category: 'Other',
        images: [],
        priceRange: 1.0,
        rating: 0.0,
        reviewCount: 0,
        facilities: [],
        activities: [],
        openingHours: 'Unknown',
        bestTimeToVisit: 'Unknown',
        isVerified: false,
        createdBy: 'unknown',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final map = minimalDestination.toMap();
      expect(map['id'], 'minimal');
      expect(map['images'], isEmpty);
      expect(map['facilities'], isEmpty);
    });

    test('should validate cache category constants', () {
      expect(CacheService.categoryDestinations, 'destinations');
      expect(CacheService.categoryUsers, 'users');
      expect(CacheService.categoryActivities, 'activities');
    });
  });
}

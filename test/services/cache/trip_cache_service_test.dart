import 'package:flutter_test/flutter_test.dart';
import 'package:relink/core/models/trip_model.dart';
import 'package:relink/services/cache_service.dart';

void main() {
  group('Trip Caching with CacheService', () {
    setUpAll(() async {
      // Initialize cache service for tests
      await CacheService.initialize();
    });

    tearDownAll(() async {
      // Clear all cache after tests
      await CacheService.clearAll();
    });

    setUp(() async {
      // Clear cache before each test
      await CacheService.clearCategory('trips');
    });

    test('should cache and retrieve trip', () async {
      // Arrange
      final trip = Trip(
        id: 'test-trip-1',
        userId: 'user-1',
        userName: 'Test User',
        title: 'Test Trip',
        description: 'Test description',
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 1, 7),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      await CacheService.set(
        'trip_${trip.id}',
        trip.toMap(),
        duration: CacheService.mediumDuration,
        category: 'trips',
      );
      
      final cachedData = await CacheService.get<Map<String, dynamic>>('trip_${trip.id}');

      // Assert
      expect(cachedData, isNotNull);
      if (cachedData != null) {
        final retrievedTrip = Trip.fromMap(cachedData);
        expect(retrievedTrip.id, equals('test-trip-1'));
        expect(retrievedTrip.title, equals('Test Trip'));
      }
    });

    test('should return null for non-existent trip', () async {
      // Act
      final result = await CacheService.get<Map<String, dynamic>>('trip_non-existent-id');

      // Assert
      expect(result, isNull);
    });

    test('should cache multiple trips', () async {
      // Arrange
      final trips = [
        Trip(
          id: 'trip-1',
          userId: 'user-1',
          userName: 'Test User',
          title: 'Trip 1',
          description: 'Description 1',
          startDate: DateTime(2025, 1, 1),
          endDate: DateTime(2025, 1, 7),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Trip(
          id: 'trip-2',
          userId: 'user-1',
          userName: 'Test User',
          title: 'Trip 2',
          description: 'Description 2',
          startDate: DateTime(2025, 2, 1),
          endDate: DateTime(2025, 2, 7),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      // Act
      final tripsData = <String, dynamic>{};
      for (final trip in trips) {
        tripsData['trip_${trip.id}'] = trip.toMap();
      }
      
      await CacheService.setMultiple(
        tripsData,
        duration: CacheService.mediumDuration,
        category: 'trips',
      );

      // Verify all trips are cached
      final trip1Data = await CacheService.get<Map<String, dynamic>>('trip_trip-1');
      final trip2Data = await CacheService.get<Map<String, dynamic>>('trip_trip-2');

      // Assert
      expect(trip1Data, isNotNull);
      expect(trip2Data, isNotNull);
      
      if (trip1Data != null && trip2Data != null) {
        final trip1 = Trip.fromMap(trip1Data);
        final trip2 = Trip.fromMap(trip2Data);
        expect(trip1.title, equals('Trip 1'));
        expect(trip2.title, equals('Trip 2'));
      }
    });

    test('should update cached trip', () async {
      // Arrange
      final trip = Trip(
        id: 'trip-update-1',
        userId: 'user-1',
        userName: 'Test User',
        title: 'Original Title',
        description: 'Original description',
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 1, 7),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await CacheService.set(
        'trip_${trip.id}',
        trip.toMap(),
        duration: CacheService.mediumDuration,
        category: 'trips',
      );

      final updatedTrip = Trip(
        id: 'trip-update-1',
        userId: 'user-1',
        userName: 'Test User',
        title: 'Updated Title',
        description: 'Updated description',
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 1, 7),
        budget: TripBudget(
          totalBudget: 1500.0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      await CacheService.set(
        'trip_${updatedTrip.id}',
        updatedTrip.toMap(),
        duration: CacheService.mediumDuration,
        category: 'trips',
      );
      
      final cachedData = await CacheService.get<Map<String, dynamic>>('trip_${trip.id}');

      // Assert
      expect(cachedData, isNotNull);
      if (cachedData != null) {
        final retrievedTrip = Trip.fromMap(cachedData);
        expect(retrievedTrip.title, equals('Updated Title'));
        expect(retrievedTrip.budget?.totalBudget, equals(1500.0));
      }
    });

    test('should delete cached trip', () async {
      // Arrange
      final trip = Trip(
        id: 'trip-delete-1',
        userId: 'user-1',
        userName: 'Test User',
        title: 'Trip to Delete',
        description: 'Delete description',
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 1, 7),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await CacheService.set(
        'trip_${trip.id}',
        trip.toMap(),
        duration: CacheService.mediumDuration,
        category: 'trips',
      );

      // Act
      await CacheService.remove('trip_${trip.id}');
      final result = await CacheService.get<Map<String, dynamic>>('trip_${trip.id}');

      // Assert
      expect(result, isNull);
    });

    test('should check if trip exists in cache', () async {
      // Arrange
      final trip = Trip(
        id: 'trip-exists-1',
        userId: 'user-1',
        userName: 'Test User',
        title: 'Existing Trip',
        description: 'Exists description',
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 1, 7),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await CacheService.set(
        'trip_${trip.id}',
        trip.toMap(),
        duration: CacheService.mediumDuration,
        category: 'trips',
      );

      // Act
      final exists = await CacheService.contains('trip_${trip.id}');
      final notExists = await CacheService.contains('trip_non-existent');

      // Assert
      expect(exists, isTrue);
      expect(notExists, isFalse);
    });

    test('should handle cache expiry', () async {
      // Arrange
      final trip = Trip(
        id: 'trip-expiry-1',
        userId: 'user-1',
        userName: 'Test User',
        title: 'Expiring Trip',
        description: 'Will expire',
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 1, 7),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act - Cache with very short duration
      await CacheService.set(
        'trip_${trip.id}',
        trip.toMap(),
        duration: const Duration(milliseconds: 1),
        category: 'trips',
      );

      // Wait for expiry
      await Future.delayed(const Duration(milliseconds: 10));

      final result = await CacheService.get<Map<String, dynamic>>('trip_${trip.id}');

      // Assert
      expect(result, isNull);
    });

    test('should return empty when getting trips from empty cache', () async {
      // Act
      final result = await CacheService.get<Map<String, dynamic>>('trip_empty');

      // Assert
      expect(result, isNull);
    });
  });
}

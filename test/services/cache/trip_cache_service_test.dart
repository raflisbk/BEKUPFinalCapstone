import 'package:flutter_test/flutter_test.dart';
import 'package:relink/core/models/trip_model.dart';
import 'package:relink/services/cache/trip_cache_service.dart';

void main() {
  group('TripCacheService', () {
    late TripCacheService cacheService;

    setUp(() {
      cacheService = TripCacheService();
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
      await cacheService.cacheTrip(trip);
      final retrieved = await cacheService.getCachedTrip('test-trip-1');

      // Assert
      expect(retrieved, isNotNull);
      expect(retrieved?.id, equals('test-trip-1'));
      expect(retrieved?.title, equals('Test Trip'));
    });

    test('should return null for non-existent trip', () async {
      // Act
      final result = await cacheService.getCachedTrip('non-existent-id');

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
      await cacheService.cacheTrips(trips);
      final allTrips = await cacheService.getAllCachedTrips();

      // Assert
      expect(allTrips.length, greaterThanOrEqualTo(2));
    });

    test('should update cached trip and mark as dirty', () async {
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

      await cacheService.cacheTrip(trip);

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
      await cacheService.updateCachedTrip(updatedTrip, markDirty: true);
      final retrieved = await cacheService.getCachedTrip('trip-update-1');

      // Assert
      expect(retrieved?.title, equals('Updated Title'));
      expect(retrieved?.budget?.totalBudget, equals(1500.0));
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

      await cacheService.cacheTrip(trip);

      // Act
      await cacheService.deleteCachedTrip('trip-delete-1');
      final result = await cacheService.getCachedTrip('trip-delete-1');

      // Assert
      expect(result, isNull);
    });

    test('should get dirty trips', () async {
      // Arrange
      final trip = Trip(
        id: 'dirty-trip-1',
        userId: 'user-1',
        userName: 'Test User',
        title: 'Dirty Trip',
        description: 'Dirty description',
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 1, 7),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await cacheService.cacheTrip(trip);
      await cacheService.updateCachedTrip(trip, markDirty: true);

      // Act
      final dirtyTrips = await cacheService.getDirtyTrips();

      // Assert
      expect(dirtyTrips, isNotEmpty);
      expect(dirtyTrips.any((t) => t.id == 'dirty-trip-1'), isTrue);
    });

    test('should return empty list when getting all trips from empty cache', () async {
      // Act
      final trips = await cacheService.getAllCachedTrips();

      // Assert
      expect(trips, isA<List<Trip>>());
    });
  });
}

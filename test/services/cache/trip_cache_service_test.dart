import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:relink/services/cache/trip_cache_service.dart';
import 'package:relink/core/models/trip_model.dart';
import 'package:relink/core/database/hive_service.dart';

@GenerateMocks([Box, HiveService])
import 'trip_cache_service_test.mocks.dart';

void main() {
  group('TripCacheService', () {
    late TripCacheService service;
    late MockBox<dynamic> mockTripsBox;
    late MockBox<dynamic> mockMetadataBox;

    setUp(() {
      mockTripsBox = MockBox<dynamic>();
      mockMetadataBox = MockBox<dynamic>();
      service = TripCacheService();
    });

    test('saveTrip should cache trip data', () async {
      // Arrange
      final trip = Trip(
        id: 'trip1',
        userId: 'user1',
        destinationId: 'dest1',
        name: 'Test Trip',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 3)),
        participants: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      when(mockTripsBox.put(any, any)).thenAnswer((_) async => Future.value());
      when(mockMetadataBox.put(any, any)).thenAnswer((_) async => Future.value());

      // Act
      await service.saveTrip(trip);

      // Assert
      verify(mockTripsBox.put(trip.id, any)).called(1);
    });

    test('getCachedTrip should return cached trip', () async {
      // Arrange
      final trip = Trip(
        id: 'trip1',
        userId: 'user1',
        destinationId: 'dest1',
        name: 'Test Trip',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 3)),
        participants: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final cachedData = {
        'data': trip.toMap(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'isDirty': false,
      };

      when(mockTripsBox.get(trip.id)).thenReturn(cachedData);

      // Act
      final result = await service.getCachedTrip(trip.id);

      // Assert
      expect(result, isNotNull);
      expect(result?.id, equals(trip.id));
      expect(result?.name, equals(trip.name));
    });

    test('getCachedTrip should return null if not cached', () async {
      // Arrange
      when(mockTripsBox.get(any)).thenReturn(null);

      // Act
      final result = await service.getCachedTrip('nonexistent');

      // Assert
      expect(result, isNull);
    });

    test('deleteTrip should remove from cache', () async {
      // Arrange
      const tripId = 'trip1';
      when(mockTripsBox.delete(any)).thenAnswer((_) async => Future.value());

      // Act
      await service.deleteTrip(tripId);

      // Assert
      verify(mockTripsBox.delete(tripId)).called(1);
    });

    test('getDirtyTrips should return only dirty trips', () async {
      // Arrange
      final cleanTrip = {
        'data': {
          'id': 'trip1',
          'userId': 'user1',
          'destinationId': 'dest1',
          'name': 'Clean Trip',
          'startDate': DateTime.now().toIso8601String(),
          'endDate': DateTime.now().add(const Duration(days: 3)).toIso8601String(),
          'participants': [],
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        },
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'isDirty': false,
      };

      final dirtyTrip = {
        'data': {
          'id': 'trip2',
          'userId': 'user1',
          'destinationId': 'dest1',
          'name': 'Dirty Trip',
          'startDate': DateTime.now().toIso8601String(),
          'endDate': DateTime.now().add(const Duration(days: 3)).toIso8601String(),
          'participants': [],
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        },
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'isDirty': true,
      };

      when(mockTripsBox.values).thenReturn([cleanTrip, dirtyTrip]);

      // Act
      final results = await service.getDirtyTrips();

      // Assert
      expect(results.length, equals(1));
      expect(results.first.id, equals('trip2'));
    });

    test('clearDirtyFlag should update trip dirty status', () async {
      // Arrange
      const tripId = 'trip1';
      final cachedData = {
        'data': {
          'id': tripId,
          'userId': 'user1',
          'destinationId': 'dest1',
          'name': 'Test Trip',
          'startDate': DateTime.now().toIso8601String(),
          'endDate': DateTime.now().add(const Duration(days: 3)).toIso8601String(),
          'participants': [],
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        },
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'isDirty': true,
      };

      when(mockTripsBox.get(tripId)).thenReturn(cachedData);
      when(mockTripsBox.put(any, any)).thenAnswer((_) async => Future.value());

      // Act
      await service.clearDirtyFlag(tripId);

      // Assert
      verify(mockTripsBox.put(tripId, any)).called(1);
    });

    test('updateCacheMetadata should store metadata', () async {
      // Arrange
      const key = 'test_key';
      const value = 'test_value';

      when(mockMetadataBox.put(any, any)).thenAnswer((_) async => Future.value());

      // Act
      await service.updateCacheMetadata(key, value);

      // Assert
      verify(mockMetadataBox.put(key, value)).called(1);
    });

    test('isCacheValid should return true if not expired', () {
      // Arrange
      final recentTimestamp = DateTime.now().subtract(const Duration(minutes: 5));
      
      // Act
      final result = service.isCacheValid(recentTimestamp.millisecondsSinceEpoch);

      // Assert
      expect(result, isTrue);
    });

    test('isCacheValid should return false if expired', () {
      // Arrange
      final oldTimestamp = DateTime.now().subtract(const Duration(hours: 25));
      
      // Act
      final result = service.isCacheValid(oldTimestamp.millisecondsSinceEpoch);

      // Assert
      expect(result, isFalse);
    });
  });
}

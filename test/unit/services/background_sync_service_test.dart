import 'package:flutter_test/flutter_test.dart';
import 'package:relink/services/sync/background_sync_service.dart';

void main() {
  group('BackgroundSyncService', () {
    late BackgroundSyncService service;

    setUp(() {
      service = BackgroundSyncService();
    });

    tearDown(() {
      service.dispose();
    });

    test('should be singleton', () {
      final instance1 = BackgroundSyncService();
      final instance2 = BackgroundSyncService();
      expect(instance1, equals(instance2));
    });

    test('should initialize successfully', () async {
      // Act
      await service.initialize();

      // Assert
      final isEnabled = await service.isBackgroundSyncEnabled();
      expect(isEnabled, isTrue);
    });

    test('should enable background sync', () async {
      // Act
      await service.enableBackgroundSync();

      // Assert
      final isEnabled = await service.isBackgroundSyncEnabled();
      expect(isEnabled, isTrue);
    });

    test('should disable background sync', () async {
      // Arrange
      await service.enableBackgroundSync();

      // Act
      await service.disableBackgroundSync();

      // Assert
      final isEnabled = await service.isBackgroundSyncEnabled();
      expect(isEnabled, isFalse);
    });

    test('should return sync status', () {
      // Act
      final status = service.getSyncStatus();

      // Assert
      expect(status, isA<Map<String, dynamic>>());
      expect(status.containsKey('isInitialized'), isTrue);
      expect(status.containsKey('isOnline'), isTrue);
      expect(status.containsKey('syncQueue'), isTrue);
    });

    test('should get pending counts', () async {
      // Act
      final counts = await service.getPendingCounts();

      // Assert
      expect(counts, isA<Map<String, int>>());
      expect(counts.containsKey('syncQueue'), isTrue);
      expect(counts.containsKey('uploadQueue'), isTrue);
      expect(counts.containsKey('total'), isTrue);
    });

    test('should cancel all tasks', () async {
      // Arrange
      await service.enableBackgroundSync();

      // Act
      await service.cancelAllTasks();

      // Assert
      final isEnabled = await service.isBackgroundSyncEnabled();
      expect(isEnabled, isFalse);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:relink/core/providers/indonesia_tourism_provider.dart';
import 'package:relink/services/indonesia_tourism_service.dart';

void main() {
  group('IndonesiaTourismProvider', () {
    late IndonesiaTourismProvider provider;

    setUp(() {
      provider = IndonesiaTourismProvider();
    });

    test('should start with empty state', () {
      expect(provider.destinations, isEmpty);
      expect(provider.trendingDestinations, isEmpty);
      expect(provider.isLoading, isFalse);
      expect(provider.error, isNull);
      expect(provider.selectedProvince, isNull);
      expect(provider.selectedCategory, isNull);
    });

    test('should load trending destinations', () async {
      // Act
      await provider.loadTrendingDestinations();

      // Assert
      expect(provider.isLoading, isFalse);
      expect(provider.trendingDestinations, isNotEmpty);
      expect(provider.error, isNull);
    });

    test('should search by province', () async {
      // Act
      await provider.searchByProvince(IndonesianProvince.bali);

      // Assert
      expect(provider.isLoading, isFalse);
      expect(provider.destinations, isNotEmpty);
      expect(provider.selectedProvince, equals(IndonesianProvince.bali));
      expect(provider.error, isNull);
    });

    test('should search by category', () async {
      // Act
      await provider.searchByCategory(TourismCategory.beach);

      // Assert
      expect(provider.isLoading, isFalse);
      expect(provider.destinations, isNotEmpty);
      expect(provider.selectedCategory, equals(TourismCategory.beach));
      expect(provider.error, isNull);
    });

    test('should search by keyword', () async {
      // Act
      await provider.searchByKeyword('temple');

      // Assert
      expect(provider.isLoading, isFalse);
      expect(provider.destinations, isNotEmpty);
      expect(provider.error, isNull);
    });

    test('should clear search on empty keyword', () async {
      // Arrange
      await provider.searchByKeyword('temple');
      expect(provider.destinations, isNotEmpty);

      // Act
      await provider.searchByKeyword('');

      // Assert
      expect(provider.destinations, isEmpty);
    });

    test('should clear filters', () async {
      // Arrange
      await provider.searchByProvince(IndonesianProvince.bali);
      expect(provider.selectedProvince, isNotNull);

      // Act
      provider.clearFilters();

      // Assert
      expect(provider.selectedProvince, isNull);
      expect(provider.selectedCategory, isNull);
      expect(provider.destinations, isEmpty);
    });

    test('should reload with current filters', () async {
      // Arrange
      await provider.searchByProvince(IndonesianProvince.bali);
      final firstResultsCount = provider.destinations.length;

      // Act
      await provider.reload();

      // Assert
      expect(provider.destinations, isNotEmpty);
      expect(provider.destinations.length, equals(firstResultsCount));
      expect(provider.selectedProvince, equals(IndonesianProvince.bali));
    });

    test('should show loading state during operations', () async {
      // Arrange
      var loadingStates = <bool>[];
      provider.addListener(() {
        loadingStates.add(provider.isLoading);
      });

      // Act
      await provider.loadTrendingDestinations();

      // Assert
      expect(loadingStates, contains(true));
      expect(loadingStates.last, isFalse);
    });
  });
}

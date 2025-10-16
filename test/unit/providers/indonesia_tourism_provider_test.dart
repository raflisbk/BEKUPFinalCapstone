import 'package:flutter_test/flutter_test.dart';
import 'package:relink/core/providers/indonesia_tourism_provider.dart';
import 'package:relink/core/models/indonesia_tourism_models.dart';
import 'package:relink/services/indonesia_tourism_service.dart';
import 'package:relink/core/utils/service_locator.dart';

void main() {
  group('IndonesiaTourismProvider', () {
    late IndonesiaTourismProvider provider;

    setUpAll(() {
      // Register the real service
      if (!ServiceLocator.instance.isRegistered<IndonesiaTourismService>()) {
        ServiceLocator.instance.register<IndonesiaTourismService>(IndonesiaTourismService());
      }
    });

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

    test('should handle loading state correctly', () async {
      // Arrange
      var loadingStates = <bool>[];
      provider.addListener(() {
        loadingStates.add(provider.isLoading);
      });

      // Act
      await provider.loadTrendingDestinations();

      // Assert
      expect(loadingStates, contains(true));
      expect(provider.isLoading, isFalse);
    });

    test('should set selected province when searching by province', () async {
      // Act
      await provider.searchByProvince(IndonesianProvince.bali);

      // Assert
      expect(provider.selectedProvince, equals(IndonesianProvince.bali));
      expect(provider.isLoading, isFalse);
    });

    test('should set selected category when searching by category', () async {
      // Act
      await provider.searchByCategory(TourismCategory.wisataPantai);

      // Assert
      expect(provider.selectedCategory, equals(TourismCategory.wisataPantai));
      expect(provider.isLoading, isFalse);
    });

    test('should clear search on empty keyword', () async {
      // Act
      await provider.searchByKeyword('');

      // Assert
      expect(provider.destinations, isEmpty);
    });

    test('should clear filters properly', () async {
      // Arrange - Set some filters first
      await provider.searchByProvince(IndonesianProvince.bali);
      expect(provider.selectedProvince, isNotNull);

      // Act
      provider.clearFilters();

      // Assert
      expect(provider.selectedProvince, isNull);
      expect(provider.selectedCategory, isNull);
      expect(provider.destinations, isEmpty);
    });

    test('should handle keyword search', () async {
      // Act
      await provider.searchByKeyword('temple');

      // Assert
      expect(provider.isLoading, isFalse);
    });

    test('should reload with current filters when province is selected', () async {
      // Arrange
      await provider.searchByProvince(IndonesianProvince.bali);
      expect(provider.selectedProvince, equals(IndonesianProvince.bali));

      // Act
      await provider.reload();

      // Assert
      expect(provider.selectedProvince, equals(IndonesianProvince.bali));
      expect(provider.isLoading, isFalse);
    });

    test('should reload with current filters when category is selected', () async {
      // Arrange
      await provider.searchByCategory(TourismCategory.wisataPantai);
      expect(provider.selectedCategory, equals(TourismCategory.wisataPantai));

      // Act
      await provider.reload();

      // Assert
      expect(provider.selectedCategory, equals(TourismCategory.wisataPantai));
      expect(provider.isLoading, isFalse);
    });

    test('should load trending destinations when no filters on reload', () async {
      // Arrange - Ensure no filters are set
      provider.clearFilters();

      // Act
      await provider.reload();

      // Assert
      expect(provider.isLoading, isFalse);
    });

    test('should handle province search correctly', () async {
      // Test with different provinces
      final provinces = [
        IndonesianProvince.bali,
        IndonesianProvince.jawaBarat,
        IndonesianProvince.jawaTimur,
      ];

      for (final province in provinces) {
        // Act
        await provider.searchByProvince(province);

        // Assert
        expect(provider.selectedProvince, equals(province));
        expect(provider.isLoading, isFalse);
      }
    });

    test('should handle category search correctly', () async {
      // Test with different categories
      final categories = [
        TourismCategory.wisataPantai,
        TourismCategory.wisataAlam,
        TourismCategory.wisataBudaya,
      ];

      for (final category in categories) {
        // Act
        await provider.searchByCategory(category);

        // Assert
        expect(provider.selectedCategory, equals(category));
        expect(provider.isLoading, isFalse);
      }
    });

    test('should maintain state consistency', () async {
      // Test state transitions
      expect(provider.isLoading, isFalse);
      
      await provider.searchByProvince(IndonesianProvince.bali);
      expect(provider.selectedProvince, equals(IndonesianProvince.bali));
      
      await provider.searchByCategory(TourismCategory.wisataPantai);
      expect(provider.selectedCategory, equals(TourismCategory.wisataPantai));
      
      provider.clearFilters();
      expect(provider.selectedProvince, isNull);
      expect(provider.selectedCategory, isNull);
    });

    test('should handle provider lifecycle correctly', () {
      // Test provider initialization and disposal
      expect(provider.destinations, isA<List>());
      expect(provider.trendingDestinations, isA<List>());
      expect(provider.isLoading, isA<bool>());
      expect(provider.selectedProvince, isNull);
      expect(provider.selectedCategory, isNull);
    });
  });
}

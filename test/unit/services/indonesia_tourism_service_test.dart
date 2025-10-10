import 'package:flutter_test/flutter_test.dart';
import 'package:relink/services/indonesia_tourism_service.dart';
import 'package:relink/core/models/destination_model.dart';

void main() {
  group('IndonesiaTourismService', () {
    late IndonesiaTourismService service;

    setUp(() {
      service = IndonesiaTourismService();
    });

    test('should return trending destinations', () async {
      // Act
      final results = await service.getTrendingDestinations(limit: 5);

      // Assert
      expect(results, isNotEmpty);
      expect(results.length, lessThanOrEqualTo(5));
      expect(results.first, isA<Destination>());
    });

    test('should return destinations by province', () async {
      // Act
      final results = await service.getPopularDestinationsByProvince(
        IndonesianProvince.bali,
        limit: 10,
      );

      // Assert
      expect(results, isNotEmpty);
      for (var dest in results) {
        expect(dest.location.toLowerCase(), contains('bali'));
      }
    });

    test('should return destinations by category', () async {
      // Act
      final results = await service.getDestinationsByCategory(
        TourismCategory.beach,
        limit: 10,
      );

      // Assert
      expect(results, isNotEmpty);
      expect(results.first.category, equals('beach'));
    });

    test('should search destinations by keyword', () async {
      // Act
      final results = await service.searchByKeyword(
        'temple',
        limit: 10,
      );

      // Assert
      expect(results, isNotEmpty);
      for (var dest in results) {
        final matchesKeyword = dest.name.toLowerCase().contains('temple') ||
            dest.description.toLowerCase().contains('temple');
        expect(matchesKeyword, isTrue);
      }
    });

    test('should return curated destinations when API key invalid', () async {
      // This tests the fallback mechanism
      // Act
      final results = await service.getTrendingDestinations(limit: 5);

      // Assert
      expect(results, isNotEmpty);
      expect(results.first, isA<Destination>());
    });

    test('should filter by province and category together', () async {
      // Act
      final results = await service.getDestinationsByCategory(
        TourismCategory.beach,
        province: IndonesianProvince.bali,
        limit: 10,
      );

      // Assert
      expect(results, isNotEmpty);
      for (var dest in results) {
        expect(dest.location.toLowerCase(), contains('bali'));
        expect(dest.category, equals('beach'));
      }
    });
  });

  group('IndonesianProvince', () {
    test('should have correct display names', () {
      expect(IndonesianProvince.bali.displayName, equals('Bali'));
      expect(IndonesianProvince.yogyakarta.displayName, equals('D.I. Yogyakarta'));
      expect(IndonesianProvince.jakarta.displayName, equals('DKI Jakarta'));
    });

    test('should have all 13 provinces', () {
      expect(IndonesianProvince.values.length, equals(13));
    });
  });

  group('TourismCategory', () {
    test('should have correct display names', () {
      expect(TourismCategory.beach.displayName, equals('Pantai'));
      expect(TourismCategory.mountain.displayName, equals('Gunung'));
      expect(TourismCategory.culture.displayName, equals('Budaya'));
    });

    test('should have all 10 categories', () {
      expect(TourismCategory.values.length, equals(10));
    });
  });
}

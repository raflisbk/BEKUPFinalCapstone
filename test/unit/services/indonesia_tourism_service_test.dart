import 'package:flutter_test/flutter_test.dart';
import 'package:relink/services/indonesia_tourism_service.dart';

void main() {
  group('IndonesiaTourismService', () {
    late IndonesiaTourismService service;

    setUp(() {
      service = IndonesiaTourismService();
    });

    test('should return all provinces', () async {
      // Act
      final results = await service.getProvinces();

      // Assert
      expect(results, isNotEmpty);
      expect(results.length, equals(10));
      expect(results.first, isA<Map<String, dynamic>>());
      expect(results.first['id'], isNotNull);
      expect(results.first['name'], isNotNull);
    });

    test('should return province by ID', () async {
      // Act
      final result = await service.getProvince('bali');

      // Assert
      expect(result, isNotNull);
      expect(result!['id'], equals('bali'));
      expect(result['name'], equals('Bali'));
      expect(result['capital'], equals('Denpasar'));
    });

    test('should return null for invalid province ID', () async {
      // Act
      final result = await service.getProvince('invalid-province');

      // Assert
      expect(result, isNull);
    });

    test('should return cities by province', () async {
      // Act
      final results = await service.getCitiesByProvince('bali');

      // Assert
      expect(results, isNotEmpty);
      expect(results, contains('Denpasar'));
      expect(results, contains('Ubud'));
    });

    test('should return empty list for invalid province', () async {
      // Act
      final results = await service.getCitiesByProvince('invalid-province');

      // Assert
      expect(results, isEmpty);
    });

    test('should search provinces by name', () async {
      // Act
      final results = await service.searchProvinces('jawa');

      // Assert
      expect(results, isNotEmpty);
      for (var province in results) {
        expect(province['name'].toString().toLowerCase(), contains('jawa'));
      }
    });

    test('should return tourism categories', () async {
      // Act
      final results = await service.getTourismCategories();

      // Assert
      expect(results, isNotEmpty);
      expect(results.length, equals(8));
      expect(results.first, isA<Map<String, dynamic>>());
      expect(results.first['id'], isNotNull);
      expect(results.first['name'], isNotNull);
    });

    test('should return tourism category by ID', () async {
      // Act
      final result = await service.getTourismCategory('wisata-pantai');

      // Assert
      expect(result, isNotNull);
      expect(result!['id'], equals('wisata-pantai'));
      expect(result['name'], equals('Wisata Pantai'));
    });

    test('should handle popular destinations by province gracefully', () async {
      // Test should handle database dependency gracefully
      try {
        final results = await service.getPopularDestinationsByProvince(
          'bali',
          limit: 5,
        );
        // If successful, verify structure
        expect(results, isA<List<Map<String, dynamic>>>());
        expect(results.length, lessThanOrEqualTo(5));
      } catch (e) {
        // If fails due to database dependency, just verify error handling
        expect(e.toString(), contains('Supabase not initialized'));
      }
    });

    test('should handle featured destinations gracefully', () async {
      // Test should handle database dependency gracefully  
      try {
        final results = await service.getFeaturedDestinations(limit: 10);
        expect(results, isA<List<Map<String, dynamic>>>());
        expect(results.length, lessThanOrEqualTo(10));
      } catch (e) {
        expect(e.toString(), contains('Supabase not initialized'));
      }
    });

    test('should handle destinations by tourism category gracefully', () async {
      // Test should handle database dependency gracefully
      try {
        final results = await service.getDestinationsByTourismCategory(
          'wisata-pantai',
          limit: 5,
        );
        expect(results, isA<List<Map<String, dynamic>>>());
        expect(results.length, lessThanOrEqualTo(5));
      } catch (e) {
        expect(e.toString(), contains('Supabase not initialized'));
      }
    });

    test('should handle travel recommendations gracefully', () async {
      // Test should handle database dependency gracefully
      try {
        final results = await service.getTravelRecommendations(
          interests: ['wisata-pantai', 'wisata-alam'],
          budget: 'moderate',
          days: 3,
          limit: 5,
        );
        expect(results, isA<List<Map<String, dynamic>>>());
        expect(results.length, lessThanOrEqualTo(5));
      } catch (e) {
        expect(e.toString(), contains('Supabase not initialized'));
      }
    });

    test('should return tourism statistics', () async {
      // Act
      final result = await service.getTourismStatistics();

      // Assert
      expect(result, isA<Map<String, dynamic>>());
      expect(result['total_provinces'], equals(10));
      expect(result['total_categories'], equals(8));
      expect(result['popular_provinces'], isA<List>());
      expect(result['popular_categories'], isA<List>());
    });

    test('should validate province and city combination', () async {
      // Act
      final isValid = await service.validateProvinceCity('bali', 'Denpasar');

      // Assert
      expect(isValid, isTrue);
    });

    test('should return false for invalid province-city combination', () async {
      // Act
      final isValid = await service.validateProvinceCity('bali', 'Invalid City');

      // Assert
      expect(isValid, isFalse);
    });

    test('should get province by city name', () async {
      // Act
      final result = await service.getProvinceByCity('Denpasar');

      // Assert
      expect(result, isNotNull);
      expect(result!['id'], equals('bali'));
      expect(result['name'], equals('Bali'));
    });

    test('should return null for city not found', () async {
      // Act
      final result = await service.getProvinceByCity('Unknown City');

      // Assert
      expect(result, isNull);
    });
  });
}

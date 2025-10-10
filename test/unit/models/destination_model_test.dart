import 'package:flutter_test/flutter_test.dart';
import 'package:relink/core/models/destination_model.dart';

void main() {
  group('Destination Model', () {
    late Destination destination;

    setUp(() {
      destination = Destination(
        id: 'test-id',
        name: 'Test Destination',
        description: 'Test description',
        location: 'Test Location',
        latitude: -8.409518,
        longitude: 115.188919,
        category: 'beach',
        images: ['image1.jpg', 'image2.jpg'],
        priceRange: 3.0,
        rating: 4.5,
        reviewCount: 100,
        facilities: ['WiFi', 'Parking'],
        activities: ['Swimming', 'Surfing'],
        openingHours: '08:00 - 18:00',
        bestTimeToVisit: 'April - October',
        isVerified: true,
        createdBy: 'user-123',
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 10),
      );
    });

    test('should create destination with all fields', () {
      expect(destination.id, equals('test-id'));
      expect(destination.name, equals('Test Destination'));
      expect(destination.priceRange, equals(3.0));
      expect(destination.rating, equals(4.5));
      expect(destination.reviewCount, equals(100));
    });

    test('should return correct price range text', () {
      final budget = Destination(
        id: '1',
        name: 'Budget',
        description: '',
        location: '',
        latitude: 0,
        longitude: 0,
        category: '',
        images: [],
        priceRange: 1.0,
        rating: 0,
        reviewCount: 0,
        facilities: [],
        activities: [],
        openingHours: '',
        bestTimeToVisit: '',
        isVerified: false,
        createdBy: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(budget.priceRangeText, equals('Budget'));
      expect(destination.priceRangeText, equals('Moderate'));
    });

    test('should return correct price range symbol', () {
      expect(destination.priceRangeSymbol, equals('\$\$\$'));
    });

    test('should convert to map correctly', () {
      final map = destination.toMap();

      expect(map['id'], equals('test-id'));
      expect(map['name'], equals('Test Destination'));
      expect(map['priceRange'], equals(3.0));
      expect(map['images'], isA<List>());
      expect(map['facilities'], isA<List>());
    });

    test('should create from map correctly', () {
      final map = destination.toMap();
      final fromMap = Destination.fromMap(map);

      expect(fromMap.id, equals(destination.id));
      expect(fromMap.name, equals(destination.name));
      expect(fromMap.priceRange, equals(destination.priceRange));
    });

    test('should copy with updated fields', () {
      final updated = destination.copyWith(
        name: 'Updated Name',
        rating: 5.0,
      );

      expect(updated.name, equals('Updated Name'));
      expect(updated.rating, equals(5.0));
      expect(updated.id, equals(destination.id)); // Unchanged
    });
  });

  group('DestinationCategory', () {
    test('should have correct display names', () {
      expect(DestinationCategory.beach.displayName, equals('Beach'));
      expect(DestinationCategory.mountain.displayName, equals('Mountain'));
      expect(DestinationCategory.cultural.displayName, equals('Cultural'));
    });

    test('should parse from string correctly', () {
      expect(
        DestinationCategory.fromString('beach'),
        equals(DestinationCategory.beach),
      );
      expect(
        DestinationCategory.fromString('invalid'),
        equals(DestinationCategory.other),
      );
    });
  });

  group('DestinationFilter', () {
    test('should detect active filters', () {
      final noFilters = DestinationFilter();
      expect(noFilters.hasActiveFilters, isFalse);

      final withFilters = DestinationFilter(category: 'beach');
      expect(withFilters.hasActiveFilters, isTrue);
    });

    test('should copy with updated fields', () {
      final filter = DestinationFilter(category: 'beach');
      final updated = filter.copyWith(minRating: 4.0);

      expect(updated.category, equals('beach'));
      expect(updated.minRating, equals(4.0));
    });
  });
}

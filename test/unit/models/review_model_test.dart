import 'package:flutter_test/flutter_test.dart';
import 'package:relink/core/stubs/firebase_stubs.dart';
import 'package:mockito/mockito.dart';
import 'package:relink/core/models/review_model.dart';
import '../../test_setup.dart';

class MockDocumentSnapshot extends Mock implements DocumentSnapshot {
  @override
  String get id => super.noSuchMethod(Invocation.getter(#id), returnValue: '');
  
  @override
  Map<String, dynamic>? data() => super.noSuchMethod(
    Invocation.method(#data, []),
    returnValue: <String, dynamic>{},
  );
}

void main() {
  setUpAll(() async {
    await setupTestEnvironment();
  });

  group('Review Model', () {
    late Review review;
    late DateTime now;

    setUp(() {
      now = DateTime.now();
      review = Review(
        id: 'review123',
        destinationId: 'dest123',
        destinationName: 'Bali Beach',
        userId: 'user123',
        userName: 'Test User',
        userPhotoUrl: 'https://example.com/photo.jpg',
        rating: 4.5,
        title: 'Amazing Experience',
        content: 'This place was absolutely wonderful! Highly recommended.',
        photoUrls: [
          'https://example.com/photo1.jpg',
          'https://example.com/photo2.jpg',
        ],
        createdAt: now,
        updatedAt: now,
        helpfulCount: 10,
        helpfulUserIds: ['user456', 'user789'],
      );
    });

    test('should create review with rating and text', () {
      final simpleReview = Review(
        id: 'review124',
        destinationId: 'dest123',
        destinationName: 'Bali Beach',
        userId: 'user123',
        userName: 'Test User',
        rating: 5.0,
        title: 'Excellent!',
        content: 'Best destination ever!',
        createdAt: now,
        updatedAt: now,
      );

      expect(simpleReview.rating, equals(5.0));
      expect(simpleReview.title, equals('Excellent!'));
      expect(simpleReview.content, equals('Best destination ever!'));
    });

    test('should validate rating range - minimum', () {
      final lowRating = Review(
        id: 'review125',
        destinationId: 'dest123',
        destinationName: 'Bali Beach',
        userId: 'user123',
        userName: 'Test User',
        rating: 1.0,
        title: 'Poor',
        content: 'Not good',
        createdAt: now,
        updatedAt: now,
      );

      expect(lowRating.rating, equals(1.0));
      expect(lowRating.rating, greaterThanOrEqualTo(1.0));
    });

    test('should validate rating range - maximum', () {
      final highRating = Review(
        id: 'review126',
        destinationId: 'dest123',
        destinationName: 'Bali Beach',
        userId: 'user123',
        userName: 'Test User',
        rating: 5.0,
        title: 'Perfect',
        content: 'Absolutely perfect!',
        createdAt: now,
        updatedAt: now,
      );

      expect(highRating.rating, equals(5.0));
      expect(highRating.rating, lessThanOrEqualTo(5.0));
    });

    test('should validate rating range - mid range', () {
      final midRating = Review(
        id: 'review127',
        destinationId: 'dest123',
        destinationName: 'Bali Beach',
        userId: 'user123',
        userName: 'Test User',
        rating: 3.5,
        title: 'Good',
        content: 'Pretty good overall',
        createdAt: now,
        updatedAt: now,
      );

      expect(midRating.rating, equals(3.5));
      expect(midRating.rating, greaterThanOrEqualTo(1.0));
      expect(midRating.rating, lessThanOrEqualTo(5.0));
    });

    test('should create review with photos', () {
      expect(review.photoUrls.length, equals(2));
      expect(review.photoUrls[0], equals('https://example.com/photo1.jpg'));
      expect(review.photoUrls[1], equals('https://example.com/photo2.jpg'));
    });

    test('should create review without photos', () {
      final reviewWithoutPhotos = Review(
        id: 'review128',
        destinationId: 'dest123',
        destinationName: 'Bali Beach',
        userId: 'user123',
        userName: 'Test User',
        rating: 4.0,
        title: 'Good',
        content: 'Nice place',
        createdAt: now,
        updatedAt: now,
      );

      expect(reviewWithoutPhotos.photoUrls, isEmpty);
    });

    test('should track helpful count', () {
      expect(review.helpfulCount, equals(10));
      expect(review.helpfulUserIds.length, equals(2));
    });

    test('should check if user marked review as helpful', () {
      expect(review.isMarkedHelpfulBy('user456'), isTrue);
      expect(review.isMarkedHelpfulBy('user789'), isTrue);
      expect(review.isMarkedHelpfulBy('user999'), isFalse);
    });

    test('should convert to Supabase correctly', () {
      final supabaseMap = review.toSupabase();

      expect(supabaseMap['destination_id'], equals('dest123'));
      expect(supabaseMap['destination_name'], equals('Bali Beach'));
      expect(supabaseMap['user_id'], equals('user123'));
      expect(supabaseMap['user_name'], equals('Test User'));
      expect(supabaseMap['rating'], equals(4.5));
      expect(supabaseMap['title'], equals('Amazing Experience'));
      expect(supabaseMap['content'], contains('wonderful'));
      expect(supabaseMap['photo_urls'], isA<List>());
      expect(supabaseMap['helpful_count'], equals(10));
      expect(supabaseMap['created_at'], isA<String>());
      expect(supabaseMap['updated_at'], isA<String>());
    });

    test('should create from Supabase correctly', () {
      final supabaseMap = {
        'id': 'review456',
        'destination_id': 'dest456',
        'destination_name': 'Mountain Resort',
        'user_id': 'user456',
        'user_name': 'Another User',
        'user_photo_url': 'https://example.com/user456.jpg',
        'rating': 3.5,
        'title': 'Nice Stay',
        'content': 'Enjoyed my time here',
        'photo_urls': ['https://example.com/photo3.jpg'],
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
        'helpful_count': 5,
        'helpful_user_ids': ['user123'],
      };

      final fromSupabase = Review.fromSupabase(supabaseMap);

      expect(fromSupabase.id, equals('review456'));
      expect(fromSupabase.destinationId, equals('dest456'));
      expect(fromSupabase.rating, equals(3.5));
      expect(fromSupabase.title, equals('Nice Stay'));
      expect(fromSupabase.helpfulCount, equals(5));
    });

    test('should convert to Map for offline cache correctly', () {
      final map = review.toMap();

      expect(map['id'], equals('review123'));
      expect(map['destinationId'], equals('dest123'));
      expect(map['rating'], equals(4.5));
      expect(map['createdAt'], isA<String>());
      expect(map['updatedAt'], isA<String>());
    });

    test('should create from Map for offline cache correctly', () {
      final map = {
        'id': 'review789',
        'destinationId': 'dest789',
        'destinationName': 'City Center',
        'userId': 'user789',
        'userName': 'User Three',
        'userPhotoUrl': 'https://example.com/user789.jpg',
        'rating': 4.0,
        'title': 'Great Location',
        'content': 'Perfect spot in the city',
        'photoUrls': [],
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
        'helpfulCount': 2,
        'helpfulUserIds': ['user123', 'user456'],
      };

      final fromMap = Review.fromMap(map);

      expect(fromMap.id, equals('review789'));
      expect(fromMap.destinationId, equals('dest789'));
      expect(fromMap.rating, equals(4.0));
      expect(fromMap.title, equals('Great Location'));
      expect(fromMap.helpfulCount, equals(2));
    });

    test('should copy with updated fields', () {
      final updatedReview = review.copyWith(
        title: 'Updated Title',
        content: 'Updated content',
        rating: 5.0,
        helpfulCount: 15,
      );

      expect(updatedReview.id, equals(review.id));
      expect(updatedReview.title, equals('Updated Title'));
      expect(updatedReview.content, equals('Updated content'));
      expect(updatedReview.rating, equals(5.0));
      expect(updatedReview.helpfulCount, equals(15));
      expect(updatedReview.destinationId, equals(review.destinationId));
    });

    test('should handle review without user photo', () {
      final reviewWithoutPhoto = Review(
        id: 'review129',
        destinationId: 'dest123',
        destinationName: 'Bali Beach',
        userId: 'user123',
        userName: 'Test User',
        rating: 4.0,
        title: 'Good',
        content: 'Nice place',
        createdAt: now,
        updatedAt: now,
      );

      expect(reviewWithoutPhoto.userPhotoUrl, isNull);
    });

    test('should handle empty helpful users list', () {
      final reviewWithNoHelpful = Review(
        id: 'review130',
        destinationId: 'dest123',
        destinationName: 'Bali Beach',
        userId: 'user123',
        userName: 'Test User',
        rating: 4.0,
        title: 'Good',
        content: 'Nice place',
        createdAt: now,
        updatedAt: now,
        helpfulCount: 0,
        helpfulUserIds: [],
      );

      expect(reviewWithNoHelpful.helpfulCount, equals(0));
      expect(reviewWithNoHelpful.helpfulUserIds, isEmpty);
      expect(reviewWithNoHelpful.isMarkedHelpfulBy('user123'), isFalse);
    });
  });

  group('RatingSummary Model', () {
    late RatingSummary summary;

    setUp(() {
      summary = RatingSummary(
        destinationId: 'dest123',
        averageRating: 4.2,
        totalReviews: 100,
        ratingDistribution: {1: 5, 2: 10, 3: 15, 4: 30, 5: 40},
      );
    });

    test('should create rating summary', () {
      expect(summary.destinationId, equals('dest123'));
      expect(summary.averageRating, equals(4.2));
      expect(summary.totalReviews, equals(100));
    });

    test('should get percentage for each star rating', () {
      expect(summary.getPercentage(5), equals(40.0));
      expect(summary.getPercentage(4), equals(30.0));
      expect(summary.getPercentage(3), equals(15.0));
      expect(summary.getPercentage(2), equals(10.0));
      expect(summary.getPercentage(1), equals(5.0));
    });

    test('should get count for specific star rating', () {
      expect(summary.getCount(5), equals(40));
      expect(summary.getCount(4), equals(30));
      expect(summary.getCount(3), equals(15));
      expect(summary.getCount(2), equals(10));
      expect(summary.getCount(1), equals(5));
    });

    test('should handle zero reviews', () {
      final emptySummary = RatingSummary(
        destinationId: 'dest456',
        averageRating: 0.0,
        totalReviews: 0,
        ratingDistribution: {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
      );

      expect(emptySummary.getPercentage(5), equals(0.0));
      expect(emptySummary.getPercentage(1), equals(0.0));
    });

    test('should convert to Supabase correctly', () {
      final supabaseMap = summary.toSupabase();

      expect(supabaseMap['average_rating'], equals(4.2));
      expect(supabaseMap['total_reviews'], equals(100));
      expect(supabaseMap['rating_distribution'], isA<Map>());
      expect(supabaseMap['updated_at'], isA<String>());
    });

    test('should create from Supabase correctly', () {
      final supabaseMap = {
        'destination_id': 'dest123',
        'average_rating': 4.2,
        'total_reviews': 100,
        'rating_distribution': {1: 5, 2: 10, 3: 15, 4: 30, 5: 40},
      };

      final fromSupabase = RatingSummary.fromSupabase(supabaseMap);

      expect(fromSupabase.destinationId, equals('dest123'));
      expect(fromSupabase.averageRating, equals(4.2));
      expect(fromSupabase.totalReviews, equals(100));
    });
  });

  group('ReviewFilter Enum', () {
    test('should have all filter options', () {
      expect(ReviewFilter.values.length, equals(4));
      expect(ReviewFilter.values.contains(ReviewFilter.mostRecent), isTrue);
      expect(ReviewFilter.values.contains(ReviewFilter.highestRated), isTrue);
      expect(ReviewFilter.values.contains(ReviewFilter.lowestRated), isTrue);
      expect(ReviewFilter.values.contains(ReviewFilter.mostHelpful), isTrue);
    });
  });

  group('ReviewSortHelper', () {
    test('should return correct Firestore field for each filter', () {
      expect(
        ReviewSortHelper.getFirestoreField(ReviewFilter.mostRecent),
        equals('createdAt'),
      );
      expect(
        ReviewSortHelper.getFirestoreField(ReviewFilter.highestRated),
        equals('rating'),
      );
      expect(
        ReviewSortHelper.getFirestoreField(ReviewFilter.lowestRated),
        equals('rating'),
      );
      expect(
        ReviewSortHelper.getFirestoreField(ReviewFilter.mostHelpful),
        equals('helpfulCount'),
      );
    });

    test('should return correct sort direction', () {
      expect(ReviewSortHelper.isDescending(ReviewFilter.mostRecent), isTrue);
      expect(ReviewSortHelper.isDescending(ReviewFilter.highestRated), isTrue);
      expect(ReviewSortHelper.isDescending(ReviewFilter.lowestRated), isFalse);
      expect(ReviewSortHelper.isDescending(ReviewFilter.mostHelpful), isTrue);
    });

    test('should return correct label for each filter', () {
      expect(
        ReviewSortHelper.getLabel(ReviewFilter.mostRecent),
        equals('Most Recent'),
      );
      expect(
        ReviewSortHelper.getLabel(ReviewFilter.highestRated),
        equals('Highest Rated'),
      );
      expect(
        ReviewSortHelper.getLabel(ReviewFilter.lowestRated),
        equals('Lowest Rated'),
      );
      expect(
        ReviewSortHelper.getLabel(ReviewFilter.mostHelpful),
        equals('Most Helpful'),
      );
    });
  });
}

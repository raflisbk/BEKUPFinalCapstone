import 'package:flutter_test/flutter_test.dart';
import 'package:relink/core/models/user_model.dart';
import '../../test_setup.dart';

void main() {
  setUpAll(() async {
    await setupTestEnvironment();
  });

  group('UserModel', () {
    late UserModel user;
    late DateTime now;

    setUp(() {
      now = DateTime.now();
      user = UserModel(
        uid: 'user123',
        email: 'test@example.com',
        displayName: 'Test User',
        photoUrl: 'https://example.com/photo.jpg',
        bio: 'Travel enthusiast',
        interests: ['travel', 'photography'],
        languages: ['English', 'Indonesian'],
        isGuide: false,
        isVerified: false,
        rating: 4.5,
        reviewCount: 10,
        createdAt: now,
        updatedAt: now,
      );
    });

    test('should create user with all required fields', () {
      expect(user.uid, equals('user123'));
      expect(user.email, equals('test@example.com'));
      expect(user.displayName, equals('Test User'));
      expect(user.photoUrl, equals('https://example.com/photo.jpg'));
      expect(user.bio, equals('Travel enthusiast'));
      expect(user.interests, equals(['travel', 'photography']));
      expect(user.languages, equals(['English', 'Indonesian']));
      expect(user.isGuide, isFalse);
      expect(user.isVerified, isFalse);
      expect(user.rating, equals(4.5));
      expect(user.reviewCount, equals(10));
    });

    test('should create guide user with guide-specific fields', () {
      final guide = UserModel(
        uid: 'guide123',
        email: 'guide@example.com',
        displayName: 'Guide User',
        bio: 'Professional guide',
        interests: ['tourism', 'history'],
        languages: ['English', 'Indonesian', 'Japanese'],
        isGuide: true,
        isVerified: true,
        rating: 4.8,
        reviewCount: 50,
        expertise: 'Cultural tours',
        pricePerDay: 100.0,
        specializations: ['temples', 'museums'],
        yearsOfExperience: 5,
        toursCompleted: 120,
        createdAt: now,
        updatedAt: now,
      );

      expect(guide.isGuide, isTrue);
      expect(guide.isVerified, isTrue);
      expect(guide.expertise, equals('Cultural tours'));
      expect(guide.pricePerDay, equals(100.0));
      expect(guide.specializations, equals(['temples', 'museums']));
      expect(guide.yearsOfExperience, equals(5));
      expect(guide.toursCompleted, equals(120));
    });

    test('should convert to map correctly', () {
      final map = user.toMap();

      expect(map['id'], equals('user123'));
      expect(map['email'], equals('test@example.com'));
      expect(map['display_name'], equals('Test User'));
      expect(map['photo_url'], equals('https://example.com/photo.jpg'));
      expect(map['bio'], equals('Travel enthusiast'));
      expect(map['interests'], equals(['travel', 'photography']));
      expect(map['languages'], equals(['English', 'Indonesian']));
      expect(map['is_guide'], isFalse);
      expect(map['is_verified'], isFalse);
      expect(map['rating'], equals(4.5));
      expect(map['review_count'], equals(10));
    });

    test('should create from map correctly', () {
      final map = {
        'uid': 'frommap123',
        'email': 'frommap@example.com',
        'displayName': 'Map User',
        'photoUrl': 'https://example.com/map.jpg',
        'bio': 'Created from map',
        'interests': ['hiking', 'camping'],
        'languages': ['English'],
        'isGuide': true,
        'isVerified': true,
        'rating': 4.2,
        'reviewCount': 25,
        'expertise': 'Mountain hiking',
        'pricePerDay': 80.0,
        'specializations': ['mountains', 'trekking'],
        'yearsOfExperience': 3,
        'toursCompleted': 75,
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      };

      final userFromMap = UserModel.fromMap(map);

      expect(userFromMap.uid, equals('frommap123'));
      expect(userFromMap.email, equals('frommap@example.com'));
      expect(userFromMap.displayName, equals('Map User'));
      expect(userFromMap.bio, equals('Created from map'));
      expect(userFromMap.interests, equals(['hiking', 'camping']));
      expect(userFromMap.isGuide, isTrue);
      expect(userFromMap.expertise, equals('Mountain hiking'));
    });

    test('should create from Supabase data correctly', () {
      final supabaseData = {
        'id': 'supabase123',
        'email': 'supabase@example.com',
        'display_name': 'Supabase User',
        'photo_url': 'https://example.com/supabase.jpg',
        'bio': 'Created from Supabase',
        'interests': ['nature', 'adventure'],
        'languages': ['English', 'Spanish'],
        'is_guide': true,
        'is_verified': true,
        'rating': 4.7,
        'review_count': 30,
        'expertise': 'Adventure tours',
        'price_per_day': 120.0,
        'specializations': ['hiking', 'climbing'],
        'years_of_experience': 7,
        'tours_completed': 150,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      final userFromSupabase = UserModel.fromSupabase(supabaseData);

      expect(userFromSupabase.uid, equals('supabase123'));
      expect(userFromSupabase.email, equals('supabase@example.com'));
      expect(userFromSupabase.displayName, equals('Supabase User'));
      expect(userFromSupabase.bio, equals('Created from Supabase'));
      expect(userFromSupabase.interests, equals(['nature', 'adventure']));
      expect(userFromSupabase.isGuide, isTrue);
      expect(userFromSupabase.expertise, equals('Adventure tours'));
      expect(userFromSupabase.pricePerDay, equals(120.0));
    });

    test('should copy with updated fields', () {
      final updatedUser = user.copyWith(
        displayName: 'Updated Name',
        bio: 'Updated bio',
        rating: 4.8,
      );

      expect(updatedUser.uid, equals('user123'));
      expect(updatedUser.email, equals('test@example.com'));
      expect(updatedUser.displayName, equals('Updated Name'));
      expect(updatedUser.bio, equals('Updated bio'));
      expect(updatedUser.rating, equals(4.8));
      expect(updatedUser.reviewCount, equals(10)); // Unchanged
    });

    test('should handle location fields correctly', () {
      final userWithLocation = user.copyWith(
        latitude: -7.797068,
        longitude: 110.370529,
        currentLocation: 'Yogyakarta, Indonesia',
        isLocationShared: true,
      );

      expect(userWithLocation.latitude, equals(-7.797068));
      expect(userWithLocation.longitude, equals(110.370529));
      expect(userWithLocation.currentLocation, equals('Yogyakarta, Indonesia'));
      expect(userWithLocation.isLocationShared, isTrue);
    });

    test('should handle default values for optional guide fields', () {
      expect(user.expertise, isNull);
      expect(user.pricePerDay, isNull);
      expect(user.specializations, isNull);
      expect(user.yearsOfExperience, isNull);
      expect(user.toursCompleted, isNull);
    });

    test('should handle default values for optional location fields', () {
      expect(user.latitude, isNull);
      expect(user.longitude, isNull);
      expect(user.currentLocation, isNull);
      expect(user.isLocationShared, isNull);
    });

    test('should convert to JSON correctly', () {
      final json = user.toJson();

      expect(json['uid'], equals('user123'));
      expect(json['email'], equals('test@example.com'));
      expect(json['displayName'], equals('Test User'));
      expect(json['photoUrl'], equals('https://example.com/photo.jpg'));
      expect(json['bio'], equals('Travel enthusiast'));
      expect(json['interests'], equals(['travel', 'photography']));
      expect(json['languages'], equals(['English', 'Indonesian']));
      expect(json['isGuide'], isFalse);
      expect(json['isVerified'], isFalse);
      expect(json['rating'], equals(4.5));
      expect(json['reviewCount'], equals(10));
      expect(json['createdAt'], isA<String>());
      expect(json['updatedAt'], isA<String>());
    });

    test('should create from JSON correctly', () {
      final json = {
        'uid': 'json123',
        'email': 'json@example.com',
        'displayName': 'JSON User',
        'photoUrl': 'https://example.com/json.jpg',
        'bio': 'Created from JSON',
        'interests': ['reading', 'writing'],
        'languages': ['English', 'French'],
        'isGuide': false,
        'isVerified': false,
        'rating': 4.3,
        'reviewCount': 15,
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      };

      final userFromJson = UserModel.fromJson(json);

      expect(userFromJson.uid, equals('json123'));
      expect(userFromJson.email, equals('json@example.com'));
      expect(userFromJson.displayName, equals('JSON User'));
      expect(userFromJson.bio, equals('Created from JSON'));
      expect(userFromJson.interests, equals(['reading', 'writing']));
      expect(userFromJson.isGuide, isFalse);
    });

    test('should have convenience getters', () {
      expect(user.id, equals(user.uid));
      expect(user.name, equals(user.displayName));
    });

    test('should implement equality correctly', () {
      final user1 = UserModel(
        uid: 'same123',
        email: 'user1@example.com',
        displayName: 'User 1',
        bio: 'Bio 1',
        interests: [],
        languages: [],
        isGuide: false,
        isVerified: false,
        rating: 0.0,
        reviewCount: 0,
        createdAt: now,
        updatedAt: now,
      );

      final user2 = UserModel(
        uid: 'same123',
        email: 'user2@example.com',
        displayName: 'User 2',
        bio: 'Bio 2',
        interests: [],
        languages: [],
        isGuide: false,
        isVerified: false,
        rating: 0.0,
        reviewCount: 0,
        createdAt: now,
        updatedAt: now,
      );

      final user3 = UserModel(
        uid: 'different123',
        email: 'user3@example.com',
        displayName: 'User 3',
        bio: 'Bio 3',
        interests: [],
        languages: [],
        isGuide: false,
        isVerified: false,
        rating: 0.0,
        reviewCount: 0,
        createdAt: now,
        updatedAt: now,
      );

      expect(user1, equals(user2)); // Same uid
      expect(user1, isNot(equals(user3))); // Different uid
      expect(user1.hashCode, equals(user2.hashCode));
    });

    test('should have proper toString method', () {
      final userString = user.toString();
      expect(userString, contains('UserModel'));
      expect(userString, contains('user123'));
      expect(userString, contains('Test User'));
      expect(userString, contains('test@example.com'));
      expect(userString, contains('false')); // isGuide
    });
  });
}

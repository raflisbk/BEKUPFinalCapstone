import 'package:flutter_test/flutter_test.dart';
import 'package:relink/core/models/friend_model.dart';
import '../../test_setup.dart';

void main() {
  setUpAll(() async {
    await setupTestEnvironment();
  });

  group('FriendRequestStatusHelper', () {
    test('should return correct labels for each status', () {
      expect(FriendRequestStatusHelper.getLabel(FriendRequestStatus.pending), 'Pending');
      expect(FriendRequestStatusHelper.getLabel(FriendRequestStatus.accepted), 'Accepted');
      expect(FriendRequestStatusHelper.getLabel(FriendRequestStatus.declined), 'Declined');
    });

    test('should return correct values for each status', () {
      expect(FriendRequestStatusHelper.getValue(FriendRequestStatus.pending), 'pending');
      expect(FriendRequestStatusHelper.getValue(FriendRequestStatus.accepted), 'accepted');
      expect(FriendRequestStatusHelper.getValue(FriendRequestStatus.declined), 'declined');
    });

    test('should convert string to enum correctly', () {
      expect(FriendRequestStatusHelper.fromString('pending'), FriendRequestStatus.pending);
      expect(FriendRequestStatusHelper.fromString('accepted'), FriendRequestStatus.accepted);
      expect(FriendRequestStatusHelper.fromString('declined'), FriendRequestStatus.declined);
      expect(FriendRequestStatusHelper.fromString('invalid'), FriendRequestStatus.pending);
    });
  });

  group('FriendActivityTypeHelper', () {
    test('should return correct labels for each type', () {
      expect(FriendActivityTypeHelper.getLabel(FriendActivityType.photoUpload), 'Photo Upload');
      expect(FriendActivityTypeHelper.getLabel(FriendActivityType.tripCreated), 'Trip Created');
      expect(FriendActivityTypeHelper.getLabel(FriendActivityType.destinationVisited), 'Destination Visited');
      expect(FriendActivityTypeHelper.getLabel(FriendActivityType.reviewPosted), 'Review Posted');
      expect(FriendActivityTypeHelper.getLabel(FriendActivityType.tripCompleted), 'Trip Completed');
      expect(FriendActivityTypeHelper.getLabel(FriendActivityType.friendAdded), 'Friend Added');
      expect(FriendActivityTypeHelper.getLabel(FriendActivityType.statusUpdate), 'Status Update');
      expect(FriendActivityTypeHelper.getLabel(FriendActivityType.other), 'Other');
    });

    test('should return correct values for each type', () {
      expect(FriendActivityTypeHelper.getValue(FriendActivityType.photoUpload), 'photo_upload');
      expect(FriendActivityTypeHelper.getValue(FriendActivityType.tripCreated), 'trip_created');
      expect(FriendActivityTypeHelper.getValue(FriendActivityType.destinationVisited), 'destination_visited');
      expect(FriendActivityTypeHelper.getValue(FriendActivityType.reviewPosted), 'review_posted');
      expect(FriendActivityTypeHelper.getValue(FriendActivityType.tripCompleted), 'trip_completed');
      expect(FriendActivityTypeHelper.getValue(FriendActivityType.friendAdded), 'friend_added');
      expect(FriendActivityTypeHelper.getValue(FriendActivityType.statusUpdate), 'status_update');
      expect(FriendActivityTypeHelper.getValue(FriendActivityType.other), 'other');
    });

    test('should convert string to enum correctly', () {
      expect(FriendActivityTypeHelper.fromString('photo_upload'), FriendActivityType.photoUpload);
      expect(FriendActivityTypeHelper.fromString('trip_created'), FriendActivityType.tripCreated);
      expect(FriendActivityTypeHelper.fromString('destination_visited'), FriendActivityType.destinationVisited);
      expect(FriendActivityTypeHelper.fromString('review_posted'), FriendActivityType.reviewPosted);
      expect(FriendActivityTypeHelper.fromString('trip_completed'), FriendActivityType.tripCompleted);
      expect(FriendActivityTypeHelper.fromString('friend_added'), FriendActivityType.friendAdded);
      expect(FriendActivityTypeHelper.fromString('status_update'), FriendActivityType.statusUpdate);
      expect(FriendActivityTypeHelper.fromString('other'), FriendActivityType.other);
      expect(FriendActivityTypeHelper.fromString('invalid'), FriendActivityType.other);
    });
  });

  group('FriendRequest Model', () {
    late FriendRequest friendRequest;
    late DateTime now;

    setUp(() {
      now = DateTime.now();
      friendRequest = FriendRequest(
        id: 'req123',
        senderId: 'user123',
        receiverId: 'user456',
        status: 'pending',
        createdAt: now,
        respondedAt: null,
      );
    });

    test('should create friend request with all required fields', () {
      expect(friendRequest.id, equals('req123'));
      expect(friendRequest.senderId, equals('user123'));
      expect(friendRequest.receiverId, equals('user456'));
      expect(friendRequest.status, equals('pending'));
      expect(friendRequest.createdAt, equals(now));
      expect(friendRequest.respondedAt, isNull);
    });

    test('should create from map correctly', () {
      final map = {
        'id': 'req124',
        'sender_id': 'user789',
        'receiver_id': 'user456',
        'status': 'accepted',
        'created_at': '2025-10-01T10:00:00.000Z',
        'responded_at': '2025-10-01T10:30:00.000Z',
      };

      final fromMap = FriendRequest.fromMap(map);

      expect(fromMap.id, equals('req124'));
      expect(fromMap.senderId, equals('user789'));
      expect(fromMap.receiverId, equals('user456'));
      expect(fromMap.status, equals('accepted'));
      expect(fromMap.createdAt, isA<DateTime>());
      expect(fromMap.respondedAt, isNotNull);
    });

    test('should convert to map correctly', () {
      final respondedAt = now.add(const Duration(minutes: 30));
      final request = friendRequest.copyWith(
        status: 'accepted',
        respondedAt: respondedAt,
      );

      final map = request.toMap();

      expect(map['id'], equals('req123'));
      expect(map['sender_id'], equals('user123'));
      expect(map['receiver_id'], equals('user456'));
      expect(map['status'], equals('accepted'));
      expect(map['created_at'], isA<String>());
      expect(map['responded_at'], isA<String>());
    });

    test('should copy with modifications', () {
      final respondedAt = now.add(const Duration(minutes: 30));
      final updated = friendRequest.copyWith(
        status: 'accepted',
        respondedAt: respondedAt,
      );

      expect(updated.id, equals(friendRequest.id));
      expect(updated.senderId, equals(friendRequest.senderId));
      expect(updated.receiverId, equals(friendRequest.receiverId));
      expect(updated.status, equals('accepted'));
      expect(updated.respondedAt, equals(respondedAt));
    });

    test('should handle missing optional fields in fromMap', () {
      final map = {
        'id': 'req125',
        'sender_id': 'user111',
        'receiver_id': 'user222',
        'status': 'pending',
        'created_at': '2025-10-01T10:00:00.000Z',
        // responded_at is null
      };

      final fromMap = FriendRequest.fromMap(map);

      expect(fromMap.respondedAt, isNull);
      expect(fromMap.status, equals('pending'));
    });

    test('should return correct status enum', () {
      final pending = friendRequest.copyWith(status: 'pending');
      final accepted = friendRequest.copyWith(status: 'accepted');
      final declined = friendRequest.copyWith(status: 'declined');

      expect(pending.statusEnum, FriendRequestStatus.pending);
      expect(accepted.statusEnum, FriendRequestStatus.accepted);
      expect(declined.statusEnum, FriendRequestStatus.declined);
    });

    test('should check status correctly', () {
      final pending = friendRequest.copyWith(status: 'pending');
      final accepted = friendRequest.copyWith(status: 'accepted');
      final declined = friendRequest.copyWith(status: 'declined');

      expect(pending.isPending, true);
      expect(pending.isAccepted, false);
      expect(pending.isDeclined, false);

      expect(accepted.isPending, false);
      expect(accepted.isAccepted, true);
      expect(accepted.isDeclined, false);

      expect(declined.isPending, false);
      expect(declined.isAccepted, false);
      expect(declined.isDeclined, true);
    });

    test('should implement equality correctly', () {
      final request1 = friendRequest.copyWith(id: 'same-id');
      final request2 = friendRequest.copyWith(id: 'same-id', status: 'accepted');
      final request3 = friendRequest.copyWith(id: 'different-id');

      expect(request1 == request2, true);
      expect(request1 == request3, false);
      expect(request1.hashCode, request2.hashCode);
    });

    test('should handle different status values', () {
      final statuses = ['pending', 'accepted', 'declined'];
      
      for (final status in statuses) {
        final request = friendRequest.copyWith(status: status);
        expect(request.status, equals(status));
      }
    });
  });

  group('Friendship Model', () {
    late Friendship friendship;
    late DateTime now;

    setUp(() {
      now = DateTime.now();
      friendship = Friendship(
        id: 'friend123',
        userId1: 'user123',
        userId2: 'user456',
        createdAt: now,
        isBlocked: false,
        blockedBy: null,
      );
    });

    test('should create friendship with all required fields', () {
      expect(friendship.id, equals('friend123'));
      expect(friendship.userId1, equals('user123'));
      expect(friendship.userId2, equals('user456'));
      expect(friendship.createdAt, equals(now));
      expect(friendship.isBlocked, isFalse);
      expect(friendship.blockedBy, isNull);
    });

    test('should create from map correctly', () {
      final map = {
        'id': 'friend124',
        'user_id_1': 'user789',
        'user_id_2': 'user456',
        'created_at': '2025-10-01T10:00:00.000Z',
        'is_blocked': false,
        'blocked_by': null,
      };

      final fromMap = Friendship.fromMap(map);

      expect(fromMap.id, equals('friend124'));
      expect(fromMap.userId1, equals('user789'));
      expect(fromMap.userId2, equals('user456'));
      expect(fromMap.createdAt, isA<DateTime>());
      expect(fromMap.isBlocked, isFalse);
      expect(fromMap.blockedBy, isNull);
    });

    test('should convert to map correctly', () {
      final map = friendship.toMap();

      expect(map['id'], equals('friend123'));
      expect(map['user_id_1'], equals('user123'));
      expect(map['user_id_2'], equals('user456'));
      expect(map['created_at'], isA<String>());
      expect(map['is_blocked'], isFalse);
      expect(map['blocked_by'], isNull);
    });

    test('should handle blocked friendship', () {
      final blocked = Friendship(
        id: 'friend125',
        userId1: 'user123',
        userId2: 'user456',
        createdAt: now,
        isBlocked: true,
        blockedBy: 'user123',
      );

      expect(blocked.isBlocked, isTrue);
      expect(blocked.blockedBy, equals('user123'));

      final map = blocked.toMap();
      expect(map['is_blocked'], isTrue);
      expect(map['blocked_by'], equals('user123'));
    });

    test('should handle friendship from map with blocking', () {
      final map = {
        'id': 'friend126',
        'user_id_1': 'user111',
        'user_id_2': 'user222',
        'created_at': '2025-10-01T10:00:00.000Z',
        'is_blocked': true,
        'blocked_by': 'user222',
      };

      final fromMap = Friendship.fromMap(map);

      expect(fromMap.isBlocked, isTrue);
      expect(fromMap.blockedBy, equals('user222'));
    });

    test('should get other user ID correctly', () {
      expect(friendship.getOtherUserId('user123'), 'user456');
      expect(friendship.getOtherUserId('user456'), 'user123');
    });

    test('should check if blocked by user correctly', () {
      final blocked = Friendship(
        id: 'friend125',
        userId1: 'user123',
        userId2: 'user456',
        createdAt: now,
        isBlocked: true,
        blockedBy: 'user123',
      );

      expect(blocked.isBlockedBy('user123'), true);
      expect(blocked.isBlockedBy('user456'), false);
      expect(friendship.isBlockedBy('user123'), false);
    });

    test('should check if involves user correctly', () {
      expect(friendship.involvesUser('user123'), true);
      expect(friendship.involvesUser('user456'), true);
      expect(friendship.involvesUser('user789'), false);
    });

    test('should handle blocked friendship', () {
      final blocked = Friendship(
        id: 'friend125',
        userId1: 'user123',
        userId2: 'user456',
        createdAt: now,
        isBlocked: true,
        blockedBy: 'user123',
      );

      expect(blocked.isBlocked, isTrue);
      expect(blocked.blockedBy, equals('user123'));

      final map = blocked.toMap();
      expect(map['is_blocked'], isTrue);
      expect(map['blocked_by'], equals('user123'));
    });

    test('should handle friendship from map with blocking', () {
      final map = {
        'id': 'friend126',
        'user_id_1': 'user111',
        'user_id_2': 'user222',
        'created_at': '2025-10-01T10:00:00.000Z',
        'is_blocked': true,
        'blocked_by': 'user222',
      };

      final fromMap = Friendship.fromMap(map);

      expect(fromMap.isBlocked, isTrue);
      expect(fromMap.blockedBy, equals('user222'));
    });

    test('should implement equality correctly', () {
      final friendship1 = Friendship(
        id: 'same-id',
        userId1: 'user123',
        userId2: 'user456',
        createdAt: now,
      );
      final friendship2 = Friendship(
        id: 'same-id',
        userId1: 'different',
        userId2: 'users',
        createdAt: DateTime.now(),
      );
      final friendship3 = Friendship(
        id: 'different-id',
        userId1: 'user123',
        userId2: 'user456',
        createdAt: now,
      );

      expect(friendship1 == friendship2, true);
      expect(friendship1 == friendship3, false);
      expect(friendship1.hashCode, friendship2.hashCode);
    });

    test('should handle default values in fromMap', () {
      final map = {
        'id': 'friend127',
        'user_id_1': 'user333',
        'user_id_2': 'user444',
        'created_at': '2025-10-01T10:00:00.000Z',
      };

      final fromMap = Friendship.fromMap(map);

      expect(fromMap.isBlocked, isFalse);
      expect(fromMap.blockedBy, isNull);
    });
  });

  group('FriendActivity Model', () {
    late FriendActivity activity;
    late DateTime now;

    setUp(() {
      now = DateTime.now();
      activity = FriendActivity(
        id: 'activity123',
        userId: 'user123',
        userName: 'John Doe',
        userPhotoUrl: 'https://example.com/photo.jpg',
        activityType: 'trip_created',
        title: 'Created a new trip to Bali',
        description: 'Exploring the beautiful beaches of Bali',
        metadata: {
          'trip_id': 'trip123',
          'destination': 'Bali',
          'duration': 7,
        },
        createdAt: now,
      );
    });

    test('should create friend activity with all fields', () {
      expect(activity.id, equals('activity123'));
      expect(activity.userId, equals('user123'));
      expect(activity.userName, equals('John Doe'));
      expect(activity.userPhotoUrl, equals('https://example.com/photo.jpg'));
      expect(activity.activityType, equals('trip_created'));
      expect(activity.title, equals('Created a new trip to Bali'));
      expect(activity.description, equals('Exploring the beautiful beaches of Bali'));
      expect(activity.metadata, isNotNull);
      expect(activity.metadata!['trip_id'], equals('trip123'));
      expect(activity.createdAt, equals(now));
    });

    test('should create from map correctly', () {
      final map = {
        'id': 'activity124',
        'user_id': 'user456',
        'user_name': 'Jane Smith',
        'user_photo_url': 'https://example.com/jane.jpg',
        'activity_type': 'photo_upload',
        'title': 'Shared beautiful sunset photos',
        'description': 'Amazing sunset at Tanah Lot temple',
        'metadata': {
          'photo_count': 5,
          'location': 'Tanah Lot',
        },
        'created_at': '2025-10-01T10:00:00.000Z',
      };

      final fromMap = FriendActivity.fromMap(map);

      expect(fromMap.id, equals('activity124'));
      expect(fromMap.userId, equals('user456'));
      expect(fromMap.userName, equals('Jane Smith'));
      expect(fromMap.userPhotoUrl, equals('https://example.com/jane.jpg'));
      expect(fromMap.activityType, equals('photo_upload'));
      expect(fromMap.title, equals('Shared beautiful sunset photos'));
      expect(fromMap.description, equals('Amazing sunset at Tanah Lot temple'));
      expect(fromMap.metadata, isNotNull);
      expect(fromMap.metadata!['photo_count'], equals(5));
      expect(fromMap.createdAt, isA<DateTime>());
    });

    test('should convert to map correctly', () {
      final map = activity.toMap();

      expect(map['id'], equals('activity123'));
      expect(map['user_id'], equals('user123'));
      expect(map['user_name'], equals('John Doe'));
      expect(map['user_photo_url'], equals('https://example.com/photo.jpg'));
      expect(map['activity_type'], equals('trip_created'));
      expect(map['title'], equals('Created a new trip to Bali'));
      expect(map['description'], equals('Exploring the beautiful beaches of Bali'));
      expect(map['metadata'], isNotNull);
      expect(map['metadata']['trip_id'], equals('trip123'));
      expect(map['created_at'], isA<String>());
    });

    test('should handle activity without optional fields', () {
      final minimal = FriendActivity(
        id: 'activity125',
        userId: 'user789',
        userName: 'Bob Wilson',
        activityType: 'destination_visited',
        title: 'Visited Mount Bromo',
        createdAt: now,
      );

      expect(minimal.userPhotoUrl, isNull);
      expect(minimal.description, isNull);
      expect(minimal.metadata, isNull);

      final map = minimal.toMap();
      expect(map['user_photo_url'], isNull);
      expect(map['description'], isNull);
      expect(map['metadata'], isNull);
    });

    test('should handle different activity types', () {
      final activityTypes = [
        'photo_upload',
        'trip_created',
        'destination_visited',
        'review_posted',
        'trip_completed',
        'friend_added',
      ];

      for (final type in activityTypes) {
        final testActivity = FriendActivity(
          id: 'test_$type',
          userId: 'user123',
          userName: 'Test User',
          activityType: type,
          title: 'Test $type activity',
          createdAt: now,
        );

        expect(testActivity.activityType, equals(type));
      }
    });

    test('should handle fromMap with missing optional fields', () {
      final map = {
        'id': 'activity126',
        'user_id': 'user999',
        'user_name': 'Minimal User',
        'activity_type': 'status_update',
        'title': 'Updated status',
        'created_at': '2025-10-01T10:00:00.000Z',
        // user_photo_url, description, metadata not provided
      };

      final fromMap = FriendActivity.fromMap(map);

      expect(fromMap.userPhotoUrl, isNull);
      expect(fromMap.description, isNull);
      expect(fromMap.metadata, isNull);
    });

    test('should return correct activity type enum', () {
      final photoActivity = FriendActivity(
        id: 'test',
        userId: 'user123',
        userName: 'Test User',
        activityType: 'photo_upload',
        title: 'Test activity',
        createdAt: DateTime.now(),
      );
      final tripActivity = FriendActivity(
        id: 'test2',
        userId: 'user123',
        userName: 'Test User',
        activityType: 'trip_created',
        title: 'Test activity',
        createdAt: DateTime.now(),
      );

      expect(photoActivity.activityTypeEnum, FriendActivityType.photoUpload);
      expect(tripActivity.activityTypeEnum, FriendActivityType.tripCreated);
    });

    test('should format time ago correctly', () {
      final recent = FriendActivity(
        id: 'test',
        userId: 'user123',
        userName: 'Test User',
        activityType: 'photo_upload',
        title: 'Test activity',
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
      );

      expect(recent.timeAgo, contains('30m ago'));
    });

    test('should check if has metadata correctly', () {
      final withMetadata = activity;
      final withoutMetadata = FriendActivity(
        id: 'test',
        userId: 'user123',
        userName: 'Test User',
        activityType: 'photo_upload',
        title: 'Test activity',
        createdAt: DateTime.now(),
      );

      expect(withMetadata.hasMetadata, true);
      expect(withoutMetadata.hasMetadata, false);
    });

    test('should handle activity without optional fields', () {
      final minimal = FriendActivity(
        id: 'activity125',
        userId: 'user789',
        userName: 'Bob Wilson',
        activityType: 'destination_visited',
        title: 'Visited Mount Bromo',
        createdAt: now,
      );

      expect(minimal.userPhotoUrl, isNull);
      expect(minimal.description, isNull);
      expect(minimal.metadata, isNull);

      final map = minimal.toMap();
      expect(map['user_photo_url'], isNull);
      expect(map['description'], isNull);
      expect(map['metadata'], isNull);
    });

    test('should handle different activity types', () {
      final activityTypes = [
        'photo_upload',
        'trip_created',
        'destination_visited',
        'review_posted',
        'trip_completed',
        'friend_added',
      ];

      for (final type in activityTypes) {
        final testActivity = FriendActivity(
          id: 'test_$type',
          userId: 'user123',
          userName: 'Test User',
          activityType: type,
          title: 'Test $type activity',
          createdAt: now,
        );

        expect(testActivity.activityType, equals(type));
      }
    });

    test('should handle fromMap with missing optional fields', () {
      final map = {
        'id': 'activity126',
        'user_id': 'user999',
        'user_name': 'Minimal User',
        'activity_type': 'status_update',
        'title': 'Updated status',
        'created_at': '2025-10-01T10:00:00.000Z',
      };

      final fromMap = FriendActivity.fromMap(map);

      expect(fromMap.userPhotoUrl, isNull);
      expect(fromMap.description, isNull);
      expect(fromMap.metadata, isNull);
    });

    test('should implement equality correctly', () {
      final activity1 = FriendActivity(
        id: 'same-id',
        userId: 'user123',
        userName: 'John Doe',
        activityType: 'trip_created',
        title: 'Same activity',
        createdAt: now,
      );
      final activity2 = FriendActivity(
        id: 'same-id',
        userId: 'different',
        userName: 'Different User',
        activityType: 'other',
        title: 'Different activity',
        createdAt: DateTime.now(),
      );
      final activity3 = FriendActivity(
        id: 'different-id',
        userId: 'user123',
        userName: 'John Doe',
        activityType: 'trip_created',
        title: 'Same activity',
        createdAt: now,
      );

      expect(activity1 == activity2, true);
      expect(activity1 == activity3, false);
      expect(activity1.hashCode, activity2.hashCode);
    });

    test('should preserve metadata structure', () {
      final complexMetadata = {
        'trip': {
          'id': 'trip123',
          'name': 'Bali Adventure',
          'participants': ['user123', 'user456'],
        },
        'location': {
          'lat': -8.4095,
          'lng': 115.1889,
          'name': 'Bali',
        },
        'stats': {
          'duration_days': 7,
          'total_cost': 5000000,
        },
      };

      final activityWithMeta = FriendActivity(
        id: 'activity127',
        userId: 'user123',
        userName: 'John Doe',
        activityType: 'trip_created',
        title: 'Complex trip created',
        metadata: complexMetadata,
        createdAt: now,
      );

      final map = activityWithMeta.toMap();
      final reconstructed = FriendActivity.fromMap(map);

      expect(reconstructed.metadata!['trip']['id'], equals('trip123'));
      expect(reconstructed.metadata!['location']['name'], equals('Bali'));
      expect(reconstructed.metadata!['stats']['duration_days'], equals(7));
    });
  });

  group('Model serialization consistency', () {
    test('FriendRequest should maintain data integrity through serialization', () {
      final original = FriendRequest(
        id: 'test-id',
        senderId: 'sender-123',
        receiverId: 'receiver-456',
        status: 'accepted',
        createdAt: DateTime.parse('2023-01-01T00:00:00.000Z'),
        respondedAt: DateTime.parse('2023-01-02T00:00:00.000Z'),
      );

      final map = original.toMap();
      final restored = FriendRequest.fromMap(map);

      expect(restored.id, original.id);
      expect(restored.senderId, original.senderId);
      expect(restored.receiverId, original.receiverId);
      expect(restored.status, original.status);
      expect(restored.createdAt, original.createdAt);
      expect(restored.respondedAt, original.respondedAt);
    });

    test('Friendship should maintain data integrity through serialization', () {
      final original = Friendship(
        id: 'friendship-id',
        userId1: 'user-1',
        userId2: 'user-2',
        createdAt: DateTime.parse('2023-01-01T00:00:00.000Z'),
        isBlocked: true,
        blockedBy: 'user-1',
      );

      final map = original.toMap();
      final restored = Friendship.fromMap(map);

      expect(restored.id, original.id);
      expect(restored.userId1, original.userId1);
      expect(restored.userId2, original.userId2);
      expect(restored.createdAt, original.createdAt);
      expect(restored.isBlocked, original.isBlocked);
      expect(restored.blockedBy, original.blockedBy);
    });

    test('FriendActivity should maintain data integrity through serialization', () {
      final original = FriendActivity(
        id: 'activity-id',
        userId: 'user-123',
        userName: 'Test User',
        userPhotoUrl: 'https://example.com/photo.jpg',
        activityType: 'trip_created',
        title: 'Created awesome trip',
        description: 'Trip to amazing places',
        metadata: {'duration': 7, 'destinations': ['Bali', 'Jakarta']},
        createdAt: DateTime.parse('2023-01-01T00:00:00.000Z'),
      );

      final map = original.toMap();
      final restored = FriendActivity.fromMap(map);

      expect(restored.id, original.id);
      expect(restored.userId, original.userId);
      expect(restored.userName, original.userName);
      expect(restored.userPhotoUrl, original.userPhotoUrl);
      expect(restored.activityType, original.activityType);
      expect(restored.title, original.title);
      expect(restored.description, original.description);
      expect(restored.metadata, original.metadata);
      expect(restored.createdAt, original.createdAt);
    });
  });

  group('Edge cases and error handling', () {
    test('should handle null values gracefully in fromMap', () {
      final requestMap = {
        'id': null,
        'sender_id': null,
        'receiver_id': null,
        'status': null,
        'created_at': null,
        'responded_at': null,
      };

      final friendshipMap = {
        'id': null,
        'user_id_1': null,
        'user_id_2': null,
        'created_at': null,
        'is_blocked': null,
        'blocked_by': null,
      };

      final activityMap = {
        'id': null,
        'user_id': null,
        'user_name': null,
        'user_photo_url': null,
        'activity_type': null,
        'title': null,
        'description': null,
        'metadata': null,
        'created_at': null,
      };

      expect(() => FriendRequest.fromMap(requestMap), returnsNormally);
      expect(() => Friendship.fromMap(friendshipMap), returnsNormally);
      expect(() => FriendActivity.fromMap(activityMap), returnsNormally);
    });

    test('should handle empty strings gracefully', () {
      final requestMap = {
        'id': '',
        'sender_id': '',
        'receiver_id': '',
        'status': '',
        'created_at': DateTime.now().toIso8601String(),
      };

      final request = FriendRequest.fromMap(requestMap);
      expect(request.id, '');
      expect(request.senderId, '');
      expect(request.receiverId, '');
      expect(request.status, '');
    });
  });
}
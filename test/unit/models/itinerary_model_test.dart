import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mockito/mockito.dart';
import 'package:relink/core/models/itinerary_model.dart';
import '../../test_setup.dart';

class MockDocumentSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

void main() {
  setUpAll(() async {
    await setupTestEnvironment();
  });

  group('TripItinerary Model', () {
    late TripItinerary itinerary;
    late DateTime now;

    setUp(() {
      now = DateTime.now();
      itinerary = TripItinerary(
        id: 'itinerary123',
        tripId: 'trip123',
        userId: 'user123',
        days: [
          ItineraryDay(
            date: DateTime(2025, 3, 1),
            activities: [
              ItineraryActivity(
                id: 'act1',
                title: 'Beach Visit',
                type: ActivityType.nature,
                startTime: '09:00',
                endTime: '12:00',
              ),
            ],
            notes: 'Day 1 notes',
          ),
          ItineraryDay(
            date: DateTime(2025, 3, 2),
            activities: [
              ItineraryActivity(
                id: 'act2',
                title: 'Museum Tour',
                type: ActivityType.attraction,
                startTime: '10:00',
                endTime: '13:00',
              ),
            ],
            notes: 'Day 2 notes',
          ),
        ],
        createdAt: now,
        updatedAt: now,
      );
    });

    test('should create itinerary with all fields', () {
      expect(itinerary.id, equals('itinerary123'));
      expect(itinerary.tripId, equals('trip123'));
      expect(itinerary.userId, equals('user123'));
      expect(itinerary.days.length, equals(2));
    });

    test('should get day by date', () {
      final day = itinerary.getDayByDate(DateTime(2025, 3, 1));

      expect(day, isNotNull);
      expect(day!.activities.length, equals(1));
      expect(day.activities[0].title, equals('Beach Visit'));
    });

    test('should return empty day for date not in itinerary', () {
      final day = itinerary.getDayByDate(DateTime(2025, 3, 10));

      expect(day, isNotNull);
      expect(day!.activities, isEmpty);
    });

    test('should calculate total activities correctly', () {
      expect(itinerary.totalActivities, equals(2));
    });

    test('should convert to Firestore document correctly', () {
      final firestoreMap = itinerary.toFirestore();

      expect(firestoreMap['tripId'], equals('trip123'));
      expect(firestoreMap['userId'], equals('user123'));
      expect(firestoreMap['days'], isA<List>());
      expect(firestoreMap['createdAt'], isA<Timestamp>());
      expect(firestoreMap['updatedAt'], isA<Timestamp>());
    });

    test('should create from Firestore document correctly', () {
      final firestoreMap = {
        'tripId': 'trip456',
        'userId': 'user456',
        'days': [
          {
            'date': Timestamp.fromDate(DateTime(2025, 4, 1)),
            'activities': [
              {
                'id': 'act3',
                'title': 'Lunch',
                'type': 'food',
                'startTime': '12:00',
                'endTime': '13:00',
              },
            ],
            'notes': 'Lunch plans',
          },
        ],
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      };

      final mockDoc = MockDocumentSnapshot();
      when(mockDoc.id).thenReturn('itinerary456');
      when(mockDoc.data()).thenReturn(firestoreMap);
      final fromFirestore = TripItinerary.fromFirestore(mockDoc);

      expect(fromFirestore.id, equals('itinerary456'));
      expect(fromFirestore.tripId, equals('trip456'));
      expect(fromFirestore.days.length, equals(1));
    });

    test('should copy with updated fields', () {
      final newDays = [
        ItineraryDay(
          date: DateTime(2025, 3, 3),
          activities: [],
          notes: 'New day',
        ),
      ];

      final updated = itinerary.copyWith(days: newDays);

      expect(updated.id, equals(itinerary.id));
      expect(updated.days.length, equals(1));
      expect(updated.days[0].notes, equals('New day'));
    });
  });

  group('ItineraryDay Model', () {
    late DateTime now;

    setUp(() {
      now = DateTime.now();
    });

    test('should create day with activities', () {
      final day = ItineraryDay(
        date: DateTime(2025, 3, 1),
        activities: [
          ItineraryActivity(
            id: 'act1',
            title: 'Morning walk',
            type: ActivityType.nature,
            startTime: '07:00',
            endTime: '08:00',
          ),
          ItineraryActivity(
            id: 'act2',
            title: 'Breakfast',
            type: ActivityType.food,
            startTime: '08:30',
            endTime: '09:30',
          ),
        ],
        notes: 'Start the day early',
      );

      expect(day.activities.length, equals(2));
      expect(day.notes, equals('Start the day early'));
    });

    test('should convert to map correctly', () {
      final day = ItineraryDay(
        date: DateTime(2025, 3, 1),
        activities: [],
        notes: 'Test notes',
      );

      final map = day.toMap();

      expect(map['date'], isA<Timestamp>());
      expect(map['activities'], isA<List>());
      expect(map['notes'], equals('Test notes'));
    });

    test('should create from map correctly', () {
      final map = {
        'date': Timestamp.fromDate(DateTime(2025, 3, 1)),
        'activities': [
          {
            'id': 'act1',
            'title': 'Activity',
            'type': 'attraction',
            'startTime': '10:00',
            'endTime': '11:00',
          },
        ],
        'notes': 'Day notes',
      };

      final day = ItineraryDay.fromMap(map);

      expect(day.activities.length, equals(1));
      expect(day.notes, equals('Day notes'));
    });

    test('should copy with updated fields', () {
      final day = ItineraryDay(
        date: DateTime(2025, 3, 1),
        activities: [],
        notes: 'Original notes',
      );

      final updated = day.copyWith(notes: 'Updated notes');

      expect(updated.notes, equals('Updated notes'));
      expect(updated.date, equals(day.date));
    });
  });

  group('ItineraryActivity Model', () {
    late DateTime now;

    setUp(() {
      now = DateTime.now();
    });

    test('should create activity with all fields', () {
      final activity = ItineraryActivity(
        id: 'act123',
        title: 'Temple Visit',
        description: 'Visit the ancient temple',
        type: ActivityType.attraction,
        location: 'Temple Complex',
        locationLat: -8.409518,
        locationLng: 115.188919,
        startTime: '09:00',
        endTime: '12:00',
        estimatedCost: 100000.0,
        bookingUrl: 'https://example.com/booking',
        isCompleted: false,
      );

      expect(activity.id, equals('act123'));
      expect(activity.title, equals('Temple Visit'));
      expect(activity.description, equals('Visit the ancient temple'));
      expect(activity.type, equals(ActivityType.attraction));
      expect(activity.location, equals('Temple Complex'));
      expect(activity.startTime, equals('09:00'));
      expect(activity.endTime, equals('12:00'));
      expect(activity.estimatedCost, equals(100000.0));
      expect(activity.isCompleted, isFalse);
    });

    test('should create activity with minimal fields', () {
      final activity = ItineraryActivity(
        id: 'act124',
        title: 'Free time',
        type: ActivityType.other,
      );

      expect(activity.description, isNull);
      expect(activity.location, isNull);
      expect(activity.startTime, isNull);
      expect(activity.endTime, isNull);
      expect(activity.estimatedCost, isNull);
      expect(activity.isCompleted, isFalse);
    });

    test('should validate time format - valid times', () {
      final activity = ItineraryActivity(
        id: 'act125',
        title: 'Lunch',
        type: ActivityType.food,
        startTime: '12:00',
        endTime: '13:30',
      );

      expect(activity.startTime, matches(RegExp(r'^\d{2}:\d{2}$')));
      expect(activity.endTime, matches(RegExp(r'^\d{2}:\d{2}$')));
    });

    test('should handle activity types - activity', () {
      final activity = ItineraryActivity(
        id: 'act126',
        title: 'Surfing lesson',
        type: ActivityType.attraction,
      );

      expect(activity.type, equals(ActivityType.attraction));
    });

    test('should handle activity types - meal', () {
      final meal = ItineraryActivity(
        id: 'act127',
        title: 'Dinner',
        type: ActivityType.food,
        startTime: '19:00',
        endTime: '20:30',
      );

      expect(meal.type, equals(ActivityType.food));
    });

    test('should handle activity types - accommodation', () {
      final accommodation = ItineraryActivity(
        id: 'act128',
        title: 'Hotel check-in',
        type: ActivityType.accommodation,
        startTime: '15:00',
      );

      expect(accommodation.type, equals(ActivityType.accommodation));
    });

    test('should handle activity types - transportation', () {
      final transport = ItineraryActivity(
        id: 'act129',
        title: 'Airport transfer',
        type: ActivityType.transportation,
        startTime: '06:00',
        endTime: '07:30',
      );

      expect(transport.type, equals(ActivityType.transportation));
    });

    test('should track completion status', () {
      final activity = ItineraryActivity(
        id: 'act130',
        title: 'Museum visit',
        type: ActivityType.attraction,
        isCompleted: false,
      );

      expect(activity.isCompleted, isFalse);

      final completed = activity.copyWith(isCompleted: true);

      expect(completed.isCompleted, isTrue);
    });

    test('should return correct icon for each activity type', () {
      expect(
        ItineraryActivity(
          id: '1',
          title: '',
          type: ActivityType.attraction,
        ).icon,
        equals('🏛️'),
      );
      expect(
        ItineraryActivity(id: '2', title: '', type: ActivityType.food).icon,
        equals('🍽️'),
      );
      expect(
        ItineraryActivity(
          id: '3',
          title: '',
          type: ActivityType.accommodation,
        ).icon,
        equals('🏨'),
      );
      expect(
        ItineraryActivity(
          id: '4',
          title: '',
          type: ActivityType.transportation,
        ).icon,
        equals('🚗'),
      );
      expect(
        ItineraryActivity(id: '5', title: '', type: ActivityType.shopping).icon,
        equals('🛍️'),
      );
      expect(
        ItineraryActivity(
          id: '6',
          title: '',
          type: ActivityType.entertainment,
        ).icon,
        equals('🎭'),
      );
      expect(
        ItineraryActivity(id: '7', title: '', type: ActivityType.nature).icon,
        equals('🏞️'),
      );
      expect(
        ItineraryActivity(id: '8', title: '', type: ActivityType.other).icon,
        equals('📍'),
      );
    });

    test('should convert to map correctly', () {
      final activity = ItineraryActivity(
        id: 'act131',
        title: 'Beach day',
        description: 'Relax at the beach',
        type: ActivityType.nature,
        location: 'Kuta Beach',
        startTime: '10:00',
        endTime: '16:00',
        estimatedCost: 50000.0,
      );

      final map = activity.toMap();

      expect(map['id'], equals('act131'));
      expect(map['title'], equals('Beach day'));
      expect(map['type'], equals('nature'));
      expect(map['location'], equals('Kuta Beach'));
      expect(map['startTime'], equals('10:00'));
      expect(map['endTime'], equals('16:00'));
      expect(map['estimatedCost'], equals(50000.0));
    });

    test('should create from map correctly', () {
      final map = {
        'id': 'act132',
        'title': 'Shopping',
        'description': 'Visit local market',
        'type': 'shopping',
        'location': 'Central Market',
        'locationLat': -8.5,
        'locationLng': 115.2,
        'startTime': '14:00',
        'endTime': '17:00',
        'estimatedCost': 200000.0,
        'bookingUrl': null,
        'isCompleted': false,
      };

      final activity = ItineraryActivity.fromMap(map);

      expect(activity.id, equals('act132'));
      expect(activity.title, equals('Shopping'));
      expect(activity.type, equals(ActivityType.shopping));
      expect(activity.estimatedCost, equals(200000.0));
    });

    test('should copy with updated fields', () {
      final activity = ItineraryActivity(
        id: 'act133',
        title: 'Original title',
        type: ActivityType.other,
        isCompleted: false,
      );

      final updated = activity.copyWith(
        title: 'Updated title',
        description: 'New description',
        isCompleted: true,
      );

      expect(updated.id, equals(activity.id));
      expect(updated.title, equals('Updated title'));
      expect(updated.description, equals('New description'));
      expect(updated.isCompleted, isTrue);
      expect(updated.type, equals(activity.type));
    });

    test('should handle activity with location coordinates', () {
      final activity = ItineraryActivity(
        id: 'act134',
        title: 'Restaurant',
        type: ActivityType.food,
        location: 'Downtown Restaurant',
        locationLat: -8.4095,
        locationLng: 115.1889,
      );

      expect(activity.location, equals('Downtown Restaurant'));
      expect(activity.locationLat, equals(-8.4095));
      expect(activity.locationLng, equals(115.1889));
    });

    test('should handle activity with booking URL', () {
      final activity = ItineraryActivity(
        id: 'act135',
        title: 'Show tickets',
        type: ActivityType.entertainment,
        bookingUrl: 'https://example.com/tickets',
      );

      expect(activity.bookingUrl, equals('https://example.com/tickets'));
    });

    test('should handle activities in sequence', () {
      final activities = [
        ItineraryActivity(
          id: 'act1',
          title: 'Breakfast',
          type: ActivityType.food,
          startTime: '08:00',
          endTime: '09:00',
        ),
        ItineraryActivity(
          id: 'act2',
          title: 'City tour',
          type: ActivityType.attraction,
          startTime: '09:30',
          endTime: '12:00',
        ),
        ItineraryActivity(
          id: 'act3',
          title: 'Lunch',
          type: ActivityType.food,
          startTime: '12:30',
          endTime: '13:30',
        ),
      ];

      expect(activities.length, equals(3));
      expect(activities[0].startTime, equals('08:00'));
      expect(activities[1].startTime, equals('09:30'));
      expect(activities[2].startTime, equals('12:30'));
    });
  });

  group('ActivityType Enum', () {
    test('should have all activity types', () {
      expect(ActivityType.values.length, equals(8));
      expect(ActivityType.values.contains(ActivityType.attraction), isTrue);
      expect(ActivityType.values.contains(ActivityType.food), isTrue);
      expect(ActivityType.values.contains(ActivityType.accommodation), isTrue);
      expect(ActivityType.values.contains(ActivityType.transportation), isTrue);
      expect(ActivityType.values.contains(ActivityType.shopping), isTrue);
      expect(ActivityType.values.contains(ActivityType.entertainment), isTrue);
      expect(ActivityType.values.contains(ActivityType.nature), isTrue);
      expect(ActivityType.values.contains(ActivityType.other), isTrue);
    });

    test('should have correct display names', () {
      expect(ActivityType.attraction.displayName, equals('Attraction'));
      expect(ActivityType.food.displayName, equals('Food & Dining'));
      expect(ActivityType.accommodation.displayName, equals('Accommodation'));
      expect(ActivityType.transportation.displayName, equals('Transportation'));
      expect(ActivityType.shopping.displayName, equals('Shopping'));
      expect(ActivityType.entertainment.displayName, equals('Entertainment'));
      expect(ActivityType.nature.displayName, equals('Nature & Outdoors'));
      expect(ActivityType.other.displayName, equals('Other'));
    });
  });

  group('Itinerary Order and Sequence', () {
    test('should handle multiple activities in a day ordered by time', () {
      final day = ItineraryDay(
        date: DateTime(2025, 3, 1),
        activities: [
          ItineraryActivity(
            id: 'act1',
            title: 'Early morning hike',
            type: ActivityType.nature,
            startTime: '06:00',
            endTime: '08:00',
          ),
          ItineraryActivity(
            id: 'act2',
            title: 'Breakfast',
            type: ActivityType.food,
            startTime: '08:30',
            endTime: '09:30',
          ),
          ItineraryActivity(
            id: 'act3',
            title: 'Museum visit',
            type: ActivityType.attraction,
            startTime: '10:00',
            endTime: '12:00',
          ),
        ],
        notes: 'Full day schedule',
      );

      expect(day.activities.length, equals(3));
      expect(day.activities[0].startTime, equals('06:00'));
      expect(day.activities[1].startTime, equals('08:30'));
      expect(day.activities[2].startTime, equals('10:00'));
    });

    test('should handle completion status across multiple activities', () {
      final day = ItineraryDay(
        date: DateTime(2025, 3, 1),
        activities: [
          ItineraryActivity(
            id: 'act1',
            title: 'Completed activity',
            type: ActivityType.attraction,
            isCompleted: true,
          ),
          ItineraryActivity(
            id: 'act2',
            title: 'Pending activity',
            type: ActivityType.food,
            isCompleted: false,
          ),
          ItineraryActivity(
            id: 'act3',
            title: 'Another completed',
            type: ActivityType.shopping,
            isCompleted: true,
          ),
        ],
        notes: 'Mixed completion status',
      );

      final completedCount = day.activities.where((a) => a.isCompleted).length;
      final pendingCount = day.activities.where((a) => !a.isCompleted).length;

      expect(completedCount, equals(2));
      expect(pendingCount, equals(1));
    });
  });
}

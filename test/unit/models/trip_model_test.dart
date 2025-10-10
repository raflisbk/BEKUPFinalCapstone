import 'package:flutter_test/flutter_test.dart';
import 'package:relink/core/models/trip_model.dart';
import '../../test_setup.dart';

void main() {
  setUpAll(() async {
    await setupTestEnvironment();
  });

  group('Trip Model', () {
    late Trip trip;
    late DateTime now;

    setUp(() {
      now = DateTime.now();
      trip = Trip(
        id: 'trip123',
        userId: 'user123',
        userName: 'Test User',
        userPhotoUrl: 'https://example.com/photo.jpg',
        title: 'Bali Adventure',
        description: 'Amazing trip to Bali',
        startDate: DateTime(2025, 3, 1),
        endDate: DateTime(2025, 3, 10),
        participantIds: ['user123'],
        participants: {
          'user123': ParticipantInfo(
            name: 'Test User',
            photoUrl: 'https://example.com/photo.jpg',
            joinedAt: now,
          ),
        },
        isPublic: true,
        createdAt: now,
        updatedAt: now,
      );
    });

    test('should create trip with all required fields', () {
      expect(trip.id, equals('trip123'));
      expect(trip.userId, equals('user123'));
      expect(trip.title, equals('Bali Adventure'));
      expect(trip.description, equals('Amazing trip to Bali'));
      expect(trip.isPublic, isTrue);
    });

    test('should calculate trip duration correctly', () {
      final duration = trip.endDate.difference(trip.startDate).inDays;
      expect(duration, equals(9));
    });

    test('should check if trip is upcoming', () {
      final upcomingTrip = Trip(
        id: 'trip124',
        userId: 'user123',
        userName: 'Test User',
        title: 'Future Trip',
        description: 'Trip in the future',
        startDate: DateTime.now().add(const Duration(days: 30)),
        endDate: DateTime.now().add(const Duration(days: 40)),
        participantIds: ['user123'],
        participants: {},
        createdAt: now,
        updatedAt: now,
      );

      expect(upcomingTrip.isUpcoming, isTrue);
    });

    test('should check if trip is ongoing', () {
      final ongoingTrip = Trip(
        id: 'trip125',
        userId: 'user123',
        userName: 'Test User',
        title: 'Current Trip',
        description: 'Trip happening now',
        startDate: DateTime.now().subtract(const Duration(days: 2)),
        endDate: DateTime.now().add(const Duration(days: 5)),
        participantIds: ['user123'],
        participants: {},
        createdAt: now,
        updatedAt: now,
      );

      expect(ongoingTrip.isOngoing, isTrue);
    });

    test('should check if trip is past', () {
      final pastTrip = Trip(
        id: 'trip126',
        userId: 'user123',
        userName: 'Test User',
        title: 'Past Trip',
        description: 'Completed trip',
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        endDate: DateTime.now().subtract(const Duration(days: 20)),
        participantIds: ['user123'],
        participants: {},
        createdAt: now,
        updatedAt: now,
      );

      expect(pastTrip.isPast, isTrue);
    });

    test('should calculate total spent from expenses', () {
      final tripWithExpenses = Trip(
        id: 'trip127',
        userId: 'user123',
        userName: 'Test User',
        title: 'Trip with Budget',
        description: 'Trip with expenses',
        startDate: DateTime(2025, 3, 1),
        endDate: DateTime(2025, 3, 10),
        participantIds: ['user123'],
        participants: {},
        expenses: [
          BudgetExpense(
            id: 'exp1',
            description: 'Hotel',
            amount: 500.0,
            currency: 'USD',
            category: BudgetCategory.accommodation,
            date: DateTime.now(),
            createdAt: now,
          ),
          BudgetExpense(
            id: 'exp2',
            description: 'Food',
            amount: 200.0,
            currency: 'USD',
            category: BudgetCategory.food,
            date: DateTime.now(),
            createdAt: now,
          ),
        ],
        createdAt: now,
        updatedAt: now,
      );

      expect(tripWithExpenses.totalSpent, equals(700.0));
    });

    test('should calculate budget remaining', () {
      final tripWithBudget = Trip(
        id: 'trip128',
        userId: 'user123',
        userName: 'Test User',
        title: 'Budgeted Trip',
        description: 'Trip with budget tracking',
        startDate: DateTime(2025, 3, 1),
        endDate: DateTime(2025, 3, 10),
        participantIds: ['user123'],
        participants: {},
        budget: TripBudget(
          totalBudget: 1000.0,
          currency: 'USD',
          createdAt: now,
          updatedAt: now,
        ),
        expenses: [
          BudgetExpense(
            id: 'exp1',
            description: 'Hotel',
            amount: 300.0,
            currency: 'USD',
            category: BudgetCategory.accommodation,
            date: DateTime.now(),
            createdAt: now,
          ),
        ],
        createdAt: now,
        updatedAt: now,
      );

      expect(tripWithBudget.budgetRemaining, equals(700.0));
    });

    test('should detect if over budget', () {
      final overBudgetTrip = Trip(
        id: 'trip129',
        userId: 'user123',
        userName: 'Test User',
        title: 'Over Budget Trip',
        description: 'Trip exceeding budget',
        startDate: DateTime(2025, 3, 1),
        endDate: DateTime(2025, 3, 10),
        participantIds: ['user123'],
        participants: {},
        budget: TripBudget(
          totalBudget: 500.0,
          currency: 'USD',
          createdAt: now,
          updatedAt: now,
        ),
        expenses: [
          BudgetExpense(
            id: 'exp1',
            description: 'Expensive Hotel',
            amount: 600.0,
            currency: 'USD',
            category: BudgetCategory.accommodation,
            date: DateTime.now(),
            createdAt: now,
          ),
        ],
        createdAt: now,
        updatedAt: now,
      );

      expect(overBudgetTrip.isOverBudget, isTrue);
    });
  });

  group('TripFilter Enum', () {
    test('should have all filter options', () {
      expect(TripFilter.values.length, equals(6));
      expect(TripFilter.values.contains(TripFilter.all), isTrue);
      expect(TripFilter.values.contains(TripFilter.myTrips), isTrue);
      expect(TripFilter.values.contains(TripFilter.joined), isTrue);
      expect(TripFilter.values.contains(TripFilter.upcoming), isTrue);
      expect(TripFilter.values.contains(TripFilter.ongoing), isTrue);
      expect(TripFilter.values.contains(TripFilter.past), isTrue);
    });
  });

  group('BudgetCategory Enum', () {
    test('should have all budget categories', () {
      expect(BudgetCategory.values.length, greaterThanOrEqualTo(6));
      expect(
        BudgetCategory.values.contains(BudgetCategory.accommodation),
        isTrue,
      );
      expect(BudgetCategory.values.contains(BudgetCategory.food), isTrue);
      expect(BudgetCategory.values.contains(BudgetCategory.transport), isTrue);
      expect(BudgetCategory.values.contains(BudgetCategory.activities), isTrue);
      expect(BudgetCategory.values.contains(BudgetCategory.shopping), isTrue);
      expect(BudgetCategory.values.contains(BudgetCategory.other), isTrue);
    });
  });
}

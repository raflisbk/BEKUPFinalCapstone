import 'package:flutter_test/flutter_test.dart';
import '../lib/core/stubs/firebase_stubs.dart';
import 'package:mockito/mockito.dart';
import 'package:relink/core/models/budget_model.dart';
import '../../test_setup.dart';

// ignore: subtype_of_sealed_class
class MockDocumentSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

void main() {
  setUpAll(() async {
    await setupTestEnvironment();
  });

  group('TripBudget Model', () {
    late TripBudget budget;
    late DateTime now;

    setUp(() {
      now = DateTime.now();
      budget = TripBudget(
        id: 'budget123',
        tripId: 'trip123',
        userId: 'user123',
        totalBudget: 10000000.0,
        currency: 'IDR',
        categories: [
          BudgetCategory(
            category: ExpenseCategory.accommodation,
            allocatedAmount: 4000000.0,
          ),
          BudgetCategory(
            category: ExpenseCategory.food,
            allocatedAmount: 3000000.0,
          ),
          BudgetCategory(
            category: ExpenseCategory.transportation,
            allocatedAmount: 2000000.0,
          ),
          BudgetCategory(
            category: ExpenseCategory.activities,
            allocatedAmount: 1000000.0,
          ),
        ],
        expenses: [],
        createdAt: now,
        updatedAt: now,
      );
    });

    test('should create budget with total amount', () {
      expect(budget.totalBudget, equals(10000000.0));
      expect(budget.currency, equals('IDR'));
      expect(budget.tripId, equals('trip123'));
      expect(budget.userId, equals('user123'));
    });

    test('should create budget with category allocations', () {
      expect(budget.categories.length, equals(4));
      expect(
        budget.categories[0].category,
        equals(ExpenseCategory.accommodation),
      );
      expect(budget.categories[0].allocatedAmount, equals(4000000.0));
      expect(budget.categories[1].category, equals(ExpenseCategory.food));
      expect(budget.categories[1].allocatedAmount, equals(3000000.0));
    });

    test('should calculate total spent correctly', () {
      final budgetWithExpenses = budget.copyWith(
        expenses: [
          Expense(
            id: 'exp1',
            category: ExpenseCategory.accommodation,
            description: 'Hotel booking',
            amount: 2000000.0,
            date: now,
          ),
          Expense(
            id: 'exp2',
            category: ExpenseCategory.food,
            description: 'Restaurant',
            amount: 500000.0,
            date: now,
          ),
        ],
      );

      expect(budgetWithExpenses.totalSpent, equals(2500000.0));
    });

    test('should calculate remaining budget correctly', () {
      final budgetWithExpenses = budget.copyWith(
        expenses: [
          Expense(
            id: 'exp1',
            category: ExpenseCategory.accommodation,
            description: 'Hotel booking',
            amount: 3000000.0,
            date: now,
          ),
        ],
      );

      expect(budgetWithExpenses.remaining, equals(7000000.0));
    });

    test('should calculate spending percentage correctly', () {
      final budgetWithExpenses = budget.copyWith(
        expenses: [
          Expense(
            id: 'exp1',
            category: ExpenseCategory.accommodation,
            description: 'Hotel booking',
            amount: 5000000.0,
            date: now,
          ),
        ],
      );

      expect(budgetWithExpenses.spentPercentage, equals(50.0));
    });

    test('should detect when over budget', () {
      final overBudget = budget.copyWith(
        expenses: [
          Expense(
            id: 'exp1',
            category: ExpenseCategory.accommodation,
            description: 'Expensive hotel',
            amount: 12000000.0,
            date: now,
          ),
        ],
      );

      expect(overBudget.isOverBudget, isTrue);
    });

    test('should detect when within budget', () {
      final withinBudget = budget.copyWith(
        expenses: [
          Expense(
            id: 'exp1',
            category: ExpenseCategory.food,
            description: 'Meal',
            amount: 500000.0,
            date: now,
          ),
        ],
      );

      expect(withinBudget.isOverBudget, isFalse);
    });

    test('should calculate spent by category', () {
      final budgetWithExpenses = budget.copyWith(
        expenses: [
          Expense(
            id: 'exp1',
            category: ExpenseCategory.food,
            description: 'Breakfast',
            amount: 200000.0,
            date: now,
          ),
          Expense(
            id: 'exp2',
            category: ExpenseCategory.food,
            description: 'Lunch',
            amount: 300000.0,
            date: now,
          ),
          Expense(
            id: 'exp3',
            category: ExpenseCategory.accommodation,
            description: 'Hotel',
            amount: 2000000.0,
            date: now,
          ),
        ],
      );

      expect(
        budgetWithExpenses.getSpentByCategory(ExpenseCategory.food),
        equals(500000.0),
      );
      expect(
        budgetWithExpenses.getSpentByCategory(ExpenseCategory.accommodation),
        equals(2000000.0),
      );
      expect(
        budgetWithExpenses.getSpentByCategory(ExpenseCategory.transportation),
        equals(0.0),
      );
    });

    test('should convert to Firestore document correctly', () {
      final firestoreMap = budget.toFirestore();

      expect(firestoreMap['tripId'], equals('trip123'));
      expect(firestoreMap['userId'], equals('user123'));
      expect(firestoreMap['totalBudget'], equals(10000000.0));
      expect(firestoreMap['currency'], equals('IDR'));
      expect(firestoreMap['categories'], isA<List>());
      expect(firestoreMap['expenses'], isA<List>());
      expect(firestoreMap['createdAt'], isA<Timestamp>());
      expect(firestoreMap['updatedAt'], isA<Timestamp>());
    });

    test('should create from Firestore document correctly', () {
      final firestoreMap = {
        'tripId': 'trip456',
        'userId': 'user456',
        'totalBudget': 5000000.0,
        'currency': 'USD',
        'categories': [
          {'category': 'accommodation', 'allocatedAmount': 2000000.0},
        ],
        'expenses': [
          {
            'id': 'exp1',
            'category': 'food',
            'description': 'Meal',
            'amount': 100000.0,
            'date': Timestamp.fromDate(now),
            'paidBy': [],
            'sharedWith': [],
          },
        ],
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      };

      final mockDoc = MockDocumentSnapshot();
      when(mockDoc.id).thenReturn('budget456');
      when(mockDoc.data()).thenReturn(firestoreMap);
      final fromFirestore = TripBudget.fromFirestore(mockDoc);

      expect(fromFirestore.id, equals('budget456'));
      expect(fromFirestore.tripId, equals('trip456'));
      expect(fromFirestore.totalBudget, equals(5000000.0));
      expect(fromFirestore.currency, equals('USD'));
    });

    test('should copy with updated fields', () {
      final updatedBudget = budget.copyWith(
        totalBudget: 15000000.0,
        currency: 'USD',
      );

      expect(updatedBudget.id, equals(budget.id));
      expect(updatedBudget.totalBudget, equals(15000000.0));
      expect(updatedBudget.currency, equals('USD'));
      expect(updatedBudget.tripId, equals(budget.tripId));
    });

    test('should handle zero budget correctly', () {
      final zeroBudget = TripBudget(
        id: 'budget456',
        tripId: 'trip456',
        userId: 'user456',
        totalBudget: 0.0,
        categories: [],
        expenses: [],
        createdAt: now,
        updatedAt: now,
      );

      expect(zeroBudget.spentPercentage, equals(0.0));
      expect(zeroBudget.isOverBudget, isFalse);
    });
  });

  group('BudgetCategory Model', () {
    test('should create category with allocation', () {
      final category = BudgetCategory(
        category: ExpenseCategory.accommodation,
        allocatedAmount: 5000000.0,
      );

      expect(category.category, equals(ExpenseCategory.accommodation));
      expect(category.allocatedAmount, equals(5000000.0));
    });

    test('should convert to map correctly', () {
      final category = BudgetCategory(
        category: ExpenseCategory.food,
        allocatedAmount: 2000000.0,
      );

      final map = category.toMap();

      expect(map['category'], equals('food'));
      expect(map['allocatedAmount'], equals(2000000.0));
    });

    test('should create from map correctly', () {
      final map = {'category': 'transportation', 'allocatedAmount': 3000000.0};

      final category = BudgetCategory.fromMap(map);

      expect(category.category, equals(ExpenseCategory.transportation));
      expect(category.allocatedAmount, equals(3000000.0));
    });
  });

  group('Expense Model', () {
    late DateTime now;

    setUp(() {
      now = DateTime.now();
    });

    test('should create expense with all fields', () {
      final expense = Expense(
        id: 'exp123',
        category: ExpenseCategory.food,
        description: 'Dinner at restaurant',
        amount: 500000.0,
        date: now,
        notes: 'Great food!',
        receiptUrl: 'https://example.com/receipt.jpg',
        paidBy: ['user123'],
        sharedWith: ['user123', 'user456'],
      );

      expect(expense.id, equals('exp123'));
      expect(expense.category, equals(ExpenseCategory.food));
      expect(expense.description, equals('Dinner at restaurant'));
      expect(expense.amount, equals(500000.0));
      expect(expense.notes, equals('Great food!'));
      expect(expense.receiptUrl, equals('https://example.com/receipt.jpg'));
      expect(expense.paidBy.length, equals(1));
      expect(expense.sharedWith.length, equals(2));
    });

    test('should create expense with minimal fields', () {
      final expense = Expense(
        id: 'exp124',
        category: ExpenseCategory.transportation,
        description: 'Taxi',
        amount: 100000.0,
        date: now,
      );

      expect(expense.notes, isNull);
      expect(expense.receiptUrl, isNull);
      expect(expense.paidBy, isEmpty);
      expect(expense.sharedWith, isEmpty);
    });

    test('should return correct icon for each category', () {
      expect(
        Expense(
          id: '1',
          category: ExpenseCategory.accommodation,
          description: '',
          amount: 0,
          date: now,
        ).icon,
        equals('🏨'),
      );
      expect(
        Expense(
          id: '2',
          category: ExpenseCategory.food,
          description: '',
          amount: 0,
          date: now,
        ).icon,
        equals('🍽️'),
      );
      expect(
        Expense(
          id: '3',
          category: ExpenseCategory.transportation,
          description: '',
          amount: 0,
          date: now,
        ).icon,
        equals('🚗'),
      );
      expect(
        Expense(
          id: '4',
          category: ExpenseCategory.activities,
          description: '',
          amount: 0,
          date: now,
        ).icon,
        equals('🎯'),
      );
      expect(
        Expense(
          id: '5',
          category: ExpenseCategory.shopping,
          description: '',
          amount: 0,
          date: now,
        ).icon,
        equals('🛍️'),
      );
      expect(
        Expense(
          id: '6',
          category: ExpenseCategory.other,
          description: '',
          amount: 0,
          date: now,
        ).icon,
        equals('💰'),
      );
    });

    test('should convert to map correctly', () {
      final expense = Expense(
        id: 'exp125',
        category: ExpenseCategory.activities,
        description: 'Museum ticket',
        amount: 150000.0,
        date: now,
        notes: 'Entry fee',
      );

      final map = expense.toMap();

      expect(map['id'], equals('exp125'));
      expect(map['category'], equals('activities'));
      expect(map['description'], equals('Museum ticket'));
      expect(map['amount'], equals(150000.0));
      expect(map['date'], isA<Timestamp>());
      expect(map['notes'], equals('Entry fee'));
    });

    test('should create from map correctly', () {
      final map = {
        'id': 'exp126',
        'category': 'shopping',
        'description': 'Souvenirs',
        'amount': 300000.0,
        'date': Timestamp.fromDate(now),
        'notes': 'Gifts for family',
        'paidBy': ['user123'],
        'sharedWith': ['user123'],
      };

      final expense = Expense.fromMap(map);

      expect(expense.id, equals('exp126'));
      expect(expense.category, equals(ExpenseCategory.shopping));
      expect(expense.description, equals('Souvenirs'));
      expect(expense.amount, equals(300000.0));
      expect(expense.notes, equals('Gifts for family'));
    });

    test('should copy with updated fields', () {
      final expense = Expense(
        id: 'exp127',
        category: ExpenseCategory.food,
        description: 'Lunch',
        amount: 200000.0,
        date: now,
      );

      final updated = expense.copyWith(
        description: 'Lunch at cafe',
        amount: 250000.0,
        notes: 'Added dessert',
      );

      expect(updated.id, equals(expense.id));
      expect(updated.description, equals('Lunch at cafe'));
      expect(updated.amount, equals(250000.0));
      expect(updated.notes, equals('Added dessert'));
      expect(updated.category, equals(expense.category));
    });

    test('should handle split expenses', () {
      final splitExpense = Expense(
        id: 'exp128',
        category: ExpenseCategory.accommodation,
        description: 'Hotel room',
        amount: 2000000.0,
        date: now,
        paidBy: ['user123'],
        sharedWith: ['user123', 'user456', 'user789'],
      );

      expect(splitExpense.paidBy.length, equals(1));
      expect(splitExpense.sharedWith.length, equals(3));
    });
  });

  group('ExpenseCategory Enum', () {
    test('should have all expense categories', () {
      expect(ExpenseCategory.values.length, equals(6));
      expect(
        ExpenseCategory.values.contains(ExpenseCategory.accommodation),
        isTrue,
      );
      expect(ExpenseCategory.values.contains(ExpenseCategory.food), isTrue);
      expect(
        ExpenseCategory.values.contains(ExpenseCategory.transportation),
        isTrue,
      );
      expect(
        ExpenseCategory.values.contains(ExpenseCategory.activities),
        isTrue,
      );
      expect(ExpenseCategory.values.contains(ExpenseCategory.shopping), isTrue);
      expect(ExpenseCategory.values.contains(ExpenseCategory.other), isTrue);
    });

    test('should have correct display names', () {
      expect(
        ExpenseCategory.accommodation.displayName,
        equals('Accommodation'),
      );
      expect(ExpenseCategory.food.displayName, equals('Food & Dining'));
      expect(
        ExpenseCategory.transportation.displayName,
        equals('Transportation'),
      );
      expect(ExpenseCategory.activities.displayName, equals('Activities'));
      expect(ExpenseCategory.shopping.displayName, equals('Shopping'));
      expect(ExpenseCategory.other.displayName, equals('Other'));
    });
  });

  group('Budget vs Actual Comparison', () {
    late TripBudget budget;
    late DateTime now;

    setUp(() {
      now = DateTime.now();
      budget = TripBudget(
        id: 'budget123',
        tripId: 'trip123',
        userId: 'user123',
        totalBudget: 10000000.0,
        currency: 'IDR',
        categories: [
          BudgetCategory(
            category: ExpenseCategory.accommodation,
            allocatedAmount: 4000000.0,
          ),
          BudgetCategory(
            category: ExpenseCategory.food,
            allocatedAmount: 3000000.0,
          ),
        ],
        expenses: [
          Expense(
            id: 'exp1',
            category: ExpenseCategory.accommodation,
            description: 'Hotel',
            amount: 3500000.0,
            date: now,
          ),
          Expense(
            id: 'exp2',
            category: ExpenseCategory.food,
            description: 'Meals',
            amount: 2500000.0,
            date: now,
          ),
        ],
        createdAt: now,
        updatedAt: now,
      );
    });

    test('should compare budget allocation vs actual spending', () {
      final accommodationAllocated = budget.categories
          .firstWhere((c) => c.category == ExpenseCategory.accommodation)
          .allocatedAmount;
      final accommodationSpent = budget.getSpentByCategory(
        ExpenseCategory.accommodation,
      );

      expect(accommodationAllocated, equals(4000000.0));
      expect(accommodationSpent, equals(3500000.0));
      expect(accommodationSpent < accommodationAllocated, isTrue);
    });

    test('should detect over-spending in a category', () {
      final budgetOverCategory = budget.copyWith(
        expenses: [
          Expense(
            id: 'exp1',
            category: ExpenseCategory.accommodation,
            description: 'Luxury hotel',
            amount: 5000000.0,
            date: now,
          ),
        ],
      );

      final allocatedAmount = budgetOverCategory.categories
          .firstWhere((c) => c.category == ExpenseCategory.accommodation)
          .allocatedAmount;
      final spentAmount = budgetOverCategory.getSpentByCategory(
        ExpenseCategory.accommodation,
      );

      expect(spentAmount > allocatedAmount, isTrue);
    });

    test('should track under-spending in a category', () {
      final foodAllocated = budget.categories
          .firstWhere((c) => c.category == ExpenseCategory.food)
          .allocatedAmount;
      final foodSpent = budget.getSpentByCategory(ExpenseCategory.food);

      expect(foodAllocated, equals(3000000.0));
      expect(foodSpent, equals(2500000.0));
      expect(foodSpent < foodAllocated, isTrue);
    });
  });
}

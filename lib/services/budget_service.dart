import '../core/stubs/firebase_stubs.dart';
import 'package:uuid/uuid.dart';
import '../core/models/budget_model.dart';
import '../core/utils/logger.dart';

/// Service for managing trip budgets
class BudgetService {
  static const String _tag = 'BudgetService';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  CollectionReference get _budgetsCollection =>
      _firestore.collection('budgets');

  /// Get budget for a trip
  Future<TripBudget?> getBudget(String tripId) async {
    try {
      AppLogger.debug(_tag, 'Getting budget', {'tripId': tripId});

      final querySnapshot = await _budgetsCollection
          .where('tripId', isEqualTo: tripId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        AppLogger.debug(_tag, 'No budget found for trip');
        return null;
      }

      return TripBudget.fromFirestore(querySnapshot.docs.first);
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get budget', e, stackTrace);
      return null;
    }
  }

  /// Create new budget for trip
  Future<TripBudget?> createBudget({
    required String tripId,
    required String userId,
    required double totalBudget,
    String currency = 'IDR',
    List<BudgetCategory>? categories,
  }) async {
    try {
      AppLogger.debug(_tag, 'Creating budget', {
        'tripId': tripId,
        'totalBudget': totalBudget,
        'currency': currency,
      });

      final now = DateTime.now();

      final budget = TripBudget(
        id: '',
        tripId: tripId,
        userId: userId,
        totalBudget: totalBudget,
        currency: currency,
        categories: categories ?? _getDefaultCategories(),
        expenses: [],
        createdAt: now,
        updatedAt: now,
      );

      final docRef = await _budgetsCollection.add(budget.toFirestore());

      AppLogger.info(_tag, 'Budget created successfully', {
        'budgetId': docRef.id,
      });

      return TripBudget.fromFirestore(await docRef.get());
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to create budget', e, stackTrace);
      return null;
    }
  }

  /// Add expense to budget
  Future<bool> addExpense({
    required String budgetId,
    required Expense expense,
  }) async {
    try {
      AppLogger.debug(_tag, 'Adding expense', {
        'budgetId': budgetId,
        'amount': expense.amount,
        'category': expense.category.displayName,
      });

      final doc = await _budgetsCollection.doc(budgetId).get();
      if (!doc.exists) {
        AppLogger.warning(_tag, 'Budget not found');
        return false;
      }

      final budget = TripBudget.fromFirestore(doc);
      final updatedExpenses = [...budget.expenses, expense];

      await _budgetsCollection.doc(budgetId).update({
        'expenses': updatedExpenses.map((e) => e.toMap()).toList(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      AppLogger.info(_tag, 'Expense added successfully');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to add expense', e, stackTrace);
      return false;
    }
  }

  /// Update expense
  Future<bool> updateExpense({
    required String budgetId,
    required String expenseId,
    required Expense updatedExpense,
  }) async {
    try {
      AppLogger.debug(_tag, 'Updating expense', {
        'budgetId': budgetId,
        'expenseId': expenseId,
      });

      final doc = await _budgetsCollection.doc(budgetId).get();
      if (!doc.exists) {
        AppLogger.warning(_tag, 'Budget not found');
        return false;
      }

      final budget = TripBudget.fromFirestore(doc);
      final updatedExpenses = budget.expenses.map((expense) {
        return expense.id == expenseId ? updatedExpense : expense;
      }).toList();

      await _budgetsCollection.doc(budgetId).update({
        'expenses': updatedExpenses.map((e) => e.toMap()).toList(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      AppLogger.info(_tag, 'Expense updated successfully');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to update expense', e, stackTrace);
      return false;
    }
  }

  /// Delete expense
  Future<bool> deleteExpense({
    required String budgetId,
    required String expenseId,
  }) async {
    try {
      AppLogger.debug(_tag, 'Deleting expense', {
        'budgetId': budgetId,
        'expenseId': expenseId,
      });

      final doc = await _budgetsCollection.doc(budgetId).get();
      if (!doc.exists) {
        AppLogger.warning(_tag, 'Budget not found');
        return false;
      }

      final budget = TripBudget.fromFirestore(doc);
      final updatedExpenses = budget.expenses
          .where((expense) => expense.id != expenseId)
          .toList();

      await _budgetsCollection.doc(budgetId).update({
        'expenses': updatedExpenses.map((e) => e.toMap()).toList(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      AppLogger.info(_tag, 'Expense deleted successfully');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to delete expense', e, stackTrace);
      return false;
    }
  }

  /// Update total budget
  Future<bool> updateTotalBudget({
    required String budgetId,
    required double totalBudget,
  }) async {
    try {
      AppLogger.debug(_tag, 'Updating total budget', {
        'budgetId': budgetId,
        'totalBudget': totalBudget,
      });

      await _budgetsCollection.doc(budgetId).update({
        'totalBudget': totalBudget,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      AppLogger.info(_tag, 'Total budget updated successfully');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to update total budget', e, stackTrace);
      return false;
    }
  }

  /// Update budget categories
  Future<bool> updateCategories({
    required String budgetId,
    required List<BudgetCategory> categories,
  }) async {
    try {
      AppLogger.debug(_tag, 'Updating budget categories', {
        'budgetId': budgetId,
        'count': categories.length,
      });

      await _budgetsCollection.doc(budgetId).update({
        'categories': categories.map((c) => c.toMap()).toList(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      AppLogger.info(_tag, 'Budget categories updated successfully');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to update budget categories', e, stackTrace);
      return false;
    }
  }

  /// Generate expense ID
  String generateExpenseId() {
    return _uuid.v4();
  }

  /// Get budget stream (real-time)
  Stream<TripBudget?> getBudgetStream(String tripId) {
    AppLogger.debug(_tag, 'Getting budget stream', {'tripId': tripId});

    return _budgetsCollection
        .where('tripId', isEqualTo: tripId)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return TripBudget.fromFirestore(snapshot.docs.first);
    });
  }

  /// Delete budget
  Future<bool> deleteBudget(String budgetId) async {
    try {
      AppLogger.debug(_tag, 'Deleting budget', {
        'budgetId': budgetId,
      });

      await _budgetsCollection.doc(budgetId).delete();

      AppLogger.info(_tag, 'Budget deleted successfully');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to delete budget', e, stackTrace);
      return false;
    }
  }

  /// Get default budget categories
  List<BudgetCategory> _getDefaultCategories() {
    return [
      BudgetCategory(
        category: ExpenseCategory.accommodation,
        allocatedAmount: 0,
      ),
      BudgetCategory(
        category: ExpenseCategory.food,
        allocatedAmount: 0,
      ),
      BudgetCategory(
        category: ExpenseCategory.transportation,
        allocatedAmount: 0,
      ),
      BudgetCategory(
        category: ExpenseCategory.activities,
        allocatedAmount: 0,
      ),
      BudgetCategory(
        category: ExpenseCategory.shopping,
        allocatedAmount: 0,
      ),
      BudgetCategory(
        category: ExpenseCategory.other,
        allocatedAmount: 0,
      ),
    ];
  }
}

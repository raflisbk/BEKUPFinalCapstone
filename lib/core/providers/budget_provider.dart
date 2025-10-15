import 'package:flutter/foundation.dart';
import '../utils/logger.dart';
import '../interfaces/budget_service_interface.dart';

/// Example Budget Provider using Dependency Injection
/// Shows how to use refactored services with DI pattern
class BudgetProvider with ChangeNotifier {
  static const String _tag = 'BudgetProvider';

  // Service instance from dependency injection
  final IBudgetService _budgetService;

  List<Map<String, dynamic>> _budgets = [];
  List<Map<String, dynamic>> _expenses = [];
  Map<String, dynamic>? _selectedBudget;
  bool _isLoading = false;
  String? _error;

  // Constructor with dependency injection
  BudgetProvider({required IBudgetService budgetService})
      : _budgetService = budgetService;

  // Getters
  List<Map<String, dynamic>> get budgets => _budgets;
  List<Map<String, dynamic>> get expenses => _expenses;
  Map<String, dynamic>? get selectedBudget => _selectedBudget;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Private methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void clearError() => _setError(null);

  // Budget operations
  Future<void> createBudget({
    required String tripId,
    required double totalBudget,
    required String currency,
    Map<String, double>? categoryBudgets,
    String? description,
  }) async {
    try {
      AppLogger.debug(_tag, 'Creating budget for trip: $tripId');
      _setLoading(true);
      _setError(null);

      final budget = await _budgetService.createBudget(
        tripId: tripId,
        totalBudget: totalBudget,
        currency: currency,
        categoryBudgets: categoryBudgets,
        description: description,
      );

      _budgets.add(budget);
      _selectedBudget = budget;

      AppLogger.success(_tag, 'Budget created successfully');
      notifyListeners();
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to create budget', e, stackTrace);
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadTripBudget(String tripId) async {
    try {
      AppLogger.debug(_tag, 'Loading budget for trip: $tripId');
      _setLoading(true);
      _setError(null);

      final budget = await _budgetService.getTripBudget(tripId);
      _selectedBudget = budget;

      if (budget != null) {
        await loadTripExpenses(tripId);
      }

      AppLogger.success(_tag, 'Budget loaded successfully');
      notifyListeners();
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to load budget', e, stackTrace);
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadTripExpenses(String tripId) async {
    try {
      AppLogger.debug(_tag, 'Loading expenses for trip: $tripId');

      final expenses = await _budgetService.getTripExpenses(tripId: tripId);
      _expenses = expenses;

      AppLogger.success(_tag, 'Expenses loaded successfully');
      notifyListeners();
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to load expenses', e, stackTrace);
      _setError(e.toString());
    }
  }

  Future<void> addExpense({
    required String budgetId,
    required String categoryId,
    required double amount,
    required String description,
    String? location,
    DateTime? date,
    List<String>? receiptUrls,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      AppLogger.debug(_tag, 'Adding expense: $description');
      _setLoading(true);
      _setError(null);

      final expense = await _budgetService.addExpense(
        budgetId: budgetId,
        categoryId: categoryId,
        amount: amount,
        description: description,
        location: location,
        date: date,
        receiptUrls: receiptUrls,
        metadata: metadata,
      );

      _expenses.add(expense);

      AppLogger.success(_tag, 'Expense added successfully');
      notifyListeners();
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to add expense', e, stackTrace);
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateExpense({
    required String expenseId,
    String? categoryId,
    double? amount,
    String? description,
    String? location,
    DateTime? date,
    List<String>? receiptUrls,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      AppLogger.debug(_tag, 'Updating expense: $expenseId');
      _setLoading(true);
      _setError(null);

      final updatedExpense = await _budgetService.updateExpense(
        expenseId: expenseId,
        categoryId: categoryId,
        amount: amount,
        description: description,
        location: location,
        date: date,
        receiptUrls: receiptUrls,
        metadata: metadata,
      );

      final index = _expenses.indexWhere((e) => e['id'] == expenseId);
      if (index >= 0) {
        _expenses[index] = updatedExpense;
      }

      AppLogger.success(_tag, 'Expense updated successfully');
      notifyListeners();
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to update expense', e, stackTrace);
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteExpense(String expenseId) async {
    try {
      AppLogger.debug(_tag, 'Deleting expense: $expenseId');
      _setLoading(true);
      _setError(null);

      await _budgetService.deleteExpense(expenseId);
      _expenses.removeWhere((e) => e['id'] == expenseId);

      AppLogger.success(_tag, 'Expense deleted successfully');
      notifyListeners();
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to delete expense', e, stackTrace);
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>?> getBudgetAnalytics(String budgetId) async {
    try {
      AppLogger.debug(_tag, 'Getting budget analytics: $budgetId');
      _setLoading(true);

      final analytics = await _budgetService.getBudgetAnalytics(budgetId);
      
      AppLogger.success(_tag, 'Budget analytics loaded');
      notifyListeners();
      
      return analytics;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get budget analytics', e, stackTrace);
      _setError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }

  void selectBudget(Map<String, dynamic> budget) {
    _selectedBudget = budget;
    notifyListeners();
  }

  void clearSelection() {
    _selectedBudget = null;
    notifyListeners();
  }

  void reset() {
    _budgets.clear();
    _expenses.clear();
    _selectedBudget = null;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
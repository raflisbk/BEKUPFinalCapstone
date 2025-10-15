/// Budget Service Interface
/// Defines contract for budget management operations
abstract class IBudgetService {
  // ===============================
  // BUDGET MANAGEMENT
  // ===============================

  /// Create budget for trip
  Future<Map<String, dynamic>> createBudget({
    required String tripId,
    required double totalBudget,
    required String currency,
    Map<String, double>? categoryBudgets,
    String? description,
  });

  /// Get trip budget
  Future<Map<String, dynamic>?> getTripBudget(String tripId);

  /// Update budget
  Future<Map<String, dynamic>> updateBudget({
    required String budgetId,
    double? totalBudget,
    String? currency,
    Map<String, double>? categoryBudgets,
    String? description,
  });

  // ===============================
  // EXPENSE MANAGEMENT
  // ===============================

  /// Add expense to budget
  Future<Map<String, dynamic>> addExpense({
    required String budgetId,
    required String categoryId,
    required double amount,
    required String description,
    String? location,
    DateTime? date,
    List<String>? receiptUrls,
    Map<String, dynamic>? metadata,
  });

  /// Get trip expenses
  Future<List<Map<String, dynamic>>> getTripExpenses({
    required String tripId,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    int? offset,
  });

  /// Update expense
  Future<Map<String, dynamic>> updateExpense({
    required String expenseId,
    String? categoryId,
    double? amount,
    String? description,
    String? location,
    DateTime? date,
    List<String>? receiptUrls,
    Map<String, dynamic>? metadata,
  });

  /// Delete expense
  Future<void> deleteExpense(String expenseId);

  // ===============================
  // EXPENSE CATEGORIES
  // ===============================

  /// Get expense categories
  Future<List<Map<String, dynamic>>> getExpenseCategories();

  /// Create expense category
  Future<Map<String, dynamic>> createExpenseCategory({
    required String name,
    required String icon,
    required String color,
    String? description,
  });

  // ===============================
  // ANALYTICS & REPORTING
  // ===============================

  /// Get expense breakdown by category
  Future<Map<String, dynamic>> getExpenseBreakdown(String budgetId);

  /// Get budget analytics
  Future<Map<String, dynamic>> getBudgetAnalytics(String budgetId);

  // ===============================
  // EXPENSE SPLITTING
  // ===============================

  /// Split expense among trip participants
  Future<Map<String, dynamic>> splitExpense({
    required String expenseId,
    required List<String> participantIds,
    Map<String, double>? customSplits,
    String splitType = 'equal',
  });

  /// Get user split expenses
  Future<List<Map<String, dynamic>>> getUserSplitExpenses(String userId);

  // ===============================
  // CURRENCY OPERATIONS
  // ===============================

  /// Get supported currencies
  Future<List<Map<String, dynamic>>> getSupportedCurrencies();

  /// Convert currency
  Future<double> convertCurrency({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
  });
}
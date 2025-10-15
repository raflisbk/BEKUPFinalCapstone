import 'dart:async';
import '../core/interfaces/budget_service_interface.dart';
import '../core/utils/logger.dart';
import 'supabase_config.dart';
import 'supabase_database_service.dart';

/// Budget Service Implementation
/// Handles trip budgeting, expense tracking, and financial analytics
class BudgetService implements IBudgetService {
  static const String _tag = 'BudgetService';
  static const String _budgetsTable = 'trip_budgets';
  static const String _expensesTable = 'trip_expenses';
  static const String _categoriesTable = 'expense_categories';
  static const String _currencyTable = 'currencies';

  /// Constructor with dependency injection
  BudgetService();

  // ===============================
  // BUDGET MANAGEMENT
  // ===============================

  /// Create budget for trip
  @override
  Future<Map<String, dynamic>> createBudget({
    required String tripId,
    required double totalBudget,
    required String currency,
    Map<String, double>? categoryBudgets,
    String? description,
  }) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Creating budget for trip: $tripId');

      final budgetData = {
        'trip_id': tripId,
        'created_by': userId,
        'total_budget': totalBudget,
        'currency': currency,
        'category_budgets': categoryBudgets ?? {},
        'total_spent': 0.0,
        'remaining_budget': totalBudget,
        'description': description,
        'is_active': true,
      };

      final result = await SupabaseDatabaseService.insert(
        table: _budgetsTable,
        data: budgetData,
      );

      AppLogger.success(_tag, 'Budget created successfully for trip: $tripId');
      return result;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to create budget', e, stackTrace);
      rethrow;
    }
  }

  /// Get trip budget
  @override
  Future<Map<String, dynamic>?> getTripBudget(String tripId) async {
    try {
      AppLogger.debug(_tag, 'Getting budget for trip: $tripId');

      final budgets = await SupabaseDatabaseService.select(
        table: _budgetsTable,
        filters: {'trip_id': tripId, 'is_active': true},
        orderBy: 'created_at',
        ascending: false,
        limit: 1,
      );

      if (budgets.isEmpty) {
        AppLogger.warning(_tag, 'No active budget found for trip: $tripId');
        return null;
      }

      final budget = budgets.first;
      
      // Get recent expenses to update spending
      await _updateBudgetSpending(budget['id']);
      
      // Re-fetch updated budget
      final updatedBudgets = await SupabaseDatabaseService.select(
        table: _budgetsTable,
        filters: {'id': budget['id']},
      );

      final updatedBudget = updatedBudgets.first;
      
      // Get expense breakdown by category
      updatedBudget['expense_breakdown'] = await getExpenseBreakdown(budget['id']);
      
      AppLogger.success(_tag, 'Retrieved trip budget');
      return updatedBudget;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get trip budget', e, stackTrace);
      rethrow;
    }
  }

  /// Update budget
  @override
  Future<Map<String, dynamic>> updateBudget({
    required String budgetId,
    double? totalBudget,
    String? currency,
    Map<String, double>? categoryBudgets,
    String? description,
  }) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Updating budget: $budgetId');

      final updateData = <String, dynamic>{};
      if (totalBudget != null) updateData['total_budget'] = totalBudget;
      if (currency != null) updateData['currency'] = currency;
      if (categoryBudgets != null) updateData['category_budgets'] = categoryBudgets;
      if (description != null) updateData['description'] = description;

      updateData['updated_at'] = DateTime.now().toIso8601String();

      final result = await SupabaseDatabaseService.update(
        table: _budgetsTable,
        id: budgetId,
        data: updateData,
      );

      // Update remaining budget calculation
      if (totalBudget != null) {
        await _updateBudgetSpending(budgetId);
      }

      AppLogger.success(_tag, 'Budget updated successfully');
      return result;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to update budget', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // EXPENSE MANAGEMENT
  // ===============================

  /// Add expense to budget
  @override
  Future<Map<String, dynamic>> addExpense({
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
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Adding expense to budget: $budgetId');

      final expenseData = {
        'budget_id': budgetId,
        'category_id': categoryId,
        'created_by': userId,
        'amount': amount,
        'description': description,
        'location': location,
        'expense_date': (date ?? DateTime.now()).toIso8601String(),
        'receipt_urls': receiptUrls ?? [],
        'metadata': metadata ?? {},
        'is_split': false,
      };

      final result = await SupabaseDatabaseService.insert(
        table: _expensesTable,
        data: expenseData,
      );

      // Update budget spending
      await _updateBudgetSpending(budgetId);

      AppLogger.success(_tag, 'Expense added successfully');
      return result;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to add expense', e, stackTrace);
      rethrow;
    }
  }

  /// Get trip expenses
  @override
  Future<List<Map<String, dynamic>>> getTripExpenses({
    required String tripId,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    int? offset,
  }) async {
    try {
      AppLogger.debug(_tag, 'Getting expenses for trip: $tripId');

      // First get the budget for this trip
      final budget = await getTripBudget(tripId);
      if (budget == null) {
        throw Exception('No active budget found for trip: $tripId');
      }

      final filters = <String, dynamic>{'budget_id': budget['id']};
      if (categoryId != null) filters['category_id'] = categoryId;

      final expenses = await SupabaseDatabaseService.select(
        table: _expensesTable,
        filters: filters,
        orderBy: 'expense_date',
        ascending: false,
        limit: limit,
        offset: offset,
      );

      // Filter by date range if provided
      List<Map<String, dynamic>> filteredExpenses = expenses;
      if (startDate != null || endDate != null) {
        filteredExpenses = expenses.where((expense) {
          final expenseDate = DateTime.parse(expense['expense_date']);
          if (startDate != null && expenseDate.isBefore(startDate)) return false;
          if (endDate != null && expenseDate.isAfter(endDate)) return false;
          return true;
        }).toList();
      }

      AppLogger.success(_tag, 'Retrieved ${filteredExpenses.length} expenses');
      return filteredExpenses;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get trip expenses', e, stackTrace);
      rethrow;
    }
  }

  /// Update expense
  @override
  Future<Map<String, dynamic>> updateExpense({
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

      final updateData = <String, dynamic>{};
      if (categoryId != null) updateData['category_id'] = categoryId;
      if (amount != null) updateData['amount'] = amount;
      if (description != null) updateData['description'] = description;
      if (location != null) updateData['location'] = location;
      if (date != null) updateData['expense_date'] = date.toIso8601String();
      if (receiptUrls != null) updateData['receipt_urls'] = receiptUrls;
      if (metadata != null) updateData['metadata'] = metadata;

      updateData['updated_at'] = DateTime.now().toIso8601String();

      final result = await SupabaseDatabaseService.update(
        table: _expensesTable,
        id: expenseId,
        data: updateData,
      );

      // Update budget spending if amount changed
      if (amount != null) {
        final expense = await _getExpense(expenseId);
        if (expense != null) {
          await _updateBudgetSpending(expense['budget_id']);
        }
      }

      AppLogger.success(_tag, 'Expense updated successfully');
      return result;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to update expense', e, stackTrace);
      rethrow;
    }
  }

  /// Delete expense
  @override
  Future<void> deleteExpense(String expenseId) async {
    try {
      AppLogger.warning(_tag, 'Deleting expense: $expenseId');

      // Get expense before deletion to update budget
      final expense = await _getExpense(expenseId);

      await SupabaseDatabaseService.delete(
        table: _expensesTable,
        id: expenseId,
      );

      // Update budget spending
      if (expense != null) {
        await _updateBudgetSpending(expense['budget_id']);
      }

      AppLogger.success(_tag, 'Expense deleted successfully');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to delete expense', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // EXPENSE CATEGORIES
  // ===============================

  /// Get expense categories
  @override
  Future<List<Map<String, dynamic>>> getExpenseCategories() async {
    try {
      AppLogger.debug(_tag, 'Getting expense categories');

      final categories = await SupabaseDatabaseService.select(
        table: _categoriesTable,
        orderBy: 'name',
        ascending: true,
      );

      AppLogger.success(_tag, 'Retrieved ${categories.length} expense categories');
      return categories;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get expense categories', e, stackTrace);
      rethrow;
    }
  }

  /// Create expense category
  @override
  Future<Map<String, dynamic>> createExpenseCategory({
    required String name,
    required String icon,
    required String color,
    String? description,
  }) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Creating expense category: $name');

      final categoryData = {
        'name': name,
        'icon': icon,
        'color': color,
        'description': description,
        'created_by': userId,
        'is_custom': true,
        'is_active': true,
      };

      final result = await SupabaseDatabaseService.insert(
        table: _categoriesTable,
        data: categoryData,
      );

      AppLogger.success(_tag, 'Expense category created successfully');
      return result;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to create expense category', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // ANALYTICS & REPORTING
  // ===============================

  /// Get expense breakdown by category
  @override
  Future<Map<String, dynamic>> getExpenseBreakdown(String budgetId) async {
    try {
      AppLogger.debug(_tag, 'Getting expense breakdown for budget: $budgetId');

      // Get all expenses for this budget
      final expenses = await SupabaseDatabaseService.select(
        table: _expensesTable,
        filters: {'budget_id': budgetId},
      );

      // Get all categories
      final categories = await SupabaseDatabaseService.select(
        table: _categoriesTable,
      );

      // Group expenses by category
      final categoryMap = <String, Map<String, dynamic>>{};
      for (final category in categories) {
        categoryMap[category['id']] = {
          'category_name': category['name'],
          'category_icon': category['icon'],
          'category_color': category['color'],
          'total_amount': 0.0,
          'expense_count': 0,
        };
      }

      // Calculate totals per category
      for (final expense in expenses) {
        final categoryId = expense['category_id'];
        if (categoryMap.containsKey(categoryId)) {
          categoryMap[categoryId]!['total_amount'] += expense['amount'];
          categoryMap[categoryId]!['expense_count']++;
        }
      }

      // Convert to list and filter out zero amounts
      final result = categoryMap.values
          .where((category) => category['expense_count'] > 0)
          .toList()
        ..sort((a, b) => b['total_amount'].compareTo(a['total_amount']));

      final breakdown = <String, dynamic>{
        'categories': result,
        'total_expenses': result.fold<double>(0, (sum, item) => sum + item['total_amount']),
        'total_transactions': result.fold<int>(0, (sum, item) => sum + item['expense_count'] as int),
      };

      AppLogger.success(_tag, 'Retrieved expense breakdown');
      return breakdown;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get expense breakdown', e, stackTrace);
      rethrow;
    }
  }

  /// Get budget analytics
  @override
  Future<Map<String, dynamic>> getBudgetAnalytics(String budgetId) async {
    try {
      AppLogger.debug(_tag, 'Getting budget analytics: $budgetId');

      final budget = await _getBudget(budgetId);
      if (budget == null) {
        throw Exception('Budget not found: $budgetId');
      }

      // Get all expenses for this budget
      final expenses = await SupabaseDatabaseService.select(
        table: _expensesTable,
        filters: {'budget_id': budgetId},
        orderBy: 'expense_date',
        ascending: true,
      );

      // Calculate daily spending
      final dailySpending = <String, double>{};
      for (final expense in expenses) {
        final date = DateTime.parse(expense['expense_date']).toIso8601String().split('T')[0];
        dailySpending[date] = (dailySpending[date] ?? 0) + expense['amount'];
      }

      // Calculate spending trend
      final last30Days = List.generate(30, (index) {
        final date = DateTime.now().subtract(Duration(days: 29 - index));
        final dateStr = date.toIso8601String().split('T')[0];
        return {
          'date': dateStr,
          'amount': dailySpending[dateStr] ?? 0.0,
        };
      });

      // Budget utilization
      final totalBudget = budget['total_budget'].toDouble();
      final totalSpent = budget['total_spent'].toDouble();
      final utilizationPercentage = totalBudget > 0 ? (totalSpent / totalBudget) * 100 : 0;

      // Category analysis
      final categoryBreakdown = await getExpenseBreakdown(budgetId);

      final analytics = {
        'budget_id': budgetId,
        'total_budget': totalBudget,
        'total_spent': totalSpent,
        'remaining_budget': totalBudget - totalSpent,
        'utilization_percentage': utilizationPercentage,
        'daily_spending_trend': last30Days,
        'category_breakdown': categoryBreakdown,
        'expense_count': expenses.length,
        'average_expense': expenses.isNotEmpty ? totalSpent / expenses.length : 0.0,
        'currency': budget['currency'],
        'analysis_date': DateTime.now().toIso8601String(),
      };

      AppLogger.success(_tag, 'Retrieved budget analytics');
      return analytics;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get budget analytics', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // EXPENSE SPLITTING
  // ===============================

  /// Split expense among trip participants
  @override
  Future<Map<String, dynamic>> splitExpense({
    required String expenseId,
    required List<String> participantIds,
    Map<String, double>? customSplits,
    String splitType = 'equal',
  }) async {
    try {
      AppLogger.debug(_tag, 'Splitting expense: $expenseId');

      final expense = await _getExpense(expenseId);
      if (expense == null) {
        throw Exception('Expense not found: $expenseId');
      }

      final totalAmount = expense['amount'].toDouble();
      Map<String, double> splits;

      if (splitType == 'equal') {
        final splitAmount = totalAmount / participantIds.length;
        splits = Map.fromIterable(
          participantIds,
          key: (id) => id.toString(),
          value: (_) => splitAmount,
        );
      } else if (splitType == 'custom' && customSplits != null) {
        splits = customSplits;
      } else {
        throw Exception('Invalid split type or missing custom splits');
      }

      // Create split records
      final splitRecords = <Map<String, dynamic>>[];
      for (final entry in splits.entries) {
        splitRecords.add({
          'expense_id': expenseId,
          'user_id': entry.key,
          'amount': entry.value,
          'split_type': splitType,
          'status': 'pending',
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      await SupabaseDatabaseService.batchInsert(
        table: 'expense_splits',
        dataList: splitRecords,
      );

      // Update expense as split
      await SupabaseDatabaseService.update(
        table: _expensesTable,
        id: expenseId,
        data: {'is_split': true, 'split_type': splitType},
      );

      AppLogger.success(_tag, 'Expense split successfully');
      return {
        'expense_id': expenseId,
        'total_amount': totalAmount,
        'participants': participantIds.length,
        'splits': splits,
        'split_type': splitType,
      };
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to split expense', e, stackTrace);
      rethrow;
    }
  }

  /// Get user split expenses
  @override
  Future<List<Map<String, dynamic>>> getUserSplitExpenses(String userId) async {
    try {
      AppLogger.debug(_tag, 'Getting split expenses for user: $userId');

      // Get split records for user
      final splitRecords = await SupabaseDatabaseService.select(
        table: 'expense_splits',
        filters: {'user_id': userId},
        orderBy: 'created_at',
        ascending: false,
      );

      // Enrich with expense and category details
      final enrichedSplits = <Map<String, dynamic>>[];
      for (final split in splitRecords) {
        final expense = await _getExpense(split['expense_id']);
        if (expense != null) {
          // Get category details
          final categories = await SupabaseDatabaseService.select(
            table: _categoriesTable,
            filters: {'id': expense['category_id']},
          );
          
          final enrichedSplit = Map<String, dynamic>.from(split);
          enrichedSplit['description'] = expense['description'];
          enrichedSplit['expense_date'] = expense['expense_date'];
          enrichedSplit['location'] = expense['location'];
          enrichedSplit['category_name'] = categories.isNotEmpty ? categories.first['name'] : 'Unknown';
          
          enrichedSplits.add(enrichedSplit);
        }
      }

      AppLogger.success(_tag, 'Retrieved ${enrichedSplits.length} split expenses');
      return enrichedSplits;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get user split expenses', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // CURRENCY OPERATIONS
  // ===============================

  /// Get supported currencies
  @override
  Future<List<Map<String, dynamic>>> getSupportedCurrencies() async {
    try {
      AppLogger.debug(_tag, 'Getting supported currencies');

      final currencies = await SupabaseDatabaseService.select(
        table: _currencyTable,
        filters: {'is_active': true},
        orderBy: 'code',
        ascending: true,
      );

      AppLogger.success(_tag, 'Retrieved ${currencies.length} currencies');
      return currencies;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get supported currencies', e, stackTrace);
      rethrow;
    }
  }

  /// Convert currency (simplified - in production use real exchange rates)
  @override
  Future<double> convertCurrency({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
  }) async {
    try {
      if (fromCurrency == toCurrency) return amount;

      AppLogger.debug(_tag, 'Converting $amount from $fromCurrency to $toCurrency');

      // This is a simplified conversion - in production, use real exchange rate API
      const exchangeRates = {
        'USD_IDR': 15000.0,
        'EUR_IDR': 16500.0,
        'JPY_IDR': 110.0,
        'SGD_IDR': 11000.0,
        'MYR_IDR': 3200.0,
      };

      final rateKey = '${fromCurrency}_$toCurrency';
      final reverseRateKey = '${toCurrency}_$fromCurrency';

      double rate = 1.0;
      if (exchangeRates.containsKey(rateKey)) {
        rate = exchangeRates[rateKey]!;
      } else if (exchangeRates.containsKey(reverseRateKey)) {
        rate = 1.0 / exchangeRates[reverseRateKey]!;
      }

      final convertedAmount = amount * rate;
      
      AppLogger.success(_tag, 'Currency converted: $amount $fromCurrency = $convertedAmount $toCurrency');
      return convertedAmount;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to convert currency', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // PRIVATE HELPER METHODS
  // ===============================

  /// Get budget by ID
  Future<Map<String, dynamic>?> _getBudget(String budgetId) async {
    final budgets = await SupabaseDatabaseService.select(
      table: _budgetsTable,
      filters: {'id': budgetId},
    );
    return budgets.isNotEmpty ? budgets.first : null;
  }

  /// Get expense by ID
  Future<Map<String, dynamic>?> _getExpense(String expenseId) async {
    final expenses = await SupabaseDatabaseService.select(
      table: _expensesTable,
      filters: {'id': expenseId},
    );
    return expenses.isNotEmpty ? expenses.first : null;
  }

  /// Update budget spending totals
  Future<void> _updateBudgetSpending(String budgetId) async {
    final expenses = await SupabaseDatabaseService.select(
      table: _expensesTable,
      filters: {'budget_id': budgetId},
    );

    final totalSpent = expenses.fold<double>(
      0.0,
      (sum, expense) => sum + expense['amount'],
    );

    final budget = await _getBudget(budgetId);
    if (budget != null) {
      final totalBudget = budget['total_budget'].toDouble();
      final remainingBudget = totalBudget - totalSpent;

      await SupabaseDatabaseService.update(
        table: _budgetsTable,
        id: budgetId,
        data: {
          'total_spent': totalSpent,
          'remaining_budget': remainingBudget,
          'updated_at': DateTime.now().toIso8601String(),
        },
      );
    }
  }
}
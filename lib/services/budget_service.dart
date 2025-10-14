import 'dart:async';
import '../core/utils/logger.dart';
import 'supabase_config.dart';
import 'supabase_database_service.dart';

/// Budget Service
/// Handles trip budgeting, expense tracking, and financial analytics
class BudgetService {
  static const String _tag = 'BudgetService';
  static const String _budgetsTable = 'trip_budgets';
  static const String _expensesTable = 'trip_expenses';
  static const String _categoriesTable = 'expense_categories';
  static const String _currencyTable = 'currencies';

  // ===============================
  // BUDGET MANAGEMENT
  // ===============================

  /// Create budget for trip
  static Future<Map<String, dynamic>> createBudget({
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
  static Future<Map<String, dynamic>?> getTripBudget(String tripId) async {
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
  static Future<Map<String, dynamic>> updateBudget({
    required String budgetId,
    double? totalBudget,
    String? currency,
    Map<String, double>? categoryBudgets,
    String? description,
  }) async {
    try {
      AppLogger.debug(_tag, 'Updating budget: $budgetId');

      final updateData = <String, dynamic>{};
      
      if (totalBudget != null) {
        updateData['total_budget'] = totalBudget;
        // Recalculate remaining budget
        final budget = await _getBudget(budgetId);
        if (budget != null) {
          updateData['remaining_budget'] = totalBudget - (budget['total_spent'] ?? 0.0);
        }
      }
      if (currency != null) updateData['currency'] = currency;
      if (categoryBudgets != null) updateData['category_budgets'] = categoryBudgets;
      if (description != null) updateData['description'] = description;

      if (updateData.isEmpty) {
        throw Exception('No data provided for update');
      }

      final result = await SupabaseDatabaseService.update(
        table: _budgetsTable,
        id: budgetId,
        data: updateData,
      );

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

  /// Add expense
  static Future<Map<String, dynamic>> addExpense({
    required String budgetId,
    required String tripId,
    required String title,
    required double amount,
    required String currency,
    required String category,
    String? description,
    DateTime? expenseDate,
    String? location,
    String? notes,
    String? receiptUrl,
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
        'trip_id': tripId,
        'added_by': userId,
        'title': title,
        'amount': amount,
        'currency': currency,
        'category': category,
        'description': description,
        'expense_date': (expenseDate ?? DateTime.now()).toIso8601String(),
        'location': location,
        'notes': notes,
        'receipt_url': receiptUrl,
        'metadata': metadata ?? {},
        'is_shared': false,
        'split_among': [],
      };

      final result = await SupabaseDatabaseService.insert(
        table: _expensesTable,
        data: expenseData,
      );

      // Update budget spending
      await _updateBudgetSpending(budgetId);

      AppLogger.success(_tag, 'Expense added successfully: $title');
      return result;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to add expense', e, stackTrace);
      rethrow;
    }
  }

  /// Get trip expenses
  static Future<List<Map<String, dynamic>>> getTripExpenses({
    required String tripId,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    String? addedBy,
    int limit = 50,
  }) async {
    try {
      AppLogger.debug(_tag, 'Getting expenses for trip: $tripId');

      final filters = <String, dynamic>{'trip_id': tripId};
      if (category != null) filters['category'] = category;
      if (addedBy != null) filters['added_by'] = addedBy;

      var expenses = await SupabaseDatabaseService.select(
        table: _expensesTable,
        filters: filters,
        orderBy: 'expense_date',
        ascending: false,
        limit: limit,
      );

      // Filter by date range if provided
      if (startDate != null || endDate != null) {
        expenses = expenses.where((expense) {
          final expenseDate = DateTime.parse(expense['expense_date']);
          
          if (startDate != null && expenseDate.isBefore(startDate)) {
            return false;
          }
          
          if (endDate != null && expenseDate.isAfter(endDate)) {
            return false;
          }
          
          return true;
        }).toList();
      }

      AppLogger.success(_tag, 'Retrieved ${expenses.length} expenses');
      return expenses;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get trip expenses', e, stackTrace);
      rethrow;
    }
  }

  /// Update expense
  static Future<Map<String, dynamic>> updateExpense({
    required String expenseId,
    String? title,
    double? amount,
    String? currency,
    String? category,
    String? description,
    DateTime? expenseDate,
    String? location,
    String? notes,
    String? receiptUrl,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      AppLogger.debug(_tag, 'Updating expense: $expenseId');

      final updateData = <String, dynamic>{};
      
      if (title != null) updateData['title'] = title;
      if (amount != null) updateData['amount'] = amount;
      if (currency != null) updateData['currency'] = currency;
      if (category != null) updateData['category'] = category;
      if (description != null) updateData['description'] = description;
      if (expenseDate != null) updateData['expense_date'] = expenseDate.toIso8601String();
      if (location != null) updateData['location'] = location;
      if (notes != null) updateData['notes'] = notes;
      if (receiptUrl != null) updateData['receipt_url'] = receiptUrl;
      if (metadata != null) updateData['metadata'] = metadata;

      if (updateData.isEmpty) {
        throw Exception('No data provided for update');
      }

      final result = await SupabaseDatabaseService.update(
        table: _expensesTable,
        id: expenseId,
        data: updateData,
      );

      // Get expense to update budget
      final expense = await _getExpense(expenseId);
      if (expense != null) {
        await _updateBudgetSpending(expense['budget_id']);
      }

      AppLogger.success(_tag, 'Expense updated successfully');
      return result;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to update expense', e, stackTrace);
      rethrow;
    }
  }

  /// Delete expense
  static Future<void> deleteExpense(String expenseId) async {
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
  static Future<List<Map<String, dynamic>>> getExpenseCategories() async {
    try {
      AppLogger.debug(_tag, 'Getting expense categories');

      final categories = await SupabaseDatabaseService.select(
        table: _categoriesTable,
        orderBy: 'name',
      );

      AppLogger.success(_tag, 'Retrieved ${categories.length} expense categories');
      return categories;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get expense categories', e, stackTrace);
      rethrow;
    }
  }

  /// Create custom expense category
  static Future<Map<String, dynamic>> createExpenseCategory({
    required String name,
    required String icon,
    String? color,
    String? description,
  }) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Creating expense category: $name');

      final categoryData = {
        'created_by': userId,
        'name': name,
        'icon': icon,
        'color': color ?? '#6B7280',
        'description': description,
        'is_default': false,
        'is_active': true,
      };

      final result = await SupabaseDatabaseService.insert(
        table: _categoriesTable,
        data: categoryData,
      );

      AppLogger.success(_tag, 'Expense category created successfully: $name');
      return result;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to create expense category', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // BUDGET ANALYTICS
  // ===============================

  /// Get expense breakdown by category
  static Future<Map<String, dynamic>> getExpenseBreakdown(String budgetId) async {
    try {
      AppLogger.debug(_tag, 'Getting expense breakdown for budget: $budgetId');

      final expenses = await SupabaseDatabaseService.select(
        table: _expensesTable,
        filters: {'budget_id': budgetId},
      );

      final breakdown = <String, dynamic>{
        'by_category': <String, double>{},
        'by_month': <String, double>{},
        'by_day': <String, double>{},
        'total_expenses': expenses.length,
        'total_amount': 0.0,
      };

      double totalAmount = 0.0;

      for (final expense in expenses) {
        final amount = (expense['amount'] ?? 0.0) as double;
        final category = expense['category'] as String? ?? 'Other';
        final expenseDate = DateTime.parse(expense['expense_date']);
        
        totalAmount += amount;
        
        // By category
        breakdown['by_category'][category] = 
            (breakdown['by_category'][category] ?? 0.0) + amount;
        
        // By month
        final monthKey = '${expenseDate.year}-${expenseDate.month.toString().padLeft(2, '0')}';
        breakdown['by_month'][monthKey] = 
            (breakdown['by_month'][monthKey] ?? 0.0) + amount;
        
        // By day
        final dayKey = '${expenseDate.year}-${expenseDate.month.toString().padLeft(2, '0')}-${expenseDate.day.toString().padLeft(2, '0')}';
        breakdown['by_day'][dayKey] = 
            (breakdown['by_day'][dayKey] ?? 0.0) + amount;
      }

      breakdown['total_amount'] = totalAmount;

      AppLogger.success(_tag, 'Retrieved expense breakdown');
      return breakdown;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get expense breakdown', e, stackTrace);
      rethrow;
    }
  }

  /// Get budget analytics
  static Future<Map<String, dynamic>> getBudgetAnalytics(String budgetId) async {
    try {
      AppLogger.debug(_tag, 'Getting budget analytics: $budgetId');

      final budget = await _getBudget(budgetId);
      if (budget == null) {
        throw Exception('Budget not found');
      }

      final expenses = await SupabaseDatabaseService.select(
        table: _expensesTable,
        filters: {'budget_id': budgetId},
        orderBy: 'expense_date',
      );

      final analytics = <String, dynamic>{
        'budget_id': budgetId,
        'total_budget': budget['total_budget'] ?? 0.0,
        'total_spent': budget['total_spent'] ?? 0.0,
        'remaining_budget': budget['remaining_budget'] ?? 0.0,
        'spend_percentage': 0.0,
        'daily_average': 0.0,
        'projected_total': 0.0,
        'budget_status': 'on_track',
        'spending_trend': [],
        'category_performance': {},
        'recommendations': [],
      };

      final totalBudget = budget['total_budget'] as double;
      final totalSpent = budget['total_spent'] as double;

      if (totalBudget > 0) {
        analytics['spend_percentage'] = (totalSpent / totalBudget * 100).round();
      }

      if (expenses.isNotEmpty) {
        // Calculate daily average
        final firstExpense = DateTime.parse(expenses.first['expense_date']);
        final lastExpense = DateTime.parse(expenses.last['expense_date']);
        final daysDiff = lastExpense.difference(firstExpense).inDays + 1;
        
        if (daysDiff > 0) {
          analytics['daily_average'] = totalSpent / daysDiff;
          
        // Project total spending
        const estimatedTripDays = 7; // Default assumption, can be improved
          analytics['projected_total'] = (totalSpent / daysDiff) * estimatedTripDays;
        }

        // Determine budget status
        final spendPercentage = analytics['spend_percentage'] as double;
        if (spendPercentage > 100) {
          analytics['budget_status'] = 'over_budget';
        } else if (spendPercentage > 80) {
          analytics['budget_status'] = 'warning';
        } else {
          analytics['budget_status'] = 'on_track';
        }

        // Generate spending trend (daily spending)
        analytics['spending_trend'] = _generateSpendingTrend(expenses);

        // Category performance vs budget
        analytics['category_performance'] = _analyzeCategoryPerformance(
          expenses, 
          budget['category_budgets'] ?? {}
        );

        // Generate recommendations
        analytics['recommendations'] = _generateBudgetRecommendations(analytics);
      }

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
  static Future<Map<String, dynamic>> splitExpense({
    required String expenseId,
    required List<String> participantIds,
    Map<String, double>? customSplits, // If not provided, split equally
  }) async {
    try {
      AppLogger.debug(_tag, 'Splitting expense: $expenseId');

      final expense = await _getExpense(expenseId);
      if (expense == null) {
        throw Exception('Expense not found');
      }

      final totalAmount = expense['amount'] as double;
      final splitData = <String, double>{};

      if (customSplits != null) {
        // Use custom split amounts
        splitData.addAll(customSplits);
        
        // Validate total equals expense amount
        final splitTotal = customSplits.values.fold(0.0, (sum, amount) => sum + amount);
        if ((splitTotal - totalAmount).abs() > 0.01) {
          throw Exception('Split amounts do not equal total expense amount');
        }
      } else {
        // Split equally
        final amountPerPerson = totalAmount / participantIds.length;
        for (final participantId in participantIds) {
          splitData[participantId] = amountPerPerson;
        }
      }

      // Update expense with split data
      final result = await SupabaseDatabaseService.update(
        table: _expensesTable,
        id: expenseId,
        data: {
          'is_shared': true,
          'split_among': participantIds,
          'split_data': splitData,
        },
      );

      AppLogger.success(_tag, 'Expense split successfully');
      return result;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to split expense', e, stackTrace);
      rethrow;
    }
  }

  /// Get split expenses for user
  static Future<List<Map<String, dynamic>>> getUserSplitExpenses(String userId) async {
    try {
      AppLogger.debug(_tag, 'Getting split expenses for user: $userId');

      // Get expenses where user is in split_among array
      final expenses = await SupabaseDatabaseService.select(
        table: _expensesTable,
        filters: {'is_shared': true},
        orderBy: 'expense_date',
        ascending: false,
      );

      // Filter expenses where user is in split_among array
      final userExpenses = expenses.where((expense) {
        final splitAmong = List<String>.from(expense['split_among'] ?? []);
        return splitAmong.contains(userId);
      }).toList();

      // Calculate user's share for each expense
      for (final expense in userExpenses) {
        final splitData = Map<String, dynamic>.from(expense['split_data'] ?? {});
        expense['user_share'] = splitData[userId] ?? 0.0;
      }

      AppLogger.success(_tag, 'Retrieved ${userExpenses.length} split expenses');
      return userExpenses;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get user split expenses', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // CURRENCY CONVERSION
  // ===============================

  /// Get supported currencies
  static Future<List<Map<String, dynamic>>> getSupportedCurrencies() async {
    try {
      AppLogger.debug(_tag, 'Getting supported currencies');

      final currencies = await SupabaseDatabaseService.select(
        table: _currencyTable,
        orderBy: 'code',
      );

      AppLogger.success(_tag, 'Retrieved ${currencies.length} currencies');
      return currencies;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get supported currencies', e, stackTrace);
      rethrow;
    }
  }

  /// Convert currency (simplified - in production use real exchange rates)
  static Future<double> convertCurrency({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
  }) async {
    try {
      if (fromCurrency == toCurrency) {
        return amount;
      }

      AppLogger.debug(_tag, 'Converting $amount from $fromCurrency to $toCurrency');

      // Simplified conversion rates (in production, fetch from API)
      final rates = {
        'IDR': 1.0,
        'USD': 15500.0,
        'EUR': 17000.0,
        'SGD': 11500.0,
        'MYR': 3500.0,
        'THB': 450.0,
      };

      final fromRate = rates[fromCurrency] ?? 1.0;
      final toRate = rates[toCurrency] ?? 1.0;

      final convertedAmount = (amount / fromRate) * toRate;

      AppLogger.success(_tag, 'Currency converted successfully');
      return convertedAmount;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to convert currency', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // PRIVATE HELPER METHODS
  // ===============================

  /// Get single budget
  static Future<Map<String, dynamic>?> _getBudget(String budgetId) async {
    try {
      final budgets = await SupabaseDatabaseService.select(
        table: _budgetsTable,
        filters: {'id': budgetId},
      );
      return budgets.isNotEmpty ? budgets.first : null;
    } catch (e) {
      return null;
    }
  }

  /// Get single expense
  static Future<Map<String, dynamic>?> _getExpense(String expenseId) async {
    try {
      final expenses = await SupabaseDatabaseService.select(
        table: _expensesTable,
        filters: {'id': expenseId},
      );
      return expenses.isNotEmpty ? expenses.first : null;
    } catch (e) {
      return null;
    }
  }

  /// Update budget spending totals
  static Future<void> _updateBudgetSpending(String budgetId) async {
    try {
      final expenses = await SupabaseDatabaseService.select(
        table: _expensesTable,
        filters: {'budget_id': budgetId},
      );

      final totalSpent = expenses.fold(0.0, (sum, expense) {
        return sum + ((expense['amount'] ?? 0.0) as double);
      });

      final budget = await _getBudget(budgetId);
      if (budget != null) {
        final totalBudget = budget['total_budget'] as double;
        final remainingBudget = totalBudget - totalSpent;

        await SupabaseDatabaseService.update(
          table: _budgetsTable,
          id: budgetId,
          data: {
            'total_spent': totalSpent,
            'remaining_budget': remainingBudget,
          },
        );
      }
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to update budget spending', e);
    }
  }

  /// Generate spending trend data
  static List<Map<String, dynamic>> _generateSpendingTrend(List<Map<String, dynamic>> expenses) {
    final trendData = <Map<String, dynamic>>[];
    final dailySpending = <String, double>{};

    // Group expenses by date
    for (final expense in expenses) {
      final expenseDate = DateTime.parse(expense['expense_date']);
      final dateKey = '${expenseDate.year}-${expenseDate.month.toString().padLeft(2, '0')}-${expenseDate.day.toString().padLeft(2, '0')}';
      final amount = (expense['amount'] ?? 0.0) as double;
      
      dailySpending[dateKey] = (dailySpending[dateKey] ?? 0.0) + amount;
    }

    // Convert to trend data
    final sortedDates = dailySpending.keys.toList()..sort();
    double cumulativeSpending = 0.0;

    for (final date in sortedDates) {
      final dailyAmount = dailySpending[date]!;
      cumulativeSpending += dailyAmount;
      
      trendData.add({
        'date': date,
        'daily_amount': dailyAmount,
        'cumulative_amount': cumulativeSpending,
      });
    }

    return trendData;
  }

  /// Analyze category performance vs budget
  static Map<String, dynamic> _analyzeCategoryPerformance(
    List<Map<String, dynamic>> expenses, 
    Map<String, dynamic> categoryBudgets
  ) {
    final performance = <String, dynamic>{};
    final categorySpending = <String, double>{};

    // Calculate actual spending per category
    for (final expense in expenses) {
      final category = expense['category'] as String? ?? 'Other';
      final amount = (expense['amount'] ?? 0.0) as double;
      categorySpending[category] = (categorySpending[category] ?? 0.0) + amount;
    }

    // Compare with budgets
    for (final category in categoryBudgets.keys) {
      final budgetAmount = (categoryBudgets[category] ?? 0.0) as double;
      final spentAmount = categorySpending[category] ?? 0.0;
      final percentage = budgetAmount > 0 ? (spentAmount / budgetAmount * 100) : 0.0;

      performance[category] = {
        'budget': budgetAmount,
        'spent': spentAmount,
        'remaining': budgetAmount - spentAmount,
        'percentage': percentage.round(),
        'status': percentage > 100 ? 'over' : percentage > 80 ? 'warning' : 'good',
      };
    }

    return performance;
  }

  /// Generate budget recommendations
  static List<String> _generateBudgetRecommendations(Map<String, dynamic> analytics) {
    final recommendations = <String>[];
    final spendPercentage = analytics['spend_percentage'] as double;
    final projectedTotal = analytics['projected_total'] as double;
    final totalBudget = analytics['total_budget'] as double;

    if (spendPercentage > 100) {
      recommendations.add('Anda telah melebihi anggaran. Pertimbangkan untuk mengurangi pengeluaran.');
    } else if (spendPercentage > 80) {
      recommendations.add('Perhatian! Anda telah menggunakan 80% dari anggaran.');
    }

    if (projectedTotal > totalBudget) {
      final excess = ((projectedTotal - totalBudget) / totalBudget * 100).round();
      recommendations.add('Berdasarkan pola pengeluaran saat ini, Anda dapat melebihi anggaran sebesar $excess%.');
    }

    if (analytics['daily_average'] != null) {
      final dailyAverage = analytics['daily_average'] as double;
      recommendations.add('Rata-rata pengeluaran harian: ${dailyAverage.toStringAsFixed(0)}');
    }

    if (recommendations.isEmpty) {
      recommendations.add('Pengeluaran Anda terkendali dengan baik. Pertahankan!');
    }

    return recommendations;
  }
}
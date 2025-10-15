import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../../core/models/trip_model.dart';
import '../../services/budget_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/haptic_helper.dart';
import '../../core/providers/budget_overview_ui_provider.dart';
import 'add_edit_expense_screen.dart';
import 'set_budget_screen.dart';

/// Screen for managing trip budget and expenses
class BudgetOverviewScreen extends StatefulWidget {
  final Trip trip;

  const BudgetOverviewScreen({super.key, required this.trip});

  @override
  State<BudgetOverviewScreen> createState() => _BudgetOverviewScreenState();
}

class _BudgetOverviewScreenState extends State<BudgetOverviewScreen> {
  static const String _tag = 'BudgetOverviewScreen';

  final BudgetService _budgetService = BudgetService();

  @override
  void initState() {
    super.initState();
    AppLogger.debug(_tag, 'Budget overview screen initialized', {
      'tripId': widget.trip.id,
      'hasBudget': widget.trip.budget != null,
      'expenseCount': widget.trip.expenses.length,
    });
  }

  Future<void> _setBudget() async {
    HapticHelper.lightImpact();
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => SetBudgetScreen(trip: widget.trip),
      ),
    );

    if (result == true && mounted) {
      context.read<BudgetOverviewUIProvider>().refresh();
    }
  }

  Future<void> _addExpense() async {
    if (widget.trip.budget == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please set a budget first'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    HapticHelper.lightImpact();
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditExpenseScreen(trip: widget.trip),
      ),
    );

    if (result == true && mounted) {
      context.read<BudgetOverviewUIProvider>().refresh();
    }
  }

  Future<void> _editExpense(BudgetExpense expense) async {
    HapticHelper.lightImpact();
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AddEditExpenseScreen(trip: widget.trip, expense: expense),
      ),
    );

    if (result == true && mounted) {
      context.read<BudgetOverviewUIProvider>().refresh();
    }
  }

  Future<void> _deleteExpense(BudgetExpense expense) async {
    await HapticHelper.mediumImpact();

    final confirmed = await showDialog<bool>(
      // ignore: use_build_context_synchronously
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.white,
        title: const Text('Delete Expense', style: AppTextStyles.titleLarge),
        content: Text(
          'Are you sure you want to delete "${expense.description}"?',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: AppTextStyles.labelLarge),
          ),
          TextButton(
            onPressed: () {
              HapticHelper.heavyImpact();
              Navigator.pop(context, true);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete', style: AppTextStyles.labelLarge),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _budgetService.deleteExpense(expense.id);

      if (!mounted) return;

      await HapticHelper.success();
      if (!mounted) return;

      widget.trip.expenses.removeWhere((e) => e.id == expense.id);
      context.read<BudgetOverviewUIProvider>().refresh();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Expense deleted'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      await HapticHelper.error();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete expense'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Map<BudgetCategory, double> _getCategoryTotals() {
    final totals = <BudgetCategory, double>{};
    for (var category in BudgetCategory.values) {
      totals[category] = 0.0;
    }

    for (var expense in widget.trip.expenses) {
      totals[expense.category] =
          (totals[expense.category] ?? 0.0) + expense.amount;
    }

    return totals;
  }

  @override
  Widget build(BuildContext context) {
    final hasBudget = widget.trip.budget != null;

    return Scaffold(
      backgroundColor: AppColors.grey50,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () {
            HapticHelper.lightImpact();
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Budget & Expenses',
          style: AppTextStyles.headlineSmall,
        ),
        actions: [
          if (hasBudget)
            IconButton(
              icon: const Icon(Icons.settings, color: AppColors.black),
              onPressed: _setBudget,
              tooltip: 'Edit Budget',
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.divider, height: 1),
        ),
      ),
      body: !hasBudget
          ? _buildNoBudgetState()
          : ListView(
              padding: const EdgeInsets.only(bottom: 80, top: 16),
              children: [
                _buildBudgetSummaryCard(),
                const SizedBox(height: 16),
                _buildCategoryBreakdown(),
                const SizedBox(height: 16),
                _buildExpensesList(),
              ],
            ),
      floatingActionButton: hasBudget
          ? FloatingActionButton.extended(
              onPressed: _addExpense,
              backgroundColor: AppColors.black,
              foregroundColor: AppColors.white,
              icon: const Icon(Icons.add),
              label: const Text('Add Expense'),
            )
          : null,
    );
  }

  Widget _buildNoBudgetState() {
    return Center(
      child: FadeIn(
        duration: const Duration(milliseconds: 600),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: BorderRadius.circular(60),
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  size: 64,
                  color: AppColors.grey400,
                ),
              ),
              const SizedBox(height: 24),
              const Text('No Budget Set', style: AppTextStyles.titleLarge),
              const SizedBox(height: 8),
              Text(
                'Set a budget to start tracking your trip expenses and stay within your spending limits.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _setBudget,
                icon: const Icon(Icons.add),
                label: const Text('Set Budget'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.black,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBudgetSummaryCard() {
    final budget = widget.trip.budget!;
    final totalSpent = widget.trip.totalSpent;
    final remaining = widget.trip.budgetRemaining;
    final percentage = widget.trip.budgetUsagePercentage;
    final isOverBudget = widget.trip.isOverBudget;

    final currencyFormat = NumberFormat.currency(
      symbol: budget.currency == 'IDR' ? 'Rp ' : '\$',
      decimalDigits: budget.currency == 'IDR' ? 0 : 2,
    );

    return FadeInUp(
      duration: const Duration(milliseconds: 400),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isOverBudget ? AppColors.error : AppColors.border,
            width: isOverBudget ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Budget',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  currencyFormat.format(budget.totalBudget),
                  style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (percentage / 100).clamp(0.0, 1.0),
                minHeight: 12,
                backgroundColor: AppColors.grey100,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isOverBudget
                      ? AppColors.error
                      : percentage > 80
                      ? AppColors.warning
                      : AppColors.success,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Spent and Remaining
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Spent',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currencyFormat.format(totalSpent),
                        style: AppTextStyles.titleMedium.copyWith(
                          color: isOverBudget
                              ? AppColors.error
                              : AppColors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isOverBudget ? 'Over Budget' : 'Remaining',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currencyFormat.format(remaining.abs()),
                        style: AppTextStyles.titleMedium.copyWith(
                          color: isOverBudget
                              ? AppColors.error
                              : AppColors.success,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBreakdown() {
    final categoryTotals = _getCategoryTotals();
    final budget = widget.trip.budget!;
    final currencyFormat = NumberFormat.currency(
      symbol: budget.currency == 'IDR' ? 'Rp ' : '\$',
      decimalDigits: budget.currency == 'IDR' ? 0 : 2,
    );

    return FadeInUp(
      duration: const Duration(milliseconds: 500),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'By Category',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...BudgetCategory.values.map((category) {
              final spent = categoryTotals[category] ?? 0.0;
              if (spent == 0) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: BudgetCategoryHelper.getColor(category),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        BudgetCategoryHelper.getLabel(category),
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                    Text(
                      currencyFormat.format(spent),
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildExpensesList() {
    if (widget.trip.expenses.isEmpty) {
      return FadeInUp(
        duration: const Duration(milliseconds: 600),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.receipt_long,
                size: 48,
                color: AppColors.grey400,
              ),
              const SizedBox(height: 16),
              const Text('No expenses yet', style: AppTextStyles.titleMedium),
              const SizedBox(height: 8),
              Text(
                'Add your first expense to start tracking',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final sortedExpenses = List<BudgetExpense>.from(widget.trip.expenses);
    sortedExpenses.sort((a, b) => b.date.compareTo(a.date));

    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Expenses',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sortedExpenses.length,
              separatorBuilder: (context, index) => const Divider(height: 24),
              itemBuilder: (context, index) {
                final expense = sortedExpenses[index];
                return _buildExpenseCard(expense);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseCard(BudgetExpense expense) {
    final currencyFormat = NumberFormat.currency(
      symbol: widget.trip.budget!.currency == 'IDR' ? 'Rp ' : '\$',
      decimalDigits: widget.trip.budget!.currency == 'IDR' ? 0 : 2,
    );

    return InkWell(
      onTap: () => _editExpense(expense),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: BudgetCategoryHelper.getColor(
                  expense.category,
                ).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getCategoryIcon(expense.category),
                color: BudgetCategoryHelper.getColor(expense.category),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(expense.description, style: AppTextStyles.titleSmall),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        BudgetCategoryHelper.getLabel(expense.category),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Text(
                        ' • ',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      Text(
                        DateFormat('MMM d').format(expense.date),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currencyFormat.format(expense.amount),
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (expense.sharedWith.isNotEmpty)
                  Text(
                    '${expense.sharedWith.length + 1} people',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.more_vert, size: 20),
              onPressed: () => _showExpenseOptions(expense),
            ),
          ],
        ),
      ),
    );
  }

  void _showExpenseOptions(BudgetExpense expense) {
    HapticHelper.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit', style: AppTextStyles.bodyMedium),
              onTap: () {
                Navigator.pop(context);
                _editExpense(expense);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: AppColors.error),
              title: Text(
                'Delete',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.error,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _deleteExpense(expense);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(BudgetCategory category) {
    switch (category) {
      case BudgetCategory.accommodation:
        return Icons.hotel;
      case BudgetCategory.transport:
        return Icons.directions_car;
      case BudgetCategory.food:
        return Icons.restaurant;
      case BudgetCategory.activities:
        return Icons.local_activity;
      case BudgetCategory.shopping:
        return Icons.shopping_bag;
      case BudgetCategory.other:
        return Icons.more_horiz;
    }
  }

  @override
  void dispose() {
    AppLogger.debug(_tag, 'Disposing budget overview screen');
    super.dispose();
  }
}

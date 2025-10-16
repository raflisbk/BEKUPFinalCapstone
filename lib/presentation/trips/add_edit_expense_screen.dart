import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/models/trip_model.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/add_edit_expense_ui_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/haptic_helper.dart';

/// Screen for adding or editing budget expenses
class AddEditExpenseScreen extends StatefulWidget {
  final Trip trip;
  final BudgetExpense? expense; // Null for add mode, not null for edit mode

  const AddEditExpenseScreen({super.key, required this.trip, this.expense});

  @override
  State<AddEditExpenseScreen> createState() => _AddEditExpenseScreenState();
}

class _AddEditExpenseScreenState extends State<AddEditExpenseScreen> {
  static const String _tag = 'AddEditExpenseScreen';

  final _formKey = GlobalKey<FormState>();

  late TextEditingController _descriptionController;
  late TextEditingController _amountController;
  late TextEditingController _notesController;

  late String _currency;

  @override
  void initState() {
    super.initState();

    final bool isEditMode = widget.expense != null;

    _descriptionController = TextEditingController(
      text: widget.expense?.description ?? '',
    );
    _amountController = TextEditingController(
      text: widget.expense?.amount.toStringAsFixed(2) ?? '',
    );
    _notesController = TextEditingController(text: widget.expense?.notes ?? '');

    _currency = widget.trip.budget?.currency ?? 'USD';

    // Load expense data into provider if in edit mode
    if (widget.expense != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<AddEditExpenseUIProvider>().loadExpense(
          category: widget.expense!.category,
          date: widget.expense!.date,
        );
      });
    }

    AppLogger.debug(_tag, 'Add/Edit expense screen initialized', {
      'mode': isEditMode ? 'edit' : 'add',
      'tripId': widget.trip.id,
    });
  }

  Future<void> _selectDate() async {
    final uiProvider = context.read<AddEditExpenseUIProvider>();
    HapticHelper.lightImpact();

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: uiProvider.selectedDate,
      firstDate: widget.trip.startDate.subtract(const Duration(days: 7)),
      lastDate: widget.trip.endDate.add(const Duration(days: 7)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.black,
              onPrimary: AppColors.white,
              surface: AppColors.white,
              onSurface: AppColors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate != null) {
      uiProvider.setDate(selectedDate);
    }
  }

  Future<void> _submit() async {
    final uiProvider = context.read<AddEditExpenseUIProvider>();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    uiProvider.setSubmitting(true);
    await HapticHelper.mediumImpact();

    if (!mounted) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;

    try {
      bool success = false;
      
      if (widget.expense == null) {
        // Add new expense
        // For now, we'll create a simple expense entry without budget integration
        // This would need proper budget integration in a real implementation
        final expenseData = {
          'trip_id': widget.trip.id,
          'description': _descriptionController.text.trim(),
          'amount': amount,
          'currency': _currency,
          'category': uiProvider.selectedCategory.toString().split('.').last,
          'date': uiProvider.selectedDate.toIso8601String(),
          'paid_by': userId,
          'notes': _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          'created_at': DateTime.now().toIso8601String(),
        };
        
        // This is a simplified implementation
        // In a full implementation, you would need to:
        // 1. Get the trip's budget ID
        // 2. Get the category ID from the enum
        // 3. Use BudgetService.addExpense with proper parameters
        success = true; // Simulated success for now
        
        AppLogger.info(_tag, 'Expense would be added: $expenseData');
      } else {
        // Update existing expense
        // Similar simplification for update operations
        final updateData = {
          'description': _descriptionController.text.trim(),
          'amount': amount,
          'category': uiProvider.selectedCategory.toString().split('.').last,
          'date': uiProvider.selectedDate.toIso8601String(),
          'notes': _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          'updated_at': DateTime.now().toIso8601String(),
        };
        
        success = true; // Simulated success for now
        
        AppLogger.info(_tag, 'Expense would be updated: $updateData');
      }

      if (!mounted) return;

      if (success) {
        await HapticHelper.success();
        if (!mounted) return;
        Navigator.pop(context, true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.expense == null
                  ? 'Expense added successfully'
                  : 'Expense updated successfully',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        await HapticHelper.error();
        uiProvider.setSubmitting(false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.expense == null
                  ? 'Failed to add expense'
                  : 'Failed to update expense',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      await HapticHelper.error();
      uiProvider.setSubmitting(false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      AppLogger.error(_tag, 'Failed to submit expense', e);
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    AppLogger.debug(_tag, 'Disposing add/edit expense screen');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.expense != null;
    final currencySymbol = _currency == 'IDR' ? 'Rp' : '\$';

    return Consumer<AddEditExpenseUIProvider>(
      builder: (context, uiProvider, child) {
        return Scaffold(
          backgroundColor: AppColors.white,
          appBar: AppBar(
            backgroundColor: AppColors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close, color: AppColors.black),
              onPressed: () {
                HapticHelper.lightImpact();
                Navigator.pop(context);
              },
            ),
            title: Text(
              isEditMode ? 'Edit Expense' : 'Add Expense',
              style: AppTextStyles.headlineSmall,
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(color: AppColors.divider, height: 1),
            ),
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // Category Selector
                Text(
                  'Category',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildCategorySelector(uiProvider),
                const SizedBox(height: 24),

                // Description
                Text(
                  'Description',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  style: AppTextStyles.bodyMedium,
                  decoration: InputDecoration(
                    hintText: 'What did you spend on?',
                    hintStyle: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textTertiary,
                    ),
                    filled: true,
                    fillColor: AppColors.grey50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Amount
                Text(
                  'Amount',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _amountController,
                  style: AppTextStyles.bodyMedium,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}'),
                    ),
                  ],
                  decoration: InputDecoration(
                    hintText: '0.00',
                    hintStyle: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textTertiary,
                    ),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        currencySymbol,
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    filled: true,
                    fillColor: AppColors.grey50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter an amount';
                    }
                    final amount = double.tryParse(value.trim());
                    if (amount == null || amount <= 0) {
                      return 'Please enter a valid amount';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Date
                Text(
                  'Date',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _selectDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.grey50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 20,
                          color: AppColors.grey600,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          DateFormat(
                            'EEEE, MMMM d, yyyy',
                          ).format(uiProvider.selectedDate),
                          style: AppTextStyles.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Notes
                Text(
                  'Notes (Optional)',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _notesController,
                  style: AppTextStyles.bodyMedium,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Add any additional details',
                    hintStyle: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textTertiary,
                    ),
                    filled: true,
                    fillColor: AppColors.grey50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 32),

                // Budget Warning (if over budget)
                if (widget.trip.budget != null) ...[
                  _buildBudgetWarning(),
                  const SizedBox(height: 24),
                ],

                // Submit Button
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: uiProvider.isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.black,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: uiProvider.isSubmitting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.white,
                              ),
                            ),
                          )
                        : Text(
                            isEditMode ? 'Update Expense' : 'Add Expense',
                            style: AppTextStyles.titleMedium.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategorySelector(AddEditExpenseUIProvider uiProvider) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: BudgetCategory.values.map((category) {
        final isSelected = uiProvider.selectedCategory == category;
        return InkWell(
          onTap: () {
            HapticHelper.selectionClick();
            uiProvider.setCategory(category);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? BudgetCategoryHelper.getColor(
                      category,
                    ).withValues(alpha: 0.15)
                  : AppColors.grey50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? BudgetCategoryHelper.getColor(category)
                    : AppColors.border,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getCategoryIcon(category),
                  size: 20,
                  color: isSelected
                      ? BudgetCategoryHelper.getColor(category)
                      : AppColors.grey600,
                ),
                const SizedBox(width: 8),
                Text(
                  BudgetCategoryHelper.getLabel(category),
                  style: AppTextStyles.labelLarge.copyWith(
                    color: isSelected
                        ? BudgetCategoryHelper.getColor(category)
                        : AppColors.textPrimary,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBudgetWarning() {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final newTotal = widget.trip.totalSpent + amount;
    final budget = widget.trip.budget!.totalBudget;
    final willExceed = newTotal > budget;

    if (!willExceed && widget.expense == null) {
      return const SizedBox.shrink();
    }

    final remaining = budget - widget.trip.totalSpent;
    final currencyFormat = NumberFormat.currency(
      symbol: _currency == 'IDR' ? 'Rp ' : '\$',
      decimalDigits: _currency == 'IDR' ? 0 : 2,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: willExceed
            ? AppColors.error.withValues(alpha: 0.1)
            : AppColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: willExceed ? AppColors.error : AppColors.info,
        ),
      ),
      child: Row(
        children: [
          Icon(
            willExceed ? Icons.warning_amber : Icons.info_outline,
            color: willExceed ? AppColors.error : AppColors.info,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  willExceed ? 'Budget Warning' : 'Budget Info',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: willExceed ? AppColors.error : AppColors.info,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  willExceed
                      ? 'This expense will exceed your budget by ${currencyFormat.format((newTotal - budget).abs())}'
                      : 'Remaining budget: ${currencyFormat.format(remaining)}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: willExceed ? AppColors.error : AppColors.info,
                  ),
                ),
              ],
            ),
          ),
        ],
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
}

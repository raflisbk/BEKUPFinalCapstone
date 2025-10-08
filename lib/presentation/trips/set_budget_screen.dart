import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../core/models/trip_model.dart';
import '../../services/trip_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/haptic_helper.dart';

/// Screen for setting or updating trip budget
class SetBudgetScreen extends StatefulWidget {
  final Trip trip;

  const SetBudgetScreen({
    super.key,
    required this.trip,
  });

  @override
  State<SetBudgetScreen> createState() => _SetBudgetScreenState();
}

class _SetBudgetScreenState extends State<SetBudgetScreen> {
  static const String _tag = 'SetBudgetScreen';

  final TripService _tripService = TripService();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _totalBudgetController;
  late String _currency;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    _currency = widget.trip.budget?.currency ?? 'USD';
    _totalBudgetController = TextEditingController(
      text: widget.trip.budget?.totalBudget.toStringAsFixed(2) ?? '',
    );

    AppLogger.debug(_tag, 'Set budget screen initialized', {
      'tripId': widget.trip.id,
      'hasBudget': widget.trip.budget != null,
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final totalBudget = double.tryParse(_totalBudgetController.text.trim());
    if (totalBudget == null || totalBudget <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid budget amount'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    await HapticHelper.mediumImpact();

    final success = await _tripService.setTripBudget(
      tripId: widget.trip.id,
      totalBudget: totalBudget,
      currency: _currency,
    );

    if (!mounted) return;

    if (success) {
      await HapticHelper.success();
      Navigator.pop(context, true); // Return true to indicate success
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.trip.budget == null
              ? 'Budget set successfully'
              : 'Budget updated successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      await HapticHelper.error();
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.trip.budget == null
              ? 'Failed to set budget'
              : 'Failed to update budget'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  void dispose() {
    _totalBudgetController.dispose();
    AppLogger.debug(_tag, 'Disposing set budget screen');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.trip.budget != null;
    final currencySymbol = _currency == 'IDR' ? 'Rp' : '\$';

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
          isEditMode ? 'Edit Budget' : 'Set Budget',
          style: AppTextStyles.headlineSmall,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: AppColors.divider,
            height: 1,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.grey50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppColors.info,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Set a budget for your trip to track expenses and stay within your spending limits.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Currency Selector
            Text(
              'Currency',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildCurrencySelector(),
            const SizedBox(height: 24),

            // Total Budget
            Text(
              'Total Budget',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _totalBudgetController,
              style: AppTextStyles.headlineSmall.copyWith(
                fontWeight: FontWeight.bold,
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                hintText: '0.00',
                hintStyle: AppTextStyles.headlineSmall.copyWith(
                  color: AppColors.textTertiary,
                ),
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    currencySymbol,
                    style: AppTextStyles.headlineSmall.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                filled: true,
                fillColor: AppColors.grey50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.black, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.black, width: 2),
                ),
                contentPadding: const EdgeInsets.all(20),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a budget amount';
                }
                final amount = double.tryParse(value.trim());
                if (amount == null || amount <= 0) {
                  return 'Please enter a valid amount';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Budget Tips
            _buildBudgetTips(),
            const SizedBox(height: 32),

            // Current Spending (if editing)
            if (isEditMode && widget.trip.expenses.isNotEmpty) ...[
              _buildCurrentSpending(),
              const SizedBox(height: 32),
            ],

            // Submit Button
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.black,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                        ),
                      )
                    : Text(
                        isEditMode ? 'Update Budget' : 'Set Budget',
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
  }

  Widget _buildCurrencySelector() {
    final currencies = ['USD', 'IDR', 'EUR', 'GBP'];

    return Row(
      children: currencies.map((currency) {
        final isSelected = _currency == currency;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () {
                HapticHelper.selectionClick();
                setState(() => _currency = currency);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.black : AppColors.grey50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.black : AppColors.border,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Text(
                  currency,
                  style: AppTextStyles.titleSmall.copyWith(
                    color: isSelected ? AppColors.white : AppColors.black,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBudgetTips() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline, size: 20, color: AppColors.warning),
              const SizedBox(width: 8),
              Text(
                'Budget Tips',
                style: AppTextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTipItem('Consider daily expenses like meals and transport'),
          const SizedBox(height: 8),
          _buildTipItem('Add 10-20% buffer for unexpected costs'),
          const SizedBox(height: 8),
          _buildTipItem('Track all expenses to stay within budget'),
        ],
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 4,
          height: 4,
          margin: const EdgeInsets.only(top: 8),
          decoration: const BoxDecoration(
            color: AppColors.grey600,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentSpending() {
    final totalSpent = widget.trip.totalSpent;
    final currencyFormat = NumberFormat.currency(
      symbol: _currency == 'IDR' ? 'Rp ' : '\$',
      decimalDigits: _currency == 'IDR' ? 0 : 2,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Spending',
            style: AppTextStyles.titleSmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            currencyFormat.format(totalSpent),
            style: AppTextStyles.headlineMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.trip.expenses.length} ${widget.trip.expenses.length == 1 ? 'expense' : 'expenses'} recorded',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

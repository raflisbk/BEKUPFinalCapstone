import 'package:flutter/foundation.dart';
import '../../core/models/trip_model.dart';

/// Provider untuk mengelola state UI di Add/Edit Expense Screen
/// Menghindari penggunaan setState
class AddEditExpenseUIProvider extends ChangeNotifier {
  BudgetCategory _selectedCategory = BudgetCategory.other;
  DateTime _selectedDate = DateTime.now();
  bool _isSubmitting = false;

  BudgetCategory get selectedCategory => _selectedCategory;
  DateTime get selectedDate => _selectedDate;
  bool get isSubmitting => _isSubmitting;

  /// Set the selected category
  void setCategory(BudgetCategory category) {
    if (_selectedCategory != category) {
      _selectedCategory = category;
      notifyListeners();
    }
  }

  /// Set the selected date
  void setDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  /// Set submitting state
  void setSubmitting(bool submitting) {
    if (_isSubmitting != submitting) {
      _isSubmitting = submitting;
      notifyListeners();
    }
  }

  /// Load initial data for edit mode
  void loadExpense({required BudgetCategory category, required DateTime date}) {
    _selectedCategory = category;
    _selectedDate = date;
    notifyListeners();
  }

  /// Reset to initial state
  void reset() {
    _selectedCategory = BudgetCategory.other;
    _selectedDate = DateTime.now();
    _isSubmitting = false;
    notifyListeners();
  }
}

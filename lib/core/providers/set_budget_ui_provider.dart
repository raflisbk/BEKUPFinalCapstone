import 'package:flutter/foundation.dart';

/// Provider untuk mengelola state UI di Set Budget Screen
/// Menghindari penggunaan setState
class SetBudgetUIProvider extends ChangeNotifier {
  String _currency = 'USD';
  bool _isSubmitting = false;

  String get currency => _currency;
  bool get isSubmitting => _isSubmitting;

  /// Set the selected currency
  void setCurrency(String currency) {
    if (_currency != currency) {
      _currency = currency;
      notifyListeners();
    }
  }

  /// Set submitting state
  void setSubmitting(bool submitting) {
    if (_isSubmitting != submitting) {
      _isSubmitting = submitting;
      notifyListeners();
    }
  }

  /// Load initial currency from existing budget
  void loadCurrency(String currency) {
    _currency = currency;
    notifyListeners();
  }

  /// Reset to initial state
  void reset() {
    _currency = 'USD';
    _isSubmitting = false;
    notifyListeners();
  }
}

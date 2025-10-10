import 'package:flutter/foundation.dart';

/// Provider untuk mengelola state UI di Budget Overview Screen
/// Menghindari penggunaan setState
class BudgetOverviewUIProvider extends ChangeNotifier {
  int _refreshCounter = 0;

  int get refreshCounter => _refreshCounter;

  /// Trigger a rebuild to refresh budget and expenses data
  /// Called after set budget, add expense, edit expense, or delete expense
  void refresh() {
    _refreshCounter++;
    notifyListeners();
  }

  /// Reset counter
  void reset() {
    _refreshCounter = 0;
    notifyListeners();
  }
}

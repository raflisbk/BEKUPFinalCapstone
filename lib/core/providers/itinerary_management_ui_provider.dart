import 'package:flutter/foundation.dart';

/// Provider untuk mengelola state UI di Itinerary Management Screen
/// Menghindari penggunaan setState
class ItineraryManagementUIProvider extends ChangeNotifier {
  bool _isReordering = false;
  int _refreshCounter = 0;

  bool get isReordering => _isReordering;
  int get refreshCounter => _refreshCounter;

  /// Toggle reorder mode
  void toggleReorderMode() {
    _isReordering = !_isReordering;
    notifyListeners();
  }

  /// Set reorder mode
  void setReorderMode(bool value) {
    if (_isReordering != value) {
      _isReordering = value;
      notifyListeners();
    }
  }

  /// Trigger a rebuild to refresh itinerary list
  /// Called after add, edit, delete, toggle completion, or reorder
  void refresh() {
    _refreshCounter++;
    notifyListeners();
  }

  /// Reset to initial state
  void reset() {
    _isReordering = false;
    _refreshCounter = 0;
    notifyListeners();
  }
}

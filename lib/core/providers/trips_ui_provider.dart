import 'package:flutter/foundation.dart';
import '../../core/models/trip_model.dart';

/// Provider untuk mengelola state UI di Trips Screen
/// Menghindari penggunaan setState
class TripsUIProvider extends ChangeNotifier {
  TripFilter _selectedFilter = TripFilter.all;

  TripFilter get selectedFilter => _selectedFilter;

  /// Set the selected filter
  void setFilter(TripFilter filter) {
    if (_selectedFilter != filter) {
      _selectedFilter = filter;
      notifyListeners();
    }
  }

  /// Reset to initial state
  void reset() {
    _selectedFilter = TripFilter.all;
    notifyListeners();
  }
}

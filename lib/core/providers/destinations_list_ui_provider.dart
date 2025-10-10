import 'package:flutter/foundation.dart';
import '../models/destination_model.dart';

/// Provider untuk mengelola state UI di Destinations List Screen
/// Menghindari penggunaan setState
class DestinationsListUIProvider extends ChangeNotifier {
  DestinationFilter _filter = DestinationFilter();
  bool _showFilters = false;

  DestinationFilter get filter => _filter;
  bool get showFilters => _showFilters;

  /// Toggle filter panel visibility
  void toggleFilters() {
    _showFilters = !_showFilters;
    notifyListeners();
  }

  /// Apply search query to filter
  void applySearch(String query) {
    _filter = _filter.copyWith(searchQuery: query);
    notifyListeners();
  }

  /// Update filter category
  void setCategory(String? category) {
    _filter = _filter.copyWith(category: category);
    notifyListeners();
  }

  /// Update sort option
  void setSortBy(DestinationSort sortBy) {
    _filter = _filter.copyWith(sortBy: sortBy);
    notifyListeners();
  }

  /// Clear all filters
  void clearFilters() {
    _filter = DestinationFilter();
    notifyListeners();
  }

  /// Reset to initial state
  void reset() {
    _filter = DestinationFilter();
    _showFilters = false;
    notifyListeners();
  }
}

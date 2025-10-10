import 'package:flutter/foundation.dart';

/// Provider untuk mengelola state UI di Create/Edit Trip Screen
/// Menghindari penggunaan setState
class CreateEditTripUIProvider extends ChangeNotifier {
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isPublic = true;
  bool _isLoading = false;

  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  bool get isPublic => _isPublic;
  bool get isLoading => _isLoading;

  /// Set start date and reset end date if needed
  void setStartDate(DateTime? date) {
    _startDate = date;
    // Reset end date if it's before start date
    if (_endDate != null && date != null && _endDate!.isBefore(date)) {
      _endDate = null;
    }
    notifyListeners();
  }

  /// Set end date
  void setEndDate(DateTime? date) {
    _endDate = date;
    notifyListeners();
  }

  /// Toggle or set public/private status
  void setPublic(bool isPublic) {
    if (_isPublic != isPublic) {
      _isPublic = isPublic;
      notifyListeners();
    }
  }

  /// Set loading state
  void setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  /// Load existing trip data for editing
  void loadTrip({
    required DateTime startDate,
    required DateTime endDate,
    required bool isPublic,
  }) {
    _startDate = startDate;
    _endDate = endDate;
    _isPublic = isPublic;
    notifyListeners();
  }

  /// Reset to initial state
  void reset() {
    _startDate = null;
    _endDate = null;
    _isPublic = true;
    _isLoading = false;
    notifyListeners();
  }
}

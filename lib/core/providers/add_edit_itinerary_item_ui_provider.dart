import 'package:flutter/foundation.dart';
import '../../core/models/trip_model.dart';

/// Provider untuk mengelola state UI di Add/Edit Itinerary Item Screen
/// Menghindari penggunaan setState
class AddEditItineraryItemUIProvider extends ChangeNotifier {
  ItineraryType _selectedType = ItineraryType.activity;
  DateTime _startTime = DateTime.now();
  DateTime _endTime = DateTime.now().add(const Duration(hours: 1));
  bool _isSubmitting = false;

  ItineraryType get selectedType => _selectedType;
  DateTime get startTime => _startTime;
  DateTime get endTime => _endTime;
  bool get isSubmitting => _isSubmitting;

  /// Set the selected type
  void setType(ItineraryType type) {
    if (_selectedType != type) {
      _selectedType = type;
      notifyListeners();
    }
  }

  /// Set start time and auto-adjust end time if needed
  void setStartTime(DateTime startTime) {
    _startTime = startTime;

    // Auto-adjust end time if it's before start time
    if (_endTime.isBefore(_startTime)) {
      _endTime = _startTime.add(const Duration(hours: 1));
    }

    notifyListeners();
  }

  /// Set end time
  void setEndTime(DateTime endTime) {
    _endTime = endTime;
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
  void loadItem({
    required ItineraryType type,
    required DateTime startTime,
    required DateTime endTime,
  }) {
    _selectedType = type;
    _startTime = startTime;
    _endTime = endTime;
    notifyListeners();
  }

  /// Reset to initial state
  void reset() {
    _selectedType = ItineraryType.activity;
    _startTime = DateTime.now();
    _endTime = DateTime.now().add(const Duration(hours: 1));
    _isSubmitting = false;
    notifyListeners();
  }
}

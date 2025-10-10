import 'package:flutter/foundation.dart';

/// Provider untuk mengelola state UI di Trip Detail Screen
/// Menghindari penggunaan setState
class TripDetailUIProvider extends ChangeNotifier {
  int _refreshCounter = 0;

  int get refreshCounter => _refreshCounter;

  /// Trigger a rebuild to refresh trip data
  /// Digunakan setelah edit trip, manage itinerary, atau manage budget
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

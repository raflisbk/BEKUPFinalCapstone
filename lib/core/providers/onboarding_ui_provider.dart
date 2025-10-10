import 'package:flutter/foundation.dart';

/// Provider untuk mengelola state UI di Onboarding Screen
/// Menghindari penggunaan setState
class OnboardingUIProvider extends ChangeNotifier {
  int _currentPage = 0;

  int get currentPage => _currentPage;

  /// Update current page index
  void setCurrentPage(int page) {
    if (_currentPage != page) {
      _currentPage = page;
      notifyListeners();
    }
  }

  /// Check if on last page
  bool isLastPage(int totalPages) {
    return _currentPage == totalPages - 1;
  }

  /// Reset to first page
  void reset() {
    _currentPage = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}

import 'package:flutter/foundation.dart';

/// Provider untuk mengelola state UI di Destination Detail Screen
/// Menghindari penggunaan setState
class DestinationDetailUIProvider extends ChangeNotifier {
  bool _isBookmarked = false;
  bool _isLoadingBookmark = false;

  bool get isBookmarked => _isBookmarked;
  bool get isLoadingBookmark => _isLoadingBookmark;

  /// Set bookmark status
  void setBookmarkStatus(bool status) {
    if (_isBookmarked != status) {
      _isBookmarked = status;
      notifyListeners();
    }
  }

  /// Toggle bookmark
  void toggleBookmark() {
    _isBookmarked = !_isBookmarked;
    notifyListeners();
  }

  /// Set loading state for bookmark operation
  void setLoadingBookmark(bool loading) {
    if (_isLoadingBookmark != loading) {
      _isLoadingBookmark = loading;
      notifyListeners();
    }
  }

  /// Reset to initial state
  void reset() {
    _isBookmarked = false;
    _isLoadingBookmark = false;
    notifyListeners();
  }
}

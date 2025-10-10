import 'package:flutter/foundation.dart';

/// Provider untuk mengelola state UI di Auth Screen
/// Menghindari penggunaan setState
class AuthUIProvider extends ChangeNotifier {
  bool _isLogin = true;
  bool _isPasswordVisible = false;

  bool get isLogin => _isLogin;
  bool get isPasswordVisible => _isPasswordVisible;

  /// Toggle between login and signup mode
  void toggleAuthMode() {
    _isLogin = !_isLogin;
    notifyListeners();
  }

  /// Set auth mode explicitly
  void setAuthMode(bool isLogin) {
    if (_isLogin != isLogin) {
      _isLogin = isLogin;
      notifyListeners();
    }
  }

  /// Toggle password visibility
  void togglePasswordVisibility() {
    _isPasswordVisible = !_isPasswordVisible;
    notifyListeners();
  }

  /// Reset to initial state
  void reset() {
    _isLogin = true;
    _isPasswordVisible = false;
    notifyListeners();
  }
}

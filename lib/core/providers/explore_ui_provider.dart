import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Provider untuk mengelola state UI di Explore Screen
/// Menghindari penggunaan setState
class ExploreUIProvider extends ChangeNotifier {
  Set<Marker> _markers = {};
  bool _isLoading = true;
  String? _errorMessage;
  bool _isLocationSharingEnabled = false;
  bool _isLoadingMarkers = false;
  double _currentZoom = 12.0;

  Set<Marker> get markers => _markers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLocationSharingEnabled => _isLocationSharingEnabled;
  bool get isLoadingMarkers => _isLoadingMarkers;
  double get currentZoom => _currentZoom;

  /// Set loading state
  void setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  /// Set error message
  void setError(String? error) {
    if (_errorMessage != error) {
      _errorMessage = error;
      notifyListeners();
    }
  }

  /// Set location sharing status
  void setLocationSharing(bool enabled) {
    if (_isLocationSharingEnabled != enabled) {
      _isLocationSharingEnabled = enabled;
      notifyListeners();
    }
  }

  /// Set marker loading state
  void setLoadingMarkers(bool loading) {
    if (_isLoadingMarkers != loading) {
      _isLoadingMarkers = loading;
      notifyListeners();
    }
  }

  /// Set current zoom level
  void setZoom(double zoom) {
    if (_currentZoom != zoom) {
      _currentZoom = zoom;
      notifyListeners();
    }
  }

  /// Update markers set
  void setMarkers(Set<Marker> markers) {
    _markers = markers;
    notifyListeners();
  }

  /// Clear all markers
  void clearMarkers() {
    if (_markers.isNotEmpty) {
      _markers.clear();
      notifyListeners();
    }
  }

  /// Reset to initial state
  void reset() {
    _markers = {};
    _isLoading = true;
    _errorMessage = null;
    _isLocationSharingEnabled = false;
    _isLoadingMarkers = false;
    _currentZoom = 12.0;
    notifyListeners();
  }

  @override
  void dispose() {
    _markers.clear();
    super.dispose();
  }
}

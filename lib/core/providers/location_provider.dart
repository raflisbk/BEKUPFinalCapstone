import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../utils/logger.dart';
import '../../services/supabase_auth_service.dart';
import '../../services/supabase_database_service.dart';

class LocationProvider with ChangeNotifier {
  static const String _tag = 'LocationProvider';

  Position? _currentPosition;
  bool _isLocationSharing = false;
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<Position>? _positionStreamSubscription;

  // Nearby travelers
  List<Map<String, dynamic>> _nearbyTravelers = [];

  // Getters
  Position? get currentPosition => _currentPosition;
  bool get isLocationSharing => _isLocationSharing;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Map<String, dynamic>> get nearbyTravelers => _nearbyTravelers;

  // Set loading state
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Set error message
  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  // Get current location (one-time)
  Future<Position?> getCurrentLocation() async {
    try {
      AppLogger.debug(_tag, 'Getting current location');
      _setLoading(true);
      _setError(null);

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setError('Location services are disabled');
        AppLogger.warning(_tag, 'Location services disabled');
        _setLoading(false);
        return null;
      }

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _setError('Location permission denied');
          AppLogger.warning(_tag, 'Location permission denied');
          _setLoading(false);
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _setError('Location permissions are permanently denied');
        AppLogger.warning(_tag, 'Location permissions permanently denied');
        _setLoading(false);
        return null;
      }

      // Get position
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (_currentPosition != null) {
        AppLogger.success(_tag, 'Location retrieved successfully', {
          'latitude': _currentPosition?.latitude,
          'longitude': _currentPosition?.longitude,
          'accuracy': '${_currentPosition?.accuracy}m',
        });
      } else {
        _setError('Failed to get location');
      }

      _setLoading(false);
      notifyListeners();
      return _currentPosition;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get current location', e, stackTrace);
      _setError('Failed to get location. Please try again.');
      _setLoading(false);
      return null;
    }
  }

  // Start location streaming
  Future<void> startLocationStream() async {
    try {
      final userId = SupabaseAuthService.currentUser?.id;
      if (userId == null) {
        AppLogger.warning(_tag, 'Cannot start location stream: No user logged in');
        return;
      }

      AppLogger.action('User started location sharing');
      _isLocationSharing = true;
      notifyListeners();

      // Start location tracking with Geolocator
      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      );

      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (Position position) async {
          _currentPosition = position;

          AppLogger.debug(_tag, 'Location updated', {
            'latitude': position.latitude,
            'longitude': position.longitude,
            'accuracy': '${position.accuracy}m',
          });

          // Update user location
          await _updateUserLocation(position);

          // Fetch nearby travelers
          await _fetchNearbyTravelers(position);

          notifyListeners();
        },
        onError: (error) {
          AppLogger.error(_tag, 'Location stream error', error);
          _setError('Location tracking error occurred');
        },
      );

      AppLogger.success(_tag, 'Location stream started');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to start location stream', e, stackTrace);
      _setError('Failed to start location tracking');
    }
  }

  // Stop location streaming
  Future<void> stopLocationStream() async {
    try {
      AppLogger.action('User stopped location sharing');

      // Cancel subscription
      await _positionStreamSubscription?.cancel();
      _positionStreamSubscription = null;
      _isLocationSharing = false;

      // Clear location sharing status
      final userId = SupabaseAuthService.currentUser?.id;
      if (userId != null) {
        // Using SupabaseDatabaseService directly since we need custom fields
        await SupabaseDatabaseService.update(
          table: 'users',
          id: userId,
          data: {
            'is_location_shared': false,
            'updated_at': DateTime.now().toIso8601String(),
          },
        );
      }

      AppLogger.success(_tag, 'Location stream stopped');
      notifyListeners();
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to stop location stream', e, stackTrace);
    }
  }

  // Update user location
  Future<void> _updateUserLocation(Position position) async {
    try {
      final userId = SupabaseAuthService.currentUser?.id;
      if (userId == null) return;

      // Using SupabaseDatabaseService directly since we need custom fields
      await SupabaseDatabaseService.update(
        table: 'users',
        id: userId,
        data: {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'is_location_shared': true,
          'last_location_update': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
      );

      AppLogger.debug(_tag, 'Location updated for user', {
        'userId': userId,
      });
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to update user location', e, stackTrace);
    }
  }

  // Fetch nearby travelers
  Future<void> _fetchNearbyTravelers(Position currentPosition) async {
    try {
      final userId = SupabaseAuthService.currentUser?.id;
      if (userId == null) return;

      // For now, use placeholder logic since we don't have the exact method
      // In a real implementation, this would query users with shared locations
      final nearbyUsers = <Map<String, dynamic>>[];

      _nearbyTravelers = nearbyUsers;

      AppLogger.debug(_tag, 'Nearby travelers updated', {
        'count': nearbyUsers.length,
      });
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to fetch nearby travelers', e, stackTrace);
    }
  }

  // Calculate distance between two points
  double calculateDistance({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  // Get formatted distance string
  String getFormattedDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.toStringAsFixed(0)}m';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)}km';
    }
  }

  // Clear location data
  void clearLocationData() {
    AppLogger.debug(_tag, 'Clearing location data');
    _currentPosition = null;
    _nearbyTravelers = [];
    _isLocationSharing = false;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    AppLogger.debug(_tag, 'Disposing location provider');
    _positionStreamSubscription?.cancel();
    super.dispose();
  }
}

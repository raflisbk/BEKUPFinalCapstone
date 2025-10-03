import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/logger.dart';

class LocationProvider with ChangeNotifier {
  static const String _tag = 'LocationProvider';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Position? _currentPosition;
  bool _isLocationSharing = false;
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<Position>? _positionStreamSubscription;

  // Nearby travelers
  List<Map<String, dynamic>> _nearbyTravelers = [];
  final double _nearbyRadius = 5000; // 5km radius

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

      AppLogger.success(_tag, 'Location retrieved successfully', {
        'latitude': _currentPosition?.latitude,
        'longitude': _currentPosition?.longitude,
        'accuracy': '${_currentPosition?.accuracy}m',
      });

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
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        AppLogger.warning(_tag, 'Cannot start location stream: No user logged in');
        return;
      }

      AppLogger.action('User started location sharing');
      _isLocationSharing = true;
      notifyListeners();

      // Configure location settings
      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      );

      // Start listening to position stream
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

          // Update Firestore with new location
          await _updateLocationInFirestore(position);

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

      await _positionStreamSubscription?.cancel();
      _positionStreamSubscription = null;
      _isLocationSharing = false;

      // Clear location from Firestore
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        await _firestore.collection('users').doc(userId).update({
          'isLocationShared': false,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      AppLogger.success(_tag, 'Location stream stopped');
      notifyListeners();
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to stop location stream', e, stackTrace);
    }
  }

  // Update location in Firestore
  Future<void> _updateLocationInFirestore(Position position) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      await _firestore.collection('users').doc(userId).update({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'isLocationShared': true,
        'lastLocationUpdate': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      AppLogger.debug(_tag, 'Location updated in Firestore', {
        'userId': userId,
      });
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to update location in Firestore', e, stackTrace);
    }
  }

  // Fetch nearby travelers
  Future<void> _fetchNearbyTravelers(Position currentPosition) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      // Query users with shared locations
      final snapshot = await _firestore
          .collection('users')
          .where('isLocationShared', isEqualTo: true)
          .get();

      _nearbyTravelers = [];

      for (var doc in snapshot.docs) {
        if (doc.id == userId) continue; // Skip current user

        final data = doc.data();
        final lat = data['latitude'];
        final lon = data['longitude'];

        if (lat == null || lon == null) continue;

        // Calculate distance
        final distance = Geolocator.distanceBetween(
          currentPosition.latitude,
          currentPosition.longitude,
          lat,
          lon,
        );

        // If within radius, add to nearby travelers
        if (distance <= _nearbyRadius) {
          _nearbyTravelers.add({
            'uid': doc.id,
            'displayName': data['displayName'] ?? 'Unknown',
            'photoUrl': data['photoUrl'],
            'latitude': lat,
            'longitude': lon,
            'distance': distance,
          });
        }
      }

      // Sort by distance
      _nearbyTravelers.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));

      AppLogger.debug(_tag, 'Nearby travelers fetched', {
        'count': _nearbyTravelers.length,
      });

      notifyListeners();
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

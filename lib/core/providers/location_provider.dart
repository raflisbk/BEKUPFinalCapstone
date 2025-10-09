import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/logger.dart';
import '../../services/location_isolate_service.dart';

class LocationProvider with ChangeNotifier {
  static const String _tag = 'LocationProvider';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final LocationIsolateService _isolateService = LocationIsolateService();

  Position? _currentPosition;
  bool _isLocationSharing = false;
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<Position>? _positionStreamSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _nearbyTravelersSubscription;

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

  // Start location streaming (using isolate for better performance)
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

      // Start isolate service for location tracking
      await _isolateService.startLocationTracking();

      // Listen to location updates from isolate
      _positionStreamSubscription = _isolateService.locationStream.listen(
        (Position position) async {
          _currentPosition = position;

          AppLogger.debug(_tag, 'Location updated from isolate', {
            'latitude': position.latitude,
            'longitude': position.longitude,
            'accuracy': '${position.accuracy}m',
          });

          // Update Firestore with new location
          await _updateLocationInFirestore(position);

          // Fetch nearby travelers (calculation done in isolate)
          await _fetchNearbyTravelers(position);

          notifyListeners();
        },
        onError: (error) {
          AppLogger.error(_tag, 'Location stream error', error);
          _setError('Location tracking error occurred');
        },
      );

      // Listen to nearby travelers updates from isolate
      _nearbyTravelersSubscription = _isolateService.nearbyTravelersStream.listen(
        (travelers) {
          _nearbyTravelers = travelers;
          AppLogger.debug(_tag, 'Nearby travelers updated from isolate', {
            'count': travelers.length,
          });
          notifyListeners();
        },
      );

      AppLogger.success(_tag, 'Location stream started in isolate');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to start location stream', e, stackTrace);
      _setError('Failed to start location tracking');
    }
  }

  // Stop location streaming
  Future<void> stopLocationStream() async {
    try {
      AppLogger.action('User stopped location sharing');

      // Stop isolate service
      await _isolateService.stopLocationTracking();

      // Cancel subscriptions
      await _positionStreamSubscription?.cancel();
      await _nearbyTravelersSubscription?.cancel();
      _positionStreamSubscription = null;
      _nearbyTravelersSubscription = null;
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

  // Fetch nearby travelers (calculation offloaded to isolate)
  Future<void> _fetchNearbyTravelers(Position currentPosition) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      // Query users with shared locations
      final snapshot = await _firestore
          .collection('users')
          .where('isLocationShared', isEqualTo: true)
          .get();

      // Prepare user data for isolate calculation
      final allUsers = <Map<String, dynamic>>[];
      for (var doc in snapshot.docs) {
        if (doc.id == userId) continue; // Skip current user

        final data = doc.data();
        allUsers.add({
          'uid': doc.id,
          'displayName': data['displayName'] ?? 'Unknown',
          'photoUrl': data['photoUrl'],
          'latitude': data['latitude'],
          'longitude': data['longitude'],
        });
      }

      // Offload distance calculation to isolate
      _isolateService.updateNearbyTravelers(allUsers, currentPosition);

      AppLogger.debug(_tag, 'Nearby travelers calculation delegated to isolate', {
        'totalUsers': allUsers.length,
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
    _nearbyTravelersSubscription?.cancel();
    _isolateService.dispose();
    super.dispose();
  }
}

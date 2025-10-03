import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../core/utils/logger.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  static const String _tag = 'LocationService';

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    AppLogger.debug(_tag, 'Checking if location services are enabled');
    final isEnabled = await Geolocator.isLocationServiceEnabled();
    AppLogger.info(_tag, 'Location services enabled: $isEnabled');
    return isEnabled;
  }

  /// Check location permission status
  Future<LocationPermission> checkPermission() async {
    AppLogger.debug(_tag, 'Checking location permission status');
    final permission = await Geolocator.checkPermission();
    AppLogger.info(_tag, 'Current permission status: $permission');
    return permission;
  }

  /// Request location permission
  Future<LocationPermission> requestPermission() async {
    AppLogger.debug(_tag, 'Requesting location permission');
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      AppLogger.info(_tag, 'Permission denied, requesting user permission');
      permission = await Geolocator.requestPermission();
      AppLogger.info(_tag, 'Permission request result: $permission');
    } else {
      AppLogger.info(_tag, 'Permission already granted: $permission');
    }

    return permission;
  }

  /// Get current location
  Future<Position?> getCurrentLocation() async {
    try {
      AppLogger.debug(_tag, 'Getting current location');

      // Check if location services are enabled
      bool serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        AppLogger.warning(_tag, 'Location services are disabled');
        throw Exception('Location services are disabled');
      }

      // Check permissions
      LocationPermission permission = await checkPermission();

      if (permission == LocationPermission.denied) {
        AppLogger.warning(_tag, 'Location permission denied, requesting permission');
        permission = await requestPermission();
        if (permission == LocationPermission.denied) {
          AppLogger.error(_tag, 'Location permissions are denied by user');
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        AppLogger.error(_tag, 'Location permissions are permanently denied');
        throw Exception('Location permissions are permanently denied');
      }

      // Get current position
      AppLogger.debug(_tag, 'Fetching current position with high accuracy');
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      AppLogger.success(_tag, 'Location retrieved successfully', {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': '${position.accuracy}m',
      });

      return position;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get current location', e, stackTrace);
      return null;
    }
  }

  /// Get address from coordinates (Reverse Geocoding)
  Future<String> getAddressFromCoordinates(double lat, double lng) async {
    try {
      AppLogger.debug(_tag, 'Reverse geocoding coordinates', {'lat': lat, 'lng': lng});

      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        final address = '${place.locality}, ${place.country}';
        AppLogger.success(_tag, 'Address found: $address');
        return address;
      }

      AppLogger.warning(_tag, 'No address found for coordinates');
      return 'Unknown Location';
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Error getting address from coordinates', e, stackTrace);
      return 'Unknown Location';
    }
  }

  /// Get coordinates from address (Geocoding)
  Future<Position?> getCoordinatesFromAddress(String address) async {
    try {
      AppLogger.debug(_tag, 'Geocoding address', {'address': address});

      List<Location> locations = await locationFromAddress(address);

      if (locations.isNotEmpty) {
        Location location = locations[0];
        AppLogger.success(_tag, 'Coordinates found for address', {
          'latitude': location.latitude,
          'longitude': location.longitude,
        });

        return Position(
          latitude: location.latitude,
          longitude: location.longitude,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
      }

      AppLogger.warning(_tag, 'No coordinates found for address: $address');
      return null;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Error getting coordinates from address', e, stackTrace);
      return null;
    }
  }

  /// Calculate distance between two points (in kilometers)
  double calculateDistance(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    AppLogger.debug(_tag, 'Calculating distance between two points', {
      'start': {'lat': startLat, 'lng': startLng},
      'end': {'lat': endLat, 'lng': endLng},
    });

    final distance = Geolocator.distanceBetween(
      startLat,
      startLng,
      endLat,
      endLng,
    ) / 1000; // Convert to kilometers

    AppLogger.info(_tag, 'Distance calculated: ${distance.toStringAsFixed(2)} km');
    return distance;
  }

  /// Get location stream (real-time updates)
  Stream<Position> getLocationStream() {
    AppLogger.debug(_tag, 'Starting location stream with 10m distance filter');

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );

    return Geolocator.getPositionStream(locationSettings: locationSettings).map((position) {
      AppLogger.info(_tag, 'Location stream update', {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': '${position.accuracy}m',
      });
      return position;
    });
  }

  /// Open location settings
  Future<bool> openLocationSettings() async {
    AppLogger.debug(_tag, 'Opening device location settings');
    final result = await Geolocator.openLocationSettings();
    AppLogger.info(_tag, 'Location settings opened: $result');
    return result;
  }
}

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/logger.dart';
import '../../services/location_service.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  static const String _tag = 'ExploreScreen';

  GoogleMapController? _mapController;
  final LocationService _locationService = LocationService();

  Position? _currentPosition;
  Set<Marker> _markers = {};
  bool _isLoading = true;
  String? _errorMessage;

  // Default location (Jakarta, Indonesia)
  static const LatLng _defaultLocation = LatLng(-6.2088, 106.8456);

  @override
  void initState() {
    super.initState();
    AppLogger.debug(_tag, 'Explore screen initialized');
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    try {
      AppLogger.debug(_tag, 'Initializing location and map');

      Position? position = await _locationService.getCurrentLocation();

      if (position != null) {
        AppLogger.success(_tag, 'Location initialized', {
          'latitude': position.latitude,
          'longitude': position.longitude,
        });

        setState(() {
          _currentPosition = position;
          _isLoading = false;
        });

        // Add current location marker
        _addCurrentLocationMarker(position);

        // Move camera to current location
        AppLogger.debug(_tag, 'Moving camera to current location');
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(position.latitude, position.longitude),
            15,
          ),
        );

        // Add nearby travelers (dummy data for now)
        _addNearbyTravelersMarkers(position);
      } else {
        AppLogger.warning(_tag, 'Unable to get location - position is null');
        setState(() {
          _isLoading = false;
          _errorMessage = 'Unable to get location';
        });
      }
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to initialize location', e, stackTrace);
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  void _addCurrentLocationMarker(Position position) {
    AppLogger.debug(_tag, 'Adding current location marker');

    setState(() {
      _markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(position.latitude, position.longitude),
          infoWindow: const InfoWindow(title: 'You are here'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    });

    AppLogger.info(_tag, 'Current location marker added', {
      'latitude': position.latitude,
      'longitude': position.longitude,
    });
  }

  void _addNearbyTravelersMarkers(Position currentPosition) {
    AppLogger.debug(_tag, 'Adding nearby travelers markers (dummy data)');

    // Dummy nearby travelers (replace with real data from Firebase later)
    final List<Map<String, dynamic>> nearbyTravelers = [
      {
        'id': '1',
        'name': 'Sarah Johnson',
        'lat': currentPosition.latitude + 0.002,
        'lng': currentPosition.longitude + 0.002,
      },
      {
        'id': '2',
        'name': 'John Doe',
        'lat': currentPosition.latitude - 0.003,
        'lng': currentPosition.longitude + 0.001,
      },
      {
        'id': '3',
        'name': 'Emma Wilson',
        'lat': currentPosition.latitude + 0.001,
        'lng': currentPosition.longitude - 0.002,
      },
    ];

    setState(() {
      for (var traveler in nearbyTravelers) {
        _markers.add(
          Marker(
            markerId: MarkerId(traveler['id']),
            position: LatLng(traveler['lat'], traveler['lng']),
            infoWindow: InfoWindow(title: traveler['name']),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
        );
      }
    });

    AppLogger.success(_tag, 'Nearby travelers markers added', {
      'count': nearbyTravelers.length,
      'travelers': nearbyTravelers.map((t) => t['name']).toList(),
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    AppLogger.debug(_tag, 'Google Map created');
    _mapController = controller;
    AppLogger.info(_tag, 'Map controller initialized');
  }

  Future<void> _goToCurrentLocation() async {
    AppLogger.action('User tapped "My Location" button');

    if (_currentPosition != null) {
      AppLogger.debug(_tag, 'Animating camera to current location');
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          15,
        ),
      );
      AppLogger.info(_tag, 'Camera moved to current location');
    } else {
      AppLogger.warning(_tag, 'Cannot go to current location - position is null');
    }
  }

  @override
  void dispose() {
    AppLogger.debug(_tag, 'Disposing explore screen resources');
    _mapController?.dispose();
    _markers.clear();
    AppLogger.info(_tag, 'Map controller disposed and markers cleared');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Google Map
            GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _currentPosition != null
                    ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                    : _defaultLocation,
                zoom: 15,
              ),
              markers: _markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: true,
              // Performance optimizations
              liteModeEnabled: false,
              tiltGesturesEnabled: false,
              rotateGesturesEnabled: false,
              buildingsEnabled: false,
              trafficEnabled: false,
            ),

            // Header
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  border: Border(
                    bottom: BorderSide(color: AppColors.divider, width: 1),
                  ),
                ),
                child: Text(
                  'Explore',
                  style: AppTextStyles.headlineSmall,
                ),
              ),
            ),

            // Loading Overlay
            if (_isLoading)
              Container(
                color: AppColors.white.withOpacity(0.9),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.black),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Getting your location...',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Error Message
            if (_errorMessage != null && !_isLoading)
              Positioned(
                bottom: 100,
                left: 24,
                right: 24,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

            // My Location Button
            Positioned(
              bottom: 100,
              right: 24,
              child: FloatingActionButton(
                onPressed: _goToCurrentLocation,
                backgroundColor: AppColors.black,
                child: const Icon(
                  Icons.my_location,
                  color: AppColors.white,
                ),
              ),
            ),

            // Nearby Travelers Bottom Sheet Preview
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 24,
                          decoration: BoxDecoration(
                            color: AppColors.black,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Nearby Travelers',
                          style: AppTextStyles.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${_markers.length - 1} travelers found near you',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

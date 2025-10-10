import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/marker_generator.dart';
import '../../core/utils/marker_cluster.dart';
import '../../core/providers/location_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/explore_ui_provider.dart';

// Data class for optimized map rebuilds
class _MapData {
  final Position? currentPosition;
  final List<Map<String, dynamic>> nearbyTravelers;
  final bool isLocationSharing;

  const _MapData({
    required this.currentPosition,
    required this.nearbyTravelers,
    required this.isLocationSharing,
  });
}

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  static const String _tag = 'ExploreScreen';

  GoogleMapController? _mapController;

  // Progressive loading settings
  static const int _markerBatchSize = 10;

  // Clustering settings
  final bool _enableClustering = true;

  // Default location (Jakarta, Indonesia)
  static const LatLng _defaultLocation = LatLng(-6.2088, 106.8456);

  @override
  void initState() {
    super.initState();
    AppLogger.debug(_tag, 'Explore screen initialized');

    // Initialize location when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeLocation();
    });
  }

  Future<void> _initializeLocation() async {
    final locationProvider = Provider.of<LocationProvider>(
      context,
      listen: false,
    );
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final exploreUIProvider = Provider.of<ExploreUIProvider>(
      context,
      listen: false,
    );

    try {
      AppLogger.debug(_tag, 'Initializing location and map');

      // Get current location
      final position = await locationProvider.getCurrentLocation();

      if (position != null) {
        AppLogger.success(_tag, 'Location initialized', {
          'latitude': position.latitude,
          'longitude': position.longitude,
        });

        exploreUIProvider.setLoading(false);

        // Move camera to current location
        AppLogger.debug(_tag, 'Moving camera to current location');
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(position.latitude, position.longitude),
            15,
          ),
        );

        // Start location stream if user is authenticated
        if (authProvider.isAuthenticated && !authProvider.isGuest) {
          await locationProvider.startLocationStream();
          exploreUIProvider.setLocationSharing(
            locationProvider.isLocationSharing,
          );
        }

        // Update markers from provider
        _updateMarkers();
      } else {
        AppLogger.warning(_tag, 'Unable to get location - position is null');
        exploreUIProvider.setLoading(false);
        exploreUIProvider.setError(
          'Unable to get location. Please enable location services.',
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to initialize location', e, stackTrace);
      exploreUIProvider.setLoading(false);
      exploreUIProvider.setError(e.toString());
    }
  }

  Future<void> _updateMarkers() async {
    final exploreUIProvider = Provider.of<ExploreUIProvider>(
      context,
      listen: false,
    );

    if (!mounted || exploreUIProvider.isLoadingMarkers) return;

    exploreUIProvider.setLoadingMarkers(true);

    final locationProvider = Provider.of<LocationProvider>(
      context,
      listen: false,
    );
    final currentPosition = locationProvider.currentPosition;
    final nearbyTravelers = locationProvider.nearbyTravelers;

    AppLogger.debug(
      _tag,
      'Starting progressive marker update with clustering',
      {
        'hasPosition': currentPosition != null,
        'travelersCount': nearbyTravelers.length,
        'zoomLevel': exploreUIProvider.currentZoom.toStringAsFixed(1),
        'clusteringEnabled': _enableClustering,
      },
    );

    final Set<Marker> allMarkers = {};

    // Add current location marker first (priority)
    if (currentPosition != null) {
      try {
        final icon = await MarkerGenerator.createSimpleMarker(
          color: AppColors.black,
          emoji: '📍',
        );
        allMarkers.add(
          Marker(
            markerId: const MarkerId('current_location'),
            position: LatLng(
              currentPosition.latitude,
              currentPosition.longitude,
            ),
            icon: icon,
            anchor: const Offset(0.5, 0.5),
          ),
        );

        // Update UI immediately with current location marker
        if (mounted) {
          exploreUIProvider.setMarkers(Set.from(allMarkers));
        }
      } catch (e) {
        AppLogger.warning(_tag, 'Failed to create current location marker');
      }
    }

    // Cluster markers if enabled and zoom is low
    final List<MarkerClusterData> clusterData;
    if (_enableClustering) {
      clusterData = MarkerCluster.clusterMarkers(
        travelers: nearbyTravelers.take(50).toList(),
        zoomLevel: exploreUIProvider.currentZoom,
      );
    } else {
      clusterData = nearbyTravelers
          .take(50)
          .map(
            (t) => MarkerClusterData(
              position: LatLng(
                t['latitude'] as double,
                t['longitude'] as double,
              ),
              travelers: [t],
              isCluster: false,
            ),
          )
          .toList();
    }

    final totalBatches = (clusterData.length / _markerBatchSize).ceil();

    AppLogger.debug(_tag, 'Loading clustered markers in batches', {
      'totalClusters': clusterData.length,
      'batchSize': _markerBatchSize,
      'totalBatches': totalBatches,
    });

    for (int batchIndex = 0; batchIndex < totalBatches; batchIndex++) {
      if (!mounted) break;

      final startIndex = batchIndex * _markerBatchSize;
      final endIndex = (startIndex + _markerBatchSize).clamp(
        0,
        clusterData.length,
      );
      final batch = clusterData.sublist(startIndex, endIndex);

      AppLogger.debug(
        _tag,
        'Processing batch ${batchIndex + 1}/$totalBatches',
        {'markersInBatch': batch.length},
      );

      // Process batch in parallel
      final List<Future<Marker?>> batchFutures = [];
      for (var cluster in batch) {
        if (cluster.isCluster) {
          // Create cluster marker
          batchFutures.add(
            MarkerCluster.createClusterMarker(cluster.count)
                .then((icon) {
                  return Marker(
                        markerId: MarkerId(
                          'cluster_${cluster.position.latitude}_${cluster.position.longitude}',
                        ),
                        position: cluster.position,
                        icon: icon,
                        anchor: const Offset(0.5, 0.5),
                      )
                      as Marker?;
                })
                .catchError((e) {
                  AppLogger.warning(_tag, 'Failed to create cluster marker');
                  return null as Marker?;
                }),
          );
        } else {
          // Create individual traveler marker
          final traveler = cluster.travelers.first;
          final uid = traveler['uid'] as String;
          final photoUrl = traveler['photoUrl'] as String?;

          batchFutures.add(
            MarkerGenerator.createMarkerFromPhoto(
                  photoUrl: photoUrl,
                  isCurrentUser: false,
                )
                .then((icon) {
                  return Marker(
                        markerId: MarkerId(uid),
                        position: cluster.position,
                        icon: icon,
                        anchor: const Offset(0.5, 0.5),
                      )
                      as Marker?;
                })
                .catchError((e) {
                  AppLogger.warning(
                    _tag,
                    'Failed to create marker for traveler',
                    {'uid': uid},
                  );
                  return null as Marker?;
                }),
          );
        }
      }

      // Wait for batch to complete
      final batchMarkers = await Future.wait(batchFutures);
      allMarkers.addAll(batchMarkers.whereType<Marker>());

      // Update UI after each batch for progressive loading
      if (mounted) {
        exploreUIProvider.setMarkers(Set.from(allMarkers));
      }

      AppLogger.debug(_tag, 'Batch ${batchIndex + 1} completed', {
        'markersGenerated': batchMarkers.whereType<Marker>().length,
        'totalMarkers': allMarkers.length,
      });
    }

    if (mounted) {
      exploreUIProvider.setLoadingMarkers(false);
    }

    AppLogger.info(_tag, 'All markers loaded successfully', {
      'totalMarkersGenerated': allMarkers.length,
      'nearbyTravelers': nearbyTravelers.length,
      'cacheStats': MarkerGenerator.getCacheStats(),
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    AppLogger.debug(_tag, 'Google Map created');
    _mapController = controller;
    AppLogger.info(_tag, 'Map controller initialized');
  }

  void _onCameraMove(CameraPosition position) {
    final exploreUIProvider = Provider.of<ExploreUIProvider>(
      context,
      listen: false,
    );
    final newZoom = position.zoom;
    if ((newZoom - exploreUIProvider.currentZoom).abs() > 1.0) {
      // Significant zoom change - update zoom level
      AppLogger.debug(_tag, 'Significant zoom change detected', {
        'oldZoom': exploreUIProvider.currentZoom.toStringAsFixed(1),
        'newZoom': newZoom.toStringAsFixed(1),
      });

      exploreUIProvider.setZoom(newZoom);

      // Trigger marker update with new clustering
      _updateMarkers();
    }
  }

  Future<void> _goToCurrentLocation() async {
    final locationProvider = Provider.of<LocationProvider>(
      context,
      listen: false,
    );

    AppLogger.action('User tapped "My Location" button');

    final currentPosition = locationProvider.currentPosition;
    if (currentPosition != null) {
      AppLogger.debug(_tag, 'Animating camera to current location');
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(currentPosition.latitude, currentPosition.longitude),
          15,
        ),
      );
      AppLogger.info(_tag, 'Camera moved to current location');
    } else {
      AppLogger.warning(
        _tag,
        'Cannot go to current location - position is null',
      );
    }
  }

  Future<void> _toggleLocationSharing() async {
    final locationProvider = Provider.of<LocationProvider>(
      context,
      listen: false,
    );
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final exploreUIProvider = Provider.of<ExploreUIProvider>(
      context,
      listen: false,
    );

    if (authProvider.isGuest) {
      _showGuestModeDialog();
      return;
    }

    AppLogger.action('User toggled location sharing', {
      'currentValue': exploreUIProvider.isLocationSharingEnabled,
    });

    if (exploreUIProvider.isLocationSharingEnabled) {
      // Stop sharing
      await locationProvider.stopLocationStream();
      exploreUIProvider.setLocationSharing(false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location sharing disabled'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } else {
      // Start sharing
      await locationProvider.startLocationStream();
      exploreUIProvider.setLocationSharing(true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location sharing enabled'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _showGuestModeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign In Required'),
        content: const Text(
          'Please create an account or sign in to share your location with nearby travelers.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/auth');
            },
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    AppLogger.debug(_tag, 'Disposing explore screen resources');
    _mapController?.dispose();
    AppLogger.info(_tag, 'Map controller disposed and markers cleared');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<LocationProvider, ExploreUIProvider>(
      builder: (context, locationProvider, exploreUIProvider, child) {
        final mapData = _MapData(
          currentPosition: locationProvider.currentPosition,
          nearbyTravelers: locationProvider.nearbyTravelers,
          isLocationSharing: locationProvider.isLocationSharing,
        );

        // Update markers when location data changes
        if (mapData.currentPosition != null && !exploreUIProvider.isLoading) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _updateMarkers();
          });
        }

        final nearbyCount = mapData.nearbyTravelers.length;

        return Scaffold(
          backgroundColor: AppColors.white,
          body: SafeArea(
            child: Stack(
              children: [
                // Google Map
                GoogleMap(
                  onMapCreated: _onMapCreated,
                  onCameraMove: _onCameraMove,
                  initialCameraPosition: CameraPosition(
                    target: mapData.currentPosition != null
                        ? LatLng(
                            mapData.currentPosition!.latitude,
                            mapData.currentPosition!.longitude,
                          )
                        : _defaultLocation,
                    zoom: 15,
                  ),
                  markers: exploreUIProvider.markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  compassEnabled: true,
                  liteModeEnabled: false,
                  tiltGesturesEnabled: false,
                  rotateGesturesEnabled: false,
                  buildingsEnabled: false,
                  trafficEnabled: false,
                ),

                // Header with Location Sharing Toggle
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      color: AppColors.white,
                      border: Border(
                        bottom: BorderSide(color: AppColors.divider, width: 1),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Text(
                          'Explore',
                          style: AppTextStyles.headlineSmall,
                        ),
                        const Spacer(),
                        // Location Sharing Toggle
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: exploreUIProvider.isLocationSharingEnabled
                                ? AppColors.black
                                : AppColors.grey100,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: exploreUIProvider.isLocationSharingEnabled
                                  ? AppColors.black
                                  : AppColors.border,
                            ),
                          ),
                          child: GestureDetector(
                            onTap: _toggleLocationSharing,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  exploreUIProvider.isLocationSharingEnabled
                                      ? Icons.location_on
                                      : Icons.location_off,
                                  size: 16,
                                  color:
                                      exploreUIProvider.isLocationSharingEnabled
                                      ? AppColors.white
                                      : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  exploreUIProvider.isLocationSharingEnabled
                                      ? 'Sharing'
                                      : 'Share',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color:
                                        exploreUIProvider
                                            .isLocationSharingEnabled
                                        ? AppColors.white
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Loading Overlay
                if (exploreUIProvider.isLoading)
                  Container(
                    color: AppColors.white.withValues(alpha: 0.9),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.black,
                            ),
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
                if (exploreUIProvider.errorMessage != null &&
                    !exploreUIProvider.isLoading)
                  Positioned(
                    bottom: 200,
                    left: 24,
                    right: 24,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        exploreUIProvider.errorMessage!,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                // My Location Button
                Positioned(
                  bottom: 200,
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
                            const Text(
                              'Nearby Travelers',
                              style: AppTextStyles.titleLarge,
                            ),
                            const Spacer(),
                            if (nearbyCount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.black,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$nearbyCount',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          nearbyCount > 0
                              ? '$nearbyCount ${nearbyCount == 1 ? "traveler" : "travelers"} found near you (within 5km)'
                              : exploreUIProvider.isLocationSharingEnabled
                              ? 'No travelers nearby. Be the first to share your location!'
                              : 'Enable location sharing to find nearby travelers',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (nearbyCount > 0) ...[
                          const SizedBox(height: 16),
                          const Divider(color: AppColors.divider),
                          const SizedBox(height: 12),
                          ...mapData.nearbyTravelers.take(3).map((traveler) {
                            final distance =
                                traveler['distance'] as double? ?? 0;
                            final formattedDistance = distance < 1
                                ? '${(distance * 1000).toStringAsFixed(0)}m away'
                                : '${distance.toStringAsFixed(1)}km away';

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: AppColors.grey100,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.border,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.person_outline,
                                      color: AppColors.grey400,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          traveler['displayName'] ?? 'Traveler',
                                          style: AppTextStyles.titleSmall,
                                        ),
                                        Text(
                                          formattedDistance,
                                          style: AppTextStyles.bodySmall
                                              .copyWith(
                                                color: AppColors.textTertiary,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

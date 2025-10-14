import 'package:flutter/material.dart';
import '../../core/widgets/mock_google_maps.dart'; // Mock implementation while migrating to Mapbox
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/models/route_model.dart';
import '../../core/models/trip_model.dart';
import '../../core/models/analytics_model.dart';
import '../../core/utils/logger.dart';
import '../../services/ai/ai_route_planning_service.dart';
import '../../services/analytics_service.dart';
import '../../core/providers/auth_provider.dart';

/// AI-powered route planning screen with visual map integration
class RouteplanningScreen extends StatefulWidget {
  final Trip trip;
  final RouteLocation? origin;
  final RouteLocation? destination;

  const RouteplanningScreen({
    super.key,
    required this.trip,
    this.origin,
    this.destination,
  });

  @override
  State<RouteplanningScreen> createState() => _RouteplanningScreenState();
}

class _RouteplanningScreenState extends State<RouteplanningScreen>
    with TickerProviderStateMixin {
  static const String _tag = 'RouteplanningScreen';

  // Services
  final AIRoutePlanningService _routePlanningService = AIRoutePlanningService();
  final AnalyticsService _analyticsService = AnalyticsService();

  // Controllers
  late GoogleMapController _mapController;
  late AnimationController _fabAnimationController;
  late AnimationController _suggestionAnimationController;
  late TextEditingController _routeNameController;
  late TextEditingController _originController;
  late TextEditingController _destinationController;

  // State variables
  RoutePlan? _currentRoutePlan;
  final List<RouteLocation> _waypoints = [];
  List<AIRouteSuggestion> _aiSuggestions = [];
  TravelMode _selectedTravelMode = TravelMode.driving;
  RouteOptimization _selectedOptimization = RouteOptimization.fastest;
  final bool _isLoading = false;
  bool _isPlanning = false;
  bool _showWaypoints = false;
  bool _showSuggestions = false;

  // Map state
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  final LatLng _initialPosition = const LatLng(-6.2088, 106.8456); // Jakarta default

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeServices();
    _setupInitialData();
    _trackScreenView();
  }

  void _initializeControllers() {
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _suggestionAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _routeNameController = TextEditingController();
    _originController = TextEditingController();
    _destinationController = TextEditingController();
  }

  Future<void> _initializeServices() async {
    try {
      await _routePlanningService.initialize();
      await _analyticsService.initialize();
      AppLogger.info(_tag, 'Services initialized successfully');
    } catch (e) {
      AppLogger.error(_tag, 'Failed to initialize services', e);
      _showErrorSnackBar('Failed to initialize route planning services');
    }
  }

  void _setupInitialData() {
    // Set initial route name
    _routeNameController.text = '${widget.trip.title} Route';

    // Set origin and destination if provided
    if (widget.origin != null) {
      _originController.text = widget.origin!.name;
      _addMarker(widget.origin!, 'origin');
    }
    if (widget.destination != null) {
      _destinationController.text = widget.destination!.name;
      _addMarker(widget.destination!, 'destination');
    }

    _fabAnimationController.forward();
  }

  void _trackScreenView() {
    _analyticsService.trackScreenView(
      'route_planning_screen',
      properties: {
        'trip_id': widget.trip.id,
        'has_origin': widget.origin != null,
        'has_destination': widget.destination != null,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: _buildFloatingActionButtons(),
      bottomSheet: _showWaypoints ? _buildWaypointSheet() : null,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Route Planning'),
      backgroundColor: Colors.transparent,
      elevation: 0,
      actions: [
        IconButton(
          onPressed: _showSuggestions ? _hideSuggestions : _showAISuggestions,
          icon: Icon(
            _showSuggestions ? Icons.close : Icons.lightbulb_outline,
            color: _showSuggestions ? Colors.orange : null,
          ),
          tooltip: _showSuggestions ? 'Hide Suggestions' : 'AI Suggestions',
        ),
        IconButton(
          onPressed: _showRouteOptions,
          icon: const Icon(Icons.tune),
          tooltip: 'Route Options',
        ),
      ],
    );
  }

  Widget _buildBody() {
    return Stack(
      children: [
        // Google Maps
        _buildMap(),
        
        // Route input panel
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: _buildRouteInputPanel(),
        ),

        // AI Suggestions panel
        if (_showSuggestions)
          Positioned(
            top: 200,
            left: 16,
            right: 16,
            child: _buildAISuggestionsPanel(),
          ),

        // Loading overlay
        if (_isLoading)
          Container(
            color: Colors.black54,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }

  Widget _buildMap() {
    return GoogleMap(
      onMapCreated: (GoogleMapController controller) {
        _mapController = controller;
        _fitMarkersOnMap();
      },
      initialCameraPosition: CameraPosition(
        target: _initialPosition,
        zoom: 12.0,
      ),
      markers: _markers,
      polylines: _polylines,
      onTap: _onMapTap,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: true,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      mapType: MapType.normal,
    );
  }

  Widget _buildRouteInputPanel() {
    return FadeInDown(
      duration: const Duration(milliseconds: 600),
      child: Card(
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Route name
              TextField(
                controller: _routeNameController,
                decoration: const InputDecoration(
                  labelText: 'Route Name',
                  prefixIcon: Icon(Icons.edit),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              
              // Origin
              TextField(
                controller: _originController,
                decoration: InputDecoration(
                  labelText: 'From',
                  prefixIcon: const Icon(Icons.location_on, color: Colors.green),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: _selectOriginFromMap,
                    icon: const Icon(Icons.my_location),
                  ),
                ),
                onSubmitted: _searchOrigin,
              ),
              const SizedBox(height: 12),
              
              // Destination
              TextField(
                controller: _destinationController,
                decoration: InputDecoration(
                  labelText: 'To',
                  prefixIcon: const Icon(Icons.location_on, color: Colors.red),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: _selectDestinationFromMap,
                    icon: const Icon(Icons.search),
                  ),
                ),
                onSubmitted: _searchDestination,
              ),
              const SizedBox(height: 16),
              
              // Travel mode selector
              _buildTravelModeSelector(),
              const SizedBox(height: 16),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _waypoints.isNotEmpty ? _clearWaypoints : _addWaypoint,
                      icon: Icon(_waypoints.isNotEmpty ? Icons.clear : Icons.add_location),
                      label: Text(_waypoints.isNotEmpty ? 'Clear Waypoints' : 'Add Waypoints'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isPlanning ? null : _planRoute,
                      icon: _isPlanning 
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.route),
                      label: Text(_isPlanning ? 'Planning...' : 'Plan Route'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTravelModeSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: TravelMode.values.map((mode) {
        final isSelected = _selectedTravelMode == mode;
        return GestureDetector(
          onTap: () => _selectTravelMode(mode),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? Theme.of(context).primaryColor : Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getTravelModeIcon(mode),
                  color: isSelected ? Colors.white : Colors.grey[600],
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  _getTravelModeName(mode),
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[600],
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAISuggestionsPanel() {
    return FadeInUp(
      duration: const Duration(milliseconds: 500),
      child: Card(
        elevation: 8,
        child: Container(
          constraints: const BoxConstraints(maxHeight: 300),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb, color: Colors.white),
                    const SizedBox(width: 8),
                    const Text(
                      'AI Suggestions',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: _hideSuggestions,
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(8),
                  itemCount: _aiSuggestions.length,
                  itemBuilder: (context, index) {
                    final suggestion = _aiSuggestions[index];
                    return _buildSuggestionCard(suggestion);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionCard(AIRouteSuggestion suggestion) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getPriorityColor(suggestion.priorityScore),
          child: Text(
            suggestion.priorityScore.toString(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          suggestion.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          suggestion.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          onPressed: () => _applySuggestion(suggestion),
          icon: const Icon(Icons.check_circle_outline),
        ),
        onTap: () => _showSuggestionDetails(suggestion),
      ),
    );
  }

  Widget _buildWaypointSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.3,
      minChildSize: 0.1,
      maxChildSize: 0.7,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.add_location_alt),
                    const SizedBox(width: 8),
                    const Text(
                      'Waypoints',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _hideWaypoints,
                      child: const Text('Done'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: _waypoints.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _waypoints.length) {
                      return ListTile(
                        leading: const Icon(Icons.add_circle_outline),
                        title: const Text('Add Waypoint'),
                        onTap: _addWaypoint,
                      );
                    }
                    
                    final waypoint = _waypoints[index];
                    return Dismissible(
                      key: Key(waypoint.id),
                      onDismissed: (direction) => _removeWaypoint(index),
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text('${index + 1}'),
                        ),
                        title: Text(waypoint.name),
                        subtitle: Text(waypoint.address),
                        trailing: ReorderableDragStartListener(
                          index: index,
                          child: const Icon(Icons.drag_handle),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFloatingActionButtons() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Navigate button (if route is planned)
        if (_currentRoutePlan != null)
          ScaleTransition(
            scale: _fabAnimationController,
            child: FloatingActionButton(
              heroTag: 'navigate',
              onPressed: _startNavigation,
              backgroundColor: Colors.green,
              child: const Icon(Icons.navigation),
            ),
          ),
        const SizedBox(height: 16),
        
        // My location button
        ScaleTransition(
          scale: _fabAnimationController,
          child: FloatingActionButton(
            heroTag: 'location',
            onPressed: _goToMyLocation,
            backgroundColor: Colors.blue,
            child: const Icon(Icons.my_location),
          ),
        ),
      ],
    );
  }

  // Event handlers
  void _onMapTap(LatLng position) {
    // Handle map tap for adding waypoints or destinations
    if (_showWaypoints) {
      _addWaypointAtPosition(position);
    }
  }

  Future<void> _planRoute() async {
    if (_originController.text.isEmpty || _destinationController.text.isEmpty) {
      _showErrorSnackBar('Please set both origin and destination');
      return;
    }

    setState(() {
      _isPlanning = true;
    });

    try {
      AppLogger.info(_tag, 'Starting route planning');

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.uid ?? '';

      // Create route locations from text inputs
      final origin = RouteLocation(
        id: 'origin_${DateTime.now().millisecondsSinceEpoch}',
        name: _originController.text,
        address: _originController.text,
        latitude: widget.origin?.latitude ?? _initialPosition.latitude,
        longitude: widget.origin?.longitude ?? _initialPosition.longitude,
      );

      final destination = RouteLocation(
        id: 'destination_${DateTime.now().millisecondsSinceEpoch}',
        name: _destinationController.text,
        address: _destinationController.text,
        latitude: widget.destination?.latitude ?? _initialPosition.latitude,
        longitude: widget.destination?.longitude ?? _initialPosition.longitude,
      );

      // Create route plan
      final routePlan = await _routePlanningService.createRoutePlan(
        userId: userId,
        tripId: widget.trip.id,
        name: _routeNameController.text,
        origin: origin,
        destination: destination,
        waypoints: _waypoints,
        travelMode: _selectedTravelMode,
        optimization: _selectedOptimization,
      );

      setState(() {
        _currentRoutePlan = routePlan;
        _aiSuggestions = routePlan.aiSuggestions;
      });

      // Update map with route
      _updateMapWithRoute(routePlan);
      
      // Track successful route planning
      _analyticsService.trackEvent(
        eventType: AnalyticsEventType.userAction,
        eventName: 'route_planned',
        properties: {
          'trip_id': widget.trip.id,
          'travel_mode': _selectedTravelMode.value,
          'waypoints_count': _waypoints.length,
          'total_distance': routePlan.totalDistance,
          'total_duration': routePlan.totalDuration,
        },
      );

      _showSuccessSnackBar('Route planned successfully!');
      AppLogger.success(_tag, 'Route planned successfully');

    } catch (e) {
      AppLogger.error(_tag, 'Failed to plan route', e);
      _showErrorSnackBar('Failed to plan route: ${e.toString()}');
    } finally {
      setState(() {
        _isPlanning = false;
      });
    }
  }

  void _updateMapWithRoute(RoutePlan routePlan) {
    setState(() {
      _markers.clear();
      _polylines.clear();

      // Add origin marker
      _addMarker(routePlan.origin, 'origin');
      
      // Add destination marker
      _addMarker(routePlan.destination, 'destination');
      
      // Add waypoint markers
      for (int i = 0; i < routePlan.waypoints.length; i++) {
        _addMarker(routePlan.waypoints[i], 'waypoint_$i');
      }

      // Add route polyline
      if (routePlan.steps.isNotEmpty) {
        final polylinePoints = <LatLng>[];
        for (final step in routePlan.steps) {
          polylinePoints.addAll(
            step.polylinePoints.map((point) => LatLng(point.latitude, point.longitude)),
          );
        }

        _polylines.add(Polyline(
          polylineId: const PolylineId('route'),
          points: polylinePoints,
          color: Theme.of(context).primaryColor,
          width: 5,
        ));
      }
    });

    _fitMarkersOnMap();
  }

  void _addMarker(RouteLocation location, String markerId) {
    _markers.add(
      Marker(
        markerId: MarkerId(markerId),
        position: LatLng(location.latitude, location.longitude),
        infoWindow: InfoWindow(
          title: location.name,
          snippet: location.address,
        ),
        icon: _getMarkerIcon(markerId),
      ),
    );
  }

  BitmapDescriptor _getMarkerIcon(String markerId) {
    if (markerId == 'origin') {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    } else if (markerId == 'destination') {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    } else {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
    }
  }

  void _fitMarkersOnMap() {
    if (_markers.isEmpty) return;

    LatLngBounds bounds;
    final positions = _markers.map((marker) => marker.position).toList();

    if (positions.length == 1) {
      bounds = LatLngBounds(
        southwest: LatLng(positions.first.latitude - 0.01, positions.first.longitude - 0.01),
        northeast: LatLng(positions.first.latitude + 0.01, positions.first.longitude + 0.01),
      );
    } else {
      double minLat = positions.first.latitude;
      double maxLat = positions.first.latitude;
      double minLng = positions.first.longitude;
      double maxLng = positions.first.longitude;

      for (final position in positions) {
        minLat = minLat < position.latitude ? minLat : position.latitude;
        maxLat = maxLat > position.latitude ? maxLat : position.latitude;
        minLng = minLng < position.longitude ? minLng : position.longitude;
        maxLng = maxLng > position.longitude ? maxLng : position.longitude;
      }

      bounds = LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      );
    }

    _mapController.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100.0),
    );
  }

  // Helper methods
  IconData _getTravelModeIcon(TravelMode mode) {
    switch (mode) {
      case TravelMode.driving:
        return Icons.directions_car;
      case TravelMode.walking:
        return Icons.directions_walk;
      case TravelMode.bicycling:
        return Icons.directions_bike;
      case TravelMode.transit:
        return Icons.directions_transit;
    }
  }

  String _getTravelModeName(TravelMode mode) {
    switch (mode) {
      case TravelMode.driving:
        return 'Drive';
      case TravelMode.walking:
        return 'Walk';
      case TravelMode.bicycling:
        return 'Bike';
      case TravelMode.transit:
        return 'Transit';
    }
  }

  Color _getPriorityColor(int priority) {
    if (priority >= 8) return Colors.red;
    if (priority >= 6) return Colors.orange;
    if (priority >= 4) return Colors.blue;
    return Colors.grey;
  }

  void _selectTravelMode(TravelMode mode) {
    setState(() {
      _selectedTravelMode = mode;
    });
    
    _analyticsService.trackEvent(
      eventType: AnalyticsEventType.userAction,
      eventName: 'travel_mode_selected',
      properties: {'mode': mode.value},
    );
  }

  void _showAISuggestions() {
    setState(() {
      _showSuggestions = true;
    });
    _suggestionAnimationController.forward();
  }

  void _hideSuggestions() {
    setState(() {
      _showSuggestions = false;
    });
    _suggestionAnimationController.reverse();
  }

  void _showRouteOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _buildRouteOptionsSheet(),
    );
  }

  Widget _buildRouteOptionsSheet() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Route Options',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          // Optimization options
          ...RouteOptimization.values.map((optimization) {
            return RadioListTile<RouteOptimization>(
              title: Text(_getOptimizationName(optimization)),
              subtitle: Text(_getOptimizationDescription(optimization)),
              value: optimization,
              // ignore: deprecated_member_use
              groupValue: _selectedOptimization,
              // ignore: deprecated_member_use
              onChanged: (value) {
                setState(() {
                  _selectedOptimization = value!;
                });
                Navigator.pop(context);
              },
            );
          }),
        ],
      ),
    );
  }

  String _getOptimizationName(RouteOptimization optimization) {
    switch (optimization) {
      case RouteOptimization.fastest:
        return 'Fastest Route';
      case RouteOptimization.shortest:
        return 'Shortest Route';
      case RouteOptimization.economic:
        return 'Most Economic';
      case RouteOptimization.scenic:
        return 'Scenic Route';
      case RouteOptimization.avoidTolls:
        return 'Avoid Tolls';
      case RouteOptimization.avoidHighways:
        return 'Avoid Highways';
    }
  }

  String _getOptimizationDescription(RouteOptimization optimization) {
    switch (optimization) {
      case RouteOptimization.fastest:
        return 'Optimize for shortest travel time';
      case RouteOptimization.shortest:
        return 'Optimize for shortest distance';
      case RouteOptimization.economic:
        return 'Balance time, distance, and fuel costs';
      case RouteOptimization.scenic:
        return 'Prefer scenic and interesting routes';
      case RouteOptimization.avoidTolls:
        return 'Avoid toll roads when possible';
      case RouteOptimization.avoidHighways:
        return 'Avoid highways and freeways';
    }
  }

  // Placeholder methods for functionality
  void _searchOrigin(String value) {
    // Implement location search
  }

  void _searchDestination(String value) {
    // Implement location search
  }

  void _selectOriginFromMap() {
    // Implement map-based origin selection
  }

  void _selectDestinationFromMap() {
    // Implement map-based destination selection
  }

  void _addWaypoint() {
    setState(() {
      _showWaypoints = true;
    });
  }

  void _clearWaypoints() {
    setState(() {
      _waypoints.clear();
      _showWaypoints = false;
    });
    _updateMapMarkers();
  }

  void _hideWaypoints() {
    setState(() {
      _showWaypoints = false;
    });
  }

  void _addWaypointAtPosition(LatLng position) {
    final waypoint = RouteLocation(
      id: 'waypoint_${_waypoints.length}',
      name: 'Waypoint ${_waypoints.length + 1}',
      address: 'Added from map',
      latitude: position.latitude,
      longitude: position.longitude,
    );
    
    setState(() {
      _waypoints.add(waypoint);
    });
    _updateMapMarkers();
  }

  void _removeWaypoint(int index) {
    setState(() {
      _waypoints.removeAt(index);
    });
    _updateMapMarkers();
  }

  void _updateMapMarkers() {
    setState(() {
      _markers.removeWhere((marker) => marker.markerId.value.startsWith('waypoint_'));
      
      for (int i = 0; i < _waypoints.length; i++) {
        _addMarker(_waypoints[i], 'waypoint_$i');
      }
    });
  }

  void _applySuggestion(AIRouteSuggestion suggestion) {
    _analyticsService.trackEvent(
      eventType: AnalyticsEventType.aiInteraction,
      eventName: 'ai_suggestion_applied',
      properties: {
        'suggestion_id': suggestion.suggestionId,
        'suggestion_type': suggestion.optimizationType.value,
      },
    );

    _showSuccessSnackBar('Applied: ${suggestion.title}');
  }

  void _showSuggestionDetails(AIRouteSuggestion suggestion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(suggestion.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(suggestion.description),
            const SizedBox(height: 16),
            Text(
              'Reasoning:',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Text(suggestion.reasoning),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _applySuggestion(suggestion);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _startNavigation() {
    if (_currentRoutePlan == null) return;

    Navigator.pushNamed(
      context,
      '/navigation',
      arguments: _currentRoutePlan,
    );
  }

  void _goToMyLocation() async {
    // Implement current location functionality
  }

  // Utility methods
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _suggestionAnimationController.dispose();
    _routeNameController.dispose();
    _originController.dispose();
    _destinationController.dispose();
    super.dispose();
  }
}
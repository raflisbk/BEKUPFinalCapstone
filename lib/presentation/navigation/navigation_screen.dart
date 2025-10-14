import 'package:flutter/material.dart';
import '../../core/widgets/mock_google_maps.dart'; // Mock implementation while migrating to Mapbox
import 'package:animate_do/animate_do.dart';
import '../../core/models/route_model.dart';
import '../../core/models/analytics_model.dart';
import '../../core/utils/logger.dart';
import '../../services/ai/ai_navigation_service.dart';
import '../../services/analytics_service.dart';

/// Turn-by-turn navigation screen with real-time AI suggestions
class NavigationScreen extends StatefulWidget {
  final RoutePlan routePlan;

  const NavigationScreen({
    super.key,
    required this.routePlan,
  });

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen>
    with TickerProviderStateMixin {
  static const String _tag = 'NavigationScreen';

  // Services
  final AINavigationService _navigationService = AINavigationService();
  final AnalyticsService _analyticsService = AnalyticsService();

  // Controllers
  late GoogleMapController _mapController;
  late AnimationController _instructionAnimationController;
  late AnimationController _suggestionAnimationController;

  // State variables
  NavigationUpdate? _currentUpdate;
  final List<AINavigationSuggestion> _activeSuggestions = [];
  bool _isNavigating = false;
  bool _showSuggestions = false;
  bool _isMuted = false;
  MapType _mapType = MapType.normal;

  // Map state
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  final Set<Circle> _circles = {};

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeServices();
    _setupNavigation();
    _trackScreenView();
  }

  void _initializeControllers() {
    _instructionAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _suggestionAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  Future<void> _initializeServices() async {
    try {
      await _navigationService.initialize();
      await _analyticsService.initialize();
      
      // Set up navigation callbacks
      _navigationService.onNavigationUpdate = _handleNavigationUpdate;
      _navigationService.onAISuggestion = _handleAISuggestion;
      _navigationService.onRouteDeviation = _handleRouteDeviation;

      AppLogger.info(_tag, 'Services initialized successfully');
    } catch (e) {
      AppLogger.error(_tag, 'Failed to initialize services', e);
      _showErrorSnackBar('Failed to initialize navigation services');
    }
  }

  Future<void> _setupNavigation() async {
    try {
      _updateMapWithRoute();
      AppLogger.info(_tag, 'Navigation setup completed');
    } catch (e) {
      AppLogger.error(_tag, 'Failed to setup navigation', e);
    }
  }

  void _trackScreenView() {
    _analyticsService.trackScreenView(
      'navigation_screen',
      properties: {
        'route_id': widget.routePlan.id,
        'travel_mode': widget.routePlan.travelMode.value,
        'total_steps': widget.routePlan.steps.length,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: _buildBody(),
        bottomSheet: _buildNavigationPanel(),
      ),
    );
  }

  Widget _buildBody() {
    return Stack(
      children: [
        // Google Maps (full screen)
        _buildMap(),
        
        // Top status bar
        Positioned(
          top: MediaQuery.of(context).padding.top,
          left: 0,
          right: 0,
          child: _buildTopStatusBar(),
        ),

        // AI Suggestions overlay
        if (_showSuggestions && _activeSuggestions.isNotEmpty)
          Positioned(
            top: MediaQuery.of(context).padding.top + 80,
            left: 16,
            right: 16,
            child: _buildSuggestionsOverlay(),
          ),

        // Navigation controls
        Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          right: 16,
          child: _buildNavigationControls(),
        ),

        // Speed and compass overlay
        Positioned(
          bottom: 200,
          right: 16,
          child: _buildSpeedCompassOverlay(),
        ),
      ],
    );
  }

  Widget _buildMap() {
    return GoogleMap(
      onMapCreated: (GoogleMapController controller) {
        _mapController = controller;
        _setMapStyle();
      },
      initialCameraPosition: CameraPosition(
        target: LatLng(
          widget.routePlan.origin.latitude,
          widget.routePlan.origin.longitude,
        ),
        zoom: 18.0,
        bearing: 0,
        tilt: 60,
      ),
      markers: _markers,
      polylines: _polylines,
      circles: _circles,
      mapType: _mapType,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: false,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      trafficEnabled: true,
      buildingsEnabled: true,
    );
  }

  Widget _buildTopStatusBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Back button
          IconButton(
            onPressed: _showExitDialog,
            icon: const Icon(Icons.close, color: Colors.white),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 16),
          
          // Trip info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.routePlan.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    Text(
                      widget.routePlan.totalDistance,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const Text(' • ', style: TextStyle(color: Colors.grey)),
                    Text(
                      widget.routePlan.totalDuration,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    if (_currentUpdate != null) ...[
                      const Text(' • ', style: TextStyle(color: Colors.grey)),
                      Text(
                        'ETA ${_formatTime(_currentUpdate!.estimatedTimeArrival)}',
                        style: const TextStyle(color: Colors.blue, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          
          // Mute button
          IconButton(
            onPressed: _toggleMute,
            icon: Icon(
              _isMuted ? Icons.volume_off : Icons.volume_up,
              color: _isMuted ? Colors.grey : Colors.white,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationControls() {
    return Column(
      children: [
        // Map type toggle
        FloatingActionButton(
          heroTag: 'map_type',
          mini: true,
          onPressed: _toggleMapType,
          backgroundColor: Colors.black87,
          child: Icon(
            _mapType == MapType.normal ? Icons.satellite : Icons.map,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        
        // Center on location
        FloatingActionButton(
          heroTag: 'center_location',
          mini: true,
          onPressed: _centerOnCurrentLocation,
          backgroundColor: Colors.black87,
          child: const Icon(Icons.my_location, color: Colors.white),
        ),
        const SizedBox(height: 8),
        
        // AI Suggestions toggle
        FloatingActionButton(
          heroTag: 'ai_suggestions',
          mini: true,
          onPressed: _toggleSuggestions,
          backgroundColor: _showSuggestions ? Colors.orange : Colors.black87,
          child: Icon(
            Icons.lightbulb,
            color: _showSuggestions ? Colors.white : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildSpeedCompassOverlay() {
    return Column(
      children: [
        // Speed indicator
        if (_currentUpdate != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${(_currentUpdate!.currentSpeed * 3.6).toInt()}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'km/h',
                  style: TextStyle(color: Colors.grey, fontSize: 10),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        
        // Compass
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.rotate(
                angle: (_currentUpdate?.bearing ?? 0) * (3.14159 / 180),
                child: const Icon(
                  Icons.navigation,
                  color: Colors.red,
                  size: 30,
                ),
              ),
              const Positioned(
                top: 5,
                child: Text(
                  'N',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestionsOverlay() {
    return SlideInDown(
      duration: const Duration(milliseconds: 300),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 250),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
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
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _hideSuggestions,
                    icon: const Icon(Icons.close, color: Colors.white),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.all(8),
                itemCount: _activeSuggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = _activeSuggestions[index];
                  return _buildSuggestionCard(suggestion);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionCard(AINavigationSuggestion suggestion) {
    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          backgroundColor: _getPriorityColor(suggestion.priority),
          radius: 16,
          child: Text(
            suggestion.priority.toString(),
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
        title: Text(
          suggestion.title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          suggestion.description,
          style: const TextStyle(color: Colors.grey),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          onPressed: () => _dismissSuggestion(suggestion),
          icon: const Icon(Icons.close, color: Colors.grey),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        onTap: () => _showSuggestionDetails(suggestion),
      ),
    );
  }

  Widget _buildNavigationPanel() {
    if (_currentUpdate == null) {
      return _buildStartNavigationPanel();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress indicator
          _buildProgressIndicator(),
          const SizedBox(height: 16),
          
          // Current instruction
          _buildCurrentInstruction(),
          const SizedBox(height: 16),
          
          // Navigation controls
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildStartNavigationPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Ready to navigate to ${widget.routePlan.destination.name}?',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.routePlan.totalDistance} • ${widget.routePlan.totalDuration}',
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isNavigating ? null : _startNavigation,
              icon: _isNavigating 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.navigation),
              label: Text(_isNavigating ? 'Starting...' : 'Start Navigation'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final currentStep = _currentUpdate?.stepIndex ?? 0;
    final totalSteps = _currentUpdate?.totalSteps ?? 1;
    final progress = totalSteps > 0 ? (currentStep + 1) / totalSteps : 0.0;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Step ${currentStep + 1} of $totalSteps',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              '${(progress * 100).toInt()}% Complete',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentInstruction() {
    final instruction = _currentUpdate?.currentStep.instruction ?? 'Getting directions...';
    final distance = _currentUpdate?.distanceToNextStep ?? 0.0;

    return FadeTransition(
      opacity: _instructionAnimationController,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue[200]!),
        ),
        child: Row(
          children: [
            Icon(
              _getInstructionIcon(instruction),
              color: Colors.blue,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatDistance(distance),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    instruction,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _showRouteOverview,
            icon: const Icon(Icons.map),
            label: const Text('Overview'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[200],
              foregroundColor: Colors.black,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _stopNavigation,
            icon: const Icon(Icons.stop),
            label: const Text('Stop'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  // Event handlers
  void _handleNavigationUpdate(NavigationUpdate update) {
    setState(() {
      _currentUpdate = update;
    });

    // Update map camera to follow user
    _updateMapCamera(update.currentPosition);
    
    // Animate instruction change
    _instructionAnimationController.forward().then((_) {
      _instructionAnimationController.reverse();
    });

    AppLogger.debug(_tag, 'Navigation update received: Step ${update.stepIndex + 1}/${update.totalSteps}');
  }

  void _handleAISuggestion(AINavigationSuggestion suggestion) {
    setState(() {
      _activeSuggestions.add(suggestion);
      // Keep only the 3 most recent suggestions
      if (_activeSuggestions.length > 3) {
        _activeSuggestions.removeAt(0);
      }
    });

    // Show suggestions panel if high priority
    if (suggestion.priority >= 8 && !_showSuggestions) {
      _showSuggestionsPanel();
    }

    _analyticsService.trackEvent(
      eventType: AnalyticsEventType.aiInteraction,
      eventName: 'ai_navigation_suggestion_received',
      properties: {
        'suggestion_category': suggestion.category,
        'priority': suggestion.priority,
      },
    );

    AppLogger.info(_tag, 'AI suggestion received: ${suggestion.title}');
  }

  void _handleRouteDeviation(String message) {
    _showWarningSnackBar(message);
    AppLogger.warning(_tag, 'Route deviation: $message');
  }

  Future<void> _startNavigation() async {
    setState(() {
      _isNavigating = true;
    });

    try {
      final success = await _navigationService.startNavigation(widget.routePlan);
      
      if (success) {
        _analyticsService.trackEvent(
          eventType: AnalyticsEventType.userAction,
          eventName: 'navigation_started',
          properties: {
            'route_id': widget.routePlan.id,
            'travel_mode': widget.routePlan.travelMode.value,
          },
        );
        
        AppLogger.success(_tag, 'Navigation started successfully');
      } else {
        throw Exception('Failed to start navigation');
      }
    } catch (e) {
      AppLogger.error(_tag, 'Failed to start navigation', e);
      _showErrorSnackBar('Failed to start navigation: ${e.toString()}');
    } finally {
      setState(() {
        _isNavigating = false;
      });
    }
  }

  Future<void> _stopNavigation() async {
    final confirmed = await _showStopConfirmationDialog();
    if (!confirmed) return;

    try {
      await _navigationService.stopNavigation();
      
      _analyticsService.trackEvent(
        eventType: AnalyticsEventType.userAction,
        eventName: 'navigation_stopped',
        properties: {
          'route_id': widget.routePlan.id,
          'completed_steps': _currentUpdate?.stepIndex ?? 0,
          'total_steps': _currentUpdate?.totalSteps ?? 0,
        },
      );

      if (!mounted) return;
      Navigator.pop(context);
      AppLogger.info(_tag, 'Navigation stopped');
    } catch (e) {
      AppLogger.error(_tag, 'Failed to stop navigation', e);
      _showErrorSnackBar('Failed to stop navigation');
    }
  }

  void _updateMapWithRoute() {
    setState(() {
      _markers.clear();
      _polylines.clear();

      // Add route polyline
      if (widget.routePlan.steps.isNotEmpty) {
        final polylinePoints = <LatLng>[];
        for (final step in widget.routePlan.steps) {
          polylinePoints.addAll(
            step.polylinePoints.map((point) => LatLng(point.latitude, point.longitude)),
          );
        }

        _polylines.add(Polyline(
          polylineId: const PolylineId('route'),
          points: polylinePoints,
          color: Colors.blue,
          width: 6,
        ));
      }

      // Add destination marker
      _markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: LatLng(
            widget.routePlan.destination.latitude,
            widget.routePlan.destination.longitude,
          ),
          infoWindow: InfoWindow(
            title: widget.routePlan.destination.name,
            snippet: 'Destination',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    });
  }

  void _updateMapCamera(RouteLocation position) {
    _mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 18.0,
          bearing: _currentUpdate?.bearing ?? 0,
          tilt: 60,
        ),
      ),
    );
  }

  Future<void> _setMapStyle() async {
    // Set dark map style for night navigation
    const darkMapStyle = '''
    [
      {
        "elementType": "geometry",
        "stylers": [{"color": "#212121"}]
      },
      {
        "elementType": "labels.icon",
        "stylers": [{"visibility": "off"}]
      },
      {
        "elementType": "labels.text.fill",
        "stylers": [{"color": "#757575"}]
      },
      {
        "elementType": "labels.text.stroke",
        "stylers": [{"color": "#212121"}]
      }
    ]
    ''';

    // ignore: deprecated_member_use
    await _mapController.setMapStyle(darkMapStyle);
  }

  // Helper methods
  IconData _getInstructionIcon(String instruction) {
    final lowercaseInstruction = instruction.toLowerCase();
    
    if (lowercaseInstruction.contains('left')) {
      return Icons.turn_left;
    } else if (lowercaseInstruction.contains('right')) {
      return Icons.turn_right;
    } else if (lowercaseInstruction.contains('straight') || lowercaseInstruction.contains('continue')) {
      return Icons.straight;
    } else if (lowercaseInstruction.contains('u-turn')) {
      return Icons.u_turn_left;
    } else if (lowercaseInstruction.contains('exit')) {
      return Icons.exit_to_app;
    } else if (lowercaseInstruction.contains('merge')) {
      return Icons.merge_type;
    } else {
      return Icons.navigation;
    }
  }

  String _formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.toInt()} m';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)} km';
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Color _getPriorityColor(int priority) {
    if (priority >= 8) return Colors.red;
    if (priority >= 6) return Colors.orange;
    if (priority >= 4) return Colors.blue;
    return Colors.grey;
  }

  void _toggleMapType() {
    setState(() {
      _mapType = _mapType == MapType.normal ? MapType.satellite : MapType.normal;
    });
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    
    _analyticsService.trackEvent(
      eventType: AnalyticsEventType.userAction,
      eventName: 'navigation_mute_toggled',
      properties: {'is_muted': _isMuted},
    );
  }

  void _centerOnCurrentLocation() {
    if (_currentUpdate != null) {
      _updateMapCamera(_currentUpdate!.currentPosition);
    }
  }

  void _showSuggestionsPanel() {
    setState(() {
      _showSuggestions = true;
    });
    _suggestionAnimationController.forward();
  }

  void _toggleSuggestions() {
    if (_showSuggestions) {
      _hideSuggestions();
    } else {
      _showSuggestionsPanel();
    }
  }

  void _hideSuggestions() {
    setState(() {
      _showSuggestions = false;
    });
    _suggestionAnimationController.reverse();
  }

  void _dismissSuggestion(AINavigationSuggestion suggestion) {
    setState(() {
      _activeSuggestions.remove(suggestion);
    });
  }

  void _showSuggestionDetails(AINavigationSuggestion suggestion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(suggestion.title),
        content: Text(suggestion.description),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (suggestion.category == 'rerouting')
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Implement rerouting
              },
              child: const Text('Reroute'),
            ),
        ],
      ),
    );
  }

  void _showRouteOverview() {
    // Implement route overview
  }

  Future<bool> _showStopConfirmationDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stop Navigation'),
        content: const Text('Are you sure you want to stop navigation?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Stop'),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<bool> _onWillPop() async {
    if (_navigationService.isNavigating) {
      return await _showStopConfirmationDialog();
    }
    return true;
  }

  void _showExitDialog() async {
    final shouldExit = await _onWillPop();
    if (shouldExit && mounted) {
      Navigator.pop(context);
    }
  }

  void _showWarningSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
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
    _instructionAnimationController.dispose();
    _suggestionAnimationController.dispose();
    
    // Stop navigation if active
    if (_navigationService.isNavigating) {
      _navigationService.stopNavigation();
    }
    
    super.dispose();
  }
}
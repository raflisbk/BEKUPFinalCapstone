import 'dart:async';
import 'dart:isolate';
import 'package:geolocator/geolocator.dart';
import '../core/utils/logger.dart';

/// Isolate-based location service to prevent UI lag on low-end devices
/// Offloads heavy location calculations to a separate thread
class LocationIsolateService {
  static final LocationIsolateService _instance = LocationIsolateService._internal();
  factory LocationIsolateService() => _instance;
  LocationIsolateService._internal();

  static const String _tag = 'LocationIsolateService';

  Isolate? _isolate;
  SendPort? _sendPort;
  ReceivePort? _receivePort;

  final StreamController<Position> _locationStreamController = StreamController<Position>.broadcast();
  final StreamController<List<Map<String, dynamic>>> _nearbyTravelersController = StreamController<List<Map<String, dynamic>>>.broadcast();

  Stream<Position> get locationStream => _locationStreamController.stream;
  Stream<List<Map<String, dynamic>>> get nearbyTravelersStream => _nearbyTravelersController.stream;

  bool _isRunning = false;
  bool get isRunning => _isRunning;

  /// Start location tracking in isolate
  Future<void> startLocationTracking() async {
    if (_isRunning) {
      AppLogger.warning(_tag, 'Location tracking already running');
      return;
    }

    try {
      AppLogger.debug(_tag, 'Starting location tracking isolate');

      // Create receive port for communication from isolate
      _receivePort = ReceivePort();

      // Spawn isolate
      _isolate = await Isolate.spawn(
        _locationIsolateEntry,
        _receivePort!.sendPort,
      );

      // Listen to messages from isolate
      _receivePort!.listen((message) {
        if (message is SendPort) {
          // Store send port for sending messages to isolate
          _sendPort = message;
          _isRunning = true;
          AppLogger.success(_tag, 'Location isolate started successfully');
        } else if (message is Map<String, dynamic>) {
          // Handle different message types
          final type = message['type'] as String?;

          if (type == 'location') {
            // Broadcast location update
            final position = message['data'] as Position;
            _locationStreamController.add(position);
          } else if (type == 'nearby') {
            // Broadcast nearby travelers update
            final travelers = message['data'] as List<Map<String, dynamic>>;
            _nearbyTravelersController.add(travelers);
          } else if (type == 'error') {
            AppLogger.error(_tag, 'Isolate error: ${message['error']}');
          }
        }
      });

      AppLogger.success(_tag, 'Location tracking started in isolate');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to start location isolate', e, stackTrace);
      _isRunning = false;
    }
  }

  /// Stop location tracking
  Future<void> stopLocationTracking() async {
    if (!_isRunning) {
      AppLogger.warning(_tag, 'Location tracking not running');
      return;
    }

    try {
      AppLogger.debug(_tag, 'Stopping location tracking isolate');

      // Send stop message to isolate
      _sendPort?.send({'command': 'stop'});

      // Kill isolate
      _isolate?.kill(priority: Isolate.immediate);
      _isolate = null;

      // Close receive port
      _receivePort?.close();
      _receivePort = null;
      _sendPort = null;

      _isRunning = false;
      AppLogger.success(_tag, 'Location tracking stopped');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to stop location isolate', e, stackTrace);
    }
  }

  /// Update nearby travelers data (to be calculated in isolate)
  void updateNearbyTravelers(List<Map<String, dynamic>> allUsers, Position currentPosition) {
    if (!_isRunning || _sendPort == null) return;

    _sendPort!.send({
      'command': 'calculate_nearby',
      'users': allUsers,
      'currentPosition': currentPosition,
    });
  }

  /// Calculate distance between two points (offloaded to isolate)
  Future<double> calculateDistance({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) async {
    if (!_isRunning || _sendPort == null) {
      // Fallback to main thread calculation
      return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
    }

    final completer = Completer<double>();
    final responsePort = ReceivePort();

    _sendPort!.send({
      'command': 'calculate_distance',
      'lat1': lat1,
      'lon1': lon1,
      'lat2': lat2,
      'lon2': lon2,
      'responsePort': responsePort.sendPort,
    });

    responsePort.listen((response) {
      completer.complete(response as double);
      responsePort.close();
    });

    return completer.future;
  }

  /// Dispose resources
  void dispose() {
    AppLogger.debug(_tag, 'Disposing location isolate service');
    stopLocationTracking();
    _locationStreamController.close();
    _nearbyTravelersController.close();
  }
}

/// Isolate entry point - runs on separate thread
void _locationIsolateEntry(SendPort mainSendPort) async {
  const tag = 'LocationIsolate';

  // Create receive port for this isolate
  final isolateReceivePort = ReceivePort();

  // Send this isolate's send port back to main isolate
  mainSendPort.send(isolateReceivePort.sendPort);

  StreamSubscription<Position>? locationSubscription;
  bool isTracking = false;

  try {
    // Listen for commands from main isolate
    await for (final message in isolateReceivePort) {
      if (message is! Map<String, dynamic>) continue;

      final command = message['command'] as String?;

      if (command == 'stop') {
        // Stop tracking and exit
        await locationSubscription?.cancel();
        isolateReceivePort.close();
        break;
      } else if (command == 'start_tracking' && !isTracking) {
        // Start location stream
        const LocationSettings settings = LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        );

        locationSubscription = Geolocator.getPositionStream(locationSettings: settings).listen(
          (Position position) {
            // Send location update to main isolate
            mainSendPort.send({
              'type': 'location',
              'data': position,
            });
          },
          onError: (error) {
            mainSendPort.send({
              'type': 'error',
              'error': error.toString(),
            });
          },
        );

        isTracking = true;
      } else if (command == 'calculate_nearby') {
        // Calculate nearby travelers
        final users = message['users'] as List<Map<String, dynamic>>;
        final currentPosition = message['currentPosition'] as Position;
        const nearbyRadius = 5000.0; // 5km

        final nearby = <Map<String, dynamic>>[];

        for (final user in users) {
          final lat = user['latitude'] as double?;
          final lon = user['longitude'] as double?;

          if (lat == null || lon == null) continue;

          // Calculate distance
          final distance = Geolocator.distanceBetween(
            currentPosition.latitude,
            currentPosition.longitude,
            lat,
            lon,
          );

          if (distance <= nearbyRadius) {
            nearby.add({
              ...user,
              'distance': distance,
            });
          }
        }

        // Sort by distance
        nearby.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));

        // Send result back
        mainSendPort.send({
          'type': 'nearby',
          'data': nearby,
        });
      } else if (command == 'calculate_distance') {
        // Calculate single distance
        final lat1 = message['lat1'] as double;
        final lon1 = message['lon1'] as double;
        final lat2 = message['lat2'] as double;
        final lon2 = message['lon2'] as double;
        final responsePort = message['responsePort'] as SendPort;

        final distance = Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
        responsePort.send(distance);
      }
    }
  } catch (e) {
    mainSendPort.send({
      'type': 'error',
      'error': e.toString(),
    });
  }
}

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../core/utils/logger.dart';

/// Connectivity Service
/// Handles network connectivity monitoring and management
class ConnectivityService {
  static const String _tag = 'ConnectivityService';
  static final Connectivity _connectivity = Connectivity();
  static StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  static List<ConnectivityResult> _currentStatus = [ConnectivityResult.none];

  // Stream controller for connectivity changes
  static final StreamController<bool> _connectionStatusController = 
      StreamController<bool>.broadcast();

  /// Stream of connection status changes (true = connected, false = disconnected)
  static Stream<bool> get connectionStream => _connectionStatusController.stream;

  /// Initialize connectivity monitoring
  static Future<void> initialize() async {
    try {
      AppLogger.info(_tag, 'Initializing connectivity service...');

      // Get initial connectivity status
      _currentStatus = await _connectivity.checkConnectivity();
      AppLogger.info(_tag, 'Initial connectivity status: $_currentStatus');

      // Listen to connectivity changes
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        (List<ConnectivityResult> results) {
          _handleConnectivityChange(results);
        },
        onError: (error) {
          AppLogger.error(_tag, 'Connectivity subscription error', error);
        },
      );

      // Emit initial status
      _connectionStatusController.add(isConnected);

      AppLogger.success(_tag, 'Connectivity service initialized successfully');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to initialize connectivity service', e, stackTrace);
      rethrow;
    }
  }

  /// Handle connectivity changes
  static void _handleConnectivityChange(List<ConnectivityResult> results) {
    final wasConnected = isConnected;
    _currentStatus = results;
    final isNowConnected = isConnected;

    AppLogger.info(_tag, 'Connectivity changed: $results');

    if (wasConnected != isNowConnected) {
      if (isNowConnected) {
        AppLogger.success(_tag, 'Internet connection restored');
      } else {
        AppLogger.warning(_tag, 'Internet connection lost');
      }

      // Emit connection status change
      _connectionStatusController.add(isNowConnected);
    }
  }

  /// Check if device is connected to internet
  static bool get isConnected {
    return _currentStatus.isNotEmpty && 
           !_currentStatus.contains(ConnectivityResult.none);
  }

  /// Check if device is offline
  static bool get isOffline => !isConnected;

  /// Get current connectivity type
  static ConnectivityResult get currentConnectivityType {
    if (_currentStatus.isEmpty) return ConnectivityResult.none;
    
    // Prioritize mobile/wifi over ethernet/other connections
    if (_currentStatus.contains(ConnectivityResult.mobile)) {
      return ConnectivityResult.mobile;
    } else if (_currentStatus.contains(ConnectivityResult.wifi)) {
      return ConnectivityResult.wifi;
    } else if (_currentStatus.contains(ConnectivityResult.ethernet)) {
      return ConnectivityResult.ethernet;
    } else {
      return _currentStatus.first;
    }
  }

  /// Get human-readable connection type
  static String get connectionTypeString {
    switch (currentConnectivityType) {
      case ConnectivityResult.wifi:
        return 'WiFi';
      case ConnectivityResult.mobile:
        return 'Mobile Data';
      case ConnectivityResult.ethernet:
        return 'Ethernet';
      case ConnectivityResult.bluetooth:
        return 'Bluetooth';
      case ConnectivityResult.other:
        return 'Other';
      case ConnectivityResult.none:
      default:
        return 'No Connection';
    }
  }

  /// Check if connection is metered (mobile data)
  static bool get isMeteredConnection {
    return currentConnectivityType == ConnectivityResult.mobile;
  }

  /// Check if connection is unmetered (WiFi/Ethernet)
  static bool get isUnmeteredConnection {
    return currentConnectivityType == ConnectivityResult.wifi ||
           currentConnectivityType == ConnectivityResult.ethernet;
  }

  /// Wait for internet connection
  static Future<void> waitForConnection({Duration? timeout}) async {
    if (isConnected) return;

    AppLogger.info(_tag, 'Waiting for internet connection...');

    final completer = Completer<void>();
    StreamSubscription<bool>? subscription;

    subscription = connectionStream.listen((bool connected) {
      if (connected) {
        AppLogger.success(_tag, 'Internet connection established');
        subscription?.cancel();
        if (!completer.isCompleted) {
          completer.complete();
        }
      }
    });

    // Add timeout if specified
    if (timeout != null) {
      Timer(timeout, () {
        subscription?.cancel();
        if (!completer.isCompleted) {
          AppLogger.warning(_tag, 'Wait for connection timed out');
          completer.completeError(TimeoutException('Connection timeout', timeout));
        }
      });
    }

    return completer.future;
  }

  /// Execute function when connected
  static Future<T> executeWhenConnected<T>(
    Future<T> Function() function, {
    Duration? timeout,
  }) async {
    if (isOffline) {
      await waitForConnection(timeout: timeout);
    }
    return await function();
  }

  /// Get connectivity status details
  static Map<String, dynamic> getConnectionStatus() {
    return {
      'isConnected': isConnected,
      'connectionType': connectionTypeString,
      'isMetered': isMeteredConnection,
      'results': _currentStatus.map((r) => r.name).toList(),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Perform network connectivity test
  static Future<bool> performConnectivityTest() async {
    try {
      AppLogger.debug(_tag, 'Performing connectivity test...');

      // This is a basic connectivity check
      // For more robust testing, you might want to ping a known server
      final results = await _connectivity.checkConnectivity();
      final connected = results.isNotEmpty && !results.contains(ConnectivityResult.none);

      AppLogger.info(_tag, 'Connectivity test result: $connected');
      return connected;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Connectivity test failed', e, stackTrace);
      return false;
    }
  }

  /// Add connectivity listener
  static StreamSubscription<bool> addConnectionListener(
    void Function(bool isConnected) callback,
  ) {
    AppLogger.debug(_tag, 'Adding connectivity listener');
    return connectionStream.listen(callback);
  }

  /// Dispose connectivity service
  static Future<void> dispose() async {
    try {
      AppLogger.info(_tag, 'Disposing connectivity service...');

      await _connectivitySubscription?.cancel();
      _connectivitySubscription = null;

      await _connectionStatusController.close();

      AppLogger.success(_tag, 'Connectivity service disposed successfully');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to dispose connectivity service', e, stackTrace);
    }
  }
}
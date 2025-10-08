import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../utils/logger.dart';

/// Service to monitor network connectivity status
class ConnectivityService {
  static const String _tag = 'ConnectivityService';

  static ConnectivityService? _instance;
  static ConnectivityService get instance => _instance ??= ConnectivityService._();

  ConnectivityService._();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  final StreamController<bool> _connectivityController =
      StreamController<bool>.broadcast();

  bool _isOnline = false;
  bool _isInitialized = false;

  /// Get current online status
  bool get isOnline => _isOnline;

  /// Stream of connectivity changes
  Stream<bool> get onConnectivityChanged => _connectivityController.stream;

  /// Initialize connectivity monitoring
  Future<void> initialize() async {
    if (_isInitialized) {
      AppLogger.debug(_tag, 'Connectivity service already initialized');
      return;
    }

    try {
      AppLogger.info(_tag, 'Initializing connectivity service');

      // Check initial connectivity
      await _checkConnectivity();

      // Listen to connectivity changes
      _subscription = _connectivity.onConnectivityChanged.listen(
        _onConnectivityChanged,
        onError: (error) {
          AppLogger.error(_tag, 'Connectivity stream error', error);
        },
      );

      _isInitialized = true;
      AppLogger.success(_tag, 'Connectivity service initialized');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to initialize connectivity service', e, stackTrace);
      rethrow;
    }
  }

  /// Check current connectivity
  Future<void> _checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateConnectionStatus(results);
    } catch (e) {
      AppLogger.error(_tag, 'Failed to check connectivity', e);
      _updateConnectionStatus([ConnectivityResult.none]);
    }
  }

  /// Handle connectivity changes
  void _onConnectivityChanged(List<ConnectivityResult> results) {
    AppLogger.debug(_tag, 'Connectivity changed: $results');
    _updateConnectionStatus(results);
  }

  /// Update connection status
  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final wasOnline = _isOnline;

    // Consider online if any connection except 'none'
    _isOnline = results.any((result) => result != ConnectivityResult.none);

    if (_isOnline != wasOnline) {
      AppLogger.info(
        _tag,
        _isOnline ? '🟢 Device is ONLINE' : '🔴 Device is OFFLINE',
        {
          'previousStatus': wasOnline ? 'online' : 'offline',
          'currentStatus': _isOnline ? 'online' : 'offline',
          'results': results.toString(),
        },
      );

      // Notify listeners
      _connectivityController.add(_isOnline);
    }
  }

  /// Get connection type details
  Future<ConnectionType> getConnectionType() async {
    try {
      final results = await _connectivity.checkConnectivity();

      if (results.contains(ConnectivityResult.wifi)) {
        return ConnectionType.wifi;
      } else if (results.contains(ConnectivityResult.mobile)) {
        return ConnectionType.mobile;
      } else if (results.contains(ConnectivityResult.ethernet)) {
        return ConnectionType.ethernet;
      } else {
        return ConnectionType.none;
      }
    } catch (e) {
      AppLogger.error(_tag, 'Failed to get connection type', e);
      return ConnectionType.none;
    }
  }

  /// Check if connected to WiFi
  Future<bool> isWiFi() async {
    final type = await getConnectionType();
    return type == ConnectionType.wifi;
  }

  /// Check if connected to mobile data
  Future<bool> isMobile() async {
    final type = await getConnectionType();
    return type == ConnectionType.mobile;
  }

  /// Wait for internet connection
  Future<void> waitForConnection({
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (_isOnline) return;

    AppLogger.info(_tag, 'Waiting for internet connection...');

    try {
      await _connectivityController.stream.firstWhere((isOnline) => isOnline).timeout(
        timeout,
        onTimeout: () {
          throw TimeoutException('Connection timeout after ${timeout.inSeconds}s');
        },
      );

      AppLogger.success(_tag, 'Connection established');
    } catch (e) {
      AppLogger.error(_tag, 'Failed to wait for connection', e);
      rethrow;
    }
  }

  /// Dispose resources
  void dispose() {
    AppLogger.debug(_tag, 'Disposing connectivity service');
    _subscription?.cancel();
    _connectivityController.close();
    _isInitialized = false;
  }
}

/// Connection type enum
enum ConnectionType {
  wifi,
  mobile,
  ethernet,
  none,
}

/// Extension for connection type
extension ConnectionTypeExtension on ConnectionType {
  String get displayName {
    switch (this) {
      case ConnectionType.wifi:
        return 'WiFi';
      case ConnectionType.mobile:
        return 'Mobile Data';
      case ConnectionType.ethernet:
        return 'Ethernet';
      case ConnectionType.none:
        return 'No Connection';
    }
  }

  bool get isMetered {
    return this == ConnectionType.mobile;
  }

  bool get isFast {
    return this == ConnectionType.wifi || this == ConnectionType.ethernet;
  }
}

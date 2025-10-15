import 'package:flutter/foundation.dart';
import '../models/trip_model.dart';
import '../utils/logger.dart';
import '../interfaces/trip_service_interface.dart';

/// Provider for Trip management
class TripProvider with ChangeNotifier {
  static const String _tag = 'TripProvider';

  // Service instance with dependency injection
  final ITripService _tripService;

  List<Trip> _userTrips = [];
  List<Trip> _publicTrips = [];
  Trip? _selectedTrip;
  bool _isLoading = false;
  String? _error;

  // Constructor with dependency injection
  TripProvider(this._tripService);

  // Getters
  List<Trip> get userTrips => _userTrips;
  List<Trip> get publicTrips => _publicTrips;
  Trip? get selectedTrip => _selectedTrip;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Set error state
  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _setError(null);
  }

  /// Load user trips
  Future<void> loadUserTrips() async {
    try {
      AppLogger.debug(_tag, 'Loading user trips');
      _setLoading(true);
      _setError(null);

      final tripsData = await _tripService.getUserTrips();
      _userTrips = tripsData.map((data) => Trip.fromMap(data)).toList();

      AppLogger.success(_tag, 'Loaded ${_userTrips.length} user trips');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to load user trips', e, stackTrace);
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Create new trip
  Future<Trip?> createTrip({
    required String title,
    required String description,
    required DateTime startDate,
    required DateTime endDate,
    required String destination,
    String? category, // Keep for UI consistency but won't be passed to service
    int? maxParticipants, // Keep for UI consistency but won't be passed to service
    bool isPublic = false,
    double? budget, // Change type to double to match interface
    List<String>? tags,
    Map<String, dynamic>? preferences,
  }) async {
    try {
      AppLogger.debug(_tag, 'Creating new trip: $title');
      _setLoading(true);
      _setError(null);

      final tripData = await _tripService.createTrip(
        title: title,
        description: description,
        startDate: startDate,
        endDate: endDate,
        destination: destination,
        isPublic: isPublic,
        budget: budget,
        tags: tags,
        preferences: preferences,
      );

      final newTrip = Trip.fromMap(tripData);
      _userTrips.insert(0, newTrip);
      _selectedTrip = newTrip;

      AppLogger.success(_tag, 'Trip created successfully: ${newTrip.id}');
      notifyListeners();
      return newTrip;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to create trip', e, stackTrace);
      _setError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Select a trip
  void selectTrip(Trip trip) {
    _selectedTrip = trip;
    notifyListeners();
  }

  /// Clear selected trip
  void clearSelection() {
    _selectedTrip = null;
    notifyListeners();
  }

  /// Refresh trips
  Future<void> refresh() async {
    await loadUserTrips();
  }
}
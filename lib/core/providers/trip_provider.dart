import 'package:flutter/foundation.dart';
import '../models/trip_model.dart';
import '../utils/logger.dart';
import '../../services/trip_service.dart';
import '../../services/supabase_config.dart';

/// Provider for Trip management
class TripProvider with ChangeNotifier {
  static const String _tag = 'TripProvider';

  // Service instance
  final TripService _tripService = TripService.instance;

  List<TripModel> _userTrips = [];
  List<TripModel> _publicTrips = [];
  TripModel? _selectedTrip;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<TripModel> get userTrips => _userTrips;
  List<TripModel> get publicTrips => _publicTrips;
  TripModel? get selectedTrip => _selectedTrip;
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
      _userTrips = tripsData.map((data) => TripModel.fromMap(data)).toList();

      AppLogger.success(_tag, 'Loaded ${_userTrips.length} user trips');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to load user trips', e, stackTrace);
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Create new trip
  Future<TripModel?> createTrip({
    required String title,
    required String description,
    required DateTime startDate,
    required DateTime endDate,
    double? budget,
    String? destination,
    bool isPublic = false,
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
        budget: budget,
        destination: destination,
        isPublic: isPublic,
        tags: tags,
        preferences: preferences,
      );

      final newTrip = TripModel.fromMap(tripData);
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
  void selectTrip(TripModel trip) {
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
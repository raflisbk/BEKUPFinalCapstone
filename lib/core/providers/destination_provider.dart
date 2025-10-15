import 'package:flutter/foundation.dart';
import '../models/destination_model.dart';
import '../utils/logger.dart';
import '../../services/interfaces/i_destination_service.dart';
import '../config/service_locator.dart';

/// Provider for Destination management
class DestinationProvider with ChangeNotifier {
  static const String _tag = 'DestinationProvider';

  // Service instance with dependency injection
  late final IDestinationService _destinationService;
  bool _isServiceInitialized = false;

  List<Destination> _destinations = [];
  List<Destination> _popularDestinations = [];
  List<Destination> _nearbyDestinations = [];
  List<Destination> _bookmarkedDestinations = [];
  Destination? _selectedDestination;
  bool _isLoading = false;
  String? _error;
  String _selectedCategory = '';
  String _selectedProvince = '';

  // Helper method to safely get destination service
  IDestinationService get destinationService {
    if (!_isServiceInitialized) {
      _destinationService = ServiceLocator.destinationService;
      _isServiceInitialized = true;
    }
    return _destinationService;
  }

  // Getters
  List<Destination> get destinations => _destinations;
  List<Destination> get popularDestinations => _popularDestinations;
  List<Destination> get nearbyDestinations => _nearbyDestinations;
  List<Destination> get bookmarkedDestinations => _bookmarkedDestinations;
  Destination? get selectedDestination => _selectedDestination;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get selectedCategory => _selectedCategory;
  String get selectedProvince => _selectedProvince;

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

  /// Load all destinations with filters
  Future<void> loadDestinations({
    String? category,
    String? province,
    String? city,
    double? minRating,
    double? maxDistance,
    double? userLat,
    double? userLng,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      AppLogger.debug(_tag, 'Loading destinations');
      _setLoading(true);
      _setError(null);

      final destinationsData = await destinationService.searchDestinations(
        category: category,
        location: province,
        latitude: userLat,
        longitude: userLng,
        radiusKm: maxDistance,
        minRating: minRating,
        limit: limit,
        offset: offset,
      );

      _destinations = destinationsData.map((data) => Destination.fromMap(data)).toList();
      _selectedCategory = category ?? '';
      _selectedProvince = province ?? '';

      AppLogger.success(_tag, 'Loaded ${_destinations.length} destinations');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to load destinations', e, stackTrace);
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Load popular destinations
  Future<void> loadPopularDestinations({int limit = 10}) async {
    try {
      AppLogger.debug(_tag, 'Loading popular destinations');
      _setError(null);

      final destinationsData = await destinationService.getTrendingDestinations(
        limit: limit,
      );

      _popularDestinations = destinationsData.map((data) => Destination.fromMap(data)).toList();
      notifyListeners();

      AppLogger.success(_tag, 'Loaded ${_popularDestinations.length} popular destinations');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to load popular destinations', e, stackTrace);
      _setError(e.toString());
    }
  }

  /// Load nearby destinations
  Future<void> loadNearbyDestinations({
    required double latitude,
    required double longitude,
    double radiusKm = 50.0,
    int limit = 20,
  }) async {
    try {
      AppLogger.debug(_tag, 'Loading nearby destinations');
      _setError(null);

      // Use getNearbyDestinations method from interface
      final destinationsData = await destinationService.getNearbyDestinations(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
        limit: limit,
      );

      _nearbyDestinations = destinationsData.map((data) => Destination.fromMap(data)).toList();
      notifyListeners();

      AppLogger.success(_tag, 'Loaded ${_nearbyDestinations.length} nearby destinations');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to load nearby destinations', e, stackTrace);
      _setError(e.toString());
    }
  }

  /// Load user bookmarked destinations
  Future<void> loadBookmarkedDestinations() async {
    try {
      AppLogger.debug(_tag, 'Loading bookmarked destinations');
      _setError(null);

      // Use getUserBookmarks method from interface
      final bookmarksData = await destinationService.getUserBookmarks();
      _bookmarkedDestinations = bookmarksData.map((data) => Destination.fromMap(data)).toList();
      notifyListeners();

      AppLogger.success(_tag, 'Loaded ${_bookmarkedDestinations.length} bookmarked destinations');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to load bookmarked destinations', e, stackTrace);
      _setError(e.toString());
    }
  }

  /// Get single destination by ID
  Future<void> loadDestination(String destinationId) async {
    try {
      AppLogger.debug(_tag, 'Loading destination: $destinationId');
      _setLoading(true);
      _setError(null);

      final destinationData = await destinationService.getDestination(destinationId);
      
      if (destinationData != null) {
        _selectedDestination = Destination.fromMap(destinationData);
        AppLogger.success(_tag, 'Destination loaded successfully');
      } else {
        _setError('Destination not found');
      }
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to load destination', e, stackTrace);
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Search destinations
  Future<void> searchDestinations(String query) async {
    if (query.isEmpty) {
      _destinations = [];
      notifyListeners();
      return;
    }

    try {
      AppLogger.debug(_tag, 'Searching destinations: $query');
      _setLoading(true);
      _setError(null);

      // Use searchDestinations method from interface
      final destinationsData = await destinationService.searchDestinations(
        query: query,
        limit: 50,
      );
      
      _destinations = destinationsData.map((data) => Destination.fromMap(data)).toList();

      AppLogger.success(_tag, 'Found ${_destinations.length} destinations for query: $query');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to search destinations', e, stackTrace);
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Select a destination
  void selectDestination(Destination destination) {
    _selectedDestination = destination;
    notifyListeners();
  }

  /// Clear selected destination
  void clearSelection() {
    _selectedDestination = null;
    notifyListeners();
  }

  /// Toggle bookmark for destination
  Future<void> toggleBookmark(String destinationId) async {
    try {
      AppLogger.debug(_tag, 'Toggling bookmark for destination: $destinationId');
      
      final isBookmarked = await destinationService.isDestinationBookmarked(destinationId);
      
      if (isBookmarked) {
        // Remove bookmark
        await destinationService.removeBookmark(destinationId);
        _bookmarkedDestinations.removeWhere((dest) => dest.id == destinationId);
      } else {
        // Add bookmark
        await destinationService.bookmarkDestination(destinationId);
        final destination = _destinations.firstWhere(
          (dest) => dest.id == destinationId,
          orElse: () => _popularDestinations.firstWhere((dest) => dest.id == destinationId),
        );
        _bookmarkedDestinations.add(destination);
      }
      
      notifyListeners();
      AppLogger.success(_tag, 'Bookmark toggled successfully');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to toggle bookmark', e, stackTrace);
      _setError(e.toString());
    }
  }

  /// Check if destination is bookmarked
  Future<bool> isBookmarked(String destinationId) async {
    try {
      return await destinationService.isDestinationBookmarked(destinationId);
    } catch (e) {
      // Fallback to checking local list
      return _bookmarkedDestinations.any((dest) => dest.id == destinationId);
    }
  }

  /// Clear all data
  void clearAll() {
    _destinations = [];
    _popularDestinations = [];
    _nearbyDestinations = [];
    _selectedDestination = null;
    _error = null;
    _selectedCategory = '';
    _selectedProvince = '';
    notifyListeners();
  }

  /// Refresh all data
  Future<void> refresh() async {
    await Future.wait([
      loadDestinations(),
      loadPopularDestinations(),
      loadBookmarkedDestinations(),
    ]);
  }
}
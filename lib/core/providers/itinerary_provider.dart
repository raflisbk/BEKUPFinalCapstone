import 'package:flutter/foundation.dart';
import '../models/itinerary_model.dart';
import '../models/destination_model.dart';
import '../models/trip_model.dart';
import '../../services/itinerary_service.dart';
import '../../services/trip_service.dart';

/// Provider for managing travel itineraries and trip planning
class ItineraryProvider with ChangeNotifier {
  final ItineraryService _itineraryService = ItineraryService.instance;
  final TripService _tripService = TripService.instance;

  List<Itinerary> _itineraries = [];
  Itinerary? _selectedItinerary;
  List<ItineraryItem> _itineraryItems = [];
  
  bool _isLoading = false;
  String? _error;

  // Trip planning state
  Trip? _currentTrip;
  List<Destination> _selectedDestinations = [];
  Map<String, List<ItineraryItem>> _dayPlans = {};
  
  // AI-generated itinerary state
  bool _isGeneratingItinerary = false;
  Map<String, dynamic>? _generatedItinerary;

  // Optimization and suggestions
  List<Map<String, dynamic>> _optimizationSuggestions = [];
  List<Map<String, dynamic>> _routeOptimizations = [];

  // Getters
  List<Itinerary> get itineraries => _itineraries;
  Itinerary? get selectedItinerary => _selectedItinerary;
  List<ItineraryItem> get itineraryItems => _itineraryItems;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Trip? get currentTrip => _currentTrip;
  List<Destination> get selectedDestinations => _selectedDestinations;
  Map<String, List<ItineraryItem>> get dayPlans => _dayPlans;
  bool get isGeneratingItinerary => _isGeneratingItinerary;
  Map<String, dynamic>? get generatedItinerary => _generatedItinerary;
  List<Map<String, dynamic>> get optimizationSuggestions => _optimizationSuggestions;
  List<Map<String, dynamic>> get routeOptimizations => _routeOptimizations;

  /// Load user's itineraries
  Future<void> loadItineraries() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final itinerariesData = await _itineraryService.getUserItineraries();
      _itineraries = itinerariesData.map((data) => Itinerary.fromMap(data)).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load specific itinerary details
  Future<void> loadItinerary(String itineraryId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final itineraryData = await _itineraryService.getItinerary(itineraryId);
      _selectedItinerary = Itinerary.fromMap(itineraryData);
      
      // Load itinerary items
      final itemsData = await _itineraryService.getItineraryItems(itineraryId);
      _itineraryItems = itemsData.map((data) => ItineraryItem.fromMap(data)).toList();
      
      // Organize items by day
      _organizeDayPlans();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create a new itinerary
  Future<Itinerary?> createItinerary({
    required String name,
    String? description,
    required DateTime startDate,
    required DateTime endDate,
    String? tripId,
  }) async {
    try {
      final itineraryData = await _itineraryService.createItinerary(
        name: name,
        description: description,
        startDate: startDate,
        endDate: endDate,
        tripId: tripId,
      );

      final newItinerary = Itinerary.fromMap(itineraryData);
      _itineraries.insert(0, newItinerary);
      notifyListeners();

      return newItinerary;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Update itinerary details
  Future<void> updateItinerary({
    required String itineraryId,
    String? name,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final updatedData = await _itineraryService.updateItinerary(
        itineraryId: itineraryId,
        name: name,
        description: description,
        startDate: startDate,
        endDate: endDate,
      );

      final itineraryIndex = _itineraries.indexWhere((i) => i.id == itineraryId);
      if (itineraryIndex != -1) {
        _itineraries[itineraryIndex] = Itinerary.fromMap(updatedData);
        
        if (_selectedItinerary?.id == itineraryId) {
          _selectedItinerary = _itineraries[itineraryIndex];
        }
        
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Delete itinerary
  Future<void> deleteItinerary(String itineraryId) async {
    try {
      await _itineraryService.deleteItinerary(itineraryId);
      
      _itineraries.removeWhere((i) => i.id == itineraryId);
      
      if (_selectedItinerary?.id == itineraryId) {
        _selectedItinerary = null;
        _itineraryItems.clear();
        _dayPlans.clear();
      }
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Add item to itinerary
  Future<ItineraryItem?> addItineraryItem({
    required String itineraryId,
    required String title,
    String? description,
    required DateTime startTime,
    DateTime? endTime,
    String? location,
    String? type,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final itemData = await _itineraryService.addItineraryItem(
        itineraryId: itineraryId,
        title: title,
        description: description,
        startTime: startTime,
        endTime: endTime,
        location: location,
        type: type,
        metadata: metadata,
      );

      final newItem = ItineraryItem.fromMap(itemData);
      _itineraryItems.add(newItem);
      _organizeDayPlans();
      notifyListeners();

      return newItem;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Update itinerary item
  Future<void> updateItineraryItem({
    required String itemId,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    String? location,
    String? type,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final updatedData = await _itineraryService.updateItineraryItem(
        itemId: itemId,
        title: title,
        description: description,
        startTime: startTime,
        endTime: endTime,
        location: location,
        type: type,
        metadata: metadata,
      );

      final itemIndex = _itineraryItems.indexWhere((item) => item.id == itemId);
      if (itemIndex != -1) {
        _itineraryItems[itemIndex] = ItineraryItem.fromMap(updatedData);
        _organizeDayPlans();
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Delete itinerary item
  Future<void> deleteItineraryItem(String itemId) async {
    try {
      await _itineraryService.deleteItineraryItem(itemId);
      
      _itineraryItems.removeWhere((item) => item.id == itemId);
      _organizeDayPlans();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Generate AI-powered itinerary
  Future<void> generateAIItinerary({
    required String destination,
    required int days,
    required List<String> interests,
    String? budget,
    String? travelStyle,
  }) async {
    _isGeneratingItinerary = true;
    _error = null;
    notifyListeners();

    try {
      final generatedData = await _itineraryService.generateAIItinerary(
        destination: destination,
        days: days,
        interests: interests,
        budget: budget,
        travelStyle: travelStyle,
      );

      _generatedItinerary = generatedData;
      _isGeneratingItinerary = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isGeneratingItinerary = false;
      notifyListeners();
    }
  }

  /// Save generated itinerary as new itinerary
  Future<Itinerary?> saveGeneratedItinerary({
    required String name,
    String? description,
  }) async {
    if (_generatedItinerary == null) return null;

    try {
      final itineraryData = await _itineraryService.createItineraryFromGenerated(
        generatedData: _generatedItinerary!,
        name: name,
        description: description,
      );

      final newItinerary = Itinerary.fromMap(itineraryData);
      _itineraries.insert(0, newItinerary);
      _generatedItinerary = null;
      notifyListeners();

      return newItinerary;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Optimize itinerary route
  Future<void> optimizeItineraryRoute(String itineraryId) async {
    try {
      final optimizedData = await _itineraryService.optimizeItineraryRoute(itineraryId);
      _routeOptimizations = List<Map<String, dynamic>>.from(optimizedData['optimizations'] ?? []);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Get itinerary suggestions
  Future<void> getItinerarySuggestions(String itineraryId) async {
    try {
      final suggestionsData = await _itineraryService.getItinerarySuggestions(itineraryId);
      _optimizationSuggestions = List<Map<String, dynamic>>.from(suggestionsData['suggestions'] ?? []);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Share itinerary
  Future<String?> shareItinerary(String itineraryId) async {
    try {
      final shareData = await _itineraryService.shareItinerary(itineraryId);
      return shareData['share_url'] as String?;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Clone itinerary
  Future<Itinerary?> cloneItinerary({
    required String itineraryId,
    required String newName,
    String? newDescription,
  }) async {
    try {
      final clonedData = await _itineraryService.cloneItinerary(
        itineraryId: itineraryId,
        newName: newName,
        newDescription: newDescription,
      );

      final clonedItinerary = Itinerary.fromMap(clonedData);
      _itineraries.insert(0, clonedItinerary);
      notifyListeners();

      return clonedItinerary;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Get itinerary statistics
  Future<Map<String, dynamic>?> getItineraryStats(String itineraryId) async {
    try {
      return await _itineraryService.getItineraryStats(itineraryId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Export itinerary
  Future<String?> exportItinerary({
    required String itineraryId,
    required String format, // 'pdf', 'json', 'csv'
  }) async {
    try {
      final exportData = await _itineraryService.exportItinerary(
        itineraryId: itineraryId,
        format: format,
      );
      return exportData['download_url'] as String?;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Organize itinerary items by day
  void _organizeDayPlans() {
    _dayPlans.clear();
    
    for (final item in _itineraryItems) {
      final dayKey = _formatDateKey(item.startTime);
      if (!_dayPlans.containsKey(dayKey)) {
        _dayPlans[dayKey] = [];
      }
      _dayPlans[dayKey]!.add(item);
    }
    
    // Sort items within each day by start time
    for (final dayItems in _dayPlans.values) {
      dayItems.sort((a, b) => a.startTime.compareTo(b.startTime));
    }
  }

  /// Format date for day plan key
  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Get items for specific day
  List<ItineraryItem> getItemsForDay(DateTime date) {
    final dayKey = _formatDateKey(date);
    return _dayPlans[dayKey] ?? [];
  }

  /// Get itinerary duration in days
  int? get itineraryDuration {
    if (_selectedItinerary == null) return null;
    return _selectedItinerary!.endDate.difference(_selectedItinerary!.startDate).inDays + 1;
  }

  /// Get upcoming items for today
  List<ItineraryItem> get upcomingItems {
    final now = DateTime.now();
    return _itineraryItems
        .where((item) => item.startTime.isAfter(now))
        .take(5)
        .toList();
  }

  /// Clear generated itinerary
  void clearGeneratedItinerary() {
    _generatedItinerary = null;
    notifyListeners();
  }

  /// Clear optimizations
  void clearOptimizations() {
    _optimizationSuggestions.clear();
    _routeOptimizations.clear();
    notifyListeners();
  }

  /// Set current trip context
  void setCurrentTrip(Trip? trip) {
    _currentTrip = trip;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Refresh itineraries
  Future<void> refresh() async {
    await loadItineraries();
    if (_selectedItinerary != null) {
      await loadItinerary(_selectedItinerary!.id);
    }
  }
}
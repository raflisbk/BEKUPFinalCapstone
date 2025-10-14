import 'package:flutter/foundation.dart';
import '../models/itinerary_model.dart' as itinerary;
import '../models/destination_model.dart';
import '../models/trip_model.dart' hide ItineraryItem;
import '../../services/itinerary_service.dart';

/// Provider for managing travel itineraries and trip planning
class ItineraryProvider with ChangeNotifier {

  List<itinerary.Itinerary> _itineraries = [];
  itinerary.Itinerary? _selectedItinerary;
  List<itinerary.ItineraryItem> _itineraryItems = [];
  
  bool _isLoading = false;
  String? _error;

  // Trip planning state
  Trip? _currentTrip;
  final List<Destination> _selectedDestinations = [];
  final Map<String, List<itinerary.ItineraryItem>> _dayPlans = {};
  
  // AI-generated itinerary state
  bool _isGeneratingItinerary = false;
  Map<String, dynamic>? _generatedItinerary;

  // Optimization and suggestions
  List<Map<String, dynamic>> _optimizationSuggestions = [];
  List<Map<String, dynamic>> _routeOptimizations = [];

  // Getters
  List<itinerary.Itinerary> get itineraries => _itineraries;
  itinerary.Itinerary? get selectedItinerary => _selectedItinerary;
  List<itinerary.ItineraryItem> get itineraryItems => _itineraryItems;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Trip? get currentTrip => _currentTrip;
  List<Destination> get selectedDestinations => _selectedDestinations;
  Map<String, List<itinerary.ItineraryItem>> get dayPlans => _dayPlans;
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
      // For now, we need a tripId to get itineraries
      // This is a limitation of the current service design
      if (_currentTrip?.id != null) {
        final itinerariesData = await ItineraryService.getTripItineraries(_currentTrip!.id);
        _itineraries = itinerariesData.map((data) => itinerary.Itinerary.fromMap(data)).toList();
      } else {
        // If no current trip, return empty list
        _itineraries = [];
      }
      
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
      final itineraryData = await ItineraryService.getItinerary(itineraryId);
      if (itineraryData != null) {
        _selectedItinerary = itinerary.Itinerary.fromMap(itineraryData);
        
        // Load itinerary items (activities)
        final itemsData = await ItineraryService.getItineraryActivities(itineraryId);
        _itineraryItems = itemsData.map((data) => itinerary.ItineraryItem.fromMap(data)).toList();
        
        // Organize items by day
        _organizeDayPlans();
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create a new itinerary
  Future<itinerary.Itinerary?> createItinerary({
    required String name,
    String? description,
    required DateTime startDate,
    required DateTime endDate,
    String? tripId,
  }) async {
    try {
      final itineraryData = await ItineraryService.createItinerary(
        tripId: tripId ?? '',
        title: name,
        description: description,
        date: startDate,
      );

      final newItinerary = itinerary.Itinerary.fromMap(itineraryData);
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
      final updatedData = await ItineraryService.updateItinerary(
        itineraryId: itineraryId,
        title: name,
        description: description,
        date: startDate,
      );

      final itineraryIndex = _itineraries.indexWhere((i) => i.id == itineraryId);
      if (itineraryIndex != -1) {
        _itineraries[itineraryIndex] = itinerary.Itinerary.fromMap(updatedData);
        
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
      await ItineraryService.deleteItinerary(itineraryId);
      
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
  Future<itinerary.ItineraryItem?> addItineraryItem({
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
      final itemData = await ItineraryService.addActivity(
        itineraryId: itineraryId,
        title: title,
        type: type ?? 'other',
        description: description,
        location: location,
        startTime: startTime,
        endTime: endTime,
        details: metadata,
      );

      final newItem = itinerary.ItineraryItem.fromMap(itemData);
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
      final updatedData = await ItineraryService.updateActivity(
        activityId: itemId,
        title: title,
        type: type,
        description: description,
        location: location,
        startTime: startTime,
        endTime: endTime,
        details: metadata,
      );

      final itemIndex = _itineraryItems.indexWhere((item) => item.id == itemId);
      if (itemIndex != -1) {
        _itineraryItems[itemIndex] = itinerary.ItineraryItem.fromMap(updatedData);
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
      await ItineraryService.deleteActivity(itemId);
      
      _itineraryItems.removeWhere((item) => item.id == itemId);
      _organizeDayPlans();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Generate AI-powered itinerary (stub implementation)
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
      // Stub implementation - AI generation not available yet
      await Future.delayed(const Duration(seconds: 2));
      
      _generatedItinerary = {
        'destination': destination,
        'days': days,
        'interests': interests,
        'budget': budget,
        'travelStyle': travelStyle,
        'generated_at': DateTime.now().toIso8601String(),
      };
      
      _isGeneratingItinerary = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isGeneratingItinerary = false;
      notifyListeners();
    }
  }

  /// Save generated itinerary as new itinerary (stub implementation)
  Future<itinerary.Itinerary?> saveGeneratedItinerary({
    required String name,
    String? description,
  }) async {
    if (_generatedItinerary == null) return null;

    try {
      // Stub implementation - create itinerary from generated data
      final itineraryData = await ItineraryService.createItinerary(
        tripId: '',
        title: name,
        description: description ?? 'Itinerary created from AI generation',
      );

      final newItinerary = itinerary.Itinerary.fromMap(itineraryData);
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
      final optimizedData = await ItineraryService.optimizeItineraryByLocation(itineraryId);
      _routeOptimizations = optimizedData.map((item) => item).toList();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Get itinerary suggestions (stub implementation)
  Future<void> getItinerarySuggestions(String itineraryId) async {
    try {
      // Stub implementation - no specific suggestion service available
      _optimizationSuggestions = [
        {'type': 'route', 'message': 'Consider optimizing route for better travel time'},
        {'type': 'cost', 'message': 'Look for cost-saving alternatives'},
      ];
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Share itinerary (stub implementation)
  Future<String?> shareItinerary(String itineraryId) async {
    try {
      // Stub implementation - return mock share URL
      return 'https://relink.app/shared/itinerary/$itineraryId';
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Clone itinerary (stub implementation)
  Future<itinerary.Itinerary?> cloneItinerary({
    required String itineraryId,
    required String newName,
    String? newDescription,
  }) async {
    try {
      // Stub implementation - create new itinerary with similar data
      final itineraryData = await ItineraryService.createItinerary(
        tripId: '',
        title: newName,
        description: newDescription ?? 'Cloned itinerary',
      );

      final clonedItinerary = itinerary.Itinerary.fromMap(itineraryData);
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
      return await ItineraryService.getItineraryStatistics(itineraryId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Export itinerary (stub implementation)
  Future<String?> exportItinerary({
    required String itineraryId,
    required String format, // 'pdf', 'json', 'csv'
  }) async {
    try {
      // Stub implementation - return mock download URL
      return 'https://relink.app/export/itinerary/$itineraryId.$format';
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
  List<itinerary.ItineraryItem> getItemsForDay(DateTime date) {
    final dayKey = _formatDateKey(date);
    return _dayPlans[dayKey] ?? [];
  }

  /// Get itinerary duration in days
  int? get itineraryDuration {
    if (_selectedItinerary == null) return null;
    return _selectedItinerary!.endDate.difference(_selectedItinerary!.startDate).inDays + 1;
  }

  /// Get upcoming items for today
  List<itinerary.ItineraryItem> get upcomingItems {
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
import 'package:flutter/foundation.dart';
import '../models/destination_model.dart';
import '../models/indonesia_tourism_models.dart';
import '../../services/indonesia_tourism_service.dart';

/// Provider for Indonesia Tourism data
class IndonesiaTourismProvider with ChangeNotifier {
  final IndonesiaTourismService _tourismService = IndonesiaTourismService.instance;
  
  List<Destination> _destinations = [];
  List<Destination> _trendingDestinations = [];
  bool _isLoading = false;
  String? _error;

  IndonesianProvince? _selectedProvince;
  TourismCategory? _selectedCategory;

  // Getters
  List<Destination> get destinations => _destinations;
  List<Destination> get trendingDestinations => _trendingDestinations;
  bool get isLoading => _isLoading;
  String? get error => _error;
  IndonesianProvince? get selectedProvince => _selectedProvince;
  TourismCategory? get selectedCategory => _selectedCategory;

  /// Load trending Indonesian destinations
  Future<void> loadTrendingDestinations() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Get featured destinations from the service
      final destinationsData = await _tourismService.getFeaturedDestinations(limit: 10);
      
      // Convert Map<String, dynamic> to Destination objects
      _trendingDestinations = destinationsData.map((data) => Destination.fromMap(data)).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Search destinations by province
  Future<void> searchByProvince(IndonesianProvince province) async {
    _selectedProvince = province;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Use static method and convert province to ID
      final destinationsData = await _tourismService.getPopularDestinationsByProvince(
        province.id,
        limit: 20,
      );
      
      // Convert Map<String, dynamic> to Destination objects
      _destinations = destinationsData.map((data) => Destination.fromMap(data)).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Search destinations by category
  Future<void> searchByCategory(TourismCategory category) async {
    _selectedCategory = category;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Use static method and convert category to ID, pass province ID if selected
      final destinationsData = await _tourismService.getDestinationsByTourismCategory(
        category.id,
        provinceId: _selectedProvince?.id,
        limit: 20,
      );
      
      // Convert Map<String, dynamic> to Destination objects
      _destinations = destinationsData.map((data) => Destination.fromMap(data)).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Search destinations by keyword
  Future<void> searchByKeyword(String keyword) async {
    if (keyword.isEmpty) {
      _destinations = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Use travel recommendations with current filters since there's no direct keyword search
      final destinationsData = await _tourismService.getTravelRecommendations(
        preferredProvinces: _selectedProvince != null ? [_selectedProvince!.id] : null,
        preferredCategories: _selectedCategory != null ? [_selectedCategory!.id] : null,
        limit: 20,
      );
      
      // Filter results by keyword in name or description
      final filteredData = destinationsData.where((dest) {
        final name = dest['name']?.toString().toLowerCase() ?? '';
        final description = dest['description']?.toString().toLowerCase() ?? '';
        final searchKeyword = keyword.toLowerCase();
        return name.contains(searchKeyword) || description.contains(searchKeyword);
      }).toList();
      
      // Convert Map<String, dynamic> to Destination objects
      _destinations = filteredData.map((data) => Destination.fromMap(data)).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear filters
  void clearFilters() {
    _selectedProvince = null;
    _selectedCategory = null;
    _destinations = [];
    notifyListeners();
  }

  /// Reload destinations with current filters
  Future<void> reload() async {
    if (_selectedProvince != null) {
      await searchByProvince(_selectedProvince!);
    } else if (_selectedCategory != null) {
      await searchByCategory(_selectedCategory!);
    } else {
      await loadTrendingDestinations();
    }
  }
}

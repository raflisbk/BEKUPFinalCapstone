import 'package:flutter/foundation.dart';
import '../models/destination_model.dart';
import '../../services/indonesia_tourism_service.dart';

/// Provider for Indonesia Tourism data
class IndonesiaTourismProvider with ChangeNotifier {
  final IndonesiaTourismService _tourismService = IndonesiaTourismService();

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
      _trendingDestinations = await _tourismService.getTrendingDestinations(limit: 10);
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
      _destinations = await _tourismService.getPopularDestinationsByProvince(
        province,
        limit: 20,
      );
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
      _destinations = await _tourismService.getDestinationsByCategory(
        category,
        province: _selectedProvince,
        limit: 20,
      );
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
      _destinations = await _tourismService.searchByKeyword(
        keyword,
        province: _selectedProvince,
        limit: 20,
      );
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

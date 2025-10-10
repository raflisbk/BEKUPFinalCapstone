import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/destination_model.dart';

/// Provider untuk mengelola state UI di Add/Edit Destination Screen
/// Menghindari penggunaan setState
class AddEditDestinationUIProvider extends ChangeNotifier {
  String _selectedCategory = DestinationCategory.other.name;
  double _priceRange = 3.0;
  List<String> _facilities = [];
  List<String> _activities = [];
  List<File> _imageFiles = [];
  List<String> _existingImageUrls = [];
  bool _isLoading = false;

  String get selectedCategory => _selectedCategory;
  double get priceRange => _priceRange;
  List<String> get facilities => _facilities;
  List<String> get activities => _activities;
  List<File> get imageFiles => _imageFiles;
  List<String> get existingImageUrls => _existingImageUrls;
  bool get isLoading => _isLoading;

  /// Set selected category
  void setCategory(String category) {
    if (_selectedCategory != category) {
      _selectedCategory = category;
      notifyListeners();
    }
  }

  /// Set price range
  void setPriceRange(double range) {
    if (_priceRange != range) {
      _priceRange = range;
      notifyListeners();
    }
  }

  /// Set image files
  void setImageFiles(List<File> files) {
    _imageFiles = files;
    notifyListeners();
  }

  /// Add facility
  void addFacility(String facility) {
    _facilities.add(facility);
    notifyListeners();
  }

  /// Remove facility
  void removeFacility(int index) {
    _facilities.removeAt(index);
    notifyListeners();
  }

  /// Add activity
  void addActivity(String activity) {
    _activities.add(activity);
    notifyListeners();
  }

  /// Remove activity
  void removeActivity(int index) {
    _activities.removeAt(index);
    notifyListeners();
  }

  /// Set loading state
  void setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  /// Load destination data for editing
  void loadDestination(Destination destination) {
    _selectedCategory = destination.category;
    _priceRange = destination.priceRange;
    _facilities = List.from(destination.facilities);
    _activities = List.from(destination.activities);
    _existingImageUrls = List.from(destination.images);
    notifyListeners();
  }

  /// Reset to initial state
  void reset() {
    _selectedCategory = DestinationCategory.other.name;
    _priceRange = 3.0;
    _facilities = [];
    _activities = [];
    _imageFiles = [];
    _existingImageUrls = [];
    _isLoading = false;
    notifyListeners();
  }
}

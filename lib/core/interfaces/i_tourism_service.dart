/// Interface for Indonesia Tourism Service
/// Defines contracts for Indonesia-specific tourism data including provinces, cities, and destinations
abstract class ITourismService {
  // ===============================
  // PROVINCE DATA
  // ===============================

  /// Get all provinces in Indonesia
  Future<List<Map<String, dynamic>>> getProvinces();

  /// Get province by ID
  Future<Map<String, dynamic>?> getProvince(String provinceId);

  /// Get popular cities in a province
  Future<List<String>> getCitiesByProvince(String provinceId);

  /// Search provinces by query
  Future<List<Map<String, dynamic>>> searchProvinces(String query);

  // ===============================
  // TOURISM CATEGORIES
  // ===============================

  /// Get all tourism categories
  Future<List<Map<String, dynamic>>> getTourismCategories();

  /// Get category by ID
  Future<Map<String, dynamic>?> getTourismCategory(String categoryId);

  // ===============================
  // DESTINATION RECOMMENDATIONS
  // ===============================

  /// Get popular destinations by province
  Future<List<Map<String, dynamic>>> getPopularDestinationsByProvince(
    String provinceId, {
    int limit = 10,
  });

  /// Get featured destinations
  Future<List<Map<String, dynamic>>> getFeaturedDestinations({
    String? category,
    String? province,
    int limit = 20,
  });

  /// Get destinations by tourism category
  Future<List<Map<String, dynamic>>> getDestinationsByTourismCategory(
    String categoryId, {
    String? province,
    int limit = 20,
  });

  /// Get travel recommendations based on preferences
  Future<List<Map<String, dynamic>>> getTravelRecommendations({
    required List<String> interests,
    String? budget,
    int? days,
    String? startLocation,
    int limit = 10,
  });

  // ===============================
  // STATISTICS & HELPERS
  // ===============================

  /// Get tourism statistics
  Future<Map<String, dynamic>> getTourismStatistics();

  /// Validate if a city belongs to a province
  Future<bool> validateProvinceCity(String provinceId, String cityName);

  /// Get province by city name
  Future<Map<String, dynamic>?> getProvinceByCity(String cityName);
}

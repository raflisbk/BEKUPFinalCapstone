/// Interface for Weather Service
/// Handles weather data integration using OpenWeatherMap API
abstract class IWeatherService {
  // ===============================
  // CURRENT WEATHER
  // ===============================

  /// Get current weather by coordinates
  Future<Map<String, dynamic>?> getCurrentWeatherByCoordinates({
    required double latitude,
    required double longitude,
    String units = 'metric',
    String language = 'id',
  });

  /// Get current weather by city name
  Future<Map<String, dynamic>?> getCurrentWeatherByCity({
    required String cityName,
    String? stateCode,
    String? countryCode,
    String units = 'metric',
    String language = 'id',
  });

  // ===============================
  // WEATHER FORECAST
  // ===============================

  /// Get weather forecast by coordinates (5 days / 3 hours)
  Future<Map<String, dynamic>?> getWeatherForecastByCoordinates({
    required double latitude,
    required double longitude,
    String units = 'metric',
    String language = 'id',
  });

  /// Get weather forecast by city name (5 days / 3 hours)
  Future<Map<String, dynamic>?> getWeatherForecastByCity({
    required String cityName,
    String? stateCode,
    String? countryCode,
    String units = 'metric',
    String language = 'id',
  });

  // ===============================
  // DESTINATION WEATHER
  // ===============================

  /// Get weather for a specific destination
  Future<Map<String, dynamic>?> getDestinationWeather({
    required String destinationId,
    bool includeForecast = false,
    String units = 'metric',
    String language = 'id',
  });

  /// Get weather for multiple destinations
  Future<List<Map<String, dynamic>>> getMultipleDestinationsWeather({
    required List<String> destinationIds,
    bool includeForecast = false,
    String units = 'metric',
    String language = 'id',
  });

  // ===============================
  // WEATHER UTILITIES
  // ===============================

  /// Check if weather conditions are good for travel
  static bool isGoodTravelWeather(Map<String, dynamic> weather) {
    throw UnimplementedError('Static method should be implemented in concrete class');
  }

  /// Get weather recommendation message
  static String getWeatherRecommendation(Map<String, dynamic> weather) {
    throw UnimplementedError('Static method should be implemented in concrete class');
  }

  /// Get weather icon URL from icon code
  static String getWeatherIconUrl(String iconCode) {
    throw UnimplementedError('Static method should be implemented in concrete class');
  }

  /// Check if weather service is available (API keys configured)
  static bool get isAvailable {
    throw UnimplementedError('Static getter should be implemented in concrete class');
  }

  /// Get weather service status
  static Map<String, dynamic> getServiceStatus() {
    throw UnimplementedError('Static method should be implemented in concrete class');
  }
}
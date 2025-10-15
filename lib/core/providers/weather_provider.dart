import 'package:flutter/foundation.dart';
import '../utils/logger.dart';
import '../interfaces/i_weather_service.dart';
import '../utils/service_locator.dart';

/// Provider for Weather data
class WeatherProvider with ChangeNotifier {
  static const String _tag = 'WeatherProvider';

  // Service instance with ServiceLocator
  final IWeatherService _weatherService = ServiceLocator.instance.get<IWeatherService>();

  Map<String, dynamic>? _currentWeather;
  List<Map<String, dynamic>> _forecast = [];
  bool _isLoading = false;
  String? _error;

  // Constructor with ServiceLocator
  WeatherProvider();

  // Getters
  Map<String, dynamic>? get currentWeather => _currentWeather;
  List<Map<String, dynamic>> get forecast => _forecast;
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

  /// Get current weather by coordinates
  Future<void> getCurrentWeather({
    required double latitude,
    required double longitude,
    String units = 'metric',
    String language = 'id',
  }) async {
    try {
      AppLogger.debug(_tag, 'Getting current weather for: $latitude, $longitude');
      _setLoading(true);
      _setError(null);

      final weather = await _weatherService.getCurrentWeatherByCoordinates(
        latitude: latitude,
        longitude: longitude,
        units: units,
        language: language,
      );

      _currentWeather = weather;
      AppLogger.success(_tag, 'Weather loaded successfully');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to load weather', e, stackTrace);
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Get current weather by city name
  Future<void> getCurrentWeatherByCity({
    required String cityName,
    String units = 'metric',
    String language = 'id',
  }) async {
    try {
      AppLogger.debug(_tag, 'Getting current weather for city: $cityName');
      _setLoading(true);
      _setError(null);

      // Note: This method needs to be implemented in WeatherService
      // For now, we'll just set error
      _setError('Weather by city name not implemented yet');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to load weather for city', e, stackTrace);
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Clear weather data
  void clearWeather() {
    _currentWeather = null;
    _forecast = [];
    _error = null;
    notifyListeners();
  }

  /// Get weather condition icon
  String? getWeatherIcon() {
    if (_currentWeather == null) return null;
    return _currentWeather!['icon'] as String?;
  }

  /// Get temperature string
  String getTemperatureString() {
    if (_currentWeather == null) return '--°';
    final temp = _currentWeather!['temperature'] as double?;
    return temp != null ? '${temp.round()}°' : '--°';
  }

  /// Get weather description
  String getWeatherDescription() {
    if (_currentWeather == null) return 'No data';
    return _currentWeather!['description'] as String? ?? 'No data';
  }

  /// Check if it's raining
  bool get isRaining {
    if (_currentWeather == null) return false;
    final condition = _currentWeather!['condition'] as String?;
    return condition != null && condition.toLowerCase().contains('rain');
  }

  /// Get humidity percentage
  int? get humidity {
    if (_currentWeather == null) return null;
    return _currentWeather!['humidity'] as int?;
  }

  /// Get wind speed
  double? get windSpeed {
    if (_currentWeather == null) return null;
    return _currentWeather!['windSpeed'] as double?;
  }
}
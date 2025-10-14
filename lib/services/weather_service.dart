import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config/env_config.dart';
import '../core/utils/logger.dart';

/// Weather Service
/// Handles weather data integration using OpenWeatherMap API
class WeatherService {
  static const String _tag = 'WeatherService';
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';
  static const String _iconBaseUrl = 'https://openweathermap.org/img/wn';

  // Singleton pattern
  static WeatherService? _instance;
  static WeatherService get instance => _instance ??= WeatherService._internal();
  
  WeatherService._internal();

  // ===============================
  // CURRENT WEATHER
  // ===============================

  /// Get current weather by coordinates
  Future<Map<String, dynamic>?> getCurrentWeatherByCoordinates({
    required double latitude,
    required double longitude,
    String units = 'metric', // metric, imperial, kelvin
    String language = 'id', // Indonesian language
  }) async {
    try {
      if (!EnvConfig.hasOpenWeatherConfig) {
        AppLogger.warning(_tag, 'OpenWeather API key not configured');
        return null;
      }

      AppLogger.debug(_tag, 'Getting current weather for coordinates: $latitude, $longitude');

      final url = Uri.parse(
        '$_baseUrl/weather?lat=$latitude&lon=$longitude&appid=${EnvConfig.openWeatherApiKey}&units=$units&lang=$language'
      );

      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final weather = _parseWeatherData(data);
        
        AppLogger.success(_tag, 'Retrieved current weather for ${weather['location']}');
        return weather;
      } else {
        AppLogger.error(_tag, 'Weather API request failed with status: ${response.statusCode}');
        return null;
      }
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get current weather', e, stackTrace);
      return null;
    }
  }

  /// Get current weather by city name
  Future<Map<String, dynamic>?> getCurrentWeatherByCity({
    required String cityName,
    String? countryCode,
    String units = 'metric',
    String language = 'id',
  }) async {
    try {
      if (!EnvConfig.hasOpenWeatherConfig) {
        AppLogger.warning(_tag, 'OpenWeather API key not configured');
        return null;
      }

      AppLogger.debug(_tag, 'Getting current weather for city: $cityName');

      final query = countryCode != null ? '$cityName,$countryCode' : cityName;
      final url = Uri.parse(
        '$_baseUrl/weather?q=$query&appid=${EnvConfig.openWeatherApiKey}&units=$units&lang=$language'
      );

      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final weather = _parseWeatherData(data);
        
        AppLogger.success(_tag, 'Retrieved current weather for $cityName');
        return weather;
      } else {
        AppLogger.error(_tag, 'Weather API request failed with status: ${response.statusCode}');
        return null;
      }
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get current weather by city', e, stackTrace);
      return null;
    }
  }

  // ===============================
  // WEATHER FORECAST
  // ===============================

  /// Get 5-day weather forecast by coordinates
  Future<Map<String, dynamic>?> getWeatherForecastByCoordinates({
    required double latitude,
    required double longitude,
    String units = 'metric',
    String language = 'id',
  }) async {
    try {
      if (!EnvConfig.hasOpenWeatherConfig) {
        AppLogger.warning(_tag, 'OpenWeather API key not configured');
        return null;
      }

      AppLogger.debug(_tag, 'Getting weather forecast for coordinates: $latitude, $longitude');

      final url = Uri.parse(
        '$_baseUrl/forecast?lat=$latitude&lon=$longitude&appid=${EnvConfig.openWeatherApiKey}&units=$units&lang=$language'
      );

      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final forecast = _parseForecastData(data);
        
        AppLogger.success(_tag, 'Retrieved weather forecast');
        return forecast;
      } else {
        AppLogger.error(_tag, 'Forecast API request failed with status: ${response.statusCode}');
        return null;
      }
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get weather forecast', e, stackTrace);
      return null;
    }
  }

  /// Get 5-day weather forecast by city name
  Future<Map<String, dynamic>?> getWeatherForecastByCity({
    required String cityName,
    String? countryCode,
    String units = 'metric',
    String language = 'id',
  }) async {
    try {
      if (!EnvConfig.hasOpenWeatherConfig) {
        AppLogger.warning(_tag, 'OpenWeather API key not configured');
        return null;
      }

      AppLogger.debug(_tag, 'Getting weather forecast for city: $cityName');

      final query = countryCode != null ? '$cityName,$countryCode' : cityName;
      final url = Uri.parse(
        '$_baseUrl/forecast?q=$query&appid=${EnvConfig.openWeatherApiKey}&units=$units&lang=$language'
      );

      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final forecast = _parseForecastData(data);
        
        AppLogger.success(_tag, 'Retrieved weather forecast for $cityName');
        return forecast;
      } else {
        AppLogger.error(_tag, 'Forecast API request failed with status: ${response.statusCode}');
        return null;
      }
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get weather forecast by city', e, stackTrace);
      return null;
    }
  }

  // ===============================
  // WEATHER FOR DESTINATIONS
  // ===============================

  /// Get weather for a destination
  Future<Map<String, dynamic>?> getDestinationWeather({
    required Map<String, dynamic> destination,
    bool includeForecast = false,
  }) async {
    try {
      AppLogger.debug(_tag, 'Getting weather for destination: ${destination['name']}');

      final latitude = destination['latitude'] as double?;
      final longitude = destination['longitude'] as double?;

      if (latitude == null || longitude == null) {
        AppLogger.warning(_tag, 'Destination coordinates not available');
        return null;
      }

      final currentWeather = await getCurrentWeatherByCoordinates(
        latitude: latitude,
        longitude: longitude,
      );

      if (currentWeather == null) {
        return null;
      }

      final result = {
        'destination_id': destination['id'],
        'destination_name': destination['name'],
        'current_weather': currentWeather,
      };

      if (includeForecast) {
        final forecast = await getWeatherForecastByCoordinates(
          latitude: latitude,
          longitude: longitude,
        );
        result['forecast'] = forecast;
      }

      AppLogger.success(_tag, 'Retrieved weather data for destination');
      return result;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get destination weather', e, stackTrace);
      return null;
    }
  }

  /// Get weather for multiple destinations
  Future<List<Map<String, dynamic>>> getMultipleDestinationsWeather({
    required List<Map<String, dynamic>> destinations,
    bool includeForecast = false,
  }) async {
    try {
      AppLogger.debug(_tag, 'Getting weather for ${destinations.length} destinations');

      final weatherData = <Map<String, dynamic>>[];

      for (final destination in destinations) {
        try {
          final weather = await getDestinationWeather(
            destination: destination,
            includeForecast: includeForecast,
          );

          if (weather != null) {
            weatherData.add(weather);
          }

          // Add small delay to avoid rate limiting
          await Future.delayed(const Duration(milliseconds: 100));
        } catch (e) {
          AppLogger.warning(_tag, 'Failed to get weather for ${destination['name']}', e);
          continue;
        }
      }

      AppLogger.success(_tag, 'Retrieved weather data for ${weatherData.length} destinations');
      return weatherData;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get multiple destinations weather', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // WEATHER ALERTS & CONDITIONS
  // ===============================

  /// Check if weather is good for travel
  static bool isGoodTravelWeather(Map<String, dynamic> weather) {
    try {
      final condition = weather['condition'] as String? ?? '';
      final temperature = weather['temperature'] as double? ?? 0.0;
      final humidity = weather['humidity'] as int? ?? 0;
      final windSpeed = weather['wind_speed'] as double? ?? 0.0;

      // Define good travel conditions
      final badConditions = [
        'thunderstorm',
        'heavy rain',
        'snow',
        'mist',
        'fog',
        'dust',
        'sand',
        'squall',
        'tornado'
      ];

      // Check if condition is bad
      if (badConditions.any((bad) => condition.toLowerCase().contains(bad))) {
        return false;
      }

      // Check temperature range (comfortable for travel: 15-35°C)
      if (temperature < 15 || temperature > 35) {
        return false;
      }

      // Check high humidity (above 85%)
      if (humidity > 85) {
        return false;
      }

      // Check strong wind (above 10 m/s)
      if (windSpeed > 10) {
        return false;
      }

      return true;
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to evaluate travel weather', e);
      return false;
    }
  }

  /// Get weather recommendation message
  static String getWeatherRecommendation(Map<String, dynamic> weather) {
    try {
      if (isGoodTravelWeather(weather)) {
        return 'Cuaca bagus untuk berwisata! ☀️';
      }

      final condition = weather['condition'] as String? ?? '';
      final temperature = weather['temperature'] as double? ?? 0.0;

      if (condition.toLowerCase().contains('rain')) {
        return 'Berawan/hujan. Bawa payung atau jas hujan! 🌧️';
      } else if (temperature > 35) {
        return 'Cuaca sangat panas. Gunakan tabir surya dan minum banyak air! 🌡️';
      } else if (temperature < 15) {
        return 'Cuaca dingin. Bawa jaket atau pakaian hangat! 🧥';
      } else if (condition.toLowerCase().contains('cloud')) {
        return 'Cuaca berawan. Cocok untuk aktivitas outdoor! ⛅';
      } else {
        return 'Periksa kondisi cuaca sebelum berangkat! 🌤️';
      }
    } catch (e) {
      return 'Informasi cuaca tidak tersedia';
    }
  }

  // ===============================
  // UTILITY METHODS
  // ===============================

  /// Get weather icon URL
  static String getWeatherIconUrl(String iconCode) {
    return '$_iconBaseUrl/$iconCode@2x.png';
  }

  /// Parse weather data from API response
  static Map<String, dynamic> _parseWeatherData(Map<String, dynamic> data) {
    try {
      final main = data['main'] as Map<String, dynamic>;
      final weather = (data['weather'] as List).first as Map<String, dynamic>;
      final wind = data['wind'] as Map<String, dynamic>? ?? {};
      final clouds = data['clouds'] as Map<String, dynamic>? ?? {};
      final sys = data['sys'] as Map<String, dynamic>? ?? {};

      return {
        'location': data['name'] ?? 'Unknown',
        'country': sys['country'] ?? '',
        'temperature': (main['temp'] as num).toDouble(),
        'feels_like': (main['feels_like'] as num).toDouble(),
        'temp_min': (main['temp_min'] as num).toDouble(),
        'temp_max': (main['temp_max'] as num).toDouble(),
        'pressure': main['pressure'] as int,
        'humidity': main['humidity'] as int,
        'condition': weather['main'] as String,
        'description': weather['description'] as String,
        'icon': weather['icon'] as String,
        'icon_url': getWeatherIconUrl(weather['icon'] as String),
        'wind_speed': (wind['speed'] as num?)?.toDouble() ?? 0.0,
        'wind_direction': wind['deg'] as int? ?? 0,
        'cloudiness': clouds['all'] as int? ?? 0,
        'visibility': (data['visibility'] as num?)?.toDouble() ?? 10000.0,
        'sunrise': sys['sunrise'] != null 
            ? DateTime.fromMillisecondsSinceEpoch((sys['sunrise'] as int) * 1000)
            : null,
        'sunset': sys['sunset'] != null
            ? DateTime.fromMillisecondsSinceEpoch((sys['sunset'] as int) * 1000)
            : null,
        'timestamp': DateTime.now(),
        'coordinates': {
          'latitude': (data['coord']['lat'] as num).toDouble(),
          'longitude': (data['coord']['lon'] as num).toDouble(),
        },
      };
    } catch (e) {
      AppLogger.error(_tag, 'Failed to parse weather data', e);
      rethrow;
    }
  }

  /// Parse forecast data from API response
  static Map<String, dynamic> _parseForecastData(Map<String, dynamic> data) {
    try {
      final city = data['city'] as Map<String, dynamic>;
      final list = data['list'] as List;

      final forecasts = list.map((item) {
        final main = item['main'] as Map<String, dynamic>;
        final weather = (item['weather'] as List).first as Map<String, dynamic>;
        final wind = item['wind'] as Map<String, dynamic>? ?? {};
        final clouds = item['clouds'] as Map<String, dynamic>? ?? {};

        return {
          'datetime': DateTime.fromMillisecondsSinceEpoch((item['dt'] as int) * 1000),
          'temperature': (main['temp'] as num).toDouble(),
          'feels_like': (main['feels_like'] as num).toDouble(),
          'temp_min': (main['temp_min'] as num).toDouble(),
          'temp_max': (main['temp_max'] as num).toDouble(),
          'pressure': main['pressure'] as int,
          'humidity': main['humidity'] as int,
          'condition': weather['main'] as String,
          'description': weather['description'] as String,
          'icon': weather['icon'] as String,
          'icon_url': getWeatherIconUrl(weather['icon'] as String),
          'wind_speed': (wind['speed'] as num?)?.toDouble() ?? 0.0,
          'wind_direction': wind['deg'] as int? ?? 0,
          'cloudiness': clouds['all'] as int? ?? 0,
          'pop': (item['pop'] as num?)?.toDouble() ?? 0.0, // Probability of precipitation
        };
      }).toList();

      return {
        'location': city['name'] ?? 'Unknown',
        'country': city['country'] ?? '',
        'coordinates': {
          'latitude': (city['coord']['lat'] as num).toDouble(),
          'longitude': (city['coord']['lon'] as num).toDouble(),
        },
        'forecasts': forecasts,
        'count': forecasts.length,
        'timestamp': DateTime.now(),
      };
    } catch (e) {
      AppLogger.error(_tag, 'Failed to parse forecast data', e);
      rethrow;
    }
  }

  /// Check if weather service is available
  static bool get isAvailable => EnvConfig.hasOpenWeatherConfig;

  /// Get service status
  static Map<String, dynamic> getServiceStatus() {
    return {
      'available': isAvailable,
      'api_configured': EnvConfig.hasOpenWeatherConfig,
      'base_url': _baseUrl,
      'last_checked': DateTime.now().toIso8601String(),
    };
  }
}
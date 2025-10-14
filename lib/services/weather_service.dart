import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/models/weather_model.dart';
import '../core/utils/logger.dart';
import '../core/config/env_config.dart';

/// Service for fetching weather information
class WeatherService {
  static const String _tag = 'WeatherService';

  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';

  // Cache for weather data
  final Map<String, WeatherCache> _cache = {};

  /// Get current weather by city name
  Future<WeatherInfo?> getWeatherByCity(String cityName) async {
    try {
      // Check cache first
      final cached = _cache[cityName];
      if (cached != null && cached.isValid) {
        AppLogger.debug(_tag, 'Weather data from cache', {
          'city': cityName,
          'age': '${cached.ageInMinutes}min',
        });
        return cached.weather;
      }

      AppLogger.debug(_tag, 'Fetching weather data', {
        'city': cityName,
      });

      final url = Uri.parse(
        '$_baseUrl/weather?q=$cityName&appid=${EnvConfig.openWeatherApiKey}&units=metric',
      );

      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final weather = WeatherInfo.fromJson(data);

        // Cache the result
        _cache[cityName] = WeatherCache(
          weather: weather,
          cachedAt: DateTime.now(),
        );

        AppLogger.info(_tag, 'Weather data fetched successfully', {
          'city': cityName,
          'temp': weather.temperature,
          'condition': weather.condition,
        });

        return weather;
      } else if (response.statusCode == 404) {
        AppLogger.warning(_tag, 'City not found', {'city': cityName});
        return null;
      } else {
        AppLogger.warning(_tag, 'Weather API error', {
          'statusCode': response.statusCode,
          'city': cityName,
        });
        return null;
      }
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to fetch weather', e, stackTrace);
      return null;
    }
  }

  /// Get current weather by coordinates
  Future<WeatherInfo?> getWeatherByCoordinates({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final cacheKey = '$latitude,$longitude';

      // Check cache first
      final cached = _cache[cacheKey];
      if (cached != null && cached.isValid) {
        AppLogger.debug(_tag, 'Weather data from cache', {
          'coordinates': cacheKey,
          'age': '${cached.ageInMinutes}min',
        });
        return cached.weather;
      }

      AppLogger.debug(_tag, 'Fetching weather data', {
        'lat': latitude,
        'lon': longitude,
      });

      final url = Uri.parse(
        '$_baseUrl/weather?lat=$latitude&lon=$longitude&appid=${EnvConfig.openWeatherApiKey}&units=metric',
      );

      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final weather = WeatherInfo.fromJson(data);

        // Cache the result
        _cache[cacheKey] = WeatherCache(
          weather: weather,
          cachedAt: DateTime.now(),
        );

        AppLogger.info(_tag, 'Weather data fetched successfully', {
          'location': weather.locationName,
          'temp': weather.temperature,
          'condition': weather.condition,
        });

        return weather;
      } else {
        AppLogger.warning(_tag, 'Weather API error', {
          'statusCode': response.statusCode,
        });
        return null;
      }
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to fetch weather', e, stackTrace);
      return null;
    }
  }

  /// Get 5-day weather forecast
  Future<List<WeatherForecast>> getWeatherForecast({
    required double latitude,
    required double longitude,
  }) async {
    try {
      AppLogger.debug(_tag, 'Fetching weather forecast', {
        'lat': latitude,
        'lon': longitude,
      });

      final url = Uri.parse(
        '$_baseUrl/forecast?lat=$latitude&lon=$longitude&appid=${EnvConfig.openWeatherApiKey}&units=metric&cnt=40',
      );

      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final list = data['list'] as List;

        // Group by day and take one forecast per day
        final Map<String, WeatherForecast> dailyForecasts = {};

        for (var item in list) {
          final forecast = WeatherForecast.fromJson(item);
          final dateKey = '${forecast.date.year}-${forecast.date.month}-${forecast.date.day}';

          // Keep the forecast closest to noon (12:00)
          if (!dailyForecasts.containsKey(dateKey) ||
              (forecast.date.hour - 12).abs() <
                  (dailyForecasts[dateKey]!.date.hour - 12).abs()) {
            dailyForecasts[dateKey] = forecast;
          }
        }

        final forecasts = dailyForecasts.values.toList()
          ..sort((a, b) => a.date.compareTo(b.date));

        AppLogger.info(_tag, 'Weather forecast fetched successfully', {
          'days': forecasts.length,
        });

        return forecasts.take(5).toList(); // Return up to 5 days
      } else {
        AppLogger.warning(_tag, 'Weather forecast API error', {
          'statusCode': response.statusCode,
        });
        return [];
      }
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to fetch weather forecast', e, stackTrace);
      return [];
    }
  }

  /// Clear weather cache
  void clearCache() {
    _cache.clear();
    AppLogger.debug(_tag, 'Weather cache cleared');
  }

  /// Clear expired cache entries
  void clearExpiredCache() {
    _cache.removeWhere((key, value) => !value.isValid);
    AppLogger.debug(_tag, 'Expired weather cache entries removed');
  }

  /// Check if API key is configured
  bool get isConfigured {
    return EnvConfig.hasOpenWeatherConfig;
  }
}

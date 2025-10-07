/// Weather information model
class WeatherInfo {
  final String locationName;
  final double temperature; // Celsius
  final double feelsLike;
  final int humidity; // Percentage
  final String condition; // Clear, Clouds, Rain, etc.
  final String description; // Detailed description
  final String icon; // Weather icon code
  final double windSpeed; // m/s
  final DateTime timestamp;
  final List<WeatherForecast> forecast;

  WeatherInfo({
    required this.locationName,
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.condition,
    required this.description,
    required this.icon,
    required this.windSpeed,
    required this.timestamp,
    this.forecast = const [],
  });

  /// Create from OpenWeatherMap API response
  factory WeatherInfo.fromJson(Map<String, dynamic> json) {
    final main = json['main'] as Map<String, dynamic>;
    final weather = (json['weather'] as List).first as Map<String, dynamic>;
    final wind = json['wind'] as Map<String, dynamic>;

    return WeatherInfo(
      locationName: json['name'] ?? 'Unknown',
      temperature: (main['temp'] ?? 0).toDouble(),
      feelsLike: (main['feels_like'] ?? 0).toDouble(),
      humidity: main['humidity'] ?? 0,
      condition: weather['main'] ?? 'Unknown',
      description: weather['description'] ?? 'No description',
      icon: weather['icon'] ?? '01d',
      windSpeed: (wind['speed'] ?? 0).toDouble(),
      timestamp: DateTime.now(),
      forecast: [],
    );
  }

  /// Get weather emoji icon
  String get emoji {
    switch (condition.toLowerCase()) {
      case 'clear':
        return '☀️';
      case 'clouds':
        return '☁️';
      case 'rain':
      case 'drizzle':
        return '🌧️';
      case 'thunderstorm':
        return '⛈️';
      case 'snow':
        return '❄️';
      case 'mist':
      case 'fog':
        return '🌫️';
      default:
        return '🌤️';
    }
  }

  /// Get temperature color (for UI)
  String get temperatureColor {
    if (temperature >= 30) return '#FF5252'; // Hot - Red
    if (temperature >= 20) return '#FFA726'; // Warm - Orange
    if (temperature >= 10) return '#66BB6A'; // Cool - Green
    return '#42A5F5'; // Cold - Blue
  }

  /// Get weather condition message
  String get conditionMessage {
    switch (condition.toLowerCase()) {
      case 'clear':
        return 'Perfect for outdoor activities!';
      case 'clouds':
        return 'Partly cloudy, good for sightseeing';
      case 'rain':
      case 'drizzle':
        return 'Bring an umbrella!';
      case 'thunderstorm':
        return 'Indoor activities recommended';
      case 'snow':
        return 'Great for winter sports!';
      default:
        return 'Check conditions before heading out';
    }
  }
}

/// Weather forecast for future days
class WeatherForecast {
  final DateTime date;
  final double tempMin;
  final double tempMax;
  final String condition;
  final String icon;
  final int humidity;
  final double windSpeed;

  WeatherForecast({
    required this.date,
    required this.tempMin,
    required this.tempMax,
    required this.condition,
    required this.icon,
    required this.humidity,
    required this.windSpeed,
  });

  /// Create from API response
  factory WeatherForecast.fromJson(Map<String, dynamic> json) {
    final main = json['main'] as Map<String, dynamic>;
    final weather = (json['weather'] as List).first as Map<String, dynamic>;
    final wind = json['wind'] as Map<String, dynamic>;

    return WeatherForecast(
      date: DateTime.fromMillisecondsSinceEpoch(json['dt'] * 1000),
      tempMin: (main['temp_min'] ?? 0).toDouble(),
      tempMax: (main['temp_max'] ?? 0).toDouble(),
      condition: weather['main'] ?? 'Unknown',
      icon: weather['icon'] ?? '01d',
      humidity: main['humidity'] ?? 0,
      windSpeed: (wind['speed'] ?? 0).toDouble(),
    );
  }

  /// Get weather emoji icon
  String get emoji {
    switch (condition.toLowerCase()) {
      case 'clear':
        return '☀️';
      case 'clouds':
        return '☁️';
      case 'rain':
      case 'drizzle':
        return '🌧️';
      case 'thunderstorm':
        return '⛈️';
      case 'snow':
        return '❄️';
      default:
        return '🌤️';
    }
  }
}

/// Weather cache entry
class WeatherCache {
  final WeatherInfo weather;
  final DateTime cachedAt;
  final Duration validDuration;

  WeatherCache({
    required this.weather,
    required this.cachedAt,
    this.validDuration = const Duration(hours: 1),
  });

  /// Check if cache is still valid
  bool get isValid {
    return DateTime.now().difference(cachedAt) < validDuration;
  }

  /// Get age of cache in minutes
  int get ageInMinutes {
    return DateTime.now().difference(cachedAt).inMinutes;
  }
}

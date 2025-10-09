import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/models/weather_model.dart';
import '../../services/weather_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/logger.dart';

/// Weather widget for displaying current weather and forecast
class WeatherWidget extends StatefulWidget {
  final String? cityName;
  final double? latitude;
  final double? longitude;

  const WeatherWidget({
    super.key,
    this.cityName,
    this.latitude,
    this.longitude,
  });

  @override
  State<WeatherWidget> createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget> {
  static const String _tag = 'WeatherWidget';

  final WeatherService _weatherService = WeatherService();
  WeatherInfo? _weatherInfo;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    if (widget.cityName == null && (widget.latitude == null || widget.longitude == null)) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'No location provided';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      WeatherInfo? weather;

      if (widget.cityName != null) {
        weather = await _weatherService.getWeatherByCity(widget.cityName!);
      } else if (widget.latitude != null && widget.longitude != null) {
        weather = await _weatherService.getWeatherByCoordinates(
          latitude: widget.latitude!,
          longitude: widget.longitude!,
        );
      }

      if (mounted) {
        setState(() {
          _weatherInfo = weather;
          _isLoading = false;
        });

        if (weather != null) {
          AppLogger.info(_tag, 'Weather loaded successfully', {
            'location': weather.locationName,
            'temperature': weather.temperature,
          });
        }
      }
    } catch (e) {
      AppLogger.error(_tag, 'Failed to load weather', e);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Unable to load weather data';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_errorMessage != null || _weatherInfo == null) {
      return _buildErrorState();
    }

    return _buildWeatherContent();
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.black,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Loading weather...',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off, size: 20, color: AppColors.grey600),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage ?? 'Weather data unavailable',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherContent() {
    final weather = _weatherInfo!;

    return FadeIn(
      duration: const Duration(milliseconds: 400),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with current weather
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.grey50,
                    AppColors.grey100,
                  ],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Weather Icon
                  Text(
                    weather.emoji,
                    style: const TextStyle(fontSize: 64),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${weather.temperature.round()}°',
                              style: AppTextStyles.displaySmall.copyWith(
                                fontWeight: FontWeight.bold,
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                'C',
                                style: AppTextStyles.titleLarge.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          weather.condition,
                          style: AppTextStyles.titleMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          weather.description.capitalize(),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          weather.conditionMessage,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Weather Details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildWeatherDetail(
                    icon: Icons.thermostat,
                    label: 'Feels Like',
                    value: '${weather.feelsLike.round()}°C',
                  ),
                  _buildWeatherDetail(
                    icon: Icons.water_drop,
                    label: 'Humidity',
                    value: '${weather.humidity}%',
                  ),
                  _buildWeatherDetail(
                    icon: Icons.air,
                    label: 'Wind',
                    value: '${weather.windSpeed.toStringAsFixed(1)} m/s',
                  ),
                ],
              ),
            ),

            // Forecast (if available)
            if (weather.forecast.isNotEmpty) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '5-Day Forecast',
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: weather.forecast.take(5).length,
                        itemBuilder: (context, index) {
                          final forecast = weather.forecast[index];
                          return _buildForecastCard(forecast);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherDetail({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, size: 24, color: AppColors.grey600),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.labelLarge.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildForecastCard(WeatherForecast forecast) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            DateFormat('EEE').format(forecast.date),
            style: AppTextStyles.labelMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            forecast.emoji,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 4),
          Text(
            '${forecast.tempMax.round()}°',
            style: AppTextStyles.labelLarge.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '${forecast.tempMin.round()}°',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    AppLogger.debug(_tag, 'Disposing weather widget');
    super.dispose();
  }
}

/// Extension for string capitalization
extension StringCapitalization on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}

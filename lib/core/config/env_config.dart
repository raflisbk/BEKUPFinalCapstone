import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../utils/logger.dart';

/// Environment Configuration
/// Handles loading and accessing environment variables from .env file
class EnvConfig {
  static const String _tag = 'EnvConfig';

  /// Load environment variables from .env file
  static Future<void> load() async {
    try {
      AppLogger.debug(_tag, 'Loading environment variables from .env file');
      await dotenv.load(fileName: ".env");
      AppLogger.success(_tag, 'Environment variables loaded successfully');

      // Validate required keys
      if (!hasGoogleMapsApiKey) {
        AppLogger.warning(
          _tag,
          'Google Maps API Key not configured or using placeholder value',
        );
      } else {
        AppLogger.info(_tag, 'Google Maps API Key configured');
      }
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to load .env file', e, stackTrace);
      AppLogger.warning(
        _tag,
        'App will continue with default/empty configuration',
      );
    }
  }

  /// Get Google Maps API Key
  static String get googleMapsApiKey {
    final key = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
    if (key.isEmpty) {
      AppLogger.warning(_tag, 'Accessing empty Google Maps API Key');
    }
    return key;
  }

  /// Check if API key is configured
  static bool get hasGoogleMapsApiKey {
    final key = googleMapsApiKey;
    final isValid = key.isNotEmpty && key != 'YOUR_API_KEY_HERE';

    if (!isValid) {
      AppLogger.warning(
        _tag,
        'Google Maps API Key is not properly configured',
      );
    }

    return isValid;
  }
}

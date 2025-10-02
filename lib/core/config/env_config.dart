import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment Configuration
/// Handles loading and accessing environment variables from .env file
class EnvConfig {
  /// Load environment variables from .env file
  static Future<void> load() async {
    await dotenv.load(fileName: ".env");
  }

  /// Get Google Maps API Key
  static String get googleMapsApiKey {
    return dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
  }

  /// Check if API key is configured
  static bool get hasGoogleMapsApiKey {
    final key = googleMapsApiKey;
    return key.isNotEmpty && key != 'YOUR_API_KEY_HERE';
  }
}

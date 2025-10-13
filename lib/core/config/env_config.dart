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

  /// Get Gemini API Key
  static String get geminiApiKey {
    final key = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (key.isEmpty) {
      AppLogger.warning(_tag, 'Accessing empty Gemini API Key');
    }
    return key;
  }

  /// Get Cloudinary Configuration
  static String get cloudinaryCloudName => dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
  static String get cloudinaryApiKey => dotenv.env['CLOUDINARY_API_KEY'] ?? '';
  static String get cloudinaryApiSecret => dotenv.env['CLOUDINARY_API_SECRET'] ?? '';
  static String get cloudinaryUploadPreset => dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? '';

  /// Get App Security Settings
  static String get appSecretKey => dotenv.env['APP_SECRET_KEY'] ?? '';
  static String get jwtSecret => dotenv.env['JWT_SECRET'] ?? '';
  static String get encryptionSalt => dotenv.env['ENCRYPTION_SALT'] ?? '';

  /// Get Environment Settings
  static String get environment => dotenv.env['ENVIRONMENT'] ?? 'development';
  static bool get isProduction => environment == 'production';
  static bool get isDebugMode => dotenv.env['DEBUG_MODE']?.toLowerCase() == 'true';

  /// Check if API key is configured
  static bool get hasGoogleMapsApiKey {
    final key = googleMapsApiKey;
    final isValid = key.isNotEmpty && key != 'YOUR_API_KEY_HERE' && key.startsWith('AIzaSy');

    if (!isValid) {
      AppLogger.warning(
        _tag,
        'Google Maps API Key is not properly configured',
      );
    }

    return isValid;
  }

  /// Check if Gemini API key is configured
  static bool get hasGeminiApiKey {
    final key = geminiApiKey;
    final isValid = key.isNotEmpty && key != 'YOUR_GEMINI_API_KEY_HERE' && key.startsWith('AIzaSy');

    if (!isValid) {
      AppLogger.warning(
        _tag,
        'Gemini API Key is not properly configured',
      );
    }

    return isValid;
  }

  /// Check if Cloudinary is configured
  static bool get hasCloudinaryConfig {
    final cloudName = cloudinaryCloudName;
    final uploadPreset = cloudinaryUploadPreset;
    final isValid = cloudName.isNotEmpty && 
                   cloudName != 'your-cloud-name' && 
                   uploadPreset.isNotEmpty && 
                   uploadPreset != 'your-upload-preset';

    if (!isValid) {
      AppLogger.warning(
        _tag,
        'Cloudinary configuration is not properly set up',
      );
    }

    return isValid;
  }

  /// Validate all critical configurations
  static bool validateConfiguration() {
    AppLogger.info(_tag, 'Validating environment configuration...');
    
    final validations = <String, bool>{
      'Google Maps API': hasGoogleMapsApiKey,
      'Gemini AI API': hasGeminiApiKey,
      'Cloudinary Config': hasCloudinaryConfig,
    };

    bool allValid = true;
    validations.forEach((service, isValid) {
      if (isValid) {
        AppLogger.success(_tag, '$service: ✓ Configured');
      } else {
        AppLogger.error(_tag, '$service: ✗ Not configured');
        allValid = false;
      }
    });

    if (allValid) {
      AppLogger.success(_tag, 'All critical services are configured');
    } else {
      AppLogger.warning(_tag, 'Some services need configuration. Check SETUP_GUIDE.md');
    }

    return allValid;
  }

  /// Get sanitized config for logging (hides sensitive data)
  static Map<String, dynamic> getSanitizedConfig() {
    return {
      'environment': environment,
      'debugMode': isDebugMode,
      'hasGoogleMapsKey': hasGoogleMapsApiKey,
      'hasGeminiKey': hasGeminiApiKey,
      'hasCloudinaryConfig': hasCloudinaryConfig,
      'appVersion': dotenv.env['APP_VERSION'] ?? 'unknown',
    };
  }
}

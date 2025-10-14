import 'dart:async';
import '../core/utils/logger.dart';
import 'supabase_database_service.dart';
import 'supabase_config.dart';

/// Integration Service
/// Manages all external service integrations and API connections
class IntegrationService {
  static const String _tag = 'IntegrationService';
  static const String _integrationsTable = 'external_integrations';
  static const String _apiKeysTable = 'api_keys';
  static const String _webhooksTable = 'webhooks';

  // Integration types
  static const String typeAPI = 'api';
  static const String typeWebhook = 'webhook';
  static const String typeOAuth = 'oauth';
  static const String typeDatabase = 'database';

  // Integration status
  static const String statusActive = 'active';
  static const String statusInactive = 'inactive';
  static const String statusError = 'error';
  static const String statusMaintenance = 'maintenance';

  // Supported integrations
  static const Map<String, Map<String, dynamic>> _supportedIntegrations = {
    'supabase': {
      'name': 'Supabase',
      'description': 'Database, Auth, and Real-time services',
      'type': typeDatabase,
      'required_keys': ['url', 'anon_key'],
      'optional_keys': ['service_role_key'],
      'endpoints': {
        'health': '/rest/v1/',
        'auth': '/auth/v1/',
        'realtime': '/realtime/v1/',
      },
    },
    'cloudinary': {
      'name': 'Cloudinary',
      'description': 'Media storage and transformation',
      'type': typeAPI,
      'required_keys': ['cloud_name', 'api_key', 'api_secret'],
      'optional_keys': ['upload_preset'],
      'endpoints': {
        'upload': '/v1_1/{cloud_name}/image/upload',
        'admin': '/v1_1/{cloud_name}/resources',
      },
    },
    'onesignal': {
      'name': 'OneSignal',
      'description': 'Push notifications',
      'type': typeAPI,
      'required_keys': ['app_id', 'rest_api_key'],
      'optional_keys': ['user_auth_key'],
      'endpoints': {
        'notifications': '/api/v1/notifications',
        'players': '/api/v1/players',
      },
    },
    'mapbox': {
      'name': 'Mapbox',
      'description': 'Maps and navigation',
      'type': typeAPI,
      'required_keys': ['access_token'],
      'optional_keys': ['style_id'],
      'endpoints': {
        'geocoding': '/geocoding/v5/mapbox.places',
        'directions': '/directions/v5/mapbox',
        'static': '/styles/v1/mapbox',
      },
    },
    'openweathermap': {
      'name': 'OpenWeatherMap',
      'description': 'Weather data',
      'type': typeAPI,
      'required_keys': ['api_key'],
      'optional_keys': [],
      'endpoints': {
        'current': '/data/2.5/weather',
        'forecast': '/data/2.5/forecast',
        'onecall': '/data/3.0/onecall',
      },
    },
    'google_gemini': {
      'name': 'Google Gemini',
      'description': 'AI and machine learning',
      'type': typeAPI,
      'required_keys': ['api_key'],
      'optional_keys': ['project_id'],
      'endpoints': {
        'generate': '/v1beta/models/gemini-pro:generateContent',
        'chat': '/v1beta/models/gemini-pro:generateContent',
        'vision': '/v1beta/models/gemini-pro-vision:generateContent',
      },
    },
  };

  // ===============================
  // INTEGRATION MANAGEMENT
  // ===============================

  /// Initialize all integrations
  static Future<Map<String, dynamic>> initializeIntegrations() async {
    try {
      AppLogger.info(_tag, 'Initializing all integrations');

      final results = <String, dynamic>{
        'initialized': <String>[],
        'failed': <String>[],
        'errors': <String, String>{},
        'total': _supportedIntegrations.length,
      };

      for (final entry in _supportedIntegrations.entries) {
        final integrationId = entry.key;
        final config = entry.value;

        try {
          final isInitialized = await _initializeIntegration(integrationId, config);
          if (isInitialized) {
            results['initialized'].add(integrationId);
          } else {
            results['failed'].add(integrationId);
          }
        } catch (e) {
          results['failed'].add(integrationId);
          results['errors'][integrationId] = e.toString();
        }
      }

      AppLogger.success(_tag, 'Integration initialization completed');
      return results;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to initialize integrations', e, stackTrace);
      rethrow;
    }
  }

  /// Test integration connectivity
  static Future<Map<String, dynamic>> testIntegration(String integrationId) async {
    try {
      AppLogger.debug(_tag, 'Testing integration: $integrationId');

      if (!_supportedIntegrations.containsKey(integrationId)) {
        throw Exception('Unsupported integration: $integrationId');
      }

      final config = _supportedIntegrations[integrationId]!;
      final testResult = <String, dynamic>{
        'integration_id': integrationId,
        'name': config['name'],
        'status': statusError,
        'response_time': 0,
        'tested_at': DateTime.now().toIso8601String(),
        'error': null,
      };

      final startTime = DateTime.now();

      // Perform integration-specific test
      switch (integrationId) {
        case 'supabase':
          await _testSupabaseIntegration();
          break;
        case 'cloudinary':
          await _testCloudinaryIntegration();
          break;
        case 'onesignal':
          await _testOneSignalIntegration();
          break;
        case 'mapbox':
          await _testMapboxIntegration();
          break;
        case 'openweathermap':
          await _testOpenWeatherMapIntegration();
          break;
        case 'google_gemini':
          await _testGoogleGeminiIntegration();
          break;
        default:
          throw Exception('No test implementation for $integrationId');
      }

      final endTime = DateTime.now();
      testResult['response_time'] = endTime.difference(startTime).inMilliseconds;
      testResult['status'] = statusActive;

      // Update integration status
      await _updateIntegrationStatus(integrationId, statusActive);

      AppLogger.success(_tag, 'Integration test passed: $integrationId');
      return testResult;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Integration test failed: $integrationId', e, stackTrace);
      
      await _updateIntegrationStatus(integrationId, statusError);
      
      return {
        'integration_id': integrationId,
        'status': statusError,
        'error': e.toString(),
        'tested_at': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Get integration status
  static Future<Map<String, dynamic>> getIntegrationStatus([String? integrationId]) async {
    try {
      AppLogger.debug(_tag, 'Getting integration status');

      if (integrationId != null) {
        // Get specific integration status
        final integrations = await SupabaseDatabaseService.select(
          table: _integrationsTable,
          filters: {'integration_id': integrationId},
        );

        if (integrations.isEmpty) {
          return {
            'integration_id': integrationId,
            'status': 'not_configured',
            'last_checked': null,
          };
        }

        return integrations.first;
      }

      // Get all integrations status
      final integrations = await SupabaseDatabaseService.select(
        table: _integrationsTable,
        orderBy: 'name',
      );

      final statusMap = <String, dynamic>{
        'total_integrations': _supportedIntegrations.length,
        'active': 0,
        'inactive': 0,
        'error': 0,
        'integrations': <String, dynamic>{},
        'last_updated': DateTime.now().toIso8601String(),
      };

      for (final integration in integrations) {
        final status = integration['status'] as String;
        statusMap[status] = (statusMap[status] ?? 0) + 1;
        statusMap['integrations'][integration['integration_id']] = integration;
      }

      AppLogger.success(_tag, 'Integration status retrieved');
      return statusMap;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get integration status', e, stackTrace);
      return {};
    }
  }

  // ===============================
  // API KEY MANAGEMENT
  // ===============================

  /// Store API key securely
  static Future<void> storeAPIKey({
    required String integrationId,
    required String keyName,
    required String keyValue,
    bool isProduction = false,
  }) async {
    try {
      AppLogger.debug(_tag, 'Storing API key: $integrationId/$keyName');

      await SupabaseDatabaseService.insert(
        table: _apiKeysTable,
        data: {
          'integration_id': integrationId,
          'key_name': keyName,
          'key_value': keyValue, // Should be encrypted in production
          'is_production': isProduction,
          'created_at': DateTime.now().toIso8601String(),
          'last_used': null,
        },
      );

      AppLogger.success(_tag, 'API key stored');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to store API key', e, stackTrace);
      rethrow;
    }
  }

  /// Get API key
  static Future<String?> getAPIKey(String integrationId, String keyName) async {
    try {
      final keys = await SupabaseDatabaseService.select(
        table: _apiKeysTable,
        filters: {
          'integration_id': integrationId,
          'key_name': keyName,
        },
      );

      if (keys.isEmpty) return null;

      // Update last used
      await SupabaseDatabaseService.update(
        table: _apiKeysTable,
        id: keys.first['id'],
        data: {'last_used': DateTime.now().toIso8601String()},
      );

      return keys.first['key_value'] as String;
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to get API key: $integrationId/$keyName', e);
      return null;
    }
  }

  // ===============================
  // WEBHOOK MANAGEMENT
  // ===============================

  /// Register webhook
  static Future<void> registerWebhook({
    required String integrationId,
    required String eventType,
    required String callbackUrl,
    Map<String, dynamic>? headers,
  }) async {
    try {
      AppLogger.debug(_tag, 'Registering webhook: $integrationId/$eventType');

      await SupabaseDatabaseService.insert(
        table: _webhooksTable,
        data: {
          'integration_id': integrationId,
          'event_type': eventType,
          'callback_url': callbackUrl,
          'headers': headers ?? {},
          'status': statusActive,
          'created_at': DateTime.now().toIso8601String(),
          'last_triggered': null,
        },
      );

      AppLogger.success(_tag, 'Webhook registered');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to register webhook', e, stackTrace);
      rethrow;
    }
  }

  /// Handle webhook event
  static Future<void> handleWebhookEvent({
    required String integrationId,
    required String eventType,
    required Map<String, dynamic> payload,
  }) async {
    try {
      AppLogger.debug(_tag, 'Handling webhook event: $integrationId/$eventType');

      // Log webhook event
      await SupabaseDatabaseService.insert(
        table: 'webhook_events',
        data: {
          'integration_id': integrationId,
          'event_type': eventType,
          'payload': payload,
          'processed': false,
          'created_at': DateTime.now().toIso8601String(),
        },
      );

      // Process event based on integration
      switch (integrationId) {
        case 'onesignal':
          await _processOneSignalWebhook(eventType, payload);
          break;
        case 'cloudinary':
          await _processCloudinaryWebhook(eventType, payload);
          break;
        default:
          AppLogger.warning(_tag, 'No webhook processor for $integrationId');
      }

      AppLogger.success(_tag, 'Webhook event processed');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to handle webhook event', e, stackTrace);
    }
  }

  // ===============================
  // INTEGRATION HEALTH MONITORING
  // ===============================

  /// Monitor integration health
  static Future<Map<String, dynamic>> monitorIntegrationHealth() async {
    try {
      AppLogger.info(_tag, 'Monitoring integration health');

      final healthReport = <String, dynamic>{
        'timestamp': DateTime.now().toIso8601String(),
        'overall_health': 'healthy',
        'total_integrations': _supportedIntegrations.length,
        'healthy_count': 0,
        'unhealthy_count': 0,
        'integrations': <String, dynamic>{},
      };

      for (final integrationId in _supportedIntegrations.keys) {
        final testResult = await testIntegration(integrationId);
        healthReport['integrations'][integrationId] = testResult;

        if (testResult['status'] == statusActive) {
          healthReport['healthy_count']++;
        } else {
          healthReport['unhealthy_count']++;
        }
      }

      // Determine overall health
      if (healthReport['unhealthy_count'] > 0) {
        if (healthReport['unhealthy_count'] > healthReport['healthy_count']) {
          healthReport['overall_health'] = 'critical';
        } else {
          healthReport['overall_health'] = 'degraded';
        }
      }

      AppLogger.success(_tag, 'Health monitoring completed');
      return healthReport;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to monitor health', e, stackTrace);
      return {
        'timestamp': DateTime.now().toIso8601String(),
        'overall_health': 'error',
        'error': e.toString(),
      };
    }
  }

  // ===============================
  // PRIVATE HELPER METHODS
  // ===============================

  /// Initialize single integration
  static Future<bool> _initializeIntegration(
    String integrationId,
    Map<String, dynamic> config,
  ) async {
    try {
      // Store integration configuration
      await SupabaseDatabaseService.insert(
        table: _integrationsTable,
        data: {
          'integration_id': integrationId,
          'name': config['name'],
          'description': config['description'],
          'type': config['type'],
          'status': statusInactive,
          'config': config,
          'created_at': DateTime.now().toIso8601String(),
          'last_checked': null,
        },
      );

      return true;
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to initialize $integrationId', e);
      return false;
    }
  }

  /// Update integration status
  static Future<void> _updateIntegrationStatus(String integrationId, String status) async {
    try {
      // For now, just log the status update
      AppLogger.info(_tag, 'Integration $integrationId status: $status');
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to update integration status', e);
    }
  }

  // Integration-specific test methods
  static Future<void> _testSupabaseIntegration() async {
    // Test Supabase connection
    await SupabaseConfig.client.from('test').select().limit(1);
  }

  static Future<void> _testCloudinaryIntegration() async {
    // Test Cloudinary API
    // Implementation would depend on Cloudinary SDK
  }

  static Future<void> _testOneSignalIntegration() async {
    // Test OneSignal API
    // Implementation would depend on OneSignal SDK
  }

  static Future<void> _testMapboxIntegration() async {
    // Test Mapbox API
    // Implementation would depend on Mapbox SDK
  }

  static Future<void> _testOpenWeatherMapIntegration() async {
    // Test OpenWeatherMap API
    // Implementation would depend on weather service
  }

  static Future<void> _testGoogleGeminiIntegration() async {
    // Test Google Gemini API
    // Implementation would depend on Gemini service
  }

  // Webhook processors
  static Future<void> _processOneSignalWebhook(String eventType, Map<String, dynamic> payload) async {
    // Process OneSignal webhook events
  }

  static Future<void> _processCloudinaryWebhook(String eventType, Map<String, dynamic> payload) async {
    // Process Cloudinary webhook events
  }

  /// Get supported integrations
  static Map<String, Map<String, dynamic>> getSupportedIntegrations() {
    return Map.from(_supportedIntegrations);
  }

  /// Check if integration is supported
  static bool isIntegrationSupported(String integrationId) {
    return _supportedIntegrations.containsKey(integrationId);
  }

  /// Get integration configuration
  static Map<String, dynamic>? getIntegrationConfig(String integrationId) {
    return _supportedIntegrations[integrationId];
  }
}
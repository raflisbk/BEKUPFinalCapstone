import 'dart:async';
import 'dart:convert';
import '../core/utils/logger.dart';
import 'supabase_database_service.dart';
import 'service_mapping_service.dart';

/// Documentation Service
/// Handles automatic documentation generation and management
class DocumentationService {
  static const String _tag = 'DocumentationService';
  static const String _documentationTable = 'app_documentation';
  static const String _changelogTable = 'changelog';

  // Documentation types
  static const String typeAPI = 'api';
  static const String typeService = 'service';
  static const String typeComponent = 'component';
  static const String typeArchitecture = 'architecture';
  static const String typeUserGuide = 'user_guide';
  static const String typeMigration = 'migration';

  // Documentation formats
  static const String formatMarkdown = 'markdown';
  static const String formatJSON = 'json';
  static const String formatHTML = 'html';
  static const String formatPDF = 'pdf';

  // ===============================
  // DOCUMENTATION GENERATION
  // ===============================

  /// Generate comprehensive API documentation
  static Future<Map<String, dynamic>> generateAPIDocumentation() async {
    try {
      AppLogger.info(_tag, 'Generating API documentation');

      final apiDocs = <String, dynamic>{
        'title': 'Relink API Documentation',
        'version': '1.0.0',
        'generated_at': DateTime.now().toIso8601String(),
        'endpoints': {},
        'models': {},
        'authentication': _generateAuthDocumentation(),
        'error_codes': _generateErrorCodeDocumentation(),
      };

      // Generate service endpoints documentation
      final serviceMapping = ServiceMappingService.getServiceMapping();
      for (final entry in serviceMapping.entries) {
        final category = entry.key;
        final services = entry.value;

        apiDocs['endpoints'][category] = {};

        for (final service in services) {
          final serviceName = service['name'] as String;
          final endpoints = await _generateServiceEndpoints(serviceName, service);
          apiDocs['endpoints'][category][serviceName] = endpoints;
        }
      }

      // Generate data models documentation
      apiDocs['models'] = await _generateDataModels();

      // Save documentation
      await _saveDocumentation(
        type: typeAPI,
        title: 'API Documentation',
        content: apiDocs,
        format: formatJSON,
      );

      AppLogger.success(_tag, 'API documentation generated successfully');
      return apiDocs;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to generate API documentation', e, stackTrace);
      rethrow;
    }
  }

  /// Generate service architecture documentation
  static Future<String> generateArchitectureDocumentation() async {
    try {
      AppLogger.info(_tag, 'Generating architecture documentation');

      final buffer = StringBuffer();
      
      // Header
      buffer.writeln('# Relink Architecture Documentation');
      buffer.writeln('');
      buffer.writeln('**Generated on**: ${DateTime.now().toString()}');
      buffer.writeln('');

      // Overview
      buffer.writeln('## Architecture Overview');
      buffer.writeln('');
      buffer.writeln('Relink is built using a modern, scalable architecture with the following key components:');
      buffer.writeln('');

      // Service layer documentation
      buffer.writeln('## Service Layer Architecture');
      buffer.writeln('');
      buffer.writeln('The application follows a service-oriented architecture with clear separation of concerns:');
      buffer.writeln('');

      final serviceMapping = ServiceMappingService.getServiceMapping();
      final stats = ServiceMappingService.getServiceStatistics();

      buffer.writeln('### Service Statistics');
      buffer.writeln('- **Total Services**: ${stats['total_services']}');
      buffer.writeln('- **Service Categories**: ${stats['total_categories']}');
      buffer.writeln('');

      // Technology stack
      buffer.writeln('## Technology Stack');
      buffer.writeln('');
      buffer.writeln('### Backend Services');
      buffer.writeln('- **Database**: Supabase (PostgreSQL)');
      buffer.writeln('- **Authentication**: Supabase Auth');
      buffer.writeln('- **Real-time**: Supabase Realtime');
      buffer.writeln('- **Storage**: Cloudinary (Media)');
      buffer.writeln('- **AI**: Google Gemini');
      buffer.writeln('- **Maps**: Mapbox');
      buffer.writeln('- **Notifications**: OneSignal');
      buffer.writeln('- **Weather**: OpenWeatherMap');
      buffer.writeln('');

      buffer.writeln('### Frontend Framework');
      buffer.writeln('- **Framework**: Flutter');
      buffer.writeln('- **State Management**: Provider');
      buffer.writeln('- **Local Storage**: Hive');
      buffer.writeln('- **HTTP Client**: Dio');
      buffer.writeln('');

      // Service categories
      for (final entry in serviceMapping.entries) {
        final category = entry.key;
        final services = entry.value;

        buffer.writeln('### $category');
        buffer.writeln('');

        for (final service in services) {
          buffer.writeln('#### ${service['name']}');
          buffer.writeln('**Purpose**: ${service['description']}');
          buffer.writeln('**Type**: ${service['type']}');
          buffer.writeln('**Status**: ${service['status']}');
          
          if (service['dependencies'] != null && (service['dependencies'] as List).isNotEmpty) {
            buffer.writeln('**Dependencies**: ${(service['dependencies'] as List).join(', ')}');
          }
          
          buffer.writeln('');
        }
      }

      // Migration information
      buffer.writeln('## Migration from Firebase');
      buffer.writeln('');
      buffer.writeln('This application has been migrated from Firebase to a free-tier stack:');
      buffer.writeln('');
      buffer.writeln('| Firebase Service | Replacement | Benefits |');
      buffer.writeln('|-----------------|-------------|----------|');
      buffer.writeln('| Firestore | Supabase PostgreSQL | More powerful queries, better performance |');
      buffer.writeln('| Firebase Auth | Supabase Auth | Same features, better integration |');
      buffer.writeln('| Firebase Storage | Cloudinary | Advanced image processing, free tier |');
      buffer.writeln('| Firebase Functions | Supabase Edge Functions | Better TypeScript support |');
      buffer.writeln('| Firebase Messaging | OneSignal | More features in free tier |');
      buffer.writeln('');

      final documentation = buffer.toString();

      // Save documentation
      await _saveDocumentation(
        type: typeArchitecture,
        title: 'Architecture Documentation',
        content: documentation,
        format: formatMarkdown,
      );

      AppLogger.success(_tag, 'Architecture documentation generated');
      return documentation;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to generate architecture documentation', e, stackTrace);
      rethrow;
    }
  }

  /// Generate migration guide documentation
  static Future<String> generateMigrationGuide() async {
    try {
      AppLogger.info(_tag, 'Generating migration guide');

      final buffer = StringBuffer();
      
      buffer.writeln('# Firebase to Free Stack Migration Guide');
      buffer.writeln('');
      buffer.writeln('This guide documents the complete migration from Firebase to a free-tier technology stack.');
      buffer.writeln('');
      
      buffer.writeln('## Migration Overview');
      buffer.writeln('');
      buffer.writeln('### Goals');
      buffer.writeln('- Reduce operational costs to zero');
      buffer.writeln('- Maintain all existing functionality');
      buffer.writeln('- Improve performance and scalability');
      buffer.writeln('- Add new AI-powered features');
      buffer.writeln('');

      buffer.writeln('### Migration Strategy');
      buffer.writeln('1. **Database Migration**: Firebase Firestore → Supabase PostgreSQL');
      buffer.writeln('2. **Authentication**: Firebase Auth → Supabase Auth');
      buffer.writeln('3. **Storage**: Firebase Storage → Cloudinary');
      buffer.writeln('4. **Real-time**: Firebase Realtime → Supabase Realtime');
      buffer.writeln('5. **Functions**: Firebase Functions → Supabase Edge Functions');
      buffer.writeln('6. **Notifications**: Firebase Messaging → OneSignal');
      buffer.writeln('');

      buffer.writeln('## Service Migration Details');
      buffer.writeln('');

      final serviceMapping = ServiceMappingService.getServiceMapping();
      for (final entry in serviceMapping.entries) {
        final category = entry.key;
        final services = entry.value;

        buffer.writeln('### $category');
        buffer.writeln('');

        for (final service in services) {
          buffer.writeln('#### ${service['name']}');
          buffer.writeln('- **New Implementation**: ${service['file_path']}');
          buffer.writeln('- **Replaces**: Firebase equivalent');
          buffer.writeln('- **Status**: ${service['status']}');
          buffer.writeln('');
        }
      }

      buffer.writeln('## Benefits Achieved');
      buffer.writeln('');
      buffer.writeln('### Cost Savings');
      buffer.writeln('- **Firebase**: \$25-100+/month');
      buffer.writeln('- **New Stack**: \$0/month (free tiers)');
      buffer.writeln('');

      buffer.writeln('### New Capabilities');
      buffer.writeln('- AI-powered trip planning');
      buffer.writeln('- Advanced image recognition');
      buffer.writeln('- Intelligent recommendations');
      buffer.writeln('- Enhanced chat features');
      buffer.writeln('- Better offline support');
      buffer.writeln('');

      final documentation = buffer.toString();

      await _saveDocumentation(
        type: typeMigration,
        title: 'Migration Guide',
        content: documentation,
        format: formatMarkdown,
      );

      AppLogger.success(_tag, 'Migration guide generated');
      return documentation;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to generate migration guide', e, stackTrace);
      rethrow;
    }
  }

  /// Generate user guide documentation
  static Future<String> generateUserGuide() async {
    try {
      AppLogger.info(_tag, 'Generating user guide');

      final buffer = StringBuffer();
      
      buffer.writeln('# Relink User Guide');
      buffer.writeln('');
      buffer.writeln('Welcome to Relink - your AI-powered travel companion!');
      buffer.writeln('');

      buffer.writeln('## Getting Started');
      buffer.writeln('');
      buffer.writeln('1. **Sign Up**: Create your account using email or social login');
      buffer.writeln('2. **Complete Profile**: Add your travel preferences and interests');
      buffer.writeln('3. **Explore Features**: Discover AI-powered trip planning');
      buffer.writeln('4. **Connect**: Join the travel community');
      buffer.writeln('');

      buffer.writeln('## Key Features');
      buffer.writeln('');

      // Generate feature documentation based on services
      final serviceMapping = ServiceMappingService.getServiceMapping();
      
      if (serviceMapping.containsKey(ServiceMappingService.categoryAI)) {
        buffer.writeln('### AI Features');
        buffer.writeln('');
        for (final service in serviceMapping[ServiceMappingService.categoryAI]!) {
          final name = service['name'] as String;
          final description = service['description'] as String;
          
          if (name.startsWith('AI')) {
            buffer.writeln('#### ${name.replaceAll('Service', '').replaceAll('AI', '')}');
            buffer.writeln(description);
            buffer.writeln('');
          }
        }
      }

      buffer.writeln('### Travel Planning');
      buffer.writeln('- Create detailed itineraries with AI assistance');
      buffer.writeln('- Get personalized recommendations');
      buffer.writeln('- Optimize routes and budgets');
      buffer.writeln('- Discover hidden gems');
      buffer.writeln('');

      buffer.writeln('### Social Features');
      buffer.writeln('- Share travel experiences');
      buffer.writeln('- Connect with fellow travelers');
      buffer.writeln('- Rate and review destinations');
      buffer.writeln('- Join travel communities');
      buffer.writeln('');

      buffer.writeln('## Tips for Best Experience');
      buffer.writeln('');
      buffer.writeln('1. **Enable Location Services**: For accurate recommendations');
      buffer.writeln('2. **Update Preferences**: Keep your travel profile current');
      buffer.writeln('3. **Engage with Community**: Share and discover experiences');
      buffer.writeln('4. **Use AI Features**: Let AI help plan your perfect trip');
      buffer.writeln('');

      final documentation = buffer.toString();

      await _saveDocumentation(
        type: typeUserGuide,
        title: 'User Guide',
        content: documentation,
        format: formatMarkdown,
      );

      AppLogger.success(_tag, 'User guide generated');
      return documentation;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to generate user guide', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // CHANGELOG MANAGEMENT
  // ===============================

  /// Add changelog entry
  static Future<void> addChangelogEntry({
    required String version,
    required String type, // 'feature', 'bugfix', 'improvement', 'breaking'
    required String description,
    List<String>? details,
  }) async {
    try {
      AppLogger.debug(_tag, 'Adding changelog entry: $version - $type');

      await SupabaseDatabaseService.insert(
        table: _changelogTable,
        data: {
          'version': version,
          'type': type,
          'description': description,
          'details': details ?? [],
          'date': DateTime.now().toIso8601String(),
          'created_at': DateTime.now().toIso8601String(),
        },
      );

      AppLogger.success(_tag, 'Changelog entry added');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to add changelog entry', e, stackTrace);
      rethrow;
    }
  }

  /// Generate changelog documentation
  static Future<String> generateChangelog() async {
    try {
      AppLogger.info(_tag, 'Generating changelog');

      final changelog = await SupabaseDatabaseService.select(
        table: _changelogTable,
        orderBy: 'date',
        ascending: false,
      );

      final buffer = StringBuffer();
      
      buffer.writeln('# Changelog');
      buffer.writeln('');
      buffer.writeln('All notable changes to Relink will be documented in this file.');
      buffer.writeln('');

      String? currentVersion;
      for (final entry in changelog) {
        final version = entry['version'] as String;
        final type = entry['type'] as String;
        final description = entry['description'] as String;
        final details = List<String>.from(entry['details'] ?? []);
        final date = DateTime.parse(entry['date'] as String);

        if (currentVersion != version) {
          if (currentVersion != null) buffer.writeln('');
          buffer.writeln('## [$version] - ${date.toString().split(' ')[0]}');
          buffer.writeln('');
          currentVersion = version;
        }

        final typeLabel = type.toUpperCase();
        buffer.writeln('### $typeLabel');
        buffer.writeln('- $description');
        
        for (final detail in details) {
          buffer.writeln('  - $detail');
        }
        buffer.writeln('');
      }

      final documentation = buffer.toString();

      await _saveDocumentation(
        type: 'changelog',
        title: 'Changelog',
        content: documentation,
        format: formatMarkdown,
      );

      AppLogger.success(_tag, 'Changelog generated');
      return documentation;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to generate changelog', e, stackTrace);
      return '# Changelog\n\nNo changelog entries found.';
    }
  }

  // ===============================
  // DOCUMENTATION MANAGEMENT
  // ===============================

  /// Save documentation to database
  static Future<void> _saveDocumentation({
    required String type,
    required String title,
    required dynamic content,
    required String format,
  }) async {
    try {
      final contentString = content is String ? content : jsonEncode(content);

      await SupabaseDatabaseService.insert(
        table: _documentationTable,
        data: {
          'type': type,
          'title': title,
          'content': contentString,
          'format': format,
          'version': '1.0.0',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to save documentation to database', e);
    }
  }

  /// Get documentation by type
  static Future<List<Map<String, dynamic>>> getDocumentation({
    String? type,
    String? format,
  }) async {
    try {
      final filters = <String, dynamic>{};
      if (type != null) filters['type'] = type;
      if (format != null) filters['format'] = format;

      return await SupabaseDatabaseService.select(
        table: _documentationTable,
        filters: filters.isNotEmpty ? filters : null,
        orderBy: 'updated_at',
        ascending: false,
      );
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to get documentation', e);
      return [];
    }
  }

  /// Export all documentation
  static Future<Map<String, dynamic>> exportAllDocumentation() async {
    try {
      AppLogger.info(_tag, 'Exporting all documentation');

      final export = <String, dynamic>{
        'export_date': DateTime.now().toIso8601String(),
        'api_docs': await generateAPIDocumentation(),
        'architecture': await generateArchitectureDocumentation(),
        'migration_guide': await generateMigrationGuide(),
        'user_guide': await generateUserGuide(),
        'changelog': await generateChangelog(),
        'service_mapping': ServiceMappingService.exportToJson(),
      };

      AppLogger.success(_tag, 'All documentation exported');
      return export;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to export documentation', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // PRIVATE HELPER METHODS
  // ===============================

  /// Generate authentication documentation
  static Map<String, dynamic> _generateAuthDocumentation() {
    return {
      'overview': 'Supabase-based authentication system',
      'methods': ['email/password', 'magic_link', 'oauth'],
      'endpoints': {
        'login': '/auth/login',
        'register': '/auth/register',
        'logout': '/auth/logout',
        'profile': '/auth/profile',
      },
      'security': 'JWT tokens with Row Level Security (RLS)',
    };
  }

  /// Generate error code documentation
  static Map<String, dynamic> _generateErrorCodeDocumentation() {
    return {
      '400': 'Bad Request - Invalid parameters',
      '401': 'Unauthorized - Authentication required',
      '403': 'Forbidden - Insufficient permissions',
      '404': 'Not Found - Resource not found',
      '500': 'Internal Server Error - Server error',
      '503': 'Service Unavailable - Service temporarily unavailable',
    };
  }

  /// Generate service endpoints
  static Future<Map<String, dynamic>> _generateServiceEndpoints(
    String serviceName,
    Map<String, dynamic> service,
  ) async {
    // This would analyze the service file and extract endpoint information
    // For now, return a placeholder structure
    return {
      'base_path': '/api/${serviceName.toLowerCase()}',
      'methods': ['GET', 'POST', 'PUT', 'DELETE'],
      'authentication_required': true,
      'rate_limiting': 'Standard',
    };
  }

  /// Generate data models documentation
  static Future<Map<String, dynamic>> _generateDataModels() async {
    // This would analyze the model files and generate schema documentation
    return {
      'User': {
        'fields': ['id', 'email', 'name', 'avatar_url', 'created_at'],
        'relationships': ['trips', 'reviews', 'social_connections'],
      },
      'Trip': {
        'fields': ['id', 'title', 'description', 'start_date', 'end_date'],
        'relationships': ['user', 'destinations', 'itinerary'],
      },
      'Destination': {
        'fields': ['id', 'name', 'location', 'description', 'category'],
        'relationships': ['trips', 'reviews', 'photos'],
      },
    };
  }
}
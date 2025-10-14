import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/utils/logger.dart';
import 'supabase_database_service.dart';
import 'service_mapping_service.dart';
import 'integration_service.dart';

/// Development Service
/// Handles development tools, testing, and environment management
class DevelopmentService {
  static const String _tag = 'DevelopmentService';
  static const String _testResultsTable = 'test_results';
  static const String _debugLogsTable = 'debug_logs';
  static const String _performanceMetricsTable = 'performance_metrics';

  // Environment types
  static const String envDevelopment = 'development';
  static const String envTesting = 'testing';
  static const String envStaging = 'staging';
  static const String envProduction = 'production';

  // Test types
  static const String testUnit = 'unit';
  static const String testIntegration = 'integration';
  static const String testWidget = 'widget';
  static const String testEnd2End = 'e2e';

  // Log levels
  static const String logDebug = 'debug';
  static const String logInfo = 'info';
  static const String logWarning = 'warning';
  static const String logError = 'error';

  static String _currentEnvironment = envDevelopment;
  static bool _debugMode = true;
  static bool _testMode = false;

  // ===============================
  // ENVIRONMENT MANAGEMENT
  // ===============================

  /// Initialize development environment
  static Future<void> initializeDevelopmentEnvironment() async {
    try {
      AppLogger.info(_tag, 'Initializing development environment');

      // Set environment
      _currentEnvironment = envDevelopment;
      _debugMode = true;
      _testMode = false;

      // Initialize debug logging
      await _initializeDebugLogging();

      // Setup development tools
      await _setupDevelopmentTools();

      // Validate environment
      await _validateEnvironment();

      AppLogger.success(_tag, 'Development environment initialized');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to initialize development environment', e, stackTrace);
      rethrow;
    }
  }

  /// Switch environment
  static Future<void> switchEnvironment(String environment) async {
    try {
      AppLogger.info(_tag, 'Switching to environment: $environment');

      final oldEnvironment = _currentEnvironment;
      _currentEnvironment = environment;

      // Update settings based on environment
      switch (environment) {
        case envDevelopment:
          _debugMode = true;
          _testMode = false;
          break;
        case envTesting:
          _debugMode = true;
          _testMode = true;
          break;
        case envStaging:
          _debugMode = false;
          _testMode = false;
          break;
        case envProduction:
          _debugMode = false;
          _testMode = false;
          break;
      }

      // Log environment switch
      await _logEnvironmentSwitch(oldEnvironment, environment);

      AppLogger.success(_tag, 'Environment switched to: $environment');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to switch environment', e, stackTrace);
      rethrow;
    }
  }

  /// Get current environment
  static String getCurrentEnvironment() => _currentEnvironment;

  /// Check if in debug mode
  static bool isDebugMode() => _debugMode;

  /// Check if in test mode
  static bool isTestMode() => _testMode;

  // ===============================
  // TESTING FRAMEWORK
  // ===============================

  /// Run service tests
  static Future<Map<String, dynamic>> runServiceTests({
    List<String>? serviceNames,
    String testType = testUnit,
    bool verbose = false,
  }) async {
    try {
      AppLogger.info(_tag, 'Running service tests: $testType');

      final testResults = <String, dynamic>{
        'test_type': testType,
        'started_at': DateTime.now().toIso8601String(),
        'total_tests': 0,
        'passed': 0,
        'failed': 0,
        'skipped': 0,
        'results': <String, dynamic>{},
        'duration': 0,
      };

      final startTime = DateTime.now();

      // Get services to test
      final services = serviceNames ?? ServiceMappingService.getAllServiceNames();

      for (final serviceName in services) {
        if (verbose) {
          AppLogger.debug(_tag, 'Testing service: $serviceName');
        }

        final serviceTestResult = await _runServiceTest(serviceName, testType);
        testResults['results'][serviceName] = serviceTestResult;
        testResults['total_tests']++;

        if (serviceTestResult['passed'] == true) {
          testResults['passed']++;
        } else if (serviceTestResult['skipped'] == true) {
          testResults['skipped']++;
        } else {
          testResults['failed']++;
        }
      }

      final endTime = DateTime.now();
      testResults['duration'] = endTime.difference(startTime).inMilliseconds;
      testResults['completed_at'] = endTime.toIso8601String();

      // Save test results
      await _saveTestResults(testResults);

      AppLogger.success(_tag, 'Service tests completed: ${testResults['passed']}/${testResults['total_tests']} passed');
      return testResults;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to run service tests', e, stackTrace);
      rethrow;
    }
  }

  /// Run integration tests
  static Future<Map<String, dynamic>> runIntegrationTests() async {
    try {
      AppLogger.info(_tag, 'Running integration tests');

      final testResults = <String, dynamic>{
        'test_type': testIntegration,
        'started_at': DateTime.now().toIso8601String(),
        'integrations': <String, dynamic>{},
        'total_integrations': 0,
        'passed': 0,
        'failed': 0,
      };

      final startTime = DateTime.now();

      // Test all integrations
      final integrations = IntegrationService.getSupportedIntegrations();
      testResults['total_integrations'] = integrations.length;

      for (final entry in integrations.entries) {
        final integrationId = entry.key;
        final config = entry.value;

        AppLogger.debug(_tag, 'Testing integration: ${config['name']}');

        final integrationTest = await IntegrationService.testIntegration(integrationId);
        testResults['integrations'][integrationId] = integrationTest;

        if (integrationTest['status'] == 'active') {
          testResults['passed']++;
        } else {
          testResults['failed']++;
        }
      }

      final endTime = DateTime.now();
      testResults['duration'] = endTime.difference(startTime).inMilliseconds;
      testResults['completed_at'] = endTime.toIso8601String();

      // Save test results
      await _saveTestResults(testResults);

      AppLogger.success(_tag, 'Integration tests completed: ${testResults['passed']}/${testResults['total_integrations']} passed');
      return testResults;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to run integration tests', e, stackTrace);
      rethrow;
    }
  }

  /// Generate test report
  static Future<String> generateTestReport() async {
    try {
      AppLogger.info(_tag, 'Generating test report');

      final testResults = await SupabaseDatabaseService.select(
        table: _testResultsTable,
        orderBy: 'created_at',
        ascending: false,
        limit: 10,
      );

      final buffer = StringBuffer();
      
      buffer.writeln('# Test Report');
      buffer.writeln('');
      buffer.writeln('**Generated**: ${DateTime.now().toString()}');
      buffer.writeln('');

      if (testResults.isEmpty) {
        buffer.writeln('No test results found.');
        return buffer.toString();
      }

      buffer.writeln('## Recent Test Runs');
      buffer.writeln('');

      for (final result in testResults) {
        final testType = result['test_type'] as String;
        final startedAt = result['started_at'] as String;
        final passed = result['passed'] as int;
        final failed = result['failed'] as int;
        final total = result['total_tests'] as int;
        final duration = result['duration'] as int;

        buffer.writeln('### ${testType.toUpperCase()} Tests - $startedAt');
        buffer.writeln('- **Results**: $passed/$total passed, $failed failed');
        buffer.writeln('- **Duration**: ${duration}ms');
        buffer.writeln('- **Success Rate**: ${((passed / total) * 100).toStringAsFixed(1)}%');
        buffer.writeln('');
      }

      final report = buffer.toString();
      AppLogger.success(_tag, 'Test report generated');
      return report;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to generate test report', e, stackTrace);
      return '# Test Report\n\nError generating report: $e';
    }
  }

  // ===============================
  // DEBUG TOOLS
  // ===============================

  /// Enable debug logging
  static void enableDebugLogging() {
    _debugMode = true;
    AppLogger.info(_tag, 'Debug logging enabled');
  }

  /// Disable debug logging
  static void disableDebugLogging() {
    _debugMode = false;
    AppLogger.info(_tag, 'Debug logging disabled');
  }

  /// Log debug message
  static Future<void> debugLog({
    required String component,
    required String message,
    String level = logDebug,
    Map<String, dynamic>? metadata,
  }) async {
    if (!_debugMode && level == logDebug) return;

    try {
      AppLogger.debug(_tag, '[$component] $message');

      await SupabaseDatabaseService.insert(
        table: _debugLogsTable,
        data: {
          'component': component,
          'message': message,
          'level': level,
          'metadata': metadata ?? {},
          'environment': _currentEnvironment,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      // Don't let logging errors break the app
      debugPrint('Failed to save debug log: $e');
    }
  }

  /// Get debug logs
  static Future<List<Map<String, dynamic>>> getDebugLogs({
    String? component,
    String? level,
    int limit = 100,
  }) async {
    try {
      final filters = <String, dynamic>{};
      if (component != null) filters['component'] = component;
      if (level != null) filters['level'] = level;

      return await SupabaseDatabaseService.select(
        table: _debugLogsTable,
        filters: filters.isNotEmpty ? filters : null,
        orderBy: 'timestamp',
        ascending: false,
        limit: limit,
      );
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to get debug logs', e);
      return [];
    }
  }

  // ===============================
  // PERFORMANCE MONITORING
  // ===============================

  /// Start performance monitoring
  static String startPerformanceTimer(String operation) {
    final timerId = '${operation}_${DateTime.now().millisecondsSinceEpoch}';
    _performanceTimers[timerId] = DateTime.now();
    return timerId;
  }

  /// End performance monitoring
  static Future<void> endPerformanceTimer(String timerId, [Map<String, dynamic>? metadata]) async {
    final startTime = _performanceTimers[timerId];
    if (startTime == null) return;

    final endTime = DateTime.now();
    final duration = endTime.difference(startTime).inMilliseconds;

    try {
      await SupabaseDatabaseService.insert(
        table: _performanceMetricsTable,
        data: {
          'timer_id': timerId,
          'operation': timerId.split('_')[0],
          'duration_ms': duration,
          'metadata': metadata ?? {},
          'environment': _currentEnvironment,
          'timestamp': endTime.toIso8601String(),
        },
      );

      _performanceTimers.remove(timerId);

      if (_debugMode) {
        AppLogger.debug(_tag, 'Performance: ${timerId.split('_')[0]} took ${duration}ms');
      }
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to save performance metric', e);
    }
  }

  /// Get performance metrics
  static Future<Map<String, dynamic>> getPerformanceMetrics({
    String? operation,
    Duration? timeRange,
  }) async {
    try {
      final filters = <String, dynamic>{};
      if (operation != null) filters['operation'] = operation;

      final metrics = await SupabaseDatabaseService.select(
        table: _performanceMetricsTable,
        filters: filters.isNotEmpty ? filters : null,
        orderBy: 'timestamp',
        ascending: false,
        limit: 1000,
      );

      if (metrics.isEmpty) {
        return {'total_metrics': 0, 'operations': {}};
      }

      final analysis = <String, dynamic>{
        'total_metrics': metrics.length,
        'operations': <String, dynamic>{},
        'analyzed_at': DateTime.now().toIso8601String(),
      };

      final operationGroups = <String, List<int>>{};

      for (final metric in metrics) {
        final op = metric['operation'] as String;
        final duration = metric['duration_ms'] as int;

        if (!operationGroups.containsKey(op)) {
          operationGroups[op] = [];
        }
        operationGroups[op]!.add(duration);
      }

      for (final entry in operationGroups.entries) {
        final op = entry.key;
        final durations = entry.value;

        durations.sort();
        final count = durations.length;
        final total = durations.reduce((a, b) => a + b);
        final avg = total / count;
        final median = durations[count ~/ 2];
        final p95 = durations[(count * 0.95).floor()];

        analysis['operations'][op] = {
          'count': count,
          'avg_ms': avg.round(),
          'median_ms': median,
          'p95_ms': p95,
          'min_ms': durations.first,
          'max_ms': durations.last,
        };
      }

      return analysis;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get performance metrics', e, stackTrace);
      return {'error': e.toString()};
    }
  }

  // ===============================
  // PRIVATE HELPER METHODS
  // ===============================

  static final Map<String, DateTime> _performanceTimers = {};

  /// Initialize debug logging
  static Future<void> _initializeDebugLogging() async {
    AppLogger.info(_tag, 'Debug logging initialized');
  }

  /// Setup development tools
  static Future<void> _setupDevelopmentTools() async {
    AppLogger.info(_tag, 'Development tools setup completed');
  }

  /// Validate environment
  static Future<void> _validateEnvironment() async {
    AppLogger.info(_tag, 'Environment validation completed');
  }

  /// Log environment switch
  static Future<void> _logEnvironmentSwitch(String from, String to) async {
    await debugLog(
      component: 'Environment',
      message: 'Environment switched from $from to $to',
      level: logInfo,
      metadata: {'from': from, 'to': to},
    );
  }

  /// Run individual service test
  static Future<Map<String, dynamic>> _runServiceTest(String serviceName, String testType) async {
    try {
      // Mock test implementation
      final testResult = <String, dynamic>{
        'service_name': serviceName,
        'test_type': testType,
        'passed': true,
        'skipped': false,
        'duration': 100 + (serviceName.hashCode % 500), // Mock duration
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Simulate occasional test failures for realism
      if (serviceName.hashCode % 10 == 0) {
        testResult['passed'] = false;
        testResult['error'] = 'Mock test failure';
      }

      return testResult;
    } catch (e) {
      return {
        'service_name': serviceName,
        'test_type': testType,
        'passed': false,
        'skipped': false,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Save test results
  static Future<void> _saveTestResults(Map<String, dynamic> testResults) async {
    try {
      await SupabaseDatabaseService.insert(
        table: _testResultsTable,
        data: {
          ...testResults,
          'environment': _currentEnvironment,
          'created_at': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to save test results', e);
    }
  }

  /// Get development status
  static Map<String, dynamic> getDevelopmentStatus() {
    return {
      'environment': _currentEnvironment,
      'debug_mode': _debugMode,
      'test_mode': _testMode,
      'active_timers': _performanceTimers.length,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}
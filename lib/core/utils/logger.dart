import 'package:flutter/foundation.dart';

/// Custom Logger for ReLink App
/// Provides structured logging with different levels and clean output
class AppLogger {
  static const String _appName = 'ReLink';

  // ANSI color codes for terminal output
  static const String _reset = '\x1B[0m';
  static const String _red = '\x1B[31m';
  static const String _green = '\x1B[32m';
  static const String _yellow = '\x1B[33m';
  static const String _blue = '\x1B[34m';
  static const String _magenta = '\x1B[35m';
  static const String _cyan = '\x1B[36m';
  static const String _white = '\x1B[37m';

  /// Log debug messages (for development only)
  static void debug(String tag, String message, [dynamic data]) {
    if (kDebugMode) {
      final timestamp = _timestamp();
      final formattedMessage = '[$_cyan$_appName$_reset][$_blue$tag$_reset] $timestamp - $_white$message$_reset';
      debugPrint(formattedMessage);
      if (data != null) {
        debugPrint('  ${_white}Data: $data$_reset');
      }
    }
  }

  /// Log info messages
  static void info(String tag, String message, [dynamic data]) {
    if (kDebugMode) {
      final timestamp = _timestamp();
      final formattedMessage = '[$_cyan$_appName$_reset][$_green$tag$_reset] $timestamp - $message';
      debugPrint(formattedMessage);
      if (data != null) {
        debugPrint('  Data: $data');
      }
    }
  }

  /// Log warning messages
  static void warning(String tag, String message, [dynamic data]) {
    final timestamp = _timestamp();
    final formattedMessage = '[$_cyan$_appName$_reset][$_yellow$tag$_reset] $timestamp - $_yellow⚠️  $message$_reset';
    debugPrint(formattedMessage);
    if (data != null) {
      debugPrint('  $_yellow⚠️  Data: $data$_reset');
    }
  }

  /// Log error messages
  static void error(String tag, String message, [dynamic error, StackTrace? stackTrace]) {
    final timestamp = _timestamp();
    final formattedMessage = '[$_cyan$_appName$_reset][$_red$tag$_reset] $timestamp - $_red❌ $message$_reset';
    debugPrint(formattedMessage);

    if (error != null) {
      debugPrint('  $_red❌ Error: $error$_reset');
    }

    if (stackTrace != null && kDebugMode) {
      debugPrint('  $_red❌ StackTrace:$_reset');
      debugPrint('$stackTrace');
    }
  }

  /// Log success messages
  static void success(String tag, String message, [dynamic data]) {
    if (kDebugMode) {
      final timestamp = _timestamp();
      final formattedMessage = '[$_cyan$_appName$_reset][$_green$tag$_reset] $timestamp - $_green✅ $message$_reset';
      debugPrint(formattedMessage);
      if (data != null) {
        debugPrint('  $_green✅ Data: $data$_reset');
      }
    }
  }

  /// Log API calls
  static void api(String method, String endpoint, {dynamic request, dynamic response, int? statusCode}) {
    if (kDebugMode) {
      final timestamp = _timestamp();
      final color = _getStatusCodeColor(statusCode);

      debugPrint('[$_cyan$_appName$_reset][$_magenta API$_reset] $timestamp - $color$method $endpoint$_reset');

      if (statusCode != null) {
        debugPrint('  ${color}Status: $statusCode$_reset');
      }

      if (request != null) {
        debugPrint('  ${color}Request: $request$_reset');
      }

      if (response != null) {
        debugPrint('  ${color}Response: $response$_reset');
      }
    }
  }

  /// Log navigation events
  static void navigation(String from, String to, [dynamic arguments]) {
    if (kDebugMode) {
      final timestamp = _timestamp();
      debugPrint('[$_cyan$_appName$_reset][$_blue NAVIGATION$_reset] $timestamp - $_blue🧭 $from → $to$_reset');
      if (arguments != null) {
        debugPrint('  $_blue🧭 Arguments: $arguments$_reset');
      }
    }
  }

  /// Log user actions
  static void action(String action, [dynamic data]) {
    if (kDebugMode) {
      final timestamp = _timestamp();
      debugPrint('[$_cyan$_appName$_reset][$_magenta USER$_reset] $timestamp - $_magenta👤 $action$_reset');
      if (data != null) {
        debugPrint('  $_magenta👤 Data: $data$_reset');
      }
    }
  }

  /// Get formatted timestamp
  static String _timestamp() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}.${now.millisecond.toString().padLeft(3, '0')}';
  }

  /// Get color based on HTTP status code
  static String _getStatusCodeColor(int? statusCode) {
    if (statusCode == null) return _white;
    if (statusCode >= 200 && statusCode < 300) return _green;
    if (statusCode >= 300 && statusCode < 400) return _yellow;
    if (statusCode >= 400) return _red;
    return _white;
  }

  /// Create a divider for visual separation
  static void divider() {
    if (kDebugMode) {
      debugPrint('$_cyan━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$_reset');
    }
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/env_config.dart';
import '../core/utils/logger.dart';

/// Supabase Configuration Service
/// Handles initialization and configuration of Supabase client
class SupabaseConfig {
  static const String _tag = 'SupabaseConfig';
  static SupabaseClient? _client;

  /// Get Supabase client instance
  static SupabaseClient get client {
    if (_client == null) {
      throw Exception('Supabase not initialized. Call initialize() first.');
    }
    return _client!;
  }

  /// Initialize Supabase
  static Future<void> initialize() async {
    try {
      AppLogger.info(_tag, 'Initializing Supabase...');

      if (!EnvConfig.hasSupabaseConfig) {
        throw Exception('Supabase configuration not found in environment variables');
      }

      await Supabase.initialize(
        url: EnvConfig.supabaseUrl,
        anonKey: EnvConfig.supabaseAnonKey,
        debug: EnvConfig.isDebugMode,
      );

      _client = Supabase.instance.client;
      AppLogger.success(_tag, 'Supabase initialized successfully');
      
      // Test connection
      await _testConnection();
      
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to initialize Supabase', e, stackTrace);
      rethrow;
    }
  }

  /// Test Supabase connection
  static Future<void> _testConnection() async {
    try {
      AppLogger.debug(_tag, 'Testing Supabase connection...');
      
      // Simple query to test connection
      await _client!.from('users').select('count').count();
      
      AppLogger.success(_tag, 'Supabase connection test successful');
    } catch (e) {
      AppLogger.warning(_tag, 'Supabase connection test failed (this is normal if tables don\'t exist yet): $e');
    }
  }

  /// Get authenticated user
  static User? get currentUser => _client?.auth.currentUser;

  /// Check if user is authenticated
  static bool get isAuthenticated => currentUser != null;

  /// Get user ID
  static String? get userId => currentUser?.id;

  /// Sign out current user
  static Future<void> signOut() async {
    try {
      AppLogger.info(_tag, 'Signing out user...');
      await _client?.auth.signOut();
      AppLogger.success(_tag, 'User signed out successfully');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to sign out user', e, stackTrace);
      rethrow;
    }
  }

  /// Dispose resources
  static void dispose() {
    AppLogger.debug(_tag, 'Disposing Supabase client');
    _client = null;
  }
}
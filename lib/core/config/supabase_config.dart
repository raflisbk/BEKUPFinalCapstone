import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Supabase configuration and initialization
/// 
/// FREE TIER BENEFITS:
/// - 2 projects
/// - 500MB database storage
/// - 1GB file storage
/// - 50MB file uploads
/// - Unlimited API requests
/// - Unlimited authentication users
/// - Unlimited realtime connections
/// 
/// ZERO COSTS - No hidden charges or usage limits on core features
class SupabaseConfig {
  static late Supabase _instance;
  static SupabaseClient get client => _instance.client;
  
  /// Initialize Supabase with environment variables
  static Future<void> initialize() async {
    final supabaseUrl = dotenv.env['SUPABASE_URL'];
    final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];
    
    if (supabaseUrl == null || supabaseUrl.isEmpty) {
      throw Exception('SUPABASE_URL not found in environment variables');
    }
    
    if (supabaseAnonKey == null || supabaseAnonKey.isEmpty) {
      throw Exception('SUPABASE_ANON_KEY not found in environment variables');
    }
    
    _instance = await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      debug: dotenv.env['DEBUG_MODE'] == 'true',
    );
  }
  
  /// Get current authenticated user
  static User? get currentUser => client.auth.currentUser;
  
  /// Check if user is authenticated
  static bool get isAuthenticated => currentUser != null;
  
  /// Get user ID (safe)
  static String? get userId => currentUser?.id;
  
  /// Get user email (safe)
  static String? get userEmail => currentUser?.email;
  
  /// Database reference (replaces Firestore)
  static SupabaseQueryBuilder table(String tableName) {
    return client.from(tableName);
  }
  
  /// Storage reference (replaces Firebase Storage)
  static SupabaseStorageClient get storage => client.storage;
  
  /// Real-time subscription (replaces Firestore streams)
  static RealtimeChannel channel(String channelName) {
    return client.channel(channelName);
  }
  
  /// Auth reference
  static GoTrueClient get auth => client.auth;
  
  /// Dispose resources
  static Future<void> dispose() async {
    await client.dispose();
  }
}

/// Supabase service response wrapper
class SupabaseResponse<T> {
  final T? data;
  final String? error;
  final bool success;
  
  const SupabaseResponse({
    this.data,
    this.error,
    required this.success,
  });
  
  factory SupabaseResponse.success(T data) {
    return SupabaseResponse(
      data: data,
      success: true,
    );
  }
  
  factory SupabaseResponse.error(String error) {
    return SupabaseResponse(
      error: error,
      success: false,
    );
  }
}

/// Database table names - centralized constants
class SupabaseTables {
  static const String users = 'users';
  static const String trips = 'trips';
  static const String destinations = 'destinations';
  static const String reviews = 'reviews';
  static const String chats = 'chats';
  static const String messages = 'messages';
  static const String expenses = 'expenses';
  static const String itineraries = 'itineraries';
  static const String galleries = 'galleries';
  static const String bookings = 'bookings';
  static const String analytics = 'analytics';
}

/// Storage bucket names
class SupabaseBuckets {
  static const String avatars = 'avatars';
  static const String photos = 'photos';
  static const String videos = 'videos';
  static const String documents = 'documents';
}
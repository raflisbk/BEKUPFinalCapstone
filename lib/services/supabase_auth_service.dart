import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/utils/logger.dart';
import 'supabase_config.dart';

/// Supabase Authentication Service
/// Handles user authentication with Supabase Auth
class SupabaseAuthService {
  static const String _tag = 'SupabaseAuthService';
  static final SupabaseClient _client = SupabaseConfig.client;

  /// Stream of authentication state changes
  static Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Get current user
  static User? get currentUser => _client.auth.currentUser;

  /// Check if user is authenticated
  static bool get isAuthenticated => currentUser != null;

  /// Get user ID
  static String? get userId => currentUser?.id;

  /// Get user email
  static String? get userEmail => currentUser?.email;

  /// Get user metadata
  static Map<String, dynamic>? get userMetadata => currentUser?.userMetadata;

  /// Sign up with email and password
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    try {
      AppLogger.info(_tag, 'Signing up user: $email');

      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: fullName != null ? {'full_name': fullName} : null,
      );

      if (response.user != null) {
        AppLogger.success(_tag, 'User signed up successfully: ${response.user!.email}');
        
        // Create user profile in database
        await _createUserProfile(response.user!);
      }

      return response;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to sign up user', e, stackTrace);
      rethrow;
    }
  }

  /// Sign in with email and password
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      AppLogger.info(_tag, 'Signing in user: $email');

      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        AppLogger.success(_tag, 'User signed in successfully: ${response.user!.email}');
      }

      return response;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to sign in user', e, stackTrace);
      rethrow;
    }
  }

  /// Sign in with Google
  static Future<bool> signInWithGoogle() async {
    try {
      AppLogger.info(_tag, 'Signing in with Google...');

      final response = await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.relink://login-callback/',
      );

      AppLogger.success(_tag, 'Google OAuth initiated successfully');
      return response;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to sign in with Google', e, stackTrace);
      rethrow;
    }
  }

  /// Sign in with Apple
  static Future<bool> signInWithApple() async {
    try {
      AppLogger.info(_tag, 'Signing in with Apple...');

      final response = await _client.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: 'io.supabase.relink://login-callback/',
      );

      AppLogger.success(_tag, 'Apple OAuth initiated successfully');
      return response;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to sign in with Apple', e, stackTrace);
      rethrow;
    }
  }

  /// Sign out current user
  static Future<void> signOut() async {
    try {
      AppLogger.info(_tag, 'Signing out user...');
      await _client.auth.signOut();
      AppLogger.success(_tag, 'User signed out successfully');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to sign out user', e, stackTrace);
      rethrow;
    }
  }

  /// Reset password
  static Future<void> resetPassword(String email) async {
    try {
      AppLogger.info(_tag, 'Sending password reset email to: $email');

      await _client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.supabase.relink://reset-password/',
      );

      AppLogger.success(_tag, 'Password reset email sent successfully');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to send password reset email', e, stackTrace);
      rethrow;
    }
  }

  /// Update user password
  static Future<UserResponse> updatePassword(String newPassword) async {
    try {
      AppLogger.info(_tag, 'Updating user password...');

      final response = await _client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      AppLogger.success(_tag, 'Password updated successfully');
      return response;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to update password', e, stackTrace);
      rethrow;
    }
  }

  /// Update user metadata
  static Future<UserResponse> updateUserMetadata(Map<String, dynamic> data) async {
    try {
      AppLogger.info(_tag, 'Updating user metadata...');

      final response = await _client.auth.updateUser(
        UserAttributes(data: data),
      );

      AppLogger.success(_tag, 'User metadata updated successfully');
      return response;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to update user metadata', e, stackTrace);
      rethrow;
    }
  }

  /// Delete user account
  static Future<void> deleteAccount() async {
    try {
      AppLogger.info(_tag, 'Deleting user account...');

      // Note: Supabase doesn't have direct user deletion from client
      // This would need to be implemented via a server function
      throw UnimplementedError('Account deletion must be implemented via Supabase Edge Function');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to delete account', e, stackTrace);
      rethrow;
    }
  }

  /// Refresh session
  static Future<AuthResponse> refreshSession() async {
    try {
      AppLogger.debug(_tag, 'Refreshing user session...');

      final response = await _client.auth.refreshSession();
      
      if (response.user != null) {
        AppLogger.success(_tag, 'Session refreshed successfully');
      }

      return response;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to refresh session', e, stackTrace);
      rethrow;
    }
  }

  /// Create user profile in database
  static Future<void> _createUserProfile(User user) async {
    try {
      AppLogger.debug(_tag, 'Creating user profile in database...');

      await _client.from('users').insert({
        'id': user.id,
        'email': user.email,
        'full_name': user.userMetadata?['full_name'],
        'avatar_url': user.userMetadata?['avatar_url'],
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      AppLogger.success(_tag, 'User profile created successfully');
    } catch (e) {
      // Don't throw error if profile already exists
      AppLogger.warning(_tag, 'User profile creation failed (may already exist): $e');
    }
  }

  /// Get authentication headers for API calls
  static Map<String, String> getAuthHeaders() {
    final session = _client.auth.currentSession;
    if (session == null) {
      throw Exception('No active session. User must be authenticated.');
    }

    return {
      'Authorization': 'Bearer ${session.accessToken}',
      'Content-Type': 'application/json',
    };
  }

  /// Check if session is valid
  static bool isSessionValid() {
    final session = _client.auth.currentSession;
    if (session == null) return false;

    final expiresAt = DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000);
    return DateTime.now().isBefore(expiresAt);
  }
}
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';
import '../core/utils/logger.dart';

/// Supabase Authentication Service
/// 
/// FREE TIER BENEFITS:
/// - Unlimited authentication users
/// - Email/password authentication
/// - Social authentication (Google, Apple, etc.)
/// - Magic links
/// - JWT tokens
/// - Row Level Security (RLS)
/// - No usage limits or charges
class SupabaseAuthService {
  static const String _tag = 'SupabaseAuthService';
  
  static GoTrueClient get _auth => SupabaseConfig.auth;
  
  /// Get current user
  static User? get currentUser => _auth.currentUser;
  
  /// Check if user is authenticated
  static bool get isAuthenticated => currentUser != null;
  
  /// Get user ID
  static String? get userId => currentUser?.id;
  
  /// Get user email
  static String? get userEmail => currentUser?.email;
  
  /// Sign up with email and password
  static Future<SupabaseResponse<User>> signUpWithEmail({
    required String email,
    required String password,
    Map<String, dynamic>? userData,
  }) async {
    try {
      AppLogger.info(_tag, 'Signing up user with email: $email');
      
      final response = await _auth.signUp(
        email: email,
        password: password,
        data: userData,
      );
      
      if (response.user != null) {
        AppLogger.success(_tag, 'User signed up successfully');
        return SupabaseResponse.success(response.user!);
      } else {
        AppLogger.error(_tag, 'Sign up failed: No user returned');
        return SupabaseResponse.error('Sign up failed');
      }
    } on AuthException catch (e) {
      AppLogger.error(_tag, 'Auth error during sign up: ${e.message}');
      return SupabaseResponse.error(e.message);
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Unexpected error during sign up', e, stackTrace);
      return SupabaseResponse.error('Sign up failed: $e');
    }
  }
  
  /// Sign in with email and password
  static Future<SupabaseResponse<User>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      AppLogger.info(_tag, 'Signing in user with email: $email');
      
      final response = await _auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        AppLogger.success(_tag, 'User signed in successfully');
        return SupabaseResponse.success(response.user!);
      } else {
        AppLogger.error(_tag, 'Sign in failed: No user returned');
        return SupabaseResponse.error('Sign in failed');
      }
    } on AuthException catch (e) {
      AppLogger.error(_tag, 'Auth error during sign in: ${e.message}');
      return SupabaseResponse.error(e.message);
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Unexpected error during sign in', e, stackTrace);
      return SupabaseResponse.error('Sign in failed: $e');
    }
  }
  
  /// Sign in with Google
  static Future<SupabaseResponse<User>> signInWithGoogle() async {
    try {
      AppLogger.info(_tag, 'Signing in with Google');
      
      final response = await _auth.signInWithOAuth(
        Provider.google,
        redirectTo: 'io.supabase.flutter://login-callback/',
      );
      
      if (response) {
        // Wait for auth state change
        await Future.delayed(const Duration(seconds: 2));
        final user = currentUser;
        
        if (user != null) {
          AppLogger.success(_tag, 'Google sign in successful');
          return SupabaseResponse.success(user);
        }
      }
      
      AppLogger.error(_tag, 'Google sign in failed');
      return SupabaseResponse.error('Google sign in failed');
    } on AuthException catch (e) {
      AppLogger.error(_tag, 'Auth error during Google sign in: ${e.message}');
      return SupabaseResponse.error(e.message);
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Unexpected error during Google sign in', e, stackTrace);
      return SupabaseResponse.error('Google sign in failed: $e');
    }
  }
  
  /// Sign out
  static Future<SupabaseResponse<void>> signOut() async {
    try {
      AppLogger.info(_tag, 'Signing out user');
      
      await _auth.signOut();
      
      AppLogger.success(_tag, 'User signed out successfully');
      return SupabaseResponse.success(null);
    } on AuthException catch (e) {
      AppLogger.error(_tag, 'Auth error during sign out: ${e.message}');
      return SupabaseResponse.error(e.message);
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Unexpected error during sign out', e, stackTrace);
      return SupabaseResponse.error('Sign out failed: $e');
    }
  }
  
  /// Send password reset email
  static Future<SupabaseResponse<void>> resetPassword(String email) async {
    try {
      AppLogger.info(_tag, 'Sending password reset email to: $email');
      
      await _auth.resetPasswordForEmail(email);
      
      AppLogger.success(_tag, 'Password reset email sent');
      return SupabaseResponse.success(null);
    } on AuthException catch (e) {
      AppLogger.error(_tag, 'Auth error during password reset: ${e.message}');
      return SupabaseResponse.error(e.message);
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Unexpected error during password reset', e, stackTrace);
      return SupabaseResponse.error('Password reset failed: $e');
    }
  }
  
  /// Update user profile
  static Future<SupabaseResponse<User>> updateProfile({
    String? email,
    String? password,
    Map<String, dynamic>? data,
  }) async {
    try {
      AppLogger.info(_tag, 'Updating user profile');
      
      final response = await _auth.updateUser(
        UserAttributes(
          email: email,
          password: password,
          data: data,
        ),
      );
      
      if (response.user != null) {
        AppLogger.success(_tag, 'Profile updated successfully');
        return SupabaseResponse.success(response.user!);
      } else {
        AppLogger.error(_tag, 'Profile update failed: No user returned');
        return SupabaseResponse.error('Profile update failed');
      }
    } on AuthException catch (e) {
      AppLogger.error(_tag, 'Auth error during profile update: ${e.message}');
      return SupabaseResponse.error(e.message);
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Unexpected error during profile update', e, stackTrace);
      return SupabaseResponse.error('Profile update failed: $e');
    }
  }
  
  /// Listen to auth state changes
  static Stream<AuthState> get authStateChanges => _auth.onAuthStateChange;
  
  /// Delete user account
  static Future<SupabaseResponse<void>> deleteAccount() async {
    try {
      AppLogger.info(_tag, 'Deleting user account');
      
      // First delete user data from database
      if (userId != null) {
        await SupabaseConfig.table(SupabaseTables.users)
            .delete()
            .eq('id', userId!);
      }
      
      // Then delete auth account
      await _auth.admin.deleteUser(userId!);
      
      AppLogger.success(_tag, 'Account deleted successfully');
      return SupabaseResponse.success(null);
    } on AuthException catch (e) {
      AppLogger.error(_tag, 'Auth error during account deletion: ${e.message}');
      return SupabaseResponse.error(e.message);
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Unexpected error during account deletion', e, stackTrace);
      return SupabaseResponse.error('Account deletion failed: $e');
    }
  }
}

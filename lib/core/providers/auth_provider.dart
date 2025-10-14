import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../utils/logger.dart';
import '../../services/supabase_auth_service.dart';

class AuthProvider extends ChangeNotifier {
  static const String _tag = 'AuthProvider';

  // Current user
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isInitialized = false;
  bool _isGuest = false;
  
  // Auth state subscription
  StreamSubscription<AuthState>? _authSubscription;

  // Getters
  UserModel? get currentUser => _currentUser;
  UserModel? get user => _currentUser; // Alias for compatibility
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;
  bool get isInitialized => _isInitialized;
  bool get isGuest => _isGuest;

  AuthProvider() {
    _initializeAuth();
  }

  void _initializeAuth() {
    try {
      AppLogger.debug(_tag, 'Initializing auth provider');

      // Get current user if authenticated
      final user = SupabaseAuthService.currentUser;
      if (user != null) {
        _currentUser = UserModel.fromSupabase({'id': user.id, 'email': user.email, ...?user.userMetadata});
        AppLogger.debug(_tag, 'Found existing authenticated user');
      }

      // Listen to auth state changes
      _authSubscription = SupabaseAuthService.authStateChanges.listen(
        (AuthState state) {
          _handleAuthStateChange(state);
        },
      );

      _isInitialized = true;
      AppLogger.success(_tag, 'Auth provider initialized');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to initialize auth provider', e, stackTrace);
      _isInitialized = true; // Mark as initialized even if failed
    }
  }

  void _handleAuthStateChange(AuthState state) {
    AppLogger.debug(_tag, 'Auth state changed', {
      'event': state.event.name,
      'userId': state.session?.user.id,
    });

    if (state.session?.user != null) {
      // User signed in
      _currentUser = UserModel.fromSupabase({'id': state.session!.user.id, 'email': state.session!.user.email, ...?state.session!.user.userMetadata});
      _setError(null);
      AppLogger.success(_tag, 'User authenticated: ${_currentUser!.email}');
    } else {
      // User signed out
      _currentUser = null;
      AppLogger.info(_tag, 'User signed out');
    }

    notifyListeners();
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set error message
  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  // Sign up with email and password
  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    String? fullName,
  }) async {
    try {
      AppLogger.action('User attempting to sign up with email');
      
      _setLoading(true);
      _setError(null);

      final response = await SupabaseAuthService.signUp(
        email: email,
        password: password,
        fullName: fullName,
      );

      if (response.user != null) {
        AppLogger.success(_tag, 'User signed up successfully');
        return true;
      } else {
        _setError('Sign up failed. Please try again.');
        return false;
      }
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Sign up failed', e, stackTrace);
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Register with email (alias for compatibility)
  Future<bool> registerWithEmail({
    required String email,
    required String password,
    String? fullName,
  }) async {
    return await signUpWithEmail(
      email: email,
      password: password,
      fullName: fullName,
    );
  }

  // Sign in as guest
  Future<bool> signInAsGuest() async {
    try {
      AppLogger.action('User signing in as guest');
      
      _setLoading(true);
      _setError(null);

      // Create a guest user
      _currentUser = UserModel(
        id: 'guest_${DateTime.now().millisecondsSinceEpoch}',
        email: 'guest@relink.app',
        displayName: 'Guest User',
        isGuest: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      _isGuest = true;
      
      AppLogger.success(_tag, 'Guest sign in successful');
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Guest sign in failed', e, stackTrace);
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Sign in with email and password
  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      AppLogger.action('User attempting to sign in with email');
      
      _setLoading(true);
      _setError(null);

      final response = await SupabaseAuthService.signIn(
        email: email,
        password: password,
      );

      if (response.user != null) {
        AppLogger.success(_tag, 'User signed in successfully');
        return true;
      } else {
        _setError('Sign in failed. Please check your credentials.');
        return false;
      }
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Sign in failed', e, stackTrace);
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Sign in with Google
  Future<bool> signInWithGoogle() async {
    try {
      AppLogger.action('User attempting to sign in with Google');
      
      _setLoading(true);
      _setError(null);

      // Check if Google Sign-In is available
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        AppLogger.warning(_tag, 'Google sign in cancelled by user');
        return false;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final AuthResponse response = await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken,
      );

      if (response.user != null) {
        AppLogger.success(_tag, 'Google sign in successful');
        return true;
      } else {
        _setError('Google sign in failed. Please try again.');
        return false;
      }
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Google sign in failed', e, stackTrace);
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      AppLogger.action('User requesting password reset');
      
      _setLoading(true);
      _setError(null);

      await SupabaseAuthService.resetPassword(email);
      
      AppLogger.success(_tag, 'Password reset email sent');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Password reset failed', e, stackTrace);
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      AppLogger.action('User signing out');
      
      _setLoading(true);
      _setError(null);

      if (_isGuest) {
        // Just clear guest state
        _currentUser = null;
        _isGuest = false;
      } else {
        await SupabaseAuthService.signOut();
      }
      
      // Clear local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      AppLogger.success(_tag, 'User signed out successfully');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Sign out failed', e, stackTrace);
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Delete account
  Future<bool> deleteAccount() async {
    try {
      AppLogger.action('User deleting account');
      
      _setLoading(true);
      _setError(null);

      await SupabaseAuthService.deleteAccount();
      
      AppLogger.success(_tag, 'Account deleted successfully');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Account deletion failed', e, stackTrace);
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  @override
  void dispose() {
    AppLogger.debug(_tag, 'Disposing auth provider');
    _authSubscription?.cancel();
    super.dispose();
  }
}
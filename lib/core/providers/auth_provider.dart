import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger.dart';

class AuthProvider with ChangeNotifier {
  static const String _tag = 'AuthProvider';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? _user;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isAuthenticated = false;

  // Getters
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _isAuthenticated;
  bool get isGuest => _user == null && _isAuthenticated;

  AuthProvider() {
    _initAuth();
  }

  // Initialize auth state listener
  Future<void> _initAuth() async {
    AppLogger.debug(_tag, 'Initializing auth provider');

    // Listen to auth state changes
    _auth.authStateChanges().listen((User? user) {
      AppLogger.debug(_tag, 'Auth state changed', {
        'userId': user?.uid ?? 'null',
        'email': user?.email ?? 'null',
      });

      _user = user;
      _isAuthenticated = user != null;
      notifyListeners();
    });

    // Check for persistent login
    await _checkPersistentLogin();
  }

  // Check if user was logged in before
  Future<void> _checkPersistentLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final wasLoggedIn = prefs.getBool('was_logged_in') ?? false;

      if (wasLoggedIn && _user == null) {
        AppLogger.warning(_tag, 'User was logged in but session expired');
      }

      AppLogger.debug(_tag, 'Persistent login check complete', {
        'wasLoggedIn': wasLoggedIn,
        'currentUser': _user != null,
      });
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to check persistent login', e, stackTrace);
    }
  }

  // Set loading state
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Set error message
  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  // Clear error message
  void clearError() {
    _setError(null);
  }

  // Register with email and password
  Future<bool> registerWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      AppLogger.action('User attempting registration', {'email': email});
      _setLoading(true);
      _setError(null);

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await credential.user?.updateDisplayName(name);

      // Send email verification
      await credential.user?.sendEmailVerification();

      // Save login state
      await _savePersistentLogin();

      AppLogger.success(_tag, 'Registration successful', {
        'userId': credential.user?.uid,
        'email': email,
      });

      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e, stackTrace) {
      AppLogger.error(_tag, 'Registration failed', e, stackTrace);
      _setError(_getErrorMessage(e.code));
      _setLoading(false);
      return false;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Unexpected registration error', e, stackTrace);
      _setError('An unexpected error occurred. Please try again.');
      _setLoading(false);
      return false;
    }
  }

  // Sign in with email and password
  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      AppLogger.action('User attempting login', {'email': email});
      _setLoading(true);
      _setError(null);

      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save login state
      await _savePersistentLogin();

      AppLogger.success(_tag, 'Login successful', {
        'userId': credential.user?.uid,
        'email': email,
      });

      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e, stackTrace) {
      AppLogger.error(_tag, 'Login failed', e, stackTrace);
      _setError(_getErrorMessage(e.code));
      _setLoading(false);
      return false;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Unexpected login error', e, stackTrace);
      _setError('An unexpected error occurred. Please try again.');
      _setLoading(false);
      return false;
    }
  }

  // Sign in with Google
  Future<bool> signInWithGoogle() async {
    try {
      AppLogger.action('User attempting Google Sign-In');
      _setLoading(true);
      _setError(null);

      // Trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        AppLogger.warning(_tag, 'Google Sign-In cancelled by user');
        _setLoading(false);
        return false;
      }

      // Obtain auth details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      final userCredential = await _auth.signInWithCredential(credential);

      // Save login state
      await _savePersistentLogin();

      AppLogger.success(_tag, 'Google Sign-In successful', {
        'userId': userCredential.user?.uid,
        'email': userCredential.user?.email,
      });

      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e, stackTrace) {
      AppLogger.error(_tag, 'Google Sign-In failed', e, stackTrace);
      _setError(_getErrorMessage(e.code));
      _setLoading(false);
      return false;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Unexpected Google Sign-In error', e, stackTrace);
      _setError('Failed to sign in with Google. Please try again.');
      _setLoading(false);
      return false;
    }
  }

  // Sign in as guest
  Future<void> signInAsGuest() async {
    try {
      AppLogger.action('User signed in as guest');
      _isAuthenticated = true;

      // Don't save persistent login for guest mode
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('was_logged_in', false);
      await prefs.setBool('is_guest', true);

      notifyListeners();
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to set guest mode', e, stackTrace);
    }
  }

  // Send password reset email
  Future<bool> resetPassword(String email) async {
    try {
      AppLogger.action('User requested password reset', {'email': email});
      _setLoading(true);
      _setError(null);

      await _auth.sendPasswordResetEmail(email: email);

      AppLogger.success(_tag, 'Password reset email sent', {'email': email});
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e, stackTrace) {
      AppLogger.error(_tag, 'Password reset failed', e, stackTrace);
      _setError(_getErrorMessage(e.code));
      _setLoading(false);
      return false;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Unexpected password reset error', e, stackTrace);
      _setError('Failed to send password reset email. Please try again.');
      _setLoading(false);
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      AppLogger.action('User signing out');
      _setLoading(true);

      // Sign out from Firebase
      await _auth.signOut();

      // Sign out from Google
      await _googleSignIn.signOut();

      // Clear persistent login
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('was_logged_in', false);
      await prefs.setBool('is_guest', false);

      _user = null;
      _isAuthenticated = false;

      AppLogger.success(_tag, 'Sign out successful');
      _setLoading(false);
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Sign out failed', e, stackTrace);
      _setLoading(false);
    }
  }

  // Save persistent login state
  Future<void> _savePersistentLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('was_logged_in', true);
      await prefs.setBool('is_guest', false);

      AppLogger.debug(_tag, 'Persistent login saved');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to save persistent login', e, stackTrace);
    }
  }

  // Get user-friendly error messages
  String _getErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already registered. Please sign in instead.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled. Please contact support.';
      case 'weak-password':
        return 'Password is too weak. Please use at least 6 characters.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'user-not-found':
        return 'No account found with this email. Please register first.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        return 'An error occurred. Please try again.';
    }
  }

  @override
  void dispose() {
    AppLogger.debug(_tag, 'Disposing auth provider');
    super.dispose();
  }
}

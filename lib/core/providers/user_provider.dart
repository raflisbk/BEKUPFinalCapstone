import 'package:flutter/foundation.dart';
import '../stubs/firebase_stubs.dart';
import '../models/user_model.dart';
import '../utils/logger.dart';

class UserProvider with ChangeNotifier {
  static const String _tag = 'UserProvider';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

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

  // Clear error
  void clearError() {
    _setError(null);
  }

  // Fetch current user profile
  Future<void> fetchUserProfile() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        AppLogger.warning(_tag, 'Cannot fetch profile: No user logged in');
        return;
      }

      AppLogger.debug(_tag, 'Fetching user profile', {'userId': userId});
      _setLoading(true);
      _setError(null);

      final doc = await _firestore.collection('users').doc(userId).get();

      if (doc.exists) {
        _currentUser = UserModel.fromFirestore(doc);
        AppLogger.success(_tag, 'User profile fetched successfully', {
          'userId': userId,
          'name': _currentUser?.displayName,
        });
      } else {
        AppLogger.warning(_tag, 'User profile not found in Firestore', {
          'userId': userId,
        });
        // Create profile if doesn't exist
        await _createUserProfile();
      }

      _setLoading(false);
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to fetch user profile', e, stackTrace);
      _setError('Failed to load profile. Please try again.');
      _setLoading(false);
    }
  }

  // Create user profile in Firestore
  Future<void> _createUserProfile() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      AppLogger.debug(_tag, 'Creating user profile', {'userId': user.uid});

      final newUser = UserModel(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? 'User',
        photoUrl: user.photoURL,
        bio: '',
        interests: [],
        languages: ['English'],
        isGuide: false,
        isVerified: false,
        rating: 0.0,
        reviewCount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(user.uid).set(newUser.toMap());

      _currentUser = newUser;

      AppLogger.success(_tag, 'User profile created successfully', {
        'userId': user.uid,
      });
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to create user profile', e, stackTrace);
    }
  }

  // Update user profile
  Future<bool> updateProfile(UserModel updatedUser) async {
    try {
      AppLogger.action('User updating profile', {'userId': updatedUser.uid});
      _setLoading(true);
      _setError(null);

      final updateData = updatedUser.toMap();
      updateData['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore
          .collection('users')
          .doc(updatedUser.uid)
          .update(updateData);

      _currentUser = updatedUser.copyWith(updatedAt: DateTime.now());

      AppLogger.success(_tag, 'Profile updated successfully', {
        'userId': updatedUser.uid,
      });

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to update profile', e, stackTrace);
      _setError('Failed to update profile. Please try again.');
      _setLoading(false);
      return false;
    }
  }

  // Toggle guide mode
  Future<bool> toggleGuideMode(bool isGuide) async {
    try {
      if (_currentUser == null) return false;

      AppLogger.action('User toggling guide mode', {'isGuide': isGuide});
      _setLoading(true);

      await _firestore.collection('users').doc(_currentUser!.uid).update({
        'isGuide': isGuide,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _currentUser = _currentUser!.copyWith(
        isGuide: isGuide,
        updatedAt: DateTime.now(),
      );

      AppLogger.success(_tag, 'Guide mode toggled', {'isGuide': isGuide});
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to toggle guide mode', e, stackTrace);
      _setLoading(false);
      return false;
    }
  }

  // Clear user data (on logout)
  void clearUser() {
    AppLogger.debug(_tag, 'Clearing user data');
    _currentUser = null;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    AppLogger.debug(_tag, 'Disposing user provider');
    super.dispose();
  }
}

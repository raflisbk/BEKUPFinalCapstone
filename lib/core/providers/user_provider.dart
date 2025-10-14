import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../utils/logger.dart';
import '../../services/user_service.dart';
import '../../services/supabase_auth_service.dart';
import '../../services/supabase_database_service.dart';

class UserProvider with ChangeNotifier {
  static const String _tag = 'UserProvider';

  // Service instance
  final UserService _userService = UserService.instance;

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
      final userId = SupabaseAuthService.currentUser?.id;
      if (userId == null) {
        AppLogger.warning(_tag, 'Cannot fetch profile: No user logged in');
        return;
      }

      AppLogger.debug(_tag, 'Fetching user profile', {'userId': userId});
      _setLoading(true);
      _setError(null);

      final userMap = await _userService.getUserProfile(userId);

      if (userMap != null) {
        _currentUser = UserModel.fromMap(userMap);
        AppLogger.success(_tag, 'User profile fetched successfully', {
          'userId': userId,
          'name': _currentUser?.displayName,
        });
      } else {
        AppLogger.warning(_tag, 'User profile not found', {
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

  // Create user profile
  Future<void> _createUserProfile() async {
    try {
      final user = SupabaseAuthService.currentUser;
      if (user == null) return;

      AppLogger.debug(_tag, 'Creating user profile', {'userId': user.id});

      final newUser = UserModel(
        uid: user.id,
        email: user.email ?? '',
        displayName: user.userMetadata?['full_name'] ?? 'User',
        photoUrl: user.userMetadata?['avatar_url'],
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

      await _userService.createUserProfile(
        userId: user.id,
        email: user.email ?? '',
        fullName: user.userMetadata?['full_name'] ?? 'User',
        avatarUrl: user.userMetadata?['avatar_url'],
      );

      _currentUser = newUser;

      AppLogger.success(_tag, 'User profile created successfully', {
        'userId': user.id,
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

      // Update profile using individual parameters
      await _userService.updateUserProfile(
        fullName: updatedUser.displayName,
        bio: updatedUser.bio,
        // Note: Other fields would need to be added based on UserModel structure
      );

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

      // Use database service directly for custom fields
      await SupabaseDatabaseService.update(
        table: 'users',
        id: _currentUser!.uid,
        data: {
          'is_guide': isGuide,
          'updated_at': DateTime.now().toIso8601String(),
        },
      );

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
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/utils/logger.dart';
import 'supabase_config.dart';
import 'supabase_database_service.dart';

/// User Service
/// Handles user profile management and related operations
class UserService {
  static const String _tag = 'UserService';
  static const String _tableName = 'users';

  // Singleton pattern
  static UserService? _instance;
  static UserService get instance => _instance ??= UserService._internal();
  
  UserService._internal();

  // ===============================
  // USER PROFILE OPERATIONS
  // ===============================

  /// Get current user profile
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Getting current user profile: $userId');

      final data = await SupabaseDatabaseService.select(
        table: _tableName,
        filters: {'id': userId},
      );

      if (data.isEmpty) {
        AppLogger.warning(_tag, 'User profile not found in database');
        return null;
      }

      AppLogger.success(_tag, 'Retrieved current user profile');
      return data.first;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get current user profile', e, stackTrace);
      rethrow;
    }
  }

  /// Get user profile by ID
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      AppLogger.debug(_tag, 'Getting user profile: $userId');

      final data = await SupabaseDatabaseService.select(
        table: _tableName,
        filters: {'id': userId},
      );

      if (data.isEmpty) {
        AppLogger.warning(_tag, 'User profile not found: $userId');
        return null;
      }

      AppLogger.success(_tag, 'Retrieved user profile: $userId');
      return data.first;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get user profile', e, stackTrace);
      rethrow;
    }
  }

  /// Create user profile
  Future<Map<String, dynamic>> createUserProfile({
    required String userId,
    required String email,
    String? fullName,
    String? avatarUrl,
    String? phone,
    DateTime? dateOfBirth,
    String? bio,
    String? location,
  }) async {
    try {
      AppLogger.debug(_tag, 'Creating user profile: $userId');

      final profileData = {
        'id': userId,
        'email': email,
        'full_name': fullName,
        'avatar_url': avatarUrl,
        'phone': phone,
        'date_of_birth': dateOfBirth?.toIso8601String(),
        'bio': bio,
        'location': location,
        'is_verified': false,
        'is_active': true,
        'privacy_settings': {
          'profile_visibility': 'public',
          'show_email': false,
          'show_phone': false,
          'allow_messages': true,
        },
        'preferences': {
          'language': 'id',
          'currency': 'IDR',
          'timezone': 'Asia/Jakarta',
          'notifications_enabled': true,
        },
        'stats': {
          'trips_count': 0,
          'reviews_count': 0,
          'photos_count': 0,
          'followers_count': 0,
          'following_count': 0,
        },
      };

      final result = await SupabaseDatabaseService.insert(
        table: _tableName,
        data: profileData,
      );

      AppLogger.success(_tag, 'User profile created successfully: $userId');
      return result;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to create user profile', e, stackTrace);
      rethrow;
    }
  }

  /// Update user profile
  Future<Map<String, dynamic>> updateUserProfile({
    String? fullName,
    String? avatarUrl,
    String? phone,
    DateTime? dateOfBirth,
    String? bio,
    String? location,
  }) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Updating user profile: $userId');

      final updateData = <String, dynamic>{};
      
      if (fullName != null) updateData['full_name'] = fullName;
      if (avatarUrl != null) updateData['avatar_url'] = avatarUrl;
      if (phone != null) updateData['phone'] = phone;
      if (dateOfBirth != null) updateData['date_of_birth'] = dateOfBirth.toIso8601String();
      if (bio != null) updateData['bio'] = bio;
      if (location != null) updateData['location'] = location;

      if (updateData.isEmpty) {
        throw Exception('No data provided for update');
      }

      final result = await SupabaseDatabaseService.update(
        table: _tableName,
        id: userId,
        data: updateData,
      );

      AppLogger.success(_tag, 'User profile updated successfully');
      return result;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to update user profile', e, stackTrace);
      rethrow;
    }
  }

  /// Update user preferences
  Future<void> updateUserPreferences(Map<String, dynamic> preferences) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Updating user preferences: $userId');

      // Get current profile to merge preferences
      final currentProfile = await getCurrentUserProfile();
      if (currentProfile == null) {
        throw Exception('User profile not found');
      }

      final currentPreferences = Map<String, dynamic>.from(
        currentProfile['preferences'] ?? {}
      );
      currentPreferences.addAll(preferences);

      await SupabaseDatabaseService.update(
        table: _tableName,
        id: userId,
        data: {'preferences': currentPreferences},
      );

      AppLogger.success(_tag, 'User preferences updated successfully');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to update user preferences', e, stackTrace);
      rethrow;
    }
  }

  /// Update privacy settings
  Future<void> updatePrivacySettings(Map<String, dynamic> privacySettings) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Updating privacy settings: $userId');

      // Get current profile to merge privacy settings
      final currentProfile = await getCurrentUserProfile();
      if (currentProfile == null) {
        throw Exception('User profile not found');
      }

      final currentPrivacy = Map<String, dynamic>.from(
        currentProfile['privacy_settings'] ?? {}
      );
      currentPrivacy.addAll(privacySettings);

      await SupabaseDatabaseService.update(
        table: _tableName,
        id: userId,
        data: {'privacy_settings': currentPrivacy},
      );

      AppLogger.success(_tag, 'Privacy settings updated successfully');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to update privacy settings', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // USER STATS OPERATIONS
  // ===============================

  /// Update user stats
  Future<void> updateUserStats({
    int? tripsCount,
    int? reviewsCount,
    int? photosCount,
    int? followersCount,
    int? followingCount,
  }) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Updating user stats: $userId');

      // Get current profile to merge stats
      final currentProfile = await getCurrentUserProfile();
      if (currentProfile == null) {
        throw Exception('User profile not found');
      }

      final currentStats = Map<String, dynamic>.from(
        currentProfile['stats'] ?? {}
      );

      if (tripsCount != null) currentStats['trips_count'] = tripsCount;
      if (reviewsCount != null) currentStats['reviews_count'] = reviewsCount;
      if (photosCount != null) currentStats['photos_count'] = photosCount;
      if (followersCount != null) currentStats['followers_count'] = followersCount;
      if (followingCount != null) currentStats['following_count'] = followingCount;

      await SupabaseDatabaseService.update(
        table: _tableName,
        id: userId,
        data: {'stats': currentStats},
      );

      AppLogger.success(_tag, 'User stats updated successfully');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to update user stats', e, stackTrace);
      rethrow;
    }
  }

  /// Increment user stat
  Future<void> incrementUserStat(String statName, {int increment = 1}) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Incrementing user stat: $statName by $increment');

      final currentProfile = await getCurrentUserProfile();
      if (currentProfile == null) {
        throw Exception('User profile not found');
      }

      final currentStats = Map<String, dynamic>.from(
        currentProfile['stats'] ?? {}
      );

      final currentValue = (currentStats[statName] as int?) ?? 0;
      currentStats[statName] = currentValue + increment;

      await SupabaseDatabaseService.update(
        table: _tableName,
        id: userId,
        data: {'stats': currentStats},
      );

      AppLogger.success(_tag, 'User stat incremented: $statName = ${currentStats[statName]}');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to increment user stat', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // USER SEARCH & DISCOVERY
  // ===============================

  /// Search users by name or email
  static Future<List<Map<String, dynamic>>> searchUsers({
    required String query,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      AppLogger.debug(_tag, 'Searching users: $query');

      final users = await SupabaseDatabaseService.textSearch(
        table: _tableName,
        searchTerm: query,
        searchColumns: ['full_name', 'email'],
        limit: limit,
      );

      // Filter out sensitive information
      final filteredUsers = users.map((user) {
        return {
          'id': user['id'],
          'full_name': user['full_name'],
          'avatar_url': user['avatar_url'],
          'bio': user['bio'],
          'stats': user['stats'],
          'is_verified': user['is_verified'],
          'created_at': user['created_at'],
        };
      }).toList();

      AppLogger.success(_tag, 'Found ${filteredUsers.length} users');
      return filteredUsers;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to search users', e, stackTrace);
      rethrow;
    }
  }

  /// Get featured users (most active, verified, etc.)
  static Future<List<Map<String, dynamic>>> getFeaturedUsers({int limit = 10}) async {
    try {
      AppLogger.debug(_tag, 'Getting featured users');

      final users = await SupabaseDatabaseService.select(
        table: _tableName,
        columns: 'id, full_name, avatar_url, bio, stats, is_verified, created_at',
        orderBy: 'is_verified',
        ascending: false,
        limit: limit,
      );

      AppLogger.success(_tag, 'Retrieved ${users.length} featured users');
      return users;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get featured users', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // USER ACCOUNT MANAGEMENT
  // ===============================

  /// Deactivate user account
  static Future<void> deactivateAccount() async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.warning(_tag, 'Deactivating user account: $userId');

      await SupabaseDatabaseService.update(
        table: _tableName,
        id: userId,
        data: {
          'is_active': false,
          'deactivated_at': DateTime.now().toIso8601String(),
        },
      );

      AppLogger.warning(_tag, 'User account deactivated successfully');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to deactivate account', e, stackTrace);
      rethrow;
    }
  }

  /// Reactivate user account
  static Future<void> reactivateAccount() async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.info(_tag, 'Reactivating user account: $userId');

      await SupabaseDatabaseService.update(
        table: _tableName,
        id: userId,
        data: {
          'is_active': true,
          'deactivated_at': null,
          'reactivated_at': DateTime.now().toIso8601String(),
        },
      );

      AppLogger.success(_tag, 'User account reactivated successfully');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to reactivate account', e, stackTrace);
      rethrow;
    }
  }

  /// Delete user data (GDPR compliance)
  static Future<void> deleteUserData() async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.warning(_tag, 'Deleting user data: $userId');

      // This would typically trigger a cascade delete in the database
      // or call an edge function to handle GDPR deletion
      await SupabaseDatabaseService.delete(
        table: _tableName,
        id: userId,
      );

      AppLogger.warning(_tag, 'User data deleted successfully');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to delete user data', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // REAL-TIME SUBSCRIPTIONS
  // ===============================

  /// Subscribe to current user profile changes
  static RealtimeChannel subscribeToCurrentUser({
    required void Function(Map<String, dynamic> user) onUpdate,
  }) {
    final userId = SupabaseConfig.userId;
    if (userId == null) {
      throw Exception('No authenticated user found');
    }

    AppLogger.info(_tag, 'Subscribing to current user profile changes');

    return SupabaseDatabaseService.subscribeToTable(
      table: _tableName,
      filter: 'id=eq.$userId',
      onInsert: (payload) {
        // Not expected for current user
      },
      onUpdate: (payload) {
        onUpdate(payload.newRecord);
      },
      onDelete: (payload) {
        AppLogger.warning(_tag, 'Current user profile deleted');
      },
    );
  }

  // ===============================
  // UTILITY METHODS
  // ===============================

  /// Check if user profile exists
  Future<bool> userProfileExists(String userId) async {
    try {
      final profile = await getUserProfile(userId);
      return profile != null;
    } catch (e) {
      return false;
    }
  }

  /// Get user display name
  static String getUserDisplayName(Map<String, dynamic> user) {
    return user['full_name']?.toString() ?? 
           user['email']?.toString() ?? 
           'Unknown User';
  }

  /// Get user avatar URL with fallback
  static String getUserAvatarUrl(Map<String, dynamic> user) {
    return user['avatar_url']?.toString() ?? 
           'https://ui-avatars.com/api/?name=${getUserDisplayName(user)}&background=random';
  }
}
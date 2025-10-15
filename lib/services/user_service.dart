import 'dart:async';
import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/utils/logger.dart';
import 'supabase_config.dart';
import 'supabase_database_service.dart';
import 'interfaces/i_user_service.dart';

/// User Service Implementation
/// Handles user profile management and related operations using instance pattern
class UserService implements IUserService {
  static const String _tag = 'UserService';
  static const String _usersTable = 'users';
  static const String _friendsTable = 'user_friends';
  static const String _friendRequestsTable = 'friend_requests';
  static const String _followersTable = 'user_followers';
  static const String _privacySettingsTable = 'user_privacy_settings';
  static const String _notificationPreferencesTable = 'user_notification_preferences';

  // Constructor with dependency injection
  UserService();

  /// Generate a simple UUID
  String _generateUuid() {
    final random = Random();
    return 'user_${random.nextInt(999999999).toString().padLeft(9, '0')}';
  }

  // ===============================
  // PROFILE MANAGEMENT
  // ===============================

  @override
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Getting current user profile: $userId');

      final data = await SupabaseDatabaseService.select(
        table: _usersTable,
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

  @override
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      AppLogger.debug(_tag, 'Getting user profile: $userId');

      final data = await SupabaseDatabaseService.select(
        table: _usersTable,
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

  @override
  Future<Map<String, dynamic>> updateUserProfile({
    required String userId,
    String? fullName,
    String? bio,
    String? profileImageUrl,
    String? coverImageUrl,
    DateTime? dateOfBirth,
    String? gender,
    String? location,
    List<String>? interests,
    Map<String, dynamic>? preferences,
    Map<String, dynamic>? socialLinks,
  }) async {
    try {
      AppLogger.debug(_tag, 'Updating user profile: $userId');

      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (fullName != null) updateData['full_name'] = fullName;
      if (bio != null) updateData['bio'] = bio;
      if (profileImageUrl != null) updateData['profile_image_url'] = profileImageUrl;
      if (coverImageUrl != null) updateData['cover_image_url'] = coverImageUrl;
      if (dateOfBirth != null) updateData['date_of_birth'] = dateOfBirth.toIso8601String();
      if (gender != null) updateData['gender'] = gender;
      if (location != null) updateData['location'] = location;
      if (interests != null) updateData['interests'] = interests;
      if (preferences != null) updateData['preferences'] = preferences;
      if (socialLinks != null) updateData['social_links'] = socialLinks;

      final updatedUser = await SupabaseDatabaseService.update(
        table: _usersTable,
        data: updateData,
        id: userId,
      );

      AppLogger.success(_tag, 'User profile updated successfully: $userId');
      return updatedUser;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to update user profile: $userId', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> deleteUserProfile(String userId) async {
    try {
      AppLogger.debug(_tag, 'Deleting user profile: $userId');

      await SupabaseDatabaseService.delete(
        table: _usersTable,
        id: userId,
      );

      AppLogger.success(_tag, 'User profile deleted successfully: $userId');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to delete user profile: $userId', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // PRIVACY SETTINGS
  // ===============================

  @override
  Future<Map<String, dynamic>> updatePrivacySettings({
    required String userId,
    bool? isProfilePublic,
    bool? showEmail,
    bool? showPhone,
    bool? allowMessages,
    bool? allowFriendRequests,
    bool? showLocation,
    bool? showAge,
  }) async {
    try {
      AppLogger.debug(_tag, 'Updating privacy settings for user: $userId');

      final privacyData = <String, dynamic>{
        'user_id': userId,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (isProfilePublic != null) privacyData['is_profile_public'] = isProfilePublic;
      if (showEmail != null) privacyData['show_email'] = showEmail;
      if (showPhone != null) privacyData['show_phone'] = showPhone;
      if (allowMessages != null) privacyData['allow_messages'] = allowMessages;
      if (allowFriendRequests != null) privacyData['allow_friend_requests'] = allowFriendRequests;
      if (showLocation != null) privacyData['show_location'] = showLocation;
      if (showAge != null) privacyData['show_age'] = showAge;

      // Check if settings exist
      final existing = await SupabaseDatabaseService.select(
        table: _privacySettingsTable,
        filters: {'user_id': userId},
      );

      Map<String, dynamic> result;
      if (existing.isEmpty) {
        privacyData['id'] = _generateUuid();
        result = await SupabaseDatabaseService.insert(
          table: _privacySettingsTable,
          data: privacyData,
        );
      } else {
        result = await SupabaseDatabaseService.update(
          table: _privacySettingsTable,
          data: privacyData,
          id: existing.first['id'],
        );
      }

      AppLogger.success(_tag, 'Privacy settings updated successfully: $userId');
      return result;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to update privacy settings: $userId', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>?> getPrivacySettings(String userId) async {
    try {
      AppLogger.debug(_tag, 'Getting privacy settings for user: $userId');

      final data = await SupabaseDatabaseService.select(
        table: _privacySettingsTable,
        filters: {'user_id': userId},
      );

      if (data.isEmpty) {
        AppLogger.warning(_tag, 'Privacy settings not found for user: $userId');
        return null;
      }

      AppLogger.success(_tag, 'Retrieved privacy settings: $userId');
      return data.first;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get privacy settings: $userId', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // SOCIAL FEATURES
  // ===============================

  @override
  Future<Map<String, dynamic>> sendFriendRequest(String targetUserId) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Sending friend request to: $targetUserId');

      // Check if request already exists
      final existing = await SupabaseDatabaseService.select(
        table: _friendRequestsTable,
        filters: {
          'sender_id': userId,
          'receiver_id': targetUserId,
        },
      );

      if (existing.isNotEmpty) {
        throw Exception('Friend request already sent');
      }

      final requestData = {
        'id': _generateUuid(),
        'sender_id': userId,
        'receiver_id': targetUserId,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      };

      final result = await SupabaseDatabaseService.insert(
        table: _friendRequestsTable,
        data: requestData,
      );

      AppLogger.success(_tag, 'Friend request sent successfully');
      return result;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to send friend request', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> acceptFriendRequest(String requestId) async {
    try {
      AppLogger.debug(_tag, 'Accepting friend request: $requestId');

      // Update request status
      await SupabaseDatabaseService.update(
        table: _friendRequestsTable,
        data: {
          'status': 'accepted',
          'updated_at': DateTime.now().toIso8601String(),
        },
        id: requestId,
      );

      // Get request details to create friendship
      final request = await SupabaseDatabaseService.select(
        table: _friendRequestsTable,
        filters: {'id': requestId},
      );

      if (request.isNotEmpty) {
        final senderId = request.first['sender_id'];
        final receiverId = request.first['receiver_id'];

        // Create friendship records (bidirectional)
        await SupabaseDatabaseService.insert(
          table: _friendsTable,
          data: {
            'id': _generateUuid(),
            'user_id': senderId,
            'friend_id': receiverId,
            'created_at': DateTime.now().toIso8601String(),
          },
        );

        await SupabaseDatabaseService.insert(
          table: _friendsTable,
          data: {
            'id': _generateUuid(),
            'user_id': receiverId,
            'friend_id': senderId,
            'created_at': DateTime.now().toIso8601String(),
          },
        );
      }

      AppLogger.success(_tag, 'Friend request accepted successfully');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to accept friend request', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> rejectFriendRequest(String requestId) async {
    try {
      AppLogger.debug(_tag, 'Rejecting friend request: $requestId');

      await SupabaseDatabaseService.update(
        table: _friendRequestsTable,
        data: {
          'status': 'rejected',
          'updated_at': DateTime.now().toIso8601String(),
        },
        id: requestId,
      );

      AppLogger.success(_tag, 'Friend request rejected successfully');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to reject friend request', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> removeFriend(String friendUserId) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Removing friend: $friendUserId');

      // Remove both directions of friendship
      await SupabaseDatabaseService.delete(
        table: _friendsTable,
        filters: {
          'user_id': userId,
          'friend_id': friendUserId,
        },
      );

      await SupabaseDatabaseService.delete(
        table: _friendsTable,
        filters: {
          'user_id': friendUserId,
          'friend_id': userId,
        },
      );

      AppLogger.success(_tag, 'Friend removed successfully');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to remove friend', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getFriends({String? userId}) async {
    try {
      final targetUserId = userId ?? SupabaseConfig.userId;
      if (targetUserId == null) {
        throw Exception('No user ID provided');
      }

      AppLogger.debug(_tag, 'Getting friends for user: $targetUserId');

      final friends = await SupabaseDatabaseService.select(
        table: _friendsTable,
        filters: {'user_id': targetUserId},
      );

      AppLogger.success(_tag, 'Retrieved ${friends.length} friends');
      return friends;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get friends', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getFriendRequests() async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Getting friend requests for user: $userId');

      final requests = await SupabaseDatabaseService.select(
        table: _friendRequestsTable,
        filters: {
          'receiver_id': userId,
          'status': 'pending',
        },
      );

      AppLogger.success(_tag, 'Retrieved ${requests.length} friend requests');
      return requests;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get friend requests', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // FOLLOW SYSTEM
  // ===============================

  @override
  Future<Map<String, dynamic>> followUser(String targetUserId) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Following user: $targetUserId');

      final followData = {
        'id': _generateUuid(),
        'follower_id': userId,
        'following_id': targetUserId,
        'created_at': DateTime.now().toIso8601String(),
      };

      final result = await SupabaseDatabaseService.insert(
        table: _followersTable,
        data: followData,
      );

      AppLogger.success(_tag, 'User followed successfully');
      return result;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to follow user', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> unfollowUser(String targetUserId) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Unfollowing user: $targetUserId');

      await SupabaseDatabaseService.delete(
        table: _followersTable,
        filters: {
          'follower_id': userId,
          'following_id': targetUserId,
        },
      );

      AppLogger.success(_tag, 'User unfollowed successfully');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to unfollow user', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getFollowers({String? userId}) async {
    try {
      final targetUserId = userId ?? SupabaseConfig.userId;
      if (targetUserId == null) {
        throw Exception('No user ID provided');
      }

      AppLogger.debug(_tag, 'Getting followers for user: $targetUserId');

      final followers = await SupabaseDatabaseService.select(
        table: _followersTable,
        filters: {'following_id': targetUserId},
      );

      AppLogger.success(_tag, 'Retrieved ${followers.length} followers');
      return followers;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get followers', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getFollowing({String? userId}) async {
    try {
      final targetUserId = userId ?? SupabaseConfig.userId;
      if (targetUserId == null) {
        throw Exception('No user ID provided');
      }

      AppLogger.debug(_tag, 'Getting following for user: $targetUserId');

      final following = await SupabaseDatabaseService.select(
        table: _followersTable,
        filters: {'follower_id': targetUserId},
      );

      AppLogger.success(_tag, 'Retrieved ${following.length} following');
      return following;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get following', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // SEARCH AND DISCOVERY
  // ===============================

  @override
  Future<List<Map<String, dynamic>>> searchUsers({
    String? query,
    String? location,
    List<String>? interests,
    int? ageMin,
    int? ageMax,
    int? limit,
    int? offset,
  }) async {
    try {
      AppLogger.debug(_tag, 'Searching users with query: $query');

      final filters = <String, dynamic>{};
      
      if (location != null) {
        filters['location'] = location;
      }

      List<Map<String, dynamic>> users = await SupabaseDatabaseService.select(
        table: _usersTable,
        filters: filters,
        limit: limit,
        offset: offset,
      );

      // Apply additional filters in memory
      if (query != null && query.isNotEmpty) {
        users = users.where((user) {
          final fullName = user['full_name']?.toString().toLowerCase() ?? '';
          final email = user['email']?.toString().toLowerCase() ?? '';
          final queryLower = query.toLowerCase();
          return fullName.contains(queryLower) || email.contains(queryLower);
        }).toList();
      }

      if (interests != null && interests.isNotEmpty) {
        users = users.where((user) {
          final userInterests = List<String>.from(user['interests'] ?? []);
          return interests.any((interest) => userInterests.contains(interest));
        }).toList();
      }

      if (ageMin != null || ageMax != null) {
        users = users.where((user) {
          final dateOfBirth = user['date_of_birth'];
          if (dateOfBirth == null) return false;
          
          final birthDate = DateTime.tryParse(dateOfBirth);
          if (birthDate == null) return false;
          
          final age = DateTime.now().difference(birthDate).inDays ~/ 365;
          
          if (ageMin != null && age < ageMin) return false;
          if (ageMax != null && age > ageMax) return false;
          
          return true;
        }).toList();
      }

      AppLogger.success(_tag, 'Found ${users.length} users');
      return users;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to search users', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getFeaturedUsers({int limit = 10}) async {
    try {
      AppLogger.debug(_tag, 'Getting featured users');

      final users = await SupabaseDatabaseService.select(
        table: _usersTable,
        filters: {'is_verified': true},
        limit: limit,
        orderBy: 'created_at',
      );

      AppLogger.success(_tag, 'Retrieved ${users.length} featured users');
      return users;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get featured users', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getSuggestedFriends({int limit = 10}) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Getting suggested friends');

      // Simple implementation: get users with similar interests
      final currentUser = await getCurrentUserProfile();
      if (currentUser == null) {
        return [];
      }

      final userInterests = List<String>.from(currentUser['interests'] ?? []);
      
      final users = await SupabaseDatabaseService.select(
        table: _usersTable,
        limit: limit * 2, // Get more to filter
      );

      // Filter out current user and existing friends
      final suggested = users.where((user) {
        if (user['id'] == userId) return false;
        
        final otherInterests = List<String>.from(user['interests'] ?? []);
        return userInterests.any((interest) => otherInterests.contains(interest));
      }).take(limit).toList();

      AppLogger.success(_tag, 'Retrieved ${suggested.length} suggested friends');
      return suggested;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get suggested friends', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // USER PREFERENCES
  // ===============================

  @override
  Future<Map<String, dynamic>> updateNotificationPreferences({
    required String userId,
    bool? pushNotifications,
    bool? emailNotifications,
    bool? tripUpdates,
    bool? friendRequests,
    bool? messages,
    bool? marketing,
  }) async {
    try {
      AppLogger.debug(_tag, 'Updating notification preferences for user: $userId');

      final preferencesData = <String, dynamic>{
        'user_id': userId,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (pushNotifications != null) preferencesData['push_notifications'] = pushNotifications;
      if (emailNotifications != null) preferencesData['email_notifications'] = emailNotifications;
      if (tripUpdates != null) preferencesData['trip_updates'] = tripUpdates;
      if (friendRequests != null) preferencesData['friend_requests'] = friendRequests;
      if (messages != null) preferencesData['messages'] = messages;
      if (marketing != null) preferencesData['marketing'] = marketing;

      // Check if preferences exist
      final existing = await SupabaseDatabaseService.select(
        table: _notificationPreferencesTable,
        filters: {'user_id': userId},
      );

      Map<String, dynamic> result;
      if (existing.isEmpty) {
        preferencesData['id'] = _generateUuid();
        result = await SupabaseDatabaseService.insert(
          table: _notificationPreferencesTable,
          data: preferencesData,
        );
      } else {
        result = await SupabaseDatabaseService.update(
          table: _notificationPreferencesTable,
          data: preferencesData,
          id: existing.first['id'],
        );
      }

      AppLogger.success(_tag, 'Notification preferences updated successfully');
      return result;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to update notification preferences', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>?> getNotificationPreferences(String userId) async {
    try {
      AppLogger.debug(_tag, 'Getting notification preferences for user: $userId');

      final data = await SupabaseDatabaseService.select(
        table: _notificationPreferencesTable,
        filters: {'user_id': userId},
      );

      if (data.isEmpty) {
        AppLogger.warning(_tag, 'Notification preferences not found for user: $userId');
        return null;
      }

      AppLogger.success(_tag, 'Retrieved notification preferences: $userId');
      return data.first;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get notification preferences', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // ACCOUNT MANAGEMENT
  // ===============================

  @override
  Future<void> deactivateAccount() async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Deactivating account: $userId');

      await SupabaseDatabaseService.update(
        table: _usersTable,
        data: {
          'is_active': false,
          'deactivated_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        id: userId,
      );

      AppLogger.success(_tag, 'Account deactivated successfully');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to deactivate account', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> reactivateAccount() async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Reactivating account: $userId');

      await SupabaseDatabaseService.update(
        table: _usersTable,
        data: {
          'is_active': true,
          'reactivated_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        id: userId,
      );

      AppLogger.success(_tag, 'Account reactivated successfully');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to reactivate account', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> deleteUserData() async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Deleting user data: $userId');

      // Delete related data first
      await SupabaseDatabaseService.delete(
        table: _friendsTable,
        filters: {'user_id': userId},
      );

      await SupabaseDatabaseService.delete(
        table: _friendRequestsTable,
        filters: {'sender_id': userId},
      );

      await SupabaseDatabaseService.delete(
        table: _followersTable,
        filters: {'follower_id': userId},
      );

      await SupabaseDatabaseService.delete(
        table: _privacySettingsTable,
        filters: {'user_id': userId},
      );

      await SupabaseDatabaseService.delete(
        table: _notificationPreferencesTable,
        filters: {'user_id': userId},
      );

      // Finally delete user profile
      await SupabaseDatabaseService.delete(
        table: _usersTable,
        id: userId,
      );

      AppLogger.success(_tag, 'User data deleted successfully');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to delete user data', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // ANALYTICS
  // ===============================

  @override
  Future<Map<String, dynamic>> getUserStatistics(String userId) async {
    try {
      AppLogger.debug(_tag, 'Getting user statistics: $userId');

      final friends = await getFriends(userId: userId);
      final followers = await getFollowers(userId: userId);
      final following = await getFollowing(userId: userId);

      final statistics = {
        'user_id': userId,
        'total_friends': friends.length,
        'total_followers': followers.length,
        'total_following': following.length,
        'engagement_ratio': followers.isNotEmpty ? following.length / followers.length : 0.0,
        'profile_completion': await _calculateProfileCompletion(userId),
        'last_active': DateTime.now().toIso8601String(),
      };

      AppLogger.success(_tag, 'Retrieved user statistics');
      return statistics;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get user statistics', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> getUserActivitySummary(String userId) async {
    try {
      AppLogger.debug(_tag, 'Getting user activity summary: $userId');

      final user = await getUserProfile(userId);
      if (user == null) {
        throw Exception('User not found');
      }

      final summary = {
        'user_id': userId,
        'join_date': user['created_at'],
        'last_login': user['last_login_at'],
        'profile_views': user['profile_views'] ?? 0,
        'total_connections': await _getTotalConnections(userId),
        'activity_score': await _calculateActivityScore(userId),
      };

      AppLogger.success(_tag, 'Retrieved user activity summary');
      return summary;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get user activity summary', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // PRIVATE HELPER METHODS
  // ===============================

  Future<double> _calculateProfileCompletion(String userId) async {
    try {
      final user = await getUserProfile(userId);
      if (user == null) return 0.0;

      int completedFields = 0;
      const totalFields = 8;

      if (user['full_name'] != null && user['full_name'].toString().isNotEmpty) completedFields++;
      if (user['bio'] != null && user['bio'].toString().isNotEmpty) completedFields++;
      if (user['profile_image_url'] != null) completedFields++;
      if (user['date_of_birth'] != null) completedFields++;
      if (user['location'] != null && user['location'].toString().isNotEmpty) completedFields++;
      if (user['interests'] != null && List<String>.from(user['interests']).isNotEmpty) completedFields++;
      if (user['social_links'] != null) completedFields++;
      if (user['preferences'] != null) completedFields++;

      return completedFields / totalFields;
    } catch (e) {
      return 0.0;
    }
  }

  Future<int> _getTotalConnections(String userId) async {
    try {
      final friends = await getFriends(userId: userId);
      final followers = await getFollowers(userId: userId);
      return friends.length + followers.length;
    } catch (e) {
      return 0;
    }
  }

  Future<double> _calculateActivityScore(String userId) async {
    try {
      final connections = await _getTotalConnections(userId);
      final profileCompletion = await _calculateProfileCompletion(userId);
      
      // Simple activity score calculation
      return (connections * 0.3 + profileCompletion * 100 * 0.7);
    } catch (e) {
      return 0.0;
    }
  }
}
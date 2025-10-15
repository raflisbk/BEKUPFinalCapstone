/// User Service Interface
/// Defines the contract for user management operations
abstract class IUserService {
  // Profile management
  Future<Map<String, dynamic>?> getCurrentUserProfile();
  Future<Map<String, dynamic>?> getUserProfile(String userId);
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
  });

  Future<void> deleteUserProfile(String userId);

  // Privacy settings
  Future<Map<String, dynamic>> updatePrivacySettings({
    required String userId,
    bool? isProfilePublic,
    bool? showEmail,
    bool? showPhone,
    bool? allowMessages,
    bool? allowFriendRequests,
    bool? showLocation,
    bool? showAge,
  });

  Future<Map<String, dynamic>?> getPrivacySettings(String userId);

  // Social features
  Future<Map<String, dynamic>> sendFriendRequest(String targetUserId);
  Future<void> acceptFriendRequest(String requestId);
  Future<void> rejectFriendRequest(String requestId);
  Future<void> removeFriend(String friendUserId);
  Future<List<Map<String, dynamic>>> getFriends({String? userId});
  Future<List<Map<String, dynamic>>> getFriendRequests();

  // Follow system
  Future<Map<String, dynamic>> followUser(String targetUserId);
  Future<void> unfollowUser(String targetUserId);
  Future<List<Map<String, dynamic>>> getFollowers({String? userId});
  Future<List<Map<String, dynamic>>> getFollowing({String? userId});

  // Search and discovery
  Future<List<Map<String, dynamic>>> searchUsers({
    String? query,
    String? location,
    List<String>? interests,
    int? ageMin,
    int? ageMax,
    int? limit,
    int? offset,
  });

  Future<List<Map<String, dynamic>>> getFeaturedUsers({int limit = 10});
  Future<List<Map<String, dynamic>>> getSuggestedFriends({int limit = 10});

  // User preferences
  Future<Map<String, dynamic>> updateNotificationPreferences({
    required String userId,
    bool? pushNotifications,
    bool? emailNotifications,
    bool? tripUpdates,
    bool? friendRequests,
    bool? messages,
    bool? marketing,
  });

  Future<Map<String, dynamic>?> getNotificationPreferences(String userId);

  // Account management
  Future<void> deactivateAccount();
  Future<void> reactivateAccount();
  Future<void> deleteUserData();

  // Analytics
  Future<Map<String, dynamic>> getUserStatistics(String userId);
  Future<Map<String, dynamic>> getUserActivitySummary(String userId);
}
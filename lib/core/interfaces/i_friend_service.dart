import 'dart:async';

/// Interface for Friend Service
/// Defines the contract for friendship features like friend requests, connections, 
/// mutual friends, friend recommendations, and social networking
abstract class IFriendService {
  // ===============================
  // FRIEND REQUESTS
  // ===============================

  /// Send friend request
  Future<Map<String, dynamic>> sendFriendRequest({
    required String targetUserId,
    String? message,
    String requestType = 'friend',
  });

  /// Get pending friend requests (received)
  Future<List<Map<String, dynamic>>> getPendingFriendRequests({
    int limit = 20,
    int offset = 0,
  });

  /// Get sent friend requests
  Future<List<Map<String, dynamic>>> getSentFriendRequests({
    int limit = 20,
    int offset = 0,
  });

  /// Respond to friend request
  Future<Map<String, dynamic>> respondToFriendRequest({
    required String requestId,
    required bool accept,
  });

  /// Cancel friend request
  Future<void> cancelFriendRequest(String requestId);

  // ===============================
  // FRIENDSHIP MANAGEMENT
  // ===============================

  /// Get user's friends
  Future<List<Map<String, dynamic>>> getFriends({
    String? userId,
    String? searchQuery,
    String? sortBy, // 'newest', 'alphabetical', 'mutual'
    int limit = 50,
    int offset = 0,
  });

  /// Get mutual friends
  Future<List<Map<String, dynamic>>> getMutualFriends({
    required String userId1,
    required String userId2,
    int limit = 20,
  });

  /// Get mutual friends count
  Future<int> getMutualFriendsCount(String userId1, String userId2);

  /// Remove friend
  Future<void> removeFriend(String friendId);

  // ===============================
  // FRIEND RECOMMENDATIONS
  // ===============================

  /// Get friend suggestions
  Future<List<Map<String, dynamic>>> getFriendSuggestions({
    int limit = 20,
  });

  /// Dismiss friend suggestion
  Future<void> dismissFriendSuggestion(String suggestedUserId);

  // ===============================
  // BLOCKING FUNCTIONALITY
  // ===============================

  /// Block user
  Future<Map<String, dynamic>> blockUser({
    required String targetUserId,
    String? reason,
  });

  /// Unblock user
  Future<void> unblockUser(String targetUserId);

  /// Get blocked users
  Future<List<Map<String, dynamic>>> getBlockedUsers({
    int limit = 50,
  });

  /// Check if user is blocked
  Future<bool> isUserBlocked(String targetUserId);

  // ===============================
  // FRIENDSHIP STATUS
  // ===============================

  /// Get friendship status between two users
  Future<Map<String, dynamic>> getFriendshipStatus({
    required String targetUserId,
  });

  // ===============================
  // USER SEARCH
  // ===============================

  /// Search users by query
  Future<List<Map<String, dynamic>>> searchUsers({
    required String query,
    int limit = 20,
    int offset = 0,
  });
}
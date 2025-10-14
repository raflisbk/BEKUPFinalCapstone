import 'dart:async';
import '../core/utils/logger.dart';
import 'supabase_config.dart';
import 'supabase_database_service.dart';
import 'notification_service.dart';

/// Friend Service
/// Handles friendship features like friend requests, connections, mutual friends,
/// friend recommendations, and social networking
class FriendService {
  static const String _tag = 'FriendService';
  static const String _friendshipsTable = 'friendships';
  static const String _friendRequestsTable = 'friend_requests';
  static const String _blockedUsersTable = 'blocked_users';

  // Singleton pattern
  static FriendService? _instance;
  static FriendService get instance => _instance ??= FriendService._internal();
  
  FriendService._internal();

  // Notification service instance
  late final NotificationService _notificationService = NotificationService.instance;

  // Friendship status
  static const String statusPending = 'pending';
  static const String statusAccepted = 'accepted';
  static const String statusDeclined = 'declined';
  static const String statusBlocked = 'blocked';

  // Request types
  static const String requestTypeFriend = 'friend';
  static const String requestTypeFollow = 'follow';

  // Privacy settings
  static const String privacyPublic = 'public';
  static const String privacyFriends = 'friends';
  static const String privacyPrivate = 'private';

  // ===============================
  // FRIEND REQUESTS
  // ===============================

  /// Send friend request
  static Future<Map<String, dynamic>> sendFriendRequest({
    required String targetUserId,
    String? message,
    String requestType = requestTypeFriend,
  }) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      if (userId == targetUserId) {
        throw Exception('Cannot send friend request to yourself');
      }

      AppLogger.debug(_tag, 'Sending friend request to: $targetUserId');

      // Check if already friends
      final existingFriendship = await _getFriendship(userId, targetUserId);
      if (existingFriendship != null) {
        throw Exception('Already friends with this user');
      }

      // Check if request already exists
      final existingRequest = await _getExistingRequest(userId, targetUserId);
      if (existingRequest != null) {
        if (existingRequest['status'] == statusPending) {
          throw Exception('Friend request already sent');
        } else if (existingRequest['status'] == statusDeclined) {
          // Update existing declined request
          return await SupabaseDatabaseService.update(
            table: _friendRequestsTable,
            id: existingRequest['id'],
            data: {
              'status': statusPending,
              'message': message,
              'updated_at': DateTime.now().toIso8601String(),
            },
          );
        }
      }

      // Check if user is blocked
      final isBlocked = await _isUserBlocked(userId, targetUserId) || 
                      await _isUserBlocked(targetUserId, userId);
      if (isBlocked) {
        throw Exception('Cannot send friend request to this user');
      }

      // Create friend request
      final requestData = {
        'sender_id': userId,
        'receiver_id': targetUserId,
        'request_type': requestType,
        'status': statusPending,
        'message': message,
        'sent_at': DateTime.now().toIso8601String(),
      };

      final request = await SupabaseDatabaseService.insert(
        table: _friendRequestsTable,
        data: requestData,
      );

      // Send notification
      await _sendFriendRequestNotification(userId, targetUserId, message);

      AppLogger.success(_tag, 'Friend request sent: ${request['id']}');
      return request;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to send friend request', e, stackTrace);
      rethrow;
    }
  }

  /// Get pending friend requests (received)
  static Future<List<Map<String, dynamic>>> getPendingFriendRequests({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Getting pending friend requests');

      final requests = await SupabaseDatabaseService.select(
        table: _friendRequestsTable,
        filters: {
          'receiver_id': userId,
          'status': statusPending,
        },
        orderBy: 'sent_at',
        ascending: false,
        limit: limit,
        offset: offset,
      );

      // Enrich with sender data
      for (final request in requests) {
        request['sender_data'] = await _getUserData(request['sender_id']);
        request['mutual_friends_count'] = await getMutualFriendsCount(
          userId,
          request['sender_id'],
        );
      }

      AppLogger.success(_tag, 'Retrieved ${requests.length} pending requests');
      return requests;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get pending friend requests', e, stackTrace);
      rethrow;
    }
  }

  /// Get sent friend requests
  static Future<List<Map<String, dynamic>>> getSentFriendRequests({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Getting sent friend requests');

      final requests = await SupabaseDatabaseService.select(
        table: _friendRequestsTable,
        filters: {
          'sender_id': userId,
        },
        orderBy: 'sent_at',
        ascending: false,
        limit: limit,
        offset: offset,
      );

      // Enrich with receiver data
      for (final request in requests) {
        request['receiver_data'] = await _getUserData(request['receiver_id']);
      }

      AppLogger.success(_tag, 'Retrieved ${requests.length} sent requests');
      return requests;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get sent friend requests', e, stackTrace);
      rethrow;
    }
  }

  /// Respond to friend request
  static Future<Map<String, dynamic>> respondToFriendRequest({
    required String requestId,
    required bool accept,
  }) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Responding to friend request: $requestId');

      // Get request
      final requests = await SupabaseDatabaseService.select(
        table: _friendRequestsTable,
        filters: {'id': requestId},
      );

      if (requests.isEmpty) {
        throw Exception('Friend request not found');
      }

      final request = requests.first;

      // Verify user is the receiver
      if (request['receiver_id'] != userId) {
        throw Exception('Not authorized to respond to this request');
      }

      // Check if already responded
      if (request['status'] != statusPending) {
        throw Exception('Request has already been responded to');
      }

      final newStatus = accept ? statusAccepted : statusDeclined;

      // Update request status
      final updatedRequest = await SupabaseDatabaseService.update(
        table: _friendRequestsTable,
        id: requestId,
        data: {
          'status': newStatus,
          'responded_at': DateTime.now().toIso8601String(),
        },
      );

      if (accept) {
        // Create friendship
        await _createFriendship(request['sender_id'], userId);

        // Send acceptance notification
        await _sendFriendRequestAcceptedNotification(
          userId,
          request['sender_id'],
        );
      }

      AppLogger.success(_tag, 'Friend request ${accept ? 'accepted' : 'declined'}');
      return updatedRequest;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to respond to friend request', e, stackTrace);
      rethrow;
    }
  }

  /// Cancel friend request
  static Future<void> cancelFriendRequest(String requestId) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Canceling friend request: $requestId');

      // Get request
      final requests = await SupabaseDatabaseService.select(
        table: _friendRequestsTable,
        filters: {'id': requestId},
      );

      if (requests.isEmpty) {
        throw Exception('Friend request not found');
      }

      final request = requests.first;

      // Verify user is the sender
      if (request['sender_id'] != userId) {
        throw Exception('Not authorized to cancel this request');
      }

      // Only pending requests can be cancelled
      if (request['status'] != statusPending) {
        throw Exception('Can only cancel pending requests');
      }

      // Delete the request
      await SupabaseDatabaseService.delete(
        table: _friendRequestsTable,
        id: requestId,
      );

      AppLogger.success(_tag, 'Friend request cancelled');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to cancel friend request', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // FRIENDSHIP MANAGEMENT
  // ===============================

  /// Get user's friends
  static Future<List<Map<String, dynamic>>> getFriends({
    String? userId,
    String? searchQuery,
    String? sortBy, // 'newest', 'alphabetical', 'mutual'
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final targetUserId = userId ?? SupabaseConfig.userId;
      if (targetUserId == null) {
        throw Exception('No user ID provided');
      }

      AppLogger.debug(_tag, 'Getting friends for user: $targetUserId');

      final friendships = await SupabaseDatabaseService.select(
        table: _friendshipsTable,
        filters: {
          'status': statusAccepted,
          'is_active': true,
        },
        orderBy: 'created_at',
        ascending: false,
        limit: limit * 2, // Get more for filtering
      );

      // Filter friendships for the target user
      var userFriendships = friendships.where((friendship) {
        return friendship['user1_id'] == targetUserId || 
               friendship['user2_id'] == targetUserId;
      }).toList();

      // Get friend user IDs
      final friends = <Map<String, dynamic>>[];
      for (final friendship in userFriendships) {
        final friendId = friendship['user1_id'] == targetUserId 
            ? friendship['user2_id'] 
            : friendship['user1_id'];

        final friendData = await _getUserData(friendId);
        friendData['friendship_id'] = friendship['id'];
        friendData['friendship_date'] = friendship['created_at'];

        // Add mutual friends count if current user is viewing someone else's friends
        final currentUserId = SupabaseConfig.userId;
        if (currentUserId != null && currentUserId != targetUserId) {
          friendData['mutual_friends_count'] = await getMutualFriendsCount(
            currentUserId,
            friendId,
          );
        }

        friends.add(friendData);
      }

      // Apply search filter
      var filteredFriends = friends;
      if (searchQuery != null && searchQuery.isNotEmpty) {
        filteredFriends = friends.where((friend) {
          final name = (friend['name'] as String? ?? '').toLowerCase();
          final username = (friend['username'] as String? ?? '').toLowerCase();
          final query = searchQuery.toLowerCase();
          return name.contains(query) || username.contains(query);
        }).toList();
      }

      // Apply sorting
      _sortFriends(filteredFriends, sortBy);

      // Apply pagination
      filteredFriends = filteredFriends.skip(offset).take(limit).toList();

      AppLogger.success(_tag, 'Retrieved ${filteredFriends.length} friends');
      return filteredFriends;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get friends', e, stackTrace);
      rethrow;
    }
  }

  /// Get mutual friends
  static Future<List<Map<String, dynamic>>> getMutualFriends({
    required String userId1,
    required String userId2,
    int limit = 20,
  }) async {
    try {
      AppLogger.debug(_tag, 'Getting mutual friends: $userId1 & $userId2');

      // Get friends of both users
      final user1Friends = await getFriends(userId: userId1, limit: 1000);
      final user2Friends = await getFriends(userId: userId2, limit: 1000);

      // Find mutual friends
      final user1FriendIds = user1Friends.map((f) => f['id'] as String).toSet();
      final mutualFriends = user2Friends.where((friend) {
        return user1FriendIds.contains(friend['id']);
      }).take(limit).toList();

      AppLogger.success(_tag, 'Found ${mutualFriends.length} mutual friends');
      return mutualFriends;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get mutual friends', e, stackTrace);
      rethrow;
    }
  }

  /// Get mutual friends count
  static Future<int> getMutualFriendsCount(String userId1, String userId2) async {
    try {
      final mutualFriends = await getMutualFriends(
        userId1: userId1,
        userId2: userId2,
        limit: 1000,
      );
      return mutualFriends.length;
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to get mutual friends count', e);
      return 0;
    }
  }

  /// Remove friend
  static Future<void> removeFriend(String friendId) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Removing friend: $friendId');

      // Find friendship
      final friendship = await _getFriendship(userId, friendId);
      if (friendship == null) {
        throw Exception('Friendship not found');
      }

      // Update friendship status
      await SupabaseDatabaseService.update(
        table: _friendshipsTable,
        id: friendship['id'],
        data: {
          'is_active': false,
          'removed_at': DateTime.now().toIso8601String(),
          'removed_by': userId,
        },
      );

      AppLogger.success(_tag, 'Friend removed successfully');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to remove friend', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // FRIEND RECOMMENDATIONS
  // ===============================

  /// Get friend suggestions
  static Future<List<Map<String, dynamic>>> getFriendSuggestions({
    int limit = 20,
  }) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Getting friend suggestions');

      final suggestions = <Map<String, dynamic>>[];

      // Get mutual friends suggestions
      final mutualSuggestions = await _getMutualFriendsSuggestions(userId, limit ~/ 2);
      suggestions.addAll(mutualSuggestions);

      // Get other suggestions (users with similar interests, location, etc.)
      final otherSuggestions = await _getOtherSuggestions(userId, limit - suggestions.length);
      suggestions.addAll(otherSuggestions);

      // Remove duplicates and sort by relevance
      final uniqueSuggestions = <String, Map<String, dynamic>>{};
      for (final suggestion in suggestions) {
        uniqueSuggestions[suggestion['id']] = suggestion;
      }

      final finalSuggestions = uniqueSuggestions.values.toList();
      finalSuggestions.sort((a, b) => (b['relevance_score'] as double).compareTo(a['relevance_score'] as double));

      AppLogger.success(_tag, 'Retrieved ${finalSuggestions.length} friend suggestions');
      return finalSuggestions.take(limit).toList();
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get friend suggestions', e, stackTrace);
      rethrow;
    }
  }

  /// Dismiss friend suggestion
  static Future<void> dismissFriendSuggestion(String suggestedUserId) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Dismissing friend suggestion: $suggestedUserId');

      // Store dismissed suggestion to avoid showing again
      await SupabaseDatabaseService.insert(
        table: 'dismissed_suggestions',
        data: {
          'user_id': userId,
          'suggested_user_id': suggestedUserId,
          'suggestion_type': 'friend',
          'dismissed_at': DateTime.now().toIso8601String(),
        },
      );

      AppLogger.success(_tag, 'Friend suggestion dismissed');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to dismiss friend suggestion', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // BLOCKING FUNCTIONALITY
  // ===============================

  /// Block user
  static Future<Map<String, dynamic>> blockUser({
    required String targetUserId,
    String? reason,
  }) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      if (userId == targetUserId) {
        throw Exception('Cannot block yourself');
      }

      AppLogger.debug(_tag, 'Blocking user: $targetUserId');

      // Check if already blocked
      final existingBlock = await _getBlockedUser(userId, targetUserId);
      if (existingBlock != null) {
        throw Exception('User is already blocked');
      }

      // Remove friendship if exists
      final friendship = await _getFriendship(userId, targetUserId);
      if (friendship != null) {
        await SupabaseDatabaseService.update(
          table: _friendshipsTable,
          id: friendship['id'],
          data: {
            'is_active': false,
            'removed_at': DateTime.now().toIso8601String(),
            'removed_by': userId,
          },
        );
      }

      // Cancel any pending friend requests
      await _cancelPendingRequests(userId, targetUserId);

      // Create block record
      final blockData = {
        'blocker_id': userId,
        'blocked_id': targetUserId,
        'reason': reason,
        'blocked_at': DateTime.now().toIso8601String(),
        'is_active': true,
      };

      final block = await SupabaseDatabaseService.insert(
        table: _blockedUsersTable,
        data: blockData,
      );

      AppLogger.success(_tag, 'User blocked successfully');
      return block;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to block user', e, stackTrace);
      rethrow;
    }
  }

  /// Unblock user
  static Future<void> unblockUser(String targetUserId) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Unblocking user: $targetUserId');

      // Find block record
      final block = await _getBlockedUser(userId, targetUserId);
      if (block == null) {
        throw Exception('User is not blocked');
      }

      // Remove block
      await SupabaseDatabaseService.update(
        table: _blockedUsersTable,
        id: block['id'],
        data: {
          'is_active': false,
          'unblocked_at': DateTime.now().toIso8601String(),
        },
      );

      AppLogger.success(_tag, 'User unblocked successfully');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to unblock user', e, stackTrace);
      rethrow;
    }
  }

  /// Get blocked users
  static Future<List<Map<String, dynamic>>> getBlockedUsers({
    int limit = 50,
  }) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Getting blocked users');

      final blocks = await SupabaseDatabaseService.select(
        table: _blockedUsersTable,
        filters: {
          'blocker_id': userId,
          'is_active': true,
        },
        orderBy: 'blocked_at',
        ascending: false,
        limit: limit,
      );

      // Enrich with user data
      for (final block in blocks) {
        block['blocked_user_data'] = await _getUserData(block['blocked_id']);
      }

      AppLogger.success(_tag, 'Retrieved ${blocks.length} blocked users');
      return blocks;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get blocked users', e, stackTrace);
      rethrow;
    }
  }

  /// Check if user is blocked
  static Future<bool> isUserBlocked(String targetUserId) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) return false;

      return await _isUserBlocked(userId, targetUserId) || 
             await _isUserBlocked(targetUserId, userId);
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to check if user is blocked', e);
      return false;
    }
  }

  // ===============================
  // FRIENDSHIP STATUS
  // ===============================

  /// Get friendship status between two users
  static Future<Map<String, dynamic>> getFriendshipStatus({
    required String targetUserId,
  }) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Getting friendship status with: $targetUserId');

      // Check if blocked
      final isBlocked = await isUserBlocked(targetUserId);
      if (isBlocked) {
        return {
          'status': 'blocked',
          'can_send_request': false,
          'can_message': false,
        };
      }

      // Check if friends
      final friendship = await _getFriendship(userId, targetUserId);
      if (friendship != null) {
        return {
          'status': 'friends',
          'friendship_id': friendship['id'],
          'friendship_date': friendship['created_at'],
          'can_send_request': false,
          'can_message': true,
        };
      }

      // Check for pending requests
      final sentRequest = await _getExistingRequest(userId, targetUserId);
      if (sentRequest != null && sentRequest['status'] == statusPending) {
        return {
          'status': 'request_sent',
          'request_id': sentRequest['id'],
          'can_send_request': false,
          'can_message': false,
        };
      }

      final receivedRequest = await _getExistingRequest(targetUserId, userId);
      if (receivedRequest != null && receivedRequest['status'] == statusPending) {
        return {
          'status': 'request_received',
          'request_id': receivedRequest['id'],
          'can_send_request': false,
          'can_message': false,
        };
      }

      // Not connected
      return {
        'status': 'not_connected',
        'can_send_request': true,
        'can_message': false,
        'mutual_friends_count': await getMutualFriendsCount(userId, targetUserId),
      };
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get friendship status', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // PRIVATE HELPER METHODS
  // ===============================

  /// Get user data
  static Future<Map<String, dynamic>> _getUserData(String userId) async {
    try {
      // This would normally fetch from user service
      return {
        'id': userId,
        'name': 'User Name',
        'username': 'username',
        'avatar_url': null,
        'location': null,
        'bio': null,
        'mutual_connections': 0,
      };
    } catch (e) {
      return {
        'id': userId,
        'name': 'Unknown User',
        'username': 'unknown',
        'avatar_url': null,
      };
    }
  }

  /// Get friendship between two users
  static Future<Map<String, dynamic>?> _getFriendship(String userId1, String userId2) async {
    try {
      final friendships = await SupabaseDatabaseService.select(
        table: _friendshipsTable,
        filters: {
          'status': statusAccepted,
          'is_active': true,
        },
      );

      return friendships.firstWhere(
        (friendship) =>
            (friendship['user1_id'] == userId1 && friendship['user2_id'] == userId2) ||
            (friendship['user1_id'] == userId2 && friendship['user2_id'] == userId1),
        orElse: () => {},
      ).isEmpty ? null : friendships.first;
    } catch (e) {
      return null;
    }
  }

  /// Get existing friend request
  static Future<Map<String, dynamic>?> _getExistingRequest(String senderId, String receiverId) async {
    try {
      final requests = await SupabaseDatabaseService.select(
        table: _friendRequestsTable,
        filters: {
          'sender_id': senderId,
          'receiver_id': receiverId,
        },
        orderBy: 'sent_at',
        ascending: false,
        limit: 1,
      );

      return requests.isNotEmpty ? requests.first : null;
    } catch (e) {
      return null;
    }
  }

  /// Create friendship
  static Future<Map<String, dynamic>> _createFriendship(String userId1, String userId2) async {
    final friendshipData = {
      'user1_id': userId1,
      'user2_id': userId2,
      'status': statusAccepted,
      'is_active': true,
      'created_at': DateTime.now().toIso8601String(),
    };

    return await SupabaseDatabaseService.insert(
      table: _friendshipsTable,
      data: friendshipData,
    );
  }

  /// Get blocked user record
  static Future<Map<String, dynamic>?> _getBlockedUser(String blockerId, String blockedId) async {
    try {
      final blocks = await SupabaseDatabaseService.select(
        table: _blockedUsersTable,
        filters: {
          'blocker_id': blockerId,
          'blocked_id': blockedId,
          'is_active': true,
        },
      );

      return blocks.isNotEmpty ? blocks.first : null;
    } catch (e) {
      return null;
    }
  }

  /// Check if user is blocked
  static Future<bool> _isUserBlocked(String blockerId, String blockedId) async {
    try {
      final block = await _getBlockedUser(blockerId, blockedId);
      return block != null;
    } catch (e) {
      return false;
    }
  }

  /// Cancel pending requests between users
  static Future<void> _cancelPendingRequests(String userId1, String userId2) async {
    try {
      // Get pending requests in both directions
      final requests = await SupabaseDatabaseService.select(
        table: _friendRequestsTable,
        filters: {'status': statusPending},
      );

      final relevantRequests = requests.where((request) =>
          (request['sender_id'] == userId1 && request['receiver_id'] == userId2) ||
          (request['sender_id'] == userId2 && request['receiver_id'] == userId1));

      for (final request in relevantRequests) {
        await SupabaseDatabaseService.update(
          table: _friendRequestsTable,
          id: request['id'],
          data: {
            'status': 'cancelled',
            'updated_at': DateTime.now().toIso8601String(),
          },
        );
      }
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to cancel pending requests', e);
    }
  }

  /// Get mutual friends suggestions
  static Future<List<Map<String, dynamic>>> _getMutualFriendsSuggestions(
    String userId,
    int limit,
  ) async {
    try {
      final suggestions = <Map<String, dynamic>>[];
      
      // Get user's friends
      final friends = await getFriends(userId: userId, limit: 100);
      
      // For each friend, get their friends (potential suggestions)
      for (final friend in friends.take(10)) { // Limit to avoid too many queries
        final friendsFriends = await getFriends(userId: friend['id'], limit: 50);
        
        for (final suggestion in friendsFriends) {
          // Skip if it's the user themselves or already a friend
          if (suggestion['id'] == userId) continue;
          
          final alreadyFriend = friends.any((f) => f['id'] == suggestion['id']);
          if (alreadyFriend) continue;
          
          // Check if already in suggestions
          final alreadySuggested = suggestions.any((s) => s['id'] == suggestion['id']);
          if (alreadySuggested) {
            // Increase relevance score for multiple mutual friends
            final existingSuggestion = suggestions.firstWhere((s) => s['id'] == suggestion['id']);
            existingSuggestion['relevance_score'] = (existingSuggestion['relevance_score'] as double) + 0.5;
            existingSuggestion['mutual_friends_count'] = (existingSuggestion['mutual_friends_count'] as int) + 1;
          } else {
            suggestion['relevance_score'] = 1.0;
            suggestion['mutual_friends_count'] = 1;
            suggestion['suggestion_reason'] = 'Mutual friends';
            suggestions.add(suggestion);
          }
        }
      }
      
      return suggestions.take(limit).toList();
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to get mutual friends suggestions', e);
      return [];
    }
  }

  /// Get other friend suggestions
  static Future<List<Map<String, dynamic>>> _getOtherSuggestions(
    String userId,
    int limit,
  ) async {
    try {
      // This would implement more sophisticated suggestion algorithms
      // Based on location, interests, mutual groups, etc.
      // For now, return empty list
      return [];
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to get other suggestions', e);
      return [];
    }
  }

  /// Sort friends list
  static void _sortFriends(List<Map<String, dynamic>> friends, String? sortBy) {
    switch (sortBy) {
      case 'alphabetical':
        friends.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
        break;
      case 'mutual':
        friends.sort((a, b) => (b['mutual_friends_count'] as int? ?? 0)
            .compareTo(a['mutual_friends_count'] as int? ?? 0));
        break;
      case 'newest':
      default:
        friends.sort((a, b) => DateTime.parse(b['friendship_date'])
            .compareTo(DateTime.parse(a['friendship_date'])));
        break;
    }
  }

  /// Send friend request notification
  static Future<void> _sendFriendRequestNotification(
    String senderId,
    String receiverId,
    String? message,
  ) async {
    try {
      final senderData = await _getUserData(senderId);
      
      await NotificationService.sendNotificationToUser(
        userId: receiverId,
        title: 'New Friend Request',
        message: '${senderData['name']} sent you a friend request',
        data: {
          'type': 'friend_request',
          'sender_id': senderId,
          'sender_name': senderData['name'],
          'message': message,
        },
      );
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to send friend request notification', e);
    }
  }

  /// Send friend request accepted notification
  static Future<void> _sendFriendRequestAcceptedNotification(
    String accepterId,
    String senderId,
  ) async {
    try {
      final accepterData = await _getUserData(accepterId);
      
      await NotificationService.sendNotificationToUser(
        userId: senderId,
        title: 'Friend Request Accepted',
        message: '${accepterData['name']} accepted your friend request',
        data: {
          'type': 'friend_request_accepted',
          'accepter_id': accepterId,
          'accepter_name': accepterData['name'],
        },
      );
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to send acceptance notification', e);
    }
  }
}
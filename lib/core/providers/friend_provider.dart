import 'package:flutter/foundation.dart';
import 'dart:math' as math;
import '../models/user_model.dart';
import '../models/friend_model.dart';
import '../../services/friend_service.dart';
import '../utils/service_locator.dart';

/// Provider for managing friends and social connections
class FriendProvider with ChangeNotifier {
  // Access FriendService through ServiceLocator for dependency injection
  FriendService get _friendService => ServiceLocator.instance.get<FriendService>();

  List<UserModel> _friends = [];
  List<FriendRequest> _friendRequests = [];
  List<UserModel> _suggestedFriends = [];
  List<UserModel> _searchResults = [];
  
  bool _isLoading = false;
  bool _isSearching = false;
  String? _error;

  // Friend request management
  List<FriendRequest> _sentRequests = [];
  List<FriendRequest> _receivedRequests = [];

  // Social stats
  Map<String, dynamic> _socialStats = {};

  // Getters
  List<UserModel> get friends => _friends;
  List<FriendRequest> get friendRequests => _friendRequests;
  List<UserModel> get suggestedFriends => _suggestedFriends;
  List<UserModel> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  String? get error => _error;
  List<FriendRequest> get sentRequests => _sentRequests;
  List<FriendRequest> get receivedRequests => _receivedRequests;
  Map<String, dynamic> get socialStats => _socialStats;

  /// Load user's friends list
  Future<void> loadFriends() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final friendsData = await _friendService.getFriends();
      _friends = friendsData.map((data) => UserModel.fromMap(data)).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load friend requests (both sent and received)
  Future<void> loadFriendRequests() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final pendingRequests = await _friendService.getPendingFriendRequests();
      final sentRequests = await _friendService.getSentFriendRequests();
      _friendRequests = [...pendingRequests, ...sentRequests].map((data) => FriendRequest.fromMap(data)).toList();
      
      // Separate sent and received requests
      _sentRequests = _friendRequests.where((req) => req.senderId == getCurrentUserId()).toList();
      _receivedRequests = _friendRequests.where((req) => req.receiverId == getCurrentUserId()).toList();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load suggested friends
  Future<void> loadSuggestedFriends() async {
    try {
      final suggestionsData = await _friendService.getFriendSuggestions();
      _suggestedFriends = suggestionsData.map((data) => UserModel.fromMap(data)).toList();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Send friend request
  Future<bool> sendFriendRequest(String userId) async {
    try {
      final requestData = await _friendService.sendFriendRequest(targetUserId: userId);
      
      // Add to sent requests
      final newRequest = FriendRequest.fromMap(requestData);
      _sentRequests.add(newRequest);
      _friendRequests.add(newRequest);
      
      // Remove from suggested friends if present
      _suggestedFriends.removeWhere((user) => user.id == userId);
      
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Accept friend request
  Future<bool> acceptFriendRequest(String requestId) async {
    try {
      final friendData = await _friendService.respondToFriendRequest(requestId: requestId, accept: true);
      
      // Add to friends list
      final newFriend = UserModel.fromMap(friendData);
      _friends.add(newFriend);
      
      // Remove from friend requests
      _friendRequests.removeWhere((req) => req.id == requestId);
      _receivedRequests.removeWhere((req) => req.id == requestId);
      
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Decline friend request
  Future<bool> declineFriendRequest(String requestId) async {
    try {
      await _friendService.respondToFriendRequest(requestId: requestId, accept: false);
      
      // Remove from friend requests
      _friendRequests.removeWhere((req) => req.id == requestId);
      _receivedRequests.removeWhere((req) => req.id == requestId);
      
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Cancel sent friend request
  Future<bool> cancelFriendRequest(String requestId) async {
    try {
      await _friendService.cancelFriendRequest(requestId);
      
      // Remove from sent requests
      _friendRequests.removeWhere((req) => req.id == requestId);
      _sentRequests.removeWhere((req) => req.id == requestId);
      
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Remove friend
  Future<bool> removeFriend(String userId) async {
    try {
      await _friendService.removeFriend(userId);
      
      // Remove from friends list
      _friends.removeWhere((friend) => friend.id == userId);
      
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Block user
  Future<bool> blockUser(String userId) async {
    try {
      await _friendService.blockUser(targetUserId: userId);
      
      // Remove from friends and requests
      _friends.removeWhere((friend) => friend.id == userId);
      _friendRequests.removeWhere((req) => req.senderId == userId || req.receiverId == userId);
      _sentRequests.removeWhere((req) => req.receiverId == userId);
      _receivedRequests.removeWhere((req) => req.senderId == userId);
      _suggestedFriends.removeWhere((user) => user.id == userId);
      
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Unblock user
  Future<bool> unblockUser(String userId) async {
    try {
      await _friendService.unblockUser(userId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Get blocked users
  Future<List<UserModel>> getBlockedUsers() async {
    try {
      final blockedData = await _friendService.getBlockedUsers();
      return blockedData.map((data) => UserModel.fromMap(data)).toList();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  /// Search users for adding as friends
  Future<void> searchUsers(String query) async {
    if (query.isEmpty) {
      _searchResults = [];
      _isSearching = false;
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();

    try {
      // Search users using FriendService with comprehensive search
      final searchData = await _friendService.searchUsers(query: query);
      _searchResults = searchData.map((data) => UserModel.fromMap(data)).toList();
      
      // Also search in current suggested friends for immediate results
      final filteredSuggestions = _suggestedFriends.where((user) {
        final name = user.displayName.toLowerCase();
        final email = user.email.toLowerCase();
        final searchQuery = query.toLowerCase();
        return name.contains(searchQuery) || email.contains(searchQuery);
      }).toList();
      
      // Combine search results, avoiding duplicates
      final existingIds = _searchResults.map((user) => user.uid).toSet();
      for (final suggestion in filteredSuggestions) {
        if (!existingIds.contains(suggestion.uid)) {
          _searchResults.add(suggestion);
        }
      }
      
      // Filter out existing friends and the current user
      final currentUserId = getCurrentUserId();
      final friendIds = _friends.map((friend) => friend.uid).toSet();
      _searchResults.removeWhere((user) => 
        friendIds.contains(user.uid) || user.uid == currentUserId);
      
      _isSearching = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isSearching = false;
      notifyListeners();
    }
  }

  /// Get mutual friends with another user
  Future<List<UserModel>> getMutualFriends(String userId) async {
    try {
      final currentUserId = getCurrentUserId();
      final mutualData = await _friendService.getMutualFriends(userId1: currentUserId, userId2: userId);
      return mutualData.map((data) => UserModel.fromMap(data)).toList();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  /// Get friend's friends (for networking)
  Future<List<UserModel>> getFriendsFriends(String friendId) async {
    try {
      // Get friends of the specified friend
      final friendsFriendsData = await _friendService.getFriends(userId: friendId);
      final friendsFriends = friendsFriendsData.map((data) => UserModel.fromMap(data)).toList();
      
      // Filter out current user and existing friends for privacy and relevance
      final currentUserId = getCurrentUserId();
      final existingFriendIds = _friends.map((friend) => friend.uid).toSet();
      
      return friendsFriends.where((user) => 
        user.uid != currentUserId && 
        !existingFriendIds.contains(user.uid)
      ).toList();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  /// Load social statistics
  Future<void> loadSocialStats() async {
    try {
      // Calculate social statistics from current data
      _socialStats = {
        'total_friends': _friends.length,
        'pending_requests': _receivedRequests.length,
        'sent_requests': _sentRequests.length,
        'friend_suggestions': _suggestedFriends.length,
        'mutual_friends_avg': _calculateAverageMutualFriends(),
        'recent_connections': _getRecentConnectionsCount(),
        'last_activity': DateTime.now().toIso8601String(),
      };
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Calculate average mutual friends count
  double _calculateAverageMutualFriends() {
    if (_friends.isEmpty) return 0.0;
    
    // This would normally be calculated from actual mutual friends data
    // For now, return a placeholder calculation
    return _friends.length * 0.3; // Estimate 30% mutual connections
  }

  /// Get count of recent connections (last 30 days)
  int _getRecentConnectionsCount() {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    
    return _friends.where((friend) {
      // This would normally check the friendship creation date
      // For now, return a placeholder count
      return friend.updatedAt.isAfter(thirtyDaysAgo);
    }).length;
  }

  /// Check friendship status with user
  Future<String> checkFriendshipStatus(String userId) async {
    try {
      final status = await _friendService.getFriendshipStatus(targetUserId: userId);
      return status['status'] ?? 'none'; // 'friends', 'request_sent', 'request_received', 'none', 'blocked'
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return 'none';
    }
  }

  /// Get online friends
  List<UserModel> get onlineFriends {
    // Filter friends who are currently online based on their last activity
    final onlineThreshold = DateTime.now().subtract(const Duration(minutes: 15));
    
    return _friends.where((friend) {
      // Check if friend was active within the last 15 minutes
      return friend.updatedAt.isAfter(onlineThreshold);
    }).toList();
  }

  /// Get friends by location/proximity
  Future<List<UserModel>> getNearbyFriends({
    required double latitude,
    required double longitude,
    double radiusKm = 50.0,
  }) async {
    try {
      // Filter friends who have location data and are within the specified radius
      final nearbyFriends = <UserModel>[];
      
      for (final friend in _friends) {
        if (friend.latitude != null && friend.longitude != null) {
          final distance = _calculateDistance(
            latitude, longitude,
            friend.latitude!, friend.longitude!
          );
          
          if (distance <= radiusKm) {
            nearbyFriends.add(friend);
          }
        }
      }
      
      // Sort by distance (closest first)
      nearbyFriends.sort((a, b) {
        final distanceA = _calculateDistance(latitude, longitude, a.latitude!, a.longitude!);
        final distanceB = _calculateDistance(latitude, longitude, b.latitude!, b.longitude!);
        return distanceA.compareTo(distanceB);
      });
      
      return nearbyFriends;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  /// Calculate distance between two coordinates using Haversine formula
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);
    
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) * math.cos(_degreesToRadians(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }

  /// Convert degrees to radians
  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  /// Get friend activity feed
  Future<List<Map<String, dynamic>>> getFriendActivity() async {
    try {
      // Generate activity feed from friends' recent activities
      final activities = <Map<String, dynamic>>[];
      
      for (final friend in _friends) {
        // Create mock activities based on friend data
        // In a real app, this would fetch from an activity/timeline service
        activities.addAll([
          {
            'id': '${friend.uid}_activity_1',
            'user_id': friend.uid,
            'user_name': friend.displayName,
            'user_avatar': friend.photoUrl,
            'activity_type': 'profile_update',
            'message': '${friend.displayName} updated their profile',
            'timestamp': friend.updatedAt.toIso8601String(),
            'data': {},
          },
          if (friend.latitude != null && friend.longitude != null)
            {
              'id': '${friend.uid}_activity_2',
              'user_id': friend.uid,
              'user_name': friend.displayName,
              'user_avatar': friend.photoUrl,
              'activity_type': 'location_update',
              'message': '${friend.displayName} shared their location',
              'timestamp': friend.updatedAt.subtract(const Duration(hours: 2)).toIso8601String(),
              'data': {
                'latitude': friend.latitude,
                'longitude': friend.longitude,
              },
            },
        ]);
      }
      
      // Sort by timestamp (most recent first)
      activities.sort((a, b) => 
        DateTime.parse(b['timestamp']).compareTo(DateTime.parse(a['timestamp'])));
      
      // Return only recent activities (last 7 days)
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      return activities.where((activity) => 
        DateTime.parse(activity['timestamp']).isAfter(weekAgo)
      ).take(50).toList();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  // Utility getters
  int get friendsCount => _friends.length;
  int get pendingRequestsCount => _receivedRequests.length;
  int get sentRequestsCount => _sentRequests.length;

  /// Get friends sorted by name
  List<UserModel> get friendsSortedByName {
    final sorted = List<UserModel>.from(_friends);
    sorted.sort((a, b) => a.displayName.compareTo(b.displayName));
    return sorted;
  }

  /// Get friends sorted by last activity
  List<UserModel> get friendsSortedByActivity {
    final sorted = List<UserModel>.from(_friends);
    sorted.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return sorted;
  }

  /// Clear search results
  void clearSearchResults() {
    _searchResults = [];
    _isSearching = false;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Refresh all friend data
  Future<void> refresh() async {
    await Future.wait([
      loadFriends(),
      loadFriendRequests(),
      loadSuggestedFriends(),
      loadSocialStats(),
    ]);
  }

  /// Helper method to get current user ID (should be implemented based on your auth system)
  String getCurrentUserId() {
    // This should return the current authenticated user's ID
    // Implementation depends on your authentication system
    return 'current_user_id'; // Placeholder
  }
}
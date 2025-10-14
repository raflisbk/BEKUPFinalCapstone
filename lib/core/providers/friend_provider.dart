import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/friend_model.dart';
import '../../services/friend_service.dart';
import '../../services/social_service.dart';

/// Provider for managing friends and social connections
class FriendProvider with ChangeNotifier {
  final FriendService _friendService = FriendService.instance;
  final SocialService _socialService = SocialService.instance;

  List<UserProfile> _friends = [];
  List<FriendRequest> _friendRequests = [];
  List<UserProfile> _suggestedFriends = [];
  List<UserProfile> _searchResults = [];
  
  bool _isLoading = false;
  bool _isSearching = false;
  String? _error;

  // Friend request management
  List<FriendRequest> _sentRequests = [];
  List<FriendRequest> _receivedRequests = [];

  // Social stats
  Map<String, dynamic> _socialStats = {};

  // Getters
  List<UserProfile> get friends => _friends;
  List<FriendRequest> get friendRequests => _friendRequests;
  List<UserProfile> get suggestedFriends => _suggestedFriends;
  List<UserProfile> get searchResults => _searchResults;
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
      _friends = friendsData.map((data) => UserProfile.fromMap(data)).toList();
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
      final requestsData = await _friendService.getFriendRequests();
      _friendRequests = requestsData.map((data) => FriendRequest.fromMap(data)).toList();
      
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
      _suggestedFriends = suggestionsData.map((data) => UserProfile.fromMap(data)).toList();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Send friend request
  Future<bool> sendFriendRequest(String userId) async {
    try {
      final requestData = await _friendService.sendFriendRequest(userId);
      
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
      final friendData = await _friendService.acceptFriendRequest(requestId);
      
      // Add to friends list
      final newFriend = UserProfile.fromMap(friendData);
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
      await _friendService.declineFriendRequest(requestId);
      
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
      await _friendService.blockUser(userId);
      
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
  Future<List<UserProfile>> getBlockedUsers() async {
    try {
      final blockedData = await _friendService.getBlockedUsers();
      return blockedData.map((data) => UserProfile.fromMap(data)).toList();
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
      final usersData = await _friendService.searchUsers(query);
      _searchResults = usersData.map((data) => UserProfile.fromMap(data)).toList();
      
      // Filter out existing friends
      final friendIds = _friends.map((friend) => friend.id).toSet();
      _searchResults.removeWhere((user) => friendIds.contains(user.id));
      
      _isSearching = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isSearching = false;
      notifyListeners();
    }
  }

  /// Get mutual friends with another user
  Future<List<UserProfile>> getMutualFriends(String userId) async {
    try {
      final mutualData = await _friendService.getMutualFriends(userId);
      return mutualData.map((data) => UserProfile.fromMap(data)).toList();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  /// Get friend's friends (for networking)
  Future<List<UserProfile>> getFriendsFriends(String friendId) async {
    try {
      final friendsData = await _friendService.getFriendsFriends(friendId);
      return friendsData.map((data) => UserProfile.fromMap(data)).toList();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  /// Load social statistics
  Future<void> loadSocialStats() async {
    try {
      _socialStats = await _socialService.getSocialStats();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Check friendship status with user
  Future<String> checkFriendshipStatus(String userId) async {
    try {
      final status = await _friendService.getFriendshipStatus(userId);
      return status; // 'friends', 'request_sent', 'request_received', 'none', 'blocked'
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return 'none';
    }
  }

  /// Get online friends
  List<UserProfile> get onlineFriends {
    return _friends.where((friend) => friend.isOnline).toList();
  }

  /// Get friends by location/proximity
  Future<List<UserProfile>> getNearbyFriends({
    required double latitude,
    required double longitude,
    double radiusKm = 50.0,
  }) async {
    try {
      final friendsData = await _friendService.getNearbyFriends(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
      );
      return friendsData.map((data) => UserProfile.fromMap(data)).toList();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  /// Get friend activity feed
  Future<List<Map<String, dynamic>>> getFriendActivity() async {
    try {
      return await _socialService.getFriendActivityFeed();
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
  List<UserProfile> get friendsSortedByName {
    final sorted = List<UserProfile>.from(_friends);
    sorted.sort((a, b) => a.displayName.compareTo(b.displayName));
    return sorted;
  }

  /// Get friends sorted by last activity
  List<UserProfile> get friendsSortedByActivity {
    final sorted = List<UserProfile>.from(_friends);
    sorted.sort((a, b) => (b.lastSeen ?? DateTime(1970)).compareTo(a.lastSeen ?? DateTime(1970)));
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
/// Interface for Community Service
/// Defines contracts for community management, membership, posts, events, and rules
abstract class ICommunityService {
  // ===============================
  // COMMUNITY MANAGEMENT
  // ===============================

  /// Create a new community
  Future<Map<String, dynamic>> createCommunity({
    required String name,
    required String description,
    required String category,
    String? visibility,
    String? coverImageUrl,
    List<String>? tags,
    Map<String, dynamic>? settings,
  });

  /// Get communities with optional filters
  Future<List<Map<String, dynamic>>> getCommunities({
    String? category,
    String? visibility,
    String? search,
    int limit = 20,
    int offset = 0,
  });

  /// Get community by ID
  Future<Map<String, dynamic>?> getCommunity(String communityId);

  /// Update community information
  Future<Map<String, dynamic>> updateCommunity({
    required String communityId,
    String? name,
    String? description,
    String? category,
    String? visibility,
    String? coverImageUrl,
    List<String>? tags,
    Map<String, dynamic>? settings,
  });

  // ===============================
  // MEMBERSHIP
  // ===============================

  /// Join a community
  Future<Map<String, dynamic>> joinCommunity(String communityId);

  /// Leave a community
  Future<void> leaveCommunity(String communityId);

  /// Get community members
  Future<List<Map<String, dynamic>>> getCommunityMembers({
    required String communityId,
    String? role,
    int limit = 50,
    int offset = 0,
  });

  /// Get user's communities
  Future<List<Map<String, dynamic>>> getUserCommunities({
    String? userId,
    int limit = 20,
    int offset = 0,
  });

  /// Update member role
  Future<Map<String, dynamic>> updateMemberRole({
    required String communityId,
    required String userId,
    required String role,
  });

  // ===============================
  // POSTS
  // ===============================

  /// Create a community post
  Future<Map<String, dynamic>> createCommunityPost({
    required String communityId,
    required String content,
    String? title,
    List<String>? imageUrls,
    List<String>? tags,
    Map<String, dynamic>? metadata,
  });

  /// Get community posts
  Future<List<Map<String, dynamic>>> getCommunityPosts({
    required String communityId,
    String? userId,
    int limit = 20,
    int offset = 0,
  });

  // ===============================
  // EVENTS
  // ===============================

  /// Create a community event
  Future<Map<String, dynamic>> createCommunityEvent({
    required String communityId,
    required String title,
    required String description,
    required DateTime startDate,
    DateTime? endDate,
    String? location,
    String? locationLat,
    String? locationLng,
    String? coverImageUrl,
    int? maxAttendees,
  });

  /// Get community events
  Future<List<Map<String, dynamic>>> getCommunityEvents({
    required String communityId,
    bool upcomingOnly = false,
    int limit = 20,
    int offset = 0,
  });

  // ===============================
  // RULES
  // ===============================

  /// Add community rule
  Future<Map<String, dynamic>> addCommunityRule({
    required String communityId,
    required String title,
    required String description,
    int? order,
  });

  /// Get community rules
  Future<List<Map<String, dynamic>>> getCommunityRules(String communityId);
}

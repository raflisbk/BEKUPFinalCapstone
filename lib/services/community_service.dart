import 'dart:async';
import '../core/interfaces/i_community_service.dart';
import '../core/utils/logger.dart';
import 'supabase_config.dart';
import 'supabase_database_service.dart';
import 'content_moderation_service.dart';
import 'notification_service.dart';

/// Community Service
/// Handles community features like groups, forums, events, and community management
class CommunityService implements ICommunityService {
  static const String _tag = 'CommunityService';
  static const String _communitiesTable = 'communities';
  static const String _communityMembersTable = 'community_members';
  static const String _communityPostsTable = 'community_posts';
  static const String _communityEventsTable = 'community_events';
  static const String _communityRulesTable = 'community_rules';
  static const String _joinRequestsTable = 'community_join_requests';

  // Community types
  static const String typePublic = 'public';
  static const String typePrivate = 'private';
  static const String typeSecret = 'secret';

  // Member roles
  static const String roleOwner = 'owner';
  static const String roleAdmin = 'admin';
  static const String roleModerator = 'moderator';
  static const String roleMember = 'member';

  // Community categories
  static const String categoryTravel = 'travel';
  static const String categoryDestination = 'destination';
  static const String categoryActivity = 'activity';
  static const String categoryBudget = 'budget';
  static const String categoryFood = 'food';
  static const String categoryCulture = 'culture';
  static const String categoryPhotography = 'photography';
  static const String categoryBackpacking = 'backpacking';
  static const String categoryLuxury = 'luxury';
  static const String categoryAdventure = 'adventure';

  // Event types
  static const String eventTypeMeetup = 'meetup';
  static const String eventTypeTrip = 'trip';
  static const String eventTypeWebinar = 'webinar';
  static const String eventTypeDiscussion = 'discussion';

  // ===============================
  // COMMUNITY MANAGEMENT
  // ===============================

  /// Create new community
  @override
  Future<Map<String, dynamic>> createCommunity({
    required String name,
    required String description,
    required String category,
    String? visibility,
    String? coverImageUrl,
    List<String>? tags,
    Map<String, dynamic>? settings,
  }) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Creating community: $name');

      // Moderate community content
      final moderationService = ContentModerationService.instance;
      final moderationResult = await moderationService.moderateTextContent(
        content: '$name\n$description',
        contentType: 'community',
        userId: userId,
      );

      if (moderationResult['action'] == 'block') {
        throw Exception('Community content was rejected by moderation');
      }

      // Create community
      final communityData = {
        'name': name,
        'description': description,
        'category': category,
        'type': visibility ?? 'public',
        'image_url': null,
        'cover_image_url': coverImageUrl,
        'tags': tags ?? [],
        'settings': settings ?? {},
        'created_by': userId,
        'member_count': 1,
        'post_count': 0,
        'event_count': 0,
        'is_active': true,
        'is_featured': false,
      };

      final community = await SupabaseDatabaseService.insert(
        table: _communitiesTable,
        data: communityData,
      );

      // Add creator as owner
      await _addMember(community['id'], userId, roleOwner);

      AppLogger.success(_tag, 'Community created: ${community['id']}');
      return community;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to create community', e, stackTrace);
      rethrow;
    }
  }

  /// Get communities
  @override
  Future<List<Map<String, dynamic>>> getCommunities({
    String? category,
    String? visibility,
    String? search,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      AppLogger.debug(_tag, 'Getting communities');

      final filters = <String, dynamic>{'is_active': true};
      if (category != null) filters['category'] = category;
      if (visibility != null) filters['type'] = visibility;

      var communities = await SupabaseDatabaseService.select(
        table: _communitiesTable,
        filters: filters,
        orderBy: 'created_at',
        ascending: false,
        limit: limit,
        offset: offset,
      );

      // Apply search filter
      if (search != null && search.isNotEmpty) {
        communities = communities.where((community) {
          final name = (community['name'] as String).toLowerCase();
          final description = (community['description'] as String).toLowerCase();
          final query = search.toLowerCase();
          return name.contains(query) || description.contains(query);
        }).toList();
      }

      // Enrich with additional data
      for (final community in communities) {
        await _enrichCommunityData(community);
      }

      AppLogger.success(_tag, 'Retrieved ${communities.length} communities');
      return communities;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get communities', e, stackTrace);
      rethrow;
    }
  }

  /// Get community by ID
  @override
  Future<Map<String, dynamic>?> getCommunity(String communityId) async {
    try {
      AppLogger.debug(_tag, 'Getting community: $communityId');

      final communities = await SupabaseDatabaseService.select(
        table: _communitiesTable,
        filters: {'id': communityId, 'is_active': true},
      );

      if (communities.isEmpty) {
        AppLogger.warning(_tag, 'Community not found: $communityId');
        return null;
      }

      final community = communities.first;
      await _enrichCommunityData(community);

      // Get community rules
      community['rules'] = await getCommunityRules(communityId);

      // Get recent posts
      community['recent_posts'] = await getCommunityPosts(
        communityId: communityId,
        limit: 5,
      );

      // Get upcoming events
      community['upcoming_events'] = await getCommunityEvents(
        communityId: communityId,
        limit: 3,
      );

      AppLogger.success(_tag, 'Retrieved community: ${community['name']}');
      return community;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get community', e, stackTrace);
      rethrow;
    }
  }

  /// Update community
  @override
  Future<Map<String, dynamic>> updateCommunity({
    required String communityId,
    String? name,
    String? description,
    String? category,
    String? visibility,
    String? coverImageUrl,
    List<String>? tags,
    Map<String, dynamic>? settings,
  }) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Updating community: $communityId');

      // Check permissions
      final hasPermission = await _hasAdminPermission(communityId, userId);
      if (!hasPermission) {
        throw Exception('Not authorized to update this community');
      }

      // Build update data
      final updateData = <String, dynamic>{};
      
      if (name != null) updateData['name'] = name;
      if (description != null) updateData['description'] = description;
      if (category != null) updateData['category'] = category;
      if (visibility != null) updateData['type'] = visibility;
      if (coverImageUrl != null) updateData['cover_image_url'] = coverImageUrl;
      if (tags != null) updateData['tags'] = tags;
      if (settings != null) updateData['settings'] = settings;

      if (updateData.isEmpty) {
        throw Exception('No data provided for update');
      }

      // Moderate content if name or description changed
      if (name != null || description != null) {
        final community = await getCommunity(communityId);
        if (community != null) {
          final contentToModerate = '${name ?? community['name']}\n${description ?? community['description']}';
          final moderationService = ContentModerationService.instance;
          final moderationResult = await moderationService.moderateTextContent(
            content: contentToModerate,
            contentType: 'community',
            contentId: communityId,
            userId: userId,
          );

          if (moderationResult['action'] == 'block') {
            throw Exception('Updated content was rejected by moderation');
          }
        }
      }

      updateData['updated_at'] = DateTime.now().toIso8601String();

      final result = await SupabaseDatabaseService.update(
        table: _communitiesTable,
        id: communityId,
        data: updateData,
      );

      AppLogger.success(_tag, 'Community updated successfully');
      return result;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to update community', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // MEMBERSHIP MANAGEMENT
  // ===============================

  /// Join community
  @override
  Future<Map<String, dynamic>> joinCommunity(String communityId) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Joining community: $communityId');

      // Check if already a member
      final existingMembership = await _getMembership(communityId, userId);
      if (existingMembership != null) {
        throw Exception('Already a member of this community');
      }

      // Get community info
      final community = await getCommunity(communityId);
      if (community == null) {
        throw Exception('Community not found');
      }

      final communityType = community['type'] as String;

      if (communityType == typePrivate) {
        // Create join request for private communities
        final result = await _createJoinRequest(communityId, userId);
        return result ?? {};
      } else if (communityType == typeSecret) {
        throw Exception('Cannot join secret communities without invitation');
      } else {
        // Direct join for public communities
        final result = await _addMember(communityId, userId, roleMember);
        return result ?? {};
      }
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to join community', e, stackTrace);
      rethrow;
    }
  }

  /// Leave community
  @override
  Future<void> leaveCommunity(String communityId) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Leaving community: $communityId');

      // Check if member
      final membership = await _getMembership(communityId, userId);
      if (membership == null) {
        throw Exception('Not a member of this community');
      }

      // Owners cannot leave (must transfer ownership first)
      if (membership['role'] == roleOwner) {
        throw Exception('Community owners cannot leave. Transfer ownership first.');
      }

      // Remove membership
      await SupabaseDatabaseService.update(
        table: _communityMembersTable,
        id: membership['id'],
        data: {
          'is_active': false,
          'left_at': DateTime.now().toIso8601String(),
        },
      );

      // Update member count
      await _updateMemberCount(communityId);

      AppLogger.success(_tag, 'Left community successfully');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to leave community', e, stackTrace);
      rethrow;
    }
  }

  /// Get community members
  @override
  Future<List<Map<String, dynamic>>> getCommunityMembers({
    required String communityId,
    String? role,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      AppLogger.debug(_tag, 'Getting members for community: $communityId');

      final filters = <String, dynamic>{
        'community_id': communityId,
        'is_active': true,
      };

      if (role != null) filters['role'] = role;

      final members = await SupabaseDatabaseService.select(
        table: _communityMembersTable,
        filters: filters,
        orderBy: 'joined_at',
        limit: limit,
        offset: offset,
      );

      // Enrich with user data
      for (final member in members) {
        member['user_data'] = await _getUserData(member['user_id']);
      }

      AppLogger.success(_tag, 'Retrieved ${members.length} community members');
      return members;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get community members', e, stackTrace);
      rethrow;
    }
  }

  /// Get user communities
  @override
  Future<List<Map<String, dynamic>>> getUserCommunities({
    String? userId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final targetUserId = userId ?? SupabaseConfig.userId;
      if (targetUserId == null) {
        throw Exception('No user ID provided');
      }

      AppLogger.debug(_tag, 'Getting communities for user: $targetUserId');

      final filters = <String, dynamic>{
        'user_id': targetUserId,
        'is_active': true,
      };

      final memberships = await SupabaseDatabaseService.select(
        table: _communityMembersTable,
        filters: filters,
        orderBy: 'joined_at',
        ascending: false,
        limit: limit,
        offset: offset,
      );

      final communities = <Map<String, dynamic>>[];

      for (final membership in memberships) {
        final community = await getCommunity(membership['community_id']);
        if (community != null) {
          community['user_role'] = membership['role'];
          community['joined_at'] = membership['joined_at'];
          communities.add(community);
        }
      }

      AppLogger.success(_tag, 'Retrieved ${communities.length} user communities');
      return communities;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get user communities', e, stackTrace);
      rethrow;
    }
  }

  /// Update member role
  @override
  Future<Map<String, dynamic>> updateMemberRole({
    required String communityId,
    required String userId,
    required String role,
  }) async {
    try {
      final currentUserId = SupabaseConfig.userId;
      if (currentUserId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Updating member role in community: $communityId');

      // Check permissions
      final hasPermission = await _hasOwnerPermission(communityId, currentUserId);
      if (!hasPermission) {
        throw Exception('Only community owners can change member roles');
      }

      // Get membership
      final membership = await _getMembership(communityId, userId);
      if (membership == null) {
        throw Exception('User is not a member of this community');
      }

      // Cannot change owner role
      if (membership['role'] == roleOwner) {
        throw Exception('Cannot change owner role');
      }

      // Update role
      final result = await SupabaseDatabaseService.update(
        table: _communityMembersTable,
        id: membership['id'],
        data: {
          'role': role,
          'role_updated_by': currentUserId,
          'role_updated_at': DateTime.now().toIso8601String(),
        },
      );

      AppLogger.success(_tag, 'Member role updated successfully');
      return result;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to update member role', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // COMMUNITY POSTS
  // ===============================

  /// Create community post
  @override
  Future<Map<String, dynamic>> createCommunityPost({
    required String communityId,
    String? title,
    required String content,
    List<String>? imageUrls,
    List<String>? tags,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Creating post in community: $communityId');

      // Check if user is a member
      final membership = await _getMembership(communityId, userId);
      if (membership == null) {
        throw Exception('Must be a community member to post');
      }

      // Moderate content
      final moderationService = ContentModerationService.instance;
      final moderationResult = await moderationService.moderateTextContent(
        content: '${title ?? ''}\n$content',
        contentType: 'community_post',
        userId: userId,
        metadata: {'community_id': communityId, ...?metadata},
      );

      String status = 'active';
      if (moderationResult['action'] == 'block') {
        status = 'removed';
      } else if (moderationResult['action'] == 'flag') {
        status = 'flagged';
      }

      // Create post
      final postData = {
        'community_id': communityId,
        'user_id': userId,
        if (title != null) 'title': title,
        'content': content,
        'post_type': metadata?['post_type'] ?? 'discussion',
        'image_urls': imageUrls ?? [],
        'tags': tags ?? [],
        'status': status,
        'is_pinned': metadata?['is_pinned'] == true && await _hasModeratorPermission(communityId, userId),
        'like_count': 0,
        'comment_count': 0,
        'view_count': 0,
      };

      final post = await SupabaseDatabaseService.insert(
        table: _communityPostsTable,
        data: postData,
      );

      // Update community post count
      await _updatePostCount(communityId);

      AppLogger.success(_tag, 'Community post created: ${post['id']}');
      return post;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to create community post', e, stackTrace);
      rethrow;
    }
  }

  /// Get community posts
  @override
  Future<List<Map<String, dynamic>>> getCommunityPosts({
    required String communityId,
    String? userId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      AppLogger.debug(_tag, 'Getting posts for community: $communityId');

      final filters = <String, dynamic>{
        'community_id': communityId,
        'status': 'active',
      };

      if (userId != null) filters['user_id'] = userId;

      var posts = await SupabaseDatabaseService.select(
        table: _communityPostsTable,
        filters: filters,
        orderBy: 'created_at',
        ascending: false,
        limit: limit,
        offset: offset,
      );

      // Handle pinned posts
      // Separate pinned and regular posts
      final pinnedPosts = posts.where((p) => p['is_pinned'] == true).toList();
      final regularPosts = posts.where((p) => p['is_pinned'] != true).toList();
        
      // Sort regular posts by creation time
      regularPosts.sort((a, b) => DateTime.parse(b['created_at']).compareTo(DateTime.parse(a['created_at'])));
        
      // Combine with pinned posts first
      posts = [...pinnedPosts, ...regularPosts];

      // Apply offset and limit
      posts = posts.skip(offset).take(limit).toList();

      // Enrich with user data
      for (final post in posts) {
        post['user_data'] = await _getUserData(post['user_id']);
        post['community_data'] = await _getCommunityBasicData(communityId);
      }

      AppLogger.success(_tag, 'Retrieved ${posts.length} community posts');
      return posts;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get community posts', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // COMMUNITY EVENTS
  // ===============================

  /// Create community event
  @override
  Future<Map<String, dynamic>> createCommunityEvent({
    required String communityId,
    required String title,
    required String description,
    required DateTime startDate,
    DateTime? endDate,
    String? location,
    String? coverImageUrl,
    String? locationLat,
    String? locationLng,
    int? maxAttendees,
  }) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Creating event in community: $communityId');

      // Check if user has permission to create events
      final hasPermission = await _hasModeratorPermission(communityId, userId);
      if (!hasPermission) {
        throw Exception('Only moderators and admins can create events');
      }

      // Create event
      final eventData = {
        'community_id': communityId,
        'created_by': userId,
        'title': title,
        'description': description,
        'event_type': 'meetup',
        'start_date': startDate.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
        'location': location,
        if (coverImageUrl != null) 'cover_image_url': coverImageUrl,
        if (locationLat != null) 'location_lat': locationLat,
        if (locationLng != null) 'location_lng': locationLng,
        'max_attendees': maxAttendees,
        'requires_approval': false,
        'metadata': {},
        'attendee_count': 0,
        'is_active': true,
      };

      final event = await SupabaseDatabaseService.insert(
        table: _communityEventsTable,
        data: eventData,
      );

      // Update community event count
      await _updateEventCount(communityId);

      // Notify community members
      await _notifyCommunityMembers(
        communityId,
        'New Event',
        'A new event has been created: $title',
        {
          'type': 'community_event',
          'event_id': event['id'],
          'community_id': communityId,
        },
      );

      AppLogger.success(_tag, 'Community event created: ${event['id']}');
      return event;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to create community event', e, stackTrace);
      rethrow;
    }
  }

  /// Get community events
  @override
  Future<List<Map<String, dynamic>>> getCommunityEvents({
    required String communityId,
    bool upcomingOnly = true,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      AppLogger.debug(_tag, 'Getting events for community: $communityId');

      final filters = <String, dynamic>{
        'community_id': communityId,
        'is_active': true,
      };

      var events = await SupabaseDatabaseService.select(
        table: _communityEventsTable,
        filters: filters,
        orderBy: 'start_date',
        limit: limit,
        offset: offset,
      );

      // Filter upcoming events
      if (upcomingOnly) {
        final now = DateTime.now();
        events = events.where((event) {
          final startDate = DateTime.parse(event['start_date']);
          return startDate.isAfter(now);
        }).toList();
      }

      // Enrich with creator data
      for (final event in events) {
        event['creator_data'] = await _getUserData(event['created_by']);
        event['community_data'] = await _getCommunityBasicData(communityId);
      }

      AppLogger.success(_tag, 'Retrieved ${events.length} community events');
      return events;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get community events', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // COMMUNITY RULES
  // ===============================

  /// Add community rule
  @override
  Future<Map<String, dynamic>> addCommunityRule({
    required String communityId,
    required String title,
    required String description,
    int? order,
  }) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Adding rule to community: $communityId');

      // Check permissions
      final hasPermission = await _hasAdminPermission(communityId, userId);
      if (!hasPermission) {
        throw Exception('Only admins can manage community rules');
      }

      return await _addCommunityRule(communityId, title, order, description);
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to add community rule', e, stackTrace);
      rethrow;
    }
  }

  /// Get community rules
  @override
  Future<List<Map<String, dynamic>>> getCommunityRules(String communityId) async {
    try {
      AppLogger.debug(_tag, 'Getting rules for community: $communityId');

      final rules = await SupabaseDatabaseService.select(
        table: _communityRulesTable,
        filters: {'community_id': communityId, 'is_active': true},
        orderBy: 'rule_order',
      );

      AppLogger.success(_tag, 'Retrieved ${rules.length} community rules');
      return rules;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get community rules', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // PRIVATE HELPER METHODS
  // ===============================

  /// Enrich community data
  Future<void> _enrichCommunityData(Map<String, dynamic> community) async {
    try {
      final currentUserId = SupabaseConfig.userId;
      
      // Add creator data
      community['creator_data'] = await _getUserData(community['created_by']);
      
      // Check if current user is a member
      if (currentUserId != null) {
        final membership = await _getMembership(community['id'], currentUserId);
        community['is_member'] = membership != null;
        community['user_role'] = membership?['role'];
      }
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to enrich community data', e);
    }
  }

  /// Get user data
  Future<Map<String, dynamic>?> _getUserData(String userId) async {
    try {
      // This would normally fetch from user service
      return {
        'id': userId,
        'name': 'User Name',
        'username': 'username',
        'avatar_url': null,
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

  /// Get community basic data
  Future<Map<String, dynamic>?> _getCommunityBasicData(String communityId) async {
    try {
      final communities = await SupabaseDatabaseService.select(
        table: _communitiesTable,
        filters: {'id': communityId},
      );

      if (communities.isNotEmpty) {
        final community = communities.first;
        return {
          'id': community['id'],
          'name': community['name'],
          'image_url': community['image_url'],
          'type': community['type'],
        };
      }

      return {'id': communityId, 'name': 'Unknown Community'};
    } catch (e) {
      return {'id': communityId, 'name': 'Unknown Community'};
    }
  }

  /// Get membership
  Future<Map<String, dynamic>?> _getMembership(String communityId, String userId) async {
    try {
      final memberships = await SupabaseDatabaseService.select(
        table: _communityMembersTable,
        filters: {
          'community_id': communityId,
          'user_id': userId,
          'is_active': true,
        },
      );

      return memberships.isNotEmpty ? memberships.first : null;
    } catch (e) {
      return null;
    }
  }

  /// Add member to community
  Future<Map<String, dynamic>?> _addMember(String communityId, String userId, String role) async {
    final memberData = {
      'community_id': communityId,
      'user_id': userId,
      'role': role,
      'is_active': true,
      'joined_at': DateTime.now().toIso8601String(),
    };

    final member = await SupabaseDatabaseService.insert(
      table: _communityMembersTable,
      data: memberData,
    );

    // Update member count
    await _updateMemberCount(communityId);

    return member;
  }

  /// Create join request
  Future<Map<String, dynamic>?> _createJoinRequest(String communityId, String userId) async {
    final requestData = {
      'community_id': communityId,
      'user_id': userId,
      'status': 'pending',
      'requested_at': DateTime.now().toIso8601String(),
    };

    return await SupabaseDatabaseService.insert(
      table: _joinRequestsTable,
      data: requestData,
    );
  }

  /// Check if user has owner permission
  Future<bool> _hasOwnerPermission(String communityId, String userId) async {
    try {
      final membership = await _getMembership(communityId, userId);
      return membership?['role'] == roleOwner;
    } catch (e) {
      return false;
    }
  }

  /// Check if user has admin permission
  Future<bool> _hasAdminPermission(String communityId, String userId) async {
    try {
      final membership = await _getMembership(communityId, userId);
      final role = membership?['role'] as String?;
      return role == roleOwner || role == roleAdmin;
    } catch (e) {
      return false;
    }
  }

  /// Check if user has moderator permission
  Future<bool> _hasModeratorPermission(String communityId, String userId) async {
    try {
      final membership = await _getMembership(communityId, userId);
      final role = membership?['role'] as String?;
      return role == roleOwner || role == roleAdmin || role == roleModerator;
    } catch (e) {
      return false;
    }
  }

  /// Update member count
  Future<void> _updateMemberCount(String communityId) async {
    try {
      final members = await SupabaseDatabaseService.select(
        table: _communityMembersTable,
        filters: {'community_id': communityId, 'is_active': true},
      );

      await SupabaseDatabaseService.update(
        table: _communitiesTable,
        id: communityId,
        data: {'member_count': members.length},
      );
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to update member count', e);
    }
  }

  /// Update post count
  Future<void> _updatePostCount(String communityId) async {
    try {
      final posts = await SupabaseDatabaseService.select(
        table: _communityPostsTable,
        filters: {'community_id': communityId, 'status': 'active'},
      );

      await SupabaseDatabaseService.update(
        table: _communitiesTable,
        id: communityId,
        data: {'post_count': posts.length},
      );
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to update post count', e);
    }
  }

  /// Update event count
  Future<void> _updateEventCount(String communityId) async {
    try {
      final events = await SupabaseDatabaseService.select(
        table: _communityEventsTable,
        filters: {'community_id': communityId, 'is_active': true},
      );

      await SupabaseDatabaseService.update(
        table: _communitiesTable,
        id: communityId,
        data: {'event_count': events.length},
      );
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to update event count', e);
    }
  }

  /// Add community rule
  Future<Map<String, dynamic>> _addCommunityRule(
    String communityId,
    String rule, [
    int? order,
    String? description,
  ]) async {
    // Get current rule count for ordering
    final existingRules = await SupabaseDatabaseService.select(
      table: _communityRulesTable,
      filters: {'community_id': communityId, 'is_active': true},
    );

    final ruleData = {
      'community_id': communityId,
      'rule': rule,
      'description': description,
      'rule_order': order ?? (existingRules.length + 1),
      'is_active': true,
    };

    return await SupabaseDatabaseService.insert(
      table: _communityRulesTable,
      data: ruleData,
    );
  }

  /// Notify community members
  Future<void> _notifyCommunityMembers(
    String communityId,
    String title,
    String message,
    Map<String, dynamic> data,
  ) async {
    try {
      // Get community members
      final members = await SupabaseDatabaseService.select(
        table: _communityMembersTable,
        filters: {'community_id': communityId, 'is_active': true},
      );

      final userIds = members.map((m) => m['user_id'] as String).toList();

      if (userIds.isNotEmpty) {
        await NotificationService.sendNotificationToUsers(
          userIds: userIds,
          title: title,
          message: message,
          data: data,
        );
      }
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to notify community members', e);
    }
  }
}
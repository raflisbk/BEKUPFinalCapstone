import 'dart:async';
import '../core/utils/logger.dart';
import 'supabase_config.dart';
import 'supabase_database_service.dart';
import 'content_moderation_service.dart';
import 'notification_service.dart';

/// Social Service
/// Handles social features like posts, feeds, interactions, and social networking
class SocialService {
  static const String _tag = 'SocialService';
  static const String _postsTable = 'social_posts';
  static const String _postLikesTable = 'post_likes';
  static const String _postCommentsTable = 'post_comments';
  static const String _postSharesTable = 'post_shares';
  static const String _followersTable = 'user_followers';
  static const String _feedTable = 'user_feeds';

  // Post types
  static const String typeText = 'text';
  static const String typeImage = 'image';
  static const String typeVideo = 'video';
  static const String typeTripUpdate = 'trip_update';
  static const String typeRecommendation = 'recommendation';
  static const String typeStory = 'story';

  // Post visibility
  static const String visibilityPublic = 'public';
  static const String visibilityFriends = 'friends';
  static const String visibilityPrivate = 'private';

  // Post status
  static const String statusActive = 'active';
  static const String statusArchived = 'archived';
  static const String statusReported = 'reported';
  static const String statusRemoved = 'removed';

  // ===============================
  // POST MANAGEMENT
  // ===============================

  /// Create social post
  static Future<Map<String, dynamic>> createPost({
    required String content,
    required String postType,
    String? visibility,
    List<String>? imageUrls,
    String? videoUrl,
    String? location,
    List<String>? tags,
    String? tripId,
    Map<String, dynamic>? metadata,
    bool skipModeration = false,
  }) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Creating social post: $postType');

      // Validate content
      if (content.trim().isEmpty && (imageUrls?.isEmpty ?? true) && videoUrl == null) {
        throw Exception('Post must have content, images, or video');
      }

      // Moderate content if not skipped
      String status = statusActive;
      if (!skipModeration && content.isNotEmpty) {
        final moderationService = ContentModerationService.instance;
        final moderationResult = await moderationService.moderateTextContent(
          content: content,
          contentType: 'social_post',
          userId: userId,
          metadata: {'post_type': postType, 'location': location},
        );

        if (moderationResult['action'] == 'block') {
          status = statusRemoved;
        } else if (moderationResult['action'] == 'flag') {
          status = statusReported;
        }
      }

      // Create post
      final postData = {
        'user_id': userId,
        'content': content,
        'post_type': postType,
        'visibility': visibility ?? visibilityPublic,
        'image_urls': imageUrls ?? [],
        'video_url': videoUrl,
        'location': location,
        'tags': tags ?? [],
        'trip_id': tripId,
        'metadata': metadata ?? {},
        'status': status,
        'like_count': 0,
        'comment_count': 0,
        'share_count': 0,
        'view_count': 0,
        'is_pinned': false,
      };

      final post = await SupabaseDatabaseService.insert(
        table: _postsTable,
        data: postData,
      );

      // Add to user feeds
      await _distributeToFeeds(post);

      AppLogger.success(_tag, 'Social post created: ${post['id']}');
      return post;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to create social post', e, stackTrace);
      rethrow;
    }
  }

  /// Get user posts
  static Future<List<Map<String, dynamic>>> getUserPosts({
    String? userId,
    String? postType,
    String? visibility,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final targetUserId = userId ?? SupabaseConfig.userId;
      if (targetUserId == null) {
        throw Exception('No user ID provided');
      }

      AppLogger.debug(_tag, 'Getting posts for user: $targetUserId');

      final filters = <String, dynamic>{
        'user_id': targetUserId,
        'status': statusActive,
      };

      if (postType != null) filters['post_type'] = postType;
      if (visibility != null) filters['visibility'] = visibility;

      var posts = await SupabaseDatabaseService.select(
        table: _postsTable,
        filters: filters,
        orderBy: 'created_at',
        ascending: false,
        limit: limit + offset,
      );

      // Apply offset
      posts = posts.skip(offset).take(limit).toList();

      // Enrich posts with interaction data
      for (final post in posts) {
        await _enrichPostData(post);
      }

      AppLogger.success(_tag, 'Retrieved ${posts.length} user posts');
      return posts;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get user posts', e, stackTrace);
      rethrow;
    }
  }

  /// Get social feed
  static Future<List<Map<String, dynamic>>> getSocialFeed({
    String? userId,
    String? feedType, // 'following', 'recommended', 'trending'
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final currentUserId = userId ?? SupabaseConfig.userId;
      if (currentUserId == null) {
        throw Exception('No user ID provided');
      }

      AppLogger.debug(_tag, 'Getting social feed for user: $currentUserId');

      List<Map<String, dynamic>> posts;

      switch (feedType) {
        case 'following':
          posts = await _getFollowingFeed(currentUserId, limit, offset);
          break;
        case 'trending':
          posts = await _getTrendingFeed(limit, offset);
          break;
        case 'recommended':
          posts = await _getRecommendedFeed(currentUserId, limit, offset);
          break;
        default:
          posts = await _getMixedFeed(currentUserId, limit, offset);
      }

      // Enrich posts with interaction data
      for (final post in posts) {
        await _enrichPostData(post);
      }

      AppLogger.success(_tag, 'Retrieved ${posts.length} feed posts');
      return posts;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get social feed', e, stackTrace);
      rethrow;
    }
  }

  /// Update post
  static Future<Map<String, dynamic>> updatePost({
    required String postId,
    String? content,
    List<String>? imageUrls,
    String? videoUrl,
    String? location,
    List<String>? tags,
    String? visibility,
    bool? isPinned,
  }) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Updating post: $postId');

      // Get post to verify ownership
      final posts = await SupabaseDatabaseService.select(
        table: _postsTable,
        filters: {'id': postId},
      );

      if (posts.isEmpty) {
        throw Exception('Post not found');
      }

      final post = posts.first;
      if (post['user_id'] != userId) {
        throw Exception('Not authorized to update this post');
      }

      // Build update data
      final updateData = <String, dynamic>{};
      
      if (content != null) updateData['content'] = content;
      if (imageUrls != null) updateData['image_urls'] = imageUrls;
      if (videoUrl != null) updateData['video_url'] = videoUrl;
      if (location != null) updateData['location'] = location;
      if (tags != null) updateData['tags'] = tags;
      if (visibility != null) updateData['visibility'] = visibility;
      if (isPinned != null) updateData['is_pinned'] = isPinned;

      if (updateData.isEmpty) {
        throw Exception('No data provided for update');
      }

      // Re-moderate if content changed
      if (content != null) {
        final moderationService = ContentModerationService.instance;
        final moderationResult = await moderationService.moderateTextContent(
          content: content,
          contentType: 'social_post',
          contentId: postId,
          userId: userId,
        );

        if (moderationResult['action'] == 'block') {
          updateData['status'] = statusRemoved;
        } else if (moderationResult['action'] == 'flag') {
          updateData['status'] = statusReported;
        }
      }

      updateData['updated_at'] = DateTime.now().toIso8601String();

      final result = await SupabaseDatabaseService.update(
        table: _postsTable,
        id: postId,
        data: updateData,
      );

      AppLogger.success(_tag, 'Post updated successfully');
      return result;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to update post', e, stackTrace);
      rethrow;
    }
  }

  /// Delete post
  static Future<void> deletePost(String postId) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.warning(_tag, 'Deleting post: $postId');

      // Get post to verify ownership
      final posts = await SupabaseDatabaseService.select(
        table: _postsTable,
        filters: {'id': postId},
      );

      if (posts.isEmpty) {
        throw Exception('Post not found');
      }

      final post = posts.first;
      if (post['user_id'] != userId) {
        throw Exception('Not authorized to delete this post');
      }

      // Soft delete
      await SupabaseDatabaseService.update(
        table: _postsTable,
        id: postId,
        data: {
          'status': statusRemoved,
          'deleted_at': DateTime.now().toIso8601String(),
        },
      );

      // Remove from feeds
      await _removeFromFeeds(postId);

      AppLogger.success(_tag, 'Post deleted successfully');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to delete post', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // POST INTERACTIONS
  // ===============================

  /// Like/unlike post
  static Future<Map<String, dynamic>> togglePostLike(String postId) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Toggling like for post: $postId');

      // Check if already liked
      final existingLikes = await SupabaseDatabaseService.select(
        table: _postLikesTable,
        filters: {'post_id': postId, 'user_id': userId},
      );

      bool isLiked;
      if (existingLikes.isNotEmpty) {
        // Unlike
        await SupabaseDatabaseService.delete(
          table: _postLikesTable,
          id: existingLikes.first['id'],
        );
        isLiked = false;
      } else {
        // Like
        await SupabaseDatabaseService.insert(
          table: _postLikesTable,
          data: {
            'post_id': postId,
            'user_id': userId,
          },
        );
        isLiked = true;

        // Send notification to post author
        await _sendLikeNotification(postId, userId);
      }

      // Update like count
      await _updatePostLikeCount(postId);

      AppLogger.success(_tag, 'Post like toggled: $isLiked');
      return {
        'post_id': postId,
        'is_liked': isLiked,
        'like_count': await _getPostLikeCount(postId),
      };
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to toggle post like', e, stackTrace);
      rethrow;
    }
  }

  /// Add comment to post
  static Future<Map<String, dynamic>> addComment({
    required String postId,
    required String content,
    String? parentCommentId,
  }) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Adding comment to post: $postId');

      // Moderate comment content
      final moderationService = ContentModerationService.instance;
      final moderationResult = await moderationService.moderateTextContent(
        content: content,
        contentType: 'comment',
        userId: userId,
        metadata: {'post_id': postId},
      );

      String status = 'active';
      if (moderationResult['action'] == 'block') {
        status = 'removed';
      } else if (moderationResult['action'] == 'flag') {
        status = 'flagged';
      }

      // Create comment
      final commentData = {
        'post_id': postId,
        'user_id': userId,
        'content': content,
        'parent_comment_id': parentCommentId,
        'status': status,
        'like_count': 0,
        'reply_count': 0,
      };

      final comment = await SupabaseDatabaseService.insert(
        table: _postCommentsTable,
        data: commentData,
      );

      // Update post comment count
      await _updatePostCommentCount(postId);

      // Update parent comment reply count if it's a reply
      if (parentCommentId != null) {
        await _updateCommentReplyCount(parentCommentId);
      }

      // Send notification to post author
      await _sendCommentNotification(postId, userId, content);

      AppLogger.success(_tag, 'Comment added successfully');
      return comment;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to add comment', e, stackTrace);
      rethrow;
    }
  }

  /// Get post comments
  static Future<List<Map<String, dynamic>>> getPostComments({
    required String postId,
    String? parentCommentId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      AppLogger.debug(_tag, 'Getting comments for post: $postId');

      final filters = <String, dynamic>{
        'post_id': postId,
        'status': 'active',
      };

      if (parentCommentId != null) {
        filters['parent_comment_id'] = parentCommentId;
      } else {
        // Get only top-level comments
        filters['parent_comment_id'] = null;
      }

      var comments = await SupabaseDatabaseService.select(
        table: _postCommentsTable,
        filters: filters,
        orderBy: 'created_at',
        ascending: true,
        limit: limit + offset,
      );

      // Apply offset
      comments = comments.skip(offset).take(limit).toList();

      // Enrich comments with user data and replies
      for (final comment in comments) {
        comment['user_data'] = await _getUserData(comment['user_id']);
        
        // Get first few replies for top-level comments
        if (parentCommentId == null && (comment['reply_count'] as int? ?? 0) > 0) {
          comment['replies'] = await getPostComments(
            postId: postId,
            parentCommentId: comment['id'],
            limit: 3,
          );
        }
      }

      AppLogger.success(_tag, 'Retrieved ${comments.length} comments');
      return comments;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get post comments', e, stackTrace);
      rethrow;
    }
  }

  /// Share post
  static Future<Map<String, dynamic>> sharePost({
    required String postId,
    String? shareComment,
    String? shareType, // 'repost', 'quote', 'external'
  }) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Sharing post: $postId');

      // Create share record
      final shareData = {
        'post_id': postId,
        'user_id': userId,
        'share_type': shareType ?? 'repost',
        'share_comment': shareComment,
      };

      final share = await SupabaseDatabaseService.insert(
        table: _postSharesTable,
        data: shareData,
      );

      // Update post share count
      await _updatePostShareCount(postId);

      // Send notification to post author
      await _sendShareNotification(postId, userId);

      AppLogger.success(_tag, 'Post shared successfully');
      return share;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to share post', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // FOLLOWING SYSTEM
  // ===============================

  /// Follow user
  static Future<Map<String, dynamic>> followUser(String targetUserId) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      if (userId == targetUserId) {
        throw Exception('Cannot follow yourself');
      }

      AppLogger.debug(_tag, 'Following user: $targetUserId');

      // Check if already following
      final existingFollows = await SupabaseDatabaseService.select(
        table: _followersTable,
        filters: {
          'follower_id': userId,
          'following_id': targetUserId,
          'is_active': true,
        },
      );

      if (existingFollows.isNotEmpty) {
        throw Exception('Already following this user');
      }

      // Create follow relationship
      final followData = {
        'follower_id': userId,
        'following_id': targetUserId,
        'is_active': true,
      };

      final follow = await SupabaseDatabaseService.insert(
        table: _followersTable,
        data: followData,
      );

      // Send notification
      await NotificationService.sendNotificationToUsers(
        userIds: [targetUserId],
        title: 'New Follower',
        message: 'Someone started following you',
        data: {
          'type': 'follow',
          'follower_id': userId,
        },
      );

      AppLogger.success(_tag, 'User followed successfully');
      return follow;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to follow user', e, stackTrace);
      rethrow;
    }
  }

  /// Unfollow user
  static Future<void> unfollowUser(String targetUserId) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Unfollowing user: $targetUserId');

      // Find follow relationship
      final follows = await SupabaseDatabaseService.select(
        table: _followersTable,
        filters: {
          'follower_id': userId,
          'following_id': targetUserId,
          'is_active': true,
        },
      );

      for (final follow in follows) {
        await SupabaseDatabaseService.update(
          table: _followersTable,
          id: follow['id'],
          data: {
            'is_active': false,
            'unfollowed_at': DateTime.now().toIso8601String(),
          },
        );
      }

      AppLogger.success(_tag, 'User unfollowed successfully');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to unfollow user', e, stackTrace);
      rethrow;
    }
  }

  /// Get user followers
  static Future<List<Map<String, dynamic>>> getUserFollowers({
    String? userId,
    int limit = 50,
  }) async {
    try {
      final targetUserId = userId ?? SupabaseConfig.userId;
      if (targetUserId == null) {
        throw Exception('No user ID provided');
      }

      AppLogger.debug(_tag, 'Getting followers for user: $targetUserId');

      final followers = await SupabaseDatabaseService.select(
        table: _followersTable,
        filters: {
          'following_id': targetUserId,
          'is_active': true,
        },
        orderBy: 'created_at',
        ascending: false,
        limit: limit,
      );

      // Enrich with user data
      for (final follower in followers) {
        follower['user_data'] = await _getUserData(follower['follower_id']);
      }

      AppLogger.success(_tag, 'Retrieved ${followers.length} followers');
      return followers;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get user followers', e, stackTrace);
      rethrow;
    }
  }

  /// Get user following
  static Future<List<Map<String, dynamic>>> getUserFollowing({
    String? userId,
    int limit = 50,
  }) async {
    try {
      final targetUserId = userId ?? SupabaseConfig.userId;
      if (targetUserId == null) {
        throw Exception('No user ID provided');
      }

      AppLogger.debug(_tag, 'Getting following for user: $targetUserId');

      final following = await SupabaseDatabaseService.select(
        table: _followersTable,
        filters: {
          'follower_id': targetUserId,
          'is_active': true,
        },
        orderBy: 'created_at',
        ascending: false,
        limit: limit,
      );

      // Enrich with user data
      for (final follow in following) {
        follow['user_data'] = await _getUserData(follow['following_id']);
      }

      AppLogger.success(_tag, 'Retrieved ${following.length} following');
      return following;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get user following', e, stackTrace);
      rethrow;
    }
  }

  /// Check if user is following another user
  static Future<bool> isFollowing(String targetUserId) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) return false;

      final follows = await SupabaseDatabaseService.select(
        table: _followersTable,
        filters: {
          'follower_id': userId,
          'following_id': targetUserId,
          'is_active': true,
        },
      );

      return follows.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // ===============================
  // STATISTICS & ANALYTICS
  // ===============================

  /// Get user social statistics
  static Future<Map<String, dynamic>> getUserSocialStatistics({
    String? userId,
  }) async {
    try {
      final targetUserId = userId ?? SupabaseConfig.userId;
      if (targetUserId == null) {
        throw Exception('No user ID provided');
      }

      AppLogger.debug(_tag, 'Getting social statistics for user: $targetUserId');

      // Get post statistics
      final posts = await SupabaseDatabaseService.select(
        table: _postsTable,
        filters: {'user_id': targetUserId, 'status': statusActive},
      );

      final totalLikes = posts.fold<int>(0, (sum, post) => sum + (post['like_count'] as int? ?? 0));
      final totalComments = posts.fold<int>(0, (sum, post) => sum + (post['comment_count'] as int? ?? 0));
      final totalShares = posts.fold<int>(0, (sum, post) => sum + (post['share_count'] as int? ?? 0));

      // Get follower counts
      final followers = await SupabaseDatabaseService.select(
        table: _followersTable,
        filters: {'following_id': targetUserId, 'is_active': true},
      );

      final following = await SupabaseDatabaseService.select(
        table: _followersTable,
        filters: {'follower_id': targetUserId, 'is_active': true},
      );

      return {
        'total_posts': posts.length,
        'total_likes': totalLikes,
        'total_comments': totalComments,
        'total_shares': totalShares,
        'followers_count': followers.length,
        'following_count': following.length,
        'engagement_rate': posts.isNotEmpty ? (totalLikes + totalComments + totalShares) / posts.length : 0.0,
      };
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get user social statistics', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // PRIVATE HELPER METHODS
  // ===============================

  /// Enrich post data with user info and interaction status
  static Future<void> _enrichPostData(Map<String, dynamic> post) async {
    try {
      final currentUserId = SupabaseConfig.userId;
      
      // Add user data
      post['user_data'] = await _getUserData(post['user_id']);
      
      // Check if current user liked the post
      if (currentUserId != null) {
        post['is_liked_by_current_user'] = await _isPostLikedByUser(post['id'], currentUserId);
      }
      
      // Get recent comments
      post['recent_comments'] = await getPostComments(
        postId: post['id'],
        limit: 3,
      );
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to enrich post data', e);
    }
  }

  /// Get user data
  static Future<Map<String, dynamic>> _getUserData(String userId) async {
    try {
      // This would normally fetch from user service
      return {
        'id': userId,
        'name': 'User Name',
        'username': 'username',
        'avatar_url': null,
        'is_verified': false,
      };
    } catch (e) {
      return {
        'id': userId,
        'name': 'Unknown User',
        'username': 'unknown',
        'avatar_url': null,
        'is_verified': false,
      };
    }
  }

  /// Get following feed
  static Future<List<Map<String, dynamic>>> _getFollowingFeed(String userId, int limit, int offset) async {
    // Get users that current user follows
    final following = await SupabaseDatabaseService.select(
      table: _followersTable,
      filters: {'follower_id': userId, 'is_active': true},
    );

    final followingIds = following.map((f) => f['following_id'] as String).toList();
    followingIds.add(userId); // Include own posts

    // Get posts from followed users
    var posts = await SupabaseDatabaseService.select(
      table: _postsTable,
      filters: {'status': statusActive},
      orderBy: 'created_at',
      ascending: false,
      limit: limit * 2, // Get more to filter properly
    );

    // Filter by following
    posts = posts.where((post) => followingIds.contains(post['user_id'])).toList();
    
    return posts.skip(offset).take(limit).toList();
  }

  /// Get trending feed
  static Future<List<Map<String, dynamic>>> _getTrendingFeed(int limit, int offset) async {
    // Get posts with high engagement in last 24 hours
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    
    var posts = await SupabaseDatabaseService.select(
      table: _postsTable,
      filters: {'status': statusActive, 'visibility': visibilityPublic},
      orderBy: 'like_count',
      ascending: false,
      limit: limit * 2,
    );

    // Filter by date and sort by engagement
    posts = posts.where((post) {
      final createdAt = DateTime.parse(post['created_at']);
      return createdAt.isAfter(yesterday);
    }).toList();

    // Sort by engagement score
    posts.sort((a, b) {
      final scoreA = (a['like_count'] as int) + (a['comment_count'] as int) * 2 + (a['share_count'] as int) * 3;
      final scoreB = (b['like_count'] as int) + (b['comment_count'] as int) * 2 + (b['share_count'] as int) * 3;
      return scoreB.compareTo(scoreA);
    });

    return posts.skip(offset).take(limit).toList();
  }

  /// Get recommended feed
  static Future<List<Map<String, dynamic>>> _getRecommendedFeed(String userId, int limit, int offset) async {
    // For now, return public posts with good engagement
    var posts = await SupabaseDatabaseService.select(
      table: _postsTable,
      filters: {'status': statusActive, 'visibility': visibilityPublic},
      orderBy: 'created_at',
      ascending: false,
      limit: limit * 3,
    );

    // Exclude own posts
    posts = posts.where((post) => post['user_id'] != userId).toList();

    // Sort by engagement
    posts.sort((a, b) {
      final scoreA = (a['like_count'] as int) + (a['comment_count'] as int);
      final scoreB = (b['like_count'] as int) + (b['comment_count'] as int);
      return scoreB.compareTo(scoreA);
    });

    return posts.skip(offset).take(limit).toList();
  }

  /// Get mixed feed
  static Future<List<Map<String, dynamic>>> _getMixedFeed(String userId, int limit, int offset) async {
    final followingPosts = await _getFollowingFeed(userId, limit ~/ 2, 0);
    final recommendedPosts = await _getRecommendedFeed(userId, limit ~/ 2, 0);
    
    // Merge and sort by creation time
    final allPosts = [...followingPosts, ...recommendedPosts];
    allPosts.sort((a, b) => DateTime.parse(b['created_at']).compareTo(DateTime.parse(a['created_at'])));
    
    return allPosts.skip(offset).take(limit).toList();
  }

  /// Distribute post to user feeds
  static Future<void> _distributeToFeeds(Map<String, dynamic> post) async {
    try {
      final postId = post['id'] as String;
      final authorId = post['user_id'] as String;
      
      // Get author's followers
      final followers = await SupabaseDatabaseService.select(
        table: _followersTable,
        filters: {'following_id': authorId, 'is_active': true},
      );

      // Add to each follower's feed
      for (final follower in followers) {
        await SupabaseDatabaseService.insert(
          table: _feedTable,
          data: {
            'user_id': follower['follower_id'],
            'post_id': postId,
            'post_author_id': authorId,
            'feed_type': 'following',
          },
        );
      }
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to distribute to feeds', e);
    }
  }

  /// Remove post from feeds
  static Future<void> _removeFromFeeds(String postId) async {
    try {
      final feedItems = await SupabaseDatabaseService.select(
        table: _feedTable,
        filters: {'post_id': postId},
      );

      for (final item in feedItems) {
        await SupabaseDatabaseService.delete(
          table: _feedTable,
          id: item['id'],
        );
      }
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to remove from feeds', e);
    }
  }

  /// Check if post is liked by user
  static Future<bool> _isPostLikedByUser(String postId, String userId) async {
    try {
      final likes = await SupabaseDatabaseService.select(
        table: _postLikesTable,
        filters: {'post_id': postId, 'user_id': userId},
      );
      return likes.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Update post like count
  static Future<void> _updatePostLikeCount(String postId) async {
    try {
      final likeCount = await _getPostLikeCount(postId);
      await SupabaseDatabaseService.update(
        table: _postsTable,
        id: postId,
        data: {'like_count': likeCount},
      );
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to update like count', e);
    }
  }

  /// Get post like count
  static Future<int> _getPostLikeCount(String postId) async {
    try {
      final likes = await SupabaseDatabaseService.select(
        table: _postLikesTable,
        filters: {'post_id': postId},
      );
      return likes.length;
    } catch (e) {
      return 0;
    }
  }

  /// Update post comment count
  static Future<void> _updatePostCommentCount(String postId) async {
    try {
      final comments = await SupabaseDatabaseService.select(
        table: _postCommentsTable,
        filters: {'post_id': postId, 'status': 'active'},
      );
      
      await SupabaseDatabaseService.update(
        table: _postsTable,
        id: postId,
        data: {'comment_count': comments.length},
      );
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to update comment count', e);
    }
  }

  /// Update comment reply count
  static Future<void> _updateCommentReplyCount(String commentId) async {
    try {
      final replies = await SupabaseDatabaseService.select(
        table: _postCommentsTable,
        filters: {'parent_comment_id': commentId, 'status': 'active'},
      );
      
      await SupabaseDatabaseService.update(
        table: _postCommentsTable,
        id: commentId,
        data: {'reply_count': replies.length},
      );
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to update reply count', e);
    }
  }

  /// Update post share count
  static Future<void> _updatePostShareCount(String postId) async {
    try {
      final shares = await SupabaseDatabaseService.select(
        table: _postSharesTable,
        filters: {'post_id': postId},
      );
      
      await SupabaseDatabaseService.update(
        table: _postsTable,
        id: postId,
        data: {'share_count': shares.length},
      );
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to update share count', e);
    }
  }

  /// Send like notification
  static Future<void> _sendLikeNotification(String postId, String likerId) async {
    try {
      // Get post to find author
      final posts = await SupabaseDatabaseService.select(
        table: _postsTable,
        filters: {'id': postId},
      );

      if (posts.isNotEmpty) {
        final post = posts.first;
        final authorId = post['user_id'] as String;
        
        if (authorId != likerId) {
          await NotificationService.sendNotificationToUsers(
            userIds: [authorId],
            title: 'Post Liked',
            message: 'Someone liked your post',
            data: {
              'type': 'post_like',
              'post_id': postId,
              'liker_id': likerId,
            },
          );
        }
      }
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to send like notification', e);
    }
  }

  /// Send comment notification
  static Future<void> _sendCommentNotification(String postId, String commenterId, String content) async {
    try {
      // Get post to find author
      final posts = await SupabaseDatabaseService.select(
        table: _postsTable,
        filters: {'id': postId},
      );

      if (posts.isNotEmpty) {
        final post = posts.first;
        final authorId = post['user_id'] as String;
        
        if (authorId != commenterId) {
          await NotificationService.sendNotificationToUsers(
            userIds: [authorId],
            title: 'New Comment',
            message: content.length > 50 ? '${content.substring(0, 50)}...' : content,
            data: {
              'type': 'post_comment',
              'post_id': postId,
              'commenter_id': commenterId,
            },
          );
        }
      }
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to send comment notification', e);
    }
  }

  /// Send share notification
  static Future<void> _sendShareNotification(String postId, String sharerId) async {
    try {
      // Get post to find author
      final posts = await SupabaseDatabaseService.select(
        table: _postsTable,
        filters: {'id': postId},
      );

      if (posts.isNotEmpty) {
        final post = posts.first;
        final authorId = post['user_id'] as String;
        
        if (authorId != sharerId) {
          await NotificationService.sendNotificationToUsers(
            userIds: [authorId],
            title: 'Post Shared',
            message: 'Someone shared your post',
            data: {
              'type': 'post_share',
              'post_id': postId,
              'sharer_id': sharerId,
            },
          );
        }
      }
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to send share notification', e);
    }
  }
}
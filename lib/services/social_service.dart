import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/utils/logger.dart';

/// Service for social features like following, posts, and interactions - Supabase version
class SocialService {
  static const String _tag = 'SocialService';

  final SupabaseClient _supabase = Supabase.instance.client;

  // Table names
  static const String _followsTable = 'user_follows';
  static const String _postsTable = 'social_posts';
  static const String _likesTable = 'post_likes';
  static const String _commentsTable = 'post_comments';

  /// Follow a user
  Future<bool> followUser({
    required String followerId,
    required String followingId,
  }) async {
    try {
      AppLogger.debug(_tag, 'Following user', {
        'followerId': followerId,
        'followingId': followingId,
      });

      await _supabase
          .from(_followsTable)
          .upsert({
            'follower_id': followerId,
            'following_id': followingId,
            'created_at': DateTime.now().toIso8601String(),
          });

      AppLogger.success(_tag, 'User followed successfully');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to follow user', e, stackTrace);
      return false;
    }
  }

  /// Unfollow a user
  Future<bool> unfollowUser({
    required String followerId,
    required String followingId,
  }) async {
    try {
      AppLogger.debug(_tag, 'Unfollowing user', {
        'followerId': followerId,
        'followingId': followingId,
      });

      await _supabase
          .from(_followsTable)
          .delete()
          .eq('follower_id', followerId)
          .eq('following_id', followingId);

      AppLogger.success(_tag, 'User unfollowed successfully');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to unfollow user', e, stackTrace);
      return false;
    }
  }

  /// Check if user is following another user
  Future<bool> isFollowing({
    required String followerId,
    required String followingId,
  }) async {
    try {
      final response = await _supabase
          .from(_followsTable)
          .select('id')
          .eq('follower_id', followerId)
          .eq('following_id', followingId)
          .maybeSingle();

      return response != null;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to check following status', e, stackTrace);
      return false;
    }
  }

  /// Get followers list
  Future<List<String>> getFollowers(String userId) async {
    try {
      final response = await _supabase
          .from(_followsTable)
          .select('follower_id')
          .eq('following_id', userId);

      return response
          .map((item) => item['follower_id'] as String)
          .toList();
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get followers', e, stackTrace);
      return [];
    }
  }

  /// Get following list
  Future<List<String>> getFollowing(String userId) async {
    try {
      final response = await _supabase
          .from(_followsTable)
          .select('following_id')
          .eq('follower_id', userId);

      return response
          .map((item) => item['following_id'] as String)
          .toList();
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get following', e, stackTrace);
      return [];
    }
  }

  /// Create a social post
  Future<String?> createPost({
    required String userId,
    required String content,
    List<String>? imageUrls,
    String? location,
    List<String>? tags,
  }) async {
    try {
      AppLogger.debug(_tag, 'Creating social post', {
        'userId': userId,
        'content': content.length,
      });

      final response = await _supabase
          .from(_postsTable)
          .insert({
            'user_id': userId,
            'content': content,
            'image_urls': imageUrls ?? [],
            'location': location,
            'tags': tags ?? [],
            'likes_count': 0,
            'comments_count': 0,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select('id')
          .single();

      final postId = response['id'] as String;
      AppLogger.success(_tag, 'Social post created', {'postId': postId});
      return postId;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to create post', e, stackTrace);
      return null;
    }
  }

  /// Get user posts
  Future<List<Map<String, dynamic>>> getUserPosts({
    required String userId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from(_postsTable)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return response;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get user posts', e, stackTrace);
      return [];
    }
  }

  /// Get timeline posts (posts from followed users)
  Future<List<Map<String, dynamic>>> getTimelinePosts({
    required String userId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      // Get following list
      final following = await getFollowing(userId);
      if (following.isEmpty) return [];

      final response = await _supabase
          .from(_postsTable)
          .select()
          .inFilter('user_id', following)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return response;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get timeline posts', e, stackTrace);
      return [];
    }
  }

  /// Like a post
  Future<bool> likePost({
    required String postId,
    required String userId,
  }) async {
    try {
      await _supabase
          .from(_likesTable)
          .upsert({
            'post_id': postId,
            'user_id': userId,
            'created_at': DateTime.now().toIso8601String(),
          });

      // Update likes count
      await _supabase.rpc('increment_post_likes', params: {
        'post_id': postId,
      });

      AppLogger.success(_tag, 'Post liked successfully');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to like post', e, stackTrace);
      return false;
    }
  }

  /// Unlike a post
  Future<bool> unlikePost({
    required String postId,
    required String userId,
  }) async {
    try {
      await _supabase
          .from(_likesTable)
          .delete()
          .eq('post_id', postId)
          .eq('user_id', userId);

      // Update likes count
      await _supabase.rpc('decrement_post_likes', params: {
        'post_id': postId,
      });

      AppLogger.success(_tag, 'Post unliked successfully');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to unlike post', e, stackTrace);
      return false;
    }
  }

  /// Add comment to post
  Future<String?> addComment({
    required String postId,
    required String userId,
    required String content,
    String? parentCommentId,
  }) async {
    try {
      final response = await _supabase
          .from(_commentsTable)
          .insert({
            'post_id': postId,
            'user_id': userId,
            'content': content,
            'parent_comment_id': parentCommentId,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select('id')
          .single();

      // Update comments count
      await _supabase.rpc('increment_post_comments', params: {
        'post_id': postId,
      });

      final commentId = response['id'] as String;
      AppLogger.success(_tag, 'Comment added', {'commentId': commentId});
      return commentId;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to add comment', e, stackTrace);
      return null;
    }
  }

  /// Get post comments
  Future<List<Map<String, dynamic>>> getPostComments({
    required String postId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from(_commentsTable)
          .select()
          .eq('post_id', postId)
          .order('created_at', ascending: true)
          .range(offset, offset + limit - 1);

      return response;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get post comments', e, stackTrace);
      return [];
    }
  }

  /// Delete post
  Future<bool> deletePost({
    required String postId,
    required String userId,
  }) async {
    try {
      await _supabase
          .from(_postsTable)
          .delete()
          .eq('id', postId)
          .eq('user_id', userId);

      AppLogger.success(_tag, 'Post deleted successfully');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to delete post', e, stackTrace);
      return false;
    }
  }

  /// Get follower count
  Future<int> getFollowerCount(String userId) async {
    try {
      final response = await _supabase
          .from(_followsTable)
          .select('id')
          .eq('following_id', userId);

      return response.length;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get follower count', e, stackTrace);
      return 0;
    }
  }

  /// Get following count
  Future<int> getFollowingCount(String userId) async {
    try {
      final response = await _supabase
          .from(_followsTable)
          .select('id')
          .eq('follower_id', userId);

      return response.length;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get following count', e, stackTrace);
      return 0;
    }
  }

  /// Get posts count
  Future<int> getPostsCount(String userId) async {
    try {
      final response = await _supabase
          .from(_postsTable)
          .select('id')
          .eq('user_id', userId);

      return response.length;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get posts count', e, stackTrace);
      return 0;
    }
  }

  /// Get social connection status between two users
  Future<Map<String, dynamic>> getSocialConnection(String currentUserId, String targetUserId) async {
    try {
      AppLogger.debug(_tag, 'Getting social connection', {
        'currentUserId': currentUserId,
        'targetUserId': targetUserId,
      });

      if (currentUserId == targetUserId) {
        return {
          'isFollowing': false,
          'isFollower': false,
          'areFriends': false,
          'connectionType': 'self',
        };
      }

      // Check if current user follows target user
      final following = await _supabase
          .from(_followsTable)
          .select()
          .eq('follower_id', currentUserId)
          .eq('following_id', targetUserId)
          .maybeSingle();

      // Check if target user follows current user
      final follower = await _supabase
          .from(_followsTable)
          .select()
          .eq('follower_id', targetUserId)
          .eq('following_id', currentUserId)
          .maybeSingle();

      final isFollowing = following != null;
      final isFollower = follower != null;
      final areFriends = isFollowing && isFollower;

      return {
        'isFollowing': isFollowing,
        'isFollower': isFollower,
        'areFriends': areFriends,
        'connectionType': areFriends ? 'friends' : isFollowing ? 'following' : isFollower ? 'follower' : 'none',
      };
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get social connection', e, stackTrace);
      return {
        'isFollowing': false,
        'isFollower': false,
        'areFriends': false,
        'connectionType': 'none',
      };
    }
  }

  /// Get activity feed stream for user
  Stream<List<Map<String, dynamic>>> getActivityFeedStream(String userId) {
    try {
      AppLogger.debug(_tag, 'Getting activity feed stream', {'userId': userId});

      // Get posts from users that the current user follows
      return _supabase
          .from(_postsTable)
          .stream(primaryKey: ['id']).map((data) {
        // Filter posts from followed users (simplified - in real implementation,
        // you'd join with follows table)
        return data.where((post) {
          // For now, return all posts - implement proper filtering later
          return true;
        }).toList();
      });
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get activity feed stream', e, stackTrace);
      return Stream.value([]);
    }
  }

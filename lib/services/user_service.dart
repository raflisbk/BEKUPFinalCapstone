import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/models/user_model.dart';
import '../core/utils/logger.dart';

/// Service for user-related operations
class UserService {
  static const String _tag = 'UserService';

  final SupabaseClient _supabase = Supabase.instance.client;

  static const String _tableName = 'users';

  /// Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      AppLogger.debug(_tag, 'Fetching user by ID', {'userId': userId});

      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) {
        AppLogger.warning(_tag, 'User not found', {'userId': userId});
        return null;
      }

      final user = UserModel.fromSupabase(response);
      AppLogger.info(_tag, 'User fetched successfully');
      return user;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to fetch user', e, stackTrace);
      return null;
    }
  }

  /// Get multiple users by IDs
  Future<List<UserModel>> getUsersByIds(List<String> userIds) async {
    try {
      if (userIds.isEmpty) return [];

      AppLogger.debug(_tag, 'Fetching multiple users', {
        'count': userIds.length,
      });

      final response = await _supabase
          .from(_tableName)
          .select()
          .inFilter('id', userIds);

      final users = (response as List<dynamic>)
          .map((data) => UserModel.fromSupabase(data))
          .toList();

      AppLogger.info(_tag, 'Users fetched successfully', {
        'requested': userIds.length,
        'fetched': users.length,
      });

      return users;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to fetch users', e, stackTrace);
      return [];
    }
  }

  /// Search users by name
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      if (query.isEmpty) return [];

      AppLogger.debug(_tag, 'Searching users', {'query': query});

      // PostgreSQL supports ILIKE for case-insensitive search - much better than Firestore!
      final response = await _supabase
          .from(_tableName)
          .select()
          .ilike('display_name', '%$query%')
          .order('display_name')
          .limit(20);

      final users = (response as List<dynamic>)
          .map((data) => UserModel.fromSupabase(data))
          .toList();

      AppLogger.info(_tag, 'User search completed', {
        'query': query,
        'results': users.length,
      });

      return users;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to search users', e, stackTrace);
      return [];
    }
  }

  /// Update user profile
  Future<bool> updateUser(String userId, Map<String, dynamic> updates) async {
    try {
      AppLogger.debug(_tag, 'Updating user', {
        'userId': userId,
        'fields': updates.keys.toList(),
      });

      await _supabase
          .from(_tableName)
          .update(updates)
          .eq('id', userId);

      AppLogger.info(_tag, 'User updated successfully');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to update user', e, stackTrace);
      return false;
    }
  }

  /// Get user stream (real-time updates)
  Stream<UserModel?> getUserStream(String userId) {
    return _supabase
        .from(_tableName)
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .map((List<Map<String, dynamic>> data) {
          if (data.isEmpty) return null;
          return UserModel.fromSupabase(data.first);
        });
  }
}

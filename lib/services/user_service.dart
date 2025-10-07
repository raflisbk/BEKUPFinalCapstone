import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/models/user_model.dart';
import '../core/utils/logger.dart';

/// Service for user-related operations
class UserService {
  static const String _tag = 'UserService';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _usersCollection => _firestore.collection('users');

  /// Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      AppLogger.debug(_tag, 'Fetching user by ID', {'userId': userId});

      final doc = await _usersCollection.doc(userId).get();

      if (!doc.exists) {
        AppLogger.warning(_tag, 'User not found', {'userId': userId});
        return null;
      }

      final user = UserModel.fromFirestore(doc);
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

      // Firestore 'in' query has a limit of 10 items
      // Split into batches if needed
      final List<UserModel> users = [];

      for (int i = 0; i < userIds.length; i += 10) {
        final batch = userIds.skip(i).take(10).toList();

        final querySnapshot = await _usersCollection
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        users.addAll(
          querySnapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList(),
        );
      }

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

      // Note: Firestore doesn't support case-insensitive search or LIKE queries
      // This is a simple implementation - consider using Algolia or similar for production
      final querySnapshot = await _usersCollection
          .orderBy('displayName')
          .startAt([query])
          .endAt(['$query\uf8ff'])
          .limit(20)
          .get();

      final users = querySnapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
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

      await _usersCollection.doc(userId).update(updates);

      AppLogger.info(_tag, 'User updated successfully');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to update user', e, stackTrace);
      return false;
    }
  }

  /// Get user stream (real-time updates)
  Stream<UserModel?> getUserStream(String userId) {
    return _usersCollection.doc(userId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    });
  }
}

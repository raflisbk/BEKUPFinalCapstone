import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import '../core/utils/logger.dart';
import 'media_service.dart';
import 'supabase_config.dart';
import 'supabase_database_service.dart';

/// Avatar Service
/// Specialized service for handling user avatars and profile images
class AvatarService {
  static const String _tag = 'AvatarService';
  static const String _avatarsTable = 'user_avatars';

  // Avatar configurations
  static const int _avatarSize = 400;
  static const int _thumbnailSize = 150;
  static const int _smallSize = 50;
  static const int _maxAvatarSizeMB = 5;

  // Default avatar options
  static const List<String> _defaultAvatars = [
    'default_avatar_1',
    'default_avatar_2',
    'default_avatar_3',
    'default_avatar_4',
    'default_avatar_5',
    'default_avatar_6',
    'default_avatar_7',
    'default_avatar_8',
  ];

  // ===============================
  // AVATAR UPLOAD & MANAGEMENT
  // ===============================

  /// Upload custom avatar
  static Future<Map<String, dynamic>> uploadCustomAvatar({
    required File imageFile,
    String? userId,
  }) async {
    try {
      final currentUserId = userId ?? SupabaseConfig.userId;
      if (currentUserId == null) {
        throw Exception('No user ID provided');
      }

      AppLogger.debug(_tag, 'Uploading custom avatar for user: $currentUserId');

      // Validate image file
      if (!MediaService.isValidImageFile(imageFile)) {
        throw Exception('Invalid image file format. Please use JPG, PNG, or WebP');
      }

      // Check file size
      final fileSizeMB = await MediaService.getFileSizeInMB(imageFile);
      if (fileSizeMB > _maxAvatarSizeMB) {
        throw Exception('Avatar file size exceeds ${_maxAvatarSizeMB}MB limit');
      }

      // Delete existing custom avatar if exists
      await _deleteExistingCustomAvatar(currentUserId);

      // Upload to Cloudinary with specific avatar transformations
      final result = await MediaService.uploadImage(
        imageFile: imageFile,
        folder: 'avatars/custom',
        publicId: 'custom_avatar_$currentUserId',
        tags: ['avatar', 'custom', currentUserId],
        transformation: 'c_fill,w_$_avatarSize,h_$_avatarSize,g_face,q_auto,f_auto',
        overwrite: true,
      );

      // Save avatar record
      final avatarRecord = await _saveAvatarRecord(
        userId: currentUserId,
        type: 'custom',
        publicId: result['public_id'],
        originalUrl: result['secure_url'],
        cloudinaryData: result,
      );

      // Generate different sizes
      final avatarUrls = _generateAvatarUrls(result['public_id']);

      AppLogger.success(_tag, 'Custom avatar uploaded successfully');
      return {
        'avatar_id': avatarRecord['id'],
        'type': 'custom',
        'public_id': result['public_id'],
        'urls': avatarUrls,
        'upload_info': result,
      };
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to upload custom avatar', e, stackTrace);
      rethrow;
    }
  }

  /// Upload avatar from bytes
  static Future<Map<String, dynamic>> uploadAvatarFromBytes({
    required Uint8List imageBytes,
    String? filename,
    String? userId,
  }) async {
    try {
      final currentUserId = userId ?? SupabaseConfig.userId;
      if (currentUserId == null) {
        throw Exception('No user ID provided');
      }

      AppLogger.debug(_tag, 'Uploading avatar from bytes for user: $currentUserId');

      // Delete existing custom avatar if exists
      await _deleteExistingCustomAvatar(currentUserId);

      // Upload to Cloudinary
      final result = await MediaService.uploadImageFromBytes(
        imageBytes: imageBytes,
        filename: filename ?? 'avatar_$currentUserId.jpg',
        folder: 'avatars/custom',
        publicId: 'custom_avatar_$currentUserId',
        tags: ['avatar', 'custom', currentUserId],
        transformation: 'c_fill,w_$_avatarSize,h_$_avatarSize,g_face,q_auto,f_auto',
      );

      // Save avatar record
      final avatarRecord = await _saveAvatarRecord(
        userId: currentUserId,
        type: 'custom',
        publicId: result['public_id'],
        originalUrl: result['secure_url'],
        cloudinaryData: result,
      );

      // Generate different sizes
      final avatarUrls = _generateAvatarUrls(result['public_id']);

      AppLogger.success(_tag, 'Avatar uploaded from bytes successfully');
      return {
        'avatar_id': avatarRecord['id'],
        'type': 'custom',
        'public_id': result['public_id'],
        'urls': avatarUrls,
        'upload_info': result,
      };
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to upload avatar from bytes', e, stackTrace);
      rethrow;
    }
  }

  /// Set default avatar
  static Future<Map<String, dynamic>> setDefaultAvatar({
    required String defaultAvatarId,
    String? userId,
  }) async {
    try {
      final currentUserId = userId ?? SupabaseConfig.userId;
      if (currentUserId == null) {
        throw Exception('No user ID provided');
      }

      AppLogger.debug(_tag, 'Setting default avatar for user: $currentUserId');

      // Validate default avatar ID
      if (!_defaultAvatars.contains(defaultAvatarId)) {
        throw Exception('Invalid default avatar ID');
      }

      // Delete existing custom avatar if exists
      await _deleteExistingCustomAvatar(currentUserId);

      // Save avatar record
      final avatarRecord = await _saveAvatarRecord(
        userId: currentUserId,
        type: 'default',
        publicId: defaultAvatarId,
        originalUrl: _getDefaultAvatarUrl(defaultAvatarId),
      );

      // Generate avatar URLs
      final avatarUrls = _generateDefaultAvatarUrls(defaultAvatarId);

      AppLogger.success(_tag, 'Default avatar set successfully');
      return {
        'avatar_id': avatarRecord['id'],
        'type': 'default',
        'public_id': defaultAvatarId,
        'urls': avatarUrls,
      };
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to set default avatar', e, stackTrace);
      rethrow;
    }
  }

  /// Get user avatar
  static Future<Map<String, dynamic>?> getUserAvatar(String userId) async {
    try {
      AppLogger.debug(_tag, 'Getting avatar for user: $userId');

      final avatars = await SupabaseDatabaseService.select(
        table: _avatarsTable,
        filters: {'user_id': userId, 'is_active': true},
        orderBy: 'created_at',
        ascending: false,
        limit: 1,
      );

      if (avatars.isEmpty) {
        AppLogger.warning(_tag, 'No avatar found for user: $userId');
        
        // Return default avatar info
        return {
          'type': 'default',
          'public_id': _defaultAvatars.first,
          'urls': _generateDefaultAvatarUrls(_defaultAvatars.first),
        };
      }

      final avatar = avatars.first;
      final type = avatar['type'] as String;
      final publicId = avatar['public_id'] as String;

      Map<String, String> urls;
      if (type == 'custom') {
        urls = _generateAvatarUrls(publicId);
      } else {
        urls = _generateDefaultAvatarUrls(publicId);
      }

      AppLogger.success(_tag, 'Retrieved user avatar');
      return {
        'avatar_id': avatar['id'],
        'type': type,
        'public_id': publicId,
        'urls': urls,
        'created_at': avatar['created_at'],
      };
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get user avatar', e, stackTrace);
      rethrow;
    }
  }

  /// Get avatar URL (quick access)
  static Future<String> getAvatarUrl({
    required String userId,
    String size = 'standard', // 'small', 'standard', 'large'
  }) async {
    try {
      final avatar = await getUserAvatar(userId);
      
      if (avatar == null) {
        return _generateDefaultAvatarUrls(_defaultAvatars.first)[size] ?? 
               _generateDefaultAvatarUrls(_defaultAvatars.first)['standard']!;
      }

      final urls = avatar['urls'] as Map<String, String>;
      return urls[size] ?? urls['standard']!;
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to get avatar URL, returning default', e);
      return _generateDefaultAvatarUrls(_defaultAvatars.first)['standard']!;
    }
  }

  /// Delete user avatar
  static Future<void> deleteUserAvatar(String userId) async {
    try {
      AppLogger.warning(_tag, 'Deleting avatar for user: $userId');

      final avatars = await SupabaseDatabaseService.select(
        table: _avatarsTable,
        filters: {'user_id': userId, 'is_active': true},
      );

      for (final avatar in avatars) {
        if (avatar['type'] == 'custom') {
          // Delete from Cloudinary
          await MediaService.deleteMedia(publicId: avatar['public_id']);
        }

        // Delete from database
        await SupabaseDatabaseService.delete(
          table: _avatarsTable,
          id: avatar['id'],
        );
      }

      AppLogger.success(_tag, 'User avatar deleted successfully');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to delete user avatar', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // AVATAR CUSTOMIZATION
  // ===============================

  /// Update avatar with filters/effects
  static Future<Map<String, dynamic>> applyAvatarFilter({
    required String userId,
    String? filter, // 'sepia', 'grayscale', 'brightness', etc.
    Map<String, dynamic>? customTransformations,
  }) async {
    try {
      AppLogger.debug(_tag, 'Applying filter to avatar: $userId');

      final avatar = await getUserAvatar(userId);
      if (avatar == null || avatar['type'] != 'custom') {
        throw Exception('No custom avatar found to apply filter');
      }

      final publicId = avatar['public_id'] as String;
      
      // Build transformation string
      final transformations = <String>['c_fill', 'w_$_avatarSize', 'h_$_avatarSize', 'g_face'];
      
      if (filter != null) {
        switch (filter) {
          case 'sepia':
            transformations.add('e_sepia');
            break;
          case 'grayscale':
            transformations.add('e_grayscale');
            break;
          case 'brightness':
            transformations.add('e_brightness:20');
            break;
          case 'blur':
            transformations.add('e_blur:300');
            break;
          case 'sharpen':
            transformations.add('e_sharpen');
            break;
        }
      }

      if (customTransformations != null) {
        for (final entry in customTransformations.entries) {
          transformations.add('${entry.key}:${entry.value}');
        }
      }

      transformations.addAll(['q_auto', 'f_auto']);

      // Generate new avatar URL with transformations
      final filteredUrl = MediaService.getOptimizedImageUrl(
        publicId: publicId,
        effects: transformations,
      );

      // Update avatar record with new transformation
      await SupabaseDatabaseService.update(
        table: _avatarsTable,
        id: avatar['avatar_id'],
        data: {
          'metadata': {
            ...Map<String, dynamic>.from(avatar['metadata'] ?? {}),
            'applied_filter': filter,
            'custom_transformations': customTransformations,
            'filtered_url': filteredUrl,
          }
        },
      );

      AppLogger.success(_tag, 'Avatar filter applied successfully');
      return {
        'avatar_id': avatar['avatar_id'],
        'filtered_url': filteredUrl,
        'applied_filter': filter,
      };
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to apply avatar filter', e, stackTrace);
      rethrow;
    }
  }

  /// Get available default avatars
  static List<Map<String, dynamic>> getAvailableDefaultAvatars() {
    return _defaultAvatars.map((avatarId) {
      return {
        'id': avatarId,
        'urls': _generateDefaultAvatarUrls(avatarId),
        'name': _getDefaultAvatarName(avatarId),
      };
    }).toList();
  }

  // ===============================
  // AVATAR ANALYTICS
  // ===============================

  /// Get avatar statistics
  static Future<Map<String, dynamic>> getAvatarStatistics() async {
    try {
      AppLogger.debug(_tag, 'Getting avatar statistics');

      final allAvatars = await SupabaseDatabaseService.select(
        table: _avatarsTable,
        filters: {'is_active': true},
      );

      final stats = {
        'total_avatars': allAvatars.length,
        'custom_avatars': allAvatars.where((a) => a['type'] == 'custom').length,
        'default_avatars': allAvatars.where((a) => a['type'] == 'default').length,
        'popular_defaults': <String, int>{},
        'upload_dates': <String, int>{},
      };

      // Count popular default avatars
      final popularDefaults = <String, int>{};
      final uploadDates = <String, int>{};

      for (final avatar in allAvatars) {
        if (avatar['type'] == 'default') {
          final publicId = avatar['public_id'] as String;
          popularDefaults[publicId] = (popularDefaults[publicId] ?? 0) + 1;
        }

        final createdAt = DateTime.parse(avatar['created_at']);
        final dateKey = '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}';
        uploadDates[dateKey] = (uploadDates[dateKey] ?? 0) + 1;
      }

      stats['popular_defaults'] = popularDefaults;
      stats['upload_dates'] = uploadDates;

      AppLogger.success(_tag, 'Avatar statistics retrieved');
      return stats;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get avatar statistics', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // PRIVATE HELPER METHODS
  // ===============================

  /// Save avatar record to database
  static Future<Map<String, dynamic>> _saveAvatarRecord({
    required String userId,
    required String type,
    required String publicId,
    required String originalUrl,
    Map<String, dynamic>? cloudinaryData,
  }) async {
    try {
      // Deactivate existing avatars
      final existingAvatars = await SupabaseDatabaseService.select(
        table: _avatarsTable,
        filters: {'user_id': userId, 'is_active': true},
      );

      for (final existingAvatar in existingAvatars) {
        await SupabaseDatabaseService.update(
          table: _avatarsTable,
          id: existingAvatar['id'],
          data: {'is_active': false},
        );
      }

      // Create new avatar record
      final avatarData = {
        'user_id': userId,
        'type': type,
        'public_id': publicId,
        'original_url': originalUrl,
        'metadata': cloudinaryData ?? {},
        'is_active': true,
      };

      return await SupabaseDatabaseService.insert(
        table: _avatarsTable,
        data: avatarData,
      );
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to save avatar record', e, stackTrace);
      rethrow;
    }
  }

  /// Delete existing custom avatar
  static Future<void> _deleteExistingCustomAvatar(String userId) async {
    try {
      final existingAvatars = await SupabaseDatabaseService.select(
        table: _avatarsTable,
        filters: {'user_id': userId, 'type': 'custom', 'is_active': true},
      );

      for (final avatar in existingAvatars) {
        // Delete from Cloudinary
        await MediaService.deleteMedia(publicId: avatar['public_id']);
        
        // Delete from database
        await SupabaseDatabaseService.delete(
          table: _avatarsTable,
          id: avatar['id'],
        );
      }
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to delete existing custom avatar', e);
      // Don't throw error as this is not critical
    }
  }

  /// Generate avatar URLs for different sizes
  static Map<String, String> _generateAvatarUrls(String publicId) {
    return {
      'small': MediaService.getOptimizedImageUrl(
        publicId: publicId,
        width: _smallSize,
        height: _smallSize,
        crop: 'fill',
        quality: 'auto',
        format: 'auto',
      ),
      'standard': MediaService.getOptimizedImageUrl(
        publicId: publicId,
        width: _thumbnailSize,
        height: _thumbnailSize,
        crop: 'fill',
        quality: 'auto',
        format: 'auto',
      ),
      'large': MediaService.getOptimizedImageUrl(
        publicId: publicId,
        width: _avatarSize,
        height: _avatarSize,
        crop: 'fill',
        quality: 'auto',
        format: 'auto',
      ),
    };
  }

  /// Generate default avatar URLs
  static Map<String, String> _generateDefaultAvatarUrls(String avatarId) {
    const baseUrl = 'https://res.cloudinary.com/relink/image/upload';
    
    return {
      'small': '$baseUrl/c_fill,w_$_smallSize,h_$_smallSize,q_auto,f_auto/avatars/defaults/$avatarId.png',
      'standard': '$baseUrl/c_fill,w_$_thumbnailSize,h_$_thumbnailSize,q_auto,f_auto/avatars/defaults/$avatarId.png',
      'large': '$baseUrl/c_fill,w_$_avatarSize,h_$_avatarSize,q_auto,f_auto/avatars/defaults/$avatarId.png',
    };
  }

  /// Get default avatar URL
  static String _getDefaultAvatarUrl(String avatarId) {
    return 'https://res.cloudinary.com/relink/image/upload/avatars/defaults/$avatarId.png';
  }

  /// Get default avatar name
  static String _getDefaultAvatarName(String avatarId) {
    final names = {
      'default_avatar_1': 'Traveler',
      'default_avatar_2': 'Explorer',
      'default_avatar_3': 'Adventurer',
      'default_avatar_4': 'Wanderer',
      'default_avatar_5': 'Nomad',
      'default_avatar_6': 'Tourist',
      'default_avatar_7': 'Voyager',
      'default_avatar_8': 'Backpacker',
    };
    
    return names[avatarId] ?? 'Default Avatar';
  }
}
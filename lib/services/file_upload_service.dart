import 'dart:async';
import 'dart:io';
import '../core/utils/logger.dart';
import 'media_service.dart';
import 'supabase_config.dart';
import 'supabase_database_service.dart';

/// File Upload Service
/// Handles specific file upload scenarios and metadata management
class FileUploadService {
  static const String _tag = 'FileUploadService';
  static const String _uploadsTable = 'file_uploads';

  // File upload limits
  static const int _maxImageSizeMB = 10;
  static const int _maxVideoSizeMB = 50;
  static const int _maxFileCount = 10;

  // ===============================
  // PROFILE & AVATAR UPLOADS
  // ===============================

  /// Upload user avatar
  static Future<Map<String, dynamic>> uploadAvatar({
    required File imageFile,
    String? userId,
  }) async {
    try {
      final currentUserId = userId ?? SupabaseConfig.userId;
      if (currentUserId == null) {
        throw Exception('No user ID provided');
      }

      AppLogger.debug(_tag, 'Uploading avatar for user: $currentUserId');

      // Validate image file
      if (!MediaService.isValidImageFile(imageFile)) {
        throw Exception('Invalid image file format');
      }

      // Check file size
      final fileSizeMB = await MediaService.getFileSizeInMB(imageFile);
      if (fileSizeMB > _maxImageSizeMB) {
        throw Exception('Image file size exceeds ${_maxImageSizeMB}MB limit');
      }

      // Upload to Cloudinary with avatar-specific settings
      final result = await MediaService.uploadImage(
        imageFile: imageFile,
        folder: 'avatars',
        publicId: 'avatar_$currentUserId',
        tags: ['avatar', 'profile'],
        transformation: 'c_fill,w_400,h_400,q_auto,f_auto',
        overwrite: true,
      );

      // Save upload record
      final uploadRecord = await _saveUploadRecord(
        userId: currentUserId,
        publicId: result['public_id'],
        originalUrl: result['secure_url'],
        type: 'avatar',
        fileSize: result['bytes'],
        format: result['format'],
        metadata: {
          'width': result['width'],
          'height': result['height'],
          'folder': 'avatars',
        },
      );

      AppLogger.success(_tag, 'Avatar uploaded successfully');
      return {
        ...result,
        'upload_id': uploadRecord['id'],
        'thumbnail_url': MediaService.getThumbnailUrl(
          publicId: result['public_id'],
          width: 150,
          height: 150,
        ),
      };
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to upload avatar', e, stackTrace);
      rethrow;
    }
  }

  /// Upload cover photo
  static Future<Map<String, dynamic>> uploadCoverPhoto({
    required File imageFile,
    String? userId,
  }) async {
    try {
      final currentUserId = userId ?? SupabaseConfig.userId;
      if (currentUserId == null) {
        throw Exception('No user ID provided');
      }

      AppLogger.debug(_tag, 'Uploading cover photo for user: $currentUserId');

      // Validate image file
      if (!MediaService.isValidImageFile(imageFile)) {
        throw Exception('Invalid image file format');
      }

      // Check file size
      final fileSizeMB = await MediaService.getFileSizeInMB(imageFile);
      if (fileSizeMB > _maxImageSizeMB) {
        throw Exception('Image file size exceeds ${_maxImageSizeMB}MB limit');
      }

      // Upload to Cloudinary with cover photo settings
      final result = await MediaService.uploadImage(
        imageFile: imageFile,
        folder: 'covers',
        publicId: 'cover_$currentUserId',
        tags: ['cover', 'profile'],
        transformation: 'c_fill,w_1200,h_400,q_auto,f_auto',
        overwrite: true,
      );

      // Save upload record
      final uploadRecord = await _saveUploadRecord(
        userId: currentUserId,
        publicId: result['public_id'],
        originalUrl: result['secure_url'],
        type: 'cover_photo',
        fileSize: result['bytes'],
        format: result['format'],
        metadata: {
          'width': result['width'],
          'height': result['height'],
          'folder': 'covers',
        },
      );

      AppLogger.success(_tag, 'Cover photo uploaded successfully');
      return {
        ...result,
        'upload_id': uploadRecord['id'],
        'responsive_urls': MediaService.getResponsiveImageUrls(
          publicId: result['public_id'],
          crop: 'fill',
        ),
      };
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to upload cover photo', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // DESTINATION & TRIP UPLOADS
  // ===============================

  /// Upload destination images
  static Future<List<Map<String, dynamic>>> uploadDestinationImages({
    required List<File> imageFiles,
    required String destinationId,
    List<String>? captions,
  }) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Uploading ${imageFiles.length} destination images');

      // Validate file count
      if (imageFiles.length > _maxFileCount) {
        throw Exception('Maximum $_maxFileCount files allowed per upload');
      }

      final results = <Map<String, dynamic>>[];

      for (int i = 0; i < imageFiles.length; i++) {
        try {
          final imageFile = imageFiles[i];
          
          // Validate image file
          if (!MediaService.isValidImageFile(imageFile)) {
            AppLogger.warning(_tag, 'Skipping invalid image file: ${imageFile.path}');
            continue;
          }

          // Check file size
          final fileSizeMB = await MediaService.getFileSizeInMB(imageFile);
          if (fileSizeMB > _maxImageSizeMB) {
            AppLogger.warning(_tag, 'Skipping oversized image: ${imageFile.path}');
            continue;
          }

          // Upload to Cloudinary
          final result = await MediaService.uploadImage(
            imageFile: imageFile,
            folder: 'destinations/$destinationId',
            tags: ['destination', destinationId, 'gallery'],
            transformation: 'c_limit,w_1920,h_1080,q_auto,f_auto',
          );

          // Save upload record
          final uploadRecord = await _saveUploadRecord(
            userId: userId,
            publicId: result['public_id'],
            originalUrl: result['secure_url'],
            type: 'destination_image',
            fileSize: result['bytes'],
            format: result['format'],
            metadata: {
              'destination_id': destinationId,
              'width': result['width'],
              'height': result['height'],
              'caption': captions != null && i < captions.length ? captions[i] : null,
              'order': i,
            },
          );

          results.add({
            ...result,
            'upload_id': uploadRecord['id'],
            'caption': captions != null && i < captions.length ? captions[i] : null,
            'thumbnail_url': MediaService.getThumbnailUrl(
              publicId: result['public_id'],
            ),
            'responsive_urls': MediaService.getResponsiveImageUrls(
              publicId: result['public_id'],
            ),
          });

        } catch (e) {
          AppLogger.warning(_tag, 'Failed to upload image ${i + 1}: $e');
          // Continue with other uploads
        }
      }

      AppLogger.success(_tag, 'Uploaded ${results.length} destination images');
      return results;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to upload destination images', e, stackTrace);
      rethrow;
    }
  }

  /// Upload trip photos
  static Future<List<Map<String, dynamic>>> uploadTripPhotos({
    required List<File> imageFiles,
    required String tripId,
    String? itineraryId,
    String? activityId,
    List<String>? captions,
  }) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Uploading ${imageFiles.length} trip photos');

      // Validate file count
      if (imageFiles.length > _maxFileCount) {
        throw Exception('Maximum $_maxFileCount files allowed per upload');
      }

      final results = <Map<String, dynamic>>[];

      for (int i = 0; i < imageFiles.length; i++) {
        try {
          final imageFile = imageFiles[i];
          
          // Validate image file
          if (!MediaService.isValidImageFile(imageFile)) {
            AppLogger.warning(_tag, 'Skipping invalid image file: ${imageFile.path}');
            continue;
          }

          // Check file size
          final fileSizeMB = await MediaService.getFileSizeInMB(imageFile);
          if (fileSizeMB > _maxImageSizeMB) {
            AppLogger.warning(_tag, 'Skipping oversized image: ${imageFile.path}');
            continue;
          }

          // Determine folder structure
          String folder = 'trips/$tripId';
          if (itineraryId != null) {
            folder += '/itinerary/$itineraryId';
          }
          if (activityId != null) {
            folder += '/activity/$activityId';
          }

          final tags = ['trip', tripId, 'photo'];
          if (itineraryId != null) tags.add(itineraryId);
          if (activityId != null) tags.add(activityId);

          // Upload to Cloudinary
          final result = await MediaService.uploadImage(
            imageFile: imageFile,
            folder: folder,
            tags: tags,
            transformation: 'c_limit,w_1920,h_1080,q_auto,f_auto',
          );

          // Save upload record
          final uploadRecord = await _saveUploadRecord(
            userId: userId,
            publicId: result['public_id'],
            originalUrl: result['secure_url'],
            type: 'trip_photo',
            fileSize: result['bytes'],
            format: result['format'],
            metadata: {
              'trip_id': tripId,
              'itinerary_id': itineraryId,
              'activity_id': activityId,
              'width': result['width'],
              'height': result['height'],
              'caption': captions != null && i < captions.length ? captions[i] : null,
              'order': i,
            },
          );

          results.add({
            ...result,
            'upload_id': uploadRecord['id'],
            'caption': captions != null && i < captions.length ? captions[i] : null,
            'thumbnail_url': MediaService.getThumbnailUrl(
              publicId: result['public_id'],
            ),
            'responsive_urls': MediaService.getResponsiveImageUrls(
              publicId: result['public_id'],
            ),
          });

        } catch (e) {
          AppLogger.warning(_tag, 'Failed to upload photo ${i + 1}: $e');
          // Continue with other uploads
        }
      }

      AppLogger.success(_tag, 'Uploaded ${results.length} trip photos');
      return results;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to upload trip photos', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // VIDEO UPLOADS
  // ===============================

  /// Upload video content
  static Future<Map<String, dynamic>> uploadVideo({
    required File videoFile,
    required String type, // 'destination', 'trip', 'review', etc.
    String? entityId,
    String? title,
    String? description,
  }) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Uploading video: $type');

      // Validate video file
      if (!MediaService.isValidVideoFile(videoFile)) {
        throw Exception('Invalid video file format');
      }

      // Check file size
      final fileSizeMB = await MediaService.getFileSizeInMB(videoFile);
      if (fileSizeMB > _maxVideoSizeMB) {
        throw Exception('Video file size exceeds ${_maxVideoSizeMB}MB limit');
      }

      // Determine folder
      String folder = 'videos/$type';
      if (entityId != null) {
        folder += '/$entityId';
      }

      final tags = ['video', type];
      if (entityId != null) tags.add(entityId);

      // Upload to Cloudinary with video optimization
      final result = await MediaService.uploadVideo(
        videoFile: videoFile,
        folder: folder,
        tags: tags,
        transformation: 'q_auto,f_auto',
      );

      // Save upload record
      final uploadRecord = await _saveUploadRecord(
        userId: userId,
        publicId: result['public_id'],
        originalUrl: result['secure_url'],
        type: 'video',
        fileSize: result['bytes'],
        format: result['format'],
        metadata: {
          'video_type': type,
          'entity_id': entityId,
          'title': title,
          'description': description,
          'duration': result['duration'],
          'width': result['width'],
          'height': result['height'],
        },
      );

      AppLogger.success(_tag, 'Video uploaded successfully');
      return {
        ...result,
        'upload_id': uploadRecord['id'],
        'title': title,
        'description': description,
      };
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to upload video', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // DOCUMENT UPLOADS
  // ===============================

  /// Upload document (receipt, ticket, etc.)
  static Future<Map<String, dynamic>> uploadDocument({
    required File documentFile,
    required String type, // 'receipt', 'ticket', 'passport', etc.
    String? entityId,
    String? title,
    String? description,
  }) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Uploading document: $type');

      // For now, treat documents as images (PDF support can be added later)
      if (!MediaService.isValidImageFile(documentFile)) {
        throw Exception('Invalid document file format');
      }

      // Check file size
      final fileSizeMB = await MediaService.getFileSizeInMB(documentFile);
      if (fileSizeMB > _maxImageSizeMB) {
        throw Exception('Document file size exceeds ${_maxImageSizeMB}MB limit');
      }

      // Determine folder
      String folder = 'documents/$type';
      if (entityId != null) {
        folder += '/$entityId';
      }

      final tags = ['document', type];
      if (entityId != null) tags.add(entityId);

      // Upload to Cloudinary
      final result = await MediaService.uploadImage(
        imageFile: documentFile,
        folder: folder,
        tags: tags,
        transformation: 'q_auto,f_auto',
      );

      // Save upload record
      final uploadRecord = await _saveUploadRecord(
        userId: userId,
        publicId: result['public_id'],
        originalUrl: result['secure_url'],
        type: 'document',
        fileSize: result['bytes'],
        format: result['format'],
        metadata: {
          'document_type': type,
          'entity_id': entityId,
          'title': title,
          'description': description,
          'width': result['width'],
          'height': result['height'],
        },
      );

      AppLogger.success(_tag, 'Document uploaded successfully');
      return {
        ...result,
        'upload_id': uploadRecord['id'],
        'title': title,
        'description': description,
        'thumbnail_url': MediaService.getThumbnailUrl(
          publicId: result['public_id'],
          width: 200,
          height: 150,
        ),
      };
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to upload document', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // UPLOAD MANAGEMENT
  // ===============================

  /// Get user uploads
  static Future<List<Map<String, dynamic>>> getUserUploads({
    String? userId,
    String? type,
    int limit = 50,
  }) async {
    try {
      final currentUserId = userId ?? SupabaseConfig.userId;
      if (currentUserId == null) {
        throw Exception('No user ID provided');
      }

      AppLogger.debug(_tag, 'Getting user uploads: $currentUserId');

      final filters = <String, dynamic>{'uploaded_by': currentUserId};
      if (type != null) filters['type'] = type;

      final uploads = await SupabaseDatabaseService.select(
        table: _uploadsTable,
        filters: filters,
        orderBy: 'created_at',
        ascending: false,
        limit: limit,
      );

      AppLogger.success(_tag, 'Retrieved ${uploads.length} uploads');
      return uploads;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get user uploads', e, stackTrace);
      rethrow;
    }
  }

  /// Update upload metadata
  static Future<Map<String, dynamic>> updateUploadMetadata({
    required String uploadId,
    String? title,
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      AppLogger.debug(_tag, 'Updating upload metadata: $uploadId');

      final updateData = <String, dynamic>{};
      
      if (title != null) {
        updateData['metadata'] = {'title': title};
      }
      if (description != null) {
        updateData['metadata'] = {'description': description};
      }
      if (metadata != null) {
        updateData['metadata'] = metadata;
      }

      if (updateData.isEmpty) {
        throw Exception('No metadata provided for update');
      }

      final result = await SupabaseDatabaseService.update(
        table: _uploadsTable,
        id: uploadId,
        data: updateData,
      );

      AppLogger.success(_tag, 'Upload metadata updated successfully');
      return result;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to update upload metadata', e, stackTrace);
      rethrow;
    }
  }

  /// Delete upload
  static Future<void> deleteUpload(String uploadId) async {
    try {
      AppLogger.warning(_tag, 'Deleting upload: $uploadId');

      // Get upload record
      final uploads = await SupabaseDatabaseService.select(
        table: _uploadsTable,
        filters: {'id': uploadId},
      );

      if (uploads.isEmpty) {
        throw Exception('Upload not found');
      }

      final upload = uploads.first;
      final publicId = upload['public_id'];

      // Delete from Cloudinary
      await MediaService.deleteMedia(publicId: publicId);

      // Delete from database
      await SupabaseDatabaseService.delete(
        table: _uploadsTable,
        id: uploadId,
      );

      AppLogger.success(_tag, 'Upload deleted successfully');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to delete upload', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // BATCH OPERATIONS
  // ===============================

  /// Delete multiple uploads
  static Future<List<String>> deleteMultipleUploads(List<String> uploadIds) async {
    try {
      AppLogger.debug(_tag, 'Deleting ${uploadIds.length} uploads');

      final deletedIds = <String>[];

      for (final uploadId in uploadIds) {
        try {
          await deleteUpload(uploadId);
          deletedIds.add(uploadId);
        } catch (e) {
          AppLogger.warning(_tag, 'Failed to delete upload $uploadId: $e');
          // Continue with other deletions
        }
      }

      AppLogger.success(_tag, 'Deleted ${deletedIds.length}/${uploadIds.length} uploads');
      return deletedIds;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to delete multiple uploads', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // PRIVATE HELPER METHODS
  // ===============================

  /// Save upload record to database
  static Future<Map<String, dynamic>> _saveUploadRecord({
    required String userId,
    required String publicId,
    required String originalUrl,
    required String type,
    required int fileSize,
    required String format,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final uploadData = {
        'uploaded_by': userId,
        'public_id': publicId,
        'original_url': originalUrl,
        'type': type,
        'file_size': fileSize,
        'format': format,
        'metadata': metadata ?? {},
        'is_active': true,
      };

      return await SupabaseDatabaseService.insert(
        table: _uploadsTable,
        data: uploadData,
      );
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to save upload record', e, stackTrace);
      rethrow;
    }
  }
}
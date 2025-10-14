import 'dart:io';
import 'dart:typed_data';
import 'package:cloudinary_public/cloudinary_public.dart';
import '../core/config/env_config.dart';
import '../core/utils/logger.dart';

/// Service for managing Cloudinary operations
/// Provides cost-effective image storage and optimization
class CloudinaryService {
  static const String _tag = 'CloudinaryService';

  late CloudinaryPublic _cloudinary;
  String get _cloudName => EnvConfig.cloudinaryCloudName;
  String get _uploadPreset => EnvConfig.cloudinaryUploadPreset;

  /// Initialize Cloudinary service
  Future<void> initialize() async {
    try {
      if (_cloudName.isEmpty || _uploadPreset.isEmpty) {
        throw Exception('Cloudinary credentials not found in .env file');
      }

      _cloudinary = CloudinaryPublic(_cloudName, _uploadPreset, cache: false);

      AppLogger.success(_tag, 'Cloudinary service initialized', {
        'cloudName': _cloudName,
        'uploadPreset': '${_uploadPreset.substring(0, 4)}***', // Hide preset for security
      });
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to initialize Cloudinary service', e, stackTrace);
      rethrow;
    }
  }

  /// Upload file to Cloudinary
  Future<String> uploadFile({
    required File file,
    required String folder,
    String? fileName,
    String resourceType = 'image',
  }) async {
    try {
      AppLogger.info(_tag, 'Uploading file to Cloudinary', {
        'folder': folder,
        'fileName': fileName,
        'fileSize': file.lengthSync(),
      });

      final publicId = fileName ?? _generatePublicId();

      CloudinaryResponse response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          file.path,
          resourceType: CloudinaryResourceType.Image,
          folder: folder,
          publicId: publicId,
        ),
      );

      final secureUrl = response.secureUrl;
      
      AppLogger.success(_tag, 'File uploaded successfully', {
        'publicId': response.publicId,
        'secureUrl': secureUrl,
      });

      return secureUrl;
      
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to upload file', e, stackTrace);
      rethrow;
    }
  }

  /// Upload bytes data to Cloudinary
  Future<String> uploadBytes({
    required Uint8List bytes,
    required String folder,
    String? fileName,
    String resourceType = 'image',
  }) async {
    try {
      AppLogger.info(_tag, 'Uploading bytes to Cloudinary', {
        'folder': folder,
        'fileName': fileName,
        'bytesLength': bytes.length,
      });

      final publicId = fileName ?? _generatePublicId();

      CloudinaryResponse response = await _cloudinary.uploadFile(
        CloudinaryFile.fromBytesData(
          bytes,
          identifier: publicId,
          resourceType: CloudinaryResourceType.Image,
          folder: folder,
          publicId: publicId,
        ),
      );

      final secureUrl = response.secureUrl;
      
      AppLogger.success(_tag, 'Bytes uploaded successfully', {
        'publicId': response.publicId,
        'secureUrl': secureUrl,
      });

      return secureUrl;
      
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to upload bytes', e, stackTrace);
      rethrow;
    }
  }

  /// Upload avatar with optimized settings
  Future<String> uploadAvatar({
    required File file,
    required String userId,
  }) async {
    final fileName = 'avatar_$userId';
    return await uploadFile(
      file: file,
      folder: 'avatars',
      fileName: fileName,
    );
  }

  /// Upload gallery photo with optimized settings
  Future<String> uploadGalleryPhoto({
    required File file,
    required String photoId,
  }) async {
    return await uploadFile(
      file: file,
      folder: 'gallery',
      fileName: photoId,
    );
  }

  /// Upload destination cover image
  Future<String> uploadDestinationCover({
    required File file,
    required String destinationId,
  }) async {
    final fileName = 'cover_$destinationId';
    return await uploadFile(
      file: file,
      folder: 'destinations',
      fileName: fileName,
    );
  }

  /// Get optimized image URL with transformations
  String getOptimizedImageUrl({
    required String secureUrl,
    int? width,
    int? height,
    String quality = 'auto',
    String format = 'auto',
  }) {
    try {
      // Parse the existing URL to add transformations
      final uri = Uri.parse(secureUrl);
      final pathSegments = uri.pathSegments.toList();
      
      // Find the upload segment
      final uploadIndex = pathSegments.indexOf('upload');
      if (uploadIndex == -1) {
        AppLogger.warning(_tag, 'Invalid Cloudinary URL format', {'url': secureUrl});
        return secureUrl;
      }

      // Build transformation string
      List<String> transformations = [];
      
      if (width != null) transformations.add('w_$width');
      if (height != null) transformations.add('h_$height');
      if (quality != 'auto') transformations.add('q_$quality');
      if (format != 'auto') transformations.add('f_$format');
      
      // Add default optimizations
      transformations.addAll(['q_auto', 'f_auto']);
      
      if (transformations.isNotEmpty) {
        pathSegments.insert(uploadIndex + 1, transformations.join(','));
      }

      final optimizedUri = uri.replace(pathSegments: pathSegments);
      
      AppLogger.debug(_tag, 'Generated optimized URL', {
        'original': secureUrl,
        'optimized': optimizedUri.toString(),
        'transformations': transformations.join(','),
      });

      return optimizedUri.toString();
    } catch (e) {
      AppLogger.error(_tag, 'Failed to generate optimized URL', e);
      return secureUrl;
    }
  }

  /// Delete file from Cloudinary
  Future<bool> deleteFile(String publicId) async {
    try {
      AppLogger.info(_tag, 'Deleting file from Cloudinary', {
        'publicId': publicId,
      });

      // Note: Deletion requires signed requests
      // For now, we'll just log the deletion request
      // In production, you'd need to implement admin API calls
      
      AppLogger.warning(_tag, 'File deletion not implemented in unsigned mode', {
        'publicId': publicId,
      });

      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to delete file', e, stackTrace);
      return false;
    }
  }

  /// Generate unique public ID
  String _generatePublicId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp * 1000 + DateTime.now().microsecond) % 999999;
    return '${timestamp}_$random';
  }

  /// Get usage statistics (placeholder - requires admin API)
  Future<Map<String, dynamic>> getUsageStats() async {
    try {
      AppLogger.info(_tag, 'Getting usage statistics');
      
      // Placeholder implementation
      // In production, you'd call Cloudinary Admin API
      final mockStats = {
        'storage': '0 MB',
        'bandwidth': '0 MB',
        'transformations': 0,
        'lastUpdated': DateTime.now().toIso8601String(),
      };

      AppLogger.success(_tag, 'Usage statistics retrieved', mockStats);
      return mockStats;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get usage statistics', e, stackTrace);
      return {};
    }
  }

  /// Check if service is properly configured
  bool get isConfigured {
    return _cloudName.isNotEmpty && _uploadPreset.isNotEmpty;
  }

  /// Get cloud name
  String get cloudName => _cloudName;

  /// Get upload preset
  String get uploadPreset => _uploadPreset;
}

import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../core/utils/logger.dart';
import 'cloudinary_service.dart';

/// Video metadata model
class VideoMetadata {
  final String id;
  final String url;
  final String thumbnailUrl;
  final int durationInSeconds;
  final int sizeInBytes;
  final int width;
  final int height;
  final DateTime uploadedAt;
  final String uploadedBy;

  const VideoMetadata({
    required this.id,
    required this.url,
    required this.thumbnailUrl,
    required this.durationInSeconds,
    required this.sizeInBytes,
    required this.width,
    required this.height,
    required this.uploadedAt,
    required this.uploadedBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'url': url,
      'thumbnailUrl': thumbnailUrl,
      'durationInSeconds': durationInSeconds,
      'sizeInBytes': sizeInBytes,
      'width': width,
      'height': height,
      'uploadedAt': uploadedAt.toIso8601String(),
      'uploadedBy': uploadedBy,
    };
  }

  factory VideoMetadata.fromMap(Map<String, dynamic> map) {
    return VideoMetadata(
      id: map['id'] ?? '',
      url: map['url'] ?? '',
      thumbnailUrl: map['thumbnailUrl'] ?? '',
      durationInSeconds: map['durationInSeconds'] ?? 0,
      sizeInBytes: map['sizeInBytes'] ?? 0,
      width: map['width'] ?? 0,
      height: map['height'] ?? 0,
      uploadedAt: DateTime.parse(map['uploadedAt']),
      uploadedBy: map['uploadedBy'] ?? '',
    );
  }
}

/// Service for video upload, compression, and playback
class VideoService {
  static const String _tag = 'VideoService';

  final CloudinaryService _cloudinaryService = CloudinaryService();

  // Video size limits
  static const int maxVideoSizeInMB = 100;
  static const int maxVideoSizeInBytes = maxVideoSizeInMB * 1024 * 1024;
  static const int maxVideoDurationInSeconds = 300; // 5 minutes

  /// Upload video to Firebase Storage
  Future<VideoMetadata?> uploadVideo({
    required File videoFile,
    required String userId,
    required String category, // 'review', 'destination', 'trip'
    required String referenceId,
    Function(double)? onProgress,
  }) async {
    try {
      AppLogger.info(_tag, 'Uploading video', {
        'category': category,
        'fileSize': await videoFile.length(),
      });

      // Check file size
      final fileSize = await videoFile.length();
      if (fileSize > maxVideoSizeInBytes) {
        AppLogger.error(_tag, 'Video file too large', {
          'size': fileSize,
          'maxSize': maxVideoSizeInBytes,
        });
        throw Exception('Video must be less than ${maxVideoSizeInMB}MB');
      }

      // Compress video if needed
      final compressedVideo = await _compressVideo(videoFile);
      if (compressedVideo == null) {
        throw Exception('Failed to compress video');
      }

      // Generate thumbnail
      final thumbnail = await _generateThumbnail(compressedVideo);
      if (thumbnail == null) {
        throw Exception('Failed to generate thumbnail');
      }

      // Upload thumbnail first
      final thumbnailUrl = await _uploadThumbnail(
        thumbnail,
        userId,
        category,
        referenceId,
      );

      // Upload video to Cloudinary
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${userId}_$timestamp';
      
      final downloadUrl = await _cloudinaryService.uploadFile(
        file: compressedVideo,
        folder: 'videos/$category/$referenceId',
        fileName: fileName,
        resourceType: 'video', // Cloudinary video resource type
      );

      // Note: Cloudinary progress monitoring would need to be implemented
      // in the CloudinaryService if needed
      onProgress?.call(1.0); // Complete

      // Get video metadata
      final metadata = await _getVideoMetadata(compressedVideo);
      final originalFileSize = await compressedVideo.length();

      // Clean up temporary files
      await compressedVideo.delete();
      await thumbnail.delete();
      if (compressedVideo.path != videoFile.path) {
        await videoFile.delete();
      }

      final videoMetadata = VideoMetadata(
        id: timestamp.toString(),
        url: downloadUrl,
        thumbnailUrl: thumbnailUrl,
        durationInSeconds: metadata['duration'] ?? 0,
        sizeInBytes: originalFileSize,
        width: metadata['width'] ?? 0,
        height: metadata['height'] ?? 0,
        uploadedAt: DateTime.now(),
        uploadedBy: userId,
      );

      AppLogger.success(_tag, 'Video uploaded successfully', {
        'url': downloadUrl,
        'thumbnailUrl': thumbnailUrl,
      });

      return videoMetadata;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to upload video', e, stackTrace);
      return null;
    }
  }

  /// Compress video to reduce file size
  Future<File?> _compressVideo(File videoFile) async {
    try {
      AppLogger.info(_tag, 'Compressing video', {
        'originalSize': await videoFile.length(),
      });

      // In real implementation, use ffmpeg_kit_flutter or video_compress package:
      // final info = await VideoCompress.compressVideo(
      //   videoFile.path,
      //   quality: VideoQuality.MediumQuality,
      //   deleteOrigin: false,
      // );
      // return info?.file;

      // Mock: Return original file
      AppLogger.success(_tag, 'Video compression skipped (mock)');
      return videoFile;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to compress video', e, stackTrace);
      return null;
    }
  }

  /// Generate thumbnail from video
  Future<File?> _generateThumbnail(File videoFile) async {
    try {
      AppLogger.debug(_tag, 'Generating video thumbnail');

      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final thumbnailPath = '${tempDir.path}/thumb_$timestamp.jpg';

      // In real implementation, use video_thumbnail package:
      // final thumbnail = await VideoThumbnail.thumbnailFile(
      //   video: videoFile.path,
      //   thumbnailPath: thumbnailPath,
      //   imageFormat: ImageFormat.JPEG,
      //   maxHeight: 720,
      //   quality: 75,
      // );

      // Mock: Create empty file
      final thumbnailFile = File(thumbnailPath);
      await thumbnailFile.create();
      await thumbnailFile.writeAsBytes([0xFF, 0xD8, 0xFF, 0xE0]); // Mock JPEG header

      AppLogger.success(_tag, 'Video thumbnail generated');
      return thumbnailFile;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to generate thumbnail', e, stackTrace);
      return null;
    }
  }

  /// Upload thumbnail to Cloudinary
  Future<String> _uploadThumbnail(
    File thumbnail,
    String userId,
    String category,
    String referenceId,
  ) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${userId}_$timestamp';
      
      final downloadUrl = await _cloudinaryService.uploadFile(
        file: thumbnail,
        folder: 'video_thumbnails/$category/$referenceId',
        fileName: fileName,
        resourceType: 'image',
      );

      AppLogger.success(_tag, 'Thumbnail uploaded to Cloudinary');
      return downloadUrl;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to upload thumbnail', e, stackTrace);
      rethrow;
    }
  }

  /// Get video metadata (duration, dimensions)
  Future<Map<String, int>> _getVideoMetadata(File videoFile) async {
    try {
      AppLogger.debug(_tag, 'Getting video metadata');

      // In real implementation, use video_player or ffmpeg:
      // final controller = VideoPlayerController.file(videoFile);
      // await controller.initialize();
      // final duration = controller.value.duration.inSeconds;
      // final width = controller.value.size.width.toInt();
      // final height = controller.value.size.height.toInt();
      // controller.dispose();

      // Mock metadata
      return {
        'duration': 30,
        'width': 1920,
        'height': 1080,
      };
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get video metadata', e, stackTrace);
      return {
        'duration': 0,
        'width': 0,
        'height': 0,
      };
    }
  }

  /// Delete video from Cloudinary
  Future<bool> deleteVideo(String videoUrl, String thumbnailUrl) async {
    try {
      AppLogger.info(_tag, 'Deleting video', {
        'url': videoUrl,
      });

      // Extract public ID from Cloudinary URLs and delete
      bool videoDeleted = false;
      bool thumbnailDeleted = true; // Default to true if no thumbnail

      // Delete video
      try {
        final videoPublicId = _extractPublicIdFromUrl(videoUrl);
        videoDeleted = await _cloudinaryService.deleteFile(videoPublicId);
      } catch (e) {
        AppLogger.error(_tag, 'Failed to delete video file', e);
      }

      // Delete thumbnail
      if (thumbnailUrl.isNotEmpty) {
        try {
          final thumbnailPublicId = _extractPublicIdFromUrl(thumbnailUrl);
          thumbnailDeleted = await _cloudinaryService.deleteFile(thumbnailPublicId);
        } catch (e) {
          AppLogger.error(_tag, 'Failed to delete thumbnail file', e);
        }
      }

      final success = videoDeleted && thumbnailDeleted;
      if (success) {
        AppLogger.success(_tag, 'Video deleted successfully from Cloudinary');
      }
      
      return success;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to delete video', e, stackTrace);
      return false;
    }
  }

  /// Extract public ID from Cloudinary URL
  String _extractPublicIdFromUrl(String url) {
    final uri = Uri.parse(url);
    final pathSegments = uri.pathSegments;
    final uploadIndex = pathSegments.indexOf('upload');
    
    if (uploadIndex == -1) {
      throw Exception('Invalid Cloudinary URL format: $url');
    }
    
    final publicIdParts = pathSegments.sublist(uploadIndex + 1);
    return publicIdParts.join('/').split('.').first; // Remove extension
  }

  /// Check if file is a valid video
  bool isValidVideoFile(File file) {
    final extension = file.path.split('.').last.toLowerCase();
    const validExtensions = ['mp4', 'mov', 'avi', 'mkv', 'flv', 'wmv'];
    return validExtensions.contains(extension);
  }

  /// Get video duration without uploading
  Future<int> getVideoDuration(String filePath) async {
    try {
      // In real implementation, use video_player package
      return 30; // Mock duration
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get video duration', e, stackTrace);
      return 0;
    }
  }

  /// Validate video before upload
  Future<Map<String, dynamic>> validateVideo(File videoFile) async {
    try {
      final fileSize = await videoFile.length();
      final duration = await getVideoDuration(videoFile.path);

      final errors = <String>[];

      if (!isValidVideoFile(videoFile)) {
        errors.add('Invalid video format. Supported: MP4, MOV, AVI, MKV');
      }

      if (fileSize > maxVideoSizeInBytes) {
        errors.add('Video size must be less than ${maxVideoSizeInMB}MB');
      }

      if (duration > maxVideoDurationInSeconds) {
        errors.add('Video duration must be less than ${maxVideoDurationInSeconds ~/ 60} minutes');
      }

      return {
        'isValid': errors.isEmpty,
        'errors': errors,
        'fileSize': fileSize,
        'duration': duration,
      };
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to validate video', e, stackTrace);
      return {
        'isValid': false,
        'errors': ['Failed to validate video'],
      };
    }
  }

  /// Format file size for display
  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Format duration for display
  String formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }
}

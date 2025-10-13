import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../core/utils/logger.dart';
import 'cloudinary_service.dart';

/// Photo upload service using Cloudinary instead of Firebase Storage
/// Provides cost-effective image storage with automatic optimization
class CloudinaryPhotoUploadService {
  static final CloudinaryPhotoUploadService _instance = CloudinaryPhotoUploadService._internal();
  factory CloudinaryPhotoUploadService() => _instance;
  CloudinaryPhotoUploadService._internal();

  static const String _tag = 'CloudinaryPhotoUploadService';

  final ImagePicker _picker = ImagePicker();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Initialize the service
  Future<void> initialize() async {
    await _cloudinaryService.initialize();
    AppLogger.info(_tag, 'Cloudinary Photo Upload Service initialized');
  }

  /// Pick image from gallery
  Future<File?> pickImageFromGallery() async {
    try {
      AppLogger.debug(_tag, 'Opening gallery to pick image');

      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 90, // Higher quality, Cloudinary will optimize
      );

      if (image == null) {
        AppLogger.info(_tag, 'User cancelled image selection');
        return null;
      }

      AppLogger.success(_tag, 'Image selected from gallery', {
        'path': image.path,
        'name': image.name,
      });

      return File(image.path);
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to pick image from gallery', e, stackTrace);
      return null;
    }
  }

  /// Pick image from camera
  Future<File?> pickImageFromCamera() async {
    try {
      AppLogger.debug(_tag, 'Opening camera to take photo');

      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 90, // Higher quality, Cloudinary will optimize
      );

      if (image == null) {
        AppLogger.info(_tag, 'User cancelled camera capture');
        return null;
      }

      AppLogger.success(_tag, 'Photo captured from camera', {
        'path': image.path,
        'name': image.name,
      });

      return File(image.path);
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to capture photo from camera', e, stackTrace);
      return null;
    }
  }

  /// Pick multiple images from gallery
  Future<List<File>> pickMultipleImagesFromGallery({int maxImages = 10}) async {
    try {
      AppLogger.debug(_tag, 'Opening gallery to pick multiple images', {
        'maxImages': maxImages,
      });

      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 90,
      );

      if (images.isEmpty) {
        AppLogger.info(_tag, 'No images selected');
        return [];
      }

      // Limit the number of images
      final limitedImages = images.take(maxImages).toList();

      AppLogger.success(_tag, 'Multiple images selected', {
        'count': limitedImages.length,
        'maxAllowed': maxImages,
      });

      return limitedImages.map((xFile) => File(xFile.path)).toList();
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to pick multiple images', e, stackTrace);
      return [];
    }
  }

  /// Upload user avatar to Cloudinary
  Future<String?> uploadAvatar(File imageFile) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      AppLogger.info(_tag, 'Uploading user avatar', {
        'userId': user.uid,
        'fileSize': imageFile.lengthSync(),
      });

      final avatarUrl = await _cloudinaryService.uploadAvatar(
        file: imageFile,
        userId: user.uid,
      );

      AppLogger.success(_tag, 'Avatar uploaded successfully', {
        'userId': user.uid,
        'url': avatarUrl,
      });

      return avatarUrl;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to upload avatar', e, stackTrace);
      return null;
    }
  }

  /// Upload gallery photo to Cloudinary
  Future<String?> uploadGalleryPhoto(File imageFile, {String? customId}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final photoId = customId ?? '${user.uid}_${DateTime.now().millisecondsSinceEpoch}';

      AppLogger.info(_tag, 'Uploading gallery photo', {
        'userId': user.uid,
        'photoId': photoId,
        'fileSize': imageFile.lengthSync(),
      });

      final photoUrl = await _cloudinaryService.uploadGalleryPhoto(
        file: imageFile,
        photoId: photoId,
      );

      AppLogger.success(_tag, 'Gallery photo uploaded successfully', {
        'userId': user.uid,
        'photoId': photoId,
        'url': photoUrl,
      });

      return photoUrl;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to upload gallery photo', e, stackTrace);
      return null;
    }
  }

  /// Upload destination cover image to Cloudinary
  Future<String?> uploadDestinationCover(File imageFile, String destinationId) async {
    try {
      AppLogger.info(_tag, 'Uploading destination cover', {
        'destinationId': destinationId,
        'fileSize': imageFile.lengthSync(),
      });

      final coverUrl = await _cloudinaryService.uploadDestinationCover(
        file: imageFile,
        destinationId: destinationId,
      );

      AppLogger.success(_tag, 'Destination cover uploaded successfully', {
        'destinationId': destinationId,
        'url': coverUrl,
      });

      return coverUrl;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to upload destination cover', e, stackTrace);
      return null;
    }
  }

  /// Upload multiple gallery photos
  Future<List<String>> uploadMultipleGalleryPhotos(List<File> imageFiles) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      AppLogger.info(_tag, 'Uploading multiple gallery photos', {
        'userId': user.uid,
        'count': imageFiles.length,
      });

      List<String> uploadedUrls = [];

      for (int i = 0; i < imageFiles.length; i++) {
        final file = imageFiles[i];
        final photoId = '${user.uid}_${DateTime.now().millisecondsSinceEpoch}_$i';

        try {
          final url = await uploadGalleryPhoto(file, customId: photoId);
          if (url != null) {
            uploadedUrls.add(url);
          }
        } catch (e) {
          AppLogger.error(_tag, 'Failed to upload individual photo $i (photoId: $photoId)', e);
        }
      }

      AppLogger.success(_tag, 'Multiple photos upload completed', {
        'total': imageFiles.length,
        'successful': uploadedUrls.length,
        'failed': imageFiles.length - uploadedUrls.length,
      });

      return uploadedUrls;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to upload multiple photos', e, stackTrace);
      return [];
    }
  }

  /// Upload generic image to specific folder
  Future<String?> uploadImage({
    required File imageFile,
    required String folder,
    String? fileName,
  }) async {
    try {
      AppLogger.info(_tag, 'Uploading image to folder', {
        'folder': folder,
        'fileName': fileName,
        'fileSize': imageFile.lengthSync(),
      });

      final imageUrl = await _cloudinaryService.uploadFile(
        file: imageFile,
        folder: folder,
        fileName: fileName,
      );

      AppLogger.success(_tag, 'Image uploaded successfully', {
        'folder': folder,
        'fileName': fileName,
        'url': imageUrl,
      });

      return imageUrl;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to upload image', e, stackTrace);
      return null;
    }
  }

  /// Get optimized image URL with specific dimensions
  String getOptimizedImageUrl({
    required String originalUrl,
    int? width,
    int? height,
    String quality = 'auto',
  }) {
    return _cloudinaryService.getOptimizedImageUrl(
      secureUrl: originalUrl,
      width: width,
      height: height,
      quality: quality,
    );
  }

  /// Get thumbnail URL (small optimized version)
  String getThumbnailUrl(String originalUrl, {int size = 150}) {
    return getOptimizedImageUrl(
      originalUrl: originalUrl,
      width: size,
      height: size,
      quality: 'auto',
    );
  }

  /// Get medium-sized image URL
  String getMediumImageUrl(String originalUrl, {int width = 600}) {
    return getOptimizedImageUrl(
      originalUrl: originalUrl,
      width: width,
      quality: 'auto',
    );
  }

  /// Get high-quality image URL
  String getHighQualityUrl(String originalUrl, {int maxWidth = 1920}) {
    return getOptimizedImageUrl(
      originalUrl: originalUrl,
      width: maxWidth,
      quality: '90',
    );
  }

  /// Delete image from Cloudinary
  Future<bool> deleteImage(String imageUrl) async {
    try {
      // Extract public ID from Cloudinary URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      final uploadIndex = pathSegments.indexOf('upload');
      
      if (uploadIndex == -1) {
        AppLogger.error(_tag, 'Invalid Cloudinary URL format: $imageUrl', null);
        return false;
      }
      
      final publicIdParts = pathSegments.sublist(uploadIndex + 1);
      final publicId = publicIdParts.join('/').split('.').first; // Remove extension
      
      AppLogger.info(_tag, 'Deleting image from Cloudinary', {
        'url': imageUrl,
        'publicId': publicId,
      });

      final success = await _cloudinaryService.deleteFile(publicId);

      AppLogger.success(_tag, 'Image deletion result', {
        'publicId': publicId,
        'success': success,
      });

      return success;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to delete image', e, stackTrace);
      return false;
    }
  }

  /// Validate image file
  bool validateImageFile(File imageFile) {
    try {
      // Check if file exists
      if (!imageFile.existsSync()) {
        AppLogger.error(_tag, 'Image file does not exist: ${imageFile.path}', null);
        return false;
      }

      // Check file size (max 10MB)
      final fileSizeBytes = imageFile.lengthSync();
      const maxSizeBytes = 10 * 1024 * 1024; // 10MB
      
      if (fileSizeBytes > maxSizeBytes) {
        AppLogger.error(_tag, 'Image file too large: ${fileSizeBytes}bytes (max: ${maxSizeBytes}bytes)', null);
        return false;
      }

      // Check file extension
      final extension = imageFile.path.split('.').last.toLowerCase();
      const allowedExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
      
      if (!allowedExtensions.contains(extension)) {
        AppLogger.error(_tag, 'Invalid image file extension: $extension (allowed: $allowedExtensions)', null);
        return false;
      }

      AppLogger.debug(_tag, 'Image file validation passed', {
        'path': imageFile.path,
        'size': fileSizeBytes,
        'extension': extension,
      });

      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to validate image file', e, stackTrace);
      return false;
    }
  }
}
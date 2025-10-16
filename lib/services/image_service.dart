import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import '../core/utils/logger.dart';

/// Service for image processing and optimization
class ImageService {
  static const String _tag = 'ImageService';

  // Singleton pattern
  static ImageService? _instance;
  static ImageService get instance => _instance ??= ImageService._internal();
  
  ImageService._internal();

  /// Process image for upload with compression and optimization
  Future<Uint8List> processImageForUpload({
    required File imageFile,
    int maxWidth = 1920,
    int maxHeight = 1080,
    int quality = 85,
  }) async {
    try {
      AppLogger.debug(_tag, 'Processing image for upload');

      // Read image bytes
      final bytes = await imageFile.readAsBytes();
      
      // Decode image
      final image = img.decodeImage(bytes);
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Resize if needed
      img.Image resizedImage = image;
      if (image.width > maxWidth || image.height > maxHeight) {
        resizedImage = img.copyResize(
          image,
          width: image.width > maxWidth ? maxWidth : null,
          height: image.height > maxHeight ? maxHeight : null,
          interpolation: img.Interpolation.linear,
        );
      }

      // Encode with quality compression
      final compressedBytes = img.encodeJpg(resizedImage, quality: quality);
      
      AppLogger.success(_tag, 'Image processed successfully', {
        'original_size': bytes.length,
        'compressed_size': compressedBytes.length,
        'compression_ratio': (bytes.length / compressedBytes.length).toStringAsFixed(2),
      });

      return Uint8List.fromList(compressedBytes);
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to process image', e, stackTrace);
      rethrow;
    }
  }

  /// Generate thumbnail from image
  Future<Uint8List> generateThumbnail({
    required File imageFile,
    int size = 200,
    int quality = 80,
  }) async {
    try {
      AppLogger.debug(_tag, 'Generating thumbnail');

      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Create square thumbnail
      final thumbnail = img.copyResize(image, width: size, height: size);
      final thumbnailBytes = img.encodeJpg(thumbnail, quality: quality);

      AppLogger.success(_tag, 'Thumbnail generated successfully');
      return Uint8List.fromList(thumbnailBytes);
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to generate thumbnail', e, stackTrace);
      rethrow;
    }
  }

  /// Extract image metadata
  Future<Map<String, dynamic>> extractImageMetadata(File imageFile) async {
    try {
      AppLogger.debug(_tag, 'Extracting image metadata');

      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      final metadata = {
        'width': image.width,
        'height': image.height,
        'format': 'JPEG', // Simplified for now
        'file_size': bytes.length,
        'aspect_ratio': (image.width / image.height).toStringAsFixed(2),
      };

      AppLogger.success(_tag, 'Image metadata extracted', metadata);
      return metadata;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to extract image metadata', e, stackTrace);
      return {};
    }
  }

  /// Validate image file
  Future<bool> validateImage(File imageFile) async {
    try {
      // Check if file exists
      if (!await imageFile.exists()) {
        return false;
      }

      // Check file size (max 10MB)
      final fileSize = await imageFile.length();
      if (fileSize > 10 * 1024 * 1024) {
        AppLogger.warning(_tag, 'Image file too large: $fileSize bytes');
        return false;
      }

      // Try to decode image
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      
      return image != null;
    } catch (e) {
      AppLogger.error(_tag, 'Image validation failed', e);
      return false;
    }
  }

  /// Apply image filters
  Future<Uint8List> applyFilter({
    required File imageFile,
    required String filterType,
    double intensity = 1.0,
  }) async {
    try {
      AppLogger.debug(_tag, 'Applying image filter: $filterType');

      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      img.Image filteredImage = image;

      switch (filterType) {
        case 'grayscale':
          filteredImage = img.grayscale(image);
          break;
        case 'sepia':
          filteredImage = img.sepia(image);
          break;
        case 'brighten':
          final brightened = img.brightness(image, (128 * intensity).round());
          if (brightened != null) filteredImage = brightened;
          break;
        case 'contrast':
          final contrasted = img.contrast(image, (128 * intensity).round());
          if (contrasted != null) filteredImage = contrasted;
          break;
        case 'blur':
          filteredImage = img.gaussianBlur(image, (5 * intensity).round());
          break;
        default:
          AppLogger.warning(_tag, 'Unknown filter type: $filterType');
      }

      final filteredBytes = img.encodeJpg(filteredImage, quality: 90);
      AppLogger.success(_tag, 'Image filter applied successfully');
      
      return Uint8List.fromList(filteredBytes);
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to apply image filter', e, stackTrace);
      rethrow;
    }
  }

  /// Get image dimensions without loading full image
  Future<Map<String, int>?> getImageDimensions(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      return {
        'width': image.width,
        'height': image.height,
      };
    } catch (e) {
      AppLogger.error(_tag, 'Failed to get image dimensions', e);
      return null;
    }
  }

  /// Calculate optimal image size for different use cases
  Map<String, int> calculateOptimalSize({
    required int originalWidth,
    required int originalHeight,
    required String useCase,
  }) {
    Map<String, int> targetSize;

    switch (useCase) {
      case 'thumbnail':
        targetSize = {'width': 200, 'height': 200};
        break;
      case 'profile':
        targetSize = {'width': 400, 'height': 400};
        break;
      case 'gallery':
        targetSize = {'width': 800, 'height': 600};
        break;
      case 'full':
        targetSize = {'width': 1920, 'height': 1080};
        break;
      default:
        targetSize = {'width': originalWidth, 'height': originalHeight};
    }

    // Maintain aspect ratio
    final aspectRatio = originalWidth / originalHeight;
    
    if (aspectRatio > 1) {
      // Landscape
      targetSize['height'] = (targetSize['width']! / aspectRatio).round();
    } else {
      // Portrait
      targetSize['width'] = (targetSize['height']! * aspectRatio).round();
    }

    return targetSize;
  }
}
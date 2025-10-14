import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import '../core/utils/logger.dart';
import '../core/config/env_config.dart';

/// Media Service
/// Handles Cloudinary media upload, management, and transformations
class MediaService {
  static const String _tag = 'MediaService';
  
  // Cloudinary configuration
  static String get _cloudName => EnvConfig.cloudinaryCloudName;
  static String get _apiKey => EnvConfig.cloudinaryApiKey;
  static String get _apiSecret => EnvConfig.cloudinaryApiSecret;
  static String get _uploadPreset => EnvConfig.cloudinaryUploadPreset;
  
  static const String _baseUrl = 'https://api.cloudinary.com/v1_1';
  static const String _uploadUrl = 'image/upload';
  static const String _videoUploadUrl = 'video/upload';

  // ===============================
  // IMAGE UPLOAD & MANAGEMENT
  // ===============================

  /// Upload image to Cloudinary
  static Future<Map<String, dynamic>> uploadImage({
    required File imageFile,
    String? folder,
    String? publicId,
    List<String>? tags,
    Map<String, dynamic>? context,
    String? transformation,
    bool useFilename = false,
    bool uniqueFilename = true,
    bool overwrite = false,
  }) async {
    try {
      AppLogger.debug(_tag, 'Uploading image to Cloudinary');

      final uri = Uri.parse('$_baseUrl/$_cloudName/$_uploadUrl');
      final request = http.MultipartRequest('POST', uri);

      // Add file
      final fileBytes = await imageFile.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: imageFile.path.split('/').last,
        ),
      );

      // Basic parameters
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final params = <String, String>{
        'timestamp': timestamp.toString(),
        'upload_preset': _uploadPreset,
      };

      // Optional parameters
      if (folder != null) params['folder'] = folder;
      if (publicId != null) params['public_id'] = publicId;
      if (tags != null) params['tags'] = tags.join(',');
      if (context != null) params['context'] = _encodeContext(context);
      if (transformation != null) params['transformation'] = transformation;
      if (useFilename) params['use_filename'] = 'true';
      if (uniqueFilename) params['unique_filename'] = 'true';
      if (overwrite) params['overwrite'] = 'true';

      // Generate signature
      final signature = _generateSignature(params, _apiSecret);
      params['signature'] = signature;
      params['api_key'] = _apiKey;

      // Add all parameters to request
      request.fields.addAll(params);

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final result = json.decode(responseBody) as Map<String, dynamic>;
        AppLogger.success(_tag, 'Image uploaded successfully: ${result['public_id']}');
        return result;
      } else {
        final error = json.decode(responseBody);
        throw Exception('Cloudinary upload failed: ${error['error']['message']}');
      }
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to upload image', e, stackTrace);
      rethrow;
    }
  }

  /// Upload image from bytes
  static Future<Map<String, dynamic>> uploadImageFromBytes({
    required Uint8List imageBytes,
    String? filename,
    String? folder,
    String? publicId,
    List<String>? tags,
    Map<String, dynamic>? context,
    String? transformation,
  }) async {
    try {
      AppLogger.debug(_tag, 'Uploading image from bytes to Cloudinary');

      final uri = Uri.parse('$_baseUrl/$_cloudName/$_uploadUrl');
      final request = http.MultipartRequest('POST', uri);

      // Add file from bytes
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: filename ?? 'image_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      );

      // Basic parameters
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final params = <String, String>{
        'timestamp': timestamp.toString(),
        'upload_preset': _uploadPreset,
      };

      // Optional parameters
      if (folder != null) params['folder'] = folder;
      if (publicId != null) params['public_id'] = publicId;
      if (tags != null) params['tags'] = tags.join(',');
      if (context != null) params['context'] = _encodeContext(context);
      if (transformation != null) params['transformation'] = transformation;

      // Generate signature
      final signature = _generateSignature(params, _apiSecret);
      params['signature'] = signature;
      params['api_key'] = _apiKey;

      // Add all parameters to request
      request.fields.addAll(params);

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final result = json.decode(responseBody) as Map<String, dynamic>;
        AppLogger.success(_tag, 'Image uploaded from bytes successfully: ${result['public_id']}');
        return result;
      } else {
        final error = json.decode(responseBody);
        throw Exception('Cloudinary upload failed: ${error['error']['message']}');
      }
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to upload image from bytes', e, stackTrace);
      rethrow;
    }
  }

  /// Upload multiple images
  static Future<List<Map<String, dynamic>>> uploadMultipleImages({
    required List<File> imageFiles,
    String? folder,
    List<String>? tags,
    String? transformation,
  }) async {
    try {
      AppLogger.debug(_tag, 'Uploading ${imageFiles.length} images to Cloudinary');

      final results = <Map<String, dynamic>>[];
      
      for (int i = 0; i < imageFiles.length; i++) {
        try {
          final result = await uploadImage(
            imageFile: imageFiles[i],
            folder: folder,
            tags: tags,
            transformation: transformation,
            publicId: '${folder ?? 'multi'}_${i}_${DateTime.now().millisecondsSinceEpoch}',
          );
          results.add(result);
        } catch (e) {
          AppLogger.warning(_tag, 'Failed to upload image ${i + 1}: $e');
          // Continue with other uploads
        }
      }

      AppLogger.success(_tag, 'Uploaded ${results.length}/${imageFiles.length} images successfully');
      return results;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to upload multiple images', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // VIDEO UPLOAD & MANAGEMENT
  // ===============================

  /// Upload video to Cloudinary
  static Future<Map<String, dynamic>> uploadVideo({
    required File videoFile,
    String? folder,
    String? publicId,
    List<String>? tags,
    String? transformation,
    bool useFilename = false,
    bool uniqueFilename = true,
    int? maxFileSize, // in bytes
  }) async {
    try {
      AppLogger.debug(_tag, 'Uploading video to Cloudinary');

      // Check file size if specified
      if (maxFileSize != null) {
        final fileSize = await videoFile.length();
        if (fileSize > maxFileSize) {
          throw Exception('Video file size exceeds maximum allowed size');
        }
      }

      final uri = Uri.parse('$_baseUrl/$_cloudName/$_videoUploadUrl');
      final request = http.MultipartRequest('POST', uri);

      // Add file
      final fileBytes = await videoFile.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: videoFile.path.split('/').last,
        ),
      );

      // Basic parameters
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final params = <String, String>{
        'timestamp': timestamp.toString(),
        'resource_type': 'video',
        'upload_preset': _uploadPreset,
      };

      // Optional parameters
      if (folder != null) params['folder'] = folder;
      if (publicId != null) params['public_id'] = publicId;
      if (tags != null) params['tags'] = tags.join(',');
      if (transformation != null) params['transformation'] = transformation;
      if (useFilename) params['use_filename'] = 'true';
      if (uniqueFilename) params['unique_filename'] = 'true';

      // Generate signature
      final signature = _generateSignature(params, _apiSecret);
      params['signature'] = signature;
      params['api_key'] = _apiKey;

      // Add all parameters to request
      request.fields.addAll(params);

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final result = json.decode(responseBody) as Map<String, dynamic>;
        AppLogger.success(_tag, 'Video uploaded successfully: ${result['public_id']}');
        return result;
      } else {
        final error = json.decode(responseBody);
        throw Exception('Cloudinary video upload failed: ${error['error']['message']}');
      }
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to upload video', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // IMAGE TRANSFORMATIONS
  // ===============================

  /// Generate optimized image URL with transformations
  static String getOptimizedImageUrl({
    required String publicId,
    int? width,
    int? height,
    String? crop,
    String? quality,
    String? format,
    List<String>? effects,
    bool? secure,
  }) {
    try {
      final transformations = <String>[];
      
      if (width != null) transformations.add('w_$width');
      if (height != null) transformations.add('h_$height');
      if (crop != null) transformations.add('c_$crop');
      if (quality != null) transformations.add('q_$quality');
      if (format != null) transformations.add('f_$format');
      if (effects != null) transformations.addAll(effects);

      final transformationString = transformations.isNotEmpty 
          ? '/${transformations.join(',')}'
          : '';

      final protocol = secure ?? true ? 'https' : 'http';
      
      return '$protocol://res.cloudinary.com/$_cloudName/image/upload$transformationString/$publicId';
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to generate optimized image URL', e, stackTrace);
      rethrow;
    }
  }

  /// Generate thumbnail URL
  static String getThumbnailUrl({
    required String publicId,
    int width = 150,
    int height = 150,
    String crop = 'fill',
    String quality = 'auto',
    String format = 'jpg',
  }) {
    return getOptimizedImageUrl(
      publicId: publicId,
      width: width,
      height: height,
      crop: crop,
      quality: quality,
      format: format,
    );
  }

  /// Generate responsive image URLs
  static Map<String, String> getResponsiveImageUrls({
    required String publicId,
    String? crop,
    String? quality,
    String? format,
  }) {
    final sizes = {
      'small': 480,
      'medium': 768,
      'large': 1024,
      'xlarge': 1440,
    };

    final urls = <String, String>{};
    
    for (final entry in sizes.entries) {
      urls[entry.key] = getOptimizedImageUrl(
        publicId: publicId,
        width: entry.value,
        crop: crop ?? 'scale',
        quality: quality ?? 'auto',
        format: format ?? 'auto',
      );
    }

    return urls;
  }

  // ===============================
  // MEDIA MANAGEMENT
  // ===============================

  /// Delete media from Cloudinary
  static Future<Map<String, dynamic>> deleteMedia({
    required String publicId,
    String resourceType = 'image',
  }) async {
    try {
      AppLogger.debug(_tag, 'Deleting media from Cloudinary: $publicId');

      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final params = <String, String>{
        'public_id': publicId,
        'timestamp': timestamp.toString(),
      };

      // Generate signature
      final signature = _generateSignature(params, _apiSecret);
      
      final uri = Uri.parse('$_baseUrl/$_cloudName/$resourceType/destroy');
      
      final response = await http.post(
        uri,
        body: {
          ...params,
          'signature': signature,
          'api_key': _apiKey,
        },
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body) as Map<String, dynamic>;
        AppLogger.success(_tag, 'Media deleted successfully: $publicId');
        return result;
      } else {
        final error = json.decode(response.body);
        throw Exception('Cloudinary delete failed: ${error['error']['message']}');
      }
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to delete media', e, stackTrace);
      rethrow;
    }
  }

  /// Get media details
  static Future<Map<String, dynamic>> getMediaDetails({
    required String publicId,
    String resourceType = 'image',
  }) async {
    try {
      AppLogger.debug(_tag, 'Getting media details: $publicId');

      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final params = <String, String>{
        'timestamp': timestamp.toString(),
      };

      // Generate signature
      final signature = _generateSignature(params, _apiSecret);
      
      final uri = Uri.parse('$_baseUrl/$_cloudName/$resourceType/upload/$publicId');
      final queryParams = {
        ...params,
        'signature': signature,
        'api_key': _apiKey,
      };

      final response = await http.get(
        uri.replace(queryParameters: queryParams),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body) as Map<String, dynamic>;
        AppLogger.success(_tag, 'Retrieved media details: $publicId');
        return result;
      } else {
        final error = json.decode(response.body);
        throw Exception('Cloudinary get details failed: ${error['error']['message']}');
      }
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get media details', e, stackTrace);
      rethrow;
    }
  }

  /// List media in folder
  static Future<List<Map<String, dynamic>>> listMediaInFolder({
    String? folder,
    String resourceType = 'image',
    int maxResults = 100,
    String? nextCursor,
  }) async {
    try {
      AppLogger.debug(_tag, 'Listing media in folder: $folder');

      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final params = <String, String>{
        'timestamp': timestamp.toString(),
        'max_results': maxResults.toString(),
      };

      if (folder != null) params['prefix'] = folder;
      if (nextCursor != null) params['next_cursor'] = nextCursor;

      // Generate signature
      final signature = _generateSignature(params, _apiSecret);
      
      final uri = Uri.parse('$_baseUrl/$_cloudName/$resourceType/list');
      final queryParams = {
        ...params,
        'signature': signature,
        'api_key': _apiKey,
      };

      final response = await http.get(
        uri.replace(queryParameters: queryParams),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body) as Map<String, dynamic>;
        final resources = List<Map<String, dynamic>>.from(result['resources'] ?? []);
        
        AppLogger.success(_tag, 'Listed ${resources.length} media items');
        return resources;
      } else {
        final error = json.decode(response.body);
        throw Exception('Cloudinary list failed: ${error['error']['message']}');
      }
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to list media in folder', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // UTILITY METHODS
  // ===============================

  /// Extract public ID from Cloudinary URL
  static String? extractPublicIdFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      
      // Find the upload segment
      final uploadIndex = pathSegments.indexOf('upload');
      if (uploadIndex == -1 || uploadIndex >= pathSegments.length - 1) {
        return null;
      }

      // Get everything after upload, removing transformations
      final afterUpload = pathSegments.sublist(uploadIndex + 1);
      
      // Remove version if present (starts with 'v' followed by numbers)
      final publicIdParts = <String>[];
      bool foundVersion = false;
      
      for (final segment in afterUpload) {
        if (!foundVersion && RegExp(r'^v\d+$').hasMatch(segment)) {
          foundVersion = true;
          continue;
        }
        publicIdParts.add(segment);
      }

      if (publicIdParts.isEmpty) return null;

      // Join segments and remove file extension
      String publicId = publicIdParts.join('/');
      final lastDotIndex = publicId.lastIndexOf('.');
      if (lastDotIndex != -1) {
        publicId = publicId.substring(0, lastDotIndex);
      }

      return publicId;
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to extract public ID from URL: $url', e);
      return null;
    }
  }

  /// Check if file is valid image
  static bool isValidImageFile(File file) {
    final allowedExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'];
    final extension = file.path.split('.').last.toLowerCase();
    return allowedExtensions.contains(extension);
  }

  /// Check if file is valid video
  static bool isValidVideoFile(File file) {
    final allowedExtensions = ['mp4', 'avi', 'mov', 'wmv', 'flv', 'webm', 'mkv'];
    final extension = file.path.split('.').last.toLowerCase();
    return allowedExtensions.contains(extension);
  }

  /// Get file size in MB
  static Future<double> getFileSizeInMB(File file) async {
    final bytes = await file.length();
    return bytes / (1024 * 1024);
  }

  // ===============================
  // PRIVATE HELPER METHODS
  // ===============================

  /// Generate Cloudinary signature
  static String _generateSignature(Map<String, String> params, String apiSecret) {
    // Sort parameters by key
    final sortedParams = Map<String, String>.fromEntries(
      params.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );

    // Create parameter string
    final paramString = sortedParams.entries
        .map((entry) => '${entry.key}=${entry.value}')
        .join('&');

    // Generate SHA1 hash
    final bytes = utf8.encode(paramString + apiSecret);
    final digest = sha1.convert(bytes);
    
    return digest.toString();
  }

  /// Encode context for Cloudinary
  static String _encodeContext(Map<String, dynamic> context) {
    return context.entries
        .map((entry) => '${entry.key}=${entry.value}')
        .join('|');
  }
}
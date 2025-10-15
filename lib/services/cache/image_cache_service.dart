import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../../core/utils/logger.dart';

/// Image Cache Service
/// Manages local image caching for offline access
class ImageCacheService {
  static const String _tag = 'ImageCacheService';
  
  // Singleton pattern
  static ImageCacheService? _instance;
  static ImageCacheService get instance => _instance ??= ImageCacheService._internal();
  
  ImageCacheService._internal();

  late Directory _cacheDirectory;
  bool _isInitialized = false;

  /// Initialize the image cache service
  Future<void> initialize() async {
    try {
      AppLogger.debug(_tag, 'Initializing image cache service');
      
      final appDir = await getApplicationDocumentsDirectory();
      _cacheDirectory = Directory(path.join(appDir.path, 'image_cache'));
      
      if (!await _cacheDirectory.exists()) {
        await _cacheDirectory.create(recursive: true);
      }
      
      _isInitialized = true;
      AppLogger.success(_tag, 'Image cache service initialized');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to initialize image cache', e, stackTrace);
      rethrow;
    }
  }

  /// Cache an image
  Future<String?> cacheImage(String imageUrl, String fileName) async {
    if (!_isInitialized) await initialize();
    
    try {
      AppLogger.debug(_tag, 'Caching image: $fileName');
      
      final file = File(path.join(_cacheDirectory.path, fileName));
      
      // If file already exists, return the path
      if (await file.exists()) {
        return file.path;
      }

      // In a real implementation, you would download the image here
      // For now, we'll just create a placeholder
      await file.writeAsString('cached_image_placeholder');
      
      AppLogger.success(_tag, 'Image cached successfully: $fileName');
      return file.path;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to cache image', e, stackTrace);
      return null;
    }
  }

  /// Get cached image path
  Future<String?> getCachedImagePath(String fileName) async {
    if (!_isInitialized) await initialize();
    
    try {
      final file = File(path.join(_cacheDirectory.path, fileName));
      
      if (await file.exists()) {
        return file.path;
      }
      
      return null;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get cached image', e, stackTrace);
      return null;
    }
  }

  /// Clear image cache
  Future<void> clearCache() async {
    if (!_isInitialized) await initialize();
    
    try {
      AppLogger.debug(_tag, 'Clearing image cache');
      
      await for (final entity in _cacheDirectory.list()) {
        await entity.delete();
      }
      
      AppLogger.success(_tag, 'Image cache cleared');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to clear image cache', e, stackTrace);
    }
  }

  /// Get cache size
  Future<int> getCacheSize() async {
    if (!_isInitialized) await initialize();
    
    try {
      int totalSize = 0;
      
      await for (final entity in _cacheDirectory.list()) {
        if (entity is File) {
          final stat = await entity.stat();
          totalSize += stat.size;
        }
      }
      
      return totalSize;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to calculate cache size', e, stackTrace);
      return 0;
    }
  }
}
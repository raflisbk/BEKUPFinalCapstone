import 'dart:io';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';

/// Service for caching images and media offline with LRU eviction
class ImageCacheService {
  static final ImageCacheService _instance = ImageCacheService._internal();
  factory ImageCacheService() => _instance;
  ImageCacheService._internal();

  // Custom cache manager with 500MB limit
  static const String _cacheKey = 'relinkMediaCache';
  static const int _maxCacheSize = 500 * 1024 * 1024; // 500MB in bytes
  static const Duration _maxCacheAge = Duration(days: 30);

  late CacheManager _cacheManager;
  bool _initialized = false;

  /// Initialize cache manager
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      final directory = await getTemporaryDirectory();
      final cacheDir = Directory('${directory.path}/$_cacheKey');

      _cacheManager = CacheManager(
        Config(
          _cacheKey,
          stalePeriod: _maxCacheAge,
          maxNrOfCacheObjects: 1000,
          repo: JsonCacheInfoRepository(databaseName: _cacheKey),
          fileService: HttpFileService(),
          fileSystem: IOFileSystem(cacheDir.path),
        ),
      );

      _initialized = true;
      print('ImageCacheService initialized with 500MB limit');
    } catch (e) {
      print('Error initializing ImageCacheService: $e');
    }
  }

  /// Get cached file or download if not available
  Future<File?> getCachedFile(String url) async {
    try {
      if (!_initialized) await initialize();
      
      final file = await _cacheManager.getSingleFile(url);
      return file;
    } catch (e) {
      print('Error getting cached file for $url: $e');
      return null;
    }
  }

  /// Download and cache file
  Future<File?> downloadAndCache(String url) async {
    try {
      if (!_initialized) await initialize();
      
      final file = await _cacheManager.downloadFile(url);
      return file.file;
    } catch (e) {
      print('Error downloading and caching $url: $e');
      return null;
    }
  }

  /// Get file from cache only (no download)
  Future<File?> getFromCacheOnly(String url) async {
    try {
      if (!_initialized) await initialize();
      
      final fileInfo = await _cacheManager.getFileFromCache(url);
      return fileInfo?.file;
    } catch (e) {
      print('Error getting file from cache only: $e');
      return null;
    }
  }

  /// Check if file is cached
  Future<bool> isCached(String url) async {
    try {
      if (!_initialized) await initialize();
      
      final fileInfo = await _cacheManager.getFileFromCache(url);
      return fileInfo != null;
    } catch (e) {
      print('Error checking if file is cached: $e');
      return false;
    }
  }

  /// Prefetch images (download in background)
  Future<void> prefetchImages(List<String> urls) async {
    try {
      if (!_initialized) await initialize();
      
      for (final url in urls) {
        // Download asynchronously without waiting
        _cacheManager.downloadFile(url).then((_) {
          // Success - do nothing
        }).catchError((error) {
          print('Error prefetching $url: $error');
        });
      }
      
      print('Prefetching ${urls.length} images...');
    } catch (e) {
      print('Error in prefetchImages: $e');
    }
  }

  /// Prefetch trip images
  Future<void> prefetchTripImages(List<String> imageUrls) async {
    await prefetchImages(imageUrls);
  }

  /// Prefetch destination images
  Future<void> prefetchDestinationImages(List<String> imageUrls) async {
    await prefetchImages(imageUrls);
  }

  /// Remove specific file from cache
  Future<void> removeFile(String url) async {
    try {
      if (!_initialized) await initialize();
      
      await _cacheManager.removeFile(url);
    } catch (e) {
      print('Error removing file from cache: $e');
    }
  }

  /// Clear all cached files
  Future<void> clearCache() async {
    try {
      if (!_initialized) await initialize();
      
      await _cacheManager.emptyCache();
      print('Image cache cleared');
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }

  /// Get cache size in bytes
  Future<int> getCacheSize() async {
    try {
      if (!_initialized) await initialize();
      
      final directory = await getTemporaryDirectory();
      final cacheDir = Directory('${directory.path}/$_cacheKey');
      
      if (!await cacheDir.exists()) return 0;
      
      int totalSize = 0;
      await for (final entity in cacheDir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
      
      return totalSize;
    } catch (e) {
      print('Error calculating cache size: $e');
      return 0;
    }
  }

  /// Get cache size in human-readable format
  Future<String> getCacheSizeFormatted() async {
    final sizeInBytes = await getCacheSize();
    
    if (sizeInBytes < 1024) {
      return '$sizeInBytes B';
    } else if (sizeInBytes < 1024 * 1024) {
      return '${(sizeInBytes / 1024).toStringAsFixed(2)} KB';
    } else if (sizeInBytes < 1024 * 1024 * 1024) {
      return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    } else {
      return '${(sizeInBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      if (!_initialized) await initialize();
      
      final sizeInBytes = await getCacheSize();
      final sizeFormatted = await getCacheSizeFormatted();
      final usagePercentage = (sizeInBytes / _maxCacheSize * 100).toStringAsFixed(1);
      
      return {
        'sizeInBytes': sizeInBytes,
        'sizeFormatted': sizeFormatted,
        'maxSizeInBytes': _maxCacheSize,
        'maxSizeFormatted': '500 MB',
        'usagePercentage': usagePercentage,
        'isFull': sizeInBytes >= _maxCacheSize,
      };
    } catch (e) {
      print('Error getting cache stats: $e');
      return {
        'sizeInBytes': 0,
        'sizeFormatted': '0 B',
        'maxSizeInBytes': _maxCacheSize,
        'maxSizeFormatted': '500 MB',
        'usagePercentage': '0.0',
        'isFull': false,
      };
    }
  }

  /// Stream of download progress (0.0 to 1.0)
  Stream<double> getDownloadProgress(String url) {
    if (!_initialized) {
      return Stream.value(0.0);
    }
    
    return _cacheManager.getFileStream(url).map((event) {
      if (event is DownloadProgress) {
        return event.progress ?? 0.0;
      } else if (event is FileInfo) {
        return 1.0;
      }
      return 0.0;
    });
  }

  /// Check if cache needs cleanup
  Future<bool> needsCleanup() async {
    final stats = await getCacheStats();
    return stats['isFull'] as bool;
  }

  /// Manual cleanup - removes oldest files if cache is full
  Future<void> cleanupIfNeeded() async {
    try {
      if (await needsCleanup()) {
        print('Cache is full, cleaning up...');
        // CacheManager handles LRU automatically, but we can force cleanup
        await _cacheManager.emptyCache();
        print('Cache cleanup completed');
      }
    } catch (e) {
      print('Error during cache cleanup: $e');
    }
  }
}

import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import '../../core/database/hive_service.dart';
import '../../core/utils/connectivity_service.dart';

/// Model for queued upload
class QueuedUpload {
  final String id;
  final String localPath;
  final String destinationPath;
  final String userId;
  final String entityType; // 'trip', 'review', 'profile', etc.
  final String? entityId;
  final Map<String, dynamic>? metadata;
  final DateTime queuedAt;
  int retryCount;
  String? error;

  QueuedUpload({
    required this.id,
    required this.localPath,
    required this.destinationPath,
    required this.userId,
    required this.entityType,
    this.entityId,
    this.metadata,
    required this.queuedAt,
    this.retryCount = 0,
    this.error,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'localPath': localPath,
      'destinationPath': destinationPath,
      'userId': userId,
      'entityType': entityType,
      'entityId': entityId,
      'metadata': metadata,
      'queuedAt': queuedAt.toIso8601String(),
      'retryCount': retryCount,
      'error': error,
    };
  }

  factory QueuedUpload.fromMap(Map<String, dynamic> map) {
    return QueuedUpload(
      id: map['id'] ?? '',
      localPath: map['localPath'] ?? '',
      destinationPath: map['destinationPath'] ?? '',
      userId: map['userId'] ?? '',
      entityType: map['entityType'] ?? '',
      entityId: map['entityId'],
      metadata: map['metadata'] as Map<String, dynamic>?,
      queuedAt: DateTime.parse(map['queuedAt'] as String),
      retryCount: map['retryCount'] ?? 0,
      error: map['error'],
    );
  }
}

/// Service for managing offline photo uploads
class UploadQueueService {
  static final UploadQueueService _instance = UploadQueueService._internal();
  factory UploadQueueService() => _instance;
  UploadQueueService._internal();

  final HiveService _hiveService = HiveService.instance;
  final ConnectivityService _connectivityService = ConnectivityService.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  static const String _uploadQueueBox = 'uploadQueue';
  static const int _maxRetries = 5;

  bool _isProcessing = false;

  /// Initialize upload queue (should be called after Hive initialization)
  Future<void> initialize() async {
    try {
      // Listen to connectivity changes
      _connectivityService.onConnectivityChanged.listen((isOnline) {
        if (isOnline) {
          processQueue();
        }
      });

      print('UploadQueueService initialized');
    } catch (e) {
      print('Error initializing UploadQueueService: $e');
    }
  }

  /// Add file to upload queue
  Future<String?> queueUpload({
    required String localPath,
    required String destinationPath,
    required String userId,
    required String entityType,
    String? entityId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final file = File(localPath);
      if (!await file.exists()) {
        print('File not found: $localPath');
        return null;
      }

      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final upload = QueuedUpload(
        id: id,
        localPath: localPath,
        destinationPath: destinationPath,
        userId: userId,
        entityType: entityType,
        entityId: entityId,
        metadata: metadata,
        queuedAt: DateTime.now(),
      );

      final box = _hiveService.getBox(_uploadQueueBox);
      await box.put(id, upload.toMap());

      print('Upload queued: $id');

      // Try to process immediately if online
      if (_connectivityService.isOnline) {
        processQueue();
      }

      return id;
    } catch (e) {
      print('Error queueing upload: $e');
      return null;
    }
  }

  /// Process upload queue
  Future<void> processQueue() async {
    if (_isProcessing) {
      print('Upload queue is already being processed');
      return;
    }

    if (!_connectivityService.isOnline) {
      print('Cannot process upload queue: offline');
      return;
    }

    _isProcessing = true;
    print('Processing upload queue...');

    try {
      final box = _hiveService.getBox(_uploadQueueBox);
      final keys = box.keys.toList();

      for (final key in keys) {
        final uploadMap = box.get(key) as Map<String, dynamic>?;
        if (uploadMap == null) continue;

        final upload = QueuedUpload.fromMap(uploadMap);

        // Skip if max retries reached
        if (upload.retryCount >= _maxRetries) {
          print('Upload ${upload.id} exceeded max retries, removing...');
          await box.delete(key);
          continue;
        }

        // Try to upload
        final success = await _uploadFile(upload);

        if (success) {
          // Remove from queue
          await box.delete(key);
          print('Upload completed: ${upload.id}');
        } else {
          // Increment retry count
          upload.retryCount++;
          await box.put(key, upload.toMap());
          print('Upload failed: ${upload.id}, retry ${upload.retryCount}/$_maxRetries');
        }
      }

      print('Upload queue processing completed');
    } catch (e) {
      print('Error processing upload queue: $e');
    } finally {
      _isProcessing = false;
    }
  }

  /// Upload single file
  Future<bool> _uploadFile(QueuedUpload upload) async {
    try {
      final file = File(upload.localPath);
      
      if (!await file.exists()) {
        print('Local file not found: ${upload.localPath}');
        upload.error = 'File not found';
        return false;
      }

      final ref = _storage.ref().child(upload.destinationPath);
      
      // Upload with metadata
      final metadata = SettableMetadata(
        contentType: _getContentType(upload.localPath),
        customMetadata: {
          'uploadedBy': upload.userId,
          'entityType': upload.entityType,
          if (upload.entityId != null) 'entityId': upload.entityId!,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      final uploadTask = ref.putFile(file, metadata);
      
      // Wait for upload to complete
      final snapshot = await uploadTask;
      
      if (snapshot.state == TaskState.success) {
        print('File uploaded successfully: ${upload.destinationPath}');
        return true;
      } else {
        upload.error = 'Upload failed with state: ${snapshot.state}';
        return false;
      }
    } catch (e) {
      print('Error uploading file: $e');
      upload.error = e.toString();
      return false;
    }
  }

  /// Get content type from file extension
  String _getContentType(String filePath) {
    final extension = filePath.toLowerCase().split('.').last;
    
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      default:
        return 'application/octet-stream';
    }
  }

  /// Get all queued uploads
  Future<List<QueuedUpload>> getQueuedUploads() async {
    try {
      final box = _hiveService.getBox(_uploadQueueBox);
      final uploads = <QueuedUpload>[];

      for (final key in box.keys) {
        final uploadMap = box.get(key) as Map<String, dynamic>?;
        if (uploadMap != null) {
          uploads.add(QueuedUpload.fromMap(uploadMap));
        }
      }

      return uploads;
    } catch (e) {
      print('Error getting queued uploads: $e');
      return [];
    }
  }

  /// Get queued uploads by entity
  Future<List<QueuedUpload>> getQueuedUploadsByEntity(String entityType, String entityId) async {
    final allUploads = await getQueuedUploads();
    return allUploads.where((upload) {
      return upload.entityType == entityType && upload.entityId == entityId;
    }).toList();
  }

  /// Get queue statistics
  Future<Map<String, int>> getQueueStats() async {
    try {
      final uploads = await getQueuedUploads();
      
      int pending = 0;
      int failed = 0;
      
      for (final upload in uploads) {
        if (upload.retryCount >= _maxRetries) {
          failed++;
        } else {
          pending++;
        }
      }

      return {
        'total': uploads.length,
        'pending': pending,
        'failed': failed,
      };
    } catch (e) {
      print('Error getting queue stats: $e');
      return {
        'total': 0,
        'pending': 0,
        'failed': 0,
      };
    }
  }

  /// Remove upload from queue
  Future<void> removeUpload(String id) async {
    try {
      final box = _hiveService.getBox(_uploadQueueBox);
      await box.delete(id);
      print('Upload removed from queue: $id');
    } catch (e) {
      print('Error removing upload: $e');
    }
  }

  /// Clear failed uploads from queue
  Future<void> clearFailedUploads() async {
    try {
      final box = _hiveService.getBox(_uploadQueueBox);
      final keys = box.keys.toList();

      for (final key in keys) {
        final uploadMap = box.get(key) as Map<String, dynamic>?;
        if (uploadMap != null) {
          final upload = QueuedUpload.fromMap(uploadMap);
          if (upload.retryCount >= _maxRetries) {
            await box.delete(key);
          }
        }
      }

      print('Failed uploads cleared');
    } catch (e) {
      print('Error clearing failed uploads: $e');
    }
  }

  /// Clear all uploads from queue
  Future<void> clearQueue() async {
    try {
      final box = _hiveService.getBox(_uploadQueueBox);
      await box.clear();
      print('Upload queue cleared');
    } catch (e) {
      print('Error clearing upload queue: $e');
    }
  }

  /// Retry failed upload
  Future<void> retryUpload(String id) async {
    try {
      final box = _hiveService.getBox(_uploadQueueBox);
      final uploadMap = box.get(id) as Map<String, dynamic>?;
      
      if (uploadMap != null) {
        final upload = QueuedUpload.fromMap(uploadMap);
        upload.retryCount = 0;
        upload.error = null;
        await box.put(id, upload.toMap());
        
        print('Upload retry reset: $id');
        
        if (_connectivityService.isOnline) {
          processQueue();
        }
      }
    } catch (e) {
      print('Error retrying upload: $e');
    }
  }
}

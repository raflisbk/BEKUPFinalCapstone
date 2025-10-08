import 'package:hive/hive.dart';

part 'cached_data.g.dart';

/// Generic cached data model for storing any entity
@HiveType(typeId: 0)
class CachedData extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  Map<String, dynamic> data;

  @HiveField(2)
  DateTime cachedAt;

  @HiveField(3)
  bool isDirty;

  @HiveField(4)
  DateTime? lastSyncedAt;

  CachedData({
    required this.id,
    required this.data,
    required this.cachedAt,
    this.isDirty = false,
    this.lastSyncedAt,
  });

  /// Check if cache is still valid (default: 1 hour)
  bool isValid({Duration maxAge = const Duration(hours: 1)}) {
    final age = DateTime.now().difference(cachedAt);
    return age < maxAge;
  }

  /// Mark as dirty (needs sync)
  void markDirty() {
    isDirty = true;
    save();
  }

  /// Mark as synced
  void markSynced() {
    isDirty = false;
    lastSyncedAt = DateTime.now();
    save();
  }

  @override
  String toString() {
    return 'CachedData(id: $id, isDirty: $isDirty, cachedAt: $cachedAt)';
  }
}

/// Sync operation model for queue
@HiveType(typeId: 1)
class SyncOperation extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String type; // 'create', 'update', 'delete'

  @HiveField(2)
  String collection; // 'trips', 'reviews', etc.

  @HiveField(3)
  Map<String, dynamic> data;

  @HiveField(4)
  DateTime timestamp;

  @HiveField(5)
  int retryCount;

  @HiveField(6)
  String? error;

  @HiveField(7)
  String? userId;

  SyncOperation({
    required this.id,
    required this.type,
    required this.collection,
    required this.data,
    required this.timestamp,
    this.retryCount = 0,
    this.error,
    this.userId,
  });

  /// Increment retry count
  void incrementRetry(String errorMessage) {
    retryCount++;
    error = errorMessage;
    save();
  }

  /// Check if max retries reached
  bool get hasMaxRetries => retryCount >= 5;

  /// Get priority (newer operations have higher priority)
  int get priority {
    final age = DateTime.now().difference(timestamp).inSeconds;
    return -age; // Newer = higher priority
  }

  /// Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'collection': collection,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'retryCount': retryCount,
      'error': error,
      'userId': userId,
    };
  }

  /// Create from Map
  factory SyncOperation.fromMap(Map<String, dynamic> map) {
    return SyncOperation(
      id: map['id'] ?? '',
      type: map['type'] ?? '',
      collection: map['collection'] ?? '',
      data: Map<String, dynamic>.from(map['data'] ?? {}),
      timestamp: DateTime.parse(map['timestamp'] as String),
      retryCount: map['retryCount'] ?? 0,
      error: map['error'],
      userId: map['userId'],
    );
  }

  @override
  String toString() {
    return 'SyncOperation(id: $id, type: $type, collection: $collection, retryCount: $retryCount)';
  }
}

/// App metadata model
class AppMetadata {
  DateTime? lastSyncTime;
  bool isOnline;
  int pendingOperations;
  int cacheSize;
  String? lastError;

  AppMetadata({
    this.lastSyncTime,
    this.isOnline = false,
    this.pendingOperations = 0,
    this.cacheSize = 0,
    this.lastError,
  });

  Map<String, dynamic> toMap() {
    return {
      'lastSyncTime': lastSyncTime?.toIso8601String(),
      'isOnline': isOnline,
      'pendingOperations': pendingOperations,
      'cacheSize': cacheSize,
      'lastError': lastError,
    };
  }

  factory AppMetadata.fromMap(Map<String, dynamic> map) {
    return AppMetadata(
      lastSyncTime: map['lastSyncTime'] != null
          ? DateTime.parse(map['lastSyncTime'] as String)
          : null,
      isOnline: map['isOnline'] as bool? ?? false,
      pendingOperations: map['pendingOperations'] as int? ?? 0,
      cacheSize: map['cacheSize'] as int? ?? 0,
      lastError: map['lastError'] as String?,
    );
  }
}

/// Sync-related models for offline synchronization
library sync_model;

/// Enum for sync status
enum SyncStatus {
  idle,
  syncing,
  completed,
  error,
  paused
}

/// Class representing sync progress information
class SyncProgress {
  final SyncStatus status;
  final int? total;
  final int? completed;
  final String? message;
  final DateTime timestamp;

  const SyncProgress({
    required this.status,
    this.total,
    this.completed,
    this.message,
    required this.timestamp,
  });

  factory SyncProgress.fromMap(Map<String, dynamic> map) {
    return SyncProgress(
      status: _parseStatus(map['status']),
      total: map['total'] as int?,
      completed: map['completed'] as int?,
      message: map['message'] as String?,
      timestamp: DateTime.now(),
    );
  }

  static SyncStatus _parseStatus(dynamic status) {
    if (status is String) {
      switch (status.toLowerCase()) {
        case 'syncing':
          return SyncStatus.syncing;
        case 'completed':
          return SyncStatus.completed;
        case 'error':
          return SyncStatus.error;
        case 'paused':
          return SyncStatus.paused;
        default:
          return SyncStatus.idle;
      }
    }
    return SyncStatus.idle;
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status.name,
      'total': total,
      'completed': completed,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'SyncProgress(status: $status, total: $total, completed: $completed)';
  }
}
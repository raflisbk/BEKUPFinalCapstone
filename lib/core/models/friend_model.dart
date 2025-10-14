/// Friend-related models for social functionality

/// Friend request model
class FriendRequest {
  final String id;
  final String senderId;
  final String receiverId;
  final String status; // 'pending', 'accepted', 'declined'
  final DateTime createdAt;
  final DateTime? respondedAt;

  FriendRequest({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.status,
    required this.createdAt,
    this.respondedAt,
  });

  /// Create from Map
  factory FriendRequest.fromMap(Map<String, dynamic> map) {
    return FriendRequest(
      id: map['id'] ?? '',
      senderId: map['sender_id'] ?? '',
      receiverId: map['receiver_id'] ?? '',
      status: map['status'] ?? 'pending',
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      respondedAt: map['responded_at'] != null ? DateTime.parse(map['responded_at']) : null,
    );
  }

  /// Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'responded_at': respondedAt?.toIso8601String(),
    };
  }

  /// Copy with modifications
  FriendRequest copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? status,
    DateTime? createdAt,
    DateTime? respondedAt,
  }) {
    return FriendRequest(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
    );
  }
}

/// Friendship model
class Friendship {
  final String id;
  final String userId1;
  final String userId2;
  final DateTime createdAt;
  final bool isBlocked;
  final String? blockedBy;

  Friendship({
    required this.id,
    required this.userId1,
    required this.userId2,
    required this.createdAt,
    this.isBlocked = false,
    this.blockedBy,
  });

  /// Create from Map
  factory Friendship.fromMap(Map<String, dynamic> map) {
    return Friendship(
      id: map['id'] ?? '',
      userId1: map['user_id_1'] ?? '',
      userId2: map['user_id_2'] ?? '',
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      isBlocked: map['is_blocked'] ?? false,
      blockedBy: map['blocked_by'],
    );
  }

  /// Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id_1': userId1,
      'user_id_2': userId2,
      'created_at': createdAt.toIso8601String(),
      'is_blocked': isBlocked,
      'blocked_by': blockedBy,
    };
  }
}

/// Friend activity model
class FriendActivity {
  final String id;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final String activityType; // 'photo_upload', 'trip_created', 'destination_visited', etc.
  final String title;
  final String? description;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  FriendActivity({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.activityType,
    required this.title,
    this.description,
    this.metadata,
    required this.createdAt,
  });

  /// Create from Map
  factory FriendActivity.fromMap(Map<String, dynamic> map) {
    return FriendActivity(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      userName: map['user_name'] ?? '',
      userPhotoUrl: map['user_photo_url'],
      activityType: map['activity_type'] ?? '',
      title: map['title'] ?? '',
      description: map['description'],
      metadata: map['metadata'],
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  /// Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'user_photo_url': userPhotoUrl,
      'activity_type': activityType,
      'title': title,
      'description': description,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
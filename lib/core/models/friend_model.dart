// Friend-related models for social functionality

/// Friend request status enum
enum FriendRequestStatus {
  pending,
  accepted,
  declined,
}

/// Friend request status helper
class FriendRequestStatusHelper {
  static String getLabel(FriendRequestStatus status) {
    switch (status) {
      case FriendRequestStatus.pending:
        return 'Pending';
      case FriendRequestStatus.accepted:
        return 'Accepted';
      case FriendRequestStatus.declined:
        return 'Declined';
    }
  }

  static String getValue(FriendRequestStatus status) {
    return status.toString().split('.').last;
  }

  static FriendRequestStatus fromString(String value) {
    return FriendRequestStatus.values.firstWhere(
      (status) => getValue(status) == value,
      orElse: () => FriendRequestStatus.pending,
    );
  }
}

/// Friend activity type enum
enum FriendActivityType {
  photoUpload,
  tripCreated,
  destinationVisited,
  reviewPosted,
  tripCompleted,
  friendAdded,
  statusUpdate,
  other,
}

/// Friend activity type helper
class FriendActivityTypeHelper {
  static String getLabel(FriendActivityType type) {
    switch (type) {
      case FriendActivityType.photoUpload:
        return 'Photo Upload';
      case FriendActivityType.tripCreated:
        return 'Trip Created';
      case FriendActivityType.destinationVisited:
        return 'Destination Visited';
      case FriendActivityType.reviewPosted:
        return 'Review Posted';
      case FriendActivityType.tripCompleted:
        return 'Trip Completed';
      case FriendActivityType.friendAdded:
        return 'Friend Added';
      case FriendActivityType.statusUpdate:
        return 'Status Update';
      case FriendActivityType.other:
        return 'Other';
    }
  }

  static String getValue(FriendActivityType type) {
    switch (type) {
      case FriendActivityType.photoUpload:
        return 'photo_upload';
      case FriendActivityType.tripCreated:
        return 'trip_created';
      case FriendActivityType.destinationVisited:
        return 'destination_visited';
      case FriendActivityType.reviewPosted:
        return 'review_posted';
      case FriendActivityType.tripCompleted:
        return 'trip_completed';
      case FriendActivityType.friendAdded:
        return 'friend_added';
      case FriendActivityType.statusUpdate:
        return 'status_update';
      case FriendActivityType.other:
        return 'other';
    }
  }

  static FriendActivityType fromString(String value) {
    return FriendActivityType.values.firstWhere(
      (type) => getValue(type) == value,
      orElse: () => FriendActivityType.other,
    );
  }
}

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

  /// Get status enum
  FriendRequestStatus get statusEnum => FriendRequestStatusHelper.fromString(status);

  /// Check if request is pending
  bool get isPending => status == 'pending';

  /// Check if request is accepted
  bool get isAccepted => status == 'accepted';

  /// Check if request is declined
  bool get isDeclined => status == 'declined';

  @override
  String toString() {
    return 'FriendRequest(id: $id, senderId: $senderId, receiverId: $receiverId, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FriendRequest && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
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

  /// Get the other user's ID in the friendship
  String getOtherUserId(String currentUserId) {
    return currentUserId == userId1 ? userId2 : userId1;
  }

  /// Check if a specific user blocked the friendship
  bool isBlockedBy(String userId) {
    return isBlocked && blockedBy == userId;
  }

  /// Check if friendship involves a specific user
  bool involvesUser(String userId) {
    return userId1 == userId || userId2 == userId;
  }

  @override
  String toString() {
    return 'Friendship(id: $id, userId1: $userId1, userId2: $userId2, isBlocked: $isBlocked)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Friendship && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
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

  /// Get activity type enum
  FriendActivityType get activityTypeEnum => FriendActivityTypeHelper.fromString(activityType);

  /// Get formatted time ago string
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  /// Check if activity has metadata
  bool get hasMetadata => metadata != null && metadata!.isNotEmpty;

  @override
  String toString() {
    return 'FriendActivity(id: $id, userId: $userId, activityType: $activityType, title: $title)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FriendActivity && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
import '../stubs/firebase_stubs.dart';
import 'package:flutter/material.dart';

/// Social connection model for follow system
class SocialConnection {
  final String userId;
  final List<String> following;
  final List<String> followers;
  final int followingCount;
  final int followersCount;

  SocialConnection({
    required this.userId,
    this.following = const [],
    this.followers = const [],
    required this.followingCount,
    required this.followersCount,
  });

  factory SocialConnection.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return SocialConnection(
      userId: doc.id,
      following: List<String>.from(data['following'] ?? []),
      followers: List<String>.from(data['followers'] ?? []),
      followingCount: data['followingCount'] ?? 0,
      followersCount: data['followersCount'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'following': following,
      'followers': followers,
      'followingCount': followingCount,
      'followersCount': followersCount,
    };
  }

  bool isFollowing(String userId) {
    return following.contains(userId);
  }

  bool isFollowedBy(String userId) {
    return followers.contains(userId);
  }
}

/// Activity feed item types
enum ActivityType {
  follow,
  like,
  comment,
  review,
  trip,
  photo,
}

/// Activity feed item model
class ActivityItem {
  final String id;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final ActivityType type;
  final String action;
  final String? targetId;
  final String? targetName;
  final String? targetImageUrl;
  final DateTime createdAt;

  ActivityItem({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.type,
    required this.action,
    this.targetId,
    this.targetName,
    this.targetImageUrl,
    required this.createdAt,
  });

  factory ActivityItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ActivityItem(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userPhotoUrl: data['userPhotoUrl'],
      type: ActivityType.values.firstWhere(
        (e) => e.toString() == 'ActivityType.${data['type']}',
        orElse: () => ActivityType.like,
      ),
      action: data['action'] ?? '',
      targetId: data['targetId'],
      targetName: data['targetName'],
      targetImageUrl: data['targetImageUrl'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'type': type.toString().split('.').last,
      'action': action,
      'targetId': targetId,
      'targetName': targetName,
      'targetImageUrl': targetImageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

/// Activity helper for formatting
class ActivityHelper {
  static String getActivityText(ActivityItem activity) {
    switch (activity.type) {
      case ActivityType.follow:
        return 'started following you';
      case ActivityType.like:
        return 'liked your ${_getTargetType(activity)}';
      case ActivityType.comment:
        return 'commented on your ${_getTargetType(activity)}';
      case ActivityType.review:
        return 'reviewed ${activity.targetName ?? 'a destination'}';
      case ActivityType.trip:
        return 'created a trip to ${activity.targetName ?? 'unknown'}';
      case ActivityType.photo:
        return 'posted a new photo';
    }
  }

  static String _getTargetType(ActivityItem activity) {
    if (activity.targetName != null) return 'post';
    return 'content';
  }

  static IconData getActivityIcon(ActivityType type) {
    switch (type) {
      case ActivityType.follow:
        return Icons.person_add;
      case ActivityType.like:
        return Icons.favorite;
      case ActivityType.comment:
        return Icons.comment;
      case ActivityType.review:
        return Icons.star;
      case ActivityType.trip:
        return Icons.flight_takeoff;
      case ActivityType.photo:
        return Icons.photo;
    }
  }
}

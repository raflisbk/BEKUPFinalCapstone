import 'package:cloud_firestore/cloud_firestore.dart';

/// Review model for destinations
class DestinationReview {
  final String id;
  final String destinationId;
  final String destinationName;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final double rating; // 1.0 to 5.0
  final String title;
  final String content;
  final List<String> photoUrls;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int helpfulCount;
  final List<String> helpfulUserIds;

  DestinationReview({
    required this.id,
    required this.destinationId,
    required this.destinationName,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.rating,
    required this.title,
    required this.content,
    this.photoUrls = const [],
    required this.createdAt,
    required this.updatedAt,
    this.helpfulCount = 0,
    this.helpfulUserIds = const [],
  });

  /// Create from Firestore document
  factory DestinationReview.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return DestinationReview(
      id: doc.id,
      destinationId: data['destinationId'] ?? '',
      destinationName: data['destinationName'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userPhotoUrl: data['userPhotoUrl'],
      rating: (data['rating'] ?? 0).toDouble(),
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      photoUrls: List<String>.from(data['photoUrls'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      helpfulCount: data['helpfulCount'] ?? 0,
      helpfulUserIds: List<String>.from(data['helpfulUserIds'] ?? []),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'destinationId': destinationId,
      'destinationName': destinationName,
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'rating': rating,
      'title': title,
      'content': content,
      'photoUrls': photoUrls,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'helpfulCount': helpfulCount,
      'helpfulUserIds': helpfulUserIds,
    };
  }

  /// Create from Map (for offline cache)
  factory DestinationReview.fromMap(Map<String, dynamic> map) {
    return DestinationReview(
      id: map['id'] ?? '',
      destinationId: map['destinationId'] ?? '',
      destinationName: map['destinationName'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userPhotoUrl: map['userPhotoUrl'],
      rating: (map['rating'] ?? 0).toDouble(),
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      photoUrls: List<String>.from(map['photoUrls'] ?? []),
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      helpfulCount: map['helpfulCount'] ?? 0,
      helpfulUserIds: List<String>.from(map['helpfulUserIds'] ?? []),
    );
  }

  /// Convert to Map (for offline cache)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'destinationId': destinationId,
      'destinationName': destinationName,
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'rating': rating,
      'title': title,
      'content': content,
      'photoUrls': photoUrls,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'helpfulCount': helpfulCount,
      'helpfulUserIds': helpfulUserIds,
    };
  }

  /// Check if user marked this review as helpful
  bool isMarkedHelpfulBy(String userId) {
    return helpfulUserIds.contains(userId);
  }

  /// Create a copy with updated fields
  DestinationReview copyWith({
    String? title,
    String? content,
    double? rating,
    List<String>? photoUrls,
    int? helpfulCount,
    List<String>? helpfulUserIds,
  }) {
    return DestinationReview(
      id: id,
      destinationId: destinationId,
      destinationName: destinationName,
      userId: userId,
      userName: userName,
      userPhotoUrl: userPhotoUrl,
      rating: rating ?? this.rating,
      title: title ?? this.title,
      content: content ?? this.content,
      photoUrls: photoUrls ?? this.photoUrls,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      helpfulCount: helpfulCount ?? this.helpfulCount,
      helpfulUserIds: helpfulUserIds ?? this.helpfulUserIds,
    );
  }
}

/// Rating summary for a destination
class RatingSummary {
  final String destinationId;
  final double averageRating;
  final int totalReviews;
  final Map<int, int> ratingDistribution; // star -> count

  RatingSummary({
    required this.destinationId,
    required this.averageRating,
    required this.totalReviews,
    required this.ratingDistribution,
  });

  /// Create from Firestore document
  factory RatingSummary.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return RatingSummary(
      destinationId: doc.id,
      averageRating: (data['averageRating'] ?? 0).toDouble(),
      totalReviews: data['totalReviews'] ?? 0,
      ratingDistribution: Map<int, int>.from(
        data['ratingDistribution'] ?? {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
      ),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'averageRating': averageRating,
      'totalReviews': totalReviews,
      'ratingDistribution': ratingDistribution,
      'updatedAt': Timestamp.now(),
    };
  }

  /// Get percentage for each star rating
  double getPercentage(int stars) {
    if (totalReviews == 0) return 0.0;
    final count = ratingDistribution[stars] ?? 0;
    return (count / totalReviews) * 100;
  }

  /// Get count for specific star rating
  int getCount(int stars) {
    return ratingDistribution[stars] ?? 0;
  }
}

/// Review filter options
enum ReviewFilter {
  mostRecent,
  highestRated,
  lowestRated,
  mostHelpful,
}

/// Review sort helper
class ReviewSortHelper {
  static String getFirestoreField(ReviewFilter filter) {
    switch (filter) {
      case ReviewFilter.mostRecent:
        return 'createdAt';
      case ReviewFilter.highestRated:
      case ReviewFilter.lowestRated:
        return 'rating';
      case ReviewFilter.mostHelpful:
        return 'helpfulCount';
    }
  }

  static bool isDescending(ReviewFilter filter) {
    return filter != ReviewFilter.lowestRated;
  }

  static String getLabel(ReviewFilter filter) {
    switch (filter) {
      case ReviewFilter.mostRecent:
        return 'Most Recent';
      case ReviewFilter.highestRated:
        return 'Highest Rated';
      case ReviewFilter.lowestRated:
        return 'Lowest Rated';
      case ReviewFilter.mostHelpful:
        return 'Most Helpful';
    }
  }
}

/// Review model for destinations - Updated for Supabase
class Review {
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

  Review({
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

  /// Create from Supabase row
  factory Review.fromSupabase(Map<String, dynamic> data) {
    return Review(
      id: data['id'] ?? '',
      destinationId: data['destination_id'] ?? '',
      destinationName: data['destination_name'] ?? '',
      userId: data['user_id'] ?? '',
      userName: data['user_name'] ?? '',
      userPhotoUrl: data['user_photo_url'],
      rating: (data['rating'] ?? 0).toDouble(),
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      photoUrls: List<String>.from(data['photo_urls'] ?? []),
      createdAt: DateTime.parse(data['created_at']),
      updatedAt: DateTime.parse(data['updated_at']),
      helpfulCount: data['helpful_count'] ?? 0,
      helpfulUserIds: List<String>.from(data['helpful_user_ids'] ?? []),
    );
  }

  /// Convert to Supabase row
  Map<String, dynamic> toSupabase() {
    return {
      'id': id,
      'destination_id': destinationId,
      'destination_name': destinationName,
      'user_id': userId,
      'user_name': userName,
      'user_photo_url': userPhotoUrl,
      'rating': rating,
      'title': title,
      'content': content,
      'photo_urls': photoUrls,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'helpful_count': helpfulCount,
      'helpful_user_ids': helpfulUserIds,
    };
  }

  /// Create from Map (for offline cache)
  factory Review.fromMap(Map<String, dynamic> map) {
    return Review(
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
  Review copyWith({
    String? title,
    String? content,
    double? rating,
    List<String>? photoUrls,
    int? helpfulCount,
    List<String>? helpfulUserIds,
  }) {
    return Review(
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

  /// Create from Supabase data
  factory RatingSummary.fromSupabase(Map<String, dynamic> data) {
    return RatingSummary(
      destinationId: data['destination_id'] ?? '',
      averageRating: (data['average_rating'] ?? 0).toDouble(),
      totalReviews: data['total_reviews'] ?? 0,
      ratingDistribution: Map<int, int>.from(
        data['rating_distribution'] ?? {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
      ),
    );
  }

  /// Convert to Supabase row
  Map<String, dynamic> toSupabase() {
    return {
      'destination_id': destinationId,
      'average_rating': averageRating,
      'total_reviews': totalReviews,
      'rating_distribution': ratingDistribution,
      'updated_at': DateTime.now().toIso8601String(),
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

import '../stubs/firebase_stubs.dart';

/// Photo model for gallery
class Photo {
  final String id;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final String imageUrl;
  final String? caption;
  final String? location;
  final String? destinationId;
  final String? destinationName;
  final List<String> tags;
  final int likes;
  final List<String> likedBy;
  final int comments;
  final bool isPublic;
  final DateTime createdAt;
  final DateTime updatedAt;

  Photo({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.imageUrl,
    this.caption,
    this.location,
    this.destinationId,
    this.destinationName,
    this.tags = const [],
    this.likes = 0,
    this.likedBy = const [],
    this.comments = 0,
    this.isPublic = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from Firestore document
  factory Photo.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Photo(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userPhotoUrl: data['userPhotoUrl'],
      imageUrl: data['imageUrl'] ?? '',
      caption: data['caption'],
      location: data['location'],
      destinationId: data['destinationId'],
      destinationName: data['destinationName'],
      tags: List<String>.from(data['tags'] ?? []),
      likes: data['likes'] ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
      comments: data['comments'] ?? 0,
      isPublic: data['isPublic'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'imageUrl': imageUrl,
      'caption': caption,
      'location': location,
      'destinationId': destinationId,
      'destinationName': destinationName,
      'tags': tags,
      'likes': likes,
      'likedBy': likedBy,
      'comments': comments,
      'isPublic': isPublic,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Check if photo is liked by user
  bool isLikedBy(String userId) {
    return likedBy.contains(userId);
  }

  /// Copy with method
  Photo copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userPhotoUrl,
    String? imageUrl,
    String? caption,
    String? location,
    String? destinationId,
    String? destinationName,
    List<String>? tags,
    int? likes,
    List<String>? likedBy,
    int? comments,
    bool? isPublic,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Photo(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      caption: caption ?? this.caption,
      location: location ?? this.location,
      destinationId: destinationId ?? this.destinationId,
      destinationName: destinationName ?? this.destinationName,
      tags: tags ?? this.tags,
      likes: likes ?? this.likes,
      likedBy: likedBy ?? this.likedBy,
      comments: comments ?? this.comments,
      isPublic: isPublic ?? this.isPublic,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Photo comment model
class PhotoComment {
  final String id;
  final String photoId;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final String comment;
  final DateTime createdAt;

  PhotoComment({
    required this.id,
    required this.photoId,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.comment,
    required this.createdAt,
  });

  factory PhotoComment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return PhotoComment(
      id: doc.id,
      photoId: data['photoId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userPhotoUrl: data['userPhotoUrl'],
      comment: data['comment'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'photoId': photoId,
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

/// Gallery filter options
enum GalleryFilter {
  all,
  myPhotos,
  liked,
  destination,
}

/// Gallery filter helper
class GalleryFilterHelper {
  static String getLabel(GalleryFilter filter) {
    switch (filter) {
      case GalleryFilter.all:
        return 'All Photos';
      case GalleryFilter.myPhotos:
        return 'My Photos';
      case GalleryFilter.liked:
        return 'Liked';
      case GalleryFilter.destination:
        return 'Destinations';
    }
  }
}

/// Gallery sort options
enum GallerySort {
  recent,
  popular,
  oldest,
}

/// Gallery sort helper
class GallerySortHelper {
  static String getLabel(GallerySort sort) {
    switch (sort) {
      case GallerySort.recent:
        return 'Most Recent';
      case GallerySort.popular:
        return 'Most Popular';
      case GallerySort.oldest:
        return 'Oldest';
    }
  }

  static List<Photo> sortPhotos(List<Photo> photos, GallerySort sort) {
    final sorted = List<Photo>.from(photos);

    switch (sort) {
      case GallerySort.recent:
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case GallerySort.popular:
        sorted.sort((a, b) {
          // Sort by likes, then by comments
          final likeDiff = b.likes.compareTo(a.likes);
          if (likeDiff != 0) return likeDiff;
          return b.comments.compareTo(a.comments);
        });
        break;
      case GallerySort.oldest:
        sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
    }

    return sorted;
  }
}

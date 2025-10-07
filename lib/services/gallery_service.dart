import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../core/models/gallery_model.dart';
import '../core/utils/logger.dart';

/// Service for managing photo gallery
class GalleryService {
  static const String _tag = 'GalleryService';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  CollectionReference get _photosCollection => _firestore.collection('photos');
  CollectionReference get _commentsCollection => _firestore.collection('photo_comments');

  /// Upload photo to Firebase Storage
  Future<String?> uploadPhoto(File imageFile, String userId) async {
    try {
      AppLogger.debug(_tag, 'Uploading photo to storage');

      final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('gallery').child(userId).child(fileName);

      final uploadTask = await ref.putFile(imageFile);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      AppLogger.info(_tag, 'Photo uploaded successfully', {
        'url': downloadUrl,
      });

      return downloadUrl;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to upload photo', e, stackTrace);
      return null;
    }
  }

  /// Create new photo post
  Future<String?> createPhoto({
    required String userId,
    required String userName,
    String? userPhotoUrl,
    required String imageUrl,
    String? caption,
    String? location,
    String? destinationId,
    String? destinationName,
    List<String> tags = const [],
    bool isPublic = true,
  }) async {
    try {
      AppLogger.debug(_tag, 'Creating photo post', {
        'userId': userId,
        'caption': caption,
      });

      final now = DateTime.now();

      final photo = Photo(
        id: '',
        userId: userId,
        userName: userName,
        userPhotoUrl: userPhotoUrl,
        imageUrl: imageUrl,
        caption: caption,
        location: location,
        destinationId: destinationId,
        destinationName: destinationName,
        tags: tags,
        isPublic: isPublic,
        createdAt: now,
        updatedAt: now,
      );

      final docRef = await _photosCollection.add(photo.toFirestore());

      AppLogger.info(_tag, 'Photo created successfully', {
        'photoId': docRef.id,
      });

      return docRef.id;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to create photo', e, stackTrace);
      return null;
    }
  }

  /// Update photo
  Future<bool> updatePhoto({
    required String photoId,
    String? caption,
    String? location,
    List<String>? tags,
    bool? isPublic,
  }) async {
    try {
      AppLogger.debug(_tag, 'Updating photo', {'photoId': photoId});

      final updates = <String, dynamic>{
        'updatedAt': Timestamp.now(),
      };

      if (caption != null) updates['caption'] = caption;
      if (location != null) updates['location'] = location;
      if (tags != null) updates['tags'] = tags;
      if (isPublic != null) updates['isPublic'] = isPublic;

      await _photosCollection.doc(photoId).update(updates);

      AppLogger.info(_tag, 'Photo updated successfully');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to update photo', e, stackTrace);
      return false;
    }
  }

  /// Delete photo
  Future<bool> deletePhoto(String photoId, String imageUrl) async {
    try {
      AppLogger.debug(_tag, 'Deleting photo', {'photoId': photoId});

      // Delete from Firestore
      await _photosCollection.doc(photoId).delete();

      // Delete comments
      final comments = await _commentsCollection
          .where('photoId', isEqualTo: photoId)
          .get();

      for (var doc in comments.docs) {
        await doc.reference.delete();
      }

      // Delete from Storage
      try {
        final ref = _storage.refFromURL(imageUrl);
        await ref.delete();
      } catch (e) {
        AppLogger.warning(_tag, 'Failed to delete image from storage', {
          'error': e.toString(),
        });
      }

      AppLogger.info(_tag, 'Photo deleted successfully');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to delete photo', e, stackTrace);
      return false;
    }
  }

  /// Toggle like on photo
  Future<bool> toggleLike({
    required String photoId,
    required String userId,
  }) async {
    try {
      AppLogger.debug(_tag, 'Toggling like', {
        'photoId': photoId,
        'userId': userId,
      });

      final doc = await _photosCollection.doc(photoId).get();
      if (!doc.exists) return false;

      final photo = Photo.fromFirestore(doc);
      final isLiked = photo.isLikedBy(userId);

      if (isLiked) {
        // Unlike
        await _photosCollection.doc(photoId).update({
          'likes': FieldValue.increment(-1),
          'likedBy': FieldValue.arrayRemove([userId]),
          'updatedAt': Timestamp.now(),
        });
      } else {
        // Like
        await _photosCollection.doc(photoId).update({
          'likes': FieldValue.increment(1),
          'likedBy': FieldValue.arrayUnion([userId]),
          'updatedAt': Timestamp.now(),
        });
      }

      AppLogger.info(_tag, isLiked ? 'Photo unliked' : 'Photo liked');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to toggle like', e, stackTrace);
      return false;
    }
  }

  /// Add comment to photo
  Future<String?> addComment({
    required String photoId,
    required String userId,
    required String userName,
    String? userPhotoUrl,
    required String comment,
  }) async {
    try {
      AppLogger.debug(_tag, 'Adding comment', {
        'photoId': photoId,
        'userId': userId,
      });

      final photoComment = PhotoComment(
        id: '',
        photoId: photoId,
        userId: userId,
        userName: userName,
        userPhotoUrl: userPhotoUrl,
        comment: comment,
        createdAt: DateTime.now(),
      );

      final docRef = await _commentsCollection.add(photoComment.toFirestore());

      // Increment comment count
      await _photosCollection.doc(photoId).update({
        'comments': FieldValue.increment(1),
        'updatedAt': Timestamp.now(),
      });

      AppLogger.info(_tag, 'Comment added successfully');
      return docRef.id;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to add comment', e, stackTrace);
      return null;
    }
  }

  /// Delete comment
  Future<bool> deleteComment(String commentId, String photoId) async {
    try {
      AppLogger.debug(_tag, 'Deleting comment', {'commentId': commentId});

      await _commentsCollection.doc(commentId).delete();

      // Decrement comment count
      await _photosCollection.doc(photoId).update({
        'comments': FieldValue.increment(-1),
        'updatedAt': Timestamp.now(),
      });

      AppLogger.info(_tag, 'Comment deleted successfully');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to delete comment', e, stackTrace);
      return false;
    }
  }

  /// Get photos stream with filter
  Stream<List<Photo>> getPhotosStream({
    GalleryFilter filter = GalleryFilter.all,
    String? userId,
    String? destinationId,
    GallerySort sort = GallerySort.recent,
    int limit = 20,
  }) {
    AppLogger.debug(_tag, 'Getting photos stream', {
      'filter': filter.toString(),
      'sort': sort.toString(),
    });

    Query query = _photosCollection;

    // Apply filters
    switch (filter) {
      case GalleryFilter.all:
        query = query.where('isPublic', isEqualTo: true);
        break;
      case GalleryFilter.myPhotos:
        if (userId != null) {
          query = query.where('userId', isEqualTo: userId);
        }
        break;
      case GalleryFilter.liked:
        if (userId != null) {
          query = query.where('likedBy', arrayContains: userId);
        }
        break;
      case GalleryFilter.destination:
        if (destinationId != null) {
          query = query.where('destinationId', isEqualTo: destinationId);
        }
        break;
    }

    // Apply sorting
    switch (sort) {
      case GallerySort.recent:
        query = query.orderBy('createdAt', descending: true);
        break;
      case GallerySort.popular:
        query = query.orderBy('likes', descending: true);
        break;
      case GallerySort.oldest:
        query = query.orderBy('createdAt', descending: false);
        break;
    }

    query = query.limit(limit);

    return query.snapshots().map((snapshot) {
      final photos = snapshot.docs.map((doc) => Photo.fromFirestore(doc)).toList();

      AppLogger.debug(_tag, 'Photos stream update', {
        'count': photos.length,
      });

      return photos;
    });
  }

  /// Get photo by ID
  Future<Photo?> getPhotoById(String photoId) async {
    try {
      final doc = await _photosCollection.doc(photoId).get();
      if (!doc.exists) return null;

      return Photo.fromFirestore(doc);
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get photo', e, stackTrace);
      return null;
    }
  }

  /// Get comments stream for photo
  Stream<List<PhotoComment>> getCommentsStream(String photoId) {
    return _commentsCollection
        .where('photoId', isEqualTo: photoId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PhotoComment.fromFirestore(doc))
          .toList();
    });
  }

  /// Get user's photos count
  Future<int> getUserPhotosCount(String userId) async {
    try {
      final snapshot = await _photosCollection
          .where('userId', isEqualTo: userId)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get user photos count', e, stackTrace);
      return 0;
    }
  }

  /// Search photos by tags
  Stream<List<Photo>> searchPhotosByTags(List<String> tags) {
    return _photosCollection
        .where('isPublic', isEqualTo: true)
        .where('tags', arrayContainsAny: tags)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Photo.fromFirestore(doc)).toList();
    });
  }
}

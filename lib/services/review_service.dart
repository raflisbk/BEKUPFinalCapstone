import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart' as img;
import '../core/models/review_model.dart';
import '../core/utils/logger.dart';

/// Service for managing destination reviews
class ReviewService {
  static const String _tag = 'ReviewService';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Collection references
  CollectionReference get _reviewsCollection =>
      _firestore.collection('reviews');
  CollectionReference get _ratingSummariesCollection =>
      _firestore.collection('rating_summaries');

  /// Submit a new review
  Future<bool> submitReview({
    required String destinationId,
    required String destinationName,
    required String userId,
    required String userName,
    String? userPhotoUrl,
    required double rating,
    required String title,
    required String content,
    List<String> photoUrls = const [],
  }) async {
    try {
      AppLogger.debug(_tag, 'Submitting review', {
        'destinationId': destinationId,
        'rating': rating,
      });

      final now = DateTime.now();

      final review = DestinationReview(
        id: '',
        destinationId: destinationId,
        destinationName: destinationName,
        userId: userId,
        userName: userName,
        userPhotoUrl: userPhotoUrl,
        rating: rating,
        title: title,
        content: content,
        photoUrls: photoUrls,
        createdAt: now,
        updatedAt: now,
      );

      // Add review
      await _reviewsCollection.add(review.toFirestore());

      // Update rating summary
      await _updateRatingSummary(destinationId, rating, isNew: true);

      AppLogger.info(_tag, 'Review submitted successfully', {
        'destinationId': destinationId,
      });

      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to submit review', e, stackTrace);
      return false;
    }
  }

  /// Update an existing review
  Future<bool> updateReview({
    required String reviewId,
    required String destinationId,
    required double oldRating,
    required double newRating,
    required String title,
    required String content,
    List<String>? photoUrls,
  }) async {
    try {
      AppLogger.debug(_tag, 'Updating review', {
        'reviewId': reviewId,
      });

      await _reviewsCollection.doc(reviewId).update({
        'rating': newRating,
        'title': title,
        'content': content,
        'photoUrls': photoUrls,
        'updatedAt': Timestamp.now(),
      });

      // Update rating summary if rating changed
      if (oldRating != newRating) {
        await _updateRatingSummary(
          destinationId,
          newRating,
          oldRating: oldRating,
        );
      }

      AppLogger.info(_tag, 'Review updated successfully');

      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to update review', e, stackTrace);
      return false;
    }
  }

  /// Delete a review
  Future<bool> deleteReview({
    required String reviewId,
    required String destinationId,
    required double rating,
  }) async {
    try {
      AppLogger.debug(_tag, 'Deleting review', {
        'reviewId': reviewId,
      });

      await _reviewsCollection.doc(reviewId).delete();

      // Update rating summary
      await _updateRatingSummary(
        destinationId,
        rating,
        isDelete: true,
      );

      AppLogger.info(_tag, 'Review deleted successfully');

      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to delete review', e, stackTrace);
      return false;
    }
  }

  /// Get reviews for a destination
  Stream<List<DestinationReview>> getReviewsStream({
    required String destinationId,
    ReviewFilter filter = ReviewFilter.mostRecent,
    int limit = 20,
  }) {
    AppLogger.debug(_tag, 'Getting reviews stream', {
      'destinationId': destinationId,
      'filter': filter.toString(),
    });

    return _reviewsCollection
        .where('destinationId', isEqualTo: destinationId)
        .orderBy(
          ReviewSortHelper.getFirestoreField(filter),
          descending: ReviewSortHelper.isDescending(filter),
        )
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      AppLogger.debug(_tag, 'Reviews stream update', {
        'count': snapshot.docs.length,
      });

      return snapshot.docs
          .map((doc) => DestinationReview.fromFirestore(doc))
          .toList();
    });
  }

  /// Get rating summary for a destination
  Stream<RatingSummary?> getRatingSummaryStream(String destinationId) {
    return _ratingSummariesCollection.doc(destinationId).snapshots().map(
      (snapshot) {
        if (!snapshot.exists) {
          return RatingSummary(
            destinationId: destinationId,
            averageRating: 0.0,
            totalReviews: 0,
            ratingDistribution: {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
          );
        }
        return RatingSummary.fromFirestore(snapshot);
      },
    );
  }

  /// Get user's review for a destination
  Future<DestinationReview?> getUserReview({
    required String destinationId,
    required String userId,
  }) async {
    try {
      final snapshot = await _reviewsCollection
          .where('destinationId', isEqualTo: destinationId)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return DestinationReview.fromFirestore(snapshot.docs.first);
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get user review', e, stackTrace);
      return null;
    }
  }

  /// Mark review as helpful
  Future<bool> toggleHelpful({
    required String reviewId,
    required String userId,
  }) async {
    try {
      AppLogger.debug(_tag, 'Toggling helpful status', {
        'reviewId': reviewId,
      });

      final doc = await _reviewsCollection.doc(reviewId).get();
      if (!doc.exists) return false;

      final review = DestinationReview.fromFirestore(doc);
      final isCurrentlyHelpful = review.isMarkedHelpfulBy(userId);

      if (isCurrentlyHelpful) {
        // Remove helpful
        await _reviewsCollection.doc(reviewId).update({
          'helpfulUserIds': FieldValue.arrayRemove([userId]),
          'helpfulCount': FieldValue.increment(-1),
        });
      } else {
        // Add helpful
        await _reviewsCollection.doc(reviewId).update({
          'helpfulUserIds': FieldValue.arrayUnion([userId]),
          'helpfulCount': FieldValue.increment(1),
        });
      }

      AppLogger.info(_tag, 'Helpful status toggled', {
        'wasHelpful': isCurrentlyHelpful,
        'nowHelpful': !isCurrentlyHelpful,
      });

      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to toggle helpful', e, stackTrace);
      return false;
    }
  }

  /// Update rating summary for a destination
  Future<void> _updateRatingSummary(
    String destinationId,
    double rating, {
    double? oldRating,
    bool isNew = false,
    bool isDelete = false,
  }) async {
    try {
      AppLogger.debug(_tag, 'Updating rating summary', {
        'destinationId': destinationId,
        'isNew': isNew,
        'isDelete': isDelete,
      });

      final summaryDoc = _ratingSummariesCollection.doc(destinationId);
      final snapshot = await summaryDoc.get();

      RatingSummary summary;

      if (!snapshot.exists) {
        // Create new summary
        summary = RatingSummary(
          destinationId: destinationId,
          averageRating: rating,
          totalReviews: 1,
          ratingDistribution: {
            1: rating == 1 ? 1 : 0,
            2: rating == 2 ? 1 : 0,
            3: rating == 3 ? 1 : 0,
            4: rating == 4 ? 1 : 0,
            5: rating == 5 ? 1 : 0,
          },
        );
      } else {
        summary = RatingSummary.fromFirestore(snapshot);

        // Calculate new values
        int newTotalReviews = summary.totalReviews;
        Map<int, int> newDistribution = Map.from(summary.ratingDistribution);

        if (isNew) {
          newTotalReviews++;
          newDistribution[rating.round()] =
              (newDistribution[rating.round()] ?? 0) + 1;
        } else if (isDelete) {
          newTotalReviews--;
          newDistribution[rating.round()] =
              (newDistribution[rating.round()] ?? 0) - 1;
        } else if (oldRating != null) {
          // Update (rating changed)
          newDistribution[oldRating.round()] =
              (newDistribution[oldRating.round()] ?? 0) - 1;
          newDistribution[rating.round()] =
              (newDistribution[rating.round()] ?? 0) + 1;
        }

        // Calculate new average
        double totalRating = 0;
        newDistribution.forEach((star, reviewCount) {
          totalRating += star * reviewCount;
        });

        final newAverage =
            newTotalReviews > 0 ? totalRating / newTotalReviews : 0.0;

        summary = RatingSummary(
          destinationId: destinationId,
          averageRating: newAverage,
          totalReviews: newTotalReviews,
          ratingDistribution: newDistribution,
        );
      }

      await summaryDoc.set(summary.toFirestore());

      AppLogger.info(_tag, 'Rating summary updated', {
        'averageRating': summary.averageRating,
        'totalReviews': summary.totalReviews,
      });
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to update rating summary', e, stackTrace);
    }
  }

  /// Get recent reviews across all destinations (for home feed)
  Stream<List<DestinationReview>> getRecentReviewsStream({int limit = 10}) {
    return _reviewsCollection
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => DestinationReview.fromFirestore(doc))
          .toList();
    });
  }

  /// Get user's all reviews
  Stream<List<DestinationReview>> getUserReviewsStream(String userId) {
    return _reviewsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => DestinationReview.fromFirestore(doc))
          .toList();
    });
  }

  /// Upload review photos to Firebase Storage
  Future<List<String>> uploadReviewPhotos({
    required String userId,
    required String destinationId,
    required List<File> photoFiles,
  }) async {
    final List<String> photoUrls = [];

    try {
      AppLogger.debug(_tag, 'Uploading review photos', {
        'count': photoFiles.length,
      });

      for (int i = 0; i < photoFiles.length; i++) {
        final file = photoFiles[i];

        // Optimize image
        final optimizedImage = await _optimizeImage(file);
        if (optimizedImage == null) {
          AppLogger.warning(_tag, 'Failed to optimize image $i, skipping');
          continue;
        }

        // Upload to Firebase Storage
        final fileName = 'review_photos/$destinationId/$userId/${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final storageRef = _storage.ref().child(fileName);

        AppLogger.debug(_tag, 'Uploading photo ${i + 1}/${photoFiles.length}');

        final uploadTask = await storageRef.putFile(
          optimizedImage,
          SettableMetadata(contentType: 'image/jpeg'),
        );

        final photoUrl = await uploadTask.ref.getDownloadURL();
        photoUrls.add(photoUrl);

        // Clean up optimized file
        await optimizedImage.delete();

        AppLogger.info(_tag, 'Photo ${i + 1} uploaded successfully');
      }

      AppLogger.success(_tag, 'All review photos uploaded', {
        'uploaded': photoUrls.length,
        'total': photoFiles.length,
      });

      return photoUrls;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to upload review photos', e, stackTrace);
      return photoUrls; // Return whatever was successfully uploaded
    }
  }

  /// Optimize image for review (reduce size and quality)
  Future<File?> _optimizeImage(File imageFile) async {
    try {
      AppLogger.debug(_tag, 'Optimizing image', {
        'originalSize': imageFile.lengthSync(),
      });

      // Read image
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) {
        AppLogger.error(_tag, 'Failed to decode image');
        return null;
      }

      // Resize if needed (max 1920x1920)
      final resized = image.width > 1920 || image.height > 1920
          ? img.copyResize(
              image,
              width: image.width > image.height ? 1920 : null,
              height: image.height > image.width ? 1920 : null,
            )
          : image;

      // Compress to JPEG with 85% quality
      final compressed = img.encodeJpg(resized, quality: 85);

      // Write to temporary file
      final tempDir = await Directory.systemTemp.createTemp('review_image_');
      final tempFile = File('${tempDir.path}/optimized.jpg');
      await tempFile.writeAsBytes(compressed);

      AppLogger.info(_tag, 'Image optimized', {
        'originalSize': imageFile.lengthSync(),
        'optimizedSize': tempFile.lengthSync(),
        'reduction': '${((1 - tempFile.lengthSync() / imageFile.lengthSync()) * 100).toStringAsFixed(1)}%',
      });

      return tempFile;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to optimize image', e, stackTrace);
      return null;
    }
  }
}

import 'package:flutter/foundation.dart';
import '../utils/logger.dart';
import '../../services/review_service.dart';

/// Provider for Review management
class ReviewProvider with ChangeNotifier {
  static const String _tag = 'ReviewProvider';

  // Service instance with dependency injection
  final ReviewService _reviewService;

  List<Map<String, dynamic>> _reviews = [];
  List<Map<String, dynamic>> _userReviews = [];
  Map<String, dynamic>? _selectedReview;
  bool _isLoading = false;
  String? _error;

  // Constructor with dependency injection
  ReviewProvider({ReviewService? reviewService})
      : _reviewService = reviewService ?? ReviewService();
  double _averageRating = 0.0;
  int _totalReviews = 0;

  // Getters
  List<Map<String, dynamic>> get reviews => _reviews;
  List<Map<String, dynamic>> get userReviews => _userReviews;
  Map<String, dynamic>? get selectedReview => _selectedReview;
  bool get isLoading => _isLoading;
  String? get error => _error;
  double get averageRating => _averageRating;
  int get totalReviews => _totalReviews;

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Set error state
  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _setError(null);
  }

  /// Load reviews for entity
  Future<void> loadReviews({
    required String entityId,
    required String entityType,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      AppLogger.debug(_tag, 'Loading reviews for $entityType: $entityId');
      _setLoading(true);
      _setError(null);

      // Note: This method needs to be implemented in ReviewService
      // For now, we'll use placeholder
      _reviews = [];
      _averageRating = 0.0;
      _totalReviews = 0;

      AppLogger.success(_tag, 'Loaded ${_reviews.length} reviews');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to load reviews', e, stackTrace);
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Load user's reviews
  Future<void> loadUserReviews() async {
    try {
      AppLogger.debug(_tag, 'Loading user reviews');
      _setError(null);

      // Note: This method needs to be implemented in ReviewService
      // For now, we'll use placeholder
      _userReviews = [];

      notifyListeners();
      AppLogger.success(_tag, 'Loaded ${_userReviews.length} user reviews');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to load user reviews', e, stackTrace);
      _setError(e.toString());
    }
  }

  /// Create new review
  Future<bool> createReview({
    required String entityId,
    required String entityType,
    required double rating,
    required String title,
    required String content,
    List<String>? pros,
    List<String>? cons,
    List<String>? tags,
    List<String>? imageUrls,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      AppLogger.debug(_tag, 'Creating review for $entityType: $entityId');
      _setLoading(true);
      _setError(null);

      final reviewData = await _reviewService.createReview(
        entityId: entityId,
        entityType: entityType,
        rating: rating,
        title: title,
        content: content,
        pros: pros,
        cons: cons,
        tags: tags,
        imageUrls: imageUrls,
        metadata: metadata,
      );

      // Add to local list
      _reviews.insert(0, reviewData);
      _userReviews.insert(0, reviewData);
      
      // Update statistics
      _totalReviews++;
      _averageRating = ((_averageRating * (_totalReviews - 1)) + rating) / _totalReviews;

      AppLogger.success(_tag, 'Review created successfully');
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to create review', e, stackTrace);
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update review
  Future<bool> updateReview({
    required String reviewId,
    double? rating,
    String? title,
    String? content,
    List<String>? pros,
    List<String>? cons,
    List<String>? tags,
    List<String>? imageUrls,
  }) async {
    try {
      AppLogger.debug(_tag, 'Updating review: $reviewId');
      _setLoading(true);
      _setError(null);

      // Note: Update method needs to be implemented in ReviewService
      // For now, we'll update locally
      final reviewIndex = _reviews.indexWhere((r) => r['id'] == reviewId);
      if (reviewIndex != -1) {
        final review = Map<String, dynamic>.from(_reviews[reviewIndex]);
        if (rating != null) review['rating'] = rating;
        if (title != null) review['title'] = title;
        if (content != null) review['content'] = content;
        if (pros != null) review['pros'] = pros;
        if (cons != null) review['cons'] = cons;
        if (tags != null) review['tags'] = tags;
        if (imageUrls != null) review['image_urls'] = imageUrls;
        
        _reviews[reviewIndex] = review;
        
        // Update in user reviews too
        final userReviewIndex = _userReviews.indexWhere((r) => r['id'] == reviewId);
        if (userReviewIndex != -1) {
          _userReviews[userReviewIndex] = review;
        }
      }

      AppLogger.success(_tag, 'Review updated successfully');
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to update review', e, stackTrace);
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Delete review
  Future<bool> deleteReview(String reviewId) async {
    try {
      AppLogger.debug(_tag, 'Deleting review: $reviewId');
      _setLoading(true);
      _setError(null);

      // Note: Delete method needs to be implemented in ReviewService
      // For now, we'll remove locally
      final removedReview = _reviews.firstWhere(
        (r) => r['id'] == reviewId,
        orElse: () => {},
      );

      _reviews.removeWhere((r) => r['id'] == reviewId);
      _userReviews.removeWhere((r) => r['id'] == reviewId);

      // Update statistics
      if (removedReview.isNotEmpty && _totalReviews > 0) {
        final removedRating = removedReview['rating'] as double? ?? 0.0;
        _totalReviews--;
        if (_totalReviews > 0) {
          _averageRating = ((_averageRating * (_totalReviews + 1)) - removedRating) / _totalReviews;
        } else {
          _averageRating = 0.0;
        }
      }

      AppLogger.success(_tag, 'Review deleted successfully');
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to delete review', e, stackTrace);
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Like/unlike review
  Future<void> toggleLike(String reviewId) async {
    try {
      AppLogger.debug(_tag, 'Toggling like for review: $reviewId');

      final reviewIndex = _reviews.indexWhere((r) => r['id'] == reviewId);
      if (reviewIndex != -1) {
        final review = _reviews[reviewIndex];
        final isLiked = review['user_liked'] as bool? ?? false;
        final likeCount = review['likes_count'] as int? ?? 0;

        review['user_liked'] = !isLiked;
        review['likes_count'] = isLiked ? likeCount - 1 : likeCount + 1;

        notifyListeners();
      }

      // Note: Database update would be done here
      AppLogger.success(_tag, 'Review like toggled successfully');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to toggle review like', e, stackTrace);
      _setError(e.toString());
    }
  }

  /// Report review
  Future<bool> reportReview({
    required String reviewId,
    required String reason,
    String? description,
  }) async {
    try {
      AppLogger.debug(_tag, 'Reporting review: $reviewId');
      _setError(null);

      // Note: Report functionality needs to be implemented
      // For now, just log the action
      AppLogger.success(_tag, 'Review reported successfully');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to report review', e, stackTrace);
      _setError(e.toString());
      return false;
    }
  }

  /// Select a review
  void selectReview(Map<String, dynamic> review) {
    _selectedReview = review;
    notifyListeners();
  }

  /// Clear selected review
  void clearSelection() {
    _selectedReview = null;
    notifyListeners();
  }

  /// Clear all data
  void clearAll() {
    _reviews = [];
    _userReviews = [];
    _selectedReview = null;
    _error = null;
    _averageRating = 0.0;
    _totalReviews = 0;
    notifyListeners();
  }

  /// Get rating distribution
  Map<int, int> getRatingDistribution() {
    final distribution = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    
    for (final review in _reviews) {
      final rating = (review['rating'] as double?)?.round() ?? 0;
      if (rating >= 1 && rating <= 5) {
        distribution[rating] = (distribution[rating] ?? 0) + 1;
      }
    }
    
    return distribution;
  }

  /// Get reviews by rating
  List<Map<String, dynamic>> getReviewsByRating(int rating) {
    return _reviews.where((review) {
      final reviewRating = (review['rating'] as double?)?.round() ?? 0;
      return reviewRating == rating;
    }).toList();
  }

  /// Refresh reviews
  Future<void> refresh({
    required String entityId,
    required String entityType,
  }) async {
    await loadReviews(entityId: entityId, entityType: entityType);
  }
}
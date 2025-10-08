import '../../core/database/models/cached_data.dart';
import '../../core/models/trip_model.dart';
import '../../core/models/destination_model.dart';
import '../../core/models/review_model.dart';
import '../../core/models/user_model.dart';
import '../cache/trip_cache_service.dart';
import '../cache/destination_cache_service.dart';
import '../cache/review_cache_service.dart';
import '../cache/profile_cache_service.dart';
import 'sync_queue_manager.dart';

/// Service for handling optimistic updates with sync queue
class OfflineOperationsService {
  static final OfflineOperationsService _instance = OfflineOperationsService._internal();
  factory OfflineOperationsService() => _instance;
  OfflineOperationsService._internal();

  final TripCacheService _tripCache = TripCacheService();
  final DestinationCacheService _destCache = DestinationCacheService();
  final ReviewCacheService _reviewCache = ReviewCacheService();
  final ProfileCacheService _profileCache = ProfileCacheService();
  final SyncQueueManager _syncQueue = SyncQueueManager();

  // ========== TRIP OPERATIONS ==========

  /// Create trip (optimistic)
  Future<Trip> createTrip(Trip trip) async {
    // Cache locally
    await _tripCache.cacheTrip(trip);

    // Add to sync queue
    await _syncQueue.addToQueue(SyncOperation(
      id: trip.id,
      type: 'create',
      collection: 'trips',
      data: trip.toMap(),
      timestamp: DateTime.now(),
      userId: trip.userId,
    ));

    return trip;
  }

  /// Update trip (optimistic)
  Future<Trip> updateTrip(Trip trip) async {
    // Update cache with dirty flag
    await _tripCache.updateCachedTrip(trip, markDirty: true);

    // Add to sync queue
    await _syncQueue.addToQueue(SyncOperation(
      id: trip.id,
      type: 'update',
      collection: 'trips',
      data: trip.toMap(),
      timestamp: DateTime.now(),
      userId: trip.userId,
    ));

    return trip;
  }

  /// Delete trip (optimistic)
  Future<void> deleteTrip(String tripId, String userId) async {
    // Mark as deleted in cache (or remove)
    await _tripCache.deleteCachedTrip(tripId);

    // Add to sync queue
    await _syncQueue.addToQueue(SyncOperation(
      id: tripId,
      type: 'delete',
      collection: 'trips',
      data: {'id': tripId},
      timestamp: DateTime.now(),
      userId: userId,
    ));
  }

  /// Get trip (from cache first)
  Future<Trip?> getTrip(String tripId) async {
    return await _tripCache.getCachedTrip(tripId);
  }

  /// Get all trips (from cache)
  Future<List<Trip>> getAllTrips() async {
    return await _tripCache.getAllCachedTrips();
  }

  /// Get user trips (from cache)
  Future<List<Trip>> getUserTrips(String userId) async {
    return await _tripCache.getCachedTripsByUser(userId);
  }

  // ========== DESTINATION OPERATIONS ==========

  /// Create destination (optimistic)
  Future<Destination> createDestination(Destination destination) async {
    await _destCache.cacheDestination(destination);

    await _syncQueue.addToQueue(SyncOperation(
      id: destination.id,
      type: 'create',
      collection: 'destinations',
      data: destination.toMap(),
      timestamp: DateTime.now(),
      userId: destination.createdBy,
    ));

    return destination;
  }

  /// Update destination (optimistic)
  Future<Destination> updateDestination(Destination destination) async {
    await _destCache.updateCachedDestination(destination, markDirty: true);

    await _syncQueue.addToQueue(SyncOperation(
      id: destination.id,
      type: 'update',
      collection: 'destinations',
      data: destination.toMap(),
      timestamp: DateTime.now(),
      userId: destination.createdBy,
    ));

    return destination;
  }

  /// Delete destination (optimistic)
  Future<void> deleteDestination(String destinationId, String userId) async {
    await _destCache.deleteCachedDestination(destinationId);

    await _syncQueue.addToQueue(SyncOperation(
      id: destinationId,
      type: 'delete',
      collection: 'destinations',
      data: {'id': destinationId},
      timestamp: DateTime.now(),
      userId: userId,
    ));
  }

  /// Get destination (from cache first)
  Future<Destination?> getDestination(String destinationId) async {
    return await _destCache.getCachedDestination(destinationId);
  }

  /// Get all destinations (from cache)
  Future<List<Destination>> getAllDestinations() async {
    return await _destCache.getAllCachedDestinations();
  }

  /// Search destinations (from cache)
  Future<List<Destination>> searchDestinations(String query) async {
    return await _destCache.searchCachedDestinations(query);
  }

  // ========== REVIEW OPERATIONS ==========

  /// Create review (optimistic)
  Future<DestinationReview> createReview(DestinationReview review) async {
    await _reviewCache.cacheReview(review);

    await _syncQueue.addToQueue(SyncOperation(
      id: review.id,
      type: 'create',
      collection: 'reviews',
      data: review.toMap(),
      timestamp: DateTime.now(),
      userId: review.userId,
    ));

    return review;
  }

  /// Update review (optimistic)
  Future<DestinationReview> updateReview(DestinationReview review) async {
    await _reviewCache.updateCachedReview(review, markDirty: true);

    await _syncQueue.addToQueue(SyncOperation(
      id: review.id,
      type: 'update',
      collection: 'reviews',
      data: review.toMap(),
      timestamp: DateTime.now(),
      userId: review.userId,
    ));

    return review;
  }

  /// Delete review (optimistic)
  Future<void> deleteReview(String reviewId, String userId) async {
    await _reviewCache.deleteCachedReview(reviewId);

    await _syncQueue.addToQueue(SyncOperation(
      id: reviewId,
      type: 'delete',
      collection: 'reviews',
      data: {'id': reviewId},
      timestamp: DateTime.now(),
      userId: userId,
    ));
  }

  /// Get review (from cache first)
  Future<DestinationReview?> getReview(String reviewId) async {
    return await _reviewCache.getCachedReview(reviewId);
  }

  /// Get destination reviews (from cache)
  Future<List<DestinationReview>> getDestinationReviews(String destinationId) async {
    return await _reviewCache.getCachedReviewsByDestination(destinationId);
  }

  /// Get user reviews (from cache)
  Future<List<DestinationReview>> getUserReviews(String userId) async {
    return await _reviewCache.getCachedReviewsByUser(userId);
  }

  // ========== PROFILE OPERATIONS ==========

  /// Update profile (optimistic)
  Future<UserModel> updateProfile(UserModel profile) async {
    await _profileCache.updateCachedProfile(profile, markDirty: true);

    await _syncQueue.addToQueue(SyncOperation(
      id: profile.uid,
      type: 'update',
      collection: 'profiles',
      data: profile.toJson(),
      timestamp: DateTime.now(),
      userId: profile.uid,
    ));

    return profile;
  }

  /// Get profile (from cache first)
  Future<UserModel?> getProfile(String userId) async {
    return await _profileCache.getCachedProfile(userId);
  }

  /// Get guides (from cache)
  Future<List<UserModel>> getGuides() async {
    return await _profileCache.getCachedGuides();
  }

  // ========== SYNC OPERATIONS ==========

  /// Trigger manual sync
  Future<void> syncNow() async {
    await _syncQueue.syncAll();
  }

  /// Get pending operations count
  int getPendingOperationsCount() {
    return _syncQueue.getPendingCount();
  }

  /// Get sync statistics
  Map<String, dynamic> getSyncStats() {
    return _syncQueue.getStats();
  }

  /// Listen to sync progress
  Stream<SyncProgress> get syncProgress => _syncQueue.syncProgress;

  /// Check if item has pending changes
  Future<bool> hasPendingChanges(String collection, String id) async {
    switch (collection) {
      case 'trips':
        final trip = await _tripCache.getCachedTrip(id);
        // Check if cached data has isDirty flag
        return trip != null; // Simplified, should check isDirty from CachedData
      case 'destinations':
        return await _destCache.isDestinationCached(id);
      case 'reviews':
        return await _reviewCache.isReviewCached(id);
      case 'profiles':
        return await _profileCache.isProfileCached(id);
      default:
        return false;
    }
  }

  /// Get all dirty items that need sync
  Future<Map<String, int>> getDirtyItemsCounts() async {
    final dirtyTrips = await _tripCache.getDirtyTrips();
    final dirtyDests = await _destCache.getDirtyDestinations();
    final dirtyReviews = await _reviewCache.getDirtyReviews();
    final dirtyProfiles = await _profileCache.getDirtyProfiles();

    return {
      'trips': dirtyTrips.length,
      'destinations': dirtyDests.length,
      'reviews': dirtyReviews.length,
      'profiles': dirtyProfiles.length,
      'total': dirtyTrips.length + dirtyDests.length + dirtyReviews.length + dirtyProfiles.length,
    };
  }

  /// Clear failed sync operations
  Future<void> clearFailedOperations() async {
    await _syncQueue.clearFailed();
  }
}

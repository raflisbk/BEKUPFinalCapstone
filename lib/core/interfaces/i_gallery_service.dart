import 'dart:async';

/// Interface for Gallery Service
/// Defines the contract for photo galleries, albums, and photo organization functionality
abstract class IGalleryService {
  // ===============================
  // GALLERY MANAGEMENT
  // ===============================

  /// Create photo gallery
  Future<Map<String, dynamic>> createGallery({
    required String title,
    String? description,
    String? tripId,
    String? destinationId,
    String? coverPhotoId,
    bool isPublic = true,
    List<String>? tags,
  });

  /// Get gallery by ID
  Future<Map<String, dynamic>?> getGallery(String galleryId);

  /// Get user galleries
  Future<List<Map<String, dynamic>>> getUserGalleries({
    String? userId,
    bool? isPublic,
    String? tripId,
    String? destinationId,
    int limit = 20,
  });

  /// Update gallery
  Future<Map<String, dynamic>> updateGallery({
    required String galleryId,
    String? title,
    String? description,
    String? coverPhotoId,
    bool? isPublic,
    List<String>? tags,
    String? status,
  });

  /// Delete gallery
  Future<void> deleteGallery(String galleryId);

  // ===============================
  // ALBUM MANAGEMENT
  // ===============================

  /// Create album within gallery
  Future<Map<String, dynamic>> createAlbum({
    required String galleryId,
    required String title,
    String? description,
    String? coverPhotoId,
    List<String>? tags,
  });

  /// Get gallery albums
  Future<List<Map<String, dynamic>>> getGalleryAlbums(String galleryId);

  /// Delete album
  Future<void> deleteAlbum(String albumId);

  // ===============================
  // PHOTO MANAGEMENT
  // ===============================

  /// Add photo to gallery
  Future<Map<String, dynamic>> addPhotoToGallery({
    required String galleryId,
    required String cloudinaryPublicId,
    required String originalUrl,
    String? albumId,
    String? title,
    String? description,
    String? location,
    DateTime? takenAt,
    Map<String, dynamic>? metadata,
    List<String>? tags,
  });

  /// Get gallery photos
  Future<List<Map<String, dynamic>>> getGalleryPhotos({
    required String galleryId,
    String? albumId,
    int limit = 50,
  });

  /// Update photo
  Future<Map<String, dynamic>> updatePhoto({
    required String photoId,
    String? title,
    String? description,
    String? location,
    DateTime? takenAt,
    List<String>? tags,
    int? sortOrder,
  });

  /// Delete photo
  Future<void> deletePhoto(String photoId);

  // ===============================
  // PHOTO INTERACTIONS
  // ===============================

  /// Like photo
  Future<Map<String, dynamic>> likePhoto(String photoId);

  /// Unlike photo
  Future<void> unlikePhoto(String photoId);

  /// Add comment to photo
  Future<Map<String, dynamic>> addPhotoComment({
    required String photoId,
    required String comment,
  });

  /// Get photo comments
  Future<List<Map<String, dynamic>>> getPhotoComments({
    required String photoId,
    int limit = 20,
  });

  // ===============================
  // GALLERY DISCOVERY
  // ===============================

  /// Search public galleries
  Future<List<Map<String, dynamic>>> searchPublicGalleries({
    String? query,
    List<String>? tags,
    String? destinationId,
    int limit = 20,
  });

  /// Get popular galleries
  Future<List<Map<String, dynamic>>> getPopularGalleries({
    int limit = 10,
    int days = 7,
  });
}
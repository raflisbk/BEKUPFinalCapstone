import 'dart:async';
import '../core/utils/logger.dart';
import 'supabase_config.dart';
import 'supabase_database_service.dart';
import 'media_service.dart';

/// Gallery Service
/// Handles photo galleries, albums, and photo organization
class GalleryService {
  static const String _tag = 'GalleryService';
  static const String _galleriesTable = 'photo_galleries';
  static const String _albumsTable = 'photo_albums';
  static const String _photosTable = 'gallery_photos';
  static const String _likesTable = 'photo_likes';
  static const String _commentsTable = 'photo_comments';

  // Singleton pattern
  static GalleryService? _instance;
  static GalleryService get instance => _instance ??= GalleryService._internal();
  
  GalleryService._internal();

  // ===============================
  // GALLERY MANAGEMENT
  // ===============================

  /// Create photo gallery
  static Future<Map<String, dynamic>> createGallery({
    required String title,
    String? description,
    String? tripId,
    String? destinationId,
    String? coverPhotoId,
    bool isPublic = true,
    List<String>? tags,
  }) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Creating photo gallery: $title');

      final galleryData = {
        'created_by': userId,
        'title': title,
        'description': description,
        'trip_id': tripId,
        'destination_id': destinationId,
        'cover_photo_id': coverPhotoId,
        'is_public': isPublic,
        'tags': tags ?? [],
        'photo_count': 0,
        'like_count': 0,
        'view_count': 0,
        'status': 'active',
      };

      final result = await SupabaseDatabaseService.insert(
        table: _galleriesTable,
        data: galleryData,
      );

      AppLogger.success(_tag, 'Photo gallery created successfully: $title');
      return result;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to create photo gallery', e, stackTrace);
      rethrow;
    }
  }

  /// Get gallery by ID
  static Future<Map<String, dynamic>?> getGallery(String galleryId) async {
    try {
      AppLogger.debug(_tag, 'Getting gallery: $galleryId');

      final galleries = await SupabaseDatabaseService.select(
        table: _galleriesTable,
        filters: {'id': galleryId},
      );

      if (galleries.isEmpty) {
        AppLogger.warning(_tag, 'Gallery not found: $galleryId');
        return null;
      }

      final gallery = galleries.first;
      
      // Get photos in this gallery
      gallery['photos'] = await getGalleryPhotos(galleryId: galleryId);
      
      // Get albums in this gallery
      gallery['albums'] = await getGalleryAlbums(galleryId);

      // Increment view count
      await _incrementViewCount(galleryId);

      AppLogger.success(_tag, 'Retrieved gallery: ${gallery['title']}');
      return gallery;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get gallery', e, stackTrace);
      rethrow;
    }
  }

  /// Get user galleries
  static Future<List<Map<String, dynamic>>> getUserGalleries({
    String? userId,
    bool? isPublic,
    String? tripId,
    String? destinationId,
    int limit = 20,
  }) async {
    try {
      final currentUserId = userId ?? SupabaseConfig.userId;
      if (currentUserId == null) {
        throw Exception('No user ID provided');
      }

      AppLogger.debug(_tag, 'Getting user galleries: $currentUserId');

      final filters = <String, dynamic>{'created_by': currentUserId};
      if (isPublic != null) filters['is_public'] = isPublic;
      if (tripId != null) filters['trip_id'] = tripId;
      if (destinationId != null) filters['destination_id'] = destinationId;

      final galleries = await SupabaseDatabaseService.select(
        table: _galleriesTable,
        filters: filters,
        orderBy: 'created_at',
        ascending: false,
        limit: limit,
      );

      // Add cover photo URLs for each gallery
      for (final gallery in galleries) {
        if (gallery['cover_photo_id'] != null) {
          final photos = await SupabaseDatabaseService.select(
            table: _photosTable,
            filters: {'id': gallery['cover_photo_id']},
          );
          
          if (photos.isNotEmpty) {
            final photo = photos.first;
            gallery['cover_photo_url'] = MediaService.getThumbnailUrl(
              publicId: photo['cloudinary_public_id'],
              width: 300,
              height: 200,
            );
          }
        }
      }

      AppLogger.success(_tag, 'Retrieved ${galleries.length} galleries');
      return galleries;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get user galleries', e, stackTrace);
      rethrow;
    }
  }

  /// Update gallery
  static Future<Map<String, dynamic>> updateGallery({
    required String galleryId,
    String? title,
    String? description,
    String? coverPhotoId,
    bool? isPublic,
    List<String>? tags,
    String? status,
  }) async {
    try {
      AppLogger.debug(_tag, 'Updating gallery: $galleryId');

      final updateData = <String, dynamic>{};
      
      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (coverPhotoId != null) updateData['cover_photo_id'] = coverPhotoId;
      if (isPublic != null) updateData['is_public'] = isPublic;
      if (tags != null) updateData['tags'] = tags;
      if (status != null) updateData['status'] = status;

      if (updateData.isEmpty) {
        throw Exception('No data provided for update');
      }

      final result = await SupabaseDatabaseService.update(
        table: _galleriesTable,
        id: galleryId,
        data: updateData,
      );

      AppLogger.success(_tag, 'Gallery updated successfully');
      return result;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to update gallery', e, stackTrace);
      rethrow;
    }
  }

  /// Delete gallery
  static Future<void> deleteGallery(String galleryId) async {
    try {
      AppLogger.warning(_tag, 'Deleting gallery: $galleryId');

      // Delete all photos in gallery
      final photos = await getGalleryPhotos(galleryId: galleryId);
      for (final photo in photos) {
        await deletePhoto(photo['id']);
      }

      // Delete all albums in gallery
      final albums = await getGalleryAlbums(galleryId);
      for (final album in albums) {
        await deleteAlbum(album['id']);
      }

      // Delete the gallery
      await SupabaseDatabaseService.delete(
        table: _galleriesTable,
        id: galleryId,
      );

      AppLogger.success(_tag, 'Gallery deleted successfully');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to delete gallery', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // ALBUM MANAGEMENT
  // ===============================

  /// Create album within gallery
  static Future<Map<String, dynamic>> createAlbum({
    required String galleryId,
    required String title,
    String? description,
    String? coverPhotoId,
    List<String>? tags,
  }) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Creating album: $title');

      final albumData = {
        'gallery_id': galleryId,
        'created_by': userId,
        'title': title,
        'description': description,
        'cover_photo_id': coverPhotoId,
        'tags': tags ?? [],
        'photo_count': 0,
        'sort_order': 0,
        'is_active': true,
      };

      final result = await SupabaseDatabaseService.insert(
        table: _albumsTable,
        data: albumData,
      );

      AppLogger.success(_tag, 'Album created successfully: $title');
      return result;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to create album', e, stackTrace);
      rethrow;
    }
  }

  /// Get gallery albums
  static Future<List<Map<String, dynamic>>> getGalleryAlbums(String galleryId) async {
    try {
      AppLogger.debug(_tag, 'Getting albums for gallery: $galleryId');

      final albums = await SupabaseDatabaseService.select(
        table: _albumsTable,
        filters: {'gallery_id': galleryId, 'is_active': true},
        orderBy: 'sort_order',
      );

      // Add cover photo URLs for each album
      for (final album in albums) {
        if (album['cover_photo_id'] != null) {
          final photos = await SupabaseDatabaseService.select(
            table: _photosTable,
            filters: {'id': album['cover_photo_id']},
          );
          
          if (photos.isNotEmpty) {
            final photo = photos.first;
            album['cover_photo_url'] = MediaService.getThumbnailUrl(
              publicId: photo['cloudinary_public_id'],
              width: 200,
              height: 150,
            );
          }
        }
      }

      AppLogger.success(_tag, 'Retrieved ${albums.length} albums');
      return albums;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get gallery albums', e, stackTrace);
      rethrow;
    }
  }

  /// Delete album
  static Future<void> deleteAlbum(String albumId) async {
    try {
      AppLogger.warning(_tag, 'Deleting album: $albumId');

      // Delete all photos in album
      final photos = await SupabaseDatabaseService.select(
        table: _photosTable,
        filters: {'album_id': albumId},
      );

      for (final photo in photos) {
        await deletePhoto(photo['id']);
      }

      // Delete the album
      await SupabaseDatabaseService.delete(
        table: _albumsTable,
        id: albumId,
      );

      AppLogger.success(_tag, 'Album deleted successfully');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to delete album', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // PHOTO MANAGEMENT
  // ===============================

  /// Add photo to gallery
  static Future<Map<String, dynamic>> addPhotoToGallery({
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
  }) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Adding photo to gallery: $galleryId');

      final photoData = {
        'gallery_id': galleryId,
        'album_id': albumId,
        'uploaded_by': userId,
        'cloudinary_public_id': cloudinaryPublicId,
        'original_url': originalUrl,
        'title': title,
        'description': description,
        'location': location,
        'taken_at': takenAt?.toIso8601String(),
        'metadata': metadata ?? {},
        'tags': tags ?? [],
        'like_count': 0,
        'comment_count': 0,
        'view_count': 0,
        'sort_order': 0,
        'is_active': true,
      };

      final result = await SupabaseDatabaseService.insert(
        table: _photosTable,
        data: photoData,
      );

      // Update photo counts
      await _updateGalleryPhotoCount(galleryId);
      if (albumId != null) {
        await _updateAlbumPhotoCount(albumId);
      }

      // Generate various image URLs
      result['thumbnail_url'] = MediaService.getThumbnailUrl(
        publicId: cloudinaryPublicId,
      );
      result['responsive_urls'] = MediaService.getResponsiveImageUrls(
        publicId: cloudinaryPublicId,
      );

      AppLogger.success(_tag, 'Photo added to gallery successfully');
      return result;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to add photo to gallery', e, stackTrace);
      rethrow;
    }
  }

  /// Get gallery photos
  static Future<List<Map<String, dynamic>>> getGalleryPhotos({
    required String galleryId,
    String? albumId,
    int limit = 50,
  }) async {
    try {
      AppLogger.debug(_tag, 'Getting photos for gallery: $galleryId');

      final filters = <String, dynamic>{
        'gallery_id': galleryId,
        'is_active': true,
      };
      if (albumId != null) filters['album_id'] = albumId;

      final photos = await SupabaseDatabaseService.select(
        table: _photosTable,
        filters: filters,
        orderBy: 'sort_order',
        limit: limit,
      );

      // Add image URLs for each photo
      for (final photo in photos) {
        final publicId = photo['cloudinary_public_id'];
        photo['thumbnail_url'] = MediaService.getThumbnailUrl(
          publicId: publicId,
        );
        photo['responsive_urls'] = MediaService.getResponsiveImageUrls(
          publicId: publicId,
        );
      }

      AppLogger.success(_tag, 'Retrieved ${photos.length} photos');
      return photos;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get gallery photos', e, stackTrace);
      rethrow;
    }
  }

  /// Update photo
  static Future<Map<String, dynamic>> updatePhoto({
    required String photoId,
    String? title,
    String? description,
    String? location,
    DateTime? takenAt,
    List<String>? tags,
    int? sortOrder,
  }) async {
    try {
      AppLogger.debug(_tag, 'Updating photo: $photoId');

      final updateData = <String, dynamic>{};
      
      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (location != null) updateData['location'] = location;
      if (takenAt != null) updateData['taken_at'] = takenAt.toIso8601String();
      if (tags != null) updateData['tags'] = tags;
      if (sortOrder != null) updateData['sort_order'] = sortOrder;

      if (updateData.isEmpty) {
        throw Exception('No data provided for update');
      }

      final result = await SupabaseDatabaseService.update(
        table: _photosTable,
        id: photoId,
        data: updateData,
      );

      AppLogger.success(_tag, 'Photo updated successfully');
      return result;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to update photo', e, stackTrace);
      rethrow;
    }
  }

  /// Delete photo
  static Future<void> deletePhoto(String photoId) async {
    try {
      AppLogger.warning(_tag, 'Deleting photo: $photoId');

      // Get photo details
      final photos = await SupabaseDatabaseService.select(
        table: _photosTable,
        filters: {'id': photoId},
      );

      if (photos.isEmpty) {
        throw Exception('Photo not found');
      }

      final photo = photos.first;
      final galleryId = photo['gallery_id'];
      final albumId = photo['album_id'];
      final publicId = photo['cloudinary_public_id'];

      // Delete from Cloudinary
      await MediaService.deleteMedia(publicId: publicId);

      // Delete comments and likes
      await _deletePhotoComments(photoId);
      await _deletePhotoLikes(photoId);

      // Delete photo record
      await SupabaseDatabaseService.delete(
        table: _photosTable,
        id: photoId,
      );

      // Update photo counts
      await _updateGalleryPhotoCount(galleryId);
      if (albumId != null) {
        await _updateAlbumPhotoCount(albumId);
      }

      AppLogger.success(_tag, 'Photo deleted successfully');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to delete photo', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // PHOTO INTERACTIONS
  // ===============================

  /// Like photo
  static Future<Map<String, dynamic>> likePhoto(String photoId) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Liking photo: $photoId');

      // Check if already liked
      final existingLikes = await SupabaseDatabaseService.select(
        table: _likesTable,
        filters: {'photo_id': photoId, 'user_id': userId},
      );

      if (existingLikes.isNotEmpty) {
        throw Exception('Photo already liked');
      }

      // Add like
      final likeData = {
        'photo_id': photoId,
        'user_id': userId,
      };

      final result = await SupabaseDatabaseService.insert(
        table: _likesTable,
        data: likeData,
      );

      // Update like count
      await _updatePhotoLikeCount(photoId);

      AppLogger.success(_tag, 'Photo liked successfully');
      return result;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to like photo', e, stackTrace);
      rethrow;
    }
  }

  /// Unlike photo
  static Future<void> unlikePhoto(String photoId) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Unliking photo: $photoId');

      // Find and delete like
      final likes = await SupabaseDatabaseService.select(
        table: _likesTable,
        filters: {'photo_id': photoId, 'user_id': userId},
      );

      if (likes.isEmpty) {
        throw Exception('Photo not liked');
      }

      await SupabaseDatabaseService.delete(
        table: _likesTable,
        id: likes.first['id'],
      );

      // Update like count
      await _updatePhotoLikeCount(photoId);

      AppLogger.success(_tag, 'Photo unliked successfully');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to unlike photo', e, stackTrace);
      rethrow;
    }
  }

  /// Add comment to photo
  static Future<Map<String, dynamic>> addPhotoComment({
    required String photoId,
    required String comment,
  }) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Adding comment to photo: $photoId');

      final commentData = {
        'photo_id': photoId,
        'user_id': userId,
        'comment': comment,
        'is_active': true,
      };

      final result = await SupabaseDatabaseService.insert(
        table: _commentsTable,
        data: commentData,
      );

      // Update comment count
      await _updatePhotoCommentCount(photoId);

      AppLogger.success(_tag, 'Comment added successfully');
      return result;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to add photo comment', e, stackTrace);
      rethrow;
    }
  }

  /// Get photo comments
  static Future<List<Map<String, dynamic>>> getPhotoComments({
    required String photoId,
    int limit = 20,
  }) async {
    try {
      AppLogger.debug(_tag, 'Getting comments for photo: $photoId');

      final comments = await SupabaseDatabaseService.select(
        table: _commentsTable,
        filters: {'photo_id': photoId, 'is_active': true},
        orderBy: 'created_at',
        ascending: false,
        limit: limit,
      );

      AppLogger.success(_tag, 'Retrieved ${comments.length} comments');
      return comments;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get photo comments', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // GALLERY DISCOVERY
  // ===============================

  /// Search public galleries
  static Future<List<Map<String, dynamic>>> searchPublicGalleries({
    String? query,
    List<String>? tags,
    String? destinationId,
    int limit = 20,
  }) async {
    try {
      AppLogger.debug(_tag, 'Searching public galleries');

      final filters = <String, dynamic>{'is_public': true, 'status': 'active'};
      if (destinationId != null) filters['destination_id'] = destinationId;

      var galleries = await SupabaseDatabaseService.select(
        table: _galleriesTable,
        filters: filters,
        orderBy: 'view_count',
        ascending: false,
        limit: limit,
      );

      // Filter by query and tags if provided
      if (query != null || tags != null) {
        galleries = galleries.where((gallery) {
          if (query != null) {
            final title = gallery['title']?.toString().toLowerCase() ?? '';
            final description = gallery['description']?.toString().toLowerCase() ?? '';
            final searchQuery = query.toLowerCase();
            
            if (!title.contains(searchQuery) && !description.contains(searchQuery)) {
              return false;
            }
          }

          if (tags != null && tags.isNotEmpty) {
            final galleryTags = List<String>.from(gallery['tags'] ?? []);
            final hasMatchingTag = tags.any((tag) => galleryTags.contains(tag));
            if (!hasMatchingTag) {
              return false;
            }
          }

          return true;
        }).toList();
      }

      // Add cover photo URLs
      for (final gallery in galleries) {
        if (gallery['cover_photo_id'] != null) {
          final photos = await SupabaseDatabaseService.select(
            table: _photosTable,
            filters: {'id': gallery['cover_photo_id']},
          );
          
          if (photos.isNotEmpty) {
            final photo = photos.first;
            gallery['cover_photo_url'] = MediaService.getThumbnailUrl(
              publicId: photo['cloudinary_public_id'],
              width: 300,
              height: 200,
            );
          }
        }
      }

      AppLogger.success(_tag, 'Found ${galleries.length} public galleries');
      return galleries;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to search public galleries', e, stackTrace);
      rethrow;
    }
  }

  /// Get popular galleries
  static Future<List<Map<String, dynamic>>> getPopularGalleries({
    int limit = 10,
    int days = 7,
  }) async {
    try {
      AppLogger.debug(_tag, 'Getting popular galleries');

      final galleries = await SupabaseDatabaseService.select(
        table: _galleriesTable,
        filters: {'is_public': true, 'status': 'active'},
        orderBy: 'like_count',
        ascending: false,
        limit: limit,
      );

      // Add cover photo URLs
      for (final gallery in galleries) {
        if (gallery['cover_photo_id'] != null) {
          final photos = await SupabaseDatabaseService.select(
            table: _photosTable,
            filters: {'id': gallery['cover_photo_id']},
          );
          
          if (photos.isNotEmpty) {
            final photo = photos.first;
            gallery['cover_photo_url'] = MediaService.getThumbnailUrl(
              publicId: photo['cloudinary_public_id'],
              width: 300,
              height: 200,
            );
          }
        }
      }

      AppLogger.success(_tag, 'Retrieved ${galleries.length} popular galleries');
      return galleries;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get popular galleries', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // PRIVATE HELPER METHODS
  // ===============================

  /// Update gallery photo count
  static Future<void> _updateGalleryPhotoCount(String galleryId) async {
    try {
      final photos = await SupabaseDatabaseService.select(
        table: _photosTable,
        filters: {'gallery_id': galleryId, 'is_active': true},
      );

      await SupabaseDatabaseService.update(
        table: _galleriesTable,
        id: galleryId,
        data: {'photo_count': photos.length},
      );
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to update gallery photo count', e);
    }
  }

  /// Update album photo count
  static Future<void> _updateAlbumPhotoCount(String albumId) async {
    try {
      final photos = await SupabaseDatabaseService.select(
        table: _photosTable,
        filters: {'album_id': albumId, 'is_active': true},
      );

      await SupabaseDatabaseService.update(
        table: _albumsTable,
        id: albumId,
        data: {'photo_count': photos.length},
      );
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to update album photo count', e);
    }
  }

  /// Update photo like count
  static Future<void> _updatePhotoLikeCount(String photoId) async {
    try {
      final likes = await SupabaseDatabaseService.select(
        table: _likesTable,
        filters: {'photo_id': photoId},
      );

      await SupabaseDatabaseService.update(
        table: _photosTable,
        id: photoId,
        data: {'like_count': likes.length},
      );
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to update photo like count', e);
    }
  }

  /// Update photo comment count
  static Future<void> _updatePhotoCommentCount(String photoId) async {
    try {
      final comments = await SupabaseDatabaseService.select(
        table: _commentsTable,
        filters: {'photo_id': photoId, 'is_active': true},
      );

      await SupabaseDatabaseService.update(
        table: _photosTable,
        id: photoId,
        data: {'comment_count': comments.length},
      );
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to update photo comment count', e);
    }
  }

  /// Increment gallery view count
  static Future<void> _incrementViewCount(String galleryId) async {
    try {
      final galleries = await SupabaseDatabaseService.select(
        table: _galleriesTable,
        filters: {'id': galleryId},
      );

      if (galleries.isNotEmpty) {
        final currentViews = galleries.first['view_count'] ?? 0;
        await SupabaseDatabaseService.update(
          table: _galleriesTable,
          id: galleryId,
          data: {'view_count': currentViews + 1},
        );
      }
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to increment view count', e);
    }
  }

  /// Delete photo comments
  static Future<void> _deletePhotoComments(String photoId) async {
    try {
      final comments = await SupabaseDatabaseService.select(
        table: _commentsTable,
        filters: {'photo_id': photoId},
      );

      for (final comment in comments) {
        await SupabaseDatabaseService.delete(
          table: _commentsTable,
          id: comment['id'],
        );
      }
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to delete photo comments', e);
    }
  }

  /// Delete photo likes
  static Future<void> _deletePhotoLikes(String photoId) async {
    try {
      final likes = await SupabaseDatabaseService.select(
        table: _likesTable,
        filters: {'photo_id': photoId},
      );

      for (final like in likes) {
        await SupabaseDatabaseService.delete(
          table: _likesTable,
          id: like['id'],
        );
      }
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to delete photo likes', e);
    }
  }
}
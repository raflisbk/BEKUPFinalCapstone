import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import '../models/gallery_model.dart';
import '../../services/gallery_service.dart';

/// Provider for managing photo gallery functionality (simplified version)
class GalleryProvider with ChangeNotifier {
  final GalleryService _galleryService = GalleryService.instance;

  List<Photo> _photos = []; // Using existing Photo model from gallery_model.dart
  bool _isLoading = false;
  String? _error;

  Photo? _selectedPhoto;
  bool _isSelectionMode = false;

  // Getters
  List<Photo> get photos => _photos;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Photo? get selectedPhoto => _selectedPhoto;
  bool get isSelectionMode => _isSelectionMode;

  /// Load gallery photos
  Future<void> loadPhotos({
    String? galleryId,
    int? limit,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final photosData = await GalleryService.getGalleryPhotos(
        galleryId: galleryId ?? '',
        limit: limit ?? 20,
      );

      // Convert to Photo objects (simplified conversion)
      _photos = photosData.map((data) => Photo(
        id: data['id'] ?? '',
        userId: data['user_id'] ?? '',
        userName: data['user_name'] ?? '',
        userPhotoUrl: data['user_photo_url'],
        imageUrl: data['image_url'] ?? '',
        caption: data['caption'],
        location: data['location'],
        destinationId: data['destination_id'],
        destinationName: data['destination_name'],
        tags: List<String>.from(data['tags'] ?? []),
        likes: data['likes'] ?? 0,
        likedBy: List<String>.from(data['liked_by'] ?? []),
        comments: data['comments'] ?? 0,
        isPublic: data['is_public'] ?? true,
        createdAt: DateTime.parse(data['created_at'] ?? DateTime.now().toIso8601String()),
        updatedAt: DateTime.parse(data['updated_at'] ?? DateTime.now().toIso8601String()),
      )).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create a new gallery
  Future<Map<String, dynamic>?> createGallery({
    required String title,
    String? description,
    bool isPublic = true,
  }) async {
    try {
      final gallery = await GalleryService.createGallery(
        title: title,
        description: description,
        isPublic: isPublic,
      );
      return gallery;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Add photo to gallery
  Future<Map<String, dynamic>?> addPhoto({
    required String galleryId,
    required String imageUrl,
    String? caption,
    List<String>? tags,
  }) async {
    try {
      final photo = await GalleryService.addPhotoToGallery(
        galleryId: galleryId,
        imageUrl: imageUrl,
        caption: caption,
        tags: tags,
      );
      
      // Refresh photos
      await loadPhotos(galleryId: galleryId);
      
      return photo;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Delete a photo
  Future<void> deletePhoto(String photoId) async {
    try {
      await GalleryService.deletePhoto(photoId);
      
      // Remove from local state
      _photos.removeWhere((photo) => photo.id == photoId);
      
      if (_selectedPhoto?.id == photoId) {
        _selectedPhoto = null;
      }
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Like a photo
  Future<void> likePhoto(String photoId) async {
    try {
      await GalleryService.likePhoto(photoId);
      
      // Update local state
      final photoIndex = _photos.indexWhere((photo) => photo.id == photoId);
      if (photoIndex != -1) {
        final photo = _photos[photoIndex];
        _photos[photoIndex] = photo.copyWith(
          likes: photo.likes + 1,
        );
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Unlike a photo
  Future<void> unlikePhoto(String photoId) async {
    try {
      await GalleryService.unlikePhoto(photoId);
      
      // Update local state
      final photoIndex = _photos.indexWhere((photo) => photo.id == photoId);
      if (photoIndex != -1) {
        final photo = _photos[photoIndex];
        _photos[photoIndex] = photo.copyWith(
          likes: photo.likes > 0 ? photo.likes - 1 : 0,
        );
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Add comment to photo
  Future<void> addComment({
    required String photoId,
    required String comment,
  }) async {
    try {
      await GalleryService.addPhotoComment(
        photoId: photoId,
        comment: comment,
      );
      
      // Update local state
      final photoIndex = _photos.indexWhere((photo) => photo.id == photoId);
      if (photoIndex != -1) {
        final photo = _photos[photoIndex];
        _photos[photoIndex] = photo.copyWith(
          comments: photo.comments + 1,
        );
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Get photo comments
  Future<List<Map<String, dynamic>>> getPhotoComments(String photoId) async {
    try {
      return await GalleryService.getPhotoComments(photoId: photoId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  // Selection management
  void selectPhoto(Photo photo) {
    _selectedPhoto = photo;
    notifyListeners();
  }

  void toggleSelectionMode() {
    _isSelectionMode = !_isSelectionMode;
    if (!_isSelectionMode) {
      _selectedPhoto = null;
    }
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Refresh gallery
  Future<void> refresh({String? galleryId}) async {
    await loadPhotos(galleryId: galleryId);
  }
}
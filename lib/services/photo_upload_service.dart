import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../core/utils/logger.dart';

class PhotoUploadService {
  static final PhotoUploadService _instance = PhotoUploadService._internal();
  factory PhotoUploadService() => _instance;
  PhotoUploadService._internal();

  static const String _tag = 'PhotoUploadService';

  final ImagePicker _picker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Pick image from gallery
  Future<File?> pickImageFromGallery() async {
    try {
      AppLogger.debug(_tag, 'Opening gallery to pick image');

      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) {
        AppLogger.info(_tag, 'User cancelled image selection');
        return null;
      }

      AppLogger.success(_tag, 'Image selected from gallery', {
        'path': image.path,
        'name': image.name,
      });

      return File(image.path);
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to pick image from gallery', e, stackTrace);
      return null;
    }
  }

  /// Pick image from camera
  Future<File?> pickImageFromCamera() async {
    try {
      AppLogger.debug(_tag, 'Opening camera to take photo');

      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) {
        AppLogger.info(_tag, 'User cancelled camera');
        return null;
      }

      AppLogger.success(_tag, 'Photo taken with camera', {
        'path': image.path,
        'name': image.name,
      });

      return File(image.path);
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to take photo with camera', e, stackTrace);
      return null;
    }
  }

  /// Upload image to Firebase Storage
  Future<String?> uploadProfilePhoto(File imageFile) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        AppLogger.error(_tag, 'Cannot upload photo: User not authenticated');
        return null;
      }

      AppLogger.debug(_tag, 'Uploading profile photo to Firebase Storage', {
        'userId': userId,
        'filePath': imageFile.path,
      });

      // Create unique file name
      final String fileName = 'profile_$userId.jpg';
      final Reference ref = _storage.ref().child('profile_photos/$fileName');

      // Upload file
      final UploadTask uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'userId': userId,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      // Wait for upload to complete
      final TaskSnapshot snapshot = await uploadTask;

      // Get download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      AppLogger.success(_tag, 'Profile photo uploaded successfully', {
        'userId': userId,
        'downloadUrl': downloadUrl,
      });

      return downloadUrl;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to upload profile photo', e, stackTrace);
      return null;
    }
  }

  /// Delete old profile photo
  Future<bool> deleteProfilePhoto(String photoUrl) async {
    try {
      if (photoUrl.isEmpty) {
        AppLogger.warning(_tag, 'No photo URL provided for deletion');
        return false;
      }

      AppLogger.debug(_tag, 'Deleting old profile photo', {
        'photoUrl': photoUrl,
      });

      // Get reference from URL
      final Reference ref = _storage.refFromURL(photoUrl);
      await ref.delete();

      AppLogger.success(_tag, 'Old profile photo deleted successfully');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to delete old profile photo', e, stackTrace);
      // Don't fail the upload if deletion fails
      return false;
    }
  }

  /// Show photo source selection dialog
  Future<File?> showPhotoSourceDialog({
    required Function() onGallery,
    required Function() onCamera,
  }) async {
    // This method is placeholder - actual dialog should be shown in UI layer
    AppLogger.debug(_tag, 'Photo source selection needed');
    return null;
  }
}

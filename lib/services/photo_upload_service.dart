// This service has been replaced by cloudinary_photo_upload_service.dart
// All photo upload functionality now uses Cloudinary instead of Firebase Storage
// 
// Migration completed:
// - Firebase Storage → Cloudinary (25GB FREE)
// - Firebase Auth → Supabase Auth (FREE)
//
// For photo uploads, use: CloudinaryPhotoUploadService()

import '../core/utils/logger.dart';

class PhotoUploadService {
  static const String _tag = 'PhotoUploadService';

  PhotoUploadService() {
    AppLogger.warning(_tag, 'PhotoUploadService is deprecated. Use CloudinaryPhotoUploadService instead.');
  }

  @deprecated
  void migrateToCloudinary() {
    AppLogger.info(_tag, 'All photo upload functionality has been migrated to Cloudinary');
    AppLogger.info(_tag, 'Use CloudinaryPhotoUploadService() for all photo operations');
  }
}

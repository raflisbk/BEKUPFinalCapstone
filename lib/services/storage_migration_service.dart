import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import '../core/utils/logger.dart';
import 'cloudinary_service.dart';

/// Service to migrate from Firebase Storage to Cloudinary
class StorageMigrationService {
  static const String _tag = 'StorageMigrationService';
  static final StorageMigrationService _instance = StorageMigrationService._internal();
  factory StorageMigrationService() => _instance;
  StorageMigrationService._internal();

  final CloudinaryService _cloudinaryService = CloudinaryService();
  final FirebaseStorage _firebaseStorage = FirebaseStorage.instance;

  /// Migrate a single file from Firebase Storage to Cloudinary
  Future<String?> migrateFile({
    required String firebaseUrl,
    required String cloudinaryFolder,
    String? fileName,
  }) async {
    try {
      AppLogger.info(_tag, 'Migrating file from Firebase to Cloudinary', {
        'firebaseUrl': firebaseUrl,
        'cloudinaryFolder': cloudinaryFolder,
        'fileName': fileName,
      });

      // Download file from Firebase Storage
      final response = await http.get(Uri.parse(firebaseUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to download file from Firebase Storage');
      }

      final bytes = response.bodyBytes;
      
      // Upload to Cloudinary
      final cloudinaryUrl = await _cloudinaryService.uploadBytes(
        bytes: bytes,
        folder: cloudinaryFolder,
        fileName: fileName ?? _extractFileNameFromUrl(firebaseUrl),
      );

      AppLogger.success(_tag, 'File migrated successfully', {
        'from': firebaseUrl,
        'to': cloudinaryUrl,
      });

      return cloudinaryUrl;
      
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to migrate file', e, stackTrace);
      return null;
    }
  }

  /// Migrate multiple files from Firebase Storage to Cloudinary
  Future<Map<String, String>> migrateMultipleFiles({
    required List<String> firebaseUrls,
    required String cloudinaryFolder,
  }) async {
    Map<String, String> migrationMap = {};

    for (String firebaseUrl in firebaseUrls) {
      try {
        final cloudinaryUrl = await migrateFile(
          firebaseUrl: firebaseUrl,
          cloudinaryFolder: cloudinaryFolder,
        );

        if (cloudinaryUrl != null) {
          migrationMap[firebaseUrl] = cloudinaryUrl;
        }
      } catch (e) {
        AppLogger.error(_tag, 'Failed to migrate individual file: $firebaseUrl', e);
      }
    }

    AppLogger.info(_tag, 'Batch migration completed', {
      'total': firebaseUrls.length,
      'successful': migrationMap.length,
      'failed': firebaseUrls.length - migrationMap.length,
    });

    return migrationMap;
  }

  /// Delete file from Firebase Storage after successful migration
  Future<bool> deleteFromFirebase(String firebaseUrl) async {
    try {
      final ref = _firebaseStorage.refFromURL(firebaseUrl);
      await ref.delete();
      
      AppLogger.success(_tag, 'File deleted from Firebase Storage', {
        'url': firebaseUrl,
      });

      return true;
      
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to delete from Firebase Storage', e, stackTrace);
      return false;
    }
  }

  /// Extract filename from Firebase Storage URL
  String _extractFileNameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final path = uri.path;
      final fileName = path.split('/').last;
      return fileName.split('?').first; // Remove query parameters
    } catch (e) {
      return 'migrated_${DateTime.now().millisecondsSinceEpoch}';
    }
  }



  /// Generate migration report
  Map<String, dynamic> generateMigrationReport({
    required int totalFiles,
    required int successfulMigrations,
    required List<String> failedUrls,
    required double totalSizeBytes,
  }) {
    final report = {
      'migration_date': DateTime.now().toIso8601String(),
      'total_files': totalFiles,
      'successful_migrations': successfulMigrations,
      'failed_migrations': failedUrls.length,
      'success_rate': totalFiles > 0 ? (successfulMigrations / totalFiles * 100).toStringAsFixed(2) : '0.00',
      'total_size_mb': (totalSizeBytes / (1024 * 1024)).toStringAsFixed(2),
      'failed_urls': failedUrls,
      'estimated_cost_savings': _calculateCostSavings(totalSizeBytes),
    };

    AppLogger.info(_tag, 'Migration report generated', report);
    
    return report;
  }

  /// Calculate estimated cost savings
  Map<String, dynamic> _calculateCostSavings(double totalSizeBytes) {
    final sizeGB = totalSizeBytes / (1024 * 1024 * 1024);
    
    // Firebase Storage pricing (approximate)
    const firebaseCostPerGB = 0.026; // $0.026 per GB per month
    const firebaseDownloadCostPerGB = 0.12; // $0.12 per GB of downloads
    
    // Cloudinary free tier
    const cloudinaryFreeStorageGB = 25;
    const cloudinaryFreeBandwidthGB = 25;
    
    final monthlyStorageSavings = sizeGB <= cloudinaryFreeStorageGB 
        ? sizeGB * firebaseCostPerGB 
        : cloudinaryFreeStorageGB * firebaseCostPerGB;
    
    final monthlyBandwidthSavings = sizeGB <= cloudinaryFreeBandwidthGB
        ? sizeGB * firebaseDownloadCostPerGB
        : cloudinaryFreeBandwidthGB * firebaseDownloadCostPerGB;

    return {
      'monthly_storage_savings_usd': monthlyStorageSavings.toStringAsFixed(2),
      'monthly_bandwidth_savings_usd': monthlyBandwidthSavings.toStringAsFixed(2),
      'total_monthly_savings_usd': (monthlyStorageSavings + monthlyBandwidthSavings).toStringAsFixed(2),
      'annual_savings_usd': ((monthlyStorageSavings + monthlyBandwidthSavings) * 12).toStringAsFixed(2),
      'cloudinary_free_tier_suitable': sizeGB <= cloudinaryFreeStorageGB,
    };
  }
}
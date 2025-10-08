import '../../core/database/hive_service.dart';
import '../../core/database/models/cached_data.dart';
import '../../core/models/user_model.dart';

/// Service for caching user profile data offline
class ProfileCacheService {
  static final ProfileCacheService _instance = ProfileCacheService._internal();
  factory ProfileCacheService() => _instance;
  ProfileCacheService._internal();

  final HiveService _hiveService = HiveService.instance;

  /// Get cached profile by ID
  Future<UserModel?> getCachedProfile(String uid) async {
    try {
      final box = _hiveService.profiles;
      final cached = box.get(uid) as CachedData?;
      
      if (cached == null) return null;
      
      return UserModel.fromMap(cached.data);
    } catch (e) {
      print('Error getting cached profile: $e');
      return null;
    }
  }

  /// Get all cached profiles
  Future<List<UserModel>> getAllCachedProfiles() async {
    try {
      final box = _hiveService.profiles;
      final profiles = <UserModel>[];
      
      for (final key in box.keys) {
        final cached = box.get(key) as CachedData?;
        if (cached != null) {
          try {
            profiles.add(UserModel.fromMap(cached.data));
          } catch (e) {
            print('Error parsing cached profile $key: $e');
          }
        }
      }
      
      return profiles;
    } catch (e) {
      print('Error getting all cached profiles: $e');
      return [];
    }
  }

  /// Cache single profile
  Future<void> cacheProfile(UserModel profile) async {
    try {
      final box = _hiveService.profiles;
      final cached = CachedData(
        id: profile.uid,
        data: profile.toJson(), // Use toJson for cache (ISO8601 dates)
        cachedAt: DateTime.now(),
        isDirty: false,
      );
      
      await box.put(profile.uid, cached);
    } catch (e) {
      print('Error caching profile: $e');
    }
  }

  /// Cache multiple profiles
  Future<void> cacheProfiles(List<UserModel> profiles) async {
    try {
      final box = _hiveService.profiles;
      final now = DateTime.now();
      
      final cachedData = {
        for (var profile in profiles)
          profile.uid: CachedData(
            id: profile.uid,
            data: profile.toJson(),
            cachedAt: now,
            isDirty: false,
          )
      };
      
      await box.putAll(cachedData);
    } catch (e) {
      print('Error caching profiles: $e');
    }
  }

  /// Update cached profile
  Future<void> updateCachedProfile(
    UserModel profile, {
    bool markDirty = false,
  }) async {
    try {
      final box = _hiveService.profiles;
      final existing = box.get(profile.uid) as CachedData?;
      
      final cached = CachedData(
        id: profile.uid,
        data: profile.toJson(),
        cachedAt: existing?.cachedAt ?? DateTime.now(),
        isDirty: markDirty,
        lastSyncedAt: markDirty ? existing?.lastSyncedAt : DateTime.now(),
      );
      
      await box.put(profile.uid, cached);
    } catch (e) {
      print('Error updating cached profile: $e');
    }
  }

  /// Delete cached profile
  Future<void> deleteCachedProfile(String uid) async {
    try {
      final box = _hiveService.profiles;
      await box.delete(uid);
    } catch (e) {
      print('Error deleting cached profile: $e');
    }
  }

  /// Get dirty profiles (need sync)
  Future<List<UserModel>> getDirtyProfiles() async {
    try {
      final box = _hiveService.profiles;
      final profiles = <UserModel>[];
      
      for (final key in box.keys) {
        final cached = box.get(key) as CachedData?;
        if (cached != null && cached.isDirty) {
          try {
            profiles.add(UserModel.fromMap(cached.data));
          } catch (e) {
            print('Error parsing dirty profile $key: $e');
          }
        }
      }
      
      return profiles;
    } catch (e) {
      print('Error getting dirty profiles: $e');
      return [];
    }
  }

  /// Mark profile as synced
  Future<void> markProfileSynced(String uid) async {
    try {
      final box = _hiveService.profiles;
      final cached = box.get(uid) as CachedData?;
      
      if (cached != null) {
        cached.markSynced();
      }
    } catch (e) {
      print('Error marking profile as synced: $e');
    }
  }

  /// Check if profile is cached
  bool isProfileCached(String uid) {
    try {
      final box = _hiveService.profiles;
      return box.containsKey(uid);
    } catch (e) {
      print('Error checking if profile is cached: $e');
      return false;
    }
  }

  /// Get cache statistics
  Map<String, int> getCacheStats() {
    try {
      final box = _hiveService.profiles;
      int total = box.length;
      int dirty = 0;
      int valid = 0;
      int invalid = 0;
      
      for (final key in box.keys) {
        final cached = box.get(key) as CachedData?;
        if (cached != null) {
          if (cached.isDirty) dirty++;
          if (cached.isValid()) {
            valid++;
          } else {
            invalid++;
          }
        }
      }
      
      return {
        'total': total,
        'dirty': dirty,
        'valid': valid,
        'invalid': invalid,
      };
    } catch (e) {
      print('Error getting cache stats: $e');
      return {
        'total': 0,
        'dirty': 0,
        'valid': 0,
        'invalid': 0,
      };
    }
  }

  /// Search cached profiles by name
  Future<List<UserModel>> searchCachedProfiles(String query) async {
    try {
      final allProfiles = await getAllCachedProfiles();
      final lowerQuery = query.toLowerCase();
      
      return allProfiles.where((profile) {
        return profile.displayName.toLowerCase().contains(lowerQuery) ||
               profile.email.toLowerCase().contains(lowerQuery) ||
               profile.bio.toLowerCase().contains(lowerQuery);
      }).toList();
    } catch (e) {
      print('Error searching cached profiles: $e');
      return [];
    }
  }

  /// Get cached guides
  Future<List<UserModel>> getCachedGuides() async {
    try {
      final allProfiles = await getAllCachedProfiles();
      return allProfiles.where((profile) => profile.isGuide).toList();
    } catch (e) {
      print('Error getting cached guides: $e');
      return [];
    }
  }

  /// Get cached verified profiles
  Future<List<UserModel>> getCachedVerifiedProfiles() async {
    try {
      final allProfiles = await getAllCachedProfiles();
      return allProfiles.where((profile) => profile.isVerified).toList();
    } catch (e) {
      print('Error getting cached verified profiles: $e');
      return [];
    }
  }

  /// Get cached profiles by interests
  Future<List<UserModel>> getCachedProfilesByInterest(String interest) async {
    try {
      final allProfiles = await getAllCachedProfiles();
      return allProfiles.where((profile) {
        return profile.interests.any((i) => 
          i.toLowerCase().contains(interest.toLowerCase()));
      }).toList();
    } catch (e) {
      print('Error getting cached profiles by interest: $e');
      return [];
    }
  }

  /// Clear all cached profiles
  Future<void> clearCache() async {
    try {
      final box = _hiveService.profiles;
      await box.clear();
    } catch (e) {
      print('Error clearing profile cache: $e');
    }
  }
}

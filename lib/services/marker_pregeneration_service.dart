import 'dart:async';
import 'package:flutter/material.dart';
// Google Maps replaced with Mapbox (50K map loads + 100K directions FREE)
import '../core/utils/logger.dart';
import '../core/utils/marker_generator.dart';
import '../core/constants/default_avatars.dart';

/// Service for pre-generating markers in the background
class MarkerPregenerationService {
  static const String _tag = 'MarkerPregeneration';

  static bool _isInitialized = false;
  static Timer? _pregenerationTimer;

  /// Initialize the pre-generation service
  static Future<void> initialize() async {
    if (_isInitialized) {
      AppLogger.debug(_tag, 'Service already initialized');
      return;
    }

    AppLogger.info(_tag, 'Initializing marker pre-generation service');

    // Pre-generate common markers immediately
    await _pregenerateCommonMarkers();

    // Schedule periodic pre-generation
    _startPeriodicPregeneration();

    _isInitialized = true;
    AppLogger.info(_tag, 'Marker pre-generation service initialized');
  }

  /// Pre-generate common markers that will likely be used
  static Future<void> _pregenerateCommonMarkers() async {
    AppLogger.debug(_tag, 'Pre-generating common markers');

    final List<Future<void>> futures = [];

    // Pre-generate current location marker
    futures.add(
      MarkerGenerator.createSimpleMarker(
        color: const Color(0xFF000000),
        emoji: '📍',
      ).catchError((e) {
        AppLogger.warning(_tag, 'Failed to pre-generate current location marker');
        return BitmapDescriptor.defaultMarker;
      }),
    );

    // Pre-generate all avatar markers (both current user and traveler versions)
    for (int i = 0; i < DefaultAvatars.count; i++) {
      final avatar = DefaultAvatars.getAvatarByIndex(i);
      final photoUrl = 'avatar:$avatar';

      // Pre-generate as current user marker
      futures.add(
        MarkerGenerator.createMarkerFromPhoto(
          photoUrl: photoUrl,
          isCurrentUser: true,
        ).catchError((e) {
          AppLogger.warning(_tag, 'Failed to pre-generate current user marker', {
            'avatar': avatar,
          });
          return BitmapDescriptor.defaultMarker;
        }),
      );

      // Pre-generate as traveler marker
      futures.add(
        MarkerGenerator.createMarkerFromPhoto(
          photoUrl: photoUrl,
          isCurrentUser: false,
        ).catchError((e) {
          AppLogger.warning(_tag, 'Failed to pre-generate traveler marker', {
            'avatar': avatar,
          });
          return BitmapDescriptor.defaultMarker;
        }),
      );
    }

    // Wait for all to complete
    await Future.wait(futures);

    final stats = MarkerGenerator.getCacheStats();
    AppLogger.info(_tag, 'Common markers pre-generated', stats);
  }

  /// Start periodic pre-generation to keep cache warm
  static void _startPeriodicPregeneration() {
    // Run every 5 minutes to keep cache warm
    _pregenerationTimer = Timer.periodic(
      const Duration(minutes: 5),
      (timer) async {
        AppLogger.debug(_tag, 'Running periodic marker pre-generation');
        await _pregenerateCommonMarkers();
      },
    );

    AppLogger.debug(_tag, 'Periodic pre-generation scheduled');
  }

  /// Dispose the service and cancel timers
  static void dispose() {
    AppLogger.info(_tag, 'Disposing marker pre-generation service');
    _pregenerationTimer?.cancel();
    _pregenerationTimer = null;
    _isInitialized = false;
  }

  /// Pre-generate markers for a specific list of travelers (on demand)
  static Future<void> pregenerateForTravelers(
    List<Map<String, dynamic>> travelers,
  ) async {
    if (travelers.isEmpty) return;

    AppLogger.debug(_tag, 'Pre-generating markers for ${travelers.length} travelers');

    final List<Future<void>> futures = [];

    for (var traveler in travelers) {
      final photoUrl = traveler['photoUrl'] as String?;

      futures.add(
        MarkerGenerator.createMarkerFromPhoto(
          photoUrl: photoUrl,
          isCurrentUser: false,
        ).catchError((e) {
          AppLogger.warning(_tag, 'Failed to pre-generate traveler marker');
          return BitmapDescriptor.defaultMarker;
        }),
      );
    }

    await Future.wait(futures);

    AppLogger.debug(_tag, 'Pre-generated ${travelers.length} traveler markers');
  }

  /// Get current cache statistics
  static Map<String, dynamic> getCacheStats() {
    return MarkerGenerator.getCacheStats();
  }
}

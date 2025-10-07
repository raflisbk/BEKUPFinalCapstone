import 'dart:math' as math;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'logger.dart';

/// Utility class for clustering markers based on zoom level
class MarkerCluster {
  static const String _tag = 'MarkerCluster';

  /// Cluster distance threshold in pixels (adjust based on zoom)
  static double getClusterDistance(double zoomLevel) {
    // Closer zoom = less clustering
    if (zoomLevel >= 15) return 40; // Minimal clustering at street level
    if (zoomLevel >= 12) return 60; // Some clustering at city level
    if (zoomLevel >= 10) return 80; // More clustering at region level
    return 100; // Maximum clustering at country level
  }

  /// Calculate distance between two LatLng points in meters
  static double calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // meters

    final lat1Rad = point1.latitude * math.pi / 180;
    final lat2Rad = point2.latitude * math.pi / 180;
    final deltaLat = (point2.latitude - point1.latitude) * math.pi / 180;
    final deltaLng = (point2.longitude - point1.longitude) * math.pi / 180;

    final a = math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1Rad) *
            math.cos(lat2Rad) *
            math.sin(deltaLng / 2) *
            math.sin(deltaLng / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  /// Cluster markers based on proximity and zoom level
  static List<MarkerClusterData> clusterMarkers({
    required List<Map<String, dynamic>> travelers,
    required double zoomLevel,
  }) {
    if (travelers.isEmpty) {
      AppLogger.debug(_tag, 'No travelers to cluster');
      return [];
    }

    AppLogger.debug(_tag, 'Starting marker clustering', {
      'travelersCount': travelers.length,
      'zoomLevel': zoomLevel.toStringAsFixed(1),
    });

    // No clustering at high zoom levels (street view)
    if (zoomLevel >= 15) {
      AppLogger.debug(_tag, 'Zoom level too high for clustering - returning individual markers');
      return travelers.map((t) => MarkerClusterData(
        position: LatLng(t['latitude'] as double, t['longitude'] as double),
        travelers: [t],
        isCluster: false,
      )).toList();
    }

    final List<MarkerClusterData> clusters = [];
    final List<Map<String, dynamic>> unclustered = List.from(travelers);
    final double clusterDistance = getClusterDistance(zoomLevel);

    // Convert cluster distance from pixels to meters (approximate)
    // At zoom 10, 100px ≈ 10km; at zoom 12, 100px ≈ 2.5km; at zoom 14, 100px ≈ 600m
    final double clusterDistanceMeters = clusterDistance * math.pow(2, 15 - zoomLevel) * 100;

    while (unclustered.isNotEmpty) {
      final current = unclustered.removeAt(0);
      final currentPos = LatLng(
        current['latitude'] as double,
        current['longitude'] as double,
      );

      final List<Map<String, dynamic>> clusterMembers = [current];

      // Find nearby travelers to cluster
      unclustered.removeWhere((traveler) {
        final travelerPos = LatLng(
          traveler['latitude'] as double,
          traveler['longitude'] as double,
        );

        final distance = calculateDistance(currentPos, travelerPos);

        if (distance <= clusterDistanceMeters) {
          clusterMembers.add(traveler);
          return true;
        }
        return false;
      });

      // Calculate cluster center (centroid)
      double avgLat = 0;
      double avgLng = 0;
      for (var member in clusterMembers) {
        avgLat += member['latitude'] as double;
        avgLng += member['longitude'] as double;
      }
      avgLat /= clusterMembers.length;
      avgLng /= clusterMembers.length;

      clusters.add(MarkerClusterData(
        position: LatLng(avgLat, avgLng),
        travelers: clusterMembers,
        isCluster: clusterMembers.length > 1,
      ));
    }

    AppLogger.info(_tag, 'Clustering completed', {
      'originalCount': travelers.length,
      'clusteredCount': clusters.length,
      'clusterDistanceMeters': clusterDistanceMeters.toStringAsFixed(0),
      'reduction': '${((1 - clusters.length / travelers.length) * 100).toStringAsFixed(1)}%',
    });

    return clusters;
  }

  /// Generate cluster marker icon with count
  static Future<BitmapDescriptor> createClusterMarker(int count) async {
    try {
      AppLogger.debug(_tag, 'Generating cluster marker', {'count': count});

      final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(pictureRecorder);

      const double size = 100.0;

      // Draw shadow
      final Paint shadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(const Offset(size / 2, size / 2), 38, shadowPaint);

      // Draw red circle for cluster
      final Paint circlePaint = Paint()
        ..color = Colors.red
        ..style = PaintingStyle.fill;
      canvas.drawCircle(const Offset(size / 2, size / 2), 35, circlePaint);

      // Draw white border
      final Paint borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawCircle(const Offset(size / 2, size / 2), 35, borderPaint);

      // Draw count text
      final textPainter = TextPainter(
        text: TextSpan(
          text: count.toString(),
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          (size - textPainter.width) / 2,
          (size - textPainter.height) / 2,
        ),
      );

      final ui.Image image = await pictureRecorder.endRecording().toImage(
        size.toInt(),
        size.toInt(),
      );

      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData == null) {
        AppLogger.warning(_tag, 'Failed to convert cluster marker to bytes');
        return BitmapDescriptor.defaultMarker;
      }

      AppLogger.debug(_tag, 'Cluster marker generated successfully');
      return BitmapDescriptor.bytes(byteData.buffer.asUint8List());
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to generate cluster marker', e, stackTrace);
      return BitmapDescriptor.defaultMarker;
    }
  }
}

/// Data class for cluster information
class MarkerClusterData {
  final LatLng position;
  final List<Map<String, dynamic>> travelers;
  final bool isCluster;

  MarkerClusterData({
    required this.position,
    required this.travelers,
    required this.isCluster,
  });

  int get count => travelers.length;
}

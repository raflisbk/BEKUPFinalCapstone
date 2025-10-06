import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../theme/app_colors.dart';
import '../utils/logger.dart';

/// Utility class to generate custom map markers with profile photos
class MarkerGenerator {
  static const String _tag = 'MarkerGenerator';

  /// Generate a marker with profile photo or avatar emoji
  static Future<BitmapDescriptor> createMarkerFromPhoto({
    required String? photoUrl,
    required bool isCurrentUser,
  }) async {
    try {
      AppLogger.debug(_tag, 'Generating marker for ${isCurrentUser ? "current user" : "traveler"}');

      final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(pictureRecorder);

      const double size = 120.0;
      const double imageSize = 80.0;
      const double borderWidth = 4.0;

      // Draw shadow layer
      final Paint shadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(
        const Offset(size / 2, size / 2),
        imageSize / 2 + borderWidth + 4,
        shadowPaint,
      );

      // Draw border circle
      final Paint borderPaint = Paint()
        ..color = isCurrentUser ? AppColors.black : Colors.red
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        const Offset(size / 2, size / 2),
        imageSize / 2 + borderWidth,
        borderPaint,
      );

      // Draw white background circle
      final Paint backgroundPaint = Paint()
        ..color = AppColors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        const Offset(size / 2, size / 2),
        imageSize / 2,
        backgroundPaint,
      );

      // Draw emoji avatar or person icon
      if (photoUrl != null && photoUrl.startsWith('avatar:')) {
        final String emoji = photoUrl.replaceFirst('avatar:', '');
        AppLogger.debug(_tag, 'Rendering emoji avatar in marker');

        final TextPainter textPainter = TextPainter(
          text: TextSpan(
            text: emoji,
            style: const TextStyle(fontSize: 48),
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
      } else {
        AppLogger.debug(_tag, 'Using default person icon in marker');

        final TextPainter iconPainter = TextPainter(
          text: const TextSpan(
            text: '👤',
            style: TextStyle(fontSize: 48),
          ),
          textDirection: TextDirection.ltr,
        );
        iconPainter.layout();
        iconPainter.paint(
          canvas,
          Offset(
            (size - iconPainter.width) / 2,
            (size - iconPainter.height) / 2,
          ),
        );
      }

      // Convert canvas to image
      final ui.Image image = await pictureRecorder.endRecording().toImage(
        size.toInt(),
        size.toInt(),
      );

      // Convert image to bytes
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData == null) {
        AppLogger.warning(_tag, 'Failed to convert marker image to bytes');
        return BitmapDescriptor.defaultMarker;
      }

      final Uint8List uint8List = byteData.buffer.asUint8List();
      AppLogger.debug(_tag, 'Marker generated successfully');

      return BitmapDescriptor.bytes(uint8List);
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to generate marker from photo', e, stackTrace);
      return BitmapDescriptor.defaultMarker;
    }
  }

  /// Generate simple colored marker with emoji
  static Future<BitmapDescriptor> createSimpleMarker({
    required Color color,
    required String emoji,
  }) async {
    try {
      AppLogger.debug(_tag, 'Generating simple marker with emoji');

      final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(pictureRecorder);

      const double size = 100.0;

      // Draw shadow
      final Paint shadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(const Offset(size / 2, size / 2), 38, shadowPaint);

      // Draw colored circle
      final Paint circlePaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(const Offset(size / 2, size / 2), 35, circlePaint);

      // Draw white border
      final Paint borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawCircle(const Offset(size / 2, size / 2), 35, borderPaint);

      // Draw emoji
      final TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: emoji,
          style: const TextStyle(fontSize: 40),
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
        AppLogger.warning(_tag, 'Failed to convert simple marker to bytes');
        return BitmapDescriptor.defaultMarker;
      }

      AppLogger.debug(_tag, 'Simple marker generated successfully');
      return BitmapDescriptor.bytes(byteData.buffer.asUint8List());
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to generate simple marker', e, stackTrace);
      return BitmapDescriptor.defaultMarker;
    }
  }
}

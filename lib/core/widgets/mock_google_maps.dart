import 'package:flutter/material.dart';

/// Placeholder widget for disabled Google Maps functionality
/// TODO: Replace with Mapbox implementation
class DisabledMapPlaceholder extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;

  const DisabledMapPlaceholder({
    super.key,
    this.title = 'Map Temporarily Unavailable',
    this.message = 'Map functionality has been temporarily disabled during migration to Mapbox. Please check back later.',
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.map_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }
}

/// Placeholder for Google Maps classes
class GoogleMapPlaceholder extends StatelessWidget {
  const GoogleMapPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const DisabledMapPlaceholder(
      title: 'Map Widget Disabled',
      message: 'GoogleMap widget has been disabled during Mapbox migration.',
    );
  }
}

/// Mock GoogleMap widget
class GoogleMap extends StatelessWidget {
  final dynamic onMapCreated;
  final dynamic initialCameraPosition;
  final dynamic markers;
  final dynamic polylines;
  final dynamic circles;
  final dynamic onCameraMove;
  final dynamic mapType;
  final dynamic myLocationEnabled;
  final dynamic myLocationButtonEnabled;
  final dynamic compassEnabled;
  final dynamic rotateGesturesEnabled;
  final dynamic tiltGesturesEnabled;
  final dynamic zoomControlsEnabled;
  final dynamic zoomGesturesEnabled;
  final dynamic scrollGesturesEnabled;
  final dynamic mapToolbarEnabled;
  final dynamic liteModeEnabled;
  final dynamic buildingsEnabled;
  final dynamic trafficEnabled;
  final dynamic onTap;

  const GoogleMap({
    super.key,
    this.onMapCreated,
    this.initialCameraPosition,
    this.markers,
    this.polylines,
    this.circles,
    this.onCameraMove,
    this.mapType,
    this.myLocationEnabled,
    this.myLocationButtonEnabled,
    this.compassEnabled,
    this.rotateGesturesEnabled,
    this.tiltGesturesEnabled,
    this.zoomControlsEnabled,
    this.zoomGesturesEnabled,
    this.scrollGesturesEnabled,
    this.mapToolbarEnabled,
    this.liteModeEnabled,
    this.buildingsEnabled,
    this.trafficEnabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return const GoogleMapPlaceholder();
  }
}

/// Mock GoogleMapController
class GoogleMapController {
  Future<void> animateCamera(dynamic cameraUpdate) async {}
  Future<void> setMapStyle(String? mapStyle) async {}
}

/// Mock LatLng
class LatLng {
  final double latitude;
  final double longitude;

  const LatLng(this.latitude, this.longitude);
}

/// Mock Marker
class Marker {
  final MarkerId markerId;
  final LatLng position;
  final dynamic infoWindow;
  final dynamic icon;
  final dynamic anchor;

  const Marker({
    required this.markerId,
    required this.position,
    this.infoWindow,
    this.icon,
    this.anchor,
  });
}

/// Mock MarkerId
class MarkerId {
  final String value;
  const MarkerId(this.value);
}

/// Mock InfoWindow
class InfoWindow {
  final String? title;
  final String? snippet;

  const InfoWindow({this.title, this.snippet});
}

/// Mock Polyline
class Polyline {
  final PolylineId polylineId;
  final List<LatLng> points;
  final dynamic color;
  final dynamic width;

  const Polyline({
    required this.polylineId,
    required this.points,
    this.color,
    this.width,
  });
}

/// Mock PolylineId
class PolylineId {
  final String value;
  const PolylineId(this.value);
}

/// Mock Circle
class Circle {
  final CircleId circleId;
  final LatLng center;
  final dynamic radius;

  const Circle({
    required this.circleId,
    required this.center,
    this.radius,
  });
}

/// Mock CircleId
class CircleId {
  final String value;
  const CircleId(this.value);
}

/// Mock CameraPosition
class CameraPosition {
  final LatLng target;
  final double zoom;
  final double bearing;
  final double tilt;

  const CameraPosition({
    required this.target,
    required this.zoom,
    this.bearing = 0.0,
    this.tilt = 0.0,
  });
}

/// Mock CameraUpdate
class CameraUpdate {
  static CameraUpdate newLatLngZoom(LatLng latLng, double zoom) {
    return CameraUpdate();
  }

  static CameraUpdate newCameraPosition(CameraPosition cameraPosition) {
    return CameraUpdate();
  }

  static CameraUpdate newLatLngBounds(LatLngBounds bounds, double padding) {
    return CameraUpdate();
  }
}

/// Mock MapType
enum MapType {
  normal,
  satellite,
  terrain,
  hybrid,
}

/// Mock BitmapDescriptor
class BitmapDescriptor {
  static const BitmapDescriptor defaultMarker = BitmapDescriptor._();
  static const double hueRed = 0.0;
  static const double hueBlue = 240.0;
  static const double hueGreen = 120.0;
  
  const BitmapDescriptor._();

  static BitmapDescriptor fromBytes(dynamic bytes) {
    return const BitmapDescriptor._();
  }

  static BitmapDescriptor bytes(dynamic bytes) {
    return const BitmapDescriptor._();
  }

  static BitmapDescriptor defaultMarkerWithHue(double hue) {
    return const BitmapDescriptor._();
  }
}

/// Mock LatLngBounds
class LatLngBounds {
  final LatLng southwest;
  final LatLng northeast;

  const LatLngBounds({
    required this.southwest,
    required this.northeast,
  });
}
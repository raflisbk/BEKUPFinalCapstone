import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a geographical location with coordinates
class RouteLocation {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String? placeId;
  final Map<String, dynamic>? additionalInfo;

  const RouteLocation({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.placeId,
    this.additionalInfo,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'placeId': placeId,
      'additionalInfo': additionalInfo,
    };
  }

  factory RouteLocation.fromMap(Map<String, dynamic> map) {
    return RouteLocation(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      latitude: map['latitude']?.toDouble() ?? 0.0,
      longitude: map['longitude']?.toDouble() ?? 0.0,
      placeId: map['placeId'],
      additionalInfo: map['additionalInfo'],
    );
  }

  factory RouteLocation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return RouteLocation.fromMap({...data, 'id': doc.id});
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RouteLocation &&
        other.id == id &&
        other.latitude == latitude &&
        other.longitude == longitude;
  }

  @override
  int get hashCode => Object.hash(id, latitude, longitude);

  @override
  String toString() {
    return 'RouteLocation(id: $id, name: $name, lat: $latitude, lng: $longitude)';
  }
}

/// Represents a step in navigation directions
class RouteStep {
  final String instruction;
  final String distance;
  final String duration;
  final RouteLocation startLocation;
  final RouteLocation endLocation;
  final String? maneuver;
  final List<RouteLocation> polylinePoints;

  const RouteStep({
    required this.instruction,
    required this.distance,
    required this.duration,
    required this.startLocation,
    required this.endLocation,
    this.maneuver,
    required this.polylinePoints,
  });

  Map<String, dynamic> toMap() {
    return {
      'instruction': instruction,
      'distance': distance,
      'duration': duration,
      'startLocation': startLocation.toMap(),
      'endLocation': endLocation.toMap(),
      'maneuver': maneuver,
      'polylinePoints': polylinePoints.map((point) => point.toMap()).toList(),
    };
  }

  factory RouteStep.fromMap(Map<String, dynamic> map) {
    return RouteStep(
      instruction: map['instruction'] ?? '',
      distance: map['distance'] ?? '',
      duration: map['duration'] ?? '',
      startLocation: RouteLocation.fromMap(map['startLocation'] ?? {}),
      endLocation: RouteLocation.fromMap(map['endLocation'] ?? {}),
      maneuver: map['maneuver'],
      polylinePoints: (map['polylinePoints'] as List<dynamic>?)
              ?.map((point) => RouteLocation.fromMap(point))
              .toList() ??
          [],
    );
  }
}

/// Travel mode enumeration
enum TravelMode {
  driving('driving'),
  walking('walking'),
  bicycling('bicycling'),
  transit('transit');

  const TravelMode(this.value);
  final String value;

  static TravelMode fromString(String value) {
    return TravelMode.values.firstWhere(
      (mode) => mode.value == value,
      orElse: () => TravelMode.driving,
    );
  }
}

/// Route optimization preference
enum RouteOptimization {
  fastest('fastest'),
  shortest('shortest'),
  economic('economic'),
  scenic('scenic'),
  avoidTolls('avoid_tolls'),
  avoidHighways('avoid_highways');

  const RouteOptimization(this.value);
  final String value;

  static RouteOptimization fromString(String value) {
    return RouteOptimization.values.firstWhere(
      (opt) => opt.value == value,
      orElse: () => RouteOptimization.fastest,
    );
  }
}

/// AI suggestion for route optimization
class AIRouteSuggestion {
  final String suggestionId;
  final String title;
  final String description;
  final String reasoning;
  final int priorityScore; // 1-10
  final RouteOptimization optimizationType;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  const AIRouteSuggestion({
    required this.suggestionId,
    required this.title,
    required this.description,
    required this.reasoning,
    required this.priorityScore,
    required this.optimizationType,
    required this.metadata,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'suggestionId': suggestionId,
      'title': title,
      'description': description,
      'reasoning': reasoning,
      'priorityScore': priorityScore,
      'optimizationType': optimizationType.value,
      'metadata': metadata,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory AIRouteSuggestion.fromMap(Map<String, dynamic> map) {
    return AIRouteSuggestion(
      suggestionId: map['suggestionId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      reasoning: map['reasoning'] ?? '',
      priorityScore: map['priorityScore']?.toInt() ?? 5,
      optimizationType: RouteOptimization.fromString(map['optimizationType'] ?? 'fastest'),
      metadata: map['metadata'] ?? {},
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory AIRouteSuggestion.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AIRouteSuggestion.fromMap({...data, 'suggestionId': doc.id});
  }
}

/// Complete route plan with AI optimizations
class RoutePlan {
  final String id;
  final String userId;
  final String tripId;
  final String name;
  final RouteLocation origin;
  final RouteLocation destination;
  final List<RouteLocation> waypoints;
  final TravelMode travelMode;
  final RouteOptimization optimization;
  final List<RouteStep> steps;
  final String totalDistance;
  final String totalDuration;
  final double estimatedCost;
  final List<AIRouteSuggestion> aiSuggestions;
  final Map<String, dynamic> routeMetadata;
  final DateTime createdAt;
  final DateTime? lastModified;
  final bool isActive;

  const RoutePlan({
    required this.id,
    required this.userId,
    required this.tripId,
    required this.name,
    required this.origin,
    required this.destination,
    required this.waypoints,
    required this.travelMode,
    required this.optimization,
    required this.steps,
    required this.totalDistance,
    required this.totalDuration,
    required this.estimatedCost,
    required this.aiSuggestions,
    required this.routeMetadata,
    required this.createdAt,
    this.lastModified,
    required this.isActive,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'tripId': tripId,
      'name': name,
      'origin': origin.toMap(),
      'destination': destination.toMap(),
      'waypoints': waypoints.map((wp) => wp.toMap()).toList(),
      'travelMode': travelMode.value,
      'optimization': optimization.value,
      'steps': steps.map((step) => step.toMap()).toList(),
      'totalDistance': totalDistance,
      'totalDuration': totalDuration,
      'estimatedCost': estimatedCost,
      'aiSuggestions': aiSuggestions.map((suggestion) => suggestion.toMap()).toList(),
      'routeMetadata': routeMetadata,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastModified': lastModified != null ? Timestamp.fromDate(lastModified!) : null,
      'isActive': isActive,
    };
  }

  factory RoutePlan.fromMap(Map<String, dynamic> map) {
    return RoutePlan(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      tripId: map['tripId'] ?? '',
      name: map['name'] ?? '',
      origin: RouteLocation.fromMap(map['origin'] ?? {}),
      destination: RouteLocation.fromMap(map['destination'] ?? {}),
      waypoints: (map['waypoints'] as List<dynamic>?)
              ?.map((wp) => RouteLocation.fromMap(wp))
              .toList() ??
          [],
      travelMode: TravelMode.fromString(map['travelMode'] ?? 'driving'),
      optimization: RouteOptimization.fromString(map['optimization'] ?? 'fastest'),
      steps: (map['steps'] as List<dynamic>?)
              ?.map((step) => RouteStep.fromMap(step))
              .toList() ??
          [],
      totalDistance: map['totalDistance'] ?? '0 km',
      totalDuration: map['totalDuration'] ?? '0 min',
      estimatedCost: map['estimatedCost']?.toDouble() ?? 0.0,
      aiSuggestions: (map['aiSuggestions'] as List<dynamic>?)
              ?.map((suggestion) => AIRouteSuggestion.fromMap(suggestion))
              .toList() ??
          [],
      routeMetadata: map['routeMetadata'] ?? {},
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastModified: (map['lastModified'] as Timestamp?)?.toDate(),
      isActive: map['isActive'] ?? false,
    );
  }

  factory RoutePlan.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return RoutePlan.fromMap({...data, 'id': doc.id});
  }

  RoutePlan copyWith({
    String? name,
    List<RouteLocation>? waypoints,
    TravelMode? travelMode,
    RouteOptimization? optimization,
    List<RouteStep>? steps,
    String? totalDistance,
    String? totalDuration,
    double? estimatedCost,
    List<AIRouteSuggestion>? aiSuggestions,
    Map<String, dynamic>? routeMetadata,
    DateTime? lastModified,
    bool? isActive,
  }) {
    return RoutePlan(
      id: id,
      userId: userId,
      tripId: tripId,
      name: name ?? this.name,
      origin: origin,
      destination: destination,
      waypoints: waypoints ?? this.waypoints,
      travelMode: travelMode ?? this.travelMode,
      optimization: optimization ?? this.optimization,
      steps: steps ?? this.steps,
      totalDistance: totalDistance ?? this.totalDistance,
      totalDuration: totalDuration ?? this.totalDuration,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      aiSuggestions: aiSuggestions ?? this.aiSuggestions,
      routeMetadata: routeMetadata ?? this.routeMetadata,
      createdAt: createdAt,
      lastModified: lastModified ?? this.lastModified,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RoutePlan && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'RoutePlan(id: $id, name: $name, from: ${origin.name}, to: ${destination.name})';
  }
}
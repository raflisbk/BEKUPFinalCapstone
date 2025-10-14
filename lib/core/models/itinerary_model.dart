import '../stubs/firebase_stubs.dart';

/// Main itinerary model for new architecture
class Itinerary {
  final String id;
  final String name;
  final String? description;
  final DateTime startDate;
  final DateTime endDate;
  final String? tripId;
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPublic;
  final List<String> tags;
  final Map<String, dynamic>? metadata;

  Itinerary({
    required this.id,
    required this.name,
    this.description,
    required this.startDate,
    required this.endDate,
    this.tripId,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    this.isPublic = false,
    this.tags = const [],
    this.metadata,
  });

  /// Create from Map
  factory Itinerary.fromMap(Map<String, dynamic> map) {
    return Itinerary(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'],
      startDate: DateTime.parse(map['start_date'] ?? DateTime.now().toIso8601String()),
      endDate: DateTime.parse(map['end_date'] ?? DateTime.now().toIso8601String()),
      tripId: map['trip_id'],
      userId: map['user_id'] ?? '',
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updated_at'] ?? DateTime.now().toIso8601String()),
      isPublic: map['is_public'] ?? false,
      tags: List<String>.from(map['tags'] ?? []),
      metadata: map['metadata'],
    );
  }

  /// Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'trip_id': tripId,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_public': isPublic,
      'tags': tags,
      'metadata': metadata,
    };
  }

  /// Copy with modifications
  Itinerary copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    String? tripId,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPublic,
    List<String>? tags,
    Map<String, dynamic>? metadata,
  }) {
    return Itinerary(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      tripId: tripId ?? this.tripId,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPublic: isPublic ?? this.isPublic,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Itinerary item model for new architecture
class ItineraryItem {
  final String id;
  final String itineraryId;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime? endTime;
  final String? location;
  final double? latitude;
  final double? longitude;
  final String type; // 'attraction', 'food', 'transport', etc.
  final double? estimatedCost;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  ItineraryItem({
    required this.id,
    required this.itineraryId,
    required this.title,
    this.description,
    required this.startTime,
    this.endTime,
    this.location,
    this.latitude,
    this.longitude,
    required this.type,
    this.estimatedCost,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from Map
  factory ItineraryItem.fromMap(Map<String, dynamic> map) {
    return ItineraryItem(
      id: map['id'] ?? '',
      itineraryId: map['itinerary_id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'],
      startTime: DateTime.parse(map['start_time'] ?? DateTime.now().toIso8601String()),
      endTime: map['end_time'] != null ? DateTime.parse(map['end_time']) : null,
      location: map['location'],
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      type: map['type'] ?? 'other',
      estimatedCost: map['estimated_cost']?.toDouble(),
      metadata: map['metadata'],
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  /// Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'itinerary_id': itineraryId,
      'title': title,
      'description': description,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'type': type,
      'estimated_cost': estimatedCost,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Copy with modifications
  ItineraryItem copyWith({
    String? id,
    String? itineraryId,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    String? location,
    double? latitude,
    double? longitude,
    String? type,
    double? estimatedCost,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ItineraryItem(
      id: id ?? this.id,
      itineraryId: itineraryId ?? this.itineraryId,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      type: type ?? this.type,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Trip itinerary model for daily plans
class TripItinerary {
  final String id;
  final String tripId;
  final String userId;
  final List<ItineraryDay> days;
  final DateTime createdAt;
  final DateTime updatedAt;

  TripItinerary({
    required this.id,
    required this.tripId,
    required this.userId,
    required this.days,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from Firestore document
  factory TripItinerary.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return TripItinerary(
      id: doc.id,
      tripId: data['tripId'] ?? '',
      userId: data['userId'] ?? '',
      days: (data['days'] as List<dynamic>?)
              ?.map((d) => ItineraryDay.fromMap(d as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'tripId': tripId,
      'userId': userId,
      'days': days.map((d) => d.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Get day by date
  ItineraryDay? getDayByDate(DateTime date) {
    return days.firstWhere(
      (day) => _isSameDay(day.date, date),
      orElse: () => ItineraryDay(
        date: date,
        activities: [],
        notes: '',
      ),
    );
  }

  /// Get total activity count
  int get totalActivities => days.fold(0, (total, day) => total + day.activities.length);

  /// Check if date is same
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// Copy with updated fields
  TripItinerary copyWith({
    List<ItineraryDay>? days,
    DateTime? updatedAt,
  }) {
    return TripItinerary(
      id: id,
      tripId: tripId,
      userId: userId,
      days: days ?? this.days,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Single day in itinerary
class ItineraryDay {
  final DateTime date;
  final List<ItineraryActivity> activities;
  final String notes;

  ItineraryDay({
    required this.date,
    required this.activities,
    required this.notes,
  });

  /// Create from map
  factory ItineraryDay.fromMap(Map<String, dynamic> map) {
    return ItineraryDay(
      date: (map['date'] as Timestamp).toDate(),
      activities: (map['activities'] as List<dynamic>?)
              ?.map((a) => ItineraryActivity.fromMap(a as Map<String, dynamic>))
              .toList() ??
          [],
      notes: map['notes'] ?? '',
    );
  }

  /// Convert to map
  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'activities': activities.map((a) => a.toMap()).toList(),
      'notes': notes,
    };
  }

  /// Copy with updated fields
  ItineraryDay copyWith({
    DateTime? date,
    List<ItineraryActivity>? activities,
    String? notes,
  }) {
    return ItineraryDay(
      date: date ?? this.date,
      activities: activities ?? this.activities,
      notes: notes ?? this.notes,
    );
  }
}

/// Single activity in a day
class ItineraryActivity {
  final String id;
  final String title;
  final String? description;
  final ActivityType type;
  final String? location;
  final double? locationLat;
  final double? locationLng;
  final String? startTime; // Format: "HH:mm"
  final String? endTime; // Format: "HH:mm"
  final double? estimatedCost;
  final String? bookingUrl;
  final bool isCompleted;

  ItineraryActivity({
    required this.id,
    required this.title,
    this.description,
    required this.type,
    this.location,
    this.locationLat,
    this.locationLng,
    this.startTime,
    this.endTime,
    this.estimatedCost,
    this.bookingUrl,
    this.isCompleted = false,
  });

  /// Create from map
  factory ItineraryActivity.fromMap(Map<String, dynamic> map) {
    return ItineraryActivity(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'],
      type: ActivityType.values.firstWhere(
        (e) => e.toString() == 'ActivityType.${map['type']}',
        orElse: () => ActivityType.other,
      ),
      location: map['location'],
      locationLat: map['locationLat']?.toDouble(),
      locationLng: map['locationLng']?.toDouble(),
      startTime: map['startTime'],
      endTime: map['endTime'],
      estimatedCost: map['estimatedCost']?.toDouble(),
      bookingUrl: map['bookingUrl'],
      isCompleted: map['isCompleted'] ?? false,
    );
  }

  /// Convert to map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.toString().split('.').last,
      'location': location,
      'locationLat': locationLat,
      'locationLng': locationLng,
      'startTime': startTime,
      'endTime': endTime,
      'estimatedCost': estimatedCost,
      'bookingUrl': bookingUrl,
      'isCompleted': isCompleted,
    };
  }

  /// Copy with updated fields
  ItineraryActivity copyWith({
    String? title,
    String? description,
    ActivityType? type,
    String? location,
    double? locationLat,
    double? locationLng,
    String? startTime,
    String? endTime,
    double? estimatedCost,
    String? bookingUrl,
    bool? isCompleted,
  }) {
    return ItineraryActivity(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      location: location ?? this.location,
      locationLat: locationLat ?? this.locationLat,
      locationLng: locationLng ?? this.locationLng,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      bookingUrl: bookingUrl ?? this.bookingUrl,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  /// Get icon for activity type
  String get icon {
    switch (type) {
      case ActivityType.attraction:
        return '🏛️';
      case ActivityType.food:
        return '🍽️';
      case ActivityType.accommodation:
        return '🏨';
      case ActivityType.transportation:
        return '🚗';
      case ActivityType.shopping:
        return '🛍️';
      case ActivityType.entertainment:
        return '🎭';
      case ActivityType.nature:
        return '🏞️';
      case ActivityType.other:
        return '📍';
    }
  }
}

/// Activity type enum
enum ActivityType {
  attraction,
  food,
  accommodation,
  transportation,
  shopping,
  entertainment,
  nature,
  other,
}

/// Extension for activity type display
extension ActivityTypeExtension on ActivityType {
  String get displayName {
    switch (this) {
      case ActivityType.attraction:
        return 'Attraction';
      case ActivityType.food:
        return 'Food & Dining';
      case ActivityType.accommodation:
        return 'Accommodation';
      case ActivityType.transportation:
        return 'Transportation';
      case ActivityType.shopping:
        return 'Shopping';
      case ActivityType.entertainment:
        return 'Entertainment';
      case ActivityType.nature:
        return 'Nature & Outdoors';
      case ActivityType.other:
        return 'Other';
    }
  }
}

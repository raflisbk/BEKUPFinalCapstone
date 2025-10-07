import 'package:cloud_firestore/cloud_firestore.dart';

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
  int get totalActivities => days.fold(0, (sum, day) => sum + day.activities.length);

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

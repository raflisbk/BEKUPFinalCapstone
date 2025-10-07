import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Trip model for planning itineraries
class Trip {
  final String id;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final String title;
  final String description;
  final String? coverImageUrl;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> destinationIds;
  final List<TripDestination> destinations;
  final List<String> participantIds;
  final Map<String, ParticipantInfo> participants;
  final TripStatus status;
  final bool isPublic;
  final DateTime createdAt;
  final DateTime updatedAt;

  Trip({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.title,
    required this.description,
    this.coverImageUrl,
    required this.startDate,
    required this.endDate,
    this.destinationIds = const [],
    this.destinations = const [],
    this.participantIds = const [],
    this.participants = const {},
    this.status = TripStatus.planning,
    this.isPublic = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from Firestore document
  factory Trip.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Trip(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userPhotoUrl: data['userPhotoUrl'],
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      coverImageUrl: data['coverImageUrl'],
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      destinationIds: List<String>.from(data['destinationIds'] ?? []),
      destinations: (data['destinations'] as List<dynamic>?)
              ?.map((d) => TripDestination.fromMap(d as Map<String, dynamic>))
              .toList() ??
          [],
      participantIds: List<String>.from(data['participantIds'] ?? []),
      participants: (data['participants'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(
              key,
              ParticipantInfo.fromMap(value as Map<String, dynamic>),
            ),
          ) ??
          {},
      status: TripStatus.values.firstWhere(
        (e) => e.toString() == 'TripStatus.${data['status']}',
        orElse: () => TripStatus.planning,
      ),
      isPublic: data['isPublic'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'title': title,
      'description': description,
      'coverImageUrl': coverImageUrl,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'destinationIds': destinationIds,
      'destinations': destinations.map((d) => d.toMap()).toList(),
      'participantIds': participantIds,
      'participants': participants.map((key, value) => MapEntry(key, value.toMap())),
      'status': status.toString().split('.').last,
      'isPublic': isPublic,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Get trip duration in days
  int get durationInDays {
    return endDate.difference(startDate).inDays + 1;
  }

  /// Check if trip is in the past
  bool get isPast {
    return endDate.isBefore(DateTime.now());
  }

  /// Check if trip is ongoing
  bool get isOngoing {
    final now = DateTime.now();
    return startDate.isBefore(now) && endDate.isAfter(now);
  }

  /// Check if trip is upcoming
  bool get isUpcoming {
    return startDate.isAfter(DateTime.now());
  }
}

/// Trip destination with scheduling
class TripDestination {
  final String id;
  final String name;
  final String? imageUrl;
  final DateTime? scheduledDate;
  final String? notes;
  final int order;

  TripDestination({
    required this.id,
    required this.name,
    this.imageUrl,
    this.scheduledDate,
    this.notes,
    this.order = 0,
  });

  factory TripDestination.fromMap(Map<String, dynamic> map) {
    return TripDestination(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      imageUrl: map['imageUrl'],
      scheduledDate: map['scheduledDate'] != null
          ? (map['scheduledDate'] as Timestamp).toDate()
          : null,
      notes: map['notes'],
      order: map['order'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'scheduledDate':
          scheduledDate != null ? Timestamp.fromDate(scheduledDate!) : null,
      'notes': notes,
      'order': order,
    };
  }
}

/// Participant information
class ParticipantInfo {
  final String name;
  final String? photoUrl;
  final DateTime joinedAt;

  ParticipantInfo({
    required this.name,
    this.photoUrl,
    required this.joinedAt,
  });

  factory ParticipantInfo.fromMap(Map<String, dynamic> map) {
    return ParticipantInfo(
      name: map['name'] ?? '',
      photoUrl: map['photoUrl'],
      joinedAt: (map['joinedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'photoUrl': photoUrl,
      'joinedAt': Timestamp.fromDate(joinedAt),
    };
  }
}

/// Trip status enum
enum TripStatus {
  planning,
  confirmed,
  ongoing,
  completed,
  cancelled,
}

/// Trip status helper
class TripStatusHelper {
  static String getLabel(TripStatus status) {
    switch (status) {
      case TripStatus.planning:
        return 'Planning';
      case TripStatus.confirmed:
        return 'Confirmed';
      case TripStatus.ongoing:
        return 'Ongoing';
      case TripStatus.completed:
        return 'Completed';
      case TripStatus.cancelled:
        return 'Cancelled';
    }
  }

  static Color getColor(TripStatus status) {
    switch (status) {
      case TripStatus.planning:
        return const Color(0xFF757575); // Gray
      case TripStatus.confirmed:
        return const Color(0xFF2196F3); // Blue
      case TripStatus.ongoing:
        return const Color(0xFF4CAF50); // Green
      case TripStatus.completed:
        return const Color(0xFF9E9E9E); // Light Gray
      case TripStatus.cancelled:
        return const Color(0xFFF44336); // Red
    }
  }
}

/// Trip filter options
enum TripFilter {
  all,
  upcoming,
  ongoing,
  past,
  myTrips,
  joined,
}

class TripFilterHelper {
  static String getLabel(TripFilter filter) {
    switch (filter) {
      case TripFilter.all:
        return 'All Trips';
      case TripFilter.upcoming:
        return 'Upcoming';
      case TripFilter.ongoing:
        return 'Ongoing';
      case TripFilter.past:
        return 'Past';
      case TripFilter.myTrips:
        return 'My Trips';
      case TripFilter.joined:
        return 'Joined';
    }
  }
}

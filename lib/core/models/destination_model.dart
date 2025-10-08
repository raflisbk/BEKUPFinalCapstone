import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Destination model for tourism destinations
class Destination {
  final String id;
  final String name;
  final String description;
  final String location;
  final double latitude;
  final double longitude;
  final String category;
  final List<String> images;
  final double priceRange; // 1-5 scale (1=cheap, 5=expensive)
  final double rating;
  final int reviewCount;
  final List<String> facilities;
  final List<String> activities;
  final String openingHours;
  final String bestTimeToVisit;
  final bool isVerified;
  final String createdBy; // userId
  final DateTime createdAt;
  final DateTime updatedAt;

  Destination({
    required this.id,
    required this.name,
    required this.description,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.category,
    required this.images,
    required this.priceRange,
    required this.rating,
    required this.reviewCount,
    required this.facilities,
    required this.activities,
    required this.openingHours,
    required this.bestTimeToVisit,
    required this.isVerified,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Destination.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Destination(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      location: data['location'] ?? '',
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      category: data['category'] ?? '',
      images: List<String>.from(data['images'] ?? []),
      priceRange: (data['priceRange'] ?? 1.0).toDouble(),
      rating: (data['rating'] ?? 0.0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      facilities: List<String>.from(data['facilities'] ?? []),
      activities: List<String>.from(data['activities'] ?? []),
      openingHours: data['openingHours'] ?? '',
      bestTimeToVisit: data['bestTimeToVisit'] ?? '',
      isVerified: data['isVerified'] ?? false,
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'category': category,
      'images': images,
      'priceRange': priceRange,
      'rating': rating,
      'reviewCount': reviewCount,
      'facilities': facilities,
      'activities': activities,
      'openingHours': openingHours,
      'bestTimeToVisit': bestTimeToVisit,
      'isVerified': isVerified,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create from Map (for offline cache)
  factory Destination.fromMap(Map<String, dynamic> map) {
    return Destination(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      location: map['location'] ?? '',
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      category: map['category'] ?? '',
      images: List<String>.from(map['images'] ?? []),
      priceRange: (map['priceRange'] ?? 1.0).toDouble(),
      rating: (map['rating'] ?? 0.0).toDouble(),
      reviewCount: map['reviewCount'] ?? 0,
      facilities: List<String>.from(map['facilities'] ?? []),
      activities: List<String>.from(map['activities'] ?? []),
      openingHours: map['openingHours'] ?? '',
      bestTimeToVisit: map['bestTimeToVisit'] ?? '',
      isVerified: map['isVerified'] ?? false,
      createdBy: map['createdBy'] ?? '',
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  /// Convert to Map (for offline cache)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'category': category,
      'images': images,
      'priceRange': priceRange,
      'rating': rating,
      'reviewCount': reviewCount,
      'facilities': facilities,
      'activities': activities,
      'openingHours': openingHours,
      'bestTimeToVisit': bestTimeToVisit,
      'isVerified': isVerified,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Destination copyWith({
    String? id,
    String? name,
    String? description,
    String? location,
    double? latitude,
    double? longitude,
    String? category,
    List<String>? images,
    double? priceRange,
    double? rating,
    int? reviewCount,
    List<String>? facilities,
    List<String>? activities,
    String? openingHours,
    String? bestTimeToVisit,
    bool? isVerified,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Destination(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      category: category ?? this.category,
      images: images ?? this.images,
      priceRange: priceRange ?? this.priceRange,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      facilities: facilities ?? this.facilities,
      activities: activities ?? this.activities,
      openingHours: openingHours ?? this.openingHours,
      bestTimeToVisit: bestTimeToVisit ?? this.bestTimeToVisit,
      isVerified: isVerified ?? this.isVerified,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get priceRangeText {
    if (priceRange <= 1.5) return 'Budget';
    if (priceRange <= 2.5) return 'Affordable';
    if (priceRange <= 3.5) return 'Moderate';
    if (priceRange <= 4.5) return 'Expensive';
    return 'Luxury';
  }

  String get priceRangeSymbol {
    final count = priceRange.round();
    return '\$' * count;
  }
}

/// Destination category enum
enum DestinationCategory {
  beach,
  mountain,
  cultural,
  culinary,
  adventure,
  nature,
  historical,
  religious,
  modern,
  other;

  String get displayName {
    switch (this) {
      case DestinationCategory.beach:
        return 'Beach';
      case DestinationCategory.mountain:
        return 'Mountain';
      case DestinationCategory.cultural:
        return 'Cultural';
      case DestinationCategory.culinary:
        return 'Culinary';
      case DestinationCategory.adventure:
        return 'Adventure';
      case DestinationCategory.nature:
        return 'Nature';
      case DestinationCategory.historical:
        return 'Historical';
      case DestinationCategory.religious:
        return 'Religious';
      case DestinationCategory.modern:
        return 'Modern';
      case DestinationCategory.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case DestinationCategory.beach:
        return Icons.beach_access;
      case DestinationCategory.mountain:
        return Icons.terrain;
      case DestinationCategory.cultural:
        return Icons.museum;
      case DestinationCategory.culinary:
        return Icons.restaurant;
      case DestinationCategory.adventure:
        return Icons.hiking;
      case DestinationCategory.nature:
        return Icons.park;
      case DestinationCategory.historical:
        return Icons.castle;
      case DestinationCategory.religious:
        return Icons.temple_buddhist;
      case DestinationCategory.modern:
        return Icons.location_city;
      case DestinationCategory.other:
        return Icons.place;
    }
  }

  static DestinationCategory fromString(String value) {
    return DestinationCategory.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => DestinationCategory.other,
    );
  }
}

/// Destination filter options
class DestinationFilter {
  final String? category;
  final double? minRating;
  final double? maxPriceRange;
  final String? searchQuery;
  final DestinationSort sortBy;

  DestinationFilter({
    this.category,
    this.minRating,
    this.maxPriceRange,
    this.searchQuery,
    this.sortBy = DestinationSort.rating,
  });

  DestinationFilter copyWith({
    String? category,
    double? minRating,
    double? maxPriceRange,
    String? searchQuery,
    DestinationSort? sortBy,
  }) {
    return DestinationFilter(
      category: category ?? this.category,
      minRating: minRating ?? this.minRating,
      maxPriceRange: maxPriceRange ?? this.maxPriceRange,
      searchQuery: searchQuery ?? this.searchQuery,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  bool get hasActiveFilters {
    return category != null ||
        minRating != null ||
        maxPriceRange != null ||
        (searchQuery != null && searchQuery!.isNotEmpty);
  }
}

/// Destination sort options
enum DestinationSort {
  rating,
  newest,
  name,
  priceRange;

  String get displayName {
    switch (this) {
      case DestinationSort.rating:
        return 'Highest Rating';
      case DestinationSort.newest:
        return 'Newest';
      case DestinationSort.name:
        return 'Name (A-Z)';
      case DestinationSort.priceRange:
        return 'Price Range';
    }
  }
}

/// User bookmark model
class UserBookmark {
  final String userId;
  final List<String> destinationIds;
  final DateTime updatedAt;

  UserBookmark({
    required this.userId,
    required this.destinationIds,
    required this.updatedAt,
  });

  factory UserBookmark.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return UserBookmark(
      userId: doc.id,
      destinationIds: List<String>.from(data['destinationIds'] ?? []),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'destinationIds': destinationIds,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  bool isBookmarked(String destinationId) {
    return destinationIds.contains(destinationId);
  }
}

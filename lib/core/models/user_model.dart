import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String bio;
  final List<String> interests;
  final List<String> languages;
  final bool isGuide;
  final bool isVerified;
  final double rating;
  final int reviewCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Guide-specific fields
  final String? expertise;
  final double? pricePerDay;
  final List<String>? specializations;
  final int? yearsOfExperience;
  final int? toursCompleted;

  // Location fields
  final double? latitude;
  final double? longitude;
  final String? currentLocation;
  final bool? isLocationShared;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.bio,
    required this.interests,
    required this.languages,
    required this.isGuide,
    required this.isVerified,
    required this.rating,
    required this.reviewCount,
    required this.createdAt,
    required this.updatedAt,
    this.expertise,
    this.pricePerDay,
    this.specializations,
    this.yearsOfExperience,
    this.toursCompleted,
    this.latitude,
    this.longitude,
    this.currentLocation,
    this.isLocationShared,
  });

  // Create from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? 'User',
      photoUrl: data['photoUrl'],
      bio: data['bio'] ?? '',
      interests: List<String>.from(data['interests'] ?? []),
      languages: List<String>.from(data['languages'] ?? ['English']),
      isGuide: data['isGuide'] ?? false,
      isVerified: data['isVerified'] ?? false,
      rating: (data['rating'] ?? 0.0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expertise: data['expertise'],
      pricePerDay: data['pricePerDay']?.toDouble(),
      specializations: data['specializations'] != null
          ? List<String>.from(data['specializations'])
          : null,
      yearsOfExperience: data['yearsOfExperience'],
      toursCompleted: data['toursCompleted'],
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
      currentLocation: data['currentLocation'],
      isLocationShared: data['isLocationShared'] ?? false,
    );
  }

  // Create from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'],
      email: json['email'] ?? '',
      displayName: json['displayName'] ?? 'User',
      photoUrl: json['photoUrl'],
      bio: json['bio'] ?? '',
      interests: List<String>.from(json['interests'] ?? []),
      languages: List<String>.from(json['languages'] ?? ['English']),
      isGuide: json['isGuide'] ?? false,
      isVerified: json['isVerified'] ?? false,
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      expertise: json['expertise'],
      pricePerDay: json['pricePerDay']?.toDouble(),
      specializations: json['specializations'] != null
          ? List<String>.from(json['specializations'])
          : null,
      yearsOfExperience: json['yearsOfExperience'],
      toursCompleted: json['toursCompleted'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      currentLocation: json['currentLocation'],
      isLocationShared: json['isLocationShared'] ?? false,
    );
  }

  // Create from Map (for offline cache) - alias for fromJson
  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel.fromJson(map);

  // Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'bio': bio,
      'interests': interests,
      'languages': languages,
      'isGuide': isGuide,
      'isVerified': isVerified,
      'rating': rating,
      'reviewCount': reviewCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      if (expertise != null) 'expertise': expertise,
      if (pricePerDay != null) 'pricePerDay': pricePerDay,
      if (specializations != null) 'specializations': specializations,
      if (yearsOfExperience != null) 'yearsOfExperience': yearsOfExperience,
      if (toursCompleted != null) 'toursCompleted': toursCompleted,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (currentLocation != null) 'currentLocation': currentLocation,
      'isLocationShared': isLocationShared ?? false,
    };
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'bio': bio,
      'interests': interests,
      'languages': languages,
      'isGuide': isGuide,
      'isVerified': isVerified,
      'rating': rating,
      'reviewCount': reviewCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (expertise != null) 'expertise': expertise,
      if (pricePerDay != null) 'pricePerDay': pricePerDay,
      if (specializations != null) 'specializations': specializations,
      if (yearsOfExperience != null) 'yearsOfExperience': yearsOfExperience,
      if (toursCompleted != null) 'toursCompleted': toursCompleted,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (currentLocation != null) 'currentLocation': currentLocation,
      'isLocationShared': isLocationShared ?? false,
    };
  }

  // Copy with method
  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    String? bio,
    List<String>? interests,
    List<String>? languages,
    bool? isGuide,
    bool? isVerified,
    double? rating,
    int? reviewCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? expertise,
    double? pricePerDay,
    List<String>? specializations,
    int? yearsOfExperience,
    int? toursCompleted,
    double? latitude,
    double? longitude,
    String? currentLocation,
    bool? isLocationShared,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
      interests: interests ?? this.interests,
      languages: languages ?? this.languages,
      isGuide: isGuide ?? this.isGuide,
      isVerified: isVerified ?? this.isVerified,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      expertise: expertise ?? this.expertise,
      pricePerDay: pricePerDay ?? this.pricePerDay,
      specializations: specializations ?? this.specializations,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      toursCompleted: toursCompleted ?? this.toursCompleted,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      currentLocation: currentLocation ?? this.currentLocation,
      isLocationShared: isLocationShared ?? this.isLocationShared,
    );
  }

  // Convenience getters for backward compatibility
  String get id => uid; // Alias for uid
  String get name => displayName; // Alias for displayName

  @override
  String toString() {
    return 'UserModel(uid: $uid, displayName: $displayName, email: $email, isGuide: $isGuide)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserModel && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;
}

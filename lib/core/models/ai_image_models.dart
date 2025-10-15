/// AI Image Analysis models for image processing and analysis features
library ai_image_models;

/// Result of AI image analysis
class ImageAnalysisResult {
  final List<String> subjects;
  final LocationInfo? location;
  final List<String> activities;
  final String? mood;
  final String? timeOfDay;
  final String? weather;
  final List<String> colors;
  final List<String> tags;

  const ImageAnalysisResult({
    required this.subjects,
    this.location,
    required this.activities,
    this.mood,
    this.timeOfDay,
    this.weather,
    required this.colors,
    required this.tags,
  });

  factory ImageAnalysisResult.fromMap(Map<String, dynamic> map) {
    return ImageAnalysisResult(
      subjects: List<String>.from(map['subjects'] ?? []),
      location: map['location'] != null ? LocationInfo.fromMap(map['location']) : null,
      activities: List<String>.from(map['activities'] ?? []),
      mood: map['mood'],
      timeOfDay: map['time_of_day'],
      weather: map['weather'],
      colors: List<String>.from(map['colors'] ?? []),
      tags: List<String>.from(map['tags'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'subjects': subjects,
      'location': location?.toMap(),
      'activities': activities,
      'mood': mood,
      'time_of_day': timeOfDay,
      'weather': weather,
      'colors': colors,
      'tags': tags,
    };
  }
}

/// Location information in analyzed image
class LocationInfo {
  final String type;
  final String? name;
  final String? description;

  const LocationInfo({
    required this.type,
    this.name,
    this.description,
  });

  factory LocationInfo.fromMap(Map<String, dynamic> map) {
    return LocationInfo(
      type: map['type'] ?? '',
      name: map['name'],
      description: map['description'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'name': name,
      'description': description,
    };
  }
}

/// Result of landmark detection
class LandmarkDetectionResult {
  final bool isLandmark;
  final String? name;
  final String? location;
  final String description;
  final int? confidence;
  final String? significance;
  final String? bestTimeToVisit;
  final String? visitorTips;
  final List<String> nearbyAttractions;

  const LandmarkDetectionResult({
    required this.isLandmark,
    this.name,
    this.location,
    required this.description,
    this.confidence,
    this.significance,
    this.bestTimeToVisit,
    this.visitorTips,
    required this.nearbyAttractions,
  });

  factory LandmarkDetectionResult.fromMap(Map<String, dynamic> map) {
    return LandmarkDetectionResult(
      isLandmark: map['is_landmark'] ?? false,
      name: map['name'],
      location: map['location'],
      description: map['description'] ?? '',
      confidence: map['confidence'],
      significance: map['significance'],
      bestTimeToVisit: map['best_time_to_visit'],
      visitorTips: map['visitor_tips'],
      nearbyAttractions: List<String>.from(map['nearby_attractions'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'is_landmark': isLandmark,
      'name': name,
      'location': location,
      'description': description,
      'confidence': confidence,
      'significance': significance,
      'best_time_to_visit': bestTimeToVisit,
      'visitor_tips': visitorTips,
      'nearby_attractions': nearbyAttractions,
    };
  }
}

/// Caption generated for an image
class PhotoCaption {
  final List<CaptionOption> captions;
  final List<String> hashtags;
  final String? locationTag;
  final String? bestPostingTime;

  const PhotoCaption({
    required this.captions,
    required this.hashtags,
    this.locationTag,
    this.bestPostingTime,
  });

  factory PhotoCaption.fromMap(Map<String, dynamic> map) {
    return PhotoCaption(
      captions: (map['captions'] as List?)
          ?.map((c) => CaptionOption.fromMap(c))
          .toList() ?? [],
      hashtags: List<String>.from(map['hashtags'] ?? []),
      locationTag: map['location_tag'],
      bestPostingTime: map['best_posting_time'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'captions': captions.map((c) => c.toMap()).toList(),
      'hashtags': hashtags,
      'location_tag': locationTag,
      'best_posting_time': bestPostingTime,
    };
  }
}

/// Individual caption option
class CaptionOption {
  final String text;
  final String type;

  const CaptionOption({
    required this.text,
    required this.type,
  });

  factory CaptionOption.fromMap(Map<String, dynamic> map) {
    return CaptionOption(
      text: map['text'] ?? '',
      type: map['type'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'type': type,
    };
  }
}

/// Photography tips and analysis
class PhotographyTips {
  final int rating;
  final List<String> tips;
  final CameraSettings? cameraSettings;
  final List<String> editingSuggestions;

  const PhotographyTips({
    required this.rating,
    required this.tips,
    this.cameraSettings,
    required this.editingSuggestions,
  });

  factory PhotographyTips.fromMap(Map<String, dynamic> map) {
    return PhotographyTips(
      rating: map['rating'] ?? 0,
      tips: List<String>.from(map['tips'] ?? []),
      cameraSettings: map['camera_settings'] != null 
          ? CameraSettings.fromMap(map['camera_settings']) 
          : null,
      editingSuggestions: List<String>.from(map['editing_suggestions'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'rating': rating,
      'tips': tips,
      'camera_settings': cameraSettings?.toMap(),
      'editing_suggestions': editingSuggestions,
    };
  }
}

/// Camera settings recommendations
class CameraSettings {
  final String aperture;
  final String shutterSpeed;
  final String iso;

  const CameraSettings({
    required this.aperture,
    required this.shutterSpeed,
    required this.iso,
  });

  factory CameraSettings.fromMap(Map<String, dynamic> map) {
    return CameraSettings(
      aperture: map['aperture'] ?? '',
      shutterSpeed: map['shutter_speed'] ?? '',
      iso: map['iso'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'aperture': aperture,
      'shutter_speed': shutterSpeed,
      'iso': iso,
    };
  }
}
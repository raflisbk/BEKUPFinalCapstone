import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/utils/logger.dart';
import 'gemini_service.dart';

/// Service for AI-powered image recognition and analysis
class AIImageService {
  static const String _tag = 'AIImageService';
  final GeminiService _geminiService = GeminiService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _imagePicker = ImagePicker();

  /// Analyze an image for landmarks, objects, and descriptions
  Future<ImageAnalysisResult> analyzeImage({
    required File imageFile,
    String? context,
  }) async {
    try {
      // Read image bytes
      final imageBytes = await imageFile.readAsBytes();

      // Build analysis prompt
      final prompt = _buildAnalysisPrompt(context);

      // Analyze with Gemini Vision
      final response = await _geminiService.analyzeImage(
        imageBytes: imageBytes,
        prompt: prompt,
      );

      // Parse response
      final result = _parseAnalysisResponse(response);

      return result;
    } catch (e) {
      AppLogger.error(_tag, 'Error analyzing image', e);
      rethrow;
    }
  }

  /// Detect landmarks in an image
  Future<LandmarkDetectionResult> detectLandmark({
    required File imageFile,
    String? location,
  }) async {
    try {
      final imageBytes = await imageFile.readAsBytes();

      final prompt = '''
Analyze this image and identify any landmarks, monuments, or famous locations.

${location != null ? 'This photo was taken in or near: $location' : ''}

Please provide:
1. Landmark name (if identifiable)
2. Location (city, country)
3. Confidence level (0-100)
4. Brief description of the landmark
5. Historical or cultural significance
6. Best time to visit
7. Tips for visitors
8. Nearby attractions

Return ONLY valid JSON matching this structure:
{
  "isLandmark": true,
  "name": "Eiffel Tower",
  "location": "Paris, France",
  "confidence": 95,
  "description": "Iconic iron lattice tower on the Champ de Mars",
  "significance": "Built in 1889, symbol of France",
  "bestTimeToVisit": "Early morning or sunset for best photos",
  "visitorTips": "Book tickets online to skip lines, visit top floor for panoramic views",
  "nearbyAttractions": ["Louvre Museum", "Arc de Triomphe", "Seine River"]
}

If no landmark is detected, return:
{
  "isLandmark": false,
  "description": "General description of what's in the image"
}
''';

      final response = await _geminiService.analyzeImage(
        imageBytes: imageBytes,
        prompt: prompt,
      );

      // Parse JSON response
      final jsonResponse = _parseJsonResponse(response);

      return LandmarkDetectionResult.fromJson(jsonResponse);
    } catch (e) {
      AppLogger.error(_tag, 'Error detecting landmark', e);
      rethrow;
    }
  }

  /// Generate caption for travel photo
  Future<PhotoCaption> generateCaption({
    required File imageFile,
    String? destinationName,
    String? activityType,
  }) async {
    try {
      final imageBytes = await imageFile.readAsBytes();

      final prompt = '''
Create an engaging Instagram-style caption for this travel photo.

Context:
${destinationName != null ? '- Destination: $destinationName' : ''}
${activityType != null ? '- Activity: $activityType' : ''}

Generate 3 caption options:
1. Short and catchy (1-2 sentences, with emojis)
2. Storytelling (3-4 sentences, personal and descriptive)
3. Inspirational (motivational quote-style with hashtags)

Also provide:
- 5-7 relevant hashtags
- Location tag suggestion
- Best posting time recommendation

Return ONLY valid JSON:
{
  "captions": [
    {
      "type": "short",
      "text": "Living my best life in paradise 🌴✨"
    },
    {
      "type": "storytelling", 
      "text": "Found this hidden gem while exploring..."
    },
    {
      "type": "inspirational",
      "text": "Adventure awaits those who seek it 🌍"
    }
  ],
  "hashtags": ["#TravelPhotography", "#Wanderlust", "#Adventure"],
  "locationTag": "Bali, Indonesia",
  "bestPostingTime": "Golden hour (sunset) for maximum engagement"
}
''';

      final response = await _geminiService.analyzeImage(
        imageBytes: imageBytes,
        prompt: prompt,
      );

      final jsonResponse = _parseJsonResponse(response);

      return PhotoCaption.fromJson(jsonResponse);
    } catch (e) {
      AppLogger.error(_tag, 'Error generating caption', e);
      rethrow;
    }
  }

  /// Get photography tips for a location
  Future<PhotographyTips> getPhotographyTips({
    required File imageFile,
  }) async {
    try {
      final imageBytes = await imageFile.readAsBytes();

      const prompt = '''
Analyze this photo and provide professional photography feedback and tips.

Evaluate:
1. Composition (rule of thirds, framing, leading lines)
2. Lighting (quality, direction, time of day)
3. Focus and sharpness
4. Color and contrast
5. Subject placement

Provide:
- Overall rating (0-10)
- What's good about this photo
- What could be improved
- Specific tips to make it better
- Best camera settings for similar shots
- Recommended editing adjustments

Return ONLY valid JSON:
{
  "rating": 8,
  "strengths": ["Great composition", "Good natural lighting"],
  "improvements": ["Could use more vibrant colors", "Slightly off-center subject"],
  "tips": [
    "Try shooting during golden hour for warmer tones",
    "Use rule of thirds to position subject"
  ],
  "cameraSettings": {
    "aperture": "f/2.8 for shallow depth of field",
    "shutterSpeed": "1/250s to freeze motion",
    "iso": "100-400 depending on light"
  },
  "editingSuggestions": [
    "Increase vibrance by 10-15%",
    "Add slight vignette to draw focus",
    "Adjust highlights and shadows for more detail"
  ]
}
''';

      final response = await _geminiService.analyzeImage(
        imageBytes: imageBytes,
        prompt: prompt,
      );

      final jsonResponse = _parseJsonResponse(response);

      return PhotographyTips.fromJson(jsonResponse);
    } catch (e) {
      AppLogger.error(_tag, 'Error getting photography tips', e);
      rethrow;
    }
  }

  /// Pick image from gallery or camera
  Future<File?> pickImage({required ImageSource source}) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile == null) return null;

      return File(pickedFile.path);
    } catch (e) {
      AppLogger.error(_tag, 'Error picking image', e);
      rethrow;
    }
  }

  /// Save analysis result to Firestore
  Future<void> saveAnalysisResult({
    required String userId,
    required String imageUrl,
    required ImageAnalysisResult result,
  }) async {
    try {
      await _firestore.collection('image_analyses').add({
        'userId': userId,
        'imageUrl': imageUrl,
        'result': result.toJson(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      AppLogger.error(_tag, 'Error saving analysis result', e);
    }
  }

  /// Build analysis prompt
  String _buildAnalysisPrompt(String? context) {
    return '''
Analyze this image in detail and provide comprehensive information.

${context != null ? 'Context: $context' : ''}

Please identify and describe:
1. Main subjects and objects in the image
2. Location/setting (indoor/outdoor, type of place)
3. Activities or events happening
4. Notable features or landmarks
5. Mood and atmosphere
6. Colors and visual style
7. Any text or signs visible
8. Estimated time of day and weather conditions

Return ONLY valid JSON:
{
  "summary": "Brief one-sentence description",
  "subjects": ["list", "of", "main", "subjects"],
  "location": {
    "type": "outdoor/indoor/nature/urban",
    "description": "Detailed location description"
  },
  "activities": ["activities", "happening"],
  "landmarks": ["any", "recognizable", "landmarks"],
  "mood": "overall mood/atmosphere",
  "colors": ["dominant", "colors"],
  "timeOfDay": "morning/afternoon/evening/night",
  "weather": "sunny/cloudy/rainy/etc",
  "tags": ["relevant", "tags", "for", "search"]
}
''';
  }

  /// Parse analysis response
  ImageAnalysisResult _parseAnalysisResponse(String response) {
    try {
      final json = _parseJsonResponse(response);
      return ImageAnalysisResult.fromJson(json);
    } catch (e) {
      // Fallback to text response
      return ImageAnalysisResult(
        summary: response,
        subjects: [],
        tags: [],
      );
    }
  }

  /// Parse JSON from Gemini response
  Map<String, dynamic> _parseJsonResponse(String response) {
    // Remove markdown code blocks if present
    var cleanResponse = response.trim();
    if (cleanResponse.startsWith('```json')) {
      cleanResponse = cleanResponse.substring(7);
    }
    if (cleanResponse.startsWith('```')) {
      cleanResponse = cleanResponse.substring(3);
    }
    if (cleanResponse.endsWith('```')) {
      cleanResponse = cleanResponse.substring(0, cleanResponse.length - 3);
    }

    // Try to parse JSON
    try {
      return Map<String, dynamic>.from(
        jsonDecode(cleanResponse.trim()),
      );
    } catch (e) {
      AppLogger.error(_tag, 'JSON parse error: $e. Response: $cleanResponse', e);
      throw Exception('Failed to parse JSON response');
    }
  }
}

/// Image analysis result
class ImageAnalysisResult {
  final String summary;
  final List<String> subjects;
  final LocationInfo? location;
  final List<String> activities;
  final List<String> landmarks;
  final String? mood;
  final List<String> colors;
  final String? timeOfDay;
  final String? weather;
  final List<String> tags;

  ImageAnalysisResult({
    required this.summary,
    required this.subjects,
    this.location,
    this.activities = const [],
    this.landmarks = const [],
    this.mood,
    this.colors = const [],
    this.timeOfDay,
    this.weather,
    required this.tags,
  });

  factory ImageAnalysisResult.fromJson(Map<String, dynamic> json) {
    return ImageAnalysisResult(
      summary: json['summary'] ?? '',
      subjects: List<String>.from(json['subjects'] ?? []),
      location: json['location'] != null
          ? LocationInfo.fromJson(json['location'])
          : null,
      activities: List<String>.from(json['activities'] ?? []),
      landmarks: List<String>.from(json['landmarks'] ?? []),
      mood: json['mood'],
      colors: List<String>.from(json['colors'] ?? []),
      timeOfDay: json['timeOfDay'],
      weather: json['weather'],
      tags: List<String>.from(json['tags'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
        'summary': summary,
        'subjects': subjects,
        'location': location?.toJson(),
        'activities': activities,
        'landmarks': landmarks,
        'mood': mood,
        'colors': colors,
        'timeOfDay': timeOfDay,
        'weather': weather,
        'tags': tags,
      };
}

/// Location info from image
class LocationInfo {
  final String type;
  final String description;

  LocationInfo({
    required this.type,
    required this.description,
  });

  factory LocationInfo.fromJson(Map<String, dynamic> json) {
    return LocationInfo(
      type: json['type'] ?? '',
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'description': description,
      };
}

/// Landmark detection result
class LandmarkDetectionResult {
  final bool isLandmark;
  final String? name;
  final String? location;
  final int? confidence;
  final String description;
  final String? significance;
  final String? bestTimeToVisit;
  final String? visitorTips;
  final List<String> nearbyAttractions;

  LandmarkDetectionResult({
    required this.isLandmark,
    this.name,
    this.location,
    this.confidence,
    required this.description,
    this.significance,
    this.bestTimeToVisit,
    this.visitorTips,
    this.nearbyAttractions = const [],
  });

  factory LandmarkDetectionResult.fromJson(Map<String, dynamic> json) {
    return LandmarkDetectionResult(
      isLandmark: json['isLandmark'] ?? false,
      name: json['name'],
      location: json['location'],
      confidence: json['confidence'],
      description: json['description'] ?? '',
      significance: json['significance'],
      bestTimeToVisit: json['bestTimeToVisit'],
      visitorTips: json['visitorTips'],
      nearbyAttractions: List<String>.from(json['nearbyAttractions'] ?? []),
    );
  }
}

/// Photo caption with options
class PhotoCaption {
  final List<CaptionOption> captions;
  final List<String> hashtags;
  final String? locationTag;
  final String? bestPostingTime;

  PhotoCaption({
    required this.captions,
    required this.hashtags,
    this.locationTag,
    this.bestPostingTime,
  });

  factory PhotoCaption.fromJson(Map<String, dynamic> json) {
    return PhotoCaption(
      captions: (json['captions'] as List)
          .map((c) => CaptionOption.fromJson(c))
          .toList(),
      hashtags: List<String>.from(json['hashtags'] ?? []),
      locationTag: json['locationTag'],
      bestPostingTime: json['bestPostingTime'],
    );
  }
}

/// Caption option
class CaptionOption {
  final String type;
  final String text;

  CaptionOption({
    required this.type,
    required this.text,
  });

  factory CaptionOption.fromJson(Map<String, dynamic> json) {
    return CaptionOption(
      type: json['type'] ?? '',
      text: json['text'] ?? '',
    );
  }
}

/// Photography tips
class PhotographyTips {
  final int rating;
  final List<String> strengths;
  final List<String> improvements;
  final List<String> tips;
  final CameraSettings? cameraSettings;
  final List<String> editingSuggestions;

  PhotographyTips({
    required this.rating,
    required this.strengths,
    required this.improvements,
    required this.tips,
    this.cameraSettings,
    required this.editingSuggestions,
  });

  factory PhotographyTips.fromJson(Map<String, dynamic> json) {
    return PhotographyTips(
      rating: json['rating'] ?? 0,
      strengths: List<String>.from(json['strengths'] ?? []),
      improvements: List<String>.from(json['improvements'] ?? []),
      tips: List<String>.from(json['tips'] ?? []),
      cameraSettings: json['cameraSettings'] != null
          ? CameraSettings.fromJson(json['cameraSettings'])
          : null,
      editingSuggestions: List<String>.from(json['editingSuggestions'] ?? []),
    );
  }
}

/// Camera settings recommendation
class CameraSettings {
  final String aperture;
  final String shutterSpeed;
  final String iso;

  CameraSettings({
    required this.aperture,
    required this.shutterSpeed,
    required this.iso,
  });

  factory CameraSettings.fromJson(Map<String, dynamic> json) {
    return CameraSettings(
      aperture: json['aperture'] ?? '',
      shutterSpeed: json['shutterSpeed'] ?? '',
      iso: json['iso'] ?? '',
    );
  }
}

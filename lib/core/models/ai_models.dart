/// AI models for various AI services
/// This file contains model classes for AI-related functionality
library ai_models;

/// AI Itinerary Result
class AIItineraryResult {
  final String id;
  final String destination;
  final DateTime startDate;
  final DateTime endDate;
  final int durationDays;
  final List<Map<String, dynamic>> dailyPlans;
  final List<String> recommendations;
  final Map<String, dynamic> budgetEstimate;
  final double confidenceScore;
  final DateTime generatedAt;

  const AIItineraryResult({
    required this.id,
    required this.destination,
    required this.startDate,
    required this.endDate,
    required this.durationDays,
    required this.dailyPlans,
    required this.recommendations,
    required this.budgetEstimate,
    required this.confidenceScore,
    required this.generatedAt,
  });

  factory AIItineraryResult.fromMap(Map<String, dynamic> map) {
    return AIItineraryResult(
      id: map['id'] ?? '',
      destination: map['destination'] ?? '',
      startDate: DateTime.parse(map['start_date'] ?? DateTime.now().toIso8601String()),
      endDate: DateTime.parse(map['end_date'] ?? DateTime.now().toIso8601String()),
      durationDays: map['duration_days'] ?? 0,
      dailyPlans: List<Map<String, dynamic>>.from(map['daily_plans'] ?? []),
      recommendations: List<String>.from(map['recommendations'] ?? []),
      budgetEstimate: Map<String, dynamic>.from(map['budget_estimate'] ?? {}),
      confidenceScore: map['confidence_score']?.toDouble() ?? 0.0,
      generatedAt: DateTime.parse(map['generated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'destination': destination,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'duration_days': durationDays,
      'daily_plans': dailyPlans,
      'recommendations': recommendations,
      'budget_estimate': budgetEstimate,
      'confidence_score': confidenceScore,
      'generated_at': generatedAt.toIso8601String(),
    };
  }
}

/// Destination Recommendation
class DestinationRecommendation {
  final String id;
  final String name;
  final String description;
  final String location;
  final String imageUrl;
  final double rating;
  final List<String> tags;
  final Map<String, dynamic> priceRange;
  final String season;
  final double matchScore;
  final String reason;

  const DestinationRecommendation({
    required this.id,
    required this.name,
    required this.description,
    required this.location,
    required this.imageUrl,
    required this.rating,
    required this.tags,
    required this.priceRange,
    required this.season,
    required this.matchScore,
    required this.reason,
  });

  factory DestinationRecommendation.fromMap(Map<String, dynamic> map) {
    return DestinationRecommendation(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      location: map['location'] ?? '',
      imageUrl: map['image_url'] ?? '',
      rating: map['rating']?.toDouble() ?? 0.0,
      tags: List<String>.from(map['tags'] ?? []),
      priceRange: Map<String, dynamic>.from(map['price_range'] ?? {}),
      season: map['season'] ?? '',
      matchScore: map['match_score']?.toDouble() ?? 0.0,
      reason: map['reason'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'location': location,
      'image_url': imageUrl,
      'rating': rating,
      'tags': tags,
      'price_range': priceRange,
      'season': season,
      'match_score': matchScore,
      'reason': reason,
    };
  }
}

/// AI Navigation Suggestion
class AINavigationSuggestion {
  final String id;
  final String type;
  final String instruction;
  final String description;
  final Map<String, dynamic> location;
  final int priority;
  final DateTime timestamp;

  const AINavigationSuggestion({
    required this.id,
    required this.type,
    required this.instruction,
    required this.description,
    required this.location,
    required this.priority,
    required this.timestamp,
  });

  factory AINavigationSuggestion.fromMap(Map<String, dynamic> map) {
    return AINavigationSuggestion(
      id: map['id'] ?? '',
      type: map['type'] ?? '',
      instruction: map['instruction'] ?? '',
      description: map['description'] ?? '',
      location: Map<String, dynamic>.from(map['location'] ?? {}),
      priority: map['priority'] ?? 0,
      timestamp: DateTime.parse(map['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'instruction': instruction,
      'description': description,
      'location': location,
      'priority': priority,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/logger.dart';
import '../ai/gemini_service.dart';

/// Model for itinerary generation parameters
class ItineraryGenerationParams {
  final String destination;
  final String destinationId;
  final int days;
  final double budgetPerDay;
  final List<String> interests;
  final String pace; // 'relaxed', 'moderate', 'fast'
  final int travelers;
  final DateTime? startDate;
  final String? accommodation;

  ItineraryGenerationParams({
    required this.destination,
    required this.destinationId,
    required this.days,
    required this.budgetPerDay,
    required this.interests,
    required this.pace,
    required this.travelers,
    this.startDate,
    this.accommodation,
  });
}

/// AI-powered itinerary generation service
class AIItineraryService {
  static const String _tag = 'AIItineraryService';
  final GeminiService _gemini = GeminiService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Generate complete trip itinerary using AI
  Future<AIItineraryResult> generateItinerary(
    ItineraryGenerationParams params,
  ) async {
    try {
      // Get destination details for context
      final destDoc = await _firestore
          .collection('destinations')
          .doc(params.destinationId)
          .get();

      final destData = destDoc.data();
      final destDescription = destData?['description'] ?? '';
      final bestTimeToVisit = destData?['bestTimeToVisit'] ?? '';
      final attractions = destData?['attractions'] as List<dynamic>? ?? [];

      // Build comprehensive prompt
      final prompt = _buildItineraryPrompt(
        params,
        destDescription,
        bestTimeToVisit,
        attractions,
      );

      // Generate itinerary using Gemini
      final jsonResponse = await _gemini.generateJSON(prompt);

      // Parse response
      final result = AIItineraryResult.fromMap(jsonResponse);

      // Save to Firestore for caching
      await _saveGeneratedItinerary(params, result);

      return result;
    } catch (e) {
      AppLogger.error(_tag, 'Error generating itinerary', e);
      rethrow;
    }
  }

  /// Build detailed prompt for itinerary generation
  String _buildItineraryPrompt(
    ItineraryGenerationParams params,
    String destDescription,
    String bestTimeToVisit,
    List<dynamic> attractions,
  ) {
    final totalBudget = params.budgetPerDay * params.days;
    final budgetLevel = _getBudgetLevel(params.budgetPerDay);
    final startDateStr = params.startDate != null
        ? params.startDate!.toIso8601String().split('T')[0]
        : 'flexible';

    return '''
You are an expert travel planner. Create a detailed ${params.days}-day itinerary for ${params.destination}.

DESTINATION CONTEXT:
- Description: $destDescription
- Best time to visit: $bestTimeToVisit
- Key attractions: ${attractions.take(10).join(', ')}

USER PREFERENCES:
- Budget per day: \$${params.budgetPerDay.toStringAsFixed(0)} ($budgetLevel)
- Total budget: \$${totalBudget.toStringAsFixed(0)}
- Interests: ${params.interests.join(', ')}
- Travel pace: ${params.pace}
- Number of travelers: ${params.travelers}
- Start date: $startDateStr
${params.accommodation != null ? '- Accommodation preference: ${params.accommodation}' : ''}

REQUIREMENTS:
1. Create a day-by-day itinerary optimized for minimal travel time
2. Include specific attractions, restaurants, and activities
3. Consider realistic opening hours and travel times
4. Stay within the specified budget
5. Balance activities based on the ${params.pace} pace
6. Include cost estimates for each activity
7. Add practical tips (transportation, tickets, booking advice)
8. Suggest alternative activities for bad weather
9. Include meal recommendations with price ranges
10. Add safety tips and local customs

IMPORTANT FORMATTING:
- Use real location names, addresses, and coordinates
- Estimate costs realistically based on destination
- Provide actionable tips (not generic advice)
- Include time buffers for travel between locations
- Suggest specific restaurants with cuisine types

OUTPUT FORMAT (JSON):
{
  "itinerary": [
    {
      "day": 1,
      "dayOfWeek": "Monday",
      "date": "$startDateStr or relative",
      "theme": "Exploring Historic District",
      "activities": [
        {
          "time": "09:00",
          "duration": 120,
          "title": "Visit National Museum",
          "type": "attraction",
          "category": "culture",
          "location": "Full address",
          "coordinates": {"lat": 0.0, "lng": 0.0},
          "description": "Detailed description of what to see and do",
          "cost": 25,
          "currency": "USD",
          "tips": ["Arrive early to avoid crowds", "Book tickets online"],
          "bookingRequired": true,
          "bookingUrl": "https://example.com",
          "openingHours": "9:00 AM - 6:00 PM",
          "priority": "high"
        },
        {
          "time": "12:00",
          "duration": 60,
          "title": "Lunch at Local Bistro",
          "type": "meal",
          "category": "food",
          "location": "Restaurant name and address",
          "coordinates": {"lat": 0.0, "lng": 0.0},
          "description": "Recommended dishes and atmosphere",
          "cost": 20,
          "currency": "USD",
          "tips": ["Try the local specialty", "Reservations recommended"],
          "cuisineType": "Local",
          "priceRange": "moderate"
        }
      ],
      "totalCost": 150,
      "totalDuration": 480,
      "summary": "Immerse yourself in the city's rich history",
      "travelTips": ["Wear comfortable shoes", "Bring sunscreen"]
    }
  ],
  "totalEstimatedCost": ${totalBudget.toStringAsFixed(0)},
  "costBreakdown": {
    "attractions": 400,
    "meals": 300,
    "transportation": 200,
    "accommodation": 600,
    "miscellaneous": 100
  },
  "keyTips": [
    "Best areas to stay for first-time visitors",
    "How to get around the city",
    "What to pack for the weather",
    "Money-saving tips",
    "Safety precautions"
  ],
  "alternatives": {
    "rainyDay": ["Indoor activities for bad weather"],
    "budget": ["Free or low-cost alternatives"],
    "extraTime": ["Activities if you have extra time"]
  },
  "transportationInfo": {
    "gettingThere": "How to reach the destination",
    "localTransport": "Best ways to get around",
    "estimatedCost": 50
  },
  "packingList": ["Essential items to bring"],
  "localCustoms": ["Cultural norms to be aware of"],
  "emergencyContacts": {
    "police": "local emergency number",
    "hospital": "nearest hospital info",
    "embassy": "embassy contact if international"
  }
}

Generate a realistic, actionable itinerary that a traveler can actually follow.
''';
  }

  /// Determine budget level from per-day amount
  String _getBudgetLevel(double perDay) {
    if (perDay < 50) return 'budget-friendly';
    if (perDay < 100) return 'moderate';
    if (perDay < 200) return 'comfortable';
    return 'luxury';
  }

  /// Save generated itinerary to Firestore
  Future<void> _saveGeneratedItinerary(
    ItineraryGenerationParams params,
    AIItineraryResult result,
  ) async {
    try {
      await _firestore.collection('ai_itineraries').add({
        'destinationId': params.destinationId,
        'destination': params.destination,
        'days': params.days,
        'budgetPerDay': params.budgetPerDay,
        'interests': params.interests,
        'pace': params.pace,
        'travelers': params.travelers,
        'totalCost': result.totalEstimatedCost,
        'generatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      AppLogger.error(_tag, 'Error saving itinerary', e);
      // Non-critical, continue
    }
  }

  /// Apply generated itinerary to a trip
  Future<void> applyToTrip({
    required String tripId,
    required AIItineraryResult itinerary,
  }) async {
    try {
      final tripRef = _firestore.collection('trips').doc(tripId);

      // Convert AI itinerary to trip itinerary items
      final Map<String, dynamic> itineraryData = {};

      for (final day in itinerary.itinerary) {
        final dayKey = 'day${day.day}';
        itineraryData[dayKey] = day.activities.map((activity) {
          return {
            'time': activity.time,
            'duration': activity.duration,
            'title': activity.title,
            'type': activity.type,
            'category': activity.category,
            'location': activity.location,
            'coordinates': activity.coordinates,
            'description': activity.description,
            'cost': activity.cost,
            'tips': activity.tips,
            'bookingRequired': activity.bookingRequired,
            'bookingUrl': activity.bookingUrl,
            'priority': activity.priority,
          };
        }).toList();
      }

      // Update trip with itinerary
      await tripRef.update({
        'itinerary': itineraryData,
        'estimatedCost': itinerary.totalEstimatedCost,
        'aiGenerated': true,
        'generatedAt': FieldValue.serverTimestamp(),
      });

      AppLogger.info(_tag, 'Successfully applied itinerary to trip $tripId');
    } catch (e) {
      AppLogger.error(_tag, 'Error applying itinerary', e);
      rethrow;
    }
  }
}

/// Result from AI itinerary generation
class AIItineraryResult {
  final List<DayItinerary> itinerary;
  final double totalEstimatedCost;
  final CostBreakdown costBreakdown;
  final List<String> keyTips;
  final AlternativeActivities alternatives;
  final TransportationInfo transportationInfo;
  final List<String> packingList;
  final List<String> localCustoms;
  final EmergencyContacts? emergencyContacts;

  AIItineraryResult({
    required this.itinerary,
    required this.totalEstimatedCost,
    required this.costBreakdown,
    required this.keyTips,
    required this.alternatives,
    required this.transportationInfo,
    required this.packingList,
    required this.localCustoms,
    this.emergencyContacts,
  });

  factory AIItineraryResult.fromMap(Map<String, dynamic> map) {
    return AIItineraryResult(
      itinerary: (map['itinerary'] as List)
          .map((e) => DayItinerary.fromMap(e as Map<String, dynamic>))
          .toList(),
      totalEstimatedCost: (map['totalEstimatedCost'] ?? 0).toDouble(),
      costBreakdown: CostBreakdown.fromMap(
        map['costBreakdown'] as Map<String, dynamic>? ?? {},
      ),
      keyTips: List<String>.from(map['keyTips'] ?? []),
      alternatives: AlternativeActivities.fromMap(
        map['alternatives'] as Map<String, dynamic>? ?? {},
      ),
      transportationInfo: TransportationInfo.fromMap(
        map['transportationInfo'] as Map<String, dynamic>? ?? {},
      ),
      packingList: List<String>.from(map['packingList'] ?? []),
      localCustoms: List<String>.from(map['localCustoms'] ?? []),
      emergencyContacts: map['emergencyContacts'] != null
          ? EmergencyContacts.fromMap(
              map['emergencyContacts'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Single day in itinerary
class DayItinerary {
  final int day;
  final String dayOfWeek;
  final String date;
  final String theme;
  final List<Activity> activities;
  final double totalCost;
  final int totalDuration;
  final String summary;
  final List<String> travelTips;

  DayItinerary({
    required this.day,
    required this.dayOfWeek,
    required this.date,
    required this.theme,
    required this.activities,
    required this.totalCost,
    required this.totalDuration,
    required this.summary,
    required this.travelTips,
  });

  factory DayItinerary.fromMap(Map<String, dynamic> map) {
    return DayItinerary(
      day: map['day'] ?? 1,
      dayOfWeek: map['dayOfWeek'] ?? '',
      date: map['date'] ?? '',
      theme: map['theme'] ?? '',
      activities: (map['activities'] as List? ?? [])
          .map((e) => Activity.fromMap(e as Map<String, dynamic>))
          .toList(),
      totalCost: (map['totalCost'] ?? 0).toDouble(),
      totalDuration: map['totalDuration'] ?? 0,
      summary: map['summary'] ?? '',
      travelTips: List<String>.from(map['travelTips'] ?? []),
    );
  }
}

/// Single activity in itinerary
class Activity {
  final String time;
  final int duration;
  final String title;
  final String type;
  final String category;
  final String location;
  final Map<String, double> coordinates;
  final String description;
  final double cost;
  final String currency;
  final List<String> tips;
  final bool bookingRequired;
  final String? bookingUrl;
  final String? openingHours;
  final String priority;
  final String? cuisineType;
  final String? priceRange;

  Activity({
    required this.time,
    required this.duration,
    required this.title,
    required this.type,
    required this.category,
    required this.location,
    required this.coordinates,
    required this.description,
    required this.cost,
    required this.currency,
    required this.tips,
    required this.bookingRequired,
    this.bookingUrl,
    this.openingHours,
    required this.priority,
    this.cuisineType,
    this.priceRange,
  });

  factory Activity.fromMap(Map<String, dynamic> map) {
    return Activity(
      time: map['time'] ?? '',
      duration: map['duration'] ?? 60,
      title: map['title'] ?? '',
      type: map['type'] ?? 'activity',
      category: map['category'] ?? '',
      location: map['location'] ?? '',
      coordinates: {
        'lat': (map['coordinates']?['lat'] ?? 0).toDouble(),
        'lng': (map['coordinates']?['lng'] ?? 0).toDouble(),
      },
      description: map['description'] ?? '',
      cost: (map['cost'] ?? 0).toDouble(),
      currency: map['currency'] ?? 'USD',
      tips: List<String>.from(map['tips'] ?? []),
      bookingRequired: map['bookingRequired'] ?? false,
      bookingUrl: map['bookingUrl'],
      openingHours: map['openingHours'],
      priority: map['priority'] ?? 'medium',
      cuisineType: map['cuisineType'],
      priceRange: map['priceRange'],
    );
  }
}

/// Cost breakdown by category
class CostBreakdown {
  final double attractions;
  final double meals;
  final double transportation;
  final double accommodation;
  final double miscellaneous;

  CostBreakdown({
    required this.attractions,
    required this.meals,
    required this.transportation,
    required this.accommodation,
    required this.miscellaneous,
  });

  factory CostBreakdown.fromMap(Map<String, dynamic> map) {
    return CostBreakdown(
      attractions: (map['attractions'] ?? 0).toDouble(),
      meals: (map['meals'] ?? 0).toDouble(),
      transportation: (map['transportation'] ?? 0).toDouble(),
      accommodation: (map['accommodation'] ?? 0).toDouble(),
      miscellaneous: (map['miscellaneous'] ?? 0).toDouble(),
    );
  }

  double get total =>
      attractions + meals + transportation + accommodation + miscellaneous;
}

/// Alternative activities for different scenarios
class AlternativeActivities {
  final List<String> rainyDay;
  final List<String> budget;
  final List<String> extraTime;

  AlternativeActivities({
    required this.rainyDay,
    required this.budget,
    required this.extraTime,
  });

  factory AlternativeActivities.fromMap(Map<String, dynamic> map) {
    return AlternativeActivities(
      rainyDay: List<String>.from(map['rainyDay'] ?? []),
      budget: List<String>.from(map['budget'] ?? []),
      extraTime: List<String>.from(map['extraTime'] ?? []),
    );
  }
}

/// Transportation information
class TransportationInfo {
  final String gettingThere;
  final String localTransport;
  final double estimatedCost;

  TransportationInfo({
    required this.gettingThere,
    required this.localTransport,
    required this.estimatedCost,
  });

  factory TransportationInfo.fromMap(Map<String, dynamic> map) {
    return TransportationInfo(
      gettingThere: map['gettingThere'] ?? '',
      localTransport: map['localTransport'] ?? '',
      estimatedCost: (map['estimatedCost'] ?? 0).toDouble(),
    );
  }
}

/// Emergency contacts
class EmergencyContacts {
  final String police;
  final String hospital;
  final String embassy;

  EmergencyContacts({
    required this.police,
    required this.hospital,
    required this.embassy,
  });

  factory EmergencyContacts.fromMap(Map<String, dynamic> map) {
    return EmergencyContacts(
      police: map['police'] ?? '',
      hospital: map['hospital'] ?? '',
      embassy: map['embassy'] ?? '',
    );
  }
}

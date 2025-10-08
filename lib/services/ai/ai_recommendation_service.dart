import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/destination_model.dart';
import 'gemini_service.dart';

/// Service for AI-powered destination recommendations
class AIRecommendationService {
  final GeminiService _geminiService = GeminiService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Generate personalized destination recommendations
  Future<List<DestinationRecommendation>> getPersonalizedRecommendations({
    required String userId,
    int limit = 10,
  }) async {
    try {
      // 1. Gather user context
      final userContext = await _gatherUserContext(userId);

      // 2. Get all destinations
      final destinations = await _getAllDestinations();

      // 3. Generate AI recommendations
      final prompt = _buildRecommendationPrompt(userContext, destinations);
      final response = await _geminiService.generateJSON(prompt);

      // 4. Parse and enrich recommendations
      final recommendations = _parseRecommendations(response, destinations);

      // 5. Cache recommendations
      await _cacheRecommendations(userId, recommendations);

      return recommendations;
    } catch (e) {
      print('Error generating recommendations: $e');
      rethrow;
    }
  }

  /// Get cached recommendations if available
  Future<List<DestinationRecommendation>?> getCachedRecommendations(
    String userId,
  ) async {
    try {
      final doc = await _firestore
          .collection('ai_recommendations')
          .doc(userId)
          .get();

      if (!doc.exists) return null;

      final data = doc.data()!;
      final cachedAt = (data['cachedAt'] as Timestamp).toDate();
      final now = DateTime.now();

      // Cache valid for 7 days
      if (now.difference(cachedAt).inDays > 7) {
        return null;
      }

      final recommendations = (data['recommendations'] as List)
          .map((json) => DestinationRecommendation.fromJson(json))
          .toList();

      return recommendations;
    } catch (e) {
      print('Error getting cached recommendations: $e');
      return null;
    }
  }

  /// Get similar destinations based on a destination
  Future<List<DestinationRecommendation>> getSimilarDestinations({
    required String destinationId,
    int limit = 5,
  }) async {
    try {
      // Get the reference destination
      final refDestination = await _getDestination(destinationId);
      if (refDestination == null) {
        throw Exception('Destination not found');
      }

      // Get all destinations except the reference
      final allDestinations = await _getAllDestinations();
      final otherDestinations = allDestinations
          .where((d) => d.id != destinationId)
          .toList();

      // Generate similarity analysis
      final prompt = _buildSimilarityPrompt(refDestination, otherDestinations);
      final response = await _geminiService.generateJSON(prompt);

      // Parse recommendations
      final recommendations = _parseRecommendations(response, otherDestinations);

      return recommendations.take(limit).toList();
    } catch (e) {
      print('Error finding similar destinations: $e');
      rethrow;
    }
  }

  /// Get trending destinations with AI insights
  Future<List<DestinationRecommendation>> getTrendingDestinations({
    int limit = 10,
  }) async {
    try {
      // Get destinations sorted by rating and review count
      final snapshot = await _firestore
          .collection('destinations')
          .orderBy('rating', descending: true)
          .orderBy('reviewCount', descending: true)
          .limit(20)
          .get();

      final destinations = snapshot.docs
          .map((doc) => Destination.fromFirestore(doc))
          .toList();

      // Generate AI insights for trending destinations
      final prompt = _buildTrendingPrompt(destinations);
      final response = await _geminiService.generateJSON(prompt);

      // Parse recommendations
      final recommendations = _parseRecommendations(response, destinations);

      return recommendations.take(limit).toList();
    } catch (e) {
      print('Error getting trending destinations: $e');
      rethrow;
    }
  }

  /// Gather user context for personalization
  Future<UserContext> _gatherUserContext(String userId) async {
    // Get user's past trips
    final tripsSnapshot = await _firestore
        .collection('trips')
        .where('userId', isEqualTo: userId)
        .get();

    final visitedDestinations = <String>[];
    final preferredCategories = <String>[];
    var avgBudget = 0.0;
    var totalTrips = 0;

    for (final doc in tripsSnapshot.docs) {
      final data = doc.data();
      totalTrips++;

      // Collect visited destinations
      if (data['destinations'] != null) {
        for (final dest in data['destinations']) {
          visitedDestinations.add(dest['name'] ?? '');
        }
      }

      // Calculate average budget
      if (data['budget'] != null) {
        avgBudget += (data['budget'] as num).toDouble();
      }
    }

    if (totalTrips > 0) {
      avgBudget /= totalTrips;
    }

    // Get user's saved destinations
    final savedSnapshot = await _firestore
        .collection('saved_destinations')
        .where('userId', isEqualTo: userId)
        .get();

    final savedDestinations = savedSnapshot.docs
        .map((doc) => doc.data()['destinationId'] as String)
        .toList();

    // Get user's reviews to understand preferences
    final reviewsSnapshot = await _firestore
        .collection('reviews')
        .where('userId', isEqualTo: userId)
        .where('rating', isGreaterThanOrEqualTo: 4)
        .get();

    for (final doc in reviewsSnapshot.docs) {
      final data = doc.data();
      if (data['categories'] != null) {
        preferredCategories.addAll((data['categories'] as List).cast<String>());
      }
    }

    return UserContext(
      visitedDestinations: visitedDestinations,
      savedDestinations: savedDestinations,
      preferredCategories: preferredCategories.toSet().toList(),
      averageBudget: avgBudget,
      totalTrips: totalTrips,
    );
  }

  /// Get all destinations from Firestore
  Future<List<Destination>> _getAllDestinations() async {
    final snapshot = await _firestore.collection('destinations').get();
    return snapshot.docs
        .map((doc) => Destination.fromFirestore(doc))
        .toList();
  }

  /// Get a single destination
  Future<Destination?> _getDestination(String destinationId) async {
    final doc = await _firestore.collection('destinations').doc(destinationId).get();
    if (!doc.exists) return null;
    return Destination.fromFirestore(doc);
  }

  /// Build prompt for personalized recommendations
  String _buildRecommendationPrompt(
    UserContext context,
    List<Destination> destinations,
  ) {
    return '''
You are a travel recommendation expert. Analyze the user's travel history and preferences to recommend the best destinations for them.

USER PROFILE:
- Total trips: ${context.totalTrips}
- Average budget: \$${context.averageBudget.toStringAsFixed(0)}
- Visited destinations: ${context.visitedDestinations.join(', ')}
- Saved destinations: ${context.savedDestinations.length}
- Preferred categories: ${context.preferredCategories.join(', ')}

AVAILABLE DESTINATIONS:
${destinations.map((d) => '''
- ${d.name}, ${d.location}
  * Category: ${d.category}
  * Activities: ${d.activities.join(', ')}
  * Budget level: ${d.priceRangeText}
  * Rating: ${d.rating}/5 (${d.reviewCount} reviews)
  * Best for: ${d.bestTimeToVisit}
  * Description: ${d.description.substring(0, d.description.length > 100 ? 100 : d.description.length)}...
''').join('\n')}

TASK:
Recommend the top 10 destinations that best match this user's profile. Consider:
1. Destinations similar to places they've visited
2. Destinations in their budget range
3. Categories they prefer
4. Variety (don't just recommend similar places)
5. Trending and popular destinations
6. Seasonal appropriateness

For each recommendation, provide:
- Destination ID
- Match score (0-100)
- Why it's a good match (specific to user's profile)
- Best aspect (what makes it special)
- Travel tip (personalized advice)

Return ONLY valid JSON matching this structure:
{
  "recommendations": [
    {
      "destinationId": "dest123",
      "matchScore": 95,
      "matchReason": "Similar to Bali which you loved, offers same cultural experiences",
      "bestAspect": "Stunning rice terraces and ancient temples",
      "travelTip": "Visit during sunset for magical golden hour photos",
      "personalizedNote": "Based on your love for cultural sites and photography"
    }
  ]
}
''';
  }

  /// Build prompt for similar destinations
  String _buildSimilarityPrompt(
    Destination reference,
    List<Destination> candidates,
  ) {
    return '''
You are a travel similarity expert. Find destinations most similar to the reference destination.

REFERENCE DESTINATION:
- Name: ${reference.name}, ${reference.location}
- Category: ${reference.category}
- Activities: ${reference.activities.join(', ')}
- Budget: ${reference.priceRangeText}
- Rating: ${reference.rating}/5
- Description: ${reference.description}
- Best for: ${reference.bestTimeToVisit}

CANDIDATE DESTINATIONS:
${candidates.map((d) => '''
- ${d.name}, ${d.location}
  * Category: ${d.category}
  * Activities: ${d.activities.join(', ')}
  * Budget: ${d.priceRangeText}
  * Rating: ${d.rating}/5
  * Description: ${d.description.substring(0, d.description.length > 100 ? 100 : d.description.length)}...
''').join('\n')}

TASK:
Find the 5 most similar destinations based on:
1. Shared categories and activities
2. Similar budget range
3. Comparable atmosphere and vibe
4. Similar target audience
5. Comparable ratings and quality

For each similar destination, provide:
- Match score (0-100)
- Why it's similar
- Key differences
- When to visit instead

Return ONLY valid JSON:
{
  "recommendations": [
    {
      "destinationId": "dest123",
      "matchScore": 92,
      "matchReason": "Both offer pristine beaches and water sports",
      "bestAspect": "Less crowded but same tropical paradise vibe",
      "travelTip": "Visit May-October for best weather",
      "personalizedNote": "A hidden gem alternative to ${reference.name}"
    }
  ]
}
''';
  }

  /// Build prompt for trending destinations
  String _buildTrendingPrompt(List<Destination> destinations) {
    return '''
You are a travel trends expert. Analyze these popular destinations and provide insights on why they're trending.

TRENDING DESTINATIONS:
${destinations.map((d) => '''
- ${d.name}, ${d.location}
  * Category: ${d.category}
  * Activities: ${d.activities.join(', ')}
  * Rating: ${d.rating}/5 (${d.reviewCount} reviews)
  * Description: ${d.description.substring(0, d.description.length > 100 ? 100 : d.description.length)}...
''').join('\n')}

TASK:
For each destination, explain:
1. Why it's trending right now
2. What makes it special
3. Who should visit
4. Best time to visit
5. Insider tip

Return ONLY valid JSON:
{
  "recommendations": [
    {
      "destinationId": "dest123",
      "matchScore": 95,
      "matchReason": "Trending for sustainable eco-tourism and wellness retreats",
      "bestAspect": "Perfect blend of adventure and relaxation",
      "travelTip": "Book yoga retreats 3 months in advance",
      "personalizedNote": "Ideal for travelers seeking authentic experiences"
    }
  ]
}
''';
  }

  /// Parse AI recommendations
  List<DestinationRecommendation> _parseRecommendations(
    Map<String, dynamic> response,
    List<Destination> destinations,
  ) {
    final recommendations = <DestinationRecommendation>[];
    
    if (response['recommendations'] == null) {
      throw Exception('Invalid response format');
    }

    for (final item in response['recommendations']) {
      try {
        final destId = item['destinationId'] as String;
        final destination = destinations.firstWhere(
          (d) => d.id == destId,
          orElse: () => throw Exception('Destination not found: $destId'),
        );

        recommendations.add(
          DestinationRecommendation(
            destination: destination,
            matchScore: (item['matchScore'] as num).toInt(),
            matchReason: item['matchReason'] as String,
            bestAspect: item['bestAspect'] as String,
            travelTip: item['travelTip'] as String,
            personalizedNote: item['personalizedNote'] as String,
          ),
        );
      } catch (e) {
        print('Error parsing recommendation item: $e');
        continue;
      }
    }

    // Sort by match score
    recommendations.sort((a, b) => b.matchScore.compareTo(a.matchScore));

    return recommendations;
  }

  /// Cache recommendations to Firestore
  Future<void> _cacheRecommendations(
    String userId,
    List<DestinationRecommendation> recommendations,
  ) async {
    try {
      await _firestore.collection('ai_recommendations').doc(userId).set({
        'recommendations': recommendations.map((r) => r.toJson()).toList(),
        'cachedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error caching recommendations: $e');
      // Don't throw, caching is optional
    }
  }
}

/// User context for personalization
class UserContext {
  final List<String> visitedDestinations;
  final List<String> savedDestinations;
  final List<String> preferredCategories;
  final double averageBudget;
  final int totalTrips;

  UserContext({
    required this.visitedDestinations,
    required this.savedDestinations,
    required this.preferredCategories,
    required this.averageBudget,
    required this.totalTrips,
  });
}

/// Destination recommendation with AI insights
class DestinationRecommendation {
  final Destination destination;
  final int matchScore;
  final String matchReason;
  final String bestAspect;
  final String travelTip;
  final String personalizedNote;

  DestinationRecommendation({
    required this.destination,
    required this.matchScore,
    required this.matchReason,
    required this.bestAspect,
    required this.travelTip,
    required this.personalizedNote,
  });

  Map<String, dynamic> toJson() => {
        'destination': destination.toMap(),
        'destinationId': destination.id,
        'matchScore': matchScore,
        'matchReason': matchReason,
        'bestAspect': bestAspect,
        'travelTip': travelTip,
        'personalizedNote': personalizedNote,
      };

  factory DestinationRecommendation.fromJson(Map<String, dynamic> json) {
    return DestinationRecommendation(
      destination: Destination.fromMap(json['destination']),
      matchScore: json['matchScore'] as int,
      matchReason: json['matchReason'] as String,
      bestAspect: json['bestAspect'] as String,
      travelTip: json['travelTip'] as String,
      personalizedNote: json['personalizedNote'] as String,
    );
  }
}

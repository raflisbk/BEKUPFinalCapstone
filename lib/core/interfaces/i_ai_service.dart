/// Interface for AI Service
/// Defines contracts for AI-powered features including text generation,
/// content analysis, and conversational AI
abstract class IAIService {
  // ===============================
  // TEXT GENERATION
  // ===============================

  /// Generate text content using Gemini AI
  Future<String> generateText({
    required String prompt,
    String? model,
    double temperature = 0.7,
    int maxTokens = 1000,
    List<String>? stopSequences,
    Map<String, dynamic>? context,
  });

  /// Generate travel itinerary
  Future<String> generateTravelItinerary({
    required String destination,
    required int days,
    required String budget,
    required List<String> interests,
    String? travelStyle,
    String? groupSize,
  });

  /// Generate destination description
  Future<String> generateDestinationDescription({
    required String destinationName,
    required String location,
    String? category,
    List<String>? highlights,
  });

  /// Generate travel tips
  Future<String> generateTravelTips({
    required String destination,
    required String travelType,
    String? season,
  });

  // ===============================
  // CONTENT ANALYSIS
  // ===============================

  /// Analyze content sentiment
  Future<Map<String, dynamic>> analyzeSentiment(String text);

  /// Extract key information from text
  Future<Map<String, dynamic>> extractInformation(String text);

  // ===============================
  // CHAT & CONVERSATIONAL AI
  // ===============================

  /// Chat with AI assistant
  Future<String> chatWithAssistant({
    required String message,
    List<Map<String, String>>? conversationHistory,
    String? context,
  });

  // ===============================
  // LOGGING & ANALYTICS
  // ===============================

  /// Get AI usage statistics
  Future<Map<String, dynamic>> getUsageStatistics({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
  });
}

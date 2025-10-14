import 'dart:async';
import 'dart:convert';
import '../../core/utils/logger.dart';
import '../supabase_config.dart';
import '../supabase_database_service.dart';
import 'gemini_service.dart';

/// AI Navigation Service
/// Handles AI-powered navigation assistance and real-time guidance
class AINavigationService {
  static const String _tag = 'AINavigationService';
  static const String _navigationSessionsTable = 'ai_navigation_sessions';
  static const String _navigationEventsTable = 'ai_navigation_events';

  // Navigation modes
  static const String modeDriving = 'driving';
  static const String modeWalking = 'walking';
  static const String modePublicTransport = 'public_transport';
  static const String modeCycling = 'cycling';

  // Event types
  static const String eventTurnByTurn = 'turn_by_turn';
  static const String eventTrafficUpdate = 'traffic_update';
  static const String eventRouteDeviation = 'route_deviation';
  static const String eventPointOfInterest = 'point_of_interest';
  static const String eventHazardAlert = 'hazard_alert';

  // Session status
  static const String statusActive = 'active';
  static const String statusPaused = 'paused';
  static const String statusCompleted = 'completed';
  static const String statusCancelled = 'cancelled';

  // ===============================
  // NAVIGATION SESSION MANAGEMENT
  // ===============================

  /// Start AI-powered navigation session
  static Future<Map<String, dynamic>> startNavigationSession({
    required String origin,
    required String destination,
    required String navigationMode,
    Map<String, dynamic>? routePlan,
    Map<String, dynamic>? preferences,
  }) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Starting AI navigation session: $origin to $destination');

      // Create navigation session
      final sessionData = {
        'user_id': userId,
        'origin': origin,
        'destination': destination,
        'navigation_mode': navigationMode,
        'route_plan': routePlan ?? {},
        'preferences': preferences ?? {},
        'status': statusActive,
        'start_time': DateTime.now().toIso8601String(),
        'events_count': 0,
        'created_at': DateTime.now().toIso8601String(),
      };

      final session = await SupabaseDatabaseService.insert(
        table: _navigationSessionsTable,
        data: sessionData,
      );

      // Generate initial navigation guidance
      final initialGuidance = await _generateNavigationGuidance(
        session['id'],
        origin,
        destination,
        navigationMode,
        routePlan,
      );

      // Log session start event
      await _logNavigationEvent(
        session['id'],
        'session_started',
        {
          'origin': origin,
          'destination': destination,
          'mode': navigationMode,
          'initial_guidance': initialGuidance,
        },
      );

      AppLogger.success(_tag, 'Navigation session started: ${session['id']}');
      return {
        'session_id': session['id'],
        'initial_guidance': initialGuidance,
        'status': statusActive,
        'navigation_mode': navigationMode,
      };
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to start navigation session', e, stackTrace);
      rethrow;
    }
  }

  /// Get real-time navigation assistance
  static Future<Map<String, dynamic>> getNavigationAssistance({
    required String sessionId,
    required Map<String, double> currentLocation, // {lat, lng}
    String? currentHeading,
    double? currentSpeed,
    Map<String, dynamic>? contextData,
  }) async {
    try {
      AppLogger.debug(_tag, 'Getting navigation assistance for session: $sessionId');

      // Get session data
      final session = await _getNavigationSession(sessionId);
      if (session == null) {
        throw Exception('Navigation session not found');
      }

      // Build assistance prompt
      final prompt = _buildNavigationAssistancePrompt(
        session,
        currentLocation,
        currentHeading,
        currentSpeed,
        contextData,
      );

      // Get AI assistance
      final aiResponse = await GeminiService.generateContent(
        prompt: prompt,
        model: GeminiService.modelFlash,
        temperature: 0.3, // Lower temperature for consistent navigation
        maxOutputTokens: 1024,
      );

      // Parse assistance response
      final assistance = _parseNavigationAssistance(aiResponse);

      // Log navigation event
      await _logNavigationEvent(
        sessionId,
        eventTurnByTurn,
        {
          'current_location': currentLocation,
          'assistance': assistance,
          'heading': currentHeading,
          'speed': currentSpeed,
        },
      );

      AppLogger.success(_tag, 'Navigation assistance provided');
      return assistance;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get navigation assistance', e, stackTrace);
      rethrow;
    }
  }

  /// Handle route deviation
  static Future<Map<String, dynamic>> handleRouteDeviation({
    required String sessionId,
    required Map<String, double> currentLocation,
    required String deviationReason,
  }) async {
    try {
      AppLogger.debug(_tag, 'Handling route deviation for session: $sessionId');

      // Get session data
      final session = await _getNavigationSession(sessionId);
      if (session == null) {
        throw Exception('Navigation session not found');
      }

      // Build rerouting prompt
      final prompt = _buildReroutingPrompt(
        session,
        currentLocation,
        deviationReason,
      );

      // Get AI rerouting suggestion
      final aiResponse = await GeminiService.generateContent(
        prompt: prompt,
        model: GeminiService.modelPro,
        temperature: 0.5,
        maxOutputTokens: 2048,
      );

      // Parse rerouting response
      final rerouting = _parseReroutingResponse(aiResponse);

      // Log deviation event
      await _logNavigationEvent(
        sessionId,
        eventRouteDeviation,
        {
          'current_location': currentLocation,
          'deviation_reason': deviationReason,
          'rerouting_suggestion': rerouting,
        },
      );

      AppLogger.success(_tag, 'Route deviation handled');
      return rerouting;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to handle route deviation', e, stackTrace);
      rethrow;
    }
  }

  /// Provide points of interest along route
  static Future<List<Map<String, dynamic>>> getPointsOfInterest({
    required String sessionId,
    required Map<String, double> currentLocation,
    double radiusKm = 5.0,
    List<String>? categories,
  }) async {
    try {
      AppLogger.debug(_tag, 'Getting points of interest for session: $sessionId');

      // Build POI prompt
      final prompt = _buildPOIPrompt(
        currentLocation,
        radiusKm,
        categories,
      );

      // Get AI POI suggestions
      final aiResponse = await GeminiService.generateContent(
        prompt: prompt,
        model: GeminiService.modelFlash,
        temperature: 0.7,
        maxOutputTokens: 2048,
      );

      // Parse POI response
      final pointsOfInterest = _parsePOIResponse(aiResponse);

      // Log POI event
      await _logNavigationEvent(
        sessionId,
        eventPointOfInterest,
        {
          'current_location': currentLocation,
          'radius_km': radiusKm,
          'categories': categories,
          'found_pois': pointsOfInterest.length,
        },
      );

      AppLogger.success(_tag, 'Found ${pointsOfInterest.length} points of interest');
      return pointsOfInterest;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get points of interest', e, stackTrace);
      return [];
    }
  }

  // ===============================
  // TRAFFIC & HAZARD ALERTS
  // ===============================

  /// Get traffic updates and alerts
  static Future<Map<String, dynamic>> getTrafficUpdates({
    required String sessionId,
    required Map<String, double> currentLocation,
    String? routeAhead,
  }) async {
    try {
      AppLogger.debug(_tag, 'Getting traffic updates for session: $sessionId');

      // Build traffic analysis prompt
      final prompt = _buildTrafficAnalysisPrompt(
        currentLocation,
        routeAhead,
      );

      // Get AI traffic analysis
      final aiResponse = await GeminiService.generateContent(
        prompt: prompt,
        model: GeminiService.modelFlash,
        temperature: 0.4,
        maxOutputTokens: 1024,
      );

      // Parse traffic updates
      final trafficUpdates = _parseTrafficUpdates(aiResponse);

      // Log traffic event
      await _logNavigationEvent(
        sessionId,
        eventTrafficUpdate,
        {
          'current_location': currentLocation,
          'traffic_updates': trafficUpdates,
        },
      );

      AppLogger.success(_tag, 'Traffic updates retrieved');
      return trafficUpdates;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get traffic updates', e, stackTrace);
      return {};
    }
  }

  /// Report and analyze hazards
  static Future<Map<String, dynamic>> reportHazard({
    required String sessionId,
    required Map<String, double> location,
    required String hazardType,
    String? description,
    String? severity,
  }) async {
    try {
      AppLogger.debug(_tag, 'Reporting hazard for session: $sessionId');

      // Build hazard analysis prompt
      final prompt = _buildHazardAnalysisPrompt(
        location,
        hazardType,
        description,
        severity,
      );

      // Get AI hazard analysis
      final aiResponse = await GeminiService.generateContent(
        prompt: prompt,
        model: GeminiService.modelFlash,
        temperature: 0.3,
        maxOutputTokens: 512,
      );

      // Parse hazard analysis
      final hazardAnalysis = _parseHazardAnalysis(aiResponse);

      // Log hazard event
      await _logNavigationEvent(
        sessionId,
        eventHazardAlert,
        {
          'location': location,
          'hazard_type': hazardType,
          'description': description,
          'severity': severity,
          'analysis': hazardAnalysis,
        },
      );

      AppLogger.success(_tag, 'Hazard reported and analyzed');
      return hazardAnalysis;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to report hazard', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // SESSION MANAGEMENT
  // ===============================

  /// End navigation session
  static Future<Map<String, dynamic>> endNavigationSession({
    required String sessionId,
    String? endReason,
    Map<String, dynamic>? finalLocation,
  }) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.debug(_tag, 'Ending navigation session: $sessionId');

      // Update session status
      await SupabaseDatabaseService.update(
        table: _navigationSessionsTable,
        id: sessionId,
        data: {
          'status': statusCompleted,
          'end_time': DateTime.now().toIso8601String(),
          'end_reason': endReason ?? 'completed',
          'final_location': finalLocation ?? {},
          'updated_at': DateTime.now().toIso8601String(),
        },
      );

      // Generate session summary
      final summary = await _generateSessionSummary(sessionId);

      // Log session end event
      await _logNavigationEvent(
        sessionId,
        'session_ended',
        {
          'end_reason': endReason,
          'final_location': finalLocation,
          'summary': summary,
        },
      );

      AppLogger.success(_tag, 'Navigation session ended');
      return summary;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to end navigation session', e, stackTrace);
      rethrow;
    }
  }

  /// Get user's navigation history
  static Future<List<Map<String, dynamic>>> getNavigationHistory({
    String? userId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final targetUserId = userId ?? SupabaseConfig.userId;
      if (targetUserId == null) {
        throw Exception('No user ID provided');
      }

      AppLogger.debug(_tag, 'Getting navigation history for user: $targetUserId');

      final sessions = await SupabaseDatabaseService.select(
        table: _navigationSessionsTable,
        filters: {'user_id': targetUserId},
        orderBy: 'created_at',
        ascending: false,
        limit: limit,
        offset: offset,
      );

      // Enrich with additional data
      for (final session in sessions) {
        await _enrichNavigationSessionData(session);
      }

      AppLogger.success(_tag, 'Retrieved ${sessions.length} navigation sessions');
      return sessions;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get navigation history', e, stackTrace);
      return [];
    }
  }

  // ===============================
  // ANALYTICS & INSIGHTS
  // ===============================

  /// Generate navigation insights
  static Future<Map<String, dynamic>> generateNavigationInsights([String? userId]) async {
    try {
      final targetUserId = userId ?? SupabaseConfig.userId;
      if (targetUserId == null) {
        throw Exception('No user ID provided');
      }

      AppLogger.debug(_tag, 'Generating navigation insights for user: $targetUserId');

      // Get user's navigation data
      final sessions = await SupabaseDatabaseService.select(
        table: _navigationSessionsTable,
        filters: {'user_id': targetUserId},
      );

      final events = await SupabaseDatabaseService.select(
        table: _navigationEventsTable,
        filters: {'user_id': targetUserId},
      );

      // Build insights prompt
      final prompt = _buildInsightsPrompt(sessions, events);

      // Get AI insights
      final aiResponse = await GeminiService.generateContent(
        prompt: prompt,
        model: GeminiService.modelPro,
        temperature: 0.6,
        maxOutputTokens: 2048,
      );

      // Parse insights
      final insights = _parseNavigationInsights(aiResponse);

      // Save insights
      await _saveNavigationInsights(targetUserId, insights, aiResponse);

      AppLogger.success(_tag, 'Navigation insights generated');
      return insights;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to generate navigation insights', e, stackTrace);
      return {};
    }
  }

  // ===============================
  // PRIVATE HELPER METHODS
  // ===============================

  /// Get navigation session by ID
  static Future<Map<String, dynamic>?> _getNavigationSession(String sessionId) async {
    try {
      final sessions = await SupabaseDatabaseService.select(
        table: _navigationSessionsTable,
        filters: {'id': sessionId},
      );

      return sessions.isNotEmpty ? sessions.first : null;
    } catch (e) {
      return null;
    }
  }

  /// Log navigation event
  static Future<void> _logNavigationEvent(
    String sessionId,
    String eventType,
    Map<String, dynamic> eventData,
  ) async {
    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) return;

      await SupabaseDatabaseService.insert(
        table: _navigationEventsTable,
        data: {
          'session_id': sessionId,
          'user_id': userId,
          'event_type': eventType,
          'event_data': eventData,
          'timestamp': DateTime.now().toIso8601String(),
          'created_at': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to log navigation event', e);
    }
  }

  /// Generate initial navigation guidance
  static Future<Map<String, dynamic>> _generateNavigationGuidance(
    String sessionId,
    String origin,
    String destination,
    String navigationMode,
    Map<String, dynamic>? routePlan,
  ) async {
    try {
      final prompt = '''
Provide initial navigation guidance for travel from $origin to $destination.

Navigation Mode: $navigationMode
Route Plan: ${jsonEncode(routePlan ?? {})}

Provide guidance in JSON format:
{
  "initial_instruction": "Turn right from your current location",
  "estimated_arrival": "14:30",
  "total_distance": "12.5 km",
  "total_duration": "25 minutes",
  "next_maneuver": "In 500m, turn left onto Jalan Sudirman",
  "route_overview": "Main route via toll road",
  "traffic_status": "Light traffic",
  "alternative_routes": ["Via city center", "Via bypass"]
}
''';

      final aiResponse = await GeminiService.generateContent(
        prompt: prompt,
        model: GeminiService.modelFlash,
        temperature: 0.4,
        maxOutputTokens: 1024,
      );

      return _parseNavigationGuidance(aiResponse);
    } catch (e) {
      AppLogger.warning(_tag, 'Failed to generate initial guidance', e);
      return {
        'initial_instruction': 'Navigate to destination',
        'estimated_arrival': 'Unknown',
        'status': 'guidance_generation_failed',
      };
    }
  }

  /// Build navigation assistance prompt
  static String _buildNavigationAssistancePrompt(
    Map<String, dynamic> session,
    Map<String, double> currentLocation,
    String? currentHeading,
    double? currentSpeed,
    Map<String, dynamic>? contextData,
  ) {
    return '''
Provide real-time navigation assistance for ongoing trip.

Session: ${session['origin']} to ${session['destination']}
Current Location: ${currentLocation['lat']}, ${currentLocation['lng']}
Heading: ${currentHeading ?? 'Unknown'}
Speed: ${currentSpeed ?? 0} km/h
Mode: ${session['navigation_mode']}

Context: ${jsonEncode(contextData ?? {})}

Provide assistance in JSON format with next instruction, distance to turn, estimated arrival time.
''';
  }

  /// Parse navigation assistance
  static Map<String, dynamic> _parseNavigationAssistance(String aiResponse) {
    try {
      final jsonStart = aiResponse.indexOf('{');
      final jsonEnd = aiResponse.lastIndexOf('}') + 1;
      
      if (jsonStart >= 0 && jsonEnd > jsonStart) {
        final jsonString = aiResponse.substring(jsonStart, jsonEnd);
        return jsonDecode(jsonString) as Map<String, dynamic>;
      }
      
      return {
        'instruction': 'Continue straight',
        'distance_to_next': 'Unknown',
        'estimated_arrival': 'Calculating...',
      };
    } catch (e) {
      return {
        'instruction': 'Continue on current route',
        'status': 'parsing_failed',
      };
    }
  }

  /// Parse navigation guidance
  static Map<String, dynamic> _parseNavigationGuidance(String aiResponse) {
    return _parseNavigationAssistance(aiResponse);
  }

  /// Other placeholder helper methods...
  static String _buildReroutingPrompt(Map<String, dynamic> session, Map<String, double> currentLocation, String deviationReason) => '';
  static String _buildPOIPrompt(Map<String, double> currentLocation, double radiusKm, List<String>? categories) => '';
  static String _buildTrafficAnalysisPrompt(Map<String, double> currentLocation, String? routeAhead) => '';
  static String _buildHazardAnalysisPrompt(Map<String, double> location, String hazardType, String? description, String? severity) => '';
  static String _buildInsightsPrompt(List<Map<String, dynamic>> sessions, List<Map<String, dynamic>> events) => '';

  static Map<String, dynamic> _parseReroutingResponse(String aiResponse) => {};
  static List<Map<String, dynamic>> _parsePOIResponse(String aiResponse) => [];
  static Map<String, dynamic> _parseTrafficUpdates(String aiResponse) => {};
  static Map<String, dynamic> _parseHazardAnalysis(String aiResponse) => {};
  static Map<String, dynamic> _parseNavigationInsights(String aiResponse) => {};

  static Future<Map<String, dynamic>> _generateSessionSummary(String sessionId) async => {};
  static Future<void> _enrichNavigationSessionData(Map<String, dynamic> session) async {}
  static Future<void> _saveNavigationInsights(String userId, Map<String, dynamic> insights, String aiResponse) async {}
}
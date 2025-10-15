/// Navigation models for AI-powered navigation features
library navigation_models;

import 'route_model.dart';

/// Represents a real-time navigation update
class NavigationUpdate {
  final RouteLocation currentPosition;
  final RouteStep currentStep;
  final int stepIndex;
  final int totalSteps;
  final double distanceToNextStep;
  final double currentSpeed;
  final double bearing;
  final DateTime estimatedTimeArrival;
  final Map<String, dynamic>? additionalData;

  const NavigationUpdate({
    required this.currentPosition,
    required this.currentStep,
    required this.stepIndex,
    required this.totalSteps,
    required this.distanceToNextStep,
    required this.currentSpeed,
    required this.bearing,
    required this.estimatedTimeArrival,
    this.additionalData,
  });

  factory NavigationUpdate.fromMap(Map<String, dynamic> map) {
    return NavigationUpdate(
      currentPosition: RouteLocation.fromMap(map['current_position'] ?? {}),
      currentStep: RouteStep.fromMap(map['current_step'] ?? {}),
      stepIndex: map['step_index'] ?? 0,
      totalSteps: map['total_steps'] ?? 0,
      distanceToNextStep: map['distance_to_next_step']?.toDouble() ?? 0.0,
      currentSpeed: map['current_speed']?.toDouble() ?? 0.0,
      bearing: map['bearing']?.toDouble() ?? 0.0,
      estimatedTimeArrival: DateTime.parse(
        map['estimated_time_arrival'] ?? DateTime.now().toIso8601String(),
      ),
      additionalData: map['additional_data'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'current_position': currentPosition.toMap(),
      'current_step': currentStep.toMap(),
      'step_index': stepIndex,
      'total_steps': totalSteps,
      'distance_to_next_step': distanceToNextStep,
      'current_speed': currentSpeed,
      'bearing': bearing,
      'estimated_time_arrival': estimatedTimeArrival.toIso8601String(),
      'additional_data': additionalData,
    };
  }
}

/// AI navigation suggestion model
class AINavigationSuggestion {
  final String id;
  final String title;
  final String description;
  final String category;
  final int priority;
  final DateTime timestamp;
  final RouteLocation? location;
  final Map<String, dynamic>? actionData;

  const AINavigationSuggestion({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.timestamp,
    this.location,
    this.actionData,
  });

  factory AINavigationSuggestion.fromMap(Map<String, dynamic> map) {
    return AINavigationSuggestion(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? 'general',
      priority: map['priority'] ?? 0,
      timestamp: DateTime.parse(
        map['timestamp'] ?? DateTime.now().toIso8601String(),
      ),
      location: map['location'] != null 
          ? RouteLocation.fromMap(map['location']) 
          : null,
      actionData: map['action_data'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'priority': priority,
      'timestamp': timestamp.toIso8601String(),
      'location': location?.toMap(),
      'action_data': actionData,
    };
  }
}
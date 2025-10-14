/// Budget-related AI models
/// This file contains model classes for budget optimization and financial planning
library budget_ai_models;

/// Budget Optimization Result
class BudgetOptimizationResult {
  final String id;
  final String tripId;
  final Map<String, dynamic> originalBudget;
  final Map<String, dynamic> optimizedBudget;
  final double totalSavings;
  final double savingsPercentage;
  final List<String> optimizationStrategies;
  final Map<String, dynamic> categoryBreakdown;
  final DateTime generatedAt;
  
  // Additional properties needed by UI
  final double totalBudget;
  final double dailyBudget;
  final BudgetAssessment assessment;
  final List<BudgetCategory> categories;

  const BudgetOptimizationResult({
    required this.id,
    required this.tripId,
    required this.originalBudget,
    required this.optimizedBudget,
    required this.totalSavings,
    required this.savingsPercentage,
    required this.optimizationStrategies,
    required this.categoryBreakdown,
    required this.generatedAt,
    required this.totalBudget,
    required this.dailyBudget,
    required this.assessment,
    required this.categories,
  });

  factory BudgetOptimizationResult.fromMap(Map<String, dynamic> map) {
    return BudgetOptimizationResult(
      id: map['id'] ?? '',
      tripId: map['trip_id'] ?? '',
      originalBudget: Map<String, dynamic>.from(map['original_budget'] ?? {}),
      optimizedBudget: Map<String, dynamic>.from(map['optimized_budget'] ?? {}),
      totalSavings: map['total_savings']?.toDouble() ?? 0.0,
      savingsPercentage: map['savings_percentage']?.toDouble() ?? 0.0,
      optimizationStrategies: List<String>.from(map['optimization_strategies'] ?? []),
      categoryBreakdown: Map<String, dynamic>.from(map['category_breakdown'] ?? {}),
      generatedAt: DateTime.parse(map['generated_at'] ?? DateTime.now().toIso8601String()),
      totalBudget: map['total_budget']?.toDouble() ?? 0.0,
      dailyBudget: map['daily_budget']?.toDouble() ?? 0.0,
      assessment: BudgetAssessment.fromMap(map['assessment'] ?? {}),
      categories: (map['categories'] as List<dynamic>?)
          ?.map((cat) => BudgetCategory.fromMap(cat))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'trip_id': tripId,
      'original_budget': originalBudget,
      'optimized_budget': optimizedBudget,
      'total_savings': totalSavings,
      'savings_percentage': savingsPercentage,
      'optimization_strategies': optimizationStrategies,
      'category_breakdown': categoryBreakdown,
      'generated_at': generatedAt.toIso8601String(),
      'total_budget': totalBudget,
      'daily_budget': dailyBudget,
      'assessment': assessment.toMap(),
      'categories': categories.map((cat) => cat.toMap()).toList(),
    };
  }
}

/// Budget Assessment  
class BudgetAssessment {
  final String level;
  final String description;

  const BudgetAssessment({
    required this.level,
    required this.description,
  });

  factory BudgetAssessment.fromMap(Map<String, dynamic> map) {
    return BudgetAssessment(
      level: map['level'] ?? 'Good',
      description: map['description'] ?? 'Budget looks balanced',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'level': level,
      'description': description,
    };
  }
}

/// Budget Category
class BudgetCategory {
  final String name;
  final double allocatedAmount;
  final String description;
  final double percentage;
  final double totalAmount;

  const BudgetCategory({
    required this.name,
    required this.allocatedAmount,
    required this.description,
    required this.percentage,
    required this.totalAmount,
  });

  factory BudgetCategory.fromMap(Map<String, dynamic> map) {
    return BudgetCategory(
      name: map['name'] ?? '',
      allocatedAmount: map['allocated_amount']?.toDouble() ?? 0.0,
      description: map['description'] ?? '',
      percentage: map['percentage']?.toDouble() ?? 0.0,
      totalAmount: map['total_amount']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'allocated_amount': allocatedAmount,
      'description': description,
      'percentage': percentage,
      'total_amount': totalAmount,
    };
  }
}

/// Spending Recommendation
class SpendingRecommendation {
  final String id;
  final String category;
  final String recommendation;
  final String reason;
  final double currentAmount;
  final double recommendedAmount;
  final double potentialSavings;
  final int priority;
  final List<String> actionItems;
  
  // Additional properties needed by UI
  final String status;
  final String message;
  final double remainingDailyBudget;

  const SpendingRecommendation({
    required this.id,
    required this.category,
    required this.recommendation,
    required this.reason,
    required this.currentAmount,
    required this.recommendedAmount,
    required this.potentialSavings,
    required this.priority,
    required this.actionItems,
    required this.status,
    required this.message,
    required this.remainingDailyBudget,
  });

  factory SpendingRecommendation.fromMap(Map<String, dynamic> map) {
    return SpendingRecommendation(
      id: map['id'] ?? '',
      category: map['category'] ?? '',
      recommendation: map['recommendation'] ?? '',
      reason: map['reason'] ?? '',
      currentAmount: map['current_amount']?.toDouble() ?? 0.0,
      recommendedAmount: map['recommended_amount']?.toDouble() ?? 0.0,
      potentialSavings: map['potential_savings']?.toDouble() ?? 0.0,
      priority: map['priority'] ?? 0,
      actionItems: List<String>.from(map['action_items'] ?? []),
      status: map['status'] ?? 'on_track',
      message: map['message'] ?? '',
      remainingDailyBudget: map['remaining_daily_budget']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'recommendation': recommendation,
      'reason': reason,
      'current_amount': currentAmount,
      'recommended_amount': recommendedAmount,
      'potential_savings': potentialSavings,
      'priority': priority,
      'action_items': actionItems,
      'status': status,
      'message': message,
      'remaining_daily_budget': remainingDailyBudget,
    };
  }
}

/// Budget Health Report
class BudgetHealthReport {
  final String id;
  final String tripId;
  final double healthScore;
  final String healthStatus;
  final Map<String, dynamic> categoryAnalysis;
  final List<String> riskFactors;
  final List<String> strengths;
  final List<String> recommendations;
  final DateTime analyzedAt;
  
  // Additional properties needed by UI
  final String status;
  final String analysis;
  final String color;
  final List<CategoryHealth> categoryHealth;

  const BudgetHealthReport({
    required this.id,
    required this.tripId,
    required this.healthScore,
    required this.healthStatus,
    required this.categoryAnalysis,
    required this.riskFactors,
    required this.strengths,
    required this.recommendations,
    required this.analyzedAt,
    required this.status,
    required this.analysis,
    required this.color,
    required this.categoryHealth,
  });

  factory BudgetHealthReport.fromMap(Map<String, dynamic> map) {
    return BudgetHealthReport(
      id: map['id'] ?? '',
      tripId: map['trip_id'] ?? '',
      healthScore: map['health_score']?.toDouble() ?? 0.0,
      healthStatus: map['health_status'] ?? '',
      categoryAnalysis: Map<String, dynamic>.from(map['category_analysis'] ?? {}),
      riskFactors: List<String>.from(map['risk_factors'] ?? []),
      strengths: List<String>.from(map['strengths'] ?? []),
      recommendations: List<String>.from(map['recommendations'] ?? []),
      analyzedAt: DateTime.parse(map['analyzed_at'] ?? DateTime.now().toIso8601String()),
      status: map['status'] ?? 'Good',
      analysis: map['analysis'] ?? '',
      color: map['color'] ?? 'green',
      categoryHealth: (map['category_health'] as List<dynamic>?)
          ?.map((ch) => CategoryHealth.fromMap(ch))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'trip_id': tripId,
      'health_score': healthScore,
      'health_status': healthStatus,
      'category_analysis': categoryAnalysis,
      'risk_factors': riskFactors,
      'strengths': strengths,
      'recommendations': recommendations,
      'analyzed_at': analyzedAt.toIso8601String(),
      'status': status,
      'analysis': analysis,
      'color': color,
      'category_health': categoryHealth.map((ch) => ch.toMap()).toList(),
    };
  }
}

/// Category Health
class CategoryHealth {
  final String category;
  final String status;
  final double spent;
  final double budget;
  final String recommendation;
  final String message;

  const CategoryHealth({
    required this.category,
    required this.status,
    required this.spent,
    required this.budget,
    required this.recommendation,
    required this.message,
  });

  factory CategoryHealth.fromMap(Map<String, dynamic> map) {
    return CategoryHealth(
      category: map['category'] ?? '',
      status: map['status'] ?? '',
      spent: map['spent']?.toDouble() ?? 0.0,
      budget: map['budget']?.toDouble() ?? 0.0,
      recommendation: map['recommendation'] ?? '',
      message: map['message'] ?? map['recommendation'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'status': status,
      'spent': spent,
      'budget': budget,
      'recommendation': recommendation,
      'message': message,
    };
  }
}

/// Money Saving Tip
class MoneySavingTip {
  final String id;
  final String title;
  final String description;
  final String category;
  final String priority;
  final String potentialSavings;
  final String difficulty;
  final List<String> tags;
  final String actionUrl;

  const MoneySavingTip({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.potentialSavings,
    required this.difficulty,
    required this.tags,
    required this.actionUrl,
  });

  factory MoneySavingTip.fromMap(Map<String, dynamic> map) {
    return MoneySavingTip(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      priority: map['priority'] ?? '',
      potentialSavings: map['potential_savings'] ?? '',
      difficulty: map['difficulty'] ?? '',
      tags: List<String>.from(map['tags'] ?? []),
      actionUrl: map['action_url'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'priority': priority,
      'potential_savings': potentialSavings,
      'difficulty': difficulty,
      'tags': tags,
      'action_url': actionUrl,
    };
  }
}
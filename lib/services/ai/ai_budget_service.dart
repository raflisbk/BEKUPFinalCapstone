import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/trip_model.dart' as trip_models;
import 'gemini_service.dart';

/// Service for AI-powered budget optimization
class AIBudgetService {
  final GeminiService _geminiService = GeminiService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Generate optimized budget allocation
  Future<BudgetOptimizationResult> optimizeBudget({
    required trip_models.Trip trip,
    required double totalBudget,
  }) async {
    try {
      final prompt = _buildOptimizationPrompt(trip, totalBudget);
      final response = await _geminiService.generateJSON(prompt);

      final result = BudgetOptimizationResult.fromJson(response);

      // Save recommendation
      await _saveBudgetRecommendation(trip.id, result);

      return result;
    } catch (e) {
      print('Error optimizing budget: $e');
      rethrow;
    }
  }

  /// Get spending recommendations based on current expenses
  Future<SpendingRecommendation> getSpendingRecommendation({
    required trip_models.Trip trip,
  }) async {
    try {
      final prompt = _buildSpendingPrompt(trip);
      final response = await _geminiService.generateJSON(prompt);

      return SpendingRecommendation.fromJson(response);
    } catch (e) {
      print('Error getting spending recommendation: $e');
      rethrow;
    }
  }

  /// Analyze budget health
  Future<BudgetHealthReport> analyzeBudgetHealth({
    required trip_models.Trip trip,
  }) async {
    try {
      final prompt = _buildHealthPrompt(trip);
      final response = await _geminiService.generateJSON(prompt);

      return BudgetHealthReport.fromJson(response);
    } catch (e) {
      print('Error analyzing budget health: $e');
      rethrow;
    }
  }

  /// Get money-saving tips
  Future<List<MoneySavingTip>> getMoneySavingTips({
    required String destination,
    required double dailyBudget,
  }) async {
    try {
      final prompt = '''
Provide practical money-saving tips for travelers visiting $destination with a daily budget of \$${dailyBudget.toStringAsFixed(0)}.

Give 8-10 specific, actionable tips covering:
- Accommodation (cheaper options, booking strategies)
- Food (local eateries, markets, avoiding tourist traps)
- Transportation (public transport, walking, bike rentals)
- Activities (free attractions, discount passes)
- Shopping (best places, bargaining tips)
- Communication (SIM cards, WiFi options)
- Timing (off-season travel, booking in advance)

Return ONLY valid JSON:
{
  "tips": [
    {
      "category": "Accommodation",
      "title": "Book hostels or guesthouses",
      "description": "Save 40-60% compared to hotels",
      "potentialSavings": "30-50 dollars per night",
      "priority": "high"
    }
  ]
}
''';

      final response = await _geminiService.generateJSON(prompt);
      
      final tips = (response['tips'] as List)
          .map((t) => MoneySavingTip.fromJson(t))
          .toList();

      return tips;
    } catch (e) {
      print('Error getting money-saving tips: $e');
      rethrow;
    }
  }

  /// Build optimization prompt
  String _buildOptimizationPrompt(trip_models.Trip trip, double totalBudget) {
    final destinations = trip.destinations.map((d) => d.name).join(', ');
    final duration = trip.endDate.difference(trip.startDate).inDays + 1;
    final dailyBudget = totalBudget / duration;
    final participants = trip.participantIds.length;

    return '''
Create an optimized budget allocation for a trip with these details:

TRIP DETAILS:
- Destinations: $destinations
- Duration: $duration days
- Total Budget: \$${totalBudget.toStringAsFixed(0)}
- Daily Budget: \$${dailyBudget.toStringAsFixed(0)}
- Travelers: $participants people

TASK:
Allocate the budget across these categories with smart recommendations:
1. Accommodation (% and amount)
2. Food & Dining (% and amount)
3. Transportation (% and amount)
4. Activities & Attractions (% and amount)
5. Shopping & Souvenirs (% and amount)
6. Emergency & Miscellaneous (% and amount)

Consider:
- Destination cost of living
- Duration of stay
- Number of travelers
- Typical expenses for each category
- Buffer for unexpected costs

For each category provide:
- Percentage of total budget
- Total amount
- Daily amount
- Breakdown (e.g., accommodation: amount per night)
- Tips to stay within budget
- Warning if allocation seems too low

Also provide:
- Overall budget assessment (tight/comfortable/generous)
- Key recommendations
- Potential cost-saving opportunities
- Items to prioritize

Return ONLY valid JSON matching this structure:
{
  "totalBudget": $totalBudget,
  "dailyBudget": $dailyBudget,
  "categories": [
    {
      "name": "Accommodation",
      "percentage": 30,
      "totalAmount": 600,
      "dailyAmount": 100,
      "breakdown": "100 dollars per night for mid-range hotel",
      "tips": ["Book in advance for better rates", "Consider hostels to save 50%"],
      "warning": null
    }
  ],
  "assessment": {
    "level": "comfortable",
    "description": "Your budget allows for a comfortable trip with some flexibility"
  },
  "recommendations": [
    "Book accommodation early to secure best prices",
    "Allocate 20% more to activities for better experiences"
  ],
  "costSavingOpportunities": [
    "Use public transport instead of taxis (save 200 dollars)",
    "Eat at local restaurants (save 150 dollars)"
  ],
  "priorities": ["Secure accommodation first", "Book popular activities in advance"]
}
''';
  }

  /// Build spending prompt
  String _buildSpendingPrompt(trip_models.Trip trip) {
    final budget = trip.budget;
    final spent = trip.expenses.fold<double>(
      0,
      (sum, expense) => sum + expense.amount,
    );
    final remaining = (budget?.totalBudget ?? 0) - spent;
    final daysLeft = trip.endDate.difference(DateTime.now()).inDays;

    return '''
Analyze spending patterns and provide recommendations:

BUDGET STATUS:
- Total Budget: \$${budget?.totalBudget ?? 0}
- Spent So Far: \$${spent.toStringAsFixed(0)}
- Remaining: \$${remaining.toStringAsFixed(0)}
- Days Left: $daysLeft

EXPENSES BY CATEGORY:
${_getExpensesByCategory(trip.expenses)}

TASK:
Analyze the spending and provide:
1. Spending pace (on track/overspending/underspending)
2. Daily budget for remaining days
3. Categories to reduce spending in
4. Categories where you can splurge
5. Specific action items
6. Alerts if running out of money

Return ONLY valid JSON:
{
  "status": "on_track",
  "remainingDailyBudget": 85,
  "message": "You're spending at a good pace",
  "reduceSpending": ["Transportation", "Dining"],
  "canSplurge": ["Activities"],
  "actionItems": [
    "Switch to public transport to save 20 dollars per day",
    "Try local eateries instead of restaurants"
  ],
  "alerts": [],
  "projectedTotal": 950
}
''';
  }

  /// Build health prompt
  String _buildHealthPrompt(trip_models.Trip trip) {
    final budget = trip.budget;
    final spent = trip.expenses.fold<double>(
      0,
      (sum, expense) => sum + expense.amount,
    );
    final percentage = budget != null && budget.totalBudget > 0
        ? (spent / budget.totalBudget * 100)
        : 0;

    return '''
Analyze budget health and provide a comprehensive report:

BUDGET OVERVIEW:
- Total Budget: \$${budget?.totalBudget ?? 0}
- Spent: \$${spent.toStringAsFixed(0)} (${percentage.toStringAsFixed(1)}%)
- Remaining: \$${(budget?.totalBudget ?? 0) - spent}

EXPENSES:
${_getExpensesByCategory(trip.expenses)}

Provide:
1. Health score (0-100)
2. Health status (Excellent/Good/Warning/Critical)
3. Visual indicator (color: green/yellow/orange/red)
4. Detailed analysis
5. Spending trends
6. Category breakdown
7. Recommendations
8. Risk factors

Return ONLY valid JSON:
{
  "healthScore": 85,
  "status": "Good",
  "color": "green",
  "summary": "Budget is healthy with controlled spending",
  "analysis": "You've spent 45% of budget with 60% of trip remaining, which is excellent",
  "trends": [
    "Accommodation spending is higher than recommended",
    "Food expenses are well-managed"
  ],
  "categoryHealth": [
    {
      "category": "Accommodation",
      "status": "Warning",
      "message": "Spending 35% vs recommended 30%"
    }
  ],
  "recommendations": [
    "Continue current spending pace",
    "Consider cheaper accommodation options"
  ],
  "riskFactors": []
}
''';
  }

  /// Get expenses grouped by category
  String _getExpensesByCategory(List<trip_models.BudgetExpense> expenses) {
    final categoryMap = <trip_models.BudgetCategory, double>{};
    
    for (final expense in expenses) {
      categoryMap[expense.category] = 
          (categoryMap[expense.category] ?? 0) + expense.amount;
    }

    return categoryMap.entries
        .map((e) => '- ${e.key.name}: \$${e.value.toStringAsFixed(0)}')
        .join('\n');
  }

  /// Save budget recommendation
  Future<void> _saveBudgetRecommendation(
    String tripId,
    BudgetOptimizationResult result,
  ) async {
    try {
      await _firestore
          .collection('budget_recommendations')
          .doc(tripId)
          .set({
        'result': result.toJson(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving budget recommendation: $e');
    }
  }
}

/// Budget optimization result
class BudgetOptimizationResult {
  final double totalBudget;
  final double dailyBudget;
  final List<BudgetCategory> categories;
  final BudgetAssessment assessment;
  final List<String> recommendations;
  final List<String> costSavingOpportunities;
  final List<String> priorities;

  BudgetOptimizationResult({
    required this.totalBudget,
    required this.dailyBudget,
    required this.categories,
    required this.assessment,
    required this.recommendations,
    required this.costSavingOpportunities,
    required this.priorities,
  });

  factory BudgetOptimizationResult.fromJson(Map<String, dynamic> json) {
    return BudgetOptimizationResult(
      totalBudget: (json['totalBudget'] as num).toDouble(),
      dailyBudget: (json['dailyBudget'] as num).toDouble(),
      categories: (json['categories'] as List)
          .map((c) => BudgetCategory.fromJson(c))
          .toList(),
      assessment: BudgetAssessment.fromJson(json['assessment']),
      recommendations: List<String>.from(json['recommendations'] ?? []),
      costSavingOpportunities:
          List<String>.from(json['costSavingOpportunities'] ?? []),
      priorities: List<String>.from(json['priorities'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
        'totalBudget': totalBudget,
        'dailyBudget': dailyBudget,
        'categories': categories.map((c) => c.toJson()).toList(),
        'assessment': assessment.toJson(),
        'recommendations': recommendations,
        'costSavingOpportunities': costSavingOpportunities,
        'priorities': priorities,
      };
}

/// Budget category allocation
class BudgetCategory {
  final String name;
  final int percentage;
  final double totalAmount;
  final double dailyAmount;
  final String breakdown;
  final List<String> tips;
  final String? warning;

  BudgetCategory({
    required this.name,
    required this.percentage,
    required this.totalAmount,
    required this.dailyAmount,
    required this.breakdown,
    required this.tips,
    this.warning,
  });

  factory BudgetCategory.fromJson(Map<String, dynamic> json) {
    return BudgetCategory(
      name: json['name'] ?? '',
      percentage: json['percentage'] ?? 0,
      totalAmount: (json['totalAmount'] as num).toDouble(),
      dailyAmount: (json['dailyAmount'] as num).toDouble(),
      breakdown: json['breakdown'] ?? '',
      tips: List<String>.from(json['tips'] ?? []),
      warning: json['warning'],
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'percentage': percentage,
        'totalAmount': totalAmount,
        'dailyAmount': dailyAmount,
        'breakdown': breakdown,
        'tips': tips,
        'warning': warning,
      };
}

/// Budget assessment
class BudgetAssessment {
  final String level;
  final String description;

  BudgetAssessment({
    required this.level,
    required this.description,
  });

  factory BudgetAssessment.fromJson(Map<String, dynamic> json) {
    return BudgetAssessment(
      level: json['level'] ?? '',
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'level': level,
        'description': description,
      };
}

/// Spending recommendation
class SpendingRecommendation {
  final String status;
  final double remainingDailyBudget;
  final String message;
  final List<String> reduceSpending;
  final List<String> canSplurge;
  final List<String> actionItems;
  final List<String> alerts;
  final double projectedTotal;

  SpendingRecommendation({
    required this.status,
    required this.remainingDailyBudget,
    required this.message,
    required this.reduceSpending,
    required this.canSplurge,
    required this.actionItems,
    required this.alerts,
    required this.projectedTotal,
  });

  factory SpendingRecommendation.fromJson(Map<String, dynamic> json) {
    return SpendingRecommendation(
      status: json['status'] ?? '',
      remainingDailyBudget: (json['remainingDailyBudget'] as num).toDouble(),
      message: json['message'] ?? '',
      reduceSpending: List<String>.from(json['reduceSpending'] ?? []),
      canSplurge: List<String>.from(json['canSplurge'] ?? []),
      actionItems: List<String>.from(json['actionItems'] ?? []),
      alerts: List<String>.from(json['alerts'] ?? []),
      projectedTotal: (json['projectedTotal'] as num).toDouble(),
    );
  }
}

/// Budget health report
class BudgetHealthReport {
  final int healthScore;
  final String status;
  final String color;
  final String summary;
  final String analysis;
  final List<String> trends;
  final List<CategoryHealth> categoryHealth;
  final List<String> recommendations;
  final List<String> riskFactors;

  BudgetHealthReport({
    required this.healthScore,
    required this.status,
    required this.color,
    required this.summary,
    required this.analysis,
    required this.trends,
    required this.categoryHealth,
    required this.recommendations,
    required this.riskFactors,
  });

  factory BudgetHealthReport.fromJson(Map<String, dynamic> json) {
    return BudgetHealthReport(
      healthScore: json['healthScore'] ?? 0,
      status: json['status'] ?? '',
      color: json['color'] ?? '',
      summary: json['summary'] ?? '',
      analysis: json['analysis'] ?? '',
      trends: List<String>.from(json['trends'] ?? []),
      categoryHealth: (json['categoryHealth'] as List? ?? [])
          .map((c) => CategoryHealth.fromJson(c))
          .toList(),
      recommendations: List<String>.from(json['recommendations'] ?? []),
      riskFactors: List<String>.from(json['riskFactors'] ?? []),
    );
  }
}

/// Category health status
class CategoryHealth {
  final String category;
  final String status;
  final String message;

  CategoryHealth({
    required this.category,
    required this.status,
    required this.message,
  });

  factory CategoryHealth.fromJson(Map<String, dynamic> json) {
    return CategoryHealth(
      category: json['category'] ?? '',
      status: json['status'] ?? '',
      message: json['message'] ?? '',
    );
  }
}

/// Money-saving tip
class MoneySavingTip {
  final String category;
  final String title;
  final String description;
  final String potentialSavings;
  final String priority;

  MoneySavingTip({
    required this.category,
    required this.title,
    required this.description,
    required this.potentialSavings,
    required this.priority,
  });

  factory MoneySavingTip.fromJson(Map<String, dynamic> json) {
    return MoneySavingTip(
      category: json['category'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      potentialSavings: json['potentialSavings'] ?? '',
      priority: json['priority'] ?? '',
    );
  }
}

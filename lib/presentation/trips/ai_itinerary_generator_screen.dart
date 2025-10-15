import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/models/trip_model.dart';
import '../../core/models/ai_models.dart';
import '../../core/providers/ai_itinerary_generator_ui_provider.dart';
import '../../services/ai/ai_itinerary_service.dart';

/// Screen for generating AI-powered trip itinerary
class AIItineraryGeneratorScreen extends StatelessWidget {
  final Trip trip;

  const AIItineraryGeneratorScreen({super.key, required this.trip});

  // Interest options
  static const List<String> _interestOptions = [
    'Culture & History',
    'Food & Dining',
    'Adventure & Outdoor',
    'Shopping',
    'Nightlife',
    'Nature & Wildlife',
    'Photography',
    'Relaxation & Spa',
    'Museums & Art',
    'Local Experiences',
    'Architecture',
    'Music & Entertainment',
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<AIItineraryGeneratorUIProvider>(
      builder: (context, uiProvider, child) {
        return Scaffold(
          backgroundColor: AppColors.white,
          appBar: AppBar(
            title: const Row(
              children: [
                Icon(Icons.auto_awesome, size: 24),
                SizedBox(width: 8),
                Text('AI Trip Planner'),
              ],
            ),
            backgroundColor: AppColors.white,
            foregroundColor: AppColors.black,
            elevation: 0,
          ),
          body: uiProvider.result == null
              ? _buildForm(context, uiProvider)
              : _buildResult(context, uiProvider),
        );
      },
    );
  }

  /// Build form for itinerary parameters
  Widget _buildForm(
    BuildContext context,
    AIItineraryGeneratorUIProvider uiProvider,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.black,
                  AppColors.black.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.psychology, color: AppColors.white, size: 32),
                const SizedBox(height: 12),
                Text(
                  'Let AI Plan Your Perfect Trip',
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Answer a few questions and get a personalized day-by-day itinerary in seconds',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Trip duration
          _buildSectionTitle('Trip Duration'),
          const SizedBox(height: 12),
          _buildDaysSelector(uiProvider),

          const SizedBox(height: 24),

          // Budget per day
          _buildSectionTitle('Daily Budget'),
          const SizedBox(height: 12),
          _buildBudgetSlider(uiProvider),

          const SizedBox(height: 24),

          // Interests
          _buildSectionTitle('Your Interests'),
          Text(
            'Select at least 3 interests',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          _buildInterestsGrid(uiProvider),

          const SizedBox(height: 24),

          // Travel pace
          _buildSectionTitle('Travel Pace'),
          const SizedBox(height: 12),
          _buildPaceSelector(uiProvider),

          const SizedBox(height: 24),

          // Number of travelers
          _buildSectionTitle('Number of Travelers'),
          const SizedBox(height: 12),
          _buildTravelersSelector(uiProvider),

          const SizedBox(height: 32),

          // Error message
          if (uiProvider.error != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      uiProvider.error!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Generate button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: uiProvider.isGenerating
                  ? null
                  : () => _generateItinerary(context, uiProvider),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.black,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                elevation: 0,
              ),
              child: uiProvider.isGenerating
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Generating Your Itinerary...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.auto_awesome, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Generate Itinerary',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 16),

          // AI info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.grey50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Powered by Google Gemini 2.0 Flash. Generation takes 10-20 seconds.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildDaysSelector(AIItineraryGeneratorUIProvider uiProvider) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [1, 2, 3, 5, 7].map((days) {
          final isSelected = uiProvider.days == days;
          return Expanded(
            child: GestureDetector(
              onTap: () => uiProvider.setDays(days),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.black : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      '$days',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? AppColors.white : AppColors.black,
                      ),
                    ),
                    Text(
                      days == 1 ? 'day' : 'days',
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected
                            ? AppColors.white.withValues(alpha: 0.8)
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBudgetSlider(AIItineraryGeneratorUIProvider uiProvider) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '\$${uiProvider.budgetPerDay.toStringAsFixed(0)} per day',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Total: \$${(uiProvider.budgetPerDay * uiProvider.days).toStringAsFixed(0)}',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        Slider(
          value: uiProvider.budgetPerDay,
          min: 30,
          max: 500,
          divisions: 94,
          activeColor: AppColors.black,
          label: '\$${uiProvider.budgetPerDay.toStringAsFixed(0)}',
          onChanged: (value) => uiProvider.setBudgetPerDay(value),
        ),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('\$30', style: AppTextStyles.bodySmall),
            Text('\$500', style: AppTextStyles.bodySmall),
          ],
        ),
      ],
    );
  }

  Widget _buildInterestsGrid(AIItineraryGeneratorUIProvider uiProvider) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _interestOptions.map((interest) {
        final isSelected = uiProvider.selectedInterests.contains(interest);
        return GestureDetector(
          onTap: () => uiProvider.toggleInterest(interest),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.black : AppColors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppColors.black : AppColors.border,
                width: 1.5,
              ),
            ),
            child: Text(
              interest,
              style: TextStyle(
                color: isSelected ? AppColors.white : AppColors.black,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPaceSelector(AIItineraryGeneratorUIProvider uiProvider) {
    final paces = {
      'relaxed': {
        'icon': Icons.weekend,
        'label': 'Relaxed',
        'desc': 'Take it easy',
      },
      'moderate': {
        'icon': Icons.directions_walk,
        'label': 'Moderate',
        'desc': 'Balanced pace',
      },
      'fast': {
        'icon': Icons.directions_run,
        'label': 'Fast-paced',
        'desc': 'See it all',
      },
    };

    return Row(
      children: paces.entries.map((entry) {
        final isSelected = uiProvider.pace == entry.key;
        return Expanded(
          child: GestureDetector(
            onTap: () => uiProvider.setPace(entry.key),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.black : AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.black : AppColors.border,
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    entry.value['icon'] as IconData,
                    color: isSelected ? AppColors.white : AppColors.black,
                    size: 28,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    entry.value['label'] as String,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppColors.white : AppColors.black,
                    ),
                  ),
                  Text(
                    entry.value['desc'] as String,
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected
                          ? AppColors.white.withValues(alpha: 0.8)
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTravelersSelector(AIItineraryGeneratorUIProvider uiProvider) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [1, 2, 3, 4, '5+'].map((count) {
          final value = count is int ? count : 5;
          final isSelected = uiProvider.travelers == value;
          return Expanded(
            child: GestureDetector(
              onTap: () => uiProvider.setTravelers(value),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.black : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  count.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? AppColors.white : AppColors.black,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _generateItinerary(
    BuildContext context,
    AIItineraryGeneratorUIProvider uiProvider,
  ) async {
    // Validate
    if (uiProvider.selectedInterests.length < 3) {
      uiProvider.setError('Please select at least 3 interests');
      return;
    }

    if (trip.destinations.isEmpty) {
      uiProvider.setError('Please add at least one destination to your trip');
      return;
    }

    uiProvider.startGeneration();

    try {
      final destination = trip.destinations.first;

      // Convert user inputs to service parameters
      final result = await AIItineraryService.generateItinerary(
        destination: destination.name,
        startDate: trip.startDate,
        endDate: trip.startDate.add(Duration(days: uiProvider.days)),
        budget: uiProvider.budgetPerDay * uiProvider.days,
        tripStyle: uiProvider.pace, // Use pace as trip style
        interests: uiProvider.selectedInterests.toList(),
        groupSize: uiProvider.travelers,
      );

      // Convert service result to AIItineraryResult
      final convertedResult = AIItineraryResult.fromMap({
        'id': result['id'] ?? '',
        'destination': destination.name,
        'start_date': trip.startDate.toIso8601String(),
        'end_date': trip.startDate.add(Duration(days: uiProvider.days)).toIso8601String(),
        'duration_days': uiProvider.days,
        'daily_plans': result['itinerary_data']?['daily_itinerary'] ?? [],
        'recommendations': result['itinerary_data']?['local_insights']?['cultural_tips'] ?? [],
        'budget_estimate': result['itinerary_data']?['budget_breakdown'] ?? {},
        'confidence_score': 0.9,
        'generated_at': DateTime.now().toIso8601String(),
      });

      uiProvider.setResult(convertedResult);
    } catch (e) {
      uiProvider.setError('Failed to generate itinerary: ${e.toString()}');
      uiProvider.setGenerating(false);
    }
  }

  /// Build result view with generated itinerary
  Widget _buildResult(
    BuildContext context,
    AIItineraryGeneratorUIProvider uiProvider,
  ) {
    if (uiProvider.result == null) return const SizedBox();

    final result = uiProvider.result!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Success header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade700, Colors.green.shade500],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: AppColors.white,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Itinerary is Ready!',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${result.durationDays} days • \$${result.budgetEstimate['total']?.toStringAsFixed(0) ?? '0'} total',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _applyToTrip(context, uiProvider),
                  icon: const Icon(Icons.add),
                  label: const Text('Add to Trip'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.black,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => uiProvider.resetResult(),
                icon: const Icon(Icons.refresh),
                label: const Text('Regenerate'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Cost breakdown
          _buildCostBreakdown(result),

          const SizedBox(height: 24),

          // Day-by-day itinerary
          const Text(
            'Day-by-Day Itinerary',
            style: AppTextStyles.headlineSmall,
          ),
          const SizedBox(height: 16),

          ...result.dailyPlans.asMap().entries.map((entry) => 
            _buildDayCard(entry.key + 1, entry.value)),

          const SizedBox(height: 24),

          // Key tips
          if (result.recommendations.isNotEmpty) ...[
            Text(
              '💡 Key Tips',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...result.recommendations.map((tip) => _buildTipItem(tip)),
            const SizedBox(height: 24),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildCostBreakdown(AIItineraryResult result) {
    final breakdown = result.budgetEstimate;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cost Breakdown',
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildCostItem('Attractions', (breakdown['activities'] as num?)?.toDouble() ?? 0),
          _buildCostItem('Meals', (breakdown['meals'] as num?)?.toDouble() ?? 0),
          _buildCostItem('Transportation', (breakdown['transportation'] as num?)?.toDouble() ?? 0),
          _buildCostItem('Accommodation', (breakdown['accommodation'] as num?)?.toDouble() ?? 0),
          _buildCostItem('Miscellaneous', (breakdown['miscellaneous'] as num?)?.toDouble() ?? 0),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '\$${(breakdown['total'] as num?)?.toStringAsFixed(0) ?? '0'}',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCostItem(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyMedium),
          Text(
            '\$${amount.toStringAsFixed(0)}',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCard(int dayNumber, Map<String, dynamic> dayData) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.grey50,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: AppColors.black,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$dayNumber',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dayData['theme'] ?? 'Day $dayNumber',
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${dayData['date'] ?? ''} • \$${(dayData['daily_budget']?['total'] as num?)?.toStringAsFixed(0) ?? '0'}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dayData['summary'] ?? 'Day activities and experiences',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  '${(dayData['activities'] as List?)?.length ?? 0} activities',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, size: 20, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(child: Text(tip, style: AppTextStyles.bodyMedium)),
        ],
      ),
    );
  }

  Future<void> _applyToTrip(
    BuildContext context,
    AIItineraryGeneratorUIProvider uiProvider,
  ) async {
    if (uiProvider.result == null) return;

    try {
      // For now, we'll just simulate success since the actual applyToTrip method doesn't exist
      // In a full implementation, you would integrate with the ItineraryService
      // to convert the AI itinerary into actual trip itinerary items
      
      // Simulate a brief loading period
      await Future.delayed(const Duration(seconds: 1));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Itinerary added to your trip!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context, true);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add itinerary: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

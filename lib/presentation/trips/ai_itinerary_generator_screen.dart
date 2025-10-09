import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/models/trip_model.dart';
import '../../services/ai/ai_itinerary_service.dart';

/// Screen for generating AI-powered trip itinerary
class AIItineraryGeneratorScreen extends StatefulWidget {
  final Trip trip;

  const AIItineraryGeneratorScreen({
    super.key,
    required this.trip,
  });

  @override
  State<AIItineraryGeneratorScreen> createState() =>
      _AIItineraryGeneratorScreenState();
}

class _AIItineraryGeneratorScreenState
    extends State<AIItineraryGeneratorScreen> {
  final AIItineraryService _aiService = AIItineraryService();

  // Form state
  int _days = 3;
  double _budgetPerDay = 100.0;
  final List<String> _selectedInterests = [];
  String _pace = 'moderate';
  int _travelers = 2;
  String? _accommodation;

  // Generation state
  bool _isGenerating = false;
  AIItineraryResult? _result;
  String? _error;

  // Interest options
  final List<String> _interestOptions = [
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
      body: _result == null ? _buildForm() : _buildResult(),
    );
  }

  /// Build form for itinerary parameters
  Widget _buildForm() {
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
                const Icon(
                  Icons.psychology,
                  color: AppColors.white,
                  size: 32,
                ),
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
          _buildDaysSelector(),

          const SizedBox(height: 24),

          // Budget per day
          _buildSectionTitle('Daily Budget'),
          const SizedBox(height: 12),
          _buildBudgetSlider(),

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
          _buildInterestsGrid(),

          const SizedBox(height: 24),

          // Travel pace
          _buildSectionTitle('Travel Pace'),
          const SizedBox(height: 12),
          _buildPaceSelector(),

          const SizedBox(height: 24),

          // Number of travelers
          _buildSectionTitle('Number of Travelers'),
          const SizedBox(height: 12),
          _buildTravelersSelector(),

          const SizedBox(height: 32),

          // Error message
          if (_error != null) ...[
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
                      _error!,
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
              onPressed: _isGenerating ? null : _generateItinerary,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.black,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                elevation: 0,
              ),
              child: _isGenerating
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
      style: AppTextStyles.titleMedium.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildDaysSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [1, 2, 3, 5, 7].map((days) {
          final isSelected = _days == days;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _days = days),
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

  Widget _buildBudgetSlider() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '\$${_budgetPerDay.toStringAsFixed(0)} per day',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Total: \$${(_budgetPerDay * _days).toStringAsFixed(0)}',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        Slider(
          value: _budgetPerDay,
          min: 30,
          max: 500,
          divisions: 94,
          activeColor: AppColors.black,
          label: '\$${_budgetPerDay.toStringAsFixed(0)}',
          onChanged: (value) => setState(() => _budgetPerDay = value),
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

  Widget _buildInterestsGrid() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _interestOptions.map((interest) {
        final isSelected = _selectedInterests.contains(interest);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedInterests.remove(interest);
              } else {
                _selectedInterests.add(interest);
              }
            });
          },
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

  Widget _buildPaceSelector() {
    final paces = {
      'relaxed': {'icon': Icons.weekend, 'label': 'Relaxed', 'desc': 'Take it easy'},
      'moderate': {'icon': Icons.directions_walk, 'label': 'Moderate', 'desc': 'Balanced pace'},
      'fast': {'icon': Icons.directions_run, 'label': 'Fast-paced', 'desc': 'See it all'},
    };

    return Row(
      children: paces.entries.map((entry) {
        final isSelected = _pace == entry.key;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _pace = entry.key),
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

  Widget _buildTravelersSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [1, 2, 3, 4, '5+'].map((count) {
          final value = count is int ? count : 5;
          final isSelected = _travelers == value;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _travelers = value),
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

  Future<void> _generateItinerary() async {
    // Validate
    if (_selectedInterests.length < 3) {
      setState(() {
        _error = 'Please select at least 3 interests';
      });
      return;
    }

    if (widget.trip.destinations.isEmpty) {
      setState(() {
        _error = 'Please add at least one destination to your trip';
      });
      return;
    }

    setState(() {
      _isGenerating = true;
      _error = null;
    });

    try {
      final destination = widget.trip.destinations.first;
      
      final params = ItineraryGenerationParams(
        destination: destination.name,
        destinationId: destination.id,
        days: _days,
        budgetPerDay: _budgetPerDay,
        interests: _selectedInterests,
        pace: _pace,
        travelers: _travelers,
        startDate: widget.trip.startDate,
        accommodation: _accommodation,
      );

      final result = await _aiService.generateItinerary(params);

      if (mounted) {
        setState(() {
          _result = result;
          _isGenerating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to generate itinerary: ${e.toString()}';
          _isGenerating = false;
        });
      }
    }
  }

  /// Build result view with generated itinerary
  Widget _buildResult() {
    if (_result == null) return const SizedBox();

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
                        '${_result!.itinerary.length} days • \$${_result!.totalEstimatedCost.toStringAsFixed(0)} total',
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
                  onPressed: _applyToTrip,
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
                onPressed: () => setState(() => _result = null),
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
          _buildCostBreakdown(),

          const SizedBox(height: 24),

          // Day-by-day itinerary
          const Text(
            'Day-by-Day Itinerary',
            style: AppTextStyles.headlineSmall,
          ),
          const SizedBox(height: 16),

          ..._result!.itinerary.map((day) => _buildDayCard(day)),

          const SizedBox(height: 24),

          // Key tips
          if (_result!.keyTips.isNotEmpty) ...[
            Text(
              '💡 Key Tips',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ..._result!.keyTips.map((tip) => _buildTipItem(tip)),
            const SizedBox(height: 24),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildCostBreakdown() {
    final breakdown = _result!.costBreakdown;
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
          _buildCostItem('Attractions', breakdown.attractions),
          _buildCostItem('Meals', breakdown.meals),
          _buildCostItem('Transportation', breakdown.transportation),
          _buildCostItem('Accommodation', breakdown.accommodation),
          _buildCostItem('Miscellaneous', breakdown.miscellaneous),
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
                '\$${breakdown.total.toStringAsFixed(0)}',
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

  Widget _buildDayCard(DayItinerary day) {
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
                      '${day.day}',
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
                        day.theme,
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${day.dayOfWeek} • \$${day.totalCost.toStringAsFixed(0)}',
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
                  day.summary,
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  '${day.activities.length} activities',
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
          Expanded(
            child: Text(
              tip,
              style: AppTextStyles.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _applyToTrip() async {
    if (_result == null) return;

    try {
      await _aiService.applyToTrip(
        tripId: widget.trip.id,
        itinerary: _result!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Itinerary added to your trip!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
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

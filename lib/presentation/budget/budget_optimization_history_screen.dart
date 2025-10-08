import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/logger.dart';

class BudgetOptimizationHistoryScreen extends StatefulWidget {
  final String userId;
  final String tripId;
  
  const BudgetOptimizationHistoryScreen({
    super.key,
    required this.userId,
    required this.tripId,
  });

  @override
  State<BudgetOptimizationHistoryScreen> createState() => _BudgetOptimizationHistoryScreenState();
}

class _BudgetOptimizationHistoryScreenState extends State<BudgetOptimizationHistoryScreen> {
  static const String _tag = 'BudgetOptimizationHistoryScreen';
  
  // State variables
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _optimizationHistory = [];
  
  @override
  void initState() {
    super.initState();
    _loadHistory();
  }
  
  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      AppLogger.debug(_tag, 'Loading budget optimization history', {
        'userId': widget.userId,
        'tripId': widget.tripId,
      });
      
      // Mock data instead of actual Firestore fetch
      await Future.delayed(const Duration(seconds: 1));
      
      final mockData = [
        {
          'id': '1',
          'createdAt': DateTime.now().subtract(const Duration(days: 1)),
          'result': {
            'totalBudget': 2000.0,
            'healthScore': 85,
            'categories': [
              {'name': 'Accommodation', 'amount': 700.0, 'percentage': 35},
              {'name': 'Food', 'amount': 500.0, 'percentage': 25},
              {'name': 'Transportation', 'amount': 300.0, 'percentage': 15},
              {'name': 'Activities', 'amount': 300.0, 'percentage': 15},
              {'name': 'Miscellaneous', 'amount': 200.0, 'percentage': 10},
            ],
          },
        },
        {
          'id': '2',
          'createdAt': DateTime.now().subtract(const Duration(days: 3)),
          'result': {
            'totalBudget': 1800.0,
            'healthScore': 75,
            'categories': [
              {'name': 'Accommodation', 'amount': 630.0, 'percentage': 35},
              {'name': 'Food', 'amount': 450.0, 'percentage': 25},
              {'name': 'Transportation', 'amount': 270.0, 'percentage': 15},
              {'name': 'Activities', 'amount': 270.0, 'percentage': 15},
              {'name': 'Miscellaneous', 'amount': 180.0, 'percentage': 10},
            ],
          },
        },
        {
          'id': '3',
          'createdAt': DateTime.now().subtract(const Duration(days: 5)),
          'result': {
            'totalBudget': 1500.0,
            'healthScore': 65,
            'categories': [
              {'name': 'Accommodation', 'amount': 525.0, 'percentage': 35},
              {'name': 'Food', 'amount': 375.0, 'percentage': 25},
              {'name': 'Transportation', 'amount': 225.0, 'percentage': 15},
              {'name': 'Activities', 'amount': 225.0, 'percentage': 15},
              {'name': 'Miscellaneous', 'amount': 150.0, 'percentage': 10},
            ],
          },
        },
      ];
      
      setState(() {
        _optimizationHistory = mockData;
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error(_tag, 'Error loading budget optimization history', e);
      setState(() {
        _errorMessage = 'Failed to load history: $e';
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.compare_arrows),
            onPressed: _optimizationHistory.length >= 2 ? _showCompareDialog : null,
            tooltip: 'Compare Optimizations',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }
  
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading optimization history...'),
          ],
        ),
      );
    }
    
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: AppTextStyles.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadHistory,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    if (_optimizationHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'No Optimization History',
              style: AppTextStyles.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Your budget optimization history will appear here',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }
    
    return Column(
      children: [
        // Timeline indicator
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history, color: Colors.teal.shade700, size: 16),
              const SizedBox(width: 8),
              Text(
                'Budget Optimization Timeline',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade700,
                ),
              ),
            ],
          ),
        ),
        
        // History list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _optimizationHistory.length,
            itemBuilder: (context, index) {
              final optimization = _optimizationHistory[index];
              final result = optimization['result'] as Map<String, dynamic>;
              final date = optimization['createdAt'] as DateTime;
              final healthScore = result['healthScore'] as int;
              final totalBudget = result['totalBudget'] as double;
              final categories = result['categories'] as List;
              
              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: () => _showOptimizationDetails(optimization),
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with date and health score
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _getHealthColor(healthScore).withOpacity(0.1),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${date.day}/${date.month}/${date.year}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  '${date.hour}:${date.minute.toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: _getHealthColor(healthScore),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _getHealthIcon(healthScore),
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '$healthScore',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Budget amount
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Budget',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              '\$${totalBudget.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Budget breakdown
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Budget Allocation',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 20,
                              child: Row(
                                children: [
                                  for (var i = 0; i < categories.length; i++)
                                    Expanded(
                                      flex: (categories[i]['percentage'] as int),
                                      child: Container(
                                        height: 20,
                                        decoration: BoxDecoration(
                                          color: _getCategoryColor(categories[i]['name']),
                                          borderRadius: BorderRadius.horizontal(
                                            left: i == 0 ? const Radius.circular(4) : Radius.zero,
                                            right: i == categories.length - 1
                                                ? const Radius.circular(4)
                                                : Radius.zero,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // View details button
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton.icon(
                              onPressed: () => _showOptimizationDetails(optimization),
                              icon: const Icon(Icons.visibility),
                              label: const Text('View Details'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.teal.shade700,
                              ),
                            ),
                            if (index > 0)
                              Text(
                                'vs. previous: ${_getTrend(optimization, _optimizationHistory[index - 1])}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
  
  String _getTrend(Map<String, dynamic> current, Map<String, dynamic> previous) {
    final currentResult = current['result'] as Map<String, dynamic>;
    final previousResult = previous['result'] as Map<String, dynamic>;
    
    final currentBudget = currentResult['totalBudget'] as double;
    final previousBudget = previousResult['totalBudget'] as double;
    
    final difference = currentBudget - previousBudget;
    final percentChange = (difference / previousBudget * 100).toStringAsFixed(1);
    
    if (difference > 0) {
      return '+\$${difference.toStringAsFixed(0)} (+$percentChange%)';
    } else if (difference < 0) {
      return '-\$${difference.abs().toStringAsFixed(0)} ($percentChange%)';
    } else {
      return 'No change';
    }
  }
  
  void _showOptimizationDetails(Map<String, dynamic> optimization) {
    final result = optimization['result'] as Map<String, dynamic>;
    final date = optimization['createdAt'] as DateTime;
    final healthScore = result['healthScore'] as int;
    final totalBudget = result['totalBudget'] as double;
    final categories = result['categories'] as List;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Close button and title
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Budget Details',
                      style: AppTextStyles.titleLarge.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              
              const Divider(),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date and time
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Health score
                      _buildDetailSection(
                        title: 'Budget Health',
                        icon: Icons.favorite,
                        iconColor: _getHealthColor(healthScore),
                        content: Column(
                          children: [
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    SizedBox(
                                      width: 120,
                                      height: 120,
                                      child: CircularProgressIndicator(
                                        value: healthScore / 100,
                                        strokeWidth: 12,
                                        backgroundColor: Colors.grey.shade200,
                                        valueColor: AlwaysStoppedAnimation<Color>(_getHealthColor(healthScore)),
                                      ),
                                    ),
                                    Column(
                                      children: [
                                        Icon(
                                          _getHealthIcon(healthScore),
                                          size: 24,
                                          color: _getHealthColor(healthScore),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '$healthScore',
                                          style: TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                            color: _getHealthColor(healthScore),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _getHealthDescription(healthScore),
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Budget breakdown
                      _buildDetailSection(
                        title: 'Budget Breakdown',
                        icon: Icons.pie_chart,
                        iconColor: Colors.blue.shade700,
                        content: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Center(
                              child: Text(
                                'Total: \$${totalBudget.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal.shade700,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            for (final category in categories)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              _getCategoryIcon(category['name']),
                                              size: 16,
                                              color: _getCategoryColor(category['name']),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              category['name'],
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Text(
                                              '\$${(category['amount'] as double).toStringAsFixed(0)}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade200,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                '${category['percentage']}%',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade700,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(2),
                                      child: LinearProgressIndicator(
                                        value: (category['percentage'] as int) / 100,
                                        backgroundColor: Colors.grey.shade200,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          _getCategoryColor(category['name']),
                                        ),
                                        minHeight: 6,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Recommendations
                      _buildDetailSection(
                        title: 'Recommendations',
                        icon: Icons.lightbulb,
                        iconColor: Colors.amber.shade700,
                        content: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildRecommendationItem(
                              'Accommodation',
                              'Consider booking accommodations in advance to get better rates.',
                            ),
                            _buildRecommendationItem(
                              'Food',
                              'Save money by eating breakfast at your accommodation and having lunch at local spots.',
                            ),
                            _buildRecommendationItem(
                              'Transportation',
                              'Use public transportation or walking for most city travel to save on taxis.',
                            ),
                            _buildRecommendationItem(
                              'Activities',
                              'Look for free attractions and city passes that bundle multiple sites.',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildRecommendationItem(String category, String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle,
            size: 18,
            color: Colors.green.shade600,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  tip,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  void _showCompareDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Compare Optimizations'),
          content: const Text(
            'Select two budget optimizations to compare their differences and track changes over time.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // In a real app, you would implement selection and comparison
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Comparison feature coming soon'),
                  ),
                );
              },
              child: const Text('Select'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
              ),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildDetailSection({
    required String title,
    required IconData icon,
    required Widget content,
    Color? iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: iconColor ?? Colors.grey.shade700,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          content,
        ],
      ),
    );
  }
  
  Color _getHealthColor(int score) {
    if (score >= 85) return Colors.green;
    if (score >= 70) return Colors.green.shade300;
    if (score >= 50) return Colors.orange;
    return Colors.red;
  }
  
  IconData _getHealthIcon(int score) {
    if (score >= 85) return Icons.sentiment_very_satisfied;
    if (score >= 70) return Icons.sentiment_satisfied;
    if (score >= 50) return Icons.sentiment_neutral;
    return Icons.sentiment_dissatisfied;
  }
  
  String _getHealthDescription(int score) {
    if (score >= 85) {
      return 'Excellent! Your budget is well-balanced and adequate for your trip.';
    }
    if (score >= 70) {
      return 'Good. Your budget is reasonable but could use some minor adjustments.';
    }
    if (score >= 50) {
      return 'Moderate. Your budget might be tight in some categories. Consider reallocation.';
    }
    return 'Tight budget. Consider increasing your total budget or reducing expenses.';
  }
  
  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'accommodation':
        return Colors.blue.shade600;
      case 'food':
        return Colors.orange.shade600;
      case 'transportation':
        return Colors.green.shade600;
      case 'activities':
        return Colors.purple.shade600;
      case 'shopping':
      case 'miscellaneous':
        return Colors.grey.shade600;
      default:
        return Colors.teal.shade600;
    }
  }
  
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'accommodation':
        return Icons.hotel;
      case 'food':
        return Icons.restaurant;
      case 'transportation':
        return Icons.directions_car;
      case 'activities':
        return Icons.local_activity;
      case 'shopping':
        return Icons.shopping_bag;
      case 'miscellaneous':
        return Icons.more_horiz;
      default:
        return Icons.attach_money;
    }
  }
}
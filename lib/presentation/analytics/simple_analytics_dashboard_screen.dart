import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/logger.dart';

/// Simple Analytics Dashboard following app's design system
class SimpleAnalyticsDashboardScreen extends StatefulWidget {
  const SimpleAnalyticsDashboardScreen({super.key});

  @override
  State<SimpleAnalyticsDashboardScreen> createState() => _SimpleAnalyticsDashboardScreenState();
}

class _SimpleAnalyticsDashboardScreenState extends State<SimpleAnalyticsDashboardScreen>
    with SingleTickerProviderStateMixin {
  static const String _tag = 'SimpleAnalyticsDashboardScreen';
  
  late TabController _tabController;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _insights = [
    {
      'title': 'Travel Pattern Insight',
      'description': 'You tend to travel more during weekends, with 73% of your trips starting on Friday or Saturday.',
      'type': 'travel_pattern',
      'priority': 'high',
    },
    {
      'title': 'Budget Optimization',
      'description': 'Consider booking accommodations 2 weeks earlier to save an average of 23% on your trips.',
      'type': 'budget',
      'priority': 'medium',
    },
    {
      'title': 'AI Usage Benefit',
      'description': 'Using AI recommendations has saved you 4.2 hours of planning time this month.',
      'type': 'ai_usage',
      'priority': 'low',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    AppLogger.debug(_tag, 'Simple Analytics Dashboard initialized');
    _loadAnalytics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadAnalytics() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate loading analytics data
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _isLoading = false;
    });

    AppLogger.info(_tag, 'Analytics data loaded');
  }

  void _dismissInsight(int index) {
    setState(() {
      _insights.removeAt(index);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Insight dismissed'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey50,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.analytics, size: 24),
            SizedBox(width: 8),
            Text('Analytics Dashboard'),
          ],
        ),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.black,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.black,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.black,
          indicatorWeight: 2,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Travel'),
            Tab(text: 'AI Insights'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.black,
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildTravelTab(),
                _buildInsightsTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary cards
          FadeInDown(
            duration: const Duration(milliseconds: 600),
            child: Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Total Trips',
                    '12',
                    Icons.airplane_ticket,
                    '+3 this month',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Total Spending',
                    '\$2,450',
                    Icons.account_balance_wallet,
                    '-12% vs last month',
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          FadeInDown(
            duration: const Duration(milliseconds: 800),
            child: Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'AI Interactions',
                    '156',
                    Icons.psychology,
                    '23 this week',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Avg Trip Rating',
                    '4.8',
                    Icons.star,
                    'Excellent satisfaction',
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Quick stats
          FadeInUp(
            duration: const Duration(milliseconds: 600),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent Activity',
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildActivityItem(
                    Icons.route,
                    'Route planned to Bali',
                    '2 hours ago',
                  ),
                  _buildActivityItem(
                    Icons.chat,
                    'AI chat consultation',
                    '5 hours ago',
                  ),
                  _buildActivityItem(
                    Icons.image,
                    'Photo analysis completed',
                    '1 day ago',
                  ),
                  _buildActivityItem(
                    Icons.account_balance_wallet,
                    'Budget optimized for Jakarta trip',
                    '2 days ago',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTravelTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Travel patterns
          FadeInDown(
            duration: const Duration(milliseconds: 600),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Top Destinations',
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDestinationItem('Bali', 4, '\$850'),
                  _buildDestinationItem('Jakarta', 3, '\$420'),
                  _buildDestinationItem('Yogyakarta', 2, '\$320'),
                  _buildDestinationItem('Bandung', 2, '\$280'),
                  _buildDestinationItem('Surabaya', 1, '\$180'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Spending breakdown
          FadeInUp(
            duration: const Duration(milliseconds: 800),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Spending by Category',
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSpendingItem('Accommodation', 45, '\$1,103'),
                  _buildSpendingItem('Transportation', 25, '\$613'),
                  _buildSpendingItem('Food & Dining', 20, '\$490'),
                  _buildSpendingItem('Activities', 7, '\$171'),
                  _buildSpendingItem('Shopping', 3, '\$73'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI insights header
          FadeInDown(
            duration: const Duration(milliseconds: 600),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.grey100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.psychology,
                      color: AppColors.textPrimary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI-Powered Insights',
                          style: AppTextStyles.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Personalized recommendations based on your travel patterns',
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
          ),

          const SizedBox(height: 20),

          // Insights list
          ..._insights.asMap().entries.map((entry) {
            final index = entry.key;
            final insight = entry.value;
            return FadeInUp(
              duration: Duration(milliseconds: 600 + (index * 200)),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: _buildInsightCard(insight, index),
              ),
            );
          }),

          // AI performance
          FadeInUp(
            duration: const Duration(milliseconds: 1000),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Performance This Month',
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildPerformanceMetric('Total AI Requests', '156', '92%'),
                  _buildPerformanceMetric('Success Rate', '95.5%', '98%'),
                  _buildPerformanceMetric('Avg Response Time', '1.2s', '0.8s'),
                  _buildPerformanceMetric('User Satisfaction', '4.8/5', '4.9/5'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.headlineSmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(IconData icon, String title, String time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.grey100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: AppColors.textPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium,
                ),
                Text(
                  time,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDestinationItem(String destination, int visits, String spent) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              destination,
              style: AppTextStyles.bodyMedium,
            ),
          ),
          Text(
            '$visits visits',
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            spent,
            style: AppTextStyles.labelLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpendingItem(String category, int percentage, String amount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  category,
                  style: AppTextStyles.bodyMedium,
                ),
              ),
              Text(
                '$percentage%',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                amount,
                style: AppTextStyles.labelLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: AppColors.grey200,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.black),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(Map<String, dynamic> insight, int index) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getPriorityColor(insight['priority']).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  insight['priority'].toString().toUpperCase(),
                  style: AppTextStyles.labelSmall.copyWith(
                    color: _getPriorityColor(insight['priority']),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => _dismissInsight(index),
                icon: const Icon(Icons.close, size: 18),
                color: AppColors.textTertiary,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            insight['title'],
            style: AppTextStyles.titleSmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            insight['description'],
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetric(String label, String value, String target) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodyMedium,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.labelLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '(Target: $target)',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return AppColors.error;
      case 'medium':
        return AppColors.warning;
      case 'low':
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }
}
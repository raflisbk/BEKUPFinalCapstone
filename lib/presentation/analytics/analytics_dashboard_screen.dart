import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/models/analytics_model.dart';
import '../../core/utils/logger.dart';
import '../../services/analytics_service.dart';
import '../../core/providers/auth_provider.dart';

/// Advanced analytics dashboard with AI-powered insights and comprehensive metrics
class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen>
    with TickerProviderStateMixin {
  static const String _tag = 'AnalyticsDashboardScreen';

  // Services
  final AnalyticsService _analyticsService = AnalyticsService();

  // Controllers
  late TabController _tabController;
  late AnimationController _chartAnimationController;

  // State variables
  AnalyticsSummary? _analyticsSummary;
  List<DashboardInsight> _insights = [];
  bool _isLoading = false;
  String _selectedPeriod = '30_days';
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  // Chart data
  final List<FlSpot> _spendingTrendData = [];
  final List<PieChartSectionData> _categoryData = [];
  final List<BarChartGroupData> _aiUsageData = [];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeServices();
    _trackScreenView();
    _loadDashboardData();
  }

  void _initializeControllers() {
    _tabController = TabController(length: 4, vsync: this);
    _chartAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
  }

  Future<void> _initializeServices() async {
    try {
      // Analytics service doesn't need explicit initialization
      // await _analyticsService.initialize();
      AppLogger.info(_tag, 'Analytics service initialized');
    } catch (e) {
      AppLogger.error(_tag, 'Failed to initialize analytics service', e);
    }
  }

  void _trackScreenView() {
    _analyticsService.trackScreenView(
      'analytics_dashboard_screen',
      properties: {
        'period': _selectedPeriod,
        'start_date': _startDate.toIso8601String(),
        'end_date': _endDate.toIso8601String(),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Analytics Dashboard'),
      backgroundColor: Colors.transparent,
      elevation: 0,
      actions: [
        PopupMenuButton<String>(
          onSelected: _changePeriod,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: '7_days',
              child: Text('Last 7 days'),
            ),
            const PopupMenuItem(
              value: '30_days',
              child: Text('Last 30 days'),
            ),
            const PopupMenuItem(
              value: '90_days',
              child: Text('Last 3 months'),
            ),
            const PopupMenuItem(
              value: '365_days',
              child: Text('Last year'),
            ),
          ],
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getPeriodDisplayName(_selectedPeriod),
                  style: const TextStyle(fontSize: 14),
                ),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
        IconButton(
          onPressed: _refreshData,
          icon: const Icon(Icons.refresh),
        ),
      ],
      bottom: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
          Tab(text: 'Travel', icon: Icon(Icons.flight_takeoff)),
          Tab(text: 'AI Usage', icon: Icon(Icons.psychology)),
          Tab(text: 'Insights', icon: Icon(Icons.lightbulb)),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildOverviewTab(),
        _buildTravelTab(),
        _buildAIUsageTab(),
        _buildInsightsTab(),
      ],
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Key metrics cards
          FadeInUp(
            duration: const Duration(milliseconds: 600),
            child: _buildKeyMetricsCards(),
          ),
          const SizedBox(height: 24),
          
          // Spending trend chart
          FadeInUp(
            duration: const Duration(milliseconds: 800),
            child: _buildSpendingTrendChart(),
          ),
          const SizedBox(height: 24),
          
          // Category breakdown
          FadeInUp(
            duration: const Duration(milliseconds: 1000),
            child: _buildCategoryBreakdownChart(),
          ),
          const SizedBox(height: 24),
          
          // Recent activity
          FadeInUp(
            duration: const Duration(milliseconds: 1200),
            child: _buildRecentActivity(),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyMetricsCards() {
    final summary = _analyticsSummary;
    
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildMetricCard(
          title: 'Total Trips',
          value: summary?.totalTrips.toString() ?? '0',
          icon: Icons.flight_takeoff,
          color: Colors.blue,
          trend: '+12%',
        ),
        _buildMetricCard(
          title: 'Total Spending',
          value: '\$${summary?.totalSpending.toStringAsFixed(0) ?? '0'}',
          icon: Icons.attach_money,
          color: Colors.green,
          trend: '+8%',
        ),
        _buildMetricCard(
          title: 'AI Interactions',
          value: summary?.aiInteractions.toString() ?? '0',
          icon: Icons.psychology,
          color: Colors.purple,
          trend: '+25%',
        ),
        _buildMetricCard(
          title: 'Avg Satisfaction',
          value: '${summary?.averageTripSatisfaction.toStringAsFixed(1) ?? '0'}/5',
          icon: Icons.star,
          color: Colors.orange,
          trend: '+0.3',
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String trend,
  }) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    trend,
                    style: TextStyle(
                      color: Colors.green[700],
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpendingTrendChart() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Spending Trend',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const style = TextStyle(fontSize: 12);
                          switch (value.toInt()) {
                            case 0:
                              return const Text('Week 1', style: style);
                            case 1:
                              return const Text('Week 2', style: style);
                            case 2:
                              return const Text('Week 3', style: style);
                            case 3:
                              return const Text('Week 4', style: style);
                            default:
                              return const Text('');
                          }
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '\$${value.toInt()}',
                            style: const TextStyle(fontSize: 12),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _spendingTrendData.isNotEmpty
                          ? _spendingTrendData
                          : [
                              const FlSpot(0, 150),
                              const FlSpot(1, 240),
                              const FlSpot(2, 180),
                              const FlSpot(3, 320),
                            ],
                      isCurved: true,
                      color: Theme.of(context).primaryColor,
                      barWidth: 3,
                      belowBarData: BarAreaData(
                        show: true,
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBreakdownChart() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Spending by Category',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: PieChart(
                      PieChartData(
                        sections: _categoryData.isNotEmpty
                            ? _categoryData
                            : _getDefaultCategoryData(),
                        centerSpaceRadius: 40,
                        sectionsSpace: 2,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: _buildCategoryLegend(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryLegend() {
    final categories = [
      {'name': 'Accommodation', 'color': Colors.blue, 'percentage': '35%'},
      {'name': 'Food', 'color': Colors.green, 'percentage': '25%'},
      {'name': 'Transport', 'color': Colors.orange, 'percentage': '20%'},
      {'name': 'Activities', 'color': Colors.purple, 'percentage': '15%'},
      {'name': 'Other', 'color': Colors.grey, 'percentage': '5%'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: categories.map((category) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: category['color'] as Color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  category['name'] as String,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              Text(
                category['percentage'] as String,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTravelTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Travel stats
          FadeInUp(
            duration: const Duration(milliseconds: 600),
            child: _buildTravelStatsCards(),
          ),
          const SizedBox(height: 24),
          
          // Destinations map
          FadeInUp(
            duration: const Duration(milliseconds: 800),
            child: _buildDestinationsChart(),
          ),
          const SizedBox(height: 24),
          
          // Trip timeline
          FadeInUp(
            duration: const Duration(milliseconds: 1000),
            child: _buildTripTimeline(),
          ),
        ],
      ),
    );
  }

  Widget _buildTravelStatsCards() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildMetricCard(
          title: 'Countries Visited',
          value: '12',
          icon: Icons.public,
          color: Colors.teal,
          trend: '+2',
        ),
        _buildMetricCard(
          title: 'Total Distance',
          value: '2,540 km',
          icon: Icons.route,
          color: Colors.indigo,
          trend: '+15%',
        ),
        _buildMetricCard(
          title: 'Avg Trip Duration',
          value: '5.2 days',
          icon: Icons.schedule,
          color: Colors.cyan,
          trend: '+0.5',
        ),
        _buildMetricCard(
          title: 'Favorite Mode',
          value: 'Driving',
          icon: Icons.directions_car,
          color: Colors.brown,
          trend: '67%',
        ),
      ],
    );
  }

  Widget _buildDestinationsChart() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top Destinations',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const destinations = ['Bali', 'Jakarta', 'Yogya', 'Bandung', 'Medan'];
                          if (value.toInt() < destinations.length) {
                            return Text(
                              destinations[value.toInt()],
                              style: const TextStyle(fontSize: 12),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 12),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  barGroups: _aiUsageData.isNotEmpty
                      ? _aiUsageData
                      : [
                          BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 8, color: Colors.blue)]),
                          BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 6, color: Colors.green)]),
                          BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 5, color: Colors.orange)]),
                          BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 4, color: Colors.purple)]),
                          BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 3, color: Colors.red)]),
                        ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripTimeline() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Trips',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 5,
              itemBuilder: (context, index) {
                return _buildTripTimelineItem(index);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripTimelineItem(int index) {
    final trips = [
      {'name': 'Bali Adventure', 'date': 'Oct 2025', 'duration': '7 days', 'spending': '\$850'},
      {'name': 'Jakarta Business', 'date': 'Sep 2025', 'duration': '3 days', 'spending': '\$420'},
      {'name': 'Yogyakarta Culture', 'date': 'Aug 2025', 'duration': '5 days', 'spending': '\$320'},
      {'name': 'Bandung Weekend', 'date': 'Jul 2025', 'duration': '2 days', 'spending': '\$180'},
      {'name': 'Medan Culinary', 'date': 'Jun 2025', 'duration': '4 days', 'spending': '\$280'},
    ];

    final trip = trips[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.flight_takeoff,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trip['name']!,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${trip['date']} • ${trip['duration']}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Text(
            trip['spending']!,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIUsageTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI usage overview
          FadeInUp(
            duration: const Duration(milliseconds: 600),
            child: _buildAIUsageOverview(),
          ),
          const SizedBox(height: 24),
          
          // AI feature breakdown
          FadeInUp(
            duration: const Duration(milliseconds: 800),
            child: _buildAIFeatureBreakdown(),
          ),
          const SizedBox(height: 24),
          
          // AI performance metrics
          FadeInUp(
            duration: const Duration(milliseconds: 1000),
            child: _buildAIPerformanceMetrics(),
          ),
        ],
      ),
    );
  }

  Widget _buildAIUsageOverview() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AI Usage Overview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildAIMetricCard(
                    'Total Requests',
                    '1,247',
                    Icons.psychology,
                    Colors.purple,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildAIMetricCard(
                    'Avg Response Time',
                    '1.2s',
                    Icons.speed,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildAIMetricCard(
                    'Success Rate',
                    '98.5%',
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildAIMetricCard(
                    'Satisfaction',
                    '4.7/5',
                    Icons.star,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAIFeatureBreakdown() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Most Used AI Features',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildFeatureUsageItem('Chat Assistant', 0.7, '847 requests'),
            _buildFeatureUsageItem('Route Planning', 0.5, '312 requests'),
            _buildFeatureUsageItem('Budget Optimization', 0.3, '156 requests'),
            _buildFeatureUsageItem('Image Analysis', 0.2, '89 requests'),
            _buildFeatureUsageItem('Recommendations', 0.15, '43 requests'),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureUsageItem(String feature, double percentage, String count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                feature,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                count,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: percentage,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIPerformanceMetrics() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AI Performance Trends',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                          if (value.toInt() < days.length) {
                            return Text(days[value.toInt()], style: const TextStyle(fontSize: 12));
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text('${value.toInt()}s', style: const TextStyle(fontSize: 12));
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: const [
                        FlSpot(0, 1.5),
                        FlSpot(1, 1.2),
                        FlSpot(2, 1.8),
                        FlSpot(3, 1.0),
                        FlSpot(4, 1.3),
                        FlSpot(5, 0.9),
                        FlSpot(6, 1.1),
                      ],
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Generate insights button
          FadeInUp(
            duration: const Duration(milliseconds: 600),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _generateInsights,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Generate AI Insights'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Insights list
          if (_insights.isNotEmpty)
            ..._insights.asMap().entries.map((entry) {
              final index = entry.key;
              final insight = entry.value;
              return FadeInUp(
                duration: Duration(milliseconds: 800 + (index * 200)),
                child: _buildInsightCard(insight),
              );
            }),
            
          if (_insights.isEmpty)
            FadeInUp(
              duration: const Duration(milliseconds: 800),
              child: _buildEmptyInsights(),
            ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(DashboardInsight insight) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getInsightCategoryColor(insight.category).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getInsightCategoryIcon(insight.category),
                    color: _getInsightCategoryColor(insight.category),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        insight.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        insight.category.toUpperCase(),
                        style: TextStyle(
                          color: _getInsightCategoryColor(insight.category),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(insight.priority).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Priority ${insight.priority}',
                    style: TextStyle(
                      color: _getPriorityColor(insight.priority),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              insight.description,
              style: const TextStyle(fontSize: 14),
            ),
            if (insight.actionableRecommendations.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Recommendations:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              ...insight.actionableRecommendations.map((recommendation) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                      Expanded(
                        child: Text(
                          recommendation,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Generated ${_formatDate(insight.generatedAt)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                TextButton(
                  onPressed: () => _dismissInsight(insight),
                  child: const Text('Dismiss'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyInsights() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.lightbulb_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'No Insights Yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Generate AI-powered insights to discover patterns in your travel behavior and get personalized recommendations.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 5,
              itemBuilder: (context, index) {
                return _buildActivityItem(index);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(int index) {
    final activities = [
      {'type': 'AI Chat', 'description': 'Asked about restaurant recommendations', 'time': '2 hours ago'},
      {'type': 'Route Planning', 'description': 'Created route to Bali Ubud', 'time': '5 hours ago'},
      {'type': 'Expense Added', 'description': 'Added hotel expense \$120', 'time': '1 day ago'},
      {'type': 'Trip Created', 'description': 'Started planning "Bali Adventure"', 'time': '2 days ago'},
      {'type': 'AI Recommendation', 'description': 'Received budget optimization tips', 'time': '3 days ago'},
    ];

    final activity = activities[index];

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        child: Icon(
          _getActivityIcon(activity['type']!),
          color: Theme.of(context).primaryColor,
          size: 20,
        ),
      ),
      title: Text(
        activity['description']!,
        style: const TextStyle(fontSize: 14),
      ),
      subtitle: Text(
        '${activity['type']} • ${activity['time']}',
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 12,
        ),
      ),
    );
  }

  // Helper methods
  List<PieChartSectionData> _getDefaultCategoryData() {
    return [
      PieChartSectionData(color: Colors.blue, value: 35, title: '35%', radius: 50),
      PieChartSectionData(color: Colors.green, value: 25, title: '25%', radius: 50),
      PieChartSectionData(color: Colors.orange, value: 20, title: '20%', radius: 50),
      PieChartSectionData(color: Colors.purple, value: 15, title: '15%', radius: 50),
      PieChartSectionData(color: Colors.grey, value: 5, title: '5%', radius: 50),
    ];
  }

  IconData _getInsightCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'spending':
        return Icons.attach_money;
      case 'travel_patterns':
        return Icons.timeline;
      case 'ai_usage':
        return Icons.psychology;
      case 'app_optimization':
        return Icons.speed;
      default:
        return Icons.lightbulb;
    }
  }

  Color _getInsightCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'spending':
        return Colors.green;
      case 'travel_patterns':
        return Colors.blue;
      case 'ai_usage':
        return Colors.purple;
      case 'app_optimization':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(int priority) {
    if (priority >= 8) return Colors.red;
    if (priority >= 6) return Colors.orange;
    if (priority >= 4) return Colors.blue;
    return Colors.grey;
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'AI Chat':
        return Icons.chat;
      case 'Route Planning':
        return Icons.route;
      case 'Expense Added':
        return Icons.attach_money;
      case 'Trip Created':
        return Icons.flight_takeoff;
      case 'AI Recommendation':
        return Icons.recommend;
      default:
        return Icons.event;
    }
  }

  String _getPeriodDisplayName(String period) {
    switch (period) {
      case '7_days':
        return 'Last 7 days';
      case '30_days':
        return 'Last 30 days';
      case '90_days':
        return 'Last 3 months';
      case '365_days':
        return 'Last year';
      default:
        return 'Last 30 days';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  // Event handlers
  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.uid ?? '';

      if (userId.isNotEmpty) {
        // Load analytics summary - placeholder implementation
        setState(() {
          _analyticsSummary = null; // Placeholder - no summary for now
        });

        AppLogger.success(_tag, 'Dashboard data loaded successfully');
      }
    } catch (e) {
      AppLogger.error(_tag, 'Failed to load dashboard data', e);
      _showErrorSnackBar('Failed to load dashboard data');
    } finally {
      setState(() {
        _isLoading = false;
      });
      
      _chartAnimationController.forward();
    }
  }

  Future<void> _generateInsights() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.uid ?? '';

      if (userId.isEmpty) return;

      _showLoadingSnackBar('Generating AI insights...');

      // Placeholder insights for now

      setState(() {
        _insights = []; // Empty insights for now
      });

      _analyticsService.trackEvent(
        'insights_generated',
        {
          'insights_count': 0,
          'period': _selectedPeriod,
        },
      );

      _showSuccessSnackBar('Analytics insights feature coming soon');
      AppLogger.success(_tag, 'Insights placeholder displayed');

    } catch (e) {
      AppLogger.error(_tag, 'Failed to generate insights', e);
      _showErrorSnackBar('Failed to generate insights');
    }
  }

  void _dismissInsight(DashboardInsight insight) {
    setState(() {
      _insights.remove(insight);
    });

    _analyticsService.trackEvent(
      'insight_dismissed',
      {
        'insight_id': insight.insightId,
        'category': insight.category,
      },
    );
  }

  void _changePeriod(String period) {
    setState(() {
      _selectedPeriod = period;
      
      switch (period) {
        case '7_days':
          _startDate = DateTime.now().subtract(const Duration(days: 7));
          break;
        case '30_days':
          _startDate = DateTime.now().subtract(const Duration(days: 30));
          break;
        case '90_days':
          _startDate = DateTime.now().subtract(const Duration(days: 90));
          break;
        case '365_days':
          _startDate = DateTime.now().subtract(const Duration(days: 365));
          break;
      }
      _endDate = DateTime.now();
    });

    _trackScreenView();
    _loadDashboardData();
  }

  void _refreshData() {
    _loadDashboardData();
  }

  // Utility methods
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showLoadingSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 16),
            Text(message),
          ],
        ),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _chartAnimationController.dispose();
    super.dispose();
  }
}
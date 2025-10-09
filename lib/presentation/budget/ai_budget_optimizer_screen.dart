import 'package:flutter/material.dart';

import '../../core/models/trip_model.dart' as trip_models;
import '../../services/ai/ai_budget_service.dart';

class AIBudgetOptimizerScreen extends StatefulWidget {
  final trip_models.Trip? trip;

  const AIBudgetOptimizerScreen({
    super.key,
    this.trip,
  });

  @override
  State<AIBudgetOptimizerScreen> createState() =>
      _AIBudgetOptimizerScreenState();
}

class _AIBudgetOptimizerScreenState extends State<AIBudgetOptimizerScreen>
    with SingleTickerProviderStateMixin {
  final AIBudgetService _aiBudgetService = AIBudgetService();
  
  late TabController _tabController;
  bool _isOptimizing = false;
  
  // Results
  BudgetOptimizationResult? _optimizationResult;
  SpendingRecommendation? _spendingRecommendation;
  BudgetHealthReport? _healthReport;
  List<MoneySavingTip>? _savingTips;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Auto-load if trip is provided
    if (widget.trip != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadAllData();
      });
    }
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadAllData() async {
    if (widget.trip == null) return;
    
    setState(() => _isOptimizing = true);
    
    try {
      final results = await Future.wait([
        _aiBudgetService.optimizeBudget(
          trip: widget.trip!,
          totalBudget: widget.trip!.budget?.totalBudget ?? 1000,
        ),
        _aiBudgetService.getSpendingRecommendation(trip: widget.trip!),
        _aiBudgetService.analyzeBudgetHealth(trip: widget.trip!),
        _aiBudgetService.getMoneySavingTips(
          destination: widget.trip!.title,
          dailyBudget: (widget.trip!.budget?.totalBudget ?? 1000) / 7,
        ),
      ]);
      
      setState(() {
        _optimizationResult = results[0] as BudgetOptimizationResult;
        _spendingRecommendation = results[1] as SpendingRecommendation;
        _healthReport = results[2] as BudgetHealthReport;
        _savingTips = results[3] as List<MoneySavingTip>;
      });
    } catch (e) {
      _showError('Failed to load budget data: $e');
    } finally {
      setState(() => _isOptimizing = false);
    }
  }
  
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
  
  Color _getColorFromString(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'green':
        return Colors.green;
      case 'yellow':
      case 'orange':
        return Colors.orange;
      case 'red':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Budget Optimizer'),
        actions: [
          if (widget.trip != null && !_isOptimizing)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadAllData,
              tooltip: 'Refresh',
            ),
        ],
        bottom: _optimizationResult != null
            ? TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: const [
                  Tab(text: 'Optimization', icon: Icon(Icons.pie_chart)),
                  Tab(text: 'Spending', icon: Icon(Icons.trending_up)),
                  Tab(text: 'Health', icon: Icon(Icons.favorite)),
                  Tab(text: 'Tips', icon: Icon(Icons.lightbulb)),
                ],
              )
            : null,
      ),
      body: widget.trip == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.account_balance_wallet, size: 100, color: Colors.grey[300]),
                  const SizedBox(height: 24),
                  Text(
                    'No Trip Selected',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Please open this from a trip to optimize budget',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : _isOptimizing
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Analyzing your budget with AI...'),
                    ],
                  ),
                )
              : _optimizationResult == null
                  ? Center(
                      child: ElevatedButton.icon(
                        onPressed: _loadAllData,
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text('Optimize Budget'),
                      ),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildOptimizationTab(),
                        _buildSpendingTab(),
                        _buildHealthTab(),
                        _buildTipsTab(),
                      ],
                    ),
    );
  }
  
  Widget _buildOptimizationTab() {
    if (_optimizationResult == null) return const SizedBox();
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Budget', style: TextStyle(fontSize: 18)),
                    Text(
                      '\$${_optimizationResult!.totalBudget.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Daily Budget'),
                    Text('\$${_optimizationResult!.dailyBudget.toStringAsFixed(0)}'),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Assessment: ${_optimizationResult!.assessment.level}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(_optimizationResult!.assessment.description),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Category Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...(_optimizationResult!.categories.map((category) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(_getCategoryIcon(category.name)),
                title: Text(category.name),
                subtitle: LinearProgressIndicator(
                  value: category.percentage / 100,
                  backgroundColor: Colors.grey[200],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${category.totalAmount.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('${category.percentage}%', style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ))),
      ],
    );
  }
  
  Widget _buildSpendingTab() {
    if (_spendingRecommendation == null) return const SizedBox();
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: _getSpendingStatusColor(_spendingRecommendation!.status),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  'Spending Status',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  _spendingRecommendation!.status,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('AI Recommendation', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(_spendingRecommendation!.message),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('Remaining Daily Budget'),
            trailing: Text(
              '\$${_spendingRecommendation!.remainingDailyBudget.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        if (_spendingRecommendation!.actionItems.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('Action Items', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ...(_spendingRecommendation!.actionItems.map(
            (action) => Card(
              child: ListTile(
                leading: const Icon(Icons.check_circle_outline),
                title: Text(action),
              ),
            ),
          )),
        ],
      ],
    );
  }
  
  Widget _buildHealthTab() {
    if (_healthReport == null) return const SizedBox();
    
    final statusColor = _getColorFromString(_healthReport!.color);
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Text('Budget Health Score', style: TextStyle(fontSize: 18)),
                const SizedBox(height: 16),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 150,
                      height: 150,
                      child: CircularProgressIndicator(
                        value: _healthReport!.healthScore / 100,
                        strokeWidth: 12,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                      ),
                    ),
                    Column(
                      children: [
                        Text(
                          '${_healthReport!.healthScore}',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                        Text(
                          _healthReport!.status,
                          style: TextStyle(color: statusColor),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Analysis', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(_healthReport!.analysis),
              ],
            ),
          ),
        ),
        if (_healthReport!.categoryHealth.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('Category Health', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ...(_healthReport!.categoryHealth.map((ch) => Card(
                child: ListTile(
                  leading: Icon(_getCategoryIcon(ch.category)),
                  title: Text(ch.category),
                  subtitle: Text(ch.message),
                  trailing: Text(
                    ch.status,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getColorFromString(ch.status),
                    ),
                  ),
                ),
              ))),
        ],
        if (_healthReport!.recommendations.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('Recommendations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ...(_healthReport!.recommendations.map(
            (rec) => Card(
              child: ListTile(
                leading: const Icon(Icons.recommend, color: Colors.blue),
                title: Text(rec),
              ),
            ),
          )),
        ],
      ],
    );
  }
  
  Widget _buildTipsTab() {
    if (_savingTips == null || _savingTips!.isEmpty) {
      return const Center(child: Text('No saving tips available'));
    }
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Money-Saving Tips', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...(_savingTips!.map((tip) {
          Color priorityColor;
          switch (tip.priority) {
            case 'high':
              priorityColor = Colors.red;
              break;
            case 'medium':
              priorityColor = Colors.orange;
              break;
            default:
              priorityColor = Colors.green;
          }
          
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(_getCategoryIcon(tip.category), size: 20),
                      const SizedBox(width: 8),
                      Expanded(child: Text(tip.category, style: const TextStyle(fontSize: 12))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: priorityColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          tip.priority.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(tip.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(tip.description),
                  if (tip.potentialSavings.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.savings, size: 16, color: Colors.green),
                          const SizedBox(width: 4),
                          Text(
                            'Save: ${tip.potentialSavings}',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        })),
      ],
    );
  }
  
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'accommodation':
        return Icons.hotel;
      case 'food & dining':
      case 'food':
        return Icons.restaurant;
      case 'transportation':
      case 'transport':
        return Icons.directions_car;
      case 'activities & attractions':
      case 'activities':
        return Icons.local_activity;
      case 'shopping & souvenirs':
      case 'shopping':
        return Icons.shopping_bag;
      case 'emergency & miscellaneous':
      case 'emergency':
        return Icons.medical_services;
      default:
        return Icons.attach_money;
    }
  }
  
  Color _getSpendingStatusColor(String status) {
    if (status.toLowerCase().contains('under')) {
      return Colors.green;
    } else if (status.toLowerCase().contains('over')) {
      return Colors.red;
    }
    return Colors.orange;
  }
}

import 'package:flutter/material.dart';
import '../../core/config/service_locator.dart';
import '../../core/utils/logger.dart';

/// DI Monitoring Screen
/// Demonstrates dependency injection with real-time service monitoring
class DIMonitoringScreen extends StatefulWidget {
  const DIMonitoringScreen({super.key});

  @override
  State<DIMonitoringScreen> createState() => _DIMonitoringScreenState();
}

class _DIMonitoringScreenState extends State<DIMonitoringScreen> {
  final Map<String, bool> _serviceStatus = {};
  final Map<String, String> _serviceMessages = {};

  @override
  void initState() {
    super.initState();
    _checkAllServices();
  }

  Future<void> _checkAllServices() async {
    setState(() {
      _serviceStatus.clear();
      _serviceMessages.clear();
    });

    // Check Analytics Service
    await _testService(
      'Analytics Service',
      () async {
        final _ = ServiceLocator.analyticsService;
        // Just check service initialization
        return 'Service initialized successfully';
      },
    );

    // Check Chat Service
    await _testService(
      'Chat Service',
      () async {
        final service = ServiceLocator.chatService;
        final conversations = await service.getUserConversations(limit: 1);
        return 'Retrieved ${conversations.length} conversations';
      },
    );

    // Check Gallery Service
    await _testService(
      'Gallery Service',
      () async {
        final _ = ServiceLocator.galleryService;
        return 'Service initialized successfully';
      },
    );

    // Check Friend Service
    await _testService(
      'Friend Service',
      () async {
        final service = ServiceLocator.friendService;
        final friends = await service.getFriends();
        return 'Retrieved ${friends.length} friends';
      },
    );

    // Check Itinerary Service
    await _testService(
      'Itinerary Service',
      () async {
        final _ = ServiceLocator.itineraryService;
        // Just check service initialization
        return 'Service initialized successfully';
      },
    );

    // Check Review Service
    await _testService(
      'Review Service',
      () async {
        final service = ServiceLocator.reviewService;
        final reviews = await service.getUserReviews(userId: 'test-user');
        return 'Retrieved ${reviews.length} reviews';
      },
    );

    // Check Weather Service
    await _testService(
      'Weather Service',
      () async {
        final service = ServiceLocator.weatherService;
        // Just check service initialization
        return 'Service ${service.runtimeType} initialized';
      },
    );

    // Check AI Service
    await _testService(
      'AI Service',
      () async {
        final service = ServiceLocator.aiService;
        final stats = await service.getUsageStatistics();
        return 'Total AI requests: ${stats['total_requests']}';
      },
    );

    // Check Tourism Service
    await _testService(
      'Tourism Service',
      () async {
        final service = ServiceLocator.tourismService;
        final provinces = await service.getProvinces();
        return 'Retrieved ${provinces.length} provinces';
      },
    );

    // Check Community Service
    await _testService(
      'Community Service',
      () async {
        final service = ServiceLocator.communityService;
        final communities = await service.getCommunities(limit: 1);
        return 'Retrieved ${communities.length} communities';
      },
    );
  }

  Future<void> _testService(String name, Future<String> Function() test) async {
    try {
      AppLogger.debug('DIMonitoring', 'Testing $name...');
      final message = await test();
      setState(() {
        _serviceStatus[name] = true;
        _serviceMessages[name] = message;
      });
      AppLogger.success('DIMonitoring', '$name: $message');
    } catch (e, stackTrace) {
      setState(() {
        _serviceStatus[name] = false;
        _serviceMessages[name] = 'Error: ${e.toString()}';
      });
      AppLogger.error('DIMonitoring', 'Failed to test $name', e, stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DI Service Monitoring'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _checkAllServices,
            tooltip: 'Refresh All Services',
          ),
        ],
      ),
      body: _serviceStatus.isEmpty
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _checkAllServices,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSummaryCard(),
                  const SizedBox(height: 16),
                  ..._serviceStatus.keys.map((serviceName) {
                    final isHealthy = _serviceStatus[serviceName] ?? false;
                    final message = _serviceMessages[serviceName] ?? '';
                    return _buildServiceCard(serviceName, isHealthy, message);
                  }),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard() {
    final total = _serviceStatus.length;
    final healthy = _serviceStatus.values.where((status) => status).length;
    final unhealthy = total - healthy;
    final healthPercentage = total > 0 ? (healthy / total * 100).toStringAsFixed(0) : '0';

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.analytics, size: 32, color: Colors.blue),
                SizedBox(width: 12),
                Text(
                  'Service Health',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn('Total', total.toString(), Colors.blue),
                _buildStatColumn('Healthy', healthy.toString(), Colors.green),
                _buildStatColumn('Errors', unhealthy.toString(), Colors.red),
                _buildStatColumn('Health', '$healthPercentage%', 
                    healthy == total ? Colors.green : Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildServiceCard(String name, bool isHealthy, String message) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          isHealthy ? Icons.check_circle : Icons.error,
          color: isHealthy ? Colors.green : Colors.red,
          size: 32,
        ),
        title: Text(
          name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          message,
          style: TextStyle(
            color: isHealthy ? Colors.green[700] : Colors.red[700],
          ),
        ),
        trailing: isHealthy
            ? const Icon(Icons.arrow_forward_ios, size: 16)
            : IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: () {
                  _showErrorDetails(name, message);
                },
              ),
      ),
    );
  }

  void _showErrorDetails(String serviceName, String errorMessage) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$serviceName Error'),
        content: SingleChildScrollView(
          child: Text(errorMessage),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _checkAllServices();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

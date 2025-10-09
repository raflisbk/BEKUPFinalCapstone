import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/logger.dart';

/// Simple AI Route Planning screen following app's design system
class SimpleRoutePlanningScreen extends StatefulWidget {
  const SimpleRoutePlanningScreen({super.key});

  @override
  State<SimpleRoutePlanningScreen> createState() => _SimpleRoutePlanningScreenState();
}

class _SimpleRoutePlanningScreenState extends State<SimpleRoutePlanningScreen> {
  static const String _tag = 'SimpleRoutePlanningScreen';
  
  final TextEditingController _originController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  bool _isPlanning = false;
  String _selectedMode = 'driving';
  
  final List<Map<String, dynamic>> _travelModes = [
    {'id': 'driving', 'name': 'Driving', 'icon': Icons.directions_car},
    {'id': 'walking', 'name': 'Walking', 'icon': Icons.directions_walk},
    {'id': 'transit', 'name': 'Transit', 'icon': Icons.directions_transit},
    {'id': 'bicycling', 'name': 'Cycling', 'icon': Icons.directions_bike},
  ];

  @override
  void initState() {
    super.initState();
    AppLogger.debug(_tag, 'Simple Route Planning screen initialized');
  }

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  void _planRoute() async {
    if (_originController.text.isEmpty || _destinationController.text.isEmpty) {
      _showError('Please enter both origin and destination');
      return;
    }

    setState(() {
      _isPlanning = true;
    });

    AppLogger.action('User planning route', {
      'origin': _originController.text,
      'destination': _destinationController.text,
      'mode': _selectedMode,
    });

    // Simulate AI route planning
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isPlanning = false;
    });

    _showRoutePlanned();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _showRoutePlanned() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Route planned successfully! AI suggestions ready.'),
        backgroundColor: AppColors.success,
        action: SnackBarAction(
          label: 'View',
          textColor: AppColors.white,
          onPressed: () {
            // Navigate to detailed route view
          },
        ),
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
            Icon(Icons.directions, size: 24),
            SizedBox(width: 8),
            Text('AI Route Planning'),
          ],
        ),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero section
            FadeInDown(
              duration: const Duration(milliseconds: 600),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.grey100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.auto_awesome,
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
                                'AI-Powered Route Planning',
                                style: AppTextStyles.titleLarge.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Get optimized routes with intelligent suggestions',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Route input form
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
                      'Plan Your Route',
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Origin input
                    _buildLocationInput(
                      controller: _originController,
                      label: 'From',
                      hint: 'Enter starting location',
                      icon: Icons.my_location,
                    ),

                    const SizedBox(height: 16),

                    // Destination input
                    _buildLocationInput(
                      controller: _destinationController,
                      label: 'To',
                      hint: 'Enter destination',
                      icon: Icons.location_on,
                    ),

                    const SizedBox(height: 20),

                    // Travel mode selector
                    const Text(
                      'Travel Mode',
                      style: AppTextStyles.labelLarge,
                    ),
                    const SizedBox(height: 12),
                    _buildTravelModeSelector(),

                    const SizedBox(height: 24),

                    // Plan route button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isPlanning ? null : _planRoute,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.black,
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isPlanning
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        AppColors.white,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text('Planning Route...'),
                                ],
                              )
                            : const Text('Plan Route with AI'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // AI Features info
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
                    Row(
                      children: [
                        const Icon(Icons.lightbulb_outline, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'AI Features',
                          style: AppTextStyles.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildFeatureItem(
                      Icons.route,
                      'Smart Route Optimization',
                      'AI analyzes traffic patterns and suggests optimal routes',
                    ),
                    _buildFeatureItem(
                      Icons.traffic,
                      'Real-time Traffic Analysis',
                      'Avoid congestion with live traffic data integration',
                    ),
                    _buildFeatureItem(
                      Icons.savings,
                      'Cost-Efficient Planning',
                      'Get routes optimized for fuel efficiency and tolls',
                    ),
                    _buildFeatureItem(
                      Icons.explore,
                      'POI Recommendations',
                      'Discover interesting stops along your route',
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

  Widget _buildLocationInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelLarge,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textTertiary),
            prefixIcon: Icon(icon, color: AppColors.textSecondary),
            filled: true,
            fillColor: AppColors.grey50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.black, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTravelModeSelector() {
    return Row(
      children: _travelModes.map((mode) {
        final isSelected = _selectedMode == mode['id'];
        return Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedMode = mode['id'];
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.black : AppColors.grey50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? AppColors.black : AppColors.border,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    mode['icon'],
                    color: isSelected ? AppColors.white : AppColors.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    mode['name'],
                    style: AppTextStyles.labelSmall.copyWith(
                      color: isSelected ? AppColors.white : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
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

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.grey100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.labelLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
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
}
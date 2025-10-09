import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../explore/ai_recommendations_screen.dart';
import '../chat/ai_chat_screen.dart';
import '../gallery/ai_image_analysis_screen.dart';
import '../budget/ai_budget_optimizer_screen.dart';

/// Central hub for all AI-powered features
class AIFeaturesScreen extends StatelessWidget {
  const AIFeaturesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey50,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, size: 24),
            SizedBox(width: 8),
            Text('AI Travel Assistant'),
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
            // Hero header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.purple.shade700,
                    Colors.blue.shade600,
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.psychology,
                          color: AppColors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Powered by AI',
                              style: TextStyle(
                                color: AppColors.white.withValues(alpha: 0.9),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              'Google Gemini 2.0',
                              style: AppTextStyles.titleLarge.copyWith(
                                color: AppColors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your intelligent travel companion. Plan smarter, discover more, and travel better with AI-powered insights.',
                    style: TextStyle(
                      color: AppColors.white.withValues(alpha: 0.95),
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Features grid
            Text(
              'AI Features',
              style: AppTextStyles.headlineSmall.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            _buildFeatureCard(
              context,
              icon: Icons.map,
              title: 'Smart Trip Planner',
              description:
                  'Generate personalized day-by-day itineraries based on your preferences',
              gradient: LinearGradient(
                colors: [Colors.blue.shade600, Colors.blue.shade400],
              ),
              onTap: () {
                Navigator.pushNamed(context, '/ai-itinerary-generator');
              },
            ),

            _buildFeatureCard(
              context,
              icon: Icons.explore,
              title: 'Personalized Recommendations',
              description:
                  'Discover destinations tailored to your travel style and history',
              gradient: LinearGradient(
                colors: [Colors.purple.shade600, Colors.purple.shade400],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AIRecommendationsScreen(),
                  ),
                );
              },
            ),

            _buildFeatureCard(
              context,
              icon: Icons.chat_bubble,
              title: 'AI Travel Assistant',
              description:
                  'Ask anything about travel, get instant expert advice',
              gradient: LinearGradient(
                colors: [Colors.green.shade600, Colors.green.shade400],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AIChatScreen(),
                  ),
                );
              },
            ),

            _buildFeatureCard(
              context,
              icon: Icons.photo_camera,
              title: 'Image Recognition',
              description:
                  'Identify landmarks, get captions, and photography tips',
              gradient: LinearGradient(
                colors: [Colors.orange.shade600, Colors.orange.shade400],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AIImageAnalysisScreen(),
                  ),
                );
              },
            ),

            _buildFeatureCard(
              context,
              icon: Icons.account_balance_wallet,
              title: 'Budget Optimizer',
              description:
                  'Smart budget allocation and spending recommendations',
              gradient: LinearGradient(
                colors: [Colors.teal.shade600, Colors.teal.shade400],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AIBudgetOptimizerScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 32),

            // Info section
            Container(
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
                      const Icon(Icons.info_outline, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'How It Works',
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInfoItem(
                    '1. Personalized',
                    'AI learns from your preferences and travel history',
                  ),
                  _buildInfoItem(
                    '2. Context-Aware',
                    'Considers your trip details, budget, and destination',
                  ),
                  _buildInfoItem(
                    '3. Real-Time',
                    'Get instant recommendations and adjustments',
                  ),
                  _buildInfoItem(
                    '4. Constantly Learning',
                    'Improves recommendations as you use the app',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Privacy note
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.shield, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your data is secure and used only to improve your travel experience',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 120,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
              child: Icon(
                icon,
                color: AppColors.white,
                size: 36,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String title, String description) {
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
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
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

<<<<<<< HEAD

=======
  void _showComingSoonDialog(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.rocket_launch, color: Colors.purple),
            const SizedBox(width: 12),
            Text('$feature UI'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'The $feature feature is fully implemented and ready to use!',
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 12),
            const Text(
              'UI screens for this feature will be added in the next update.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
>>>>>>> 2ddae3e (refactor: clean up codebase and resolve all Flutter hints)
}

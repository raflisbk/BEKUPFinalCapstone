import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/ai_recommendations_ui_provider.dart';
import '../../core/models/ai_models.dart';
import '../../services/ai/ai_recommendation_service.dart';
import '../destinations/destination_detail_new_screen.dart';

/// Screen showing personalized AI-powered destination recommendations
class AIRecommendationsScreen extends StatefulWidget {
  const AIRecommendationsScreen({super.key});

  @override
  State<AIRecommendationsScreen> createState() =>
      _AIRecommendationsScreenState();
}

class _AIRecommendationsScreenState extends State<AIRecommendationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRecommendations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRecommendations() async {
    final uiProvider = context.read<AIRecommendationsUIProvider>();

    uiProvider.setLoading(true);
    uiProvider.clearError();

    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.user?.uid;

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Load personalized recommendations using available method
      final personalizedData = await AIRecommendationService.getPersonalizedRecommendations(
        userId: userId,
        limit: 15,
      );

      // Convert to DestinationRecommendation objects
      final personalizedRecs = personalizedData.map((data) {
        return DestinationRecommendation.fromMap(data);
      }).toList();

      // For trending, we'll use destination recommendations as placeholder
      final trendingData = await AIRecommendationService.getDestinationRecommendations(
        userId: userId,
        limit: 10,
      );

      final trendingRecs = trendingData.map((data) {
        return DestinationRecommendation.fromMap(data);
      }).toList();

      if (mounted) {
        uiProvider.setRecommendations(
          personalized: personalizedRecs,
          trending: trendingRecs,
          loading: false,
        );
      }
    } catch (e) {
      if (mounted) {
        uiProvider.setError(e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AIRecommendationsUIProvider>(
      builder: (context, uiProvider, child) {
        return Scaffold(
          backgroundColor: AppColors.white,
          appBar: AppBar(
            title: const Row(
              children: [
                Icon(Icons.psychology, size: 24),
                SizedBox(width: 8),
                Text('AI Recommendations'),
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
              tabs: const [
                Tab(text: 'For You'),
                Tab(text: 'Trending'),
              ],
            ),
          ),
          body: _buildBody(uiProvider),
        );
      },
    );
  }

  Widget _buildBody(AIRecommendationsUIProvider uiProvider) {
    if (uiProvider.isLoading && uiProvider.personalizedRecs == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.black),
            SizedBox(height: 16),
            Text(
              'AI is analyzing your preferences...',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    if (uiProvider.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Failed to load recommendations',
                style: AppTextStyles.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                uiProvider.error!,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadRecommendations,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.black,
                  foregroundColor: AppColors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildPersonalizedTab(uiProvider),
        _buildTrendingTab(uiProvider),
      ],
    );
  }

  Widget _buildPersonalizedTab(AIRecommendationsUIProvider uiProvider) {
    if (uiProvider.personalizedRecs == null ||
        uiProvider.personalizedRecs!.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.travel_explore,
                size: 64,
                color: AppColors.textSecondary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              const Text(
                'No recommendations yet',
                style: AppTextStyles.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Start exploring destinations and planning trips to get personalized recommendations',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRecommendations,
      color: AppColors.black,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: uiProvider.personalizedRecs!.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildPersonalizedHeader();
          }

          final rec = uiProvider.personalizedRecs![index - 1];
          return _buildRecommendationCard(rec);
        },
      ),
    );
  }

  Widget _buildPersonalizedHeader() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.black, AppColors.black.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.stars, color: AppColors.white, size: 32),
          const SizedBox(height: 12),
          Text(
            'Picked Just for You',
            style: AppTextStyles.headlineSmall.copyWith(color: AppColors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Based on your travel history, preferences, and places you\'ve loved',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingTab(AIRecommendationsUIProvider uiProvider) {
    if (uiProvider.trendingRecs == null || uiProvider.trendingRecs!.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.black),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRecommendations,
      color: AppColors.black,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: uiProvider.trendingRecs!.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildTrendingHeader();
          }

          final rec = uiProvider.trendingRecs![index - 1];
          return _buildRecommendationCard(rec);
        },
      ),
    );
  }

  Widget _buildTrendingHeader() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade700, Colors.orange.shade500],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.trending_up, color: AppColors.white, size: 32),
          const SizedBox(height: 12),
          Text(
            'Trending Now',
            style: AppTextStyles.headlineSmall.copyWith(color: AppColors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Popular destinations travelers are loving right now',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(DestinationRecommendation rec) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DestinationDetailNewScreen(destinationId: rec.id),
          ),
        );
      },
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: rec.imageUrl.isNotEmpty
                      ? Image.network(
                          rec.imageUrl,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 180,
                            color: AppColors.grey50,
                            child: const Icon(Icons.image, size: 48),
                          ),
                        )
                      : Container(
                          height: 180,
                          color: AppColors.grey50,
                          child: const Icon(Icons.image, size: 48),
                        ),
                ),
                // Match score badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getMatchColor(rec.matchScore.toInt()),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star,
                          color: AppColors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${rec.matchScore.toInt()}% Match',
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and rating
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          rec.name,
                          style: AppTextStyles.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            size: 16,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            rec.rating.toStringAsFixed(1),
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Location and price
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          rec.location,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // AI insights
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.lightbulb,
                              size: 16,
                              color: Colors.blue.shade700,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Why we recommend this',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          rec.reason,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Tags/Categories
                  if (rec.tags.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: rec.tags.take(3).map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.grey50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.grey200),
                          ),
                          child: Text(
                            tag,
                            style: AppTextStyles.bodySmall.copyWith(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getMatchColor(int score) {
    if (score >= 90) return Colors.green.shade600;
    if (score >= 80) return Colors.blue.shade600;
    if (score >= 70) return Colors.orange.shade600;
    return Colors.grey.shade600;
  }
}

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/haptic_helper.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../core/config/service_locator.dart';
import '../../core/interfaces/i_community_service.dart';
import 'community_posts_screen.dart';
import 'community_events_screen.dart';
import 'community_members_screen.dart';

/// Detailed view of a community with tabs for posts, events, members, and about
class CommunityDetailScreen extends StatefulWidget {
  final String communityId;

  const CommunityDetailScreen({
    super.key,
    required this.communityId,
  });

  @override
  State<CommunityDetailScreen> createState() => _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends State<CommunityDetailScreen>
    with SingleTickerProviderStateMixin {
  static const String _tag = 'CommunityDetailScreen';
  
  final ICommunityService _communityService = ServiceLocator.iCommunityService;
  
  Map<String, dynamic>? _community;
  bool _isLoading = true;
  bool _isJoining = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    AppLogger.debug(_tag, 'Community detail screen initialized: ${widget.communityId}');
    _loadCommunity();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCommunity() async {
    try {
      setState(() => _isLoading = true);
      
        final community = await _communityService.getCommunity(
          widget.communityId,
        );
      
      setState(() {
        _community = community;
        _isLoading = false;
      });
      
      AppLogger.success(_tag, 'Loaded community: ${community?['name']}');
    } catch (e) {
      AppLogger.error(_tag, 'Failed to load community', e);
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load community: $e')),
        );
      }
    }
  }

  Future<void> _toggleJoinCommunity() async {
    final isMember = _community?['is_member'] == true;
    
    try {
      setState(() => _isJoining = true);
      HapticHelper.mediumImpact();
      
      if (isMember) {
          await _communityService.leaveCommunity(widget.communityId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Left community')),
          );
        }
      } else {
          await _communityService.joinCommunity(widget.communityId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Joined community successfully!')),
          );
        }
      }
      
      _loadCommunity(); // Reload to update status
    } catch (e) {
      AppLogger.error(_tag, 'Failed to toggle join', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isJoining = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey50,
      body: _isLoading ? _buildLoadingState() : _buildContent(),
    );
  }

  Widget _buildLoadingState() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: SkeletonLoader.container(
              width: double.infinity,
              height: 200,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Column(
            children: [
              const SizedBox(height: 16),
              SkeletonLoader.container(width: 200, height: 24),
              const SizedBox(height: 8),
              SkeletonLoader.container(width: 150, height: 16),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_community == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.groups_outlined, size: 80, color: AppColors.grey400),
            SizedBox(height: 16),
            Text(
              'Community not found',
              style: AppTextStyles.titleLarge,
            ),
          ],
        ),
      );
    }

    final isMember = _community!['is_member'] == true;
    final userRole = _community!['user_role'] as String?;
    final coverImageUrl = _community!['cover_image_url'] as String?;

    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Cover image
                  if (coverImageUrl != null)
                    Image.network(
                      coverImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildDefaultCover(),
                    )
                  else
                    _buildDefaultCover(),
                  
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                  
                  // Community info
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            (_community!['category'] ?? 'General').toString().toUpperCase(),
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Name
                        Text(
                          _community!['name'] ?? 'Unnamed Community',
                          style: AppTextStyles.headlineMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // Stats
                        Row(
                          children: [
                            _buildStatItem(
                              Icons.people,
                              '${_community!['member_count'] ?? 0} members',
                            ),
                            const SizedBox(width: 16),
                            _buildStatItem(
                              Icons.article,
                              '${_community!['post_count'] ?? 0} posts',
                            ),
                            const SizedBox(width: 16),
                            _buildStatItem(
                              Icons.event,
                              '${_community!['event_count'] ?? 0} events',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Join button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _isJoining ? null : _toggleJoinCommunity,
                      icon: Icon(
                        isMember ? Icons.check : Icons.add,
                        size: 20,
                      ),
                      label: Text(
                        _isJoining
                            ? 'Loading...'
                            : isMember
                                ? 'Joined${userRole != null ? ' • $userRole' : ''}'
                                : 'Join Community',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isMember
                            ? AppColors.grey200
                            : AppColors.primary,
                        foregroundColor: isMember
                            ? AppColors.textPrimary
                            : Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Tabs
                  TabBar(
                    controller: _tabController,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textSecondary,
                    indicatorColor: AppColors.primary,
                    labelStyle: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    tabs: const [
                      Tab(text: 'Posts'),
                      Tab(text: 'Events'),
                      Tab(text: 'Members'),
                      Tab(text: 'About'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ];
      },
      body: TabBarView(
        controller: _tabController,
        children: [
          CommunityPostsScreen(communityId: widget.communityId),
          CommunityEventsScreen(communityId: widget.communityId),
          CommunityMembersScreen(communityId: widget.communityId),
          _buildAboutTab(),
        ],
      ),
    );
  }

  Widget _buildDefaultCover() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.groups,
          size: 80,
          color: Colors.white38,
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.white),
        const SizedBox(width: 4),
        Text(
          text,
          style: AppTextStyles.bodySmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildAboutTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description
          Text(
            'Description',
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _community!['description'] ?? 'No description available',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          
          // Tags
          if (_community!['tags'] != null && (_community!['tags'] as List).isNotEmpty) ...[
            Text(
              'Tags',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (_community!['tags'] as List).map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    tag.toString(),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],
          
          // Rules
          if (_community!['rules'] != null && (_community!['rules'] as List).isNotEmpty) ...[
            Text(
              'Community Rules',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...(_community!['rules'] as List).asMap().entries.map((entry) {
              final index = entry.key;
              final rule = entry.value as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
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
                            rule['title'] ?? 'Rule ${index + 1}',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (rule['description'] != null)
                            Text(
                              rule['description'],
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
            }),
          ],
        ],
      ),
    );
  }
}

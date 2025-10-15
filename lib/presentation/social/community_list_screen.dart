import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/haptic_helper.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/config/service_locator.dart';
import '../../core/interfaces/i_community_service.dart';
import 'community_detail_screen.dart';
import 'create_community_screen.dart';

/// Screen to browse and search communities
class CommunityListScreen extends StatefulWidget {
  const CommunityListScreen({super.key});

  @override
  State<CommunityListScreen> createState() => _CommunityListScreenState();
}

class _CommunityListScreenState extends State<CommunityListScreen> {
  static const String _tag = 'CommunityListScreen';
  
  final ICommunityService _communityService = ServiceLocator.iCommunityService;
  final TextEditingController _searchController = TextEditingController();
  
  List<Map<String, dynamic>> _communities = [];
  bool _isLoading = true;
  String? _selectedCategory;
  String? _selectedVisibility;
  
  // Categories
  final List<Map<String, dynamic>> _categories = [
    {'id': null, 'name': 'All', 'icon': Icons.grid_view},
    {'id': 'travel', 'name': 'Travel', 'icon': Icons.flight},
    {'id': 'destination', 'name': 'Destinations', 'icon': Icons.place},
    {'id': 'activity', 'name': 'Activities', 'icon': Icons.hiking},
    {'id': 'food', 'name': 'Food', 'icon': Icons.restaurant},
    {'id': 'culture', 'name': 'Culture', 'icon': Icons.museum},
    {'id': 'photography', 'name': 'Photography', 'icon': Icons.camera_alt},
    {'id': 'budget', 'name': 'Budget Travel', 'icon': Icons.savings},
  ];

  @override
  void initState() {
    super.initState();
    AppLogger.debug(_tag, 'Community list screen initialized');
    _loadCommunities();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCommunities() async {
    try {
      setState(() => _isLoading = true);
      
      final communities = await _communityService.getCommunities(
        category: _selectedCategory,
        visibility: _selectedVisibility,
        search: _searchController.text.isEmpty ? null : _searchController.text,
        limit: 50,
      );
      
      setState(() {
        _communities = communities;
        _isLoading = false;
      });
      
      AppLogger.success(_tag, 'Loaded ${communities.length} communities');
    } catch (e) {
      AppLogger.error(_tag, 'Failed to load communities', e);
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load communities: $e')),
        );
      }
    }
  }

  Future<void> _joinCommunity(String communityId) async {
    try {
      HapticHelper.mediumImpact();
      await _communityService.joinCommunity(communityId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Joined community successfully!')),
        );
      }
      
      _loadCommunities(); // Reload to update join status
    } catch (e) {
      AppLogger.error(_tag, 'Failed to join community', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to join: $e')),
        );
      }
    }
  }

  Future<void> _leaveCommunity(String communityId) async {
    try {
      HapticHelper.mediumImpact();
      await _communityService.leaveCommunity(communityId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Left community')),
        );
      }
      
      _loadCommunities(); // Reload to update join status
    } catch (e) {
      AppLogger.error(_tag, 'Failed to leave community', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to leave: $e')),
        );
      }
    }
  }

  void _navigateToCreateCommunity() {
    HapticHelper.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CreateCommunityScreen(),
      ),
    ).then((_) => _loadCommunities());
  }

  void _navigateToCommunityDetail(Map<String, dynamic> community) {
    HapticHelper.selectionClick();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CommunityDetailScreen(communityId: community['id']),
      ),
    ).then((_) => _loadCommunities());
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    return Scaffold(
      backgroundColor: AppColors.grey50,
      appBar: AppBar(
        title: const Text('Communities'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.black,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.grey200),
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildCategoryFilter(),
          Expanded(
            child: _isLoading ? _buildLoadingState() : _buildCommunityList(),
          ),
        ],
      ),
      floatingActionButton: authProvider.isAuthenticated && !authProvider.isGuest
          ? FloatingActionButton.extended(
              onPressed: _navigateToCreateCommunity,
              icon: const Icon(Icons.add),
              label: const Text('Create'),
              backgroundColor: AppColors.primary,
            )
          : null,
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search communities...',
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    _loadCommunities();
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.grey100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        onChanged: (_) => _loadCommunities(),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        height: 48,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            final category = _categories[index];
            final isSelected = _selectedCategory == category['id'];
            
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      category['icon'] as IconData,
                      size: 16,
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(category['name'] as String),
                  ],
                ),
                selected: isSelected,
                onSelected: (selected) {
                  HapticHelper.selectionClick();
                  setState(() {
                    _selectedCategory = selected ? category['id'] as String? : null;
                  });
                  _loadCommunities();
                },
                backgroundColor: AppColors.grey100,
                selectedColor: AppColors.primary,
                labelStyle: AppTextStyles.bodySmall.copyWith(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: 6,
      itemBuilder: (context, index) => SkeletonLoader.container(
        width: double.infinity,
        height: double.infinity,
        borderRadius: 12,
      ),
    );
  }

  Widget _buildCommunityList() {
    if (_communities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.groups_outlined,
              size: 80,
              color: AppColors.grey300,
            ),
            const SizedBox(height: 16),
            Text(
              'No Communities Found',
              style: AppTextStyles.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchController.text.isNotEmpty
                  ? 'Try different search terms'
                  : 'Be the first to create one!',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCommunities,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _communities.length,
        itemBuilder: (context, index) {
          return _buildCommunityCard(_communities[index]);
        },
      ),
    );
  }

  Widget _buildCommunityCard(Map<String, dynamic> community) {
    final isMember = community['is_member'] == true;
    final memberCount = community['member_count'] ?? 0;
    final postCount = community['post_count'] ?? 0;
    final category = community['category'] ?? 'general';
    final coverImageUrl = community['cover_image_url'] as String?;

    return GestureDetector(
      onTap: () => _navigateToCommunityDetail(community),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.7),
                      AppColors.secondary.withOpacity(0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: coverImageUrl != null
                    ? Image.network(
                        coverImageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox(),
                      )
                    : Center(
                        child: Icon(
                          Icons.groups,
                          size: 48,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
              ),
            ),
            
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        category.toUpperCase(),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Title
                    Text(
                      community['name'] ?? 'Unnamed Community',
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    
                    // Stats
                    Row(
                      children: [
                        Icon(
                          Icons.people,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$memberCount',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.article,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$postCount',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // Join button
                    SizedBox(
                      width: double.infinity,
                      height: 32,
                      child: ElevatedButton(
                        onPressed: () {
                          if (isMember) {
                            _leaveCommunity(community['id']);
                          } else {
                            _joinCommunity(community['id']);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isMember
                              ? AppColors.grey200
                              : AppColors.primary,
                          foregroundColor: isMember
                              ? AppColors.textPrimary
                              : Colors.white,
                          elevation: 0,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          isMember ? 'Joined' : 'Join',
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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
}

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/haptic_helper.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../core/config/service_locator.dart';
import '../../core/interfaces/i_community_service.dart';

/// Screen showing community members with role management
class CommunityMembersScreen extends StatefulWidget {
  final String communityId;

  const CommunityMembersScreen({
    super.key,
    required this.communityId,
  });

  @override
  State<CommunityMembersScreen> createState() => _CommunityMembersScreenState();
}

class _CommunityMembersScreenState extends State<CommunityMembersScreen> {
  static const String _tag = 'CommunityMembersScreen';
  
  final ICommunityService _communityService = ServiceLocator.iCommunityService;
  final TextEditingController _searchController = TextEditingController();
  
  List<Map<String, dynamic>> _members = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    try {
      setState(() => _isLoading = true);
      
      final members = await _communityService.getCommunityMembers(
        communityId: widget.communityId,
        limit: 100,
      );
      
      setState(() {
        _members = members;
        _isLoading = false;
      });
      
      AppLogger.success(_tag, 'Loaded ${members.length} members');
    } catch (e) {
      AppLogger.error(_tag, 'Failed to load members', e);
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredMembers {
    if (_searchController.text.isEmpty) {
      return _members;
    }
    
    final query = _searchController.text.toLowerCase();
    return _members.where((member) {
      final userData = member['user_data'] as Map<String, dynamic>?;
      final name = (userData?['display_name'] ?? '').toString().toLowerCase();
      final email = (userData?['email'] ?? '').toString().toLowerCase();
      return name.contains(query) || email.contains(query);
    }).toList();
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'owner':
        return Colors.red;
      case 'admin':
        return Colors.orange;
      case 'moderator':
        return Colors.blue;
      default:
        return AppColors.grey400;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'owner':
        return Icons.stars;
      case 'admin':
        return Icons.shield;
      case 'moderator':
        return Icons.verified_user;
      default:
        return Icons.person;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey50,
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _isLoading ? _buildLoadingState() : _buildMemberList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search members...',
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.grey100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 10,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: SkeletonLoader.container(
          width: double.infinity,
          height: 72,
          borderRadius: 12,
        ),
      ),
    );
  }

  Widget _buildMemberList() {
    final filteredMembers = _filteredMembers;
    
    if (filteredMembers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchController.text.isNotEmpty
                  ? Icons.search_off
                  : Icons.people_outline,
              size: 80,
              color: AppColors.grey300,
            ),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isNotEmpty
                  ? 'No Members Found'
                  : 'No Members',
              style: AppTextStyles.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchController.text.isNotEmpty
                  ? 'Try different search terms'
                  : 'This community has no members yet',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    // Group members by role
    final owners = filteredMembers.where((m) => m['role'] == 'owner').toList();
    final admins = filteredMembers.where((m) => m['role'] == 'admin').toList();
    final moderators = filteredMembers.where((m) => m['role'] == 'moderator').toList();
    final members = filteredMembers.where((m) => m['role'] == 'member').toList();

    return RefreshIndicator(
      onRefresh: _loadMembers,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Total count
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              '${filteredMembers.length} member${filteredMembers.length != 1 ? 's' : ''}',
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          
          // Owners
          if (owners.isNotEmpty) ...[
            _buildRoleSectionHeader('Owners', owners.length),
            ...owners.map((member) => _buildMemberCard(member)),
            const SizedBox(height: 16),
          ],
          
          // Admins
          if (admins.isNotEmpty) ...[
            _buildRoleSectionHeader('Admins', admins.length),
            ...admins.map((member) => _buildMemberCard(member)),
            const SizedBox(height: 16),
          ],
          
          // Moderators
          if (moderators.isNotEmpty) ...[
            _buildRoleSectionHeader('Moderators', moderators.length),
            ...moderators.map((member) => _buildMemberCard(member)),
            const SizedBox(height: 16),
          ],
          
          // Members
          if (members.isNotEmpty) ...[
            _buildRoleSectionHeader('Members', members.length),
            ...members.map((member) => _buildMemberCard(member)),
          ],
        ],
      ),
    );
  }

  Widget _buildRoleSectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        '$title ($count)',
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildMemberCard(Map<String, dynamic> member) {
    final userData = member['user_data'] as Map<String, dynamic>?;
    final role = member['role'] as String? ?? 'member';
    final roleColor = _getRoleColor(role);
    final roleIcon = _getRoleIcon(role);
    final isActive = member['is_active'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: roleColor.withOpacity(0.1),
              child: Text(
                (userData?['display_name'] ?? 'U')[0].toUpperCase(),
                style: AppTextStyles.titleMedium.copyWith(
                  color: roleColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (isActive)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                userData?['display_name'] ?? 'Unknown User',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              roleIcon,
              size: 16,
              color: roleColor,
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (userData?['email'] != null)
              Text(
                userData!['email'],
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: roleColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                role.toUpperCase(),
                style: AppTextStyles.bodySmall.copyWith(
                  color: roleColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
        trailing: role != 'owner'
            ? IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () {
                  HapticHelper.lightImpact();
                  _showMemberActions(member);
                },
                color: AppColors.textSecondary,
              )
            : null,
        onTap: () {
          HapticHelper.lightImpact();
          // Navigate to member profile
        },
      ),
    );
  }

  void _showMemberActions(Map<String, dynamic> member) {
    final userData = member['user_data'] as Map<String, dynamic>?;
    final role = member['role'] as String? ?? 'member';
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grey300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.person),
                title: Text(
                  userData?['display_name'] ?? 'Unknown User',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  role.toUpperCase(),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: _getRoleColor(role),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.shield_outlined),
                title: const Text('Change Role'),
                onTap: () {
                  Navigator.pop(context);
                  // Show role change dialog
                },
              ),
              ListTile(
                leading: const Icon(Icons.remove_circle_outline, color: Colors.red),
                title: const Text('Remove from Community', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  // Confirm and remove member
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

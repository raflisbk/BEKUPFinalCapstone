import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../services/user_safety_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/haptic_helper.dart';

/// Screen for viewing and managing blocked users
class BlockedUsersScreen extends StatefulWidget {
  final String currentUserId;

  const BlockedUsersScreen({
    super.key,
    required this.currentUserId,
  });

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  static const String _tag = 'BlockedUsersScreen';

  List<Map<String, dynamic>> _blockedUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    AppLogger.debug(_tag, 'Blocked users screen initialized', {
      'userId': widget.currentUserId,
    });
    _loadBlockedUsers();
  }

  Future<void> _loadBlockedUsers() async {
    setState(() => _isLoading = true);

    final blockedUsers = await UserSafetyService.getBlockedUsers();

    if (mounted) {
      setState(() {
        _blockedUsers = blockedUsers;
        _isLoading = false;
      });

      AppLogger.info(_tag, 'Blocked users loaded', {
        'count': blockedUsers.length,
      });
    }
  }

  Future<void> _unblockUser(String blockedUserId) async {
    await HapticHelper.mediumImpact();

    final confirmed = await showDialog<bool>(
      // ignore: use_build_context_synchronously
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.white,
        title: const Text('Unblock User', style: AppTextStyles.titleLarge),
        content: const Text(
          'Are you sure you want to unblock this user? They will be able to interact with you again.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: AppTextStyles.labelLarge),
          ),
          TextButton(
            onPressed: () {
              HapticHelper.lightImpact();
              Navigator.pop(context, true);
            },
            child: Text('Unblock', style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.bold,
            )),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await UserSafetyService.unblockUser(blockedUserId);

      if (!mounted) return;

      await HapticHelper.success();
      setState(() {
        _blockedUsers.removeWhere((user) => user['blocked_user_id'] == blockedUserId);
      });

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User unblocked successfully'),
          backgroundColor: AppColors.success,
        ),
      );

      AppLogger.info(_tag, 'User unblocked', {
        'blockedUserId': blockedUserId,
      });
    } catch (e) {
      if (!mounted) return;

      await HapticHelper.error();
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to unblock user: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );

      AppLogger.error(_tag, 'Failed to unblock user', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey50,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () {
            HapticHelper.lightImpact();
            Navigator.pop(context);
          },
        ),
        title: const Text('Blocked Users', style: AppTextStyles.headlineSmall),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: AppColors.divider,
            height: 1,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.black))
          : _blockedUsers.isEmpty
              ? _buildEmptyState()
              : _buildBlockedUsersList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: FadeIn(
        duration: const Duration(milliseconds: 600),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: BorderRadius.circular(60),
                ),
                child: const Icon(
                  Icons.block,
                  size: 64,
                  color: AppColors.grey400,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'No Blocked Users',
                style: AppTextStyles.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'You haven\'t blocked anyone yet. Blocked users won\'t be able to interact with you.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBlockedUsersList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _blockedUsers.length,
      itemBuilder: (context, index) {
        final blockedUser = _blockedUsers[index];
        return FadeInUp(
          duration: Duration(milliseconds: 300 + (index * 50)),
          child: _buildBlockedUserCard(blockedUser, index),
        );
      },
    );
  }

  Widget _buildBlockedUserCard(Map<String, dynamic> blockedUser, int index) {
    final blockedUserId = blockedUser['blocked_user_id'] as String;
    final createdAt = DateTime.parse(blockedUser['created_at'] as String);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            color: AppColors.grey100,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.person,
            color: AppColors.grey600,
            size: 24,
          ),
        ),
        title: Text(
          'User ID: ${blockedUserId.substring(0, 8)}...',
          style: AppTextStyles.titleSmall,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Blocked',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Since: ${createdAt.day}/${createdAt.month}/${createdAt.year}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
        trailing: OutlinedButton(
          onPressed: () => _unblockUser(blockedUserId),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.success,
            side: const BorderSide(color: AppColors.success),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: Text(
            'Unblock',
            style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    AppLogger.debug(_tag, 'Disposing blocked users screen');
    super.dispose();
  }
}

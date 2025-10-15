import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/user_model.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/user_provider.dart';
import '../../services/chat_service.dart';
import '../../services/social_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/haptic_helper.dart';

/// Screen to create a new group chat
class CreateGroupChatScreen extends StatefulWidget {
  const CreateGroupChatScreen({super.key});

  @override
  State<CreateGroupChatScreen> createState() => _CreateGroupChatScreenState();
}

class _CreateGroupChatScreenState extends State<CreateGroupChatScreen> {
  static const String _tag = 'CreateGroupChatScreen';

  final TextEditingController _groupNameController = TextEditingController();

  List<UserModel> _followingUsers = [];
  final Set<String> _selectedUserIds = {};
  bool _isLoading = true;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _loadFollowingUsers();
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  Future<void> _loadFollowingUsers() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUserId = authProvider.user?.uid;

      if (currentUserId == null) return;

      AppLogger.debug(_tag, 'Loading following users');

      // Get following user IDs
      final followingUsers = await SocialService.getUserFollowing(userId: currentUserId);
      final followingIds = followingUsers.map((user) => user['id'] as String).toList();

      // Load user details for following users
      final users = <UserModel>[];
      for (var userId in followingIds) {
        // Create a basic user model from connection data
        // In production, you should have a proper UserService method for this
        users.add(UserModel(
          uid: userId,
          email: '',
          displayName: 'User', // This should come from user service
          photoUrl: null,
          bio: '',
          interests: [],
          languages: ['English'],
          isGuide: false,
          isVerified: false,
          rating: 0.0,
          reviewCount: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      }

      setState(() {
        _followingUsers = users;
        _isLoading = false;
      });

      AppLogger.info(_tag, 'Loaded following users', {
        'count': users.length,
      });
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to load following users', e, stackTrace);
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createGroupChat() async {
    final groupName = _groupNameController.text.trim();

    if (groupName.isEmpty) {
      await HapticHelper.warning();
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a group name')),
      );
      return;
    }

    if (_selectedUserIds.length < 2) {
      await HapticHelper.warning();
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select at least 2 members for the group')),
      );
      return;
    }

    await HapticHelper.lightImpact();
    setState(() => _isCreating = true);

    try {
      // ignore: use_build_context_synchronously
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      // ignore: use_build_context_synchronously
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      if (authProvider.user == null) return;

      final currentUserId = authProvider.user!.uid;
      final currentUserName = userProvider.currentUser?.name ?? 'Unknown';
      final currentUserPhotoUrl = userProvider.currentUser?.photoUrl;

      AppLogger.action('User creating group chat', {
        'groupName': groupName,
        'memberCount': _selectedUserIds.length + 1,
      });

      // Build participant data
      final participantIds = [currentUserId, ..._selectedUserIds];
      final participantData = <String, Map<String, dynamic>>{
        currentUserId: {
          'name': currentUserName,
          'photoUrl': currentUserPhotoUrl,
        },
      };

      for (var userId in _selectedUserIds) {
        final user = _followingUsers.firstWhere((u) => u.id == userId);
        participantData[userId] = {
          'name': user.displayName,
          'photoUrl': user.photoUrl,
        };
      }

      final conversation = await ChatService.createConversation(
        participantIds: participantIds,
        title: groupName,
        type: 'group',
      );

      AppLogger.success(_tag, 'Group chat created successfully');
      await HapticHelper.success();

      if (mounted) {
        Navigator.pop(context, conversation);
      }
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to create group chat', e, stackTrace);
      await HapticHelper.error();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create group chat'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.black),
          onPressed: () {
            HapticHelper.lightImpact();
            Navigator.pop(context);
          },
        ),
        title: Text(
          'New Group Chat',
          style: AppTextStyles.headlineSmall.copyWith(fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: _isCreating ? null : _createGroupChat,
            child: _isCreating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Create',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: AppColors.divider,
            height: 1,
          ),
        ),
      ),
      body: Column(
        children: [
          // Group name input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.divider, width: 1),
              ),
            ),
            child: TextField(
              controller: _groupNameController,
              decoration: InputDecoration(
                hintText: 'Group Name',
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                border: InputBorder.none,
              ),
              style: AppTextStyles.bodyMedium,
              textCapitalization: TextCapitalization.words,
            ),
          ),

          // Selected count
          if (_selectedUserIds.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: AppColors.grey50,
                border: Border(
                  bottom: BorderSide(color: AppColors.divider, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    '${_selectedUserIds.length + 1} participants',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

          // Member list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _followingUsers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.people_outline,
                              size: 64,
                              color: AppColors.grey400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No following users',
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Follow users to add them to groups',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _followingUsers.length,
                        itemBuilder: (context, index) {
                          final user = _followingUsers[index];
                          final isSelected = _selectedUserIds.contains(user.id);

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.grey100,
                              backgroundImage: user.photoUrl != null
                                  ? NetworkImage(user.photoUrl!)
                                  : null,
                              child: user.photoUrl == null
                                  ? const Icon(Icons.person,
                                      color: AppColors.grey500)
                                  : null,
                            ),
                            title: Text(
                              user.displayName,
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            trailing: Checkbox(
                              value: isSelected,
                              onChanged: (value) {
                                setState(() {
                                  if (value == true) {
                                    _selectedUserIds.add(user.id);
                                  } else {
                                    _selectedUserIds.remove(user.id);
                                  }
                                });
                                HapticHelper.lightImpact();
                              },
                              activeColor: AppColors.black,
                            ),
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _selectedUserIds.remove(user.id);
                                } else {
                                  _selectedUserIds.add(user.id);
                                }
                              });
                              HapticHelper.lightImpact();
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

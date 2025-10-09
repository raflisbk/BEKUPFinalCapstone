import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/providers/chat_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/models/chat_models.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/logger.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  static const String _tag = 'ChatListScreen';

  @override
  void initState() {
    super.initState();
    AppLogger.debug(_tag, 'Chat list screen initialized');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);

      if (authProvider.user != null && chatProvider.currentUserId == null) {
        chatProvider.initialize(authProvider.user!.uid);
      }
    });
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';

    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(time);
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE').format(time);
    } else {
      return DateFormat('dd/MM/yyyy').format(time);
    }
  }

  Widget _buildConversationTile(
    BuildContext context,
    ChatConversation conversation,
    String currentUserId,
  ) {
    final otherParticipant = conversation.getOtherParticipant(currentUserId);
    if (otherParticipant == null) return const SizedBox.shrink();

    final name = otherParticipant['name'] ?? 'Unknown';
    final photoUrl = otherParticipant['photoUrl'];
    final unreadCount = conversation.getUnreadCount(currentUserId);
    final hasUnread = unreadCount > 0;

    return InkWell(
      onTap: () {
        AppLogger.action('User tapped conversation', {
          'conversationId': conversation.id,
        });

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              conversation: conversation,
              otherUserName: name,
              otherUserPhotoUrl: photoUrl,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.divider, width: 1),
          ),
        ),
        child: Row(
          children: [
            // Avatar
            _buildAvatar(photoUrl),
            const SizedBox(width: 16),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Name
                      Expanded(
                        child: Text(
                          name,
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // Time
                      Text(
                        _formatTime(conversation.lastMessageTime),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: hasUnread ? AppColors.black : AppColors.textSecondary,
                          fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Last message
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.lastMessage ?? 'No messages yet',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: hasUnread ? AppColors.black : AppColors.textSecondary,
                            fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),

                      // Unread badge
                      if (hasUnread) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.black,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : unreadCount.toString(),
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String? photoUrl) {
    if (photoUrl != null && photoUrl.startsWith('avatar:')) {
      final emoji = photoUrl.replaceFirst('avatar:', '');
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.grey50,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Center(
          child: Text(
            emoji,
            style: const TextStyle(fontSize: 28),
          ),
        ),
      );
    }

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.grey50,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: const Center(
        child: Text('👤', style: TextStyle(fontSize: 28)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: const Text('Messages', style: AppTextStyles.headlineSmall),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: AppColors.divider,
            height: 1,
          ),
        ),
      ),
      body: Consumer2<ChatProvider, AuthProvider>(
        builder: (context, chatProvider, authProvider, child) {
          final currentUserId = authProvider.user?.uid;

          if (currentUserId == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('👤', style: TextStyle(fontSize: 64)),
                  const SizedBox(height: 16),
                  Text(
                    'Please login to view messages',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          if (chatProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.black),
              ),
            );
          }

          final conversations = chatProvider.conversations;

          if (conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('💬', style: TextStyle(fontSize: 64)),
                  const SizedBox(height: 16),
                  const Text(
                    'No messages yet',
                    style: AppTextStyles.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start chatting with travelers you meet',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              return _buildConversationTile(
                context,
                conversations[index],
                currentUserId,
              );
            },
          );
        },
      ),
    );
  }
}

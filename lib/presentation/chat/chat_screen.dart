import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/providers/chat_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/user_provider.dart';
import '../../core/models/chat_models.dart';
import '../../services/chat_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/logger.dart';

class ChatScreen extends StatefulWidget {
  final ChatConversation conversation;
  final String otherUserName;
  final String? otherUserPhotoUrl;

  const ChatScreen({
    super.key,
    required this.conversation,
    required this.otherUserName,
    this.otherUserPhotoUrl,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static const String _tag = 'ChatScreen';

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();

  @override
  void initState() {
    super.initState();
    AppLogger.debug(_tag, 'Chat screen initialized', {
      'conversationId': widget.conversation.id,
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markMessagesAsRead();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _markMessagesAsRead() {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.markMessagesAsRead(widget.conversation.id);
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    if (authProvider.user == null) return;

    final currentUserId = authProvider.user!.uid;
    final otherUserId = widget.conversation.participantIds
        .firstWhere((id) => id != currentUserId);

    AppLogger.action('User sending message', {
      'textLength': text.length,
    });

    // Clear input immediately
    _messageController.clear();

    // Send message
    final success = await chatProvider.sendMessage(
      conversationId: widget.conversation.id,
      text: text,
      senderName: userProvider.currentUser?.name ?? 'Unknown',
      senderPhotoUrl: userProvider.currentUser?.photoUrl,
      recipientId: otherUserId,
    );

    if (success) {
      AppLogger.info(_tag, 'Message sent successfully');
      // Scroll to bottom after sending
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    } else {
      AppLogger.warning(_tag, 'Failed to send message');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send message'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildMessageBubble(ChatMessage message, bool isCurrentUser) {
    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          color: isCurrentUser ? AppColors.black : AppColors.grey50,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isCurrentUser ? 16 : 4),
            bottomRight: Radius.circular(isCurrentUser ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isCurrentUser ? AppColors.white : AppColors.black,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('HH:mm').format(message.sentAt),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isCurrentUser
                        ? AppColors.white.withValues(alpha: 0.7)
                        : AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                if (isCurrentUser) ...[
                  const SizedBox(width: 4),
                  Text(
                    message.isRead ? '✓✓' : '✓',
                    style: TextStyle(
                      color: message.isRead
                          ? Colors.blue[300]
                          : AppColors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSeparator(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    String dateText;
    if (difference.inDays == 0) {
      dateText = 'Today';
    } else if (difference.inDays == 1) {
      dateText = 'Yesterday';
    } else {
      dateText = DateFormat('dd MMM yyyy').format(date);
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.grey50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            dateText,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildMessageListWithSeparators(
    List<ChatMessage> messages,
    String currentUserId,
  ) {
    final widgets = <Widget>[];
    DateTime? lastDate;

    for (var i = 0; i < messages.length; i++) {
      final message = messages[i];
      final messageDate = DateTime(
        message.sentAt.year,
        message.sentAt.month,
        message.sentAt.day,
      );

      // Add date separator if date changed
      if (lastDate == null || !_isSameDay(messageDate, lastDate)) {
        widgets.add(_buildDateSeparator(messageDate));
        lastDate = messageDate;
      }

      // Add message bubble
      widgets.add(_buildMessageBubble(
        message,
        message.senderId == currentUserId,
      ));
    }

    return widgets;
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            // Avatar
            if (widget.otherUserPhotoUrl != null &&
                widget.otherUserPhotoUrl!.startsWith('avatar:'))
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.grey50,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    widget.otherUserPhotoUrl!.replaceFirst('avatar:', ''),
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              )
            else
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.grey50,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('👤', style: TextStyle(fontSize: 20)),
                ),
              ),
            const SizedBox(width: 12),

            // Name
            Expanded(
              child: Text(
                widget.otherUserName,
                style: AppTextStyles.headlineSmall.copyWith(fontSize: 18),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
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
          // Messages list
          Expanded(
            child: Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                final currentUserId = authProvider.user?.uid;
                if (currentUserId == null) {
                  return const Center(child: Text('Not authenticated'));
                }

                return StreamBuilder<List<ChatMessage>>(
                  stream: _chatService.getMessagesStream(widget.conversation.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.black),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error loading messages',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      );
                    }

                    final messages = snapshot.data ?? [];

                    if (messages.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('💬', style: TextStyle(fontSize: 64)),
                            const SizedBox(height: 16),
                            Text(
                              'No messages yet',
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Send a message to start chatting',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // Scroll to bottom when new messages arrive
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _scrollToBottom();
                    });

                    return ListView(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      children: _buildMessageListWithSeparators(
                        messages,
                        currentUserId,
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Message input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border(
                top: BorderSide(color: AppColors.divider, width: 1),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Text input
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.grey50,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.border, width: 1),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          border: InputBorder.none,
                        ),
                        style: AppTextStyles.bodyMedium,
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Send button
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: AppColors.black,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send,
                        color: AppColors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

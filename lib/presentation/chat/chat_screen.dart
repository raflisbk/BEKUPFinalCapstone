import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/providers/chat_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/user_provider.dart';
import '../../core/models/chat_models.dart';
import '../../services/chat_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/haptic_helper.dart';

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
  final ImagePicker _imagePicker = ImagePicker();
  bool _isSendingImage = false;

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

  Future<void> _pickAndSendImage() async {
    await HapticHelper.lightImpact();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    if (authProvider.user == null) return;

    final currentUserId = authProvider.user!.uid;
    final otherUserId = widget.conversation.participantIds
        .firstWhere((id) => id != currentUserId);

    AppLogger.action('User picking image to send');

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (image == null) {
        AppLogger.debug(_tag, 'Image picker cancelled');
        return;
      }

      setState(() => _isSendingImage = true);

      AppLogger.info(_tag, 'Image selected, sending...', {
        'path': image.path,
      });

      final imageUrl = await _chatService.sendImageMessage(
        conversationId: widget.conversation.id,
        senderId: currentUserId,
        senderName: userProvider.currentUser?.name ?? 'Unknown',
        senderPhotoUrl: userProvider.currentUser?.photoUrl,
        imageFile: File(image.path),
        recipientId: otherUserId,
      );

      if (imageUrl != null) {
        AppLogger.info(_tag, 'Image message sent successfully');
        await HapticHelper.success();
        // Scroll to bottom after sending
        Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
      } else {
        AppLogger.warning(_tag, 'Failed to send image');
        await HapticHelper.error();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to send image'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Error picking or sending image', e, stackTrace);
      await HapticHelper.error();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error sending image'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSendingImage = false);
      }
    }
  }

  Widget _buildMessageBubble(ChatMessage message, bool isCurrentUser) {
    // Handle system messages
    if (message.type == MessageType.system) {
      return _buildSystemMessageBubble(message);
    }

    // Handle image messages
    if (message.type == MessageType.image) {
      return _buildImageMessageBubble(message, isCurrentUser);
    }

    // Handle text messages
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

  Widget _buildImageMessageBubble(ChatMessage message, bool isCurrentUser) {
    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          crossAxisAlignment:
              isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                HapticHelper.lightImpact();
                _viewFullImage(message.text);
              },
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isCurrentUser ? 16 : 4),
                  bottomRight: Radius.circular(isCurrentUser ? 4 : 16),
                ),
                child: CachedNetworkImage(
                  imageUrl: message.text,
                  width: 220,
                  height: 220,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: 220,
                    height: 220,
                    color: AppColors.grey50,
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.black),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 220,
                    height: 220,
                    color: AppColors.grey50,
                    child: const Center(
                      child: Icon(Icons.error, color: AppColors.textSecondary),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('HH:mm').format(message.sentAt),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
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
                            : AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _viewFullImage(String imageUrl) {
    AppLogger.action('User viewing full image');
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                errorWidget: (context, url, error) => const Center(
                  child: Icon(Icons.error, color: Colors.white, size: 48),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
                onPressed: () {
                  HapticHelper.lightImpact();
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemMessageBubble(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.grey50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            message.text,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
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
                  // Image picker button
                  GestureDetector(
                    onTap: _isSendingImage ? null : _pickAndSendImage,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _isSendingImage
                            ? AppColors.grey50
                            : AppColors.grey100,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border, width: 1),
                      ),
                      child: _isSendingImage
                          ? const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.black),
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.image,
                              color: AppColors.black,
                              size: 24,
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),

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

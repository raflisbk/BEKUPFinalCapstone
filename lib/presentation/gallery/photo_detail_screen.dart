import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/user_provider.dart';
import '../../core/models/gallery_model.dart';
import '../../services/gallery_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/haptic_helper.dart';

class PhotoDetailScreen extends StatefulWidget {
  final Photo photo;

  const PhotoDetailScreen({
    super.key,
    required this.photo,
  });

  @override
  State<PhotoDetailScreen> createState() => _PhotoDetailScreenState();
}

class _PhotoDetailScreenState extends State<PhotoDetailScreen> {
  static const String _tag = 'PhotoDetailScreen';

  final GalleryService _galleryService = GalleryService();
  final TextEditingController _commentController = TextEditingController();

  late Photo _currentPhoto;

  @override
  void initState() {
    super.initState();
    _currentPhoto = widget.photo;
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _toggleLike(String userId) async {
    await HapticHelper.lightImpact();

    final success = await _galleryService.toggleLike(
      photoId: _currentPhoto.id,
      userId: userId,
    );

    if (success) {
      // Optimistically update UI
      setState(() {
        if (_currentPhoto.isLikedBy(userId)) {
          _currentPhoto = _currentPhoto.copyWith(
            likes: _currentPhoto.likes - 1,
            likedBy: _currentPhoto.likedBy.where((id) => id != userId).toList(),
          );
        } else {
          _currentPhoto = _currentPhoto.copyWith(
            likes: _currentPhoto.likes + 1,
            likedBy: [..._currentPhoto.likedBy, userId],
          );
        }
      });
    }
  }

  Future<void> _addComment(String userId, String userName, String? photoUrl) async {
    if (_commentController.text.trim().isEmpty) return;

    await HapticHelper.submit();

    final commentId = await _galleryService.addComment(
      photoId: _currentPhoto.id,
      userId: userId,
      userName: userName,
      userPhotoUrl: photoUrl,
      comment: _commentController.text.trim(),
    );

    if (commentId != null) {
      _commentController.clear();
      FocusScope.of(context).unfocus();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comment added'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _deletePhoto() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Photo'),
        content: const Text('Are you sure you want to delete this photo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await HapticHelper.delete();

    final success = await _galleryService.deletePhoto(
      _currentPhoto.id,
      _currentPhoto.imageUrl,
    );

    if (!mounted) return;

    if (success) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Photo deleted'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete photo'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showOptionsMenu(BuildContext context, bool isOwner) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isOwner) ...[
                ListTile(
                  leading: const Icon(Icons.delete, color: AppColors.error),
                  title: const Text('Delete Photo', style: TextStyle(color: AppColors.error)),
                  onTap: () {
                    Navigator.pop(context);
                    _deletePhoto();
                  },
                ),
              ],
              ListTile(
                leading: const Icon(Icons.share, color: AppColors.black),
                title: const Text('Share'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Share feature coming soon')),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCommentItem(PhotoComment comment, String currentUserId) {
    final isOwner = comment.userId == currentUserId;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.grey300,
            backgroundImage: comment.userPhotoUrl != null
                ? NetworkImage(comment.userPhotoUrl!)
                : null,
            child: comment.userPhotoUrl == null
                ? Text(
                    comment.userName[0].toUpperCase(),
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.userName,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('dd MMM').format(comment.createdAt),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (isOwner) ...[
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18),
                        color: AppColors.error,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () async {
                          await HapticHelper.delete();
                          await _galleryService.deleteComment(
                            comment.id,
                            _currentPhoto.id,
                          );
                        },
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.comment,
                  style: AppTextStyles.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final currentUserId = authProvider.user?.uid;
        final isOwner = currentUserId == _currentPhoto.userId;
        final isLiked = currentUserId != null && _currentPhoto.isLikedBy(currentUserId);

        return Scaffold(
          backgroundColor: AppColors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close, color: AppColors.white),
              onPressed: () async {
                await HapticHelper.buttonTap();
                Navigator.pop(context);
              },
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.more_vert, color: AppColors.white),
                onPressed: () => _showOptionsMenu(context, isOwner),
              ),
            ],
          ),
          body: Column(
            children: [
              // Photo
              Expanded(
                child: Center(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: CachedNetworkImage(
                      imageUrl: _currentPhoto.imageUrl,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                        ),
                      ),
                      errorWidget: (context, url, error) => const Icon(
                        Icons.error,
                        color: AppColors.white,
                        size: 48,
                      ),
                    ),
                  ),
                ),
              ),

              // Info section
              Container(
                color: AppColors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User info and actions
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: AppColors.grey300,
                            backgroundImage: _currentPhoto.userPhotoUrl != null
                                ? NetworkImage(_currentPhoto.userPhotoUrl!)
                                : null,
                            child: _currentPhoto.userPhotoUrl == null
                                ? Text(
                                    _currentPhoto.userName[0].toUpperCase(),
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _currentPhoto.userName,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  DateFormat('dd MMM yyyy').format(_currentPhoto.createdAt),
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Like button
                          IconButton(
                            icon: Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              color: isLiked ? Colors.red : AppColors.black,
                            ),
                            onPressed: currentUserId != null
                                ? () => _toggleLike(currentUserId)
                                : null,
                          ),
                        ],
                      ),
                    ),

                    // Caption
                    if (_currentPhoto.caption != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          _currentPhoto.caption!,
                          style: AppTextStyles.bodyMedium,
                        ),
                      ),

                    // Location
                    if (_currentPhoto.location != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on, size: 16, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              _currentPhoto.location!,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Stats
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      child: Text(
                        '${_currentPhoto.likes} likes • ${_currentPhoto.comments} comments',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const Divider(height: 1),

                    // Comments
                    SizedBox(
                      height: 300,
                      child: StreamBuilder<List<PhotoComment>>(
                        stream: _galleryService.getCommentsStream(_currentPhoto.id),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.black),
                              ),
                            );
                          }

                          final comments = snapshot.data ?? [];

                          if (comments.isEmpty) {
                            return Center(
                              child: Text(
                                'No comments yet',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            );
                          }

                          return ListView.builder(
                            itemCount: comments.length,
                            itemBuilder: (context, index) {
                              return _buildCommentItem(
                                comments[index],
                                currentUserId ?? '',
                              );
                            },
                          );
                        },
                      ),
                    ),

                    const Divider(height: 1),

                    // Comment input
                    if (currentUserId != null)
                      Consumer<UserProvider>(
                        builder: (context, userProvider, child) {
                          return SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _commentController,
                                      decoration: InputDecoration(
                                        hintText: 'Add a comment...',
                                        filled: true,
                                        fillColor: AppColors.grey50,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(24),
                                          borderSide: BorderSide.none,
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.send, color: AppColors.black),
                                    onPressed: () => _addComment(
                                      currentUserId,
                                      userProvider.currentUser?.displayName ?? 'Anonymous',
                                      userProvider.currentUser?.photoUrl,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

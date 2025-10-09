import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/models/gallery_model.dart';
import '../../services/gallery_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/haptic_helper.dart';
import '../../core/widgets/skeleton_loader.dart';
import 'upload_photo_screen.dart';
import 'photo_detail_screen.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  static const String _tag = 'GalleryScreen';

  final GalleryService _galleryService = GalleryService();
  GalleryFilter _selectedFilter = GalleryFilter.all;
  GallerySort _selectedSort = GallerySort.recent;

  void _navigateToUpload() async {
    await HapticHelper.buttonTap();

    if (!mounted) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const UploadPhotoScreen(),
      ),
    );

    if (result == true && mounted) {
      setState(() {});
    }
  }

  void _navigateToPhotoDetail(Photo photo) async {
    await HapticHelper.cardTap();

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhotoDetailScreen(photo: photo),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: GalleryFilter.values.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(GalleryFilterHelper.getLabel(filter)),
              selected: isSelected,
              onSelected: (selected) async {
                if (selected) {
                  await HapticHelper.selectionClick();
                  setState(() {
                    _selectedFilter = filter;
                  });
                  AppLogger.debug(_tag, 'Filter changed', {
                    'filter': filter.toString(),
                  });
                }
              },
              backgroundColor: AppColors.grey50,
              selectedColor: AppColors.black,
              labelStyle: AppTextStyles.bodyMedium.copyWith(
                color: isSelected ? AppColors.white : AppColors.black,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? AppColors.black : AppColors.border,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSortMenu() {
    return PopupMenuButton<GallerySort>(
      icon: const Icon(Icons.sort, color: AppColors.black),
      onSelected: (sort) async {
        await HapticHelper.selectionClick();
        setState(() {
          _selectedSort = sort;
        });
      },
      itemBuilder: (context) {
        return GallerySort.values.map((sort) {
          return PopupMenuItem<GallerySort>(
            value: sort,
            child: Row(
              children: [
                if (_selectedSort == sort)
                  const Icon(Icons.check, size: 20, color: AppColors.black),
                if (_selectedSort == sort) const SizedBox(width: 8),
                Text(
                  GallerySortHelper.getLabel(sort),
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: _selectedSort == sort
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          );
        }).toList();
      },
    );
  }

  Widget _buildPhotoGrid(List<Photo> photos) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1,
      ),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        return _buildPhotoCard(photos[index]);
      },
    );
  }

  Widget _buildPhotoCard(Photo photo) {
    return GestureDetector(
      onTap: () => _navigateToPhotoDetail(photo),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Photo
              CachedNetworkImage(
                imageUrl: photo.imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: AppColors.grey100,
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.black),
                      strokeWidth: 2,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppColors.grey100,
                  child: const Icon(Icons.error, color: AppColors.grey500),
                ),
              ),

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
                    stops: const [0.5, 1.0],
                  ),
                ),
              ),

              // Info overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // User info
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: AppColors.grey300,
                            backgroundImage: photo.userPhotoUrl != null
                                ? NetworkImage(photo.userPhotoUrl!)
                                : null,
                            child: photo.userPhotoUrl == null
                                ? Text(
                                    photo.userName[0].toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              photo.userName,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Stats
                      Row(
                        children: [
                          const Icon(
                            Icons.favorite,
                            size: 14,
                            color: AppColors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${photo.likes}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(
                            Icons.comment,
                            size: 14,
                            color: AppColors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${photo.comments}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📷', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          const Text(
            'No photos yet',
            style: AppTextStyles.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Share your travel moments',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _navigateToUpload,
            icon: const Icon(Icons.add_a_photo),
            label: const Text('Upload Photo'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.black,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey50,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: const Text('Gallery', style: AppTextStyles.headlineSmall),
        actions: [
          _buildSortMenu(),
          IconButton(
            icon: const Icon(Icons.add_a_photo, color: AppColors.black),
            onPressed: _navigateToUpload,
            tooltip: 'Upload Photo',
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
          const SizedBox(height: 8),
          _buildFilterChips(),
          const SizedBox(height: 8),
          Expanded(
            child: Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                final userId = authProvider.user?.uid;

                return StreamBuilder<List<Photo>>(
                  stream: _galleryService.getPhotosStream(
                    filter: _selectedFilter,
                    userId: userId,
                    sort: _selectedSort,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1,
                        ),
                        itemCount: 6,
                        itemBuilder: (context, index) {
                          return SkeletonLoader.container(
                            width: double.infinity,
                            height: double.infinity,
                            borderRadius: 16,
                          );
                        },
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error loading photos',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      );
                    }

                    final photos = snapshot.data ?? [];

                    if (photos.isEmpty) {
                      return _buildEmptyState();
                    }

                    return _buildPhotoGrid(photos);
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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/models/review_model.dart';
import '../../services/review_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/haptic_helper.dart';
import 'write_edit_review_screen.dart';

class ReviewsScreen extends StatefulWidget {
  final String destinationId;
  final String destinationName;

  const ReviewsScreen({
    super.key,
    required this.destinationId,
    required this.destinationName,
  });

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  static const String _tag = 'ReviewsScreen';

  final ReviewService _reviewService = ReviewService();
  ReviewFilter _selectedFilter = ReviewFilter.mostRecent;

  Future<void> _navigateToWriteReview() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WriteEditReviewScreen(
          destinationId: widget.destinationId,
          destinationName: widget.destinationName,
        ),
      ),
    );

    if (result == true) {
      AppLogger.info(_tag, 'Review submitted, refreshing list');
    }
  }

  Future<void> _deleteReview(DestinationReview review) async {
    await HapticHelper.warning();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Review'),
        content: const Text('Are you sure you want to delete this review? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await HapticHelper.heavyImpact();
              if (!context.mounted) return;
              Navigator.pop(context, true);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    AppLogger.debug(_tag, 'Deleting review', {'reviewId': review.id});

    final success = await _reviewService.deleteReview(
      reviewId: review.id,
      destinationId: widget.destinationId,
    );

    if (!mounted) return;

    if (success) {
      await HapticHelper.success();
      AppLogger.success(_tag, 'Review deleted successfully');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Review deleted successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      await HapticHelper.error();
      AppLogger.error(_tag, 'Failed to delete review');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete review'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showReviewOptions(DestinationReview review) {
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
              ListTile(
                leading: const Icon(Icons.edit, color: AppColors.black),
                title: const Text('Edit Review'),
                onTap: () async {
                  Navigator.pop(context);
                  await HapticHelper.lightImpact();

                  if (!mounted) return;

                  final result = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WriteEditReviewScreen(
                        destinationId: widget.destinationId,
                        destinationName: widget.destinationName,
                        review: review,
                      ),
                    ),
                  );

                  if (result == true && mounted) {
                    setState(() {}); // Trigger rebuild to refresh data
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: AppColors.error),
                title: const Text('Delete Review', style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(context);
                  _deleteReview(review);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _toggleHelpful(String reviewId, String userId) async {
    AppLogger.action('User toggled helpful', {'reviewId': reviewId});

    await _reviewService.toggleHelpful(
      reviewId: reviewId,
      userId: userId,
    );
  }

  Widget _buildRatingSummary(RatingSummary summary) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Average rating
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Large rating number
              Column(
                children: [
                  Text(
                    summary.averageRating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  ),
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < summary.averageRating.floor()
                            ? Icons.star
                            : Icons.star_border,
                        size: 20,
                        color: Colors.amber,
                      );
                    }),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${summary.totalReviews} reviews',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 32),

              // Rating distribution
              Expanded(
                child: Column(
                  children: List.generate(5, (index) {
                    final stars = 5 - index;
                    final count = summary.getCount(stars);
                    final percentage = summary.getPercentage(stars);

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Text(
                            '$stars',
                            style: AppTextStyles.bodySmall,
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.star,
                            size: 14,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: LinearProgressIndicator(
                              value: percentage / 100,
                              backgroundColor: AppColors.grey50,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.amber,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 30,
                            child: Text(
                              count.toString(),
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: ReviewFilter.values.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(ReviewSortHelper.getLabel(filter)),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
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

  Widget _buildReviewCard(DestinationReview review, String? currentUserId) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info and rating
          Row(
            children: [
              // Avatar
              _buildUserAvatar(review.userPhotoUrl),
              const SizedBox(width: 12),

              // Name and date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      DateFormat('dd MMM yyyy').format(review.createdAt),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Rating stars
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < review.rating.floor()
                        ? Icons.star
                        : Icons.star_border,
                    size: 16,
                    color: Colors.amber,
                  );
                }),
              ),

              // Options button (only for own reviews)
              if (currentUserId == review.userId)
                IconButton(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onPressed: () {
                    HapticHelper.lightImpact();
                    _showReviewOptions(review);
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Title
          Text(
            review.title,
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // Content
          Text(
            review.content,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),

          // Helpful button
          if (currentUserId != null)
            GestureDetector(
              onTap: () => _toggleHelpful(review.id, currentUserId),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: review.isMarkedHelpfulBy(currentUserId)
                      ? AppColors.black
                      : AppColors.grey50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: review.isMarkedHelpfulBy(currentUserId)
                        ? AppColors.black
                        : AppColors.border,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      review.isMarkedHelpfulBy(currentUserId)
                          ? Icons.thumb_up
                          : Icons.thumb_up_outlined,
                      size: 16,
                      color: review.isMarkedHelpfulBy(currentUserId)
                          ? AppColors.white
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Helpful (${review.helpfulCount})',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: review.isMarkedHelpfulBy(currentUserId)
                            ? AppColors.white
                            : AppColors.textSecondary,
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

  Widget _buildUserAvatar(String? photoUrl) {
    if (photoUrl != null && photoUrl.startsWith('avatar:')) {
      final emoji = photoUrl.replaceFirst('avatar:', '');
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.grey50,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Center(
          child: Text(emoji, style: const TextStyle(fontSize: 24)),
        ),
      );
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.grey50,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: const Center(
        child: Text('👤', style: TextStyle(fontSize: 24)),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Reviews', style: AppTextStyles.headlineSmall),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: AppColors.black),
            onPressed: _navigateToWriteReview,
            tooltip: 'Write Review',
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
          // Rating summary
          StreamBuilder<RatingSummary?>(
            stream: _reviewService.getRatingSummaryStream(widget.destinationId),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox(height: 120);
              }

              return _buildRatingSummary(snapshot.data!);
            },
          ),

          // Filter chips
          _buildFilterChips(),
          const SizedBox(height: 8),

          // Reviews list
          Expanded(
            child: Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                final currentUserId = authProvider.user?.uid;

                return StreamBuilder<List<DestinationReview>>(
                  stream: _reviewService.getReviewsStream(
                    destinationId: widget.destinationId,
                    filter: _selectedFilter,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.black,
                          ),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error loading reviews',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      );
                    }

                    final reviews = snapshot.data ?? [];

                    if (reviews.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('⭐', style: TextStyle(fontSize: 64)),
                            const SizedBox(height: 16),
                            Text(
                              'No reviews yet',
                              style: AppTextStyles.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Be the first to review this destination',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: _navigateToWriteReview,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.black,
                                foregroundColor: AppColors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                              child: const Text('Write Review'),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: reviews.length,
                      itemBuilder: (context, index) {
                        return _buildReviewCard(reviews[index], currentUserId);
                      },
                    );
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

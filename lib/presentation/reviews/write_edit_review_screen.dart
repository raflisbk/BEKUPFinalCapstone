import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/user_provider.dart';
import '../../core/models/review_model.dart';
import '../../services/review_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/haptic_helper.dart';

/// Unified screen for writing new reviews or editing existing ones
class WriteEditReviewScreen extends StatefulWidget {
  final String destinationId;
  final String destinationName;
  final Review? review; // If null, write mode; if not null, edit mode

  const WriteEditReviewScreen({
    super.key,
    required this.destinationId,
    required this.destinationName,
    this.review,
  });

  @override
  State<WriteEditReviewScreen> createState() => _WriteEditReviewScreenState();
}

class _WriteEditReviewScreenState extends State<WriteEditReviewScreen> {
  static const String _tag = 'WriteEditReviewScreen';

  final ReviewService _reviewService = ReviewService();
  late TextEditingController _titleController;
  late TextEditingController _contentController;

  late double _rating;
  bool _isSubmitting = false;

  bool get isEditMode => widget.review != null;

  @override
  void initState() {
    super.initState();

    // Initialize with existing review data if in edit mode
    _titleController = TextEditingController(text: widget.review?.title ?? '');
    _contentController = TextEditingController(text: widget.review?.content ?? '');
    _rating = widget.review?.rating ?? 0.0;

    AppLogger.debug(_tag, isEditMode ? 'Edit mode initialized' : 'Write mode initialized');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveReview() async {
    if (_rating == 0) {
      await HapticHelper.error();
      _showError('Please select a rating');
      return;
    }

    if (_titleController.text.trim().isEmpty) {
      await HapticHelper.error();
      _showError('Please enter a title');
      return;
    }

    if (_contentController.text.trim().isEmpty) {
      await HapticHelper.error();
      _showError('Please write your review');
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    if (authProvider.user == null) {
      await HapticHelper.error();
      _showError('You must be logged in to continue');
      return;
    }

    setState(() => _isSubmitting = true);
    await HapticHelper.buttonTap();

    try {
      bool success;

      if (isEditMode) {
        // Update existing review
        AppLogger.debug(_tag, 'Updating review', {
          'reviewId': widget.review!.id,
          'rating': _rating,
        });

        success = await _reviewService.updateReview(
          reviewId: widget.review!.id,
          destinationId: widget.destinationId,
          rating: _rating,
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
        );

        if (success) {
          AppLogger.success(_tag, 'Review updated successfully');
        }
      } else {
        // Create new review
        AppLogger.action('User submitting review', {
          'destinationId': widget.destinationId,
          'rating': _rating,
        });

        success = await _reviewService.submitReview(
          destinationId: widget.destinationId,
          destinationName: widget.destinationName,
          userId: authProvider.user!.uid,
          userName: userProvider.currentUser?.displayName ?? 'Anonymous',
          userPhotoUrl: userProvider.currentUser?.photoUrl,
          rating: _rating,
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
        );

        if (success) {
          AppLogger.success(_tag, 'Review submitted successfully');
        }
      }

      if (!mounted) return;

      setState(() => _isSubmitting = false);

      if (success) {
        await HapticHelper.success();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditMode ? 'Review updated successfully' : 'Review submitted successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      } else {
        await HapticHelper.error();
        _showError(isEditMode ? 'Failed to update review' : 'Failed to submit review');
      }
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Error saving review', e, stackTrace);
      await HapticHelper.error();

      if (!mounted) return;

      setState(() => _isSubmitting = false);
      _showError('An error occurred. Please try again.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  Widget _buildRatingSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Rating',
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final starValue = index + 1.0;
            return GestureDetector(
              onTap: () async {
                await HapticHelper.selectionClick();
                setState(() => _rating = starValue);
                AppLogger.debug(_tag, 'Rating selected', {'rating': starValue});
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  _rating >= starValue ? Icons.star : Icons.star_border,
                  size: 40,
                  color: _rating >= starValue ? Colors.amber : AppColors.textSecondary,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        if (_rating > 0)
          Center(
            child: Text(
              _getRatingText(_rating),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
      ],
    );
  }

  String _getRatingText(double rating) {
    if (rating == 5) return 'Excellent!';
    if (rating == 4) return 'Very Good';
    if (rating == 3) return 'Good';
    if (rating == 2) return 'Fair';
    return 'Poor';
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
          isEditMode ? 'Edit Review' : 'Write Review',
          style: AppTextStyles.headlineSmall,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: AppColors.divider,
            height: 1,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Destination name
            Text(
              widget.destinationName,
              style: AppTextStyles.headlineMedium,
            ),
            const SizedBox(height: 24),

            // Rating selector
            _buildRatingSelector(),
            const SizedBox(height: 32),

            // Title field
            Text(
              'Review Title',
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Summarize your experience',
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                filled: true,
                fillColor: AppColors.grey50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.black, width: 2),
                ),
              ),
              style: AppTextStyles.bodyMedium,
              maxLength: 100,
            ),
            const SizedBox(height: 24),

            // Content field
            Text(
              'Your Review',
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _contentController,
              decoration: InputDecoration(
                hintText: 'Share your experience with other travelers...',
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                filled: true,
                fillColor: AppColors.grey50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.black, width: 2),
                ),
              ),
              style: AppTextStyles.bodyMedium,
              maxLines: 8,
              maxLength: 500,
            ),
            const SizedBox(height: 32),

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _saveReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.black,
                  foregroundColor: AppColors.white,
                  disabledBackgroundColor: AppColors.grey300,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        isEditMode ? 'Update Review' : 'Submit Review',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

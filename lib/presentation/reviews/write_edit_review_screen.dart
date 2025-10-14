import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/providers/auth_provider.dart';
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
  final Review? existingReview;

  const WriteEditReviewScreen({
    super.key,
    required this.destinationId,
    required this.destinationName,
    this.existingReview,
  });

  @override
  State<WriteEditReviewScreen> createState() => _WriteEditReviewScreenState();
}

class _WriteEditReviewScreenState extends State<WriteEditReviewScreen> {
  static const String _tag = 'WriteEditReviewScreen';

  final ReviewService _reviewService = ReviewService();
  final ImagePicker _imagePicker = ImagePicker();

  late TextEditingController _titleController;
  late TextEditingController _contentController;

  late double _rating;
  bool _isSubmitting = false;
  bool _isUploadingPhotos = false;

  // Photo management
  List<String> _existingPhotoUrls = [];
  final List<File> _newPhotoFiles = [];
  final int _maxPhotos = 5;

  bool get isEditMode => widget.existingReview != null;

  @override
  void initState() {
    super.initState();

    // Initialize with existing review data if in edit mode
    _titleController = TextEditingController(text: widget.existingReview?.title ?? '');
    _contentController = TextEditingController(text: widget.existingReview?.content ?? '');
    _rating = widget.existingReview?.rating ?? 0.0;
    _existingPhotoUrls = widget.existingReview?.photoUrls ?? [];

    AppLogger.debug(_tag, isEditMode ? 'Edit mode initialized' : 'Write mode initialized', {
      'existingPhotos': _existingPhotoUrls.length,
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // Photo picker methods
  Future<void> _pickPhotos() async {
    try {
      final totalPhotos = _existingPhotoUrls.length + _newPhotoFiles.length;
      if (totalPhotos >= _maxPhotos) {
        await HapticHelper.error();
        _showError('Maximum $_maxPhotos photos allowed');
        return;
      }

      await HapticHelper.buttonTap();

      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (images.isEmpty) return;

      final remainingSlots = _maxPhotos - totalPhotos;
      final imagesToAdd = images.take(remainingSlots).toList();

      setState(() {
        _newPhotoFiles.addAll(imagesToAdd.map((xFile) => File(xFile.path)));
      });

      AppLogger.info(_tag, 'Photos selected', {
        'newPhotos': imagesToAdd.length,
        'totalPhotos': _existingPhotoUrls.length + _newPhotoFiles.length,
      });

      if (images.length > remainingSlots) {
        _showError('Only $remainingSlots more photos can be added');
      }
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Error picking photos', e, stackTrace);
      await HapticHelper.error();
      _showError('Failed to select photos');
    }
  }

  Future<void> _takePicture() async {
    try {
      final totalPhotos = _existingPhotoUrls.length + _newPhotoFiles.length;
      if (totalPhotos >= _maxPhotos) {
        await HapticHelper.error();
        _showError('Maximum $_maxPhotos photos allowed');
        return;
      }

      await HapticHelper.buttonTap();

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() {
        _newPhotoFiles.add(File(image.path));
      });

      AppLogger.info(_tag, 'Photo captured from camera');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Error taking picture', e, stackTrace);
      await HapticHelper.error();
      _showError('Failed to take picture');
    }
  }

  void _removeExistingPhoto(int index) async {
    await HapticHelper.lightImpact();
    setState(() {
      _existingPhotoUrls.removeAt(index);
    });
    AppLogger.debug(_tag, 'Existing photo removed', {'index': index});
  }

  void _removeNewPhoto(int index) async {
    await HapticHelper.lightImpact();
    setState(() {
      _newPhotoFiles.removeAt(index);
    });
    AppLogger.debug(_tag, 'New photo removed', {'index': index});
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.black),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _takePicture();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.black),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickPhotos();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
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

    if (authProvider.user == null) {
      await HapticHelper.error();
      _showError('You must be logged in to continue');
      return;
    }

    setState(() => _isSubmitting = true);
    await HapticHelper.buttonTap();

    try {
      bool success;
      List<String> allPhotoUrls = List.from(_existingPhotoUrls);

      // Upload new photos if any
      if (_newPhotoFiles.isNotEmpty) {
        setState(() => _isUploadingPhotos = true);

        AppLogger.info(_tag, 'Uploading ${_newPhotoFiles.length} photos');

        final uploadedUrls = await _reviewService.uploadReviewPhotos(
          _newPhotoFiles.map((file) => file.path).toList(),
        );

        allPhotoUrls.addAll(uploadedUrls);

        setState(() => _isUploadingPhotos = false);

        AppLogger.info(_tag, 'Photo upload completed', {
          'uploaded': uploadedUrls.length,
          'total': _newPhotoFiles.length,
        });
      }

      if (isEditMode) {
        // Update existing review
        AppLogger.debug(_tag, 'Updating review', {
          'reviewId': widget.existingReview!.id,
          'rating': _rating,
          'photoCount': allPhotoUrls.length,
        });

        final result = await _reviewService.updateReview(
          reviewId: widget.existingReview!.id,
          reviewerId: authProvider.user!.uid,
          rating: _rating,
          content: _contentController.text.trim(),
          imageUrls: allPhotoUrls,
        );
        success = result;

        if (success) {
          AppLogger.success(_tag, 'Review updated successfully');
        }
      } else {
        // Create new review
        AppLogger.action('User submitting review', {
          'destinationId': widget.destinationId,
          'rating': _rating,
          'photoCount': allPhotoUrls.length,
        });

        final reviewId = await _reviewService.submitReview(
          reviewerId: authProvider.user!.uid,
          targetId: widget.destinationId,
          targetType: 'destination',
          rating: _rating,
          content: _contentController.text.trim(),
          imageUrls: allPhotoUrls,
        );
        success = reviewId != null;

        if (success) {
          AppLogger.success(_tag, 'Review submitted successfully');
        }
      }

      if (!mounted) return;

      setState(() => _isSubmitting = false);

      if (success) {
        await HapticHelper.success();

        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditMode ? 'Review updated successfully' : 'Review submitted successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        // ignore: use_build_context_synchronously
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

  Widget _buildPhotoSection() {
    final totalPhotos = _existingPhotoUrls.length + _newPhotoFiles.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Photos (Optional)',
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '$totalPhotos/$_maxPhotos',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Photo grid
        if (totalPhotos > 0)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Existing photos
              ..._existingPhotoUrls.asMap().entries.map((entry) {
                final index = entry.key;
                final url = entry.value;
                return _buildPhotoThumbnail(
                  imageProvider: NetworkImage(url),
                  onRemove: () => _removeExistingPhoto(index),
                );
              }),

              // New photos
              ..._newPhotoFiles.asMap().entries.map((entry) {
                final index = entry.key;
                final file = entry.value;
                return _buildPhotoThumbnail(
                  imageProvider: FileImage(file),
                  onRemove: () => _removeNewPhoto(index),
                );
              }),

              // Add photo button
              if (totalPhotos < _maxPhotos) _buildAddPhotoButton(),
            ],
          ),

        // Add photo button (when no photos)
        if (totalPhotos == 0) _buildAddPhotoButton(),
      ],
    );
  }

  Widget _buildPhotoThumbnail({
    required ImageProvider imageProvider,
    required VoidCallback onRemove,
  }) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: DecorationImage(
          image: imageProvider,
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          // Remove button
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddPhotoButton() {
    return GestureDetector(
      onTap: _showPhotoOptions,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: AppColors.grey50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.border,
            width: 2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.add_photo_alternate,
              size: 32,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 4),
            Text(
              'Add Photo',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
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

            // Photo section
            _buildPhotoSection(),
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
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                              strokeWidth: 2,
                            ),
                          ),
                          if (_isUploadingPhotos) ...[
                            const SizedBox(width: 12),
                            Text(
                              'Uploading photos...',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.white,
                              ),
                            ),
                          ],
                        ],
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

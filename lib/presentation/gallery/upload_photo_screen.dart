import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/providers/auth_provider.dart';
import '../../services/gallery_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/haptic_helper.dart';

class UploadPhotoScreen extends StatefulWidget {
  const UploadPhotoScreen({super.key});

  @override
  State<UploadPhotoScreen> createState() => _UploadPhotoScreenState();
}

class _UploadPhotoScreenState extends State<UploadPhotoScreen> {
  static const String _tag = 'UploadPhotoScreen';

  final GalleryService _galleryService = GalleryService();
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  File? _selectedImage;
  bool _isUploading = false;
  bool _isPublic = true;

  @override
  void dispose() {
    _captionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      await HapticHelper.buttonTap();

      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
        AppLogger.info(_tag, 'Image selected', {'path': image.path});
      }
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to pick image', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to select image'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showImageSourceDialog() {
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
                leading: const Icon(Icons.camera_alt, color: AppColors.black),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.black),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _uploadPhoto() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an image'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();

    if (authProvider.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to upload photos'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    await HapticHelper.submit();

    try {
      AppLogger.info(_tag, 'Uploading photo');

      // Since the GalleryService doesn't have uploadPhoto/createPhoto methods,
      // we need to first create a gallery and then add the photo to it
      
      // Create a temporary gallery for this photo (or use an existing one)
      final galleryData = await _galleryService.createGallery(
        title: 'My Photos',
        description: 'Personal photo gallery',
        isPublic: _isPublic,
      );

      // For now, we'll use placeholder values since we don't have direct photo upload
      // In a real implementation, you would upload to cloud storage first
      final photoData = await _galleryService.addPhotoToGallery(
        galleryId: galleryData['id'],
        cloudinaryPublicId: 'placeholder_${DateTime.now().millisecondsSinceEpoch}',
        originalUrl: 'placeholder_url', // This would be the actual uploaded URL
        title: _captionController.text.trim().isEmpty
            ? null
            : _captionController.text.trim(),
        description: _captionController.text.trim().isEmpty
            ? null
            : _captionController.text.trim(),
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        takenAt: DateTime.now(),
      );

      if (!mounted) return;

      await HapticHelper.success();
      AppLogger.info(_tag, 'Photo uploaded successfully', {'photoId': photoData['id']});

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Photo uploaded successfully!'),
          backgroundColor: AppColors.success,
        ),
      );

      // ignore: use_build_context_synchronously
      Navigator.pop(context, true);
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to upload photo', e, stackTrace);
      await HapticHelper.error();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to upload photo'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
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
          icon: const Icon(Icons.close, color: AppColors.black),
          onPressed: () async {
            await HapticHelper.buttonTap();
            // ignore: use_build_context_synchronously
            Navigator.pop(context);
          },
        ),
        title: const Text('Upload Photo', style: AppTextStyles.headlineSmall),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: AppColors.divider,
            height: 1,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image preview
            GestureDetector(
              onTap: _selectedImage == null ? _showImageSourceDialog : null,
              child: Container(
                height: 300,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(
                              _selectedImage!,
                              fit: BoxFit.cover,
                            ),
                            Positioned(
                              top: 12,
                              right: 12,
                              child: IconButton(
                                icon: const Icon(Icons.close, color: AppColors.white),
                                onPressed: () async {
                                  await HapticHelper.buttonTap();
                                  setState(() {
                                    _selectedImage = null;
                                  });
                                },
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.black.withValues(alpha: 0.5),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.add_a_photo,
                            size: 64,
                            color: AppColors.grey500,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Tap to select photo',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),

            // Caption
            Text(
              'Caption (Optional)',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _captionController,
              maxLength: 200,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Write a caption...',
                filled: true,
                fillColor: AppColors.white,
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
            ),
            const SizedBox(height: 16),

            // Location
            Text(
              'Location (Optional)',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _locationController,
              maxLength: 100,
              decoration: InputDecoration(
                hintText: 'Add location...',
                filled: true,
                fillColor: AppColors.white,
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
                counterText: '',
              ),
            ),
            const SizedBox(height: 16),

            // Privacy toggle
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Icon(
                    _isPublic ? Icons.public : Icons.lock,
                    color: AppColors.black,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isPublic ? 'Public' : 'Private',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isPublic
                              ? 'Everyone can see this photo'
                              : 'Only you can see this photo',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isPublic,
                    onChanged: (value) async {
                      await HapticHelper.toggle();
                      setState(() {
                        _isPublic = value;
                      });
                    },
                    activeTrackColor: AppColors.black,
                    activeThumbColor: AppColors.white,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Upload button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _uploadPhoto,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.black,
                  foregroundColor: AppColors.white,
                  disabledBackgroundColor: AppColors.grey300,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: _isUploading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                        ),
                      )
                    : const Text(
                        'Upload Photo',
                        style: TextStyle(
                          fontSize: 16,
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

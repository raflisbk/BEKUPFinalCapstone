import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../core/models/destination_model.dart';
import '../../core/providers/auth_provider.dart';
import '../../services/destination_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/haptic_helper.dart';

/// Add or Edit destination screen with form validation
class AddEditDestinationScreen extends StatefulWidget {
  final String? destinationId;
  final Destination? destination;

  const AddEditDestinationScreen({
    super.key,
    this.destinationId,
    this.destination,
  });

  @override
  State<AddEditDestinationScreen> createState() => _AddEditDestinationScreenState();
}

class _AddEditDestinationScreenState extends State<AddEditDestinationScreen> {
  final _formKey = GlobalKey<FormState>();
  final DestinationService _destinationService = DestinationService();
  final ImagePicker _imagePicker = ImagePicker();

  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  final TextEditingController _openingHoursController = TextEditingController();
  final TextEditingController _bestTimeController = TextEditingController();
  final TextEditingController _facilityController = TextEditingController();
  final TextEditingController _activityController = TextEditingController();

  // Form data
  String _selectedCategory = DestinationCategory.other.name;
  double _priceRange = 3.0;
  List<String> _facilities = [];
  List<String> _activities = [];
  List<File> _imageFiles = [];
  List<String> _existingImageUrls = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.destination != null) {
      _loadDestinationData();
    }
  }

  void _loadDestinationData() {
    final dest = widget.destination!;
    _nameController.text = dest.name;
    _descriptionController.text = dest.description;
    _locationController.text = dest.location;
    _latitudeController.text = dest.latitude.toString();
    _longitudeController.text = dest.longitude.toString();
    _openingHoursController.text = dest.openingHours;
    _bestTimeController.text = dest.bestTimeToVisit;
    _selectedCategory = dest.category;
    _priceRange = dest.priceRange;
    _facilities = List.from(dest.facilities);
    _activities = List.from(dest.activities);
    _existingImageUrls = List.from(dest.images);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _openingHoursController.dispose();
    _bestTimeController.dispose();
    _facilityController.dispose();
    _activityController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage();

      if (images.isNotEmpty && images.length <= 5) {
        setState(() {
          _imageFiles = images.map((img) => File(img.path)).toList();
        });
        HapticHelper.success();
      } else if (images.length > 5) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Maximum 5 images allowed')),
        );
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking images: $e')),
      );
    }
  }

  Future<List<String>> _uploadImages() async {
    final List<String> uploadedUrls = [];

    for (var imageFile in _imageFiles) {
      final fileName = 'destinations/${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';
      final ref = FirebaseStorage.instance.ref().child(fileName);

      final uploadTask = await ref.putFile(imageFile);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      uploadedUrls.add(downloadUrl);
    }

    return uploadedUrls;
  }

  void _addFacility() {
    if (_facilityController.text.isNotEmpty) {
      setState(() {
        _facilities.add(_facilityController.text);
        _facilityController.clear();
      });
      HapticHelper.lightImpact();
    }
  }

  void _removeFacility(int index) {
    setState(() {
      _facilities.removeAt(index);
    });
    HapticHelper.lightImpact();
  }

  void _addActivity() {
    if (_activityController.text.isNotEmpty) {
      setState(() {
        _activities.add(_activityController.text);
        _activityController.clear();
      });
      HapticHelper.lightImpact();
    }
  }

  void _removeActivity(int index) {
    setState(() {
      _activities.removeAt(index);
    });
    HapticHelper.lightImpact();
  }

  Future<void> _saveDestination() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_imageFiles.isEmpty && _existingImageUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one image')),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to continue')),
      );
      return;
    }

    setState(() => _isLoading = true);
    HapticHelper.buttonTap();

    try {
      // Upload new images if any
      List<String> imageUrls = List.from(_existingImageUrls);
      if (_imageFiles.isNotEmpty) {
        final uploadedUrls = await _uploadImages();
        imageUrls.addAll(uploadedUrls);
      }

      if (widget.destinationId == null) {
        // Create new destination
        final destinationId = await _destinationService.createDestination(
          name: _nameController.text,
          description: _descriptionController.text,
          location: _locationController.text,
          latitude: double.parse(_latitudeController.text),
          longitude: double.parse(_longitudeController.text),
          category: _selectedCategory,
          images: imageUrls,
          priceRange: _priceRange,
          facilities: _facilities,
          activities: _activities,
          openingHours: _openingHoursController.text,
          bestTimeToVisit: _bestTimeController.text,
          userId: userId,
        );

        if (destinationId != null) {
          await HapticHelper.success();
          if (mounted) {
            Navigator.pop(context, true);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Destination created successfully')),
            );
          }
        } else {
          throw Exception('Failed to create destination');
        }
      } else {
        // Update existing destination
        final success = await _destinationService.updateDestination(
          destinationId: widget.destinationId!,
          name: _nameController.text,
          description: _descriptionController.text,
          location: _locationController.text,
          latitude: double.parse(_latitudeController.text),
          longitude: double.parse(_longitudeController.text),
          category: _selectedCategory,
          images: imageUrls,
          priceRange: _priceRange,
          facilities: _facilities,
          activities: _activities,
          openingHours: _openingHoursController.text,
          bestTimeToVisit: _bestTimeController.text,
        );

        if (success) {
          await HapticHelper.success();
          if (mounted) {
            Navigator.pop(context, true);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Destination updated successfully')),
            );
          }
        } else {
          throw Exception('Failed to update destination');
        }
      }
    } catch (e) {
      await HapticHelper.error();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.destinationId == null ? 'Add Destination' : 'Edit Destination'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.black,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: AppColors.grey200,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Images section
            _buildImagesSection(),
            const SizedBox(height: 24),

            // Basic info
            _buildTextField(
              controller: _nameController,
              label: 'Destination Name',
              hint: 'e.g., Borobudur Temple',
              validator: (value) => value?.isEmpty ?? true ? 'Name is required' : null,
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _descriptionController,
              label: 'Description',
              hint: 'Describe the destination...',
              maxLines: 4,
              validator: (value) => value?.isEmpty ?? true ? 'Description is required' : null,
            ),
            const SizedBox(height: 16),

            // Category
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: DestinationCategory.values.map((category) {
                return DropdownMenuItem(
                  value: category.name,
                  child: Row(
                    children: [
                      Icon(category.icon, size: 20),
                      const SizedBox(width: 12),
                      Text(category.displayName),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedCategory = value);
                }
              },
            ),
            const SizedBox(height: 16),

            // Location
            _buildTextField(
              controller: _locationController,
              label: 'Location',
              hint: 'City, Province',
              validator: (value) => value?.isEmpty ?? true ? 'Location is required' : null,
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _latitudeController,
                    label: 'Latitude',
                    hint: 'e.g., -7.6079',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Required';
                      if (double.tryParse(value!) == null) return 'Invalid number';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _longitudeController,
                    label: 'Longitude',
                    hint: 'e.g., 110.2038',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Required';
                      if (double.tryParse(value!) == null) return 'Invalid number';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Price range
            Text(
              'Price Range',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Slider(
              value: _priceRange,
              min: 1,
              max: 5,
              divisions: 4,
              label: Destination(
                id: '',
                name: '',
                description: '',
                location: '',
                latitude: 0,
                longitude: 0,
                category: '',
                images: [],
                priceRange: _priceRange,
                rating: 0,
                reviewCount: 0,
                facilities: [],
                activities: [],
                openingHours: '',
                bestTimeToVisit: '',
                isVerified: false,
                createdBy: '',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ).priceRangeText,
              onChanged: (value) {
                setState(() => _priceRange = value);
              },
            ),
            const SizedBox(height: 16),

            // Opening hours
            _buildTextField(
              controller: _openingHoursController,
              label: 'Opening Hours',
              hint: 'e.g., Daily 08:00 - 17:00',
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _bestTimeController,
              label: 'Best Time to Visit',
              hint: 'e.g., April - October (Dry Season)',
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 24),

            // Facilities
            _buildListSection(
              title: 'Facilities',
              items: _facilities,
              controller: _facilityController,
              hint: 'e.g., Parking, WiFi, Restaurant',
              onAdd: _addFacility,
              onRemove: _removeFacility,
            ),
            const SizedBox(height: 24),

            // Activities
            _buildListSection(
              title: 'Activities',
              items: _activities,
              controller: _activityController,
              hint: 'e.g., Hiking, Photography, Temple Tour',
              onAdd: _addActivity,
              onRemove: _removeActivity,
            ),
            const SizedBox(height: 32),

            // Save button
            ElevatedButton(
              onPressed: _isLoading ? null : _saveDestination,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.black,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(widget.destinationId == null ? 'Create Destination' : 'Update Destination'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildImagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Images',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        if (_imageFiles.isEmpty && _existingImageUrls.isEmpty)
          InkWell(
            onTap: _pickImages,
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.grey300, style: BorderStyle.solid),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate, size: 48, color: AppColors.grey500),
                    SizedBox(height: 8),
                    Text('Add Images (Max 5)'),
                  ],
                ),
              ),
            ),
          )
        else
          Column(
            children: [
              SizedBox(
                height: 120,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    ..._imageFiles.map((file) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            file,
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    }),
                    if (_imageFiles.length < 5)
                      InkWell(
                        onTap: _pickImages,
                        child: Container(
                          width: 120,
                          decoration: BoxDecoration(
                            color: AppColors.grey100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.grey300),
                          ),
                          child: const Icon(Icons.add, size: 32),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Widget _buildListSection({
    required String title,
    required List<String> items,
    required TextEditingController controller,
    required String hint,
    required VoidCallback onAdd,
    required Function(int) onRemove,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: hint,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: onAdd,
              icon: const Icon(Icons.add_circle),
              color: AppColors.black,
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (items.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items.asMap().entries.map((entry) {
              return Chip(
                label: Text(entry.value),
                onDeleted: () => onRemove(entry.key),
                deleteIcon: const Icon(Icons.close, size: 18),
              );
            }).toList(),
          ),
      ],
    );
  }
}

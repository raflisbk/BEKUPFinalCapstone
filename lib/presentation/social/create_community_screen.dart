import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/haptic_helper.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/config/service_locator.dart';
import '../../core/interfaces/i_community_service.dart';

/// Screen to create a new community
class CreateCommunityScreen extends StatefulWidget {
  const CreateCommunityScreen({super.key});

  @override
  State<CreateCommunityScreen> createState() => _CreateCommunityScreenState();
}

class _CreateCommunityScreenState extends State<CreateCommunityScreen> {
  static const String _tag = 'CreateCommunityScreen';
  
  final ICommunityService _communityService = ServiceLocator.iCommunityService;
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  String _selectedCategory = 'travel';
  String _selectedVisibility = 'public';
  final List<String> _selectedTags = [];
  bool _isCreating = false;

  final List<Map<String, dynamic>> _categories = [
    {'id': 'travel', 'name': 'Travel', 'icon': Icons.flight},
    {'id': 'destination', 'name': 'Destinations', 'icon': Icons.place},
    {'id': 'activity', 'name': 'Activities', 'icon': Icons.hiking},
    {'id': 'food', 'name': 'Food & Dining', 'icon': Icons.restaurant},
    {'id': 'culture', 'name': 'Culture', 'icon': Icons.museum},
    {'id': 'photography', 'name': 'Photography', 'icon': Icons.camera_alt},
    {'id': 'budget', 'name': 'Budget Travel', 'icon': Icons.savings},
    {'id': 'adventure', 'name': 'Adventure', 'icon': Icons.terrain},
  ];

  final List<Map<String, String>> _visibilityOptions = [
    {
      'id': 'public',
      'name': 'Public',
      'description': 'Anyone can see and join',
    },
    {
      'id': 'private',
      'name': 'Private',
      'description': 'Anyone can see, approval needed to join',
    },
    {
      'id': 'secret',
      'name': 'Secret',
      'description': 'Only invited members can see',
    },
  ];

  final List<String> _availableTags = [
    'Backpacking',
    'Luxury',
    'Solo Travel',
    'Family',
    'Adventure',
    'Beach',
    'Mountains',
    'City',
    'Wildlife',
    'Camping',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createCommunity() async {
    if (!_formKey.currentState!.validate()) return;
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated || authProvider.isGuest) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to create a community')),
      );
      return;
    }

    try {
      setState(() => _isCreating = true);
      HapticHelper.mediumImpact();
      
      final community = await _communityService.createCommunity(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        visibility: _selectedVisibility,
        tags: _selectedTags,
      );
      
      AppLogger.success(_tag, 'Community created: ${community['id']}');
      
      if (mounted) {
          HapticHelper.heavyImpact();
        Navigator.pop(context, community);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Community created successfully!')),
        );
      }
    } catch (e) {
      AppLogger.error(_tag, 'Failed to create community', e);
      if (mounted) {
          HapticHelper.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create community: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey50,
      appBar: AppBar(
        title: const Text('Create Community'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.black,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.grey200),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Name
            _buildSectionTitle('Community Name'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Enter community name',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.grey300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.grey300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a community name';
                }
                if (value.trim().length < 3) {
                  return 'Name must be at least 3 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            
            // Description
            _buildSectionTitle('Description'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: 'Describe your community...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.grey300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.grey300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a description';
                }
                if (value.trim().length < 10) {
                  return 'Description must be at least 10 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            
            // Category
            _buildSectionTitle('Category'),
            const SizedBox(height: 8),
            _buildCategoryGrid(),
            const SizedBox(height: 24),
            
            // Visibility
            _buildSectionTitle('Privacy'),
            const SizedBox(height: 8),
            _buildVisibilityOptions(),
            const SizedBox(height: 24),
            
            // Tags
            _buildSectionTitle('Tags (Optional)'),
            const SizedBox(height: 8),
            _buildTagSelection(),
            const SizedBox(height: 32),
            
            // Create button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isCreating ? null : _createCommunity,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: AppColors.grey300,
                ),
                child: _isCreating
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Create Community',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.titleMedium.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildCategoryGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.9,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final category = _categories[index];
        final isSelected = _selectedCategory == category['id'];
        
        return GestureDetector(
          onTap: () {
            HapticHelper.selectionClick();
            setState(() {
              _selectedCategory = category['id'] as String;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.grey300,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  category['icon'] as IconData,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  size: 28,
                ),
                const SizedBox(height: 6),
                Text(
                  category['name'] as String,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVisibilityOptions() {
    return Column(
      children: _visibilityOptions.map((option) {
        final isSelected = _selectedVisibility == option['id'];
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () {
              HapticHelper.selectionClick();
              setState(() {
                _selectedVisibility = option['id']!;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.grey300,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.grey300,
                        width: 2,
                      ),
                      color: isSelected ? AppColors.primary : Colors.transparent,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          option['name']!,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isSelected ? AppColors.primary : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          option['description']!,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTagSelection() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _availableTags.map((tag) {
        final isSelected = _selectedTags.contains(tag);
        
        return FilterChip(
          label: Text(tag),
          selected: isSelected,
          onSelected: (selected) {
            HapticHelper.selectionClick();
            setState(() {
              if (selected) {
                _selectedTags.add(tag);
              } else {
                _selectedTags.remove(tag);
              }
            });
          },
          backgroundColor: Colors.white,
          selectedColor: AppColors.primary.withValues(alpha: 0.1),
          labelStyle: AppTextStyles.bodySmall.copyWith(
            color: isSelected ? AppColors.primary : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
          side: BorderSide(
            color: isSelected ? AppColors.primary : AppColors.grey300,
          ),
        );
      }).toList(),
    );
  }
}

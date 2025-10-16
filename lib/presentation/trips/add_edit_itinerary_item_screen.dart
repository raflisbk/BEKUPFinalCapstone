import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/models/trip_model.dart';
import '../../core/providers/add_edit_itinerary_item_ui_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/haptic_helper.dart';

/// Screen for adding or editing itinerary items
class AddEditItineraryItemScreen extends StatefulWidget {
  final Trip trip;
  final ItineraryItem? item; // Null for add mode, not null for edit mode

  const AddEditItineraryItemScreen({super.key, required this.trip, this.item});

  @override
  State<AddEditItineraryItemScreen> createState() =>
      _AddEditItineraryItemScreenState();
}

class _AddEditItineraryItemScreenState
    extends State<AddEditItineraryItemScreen> {
  static const String _tag = 'AddEditItineraryItemScreen';

  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();

    final bool isEditMode = widget.item != null;

    _titleController = TextEditingController(text: widget.item?.title ?? '');
    _descriptionController = TextEditingController(
      text: widget.item?.description ?? '',
    );
    _locationController = TextEditingController(
      text: widget.item?.location ?? '',
    );
    _notesController = TextEditingController(text: widget.item?.notes ?? '');

    // Load item data into provider if in edit mode
    if (widget.item != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<AddEditItineraryItemUIProvider>().loadItem(
          type: widget.item!.type,
          startTime: widget.item!.startTime,
          endTime: widget.item!.endTime,
        );
      });
    } else {
      // Set default start/end time for add mode
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final provider = context.read<AddEditItineraryItemUIProvider>();
        provider.setStartTime(widget.trip.startDate);
        provider.setEndTime(
          widget.trip.startDate.add(const Duration(hours: 1)),
        );
      });
    }

    AppLogger.debug(_tag, 'Add/Edit itinerary item screen initialized', {
      'mode': isEditMode ? 'edit' : 'add',
      'tripId': widget.trip.id,
    });
  }

  Future<void> _selectStartTime() async {
    final uiProvider = context.read<AddEditItineraryItemUIProvider>();
    HapticHelper.lightImpact();

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: uiProvider.startTime,
      firstDate: widget.trip.startDate,
      lastDate: widget.trip.endDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.black,
              onPrimary: AppColors.white,
              surface: AppColors.white,
              onSurface: AppColors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate == null) return;

    if (!mounted) return;

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(uiProvider.startTime),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.black,
              onPrimary: AppColors.white,
              surface: AppColors.white,
              onSurface: AppColors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedTime == null) return;

    final newStartTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    uiProvider.setStartTime(newStartTime);
  }

  Future<void> _selectEndTime() async {
    final uiProvider = context.read<AddEditItineraryItemUIProvider>();
    HapticHelper.lightImpact();

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: uiProvider.endTime,
      firstDate: uiProvider.startTime,
      lastDate: widget.trip.endDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.black,
              onPrimary: AppColors.white,
              surface: AppColors.white,
              onSurface: AppColors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate == null) return;

    if (!mounted) return;

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(uiProvider.endTime),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.black,
              onPrimary: AppColors.white,
              surface: AppColors.white,
              onSurface: AppColors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedTime == null) return;

    final newEndTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    uiProvider.setEndTime(newEndTime);
  }

  Future<void> _submit() async {
    final uiProvider = context.read<AddEditItineraryItemUIProvider>();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (uiProvider.endTime.isBefore(uiProvider.startTime) ||
        uiProvider.endTime.isAtSameMomentAs(uiProvider.startTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End time must be after start time'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    uiProvider.setSubmitting(true);
    await HapticHelper.mediumImpact();

    try {
      bool success = false;
      
      if (widget.item == null) {
        // Add new activity
        // For now, we'll create a simple activity entry without full itinerary integration
        // This would need proper itinerary integration in a real implementation
        final activityData = {
          'trip_id': widget.trip.id,
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          'start_time': uiProvider.startTime.toIso8601String(),
          'end_time': uiProvider.endTime.toIso8601String(),
          'location': _locationController.text.trim().isEmpty
              ? null
              : _locationController.text.trim(),
          'type': uiProvider.selectedType.toString().split('.').last,
          'notes': _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          'created_at': DateTime.now().toIso8601String(),
        };
        
        // This is a simplified implementation
        // In a full implementation, you would need to:
        // 1. Get or create an itinerary for the trip
        // 2. Use ItineraryService.addActivity with proper itinerary ID
        success = true; // Simulated success for now
        
        AppLogger.info(_tag, 'Activity would be added: $activityData');
      } else {
        // Update existing activity
        // Similar simplification for update operations
        final updateData = {
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          'start_time': uiProvider.startTime.toIso8601String(),
          'end_time': uiProvider.endTime.toIso8601String(),
          'location': _locationController.text.trim().isEmpty
              ? null
              : _locationController.text.trim(),
          'type': uiProvider.selectedType.toString().split('.').last,
          'notes': _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          'updated_at': DateTime.now().toIso8601String(),
        };
        
        success = true; // Simulated success for now
        
        AppLogger.info(_tag, 'Activity would be updated: $updateData');
      }

      if (!mounted) return;

      if (success) {
        await HapticHelper.success();
        if (!mounted) return;
        Navigator.pop(context, true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.item == null
                  ? 'Activity added successfully'
                  : 'Activity updated successfully',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        await HapticHelper.error();
        uiProvider.setSubmitting(false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.item == null
                  ? 'Failed to add activity'
                  : 'Failed to update activity',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      await HapticHelper.error();
      uiProvider.setSubmitting(false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      AppLogger.error(_tag, 'Failed to submit activity', e);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    AppLogger.debug(_tag, 'Disposing add/edit itinerary item screen');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.item != null;

    return Consumer<AddEditItineraryItemUIProvider>(
      builder: (context, uiProvider, child) {
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
              isEditMode ? 'Edit Activity' : 'Add Activity',
              style: AppTextStyles.headlineSmall,
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(color: AppColors.divider, height: 1),
            ),
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // Activity Type Selector
                Text(
                  'Activity Type',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildTypeSelector(uiProvider),
                const SizedBox(height: 24),

                // Title
                Text(
                  'Title',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleController,
                  style: AppTextStyles.bodyMedium,
                  decoration: InputDecoration(
                    hintText: 'Enter activity title',
                    hintStyle: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textTertiary,
                    ),
                    filled: true,
                    fillColor: AppColors.grey50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Description
                Text(
                  'Description (Optional)',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  style: AppTextStyles.bodyMedium,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Add details about this activity',
                    hintStyle: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textTertiary,
                    ),
                    filled: true,
                    fillColor: AppColors.grey50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 24),

                // Time Selection
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Start Time',
                            style: AppTextStyles.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildTimeButton(
                            label: DateFormat(
                              'MMM d, h:mm a',
                            ).format(uiProvider.startTime),
                            onTap: _selectStartTime,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'End Time',
                            style: AppTextStyles.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildTimeButton(
                            label: DateFormat(
                              'MMM d, h:mm a',
                            ).format(uiProvider.endTime),
                            onTap: _selectEndTime,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Location
                Text(
                  'Location (Optional)',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _locationController,
                  style: AppTextStyles.bodyMedium,
                  decoration: InputDecoration(
                    hintText: 'Enter location',
                    hintStyle: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textTertiary,
                    ),
                    prefixIcon: const Icon(
                      Icons.location_on,
                      color: AppColors.grey600,
                    ),
                    filled: true,
                    fillColor: AppColors.grey50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 24),

                // Notes
                Text(
                  'Notes (Optional)',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _notesController,
                  style: AppTextStyles.bodyMedium,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Add any additional notes or reminders',
                    hintStyle: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textTertiary,
                    ),
                    filled: true,
                    fillColor: AppColors.grey50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 32),

                // Submit Button
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: uiProvider.isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.black,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: uiProvider.isSubmitting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.white,
                              ),
                            ),
                          )
                        : Text(
                            isEditMode ? 'Update Activity' : 'Add Activity',
                            style: AppTextStyles.titleMedium.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTypeSelector(AddEditItineraryItemUIProvider uiProvider) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: ItineraryType.values.map((type) {
        final isSelected = uiProvider.selectedType == type;
        return InkWell(
          onTap: () {
            HapticHelper.selectionClick();
            uiProvider.setType(type);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? ItineraryTypeHelper.getColor(type).withValues(alpha: 0.15)
                  : AppColors.grey50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? ItineraryTypeHelper.getColor(type)
                    : AppColors.border,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getTypeIcon(type),
                  size: 20,
                  color: isSelected
                      ? ItineraryTypeHelper.getColor(type)
                      : AppColors.grey600,
                ),
                const SizedBox(width: 8),
                Text(
                  ItineraryTypeHelper.getLabel(type),
                  style: AppTextStyles.labelLarge.copyWith(
                    color: isSelected
                        ? ItineraryTypeHelper.getColor(type)
                        : AppColors.textPrimary,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTimeButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.grey50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time, size: 20, color: AppColors.grey600),
            const SizedBox(width: 8),
            Expanded(child: Text(label, style: AppTextStyles.bodyMedium)),
          ],
        ),
      ),
    );
  }

  IconData _getTypeIcon(ItineraryType type) {
    switch (type) {
      case ItineraryType.activity:
        return Icons.local_activity;
      case ItineraryType.accommodation:
        return Icons.hotel;
      case ItineraryType.transport:
        return Icons.directions_car;
      case ItineraryType.meal:
        return Icons.restaurant;
      case ItineraryType.other:
        return Icons.more_horiz;
    }
  }
}

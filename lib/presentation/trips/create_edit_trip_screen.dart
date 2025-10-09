import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/models/trip_model.dart';
import '../../services/trip_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/haptic_helper.dart';

/// Unified screen for creating new trips or editing existing ones
class CreateEditTripScreen extends StatefulWidget {
  final Trip? trip; // If null, create mode; if not null, edit mode

  const CreateEditTripScreen({
    super.key,
    this.trip,
  });

  @override
  State<CreateEditTripScreen> createState() => _CreateEditTripScreenState();
}

class _CreateEditTripScreenState extends State<CreateEditTripScreen> {
  static const String _tag = 'CreateEditTripScreen';

  final TripService _tripService = TripService();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;

  DateTime? _startDate;
  DateTime? _endDate;
  bool _isPublic = true;
  bool _isLoading = false;

  bool get isEditMode => widget.trip != null;

  @override
  void initState() {
    super.initState();

    // Initialize with existing trip data if in edit mode
    _titleController = TextEditingController(text: widget.trip?.title ?? '');
    _descriptionController = TextEditingController(text: widget.trip?.description ?? '');

    if (widget.trip != null) {
      _startDate = widget.trip!.startDate;
      _endDate = widget.trip!.endDate;
      _isPublic = widget.trip!.isPublic;
    }

    AppLogger.debug(_tag, isEditMode ? 'Edit mode initialized' : 'Create mode initialized');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    await HapticHelper.lightImpact();

    final DateTime? picked = await showDatePicker(
      // ignore: use_build_context_synchronously
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)), // 2 years
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

    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
        // Reset end date if it's before start date
        if (_endDate != null && _endDate!.isBefore(_startDate!)) {
          _endDate = null;
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    if (_startDate == null) {
      await HapticHelper.warning();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select start date first'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    await HapticHelper.lightImpact();

    final DateTime? picked = await showDatePicker(
      // ignore: use_build_context_synchronously
      context: context,
      initialDate: _endDate ?? _startDate!.add(const Duration(days: 1)),
      firstDate: _startDate!,
      lastDate: _startDate!.add(const Duration(days: 365)), // 1 year max trip
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

    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  int _getDurationInDays() {
    if (_startDate == null || _endDate == null) return 0;
    return _endDate!.difference(_startDate!).inDays + 1;
  }

  Future<void> _saveTrip() async {
    if (!_formKey.currentState!.validate()) {
      await HapticHelper.error();
      return;
    }

    if (_startDate == null || _endDate == null) {
      await HapticHelper.error();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select start and end dates'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;

    if (user == null) {
      await HapticHelper.error();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to continue'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    await HapticHelper.buttonTap();

    try {
      bool success;

      if (isEditMode) {
        // Update existing trip
        AppLogger.debug(_tag, 'Updating trip', {
          'tripId': widget.trip!.id,
          'title': _titleController.text,
        });

        success = await _tripService.updateTrip(
          tripId: widget.trip!.id,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          startDate: _startDate!,
          endDate: _endDate!,
          isPublic: _isPublic,
        );

        if (success) {
          AppLogger.success(_tag, 'Trip updated successfully');
        }
      } else {
        // Create new trip
        AppLogger.debug(_tag, 'Creating trip', {
          'title': _titleController.text,
          'duration': _getDurationInDays(),
        });

        final tripId = await _tripService.createTrip(
          userId: user.uid,
          userName: user.displayName ?? 'Anonymous',
          userPhotoUrl: user.photoURL,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          startDate: _startDate!,
          endDate: _endDate!,
          isPublic: _isPublic,
        );

        success = tripId != null;

        if (success) {
          AppLogger.success(_tag, 'Trip created successfully', {'tripId': tripId});
        }
      }

      if (!mounted) return;

      if (success) {
        await HapticHelper.success();

        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditMode ? 'Trip updated successfully!' : 'Trip created successfully!'),
            backgroundColor: AppColors.success,
          ),
        );

        // ignore: use_build_context_synchronously
        Navigator.pop(context, true); // Return true to indicate success
      } else {
        await HapticHelper.error();

        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditMode ? 'Failed to update trip' : 'Failed to create trip'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Error saving trip', e, stackTrace);
      await HapticHelper.error();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred while saving trip'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildDateSelector({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 20, color: AppColors.black),
                const SizedBox(width: 12),
                Text(
                  date != null
                      ? DateFormat('EEE, dd MMM yyyy').format(date)
                      : 'Select date',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: date != null ? AppColors.black : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final duration = _getDurationInDays();

    return Scaffold(
      backgroundColor: AppColors.grey50,
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
          isEditMode ? 'Edit Trip' : 'Create Trip',
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
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title
            Text(
              'Trip Title',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              maxLength: 100,
              decoration: InputDecoration(
                hintText: 'e.g., Summer Beach Getaway',
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
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a trip title';
                }
                if (value.trim().length < 3) {
                  return 'Title must be at least 3 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Description
            Text(
              'Description',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              maxLength: 500,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Describe your trip plans...',
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

            // Start Date
            _buildDateSelector(
              label: 'Start Date',
              date: _startDate,
              onTap: _selectStartDate,
            ),
            const SizedBox(height: 16),

            // End Date
            _buildDateSelector(
              label: 'End Date',
              date: _endDate,
              onTap: _selectEndDate,
            ),
            const SizedBox(height: 8),

            // Duration indicator
            if (duration > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '$duration ${duration == 1 ? 'day' : 'days'}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(height: 24),

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
                          _isPublic ? 'Public Trip' : 'Private Trip',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isPublic
                              ? 'Other travelers can discover and join'
                              : 'Only invited members can join',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isPublic,
                    onChanged: (value) {
                      HapticHelper.selectionClick();
                      setState(() => _isPublic = value);
                    },
                    activeTrackColor: AppColors.black,
                    activeThumbColor: AppColors.white,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Save button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveTrip,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.black,
                  foregroundColor: AppColors.white,
                  disabledBackgroundColor: AppColors.grey300,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                        ),
                      )
                    : Text(
                        isEditMode ? 'Update Trip' : 'Create Trip',
                        style: const TextStyle(
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

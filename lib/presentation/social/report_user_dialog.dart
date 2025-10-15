import 'package:flutter/material.dart';
import '../../services/user_safety_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/haptic_helper.dart';
import '../../core/utils/logger.dart';

/// Dialog for reporting users
class ReportUserDialog extends StatefulWidget {
  final String reportedUserId;
  final String reporterId;

  const ReportUserDialog({
    super.key,
    required this.reportedUserId,
    required this.reporterId,
  });

  @override
  State<ReportUserDialog> createState() => _ReportUserDialogState();
}

class _ReportUserDialogState extends State<ReportUserDialog> {
  static const String _tag = 'ReportUserDialog';

  final TextEditingController _detailsController = TextEditingController();

  String? _selectedReason;
  bool _isSubmitting = false;

  final List<String> _reasons = [
    'Spam or misleading',
    'Inappropriate content',
    'Harassment or hate speech',
    'Fake account',
    'Safety concern',
    'Other',
  ];

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (_selectedReason == null) {
      await HapticHelper.error();
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a reason'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    await HapticHelper.buttonTap();

    try {
      await UserSafetyService.reportUser(
        reportedUserId: widget.reportedUserId,
        reason: _selectedReason!,
        description: _detailsController.text.trim().isNotEmpty
            ? _detailsController.text.trim()
            : null,
      );

      if (!mounted) return;

      setState(() => _isSubmitting = false);
      await HapticHelper.success();
      AppLogger.success(_tag, 'Report submitted');

      // ignore: use_build_context_synchronously
      Navigator.pop(context, true);
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report submitted successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      setState(() => _isSubmitting = false);
      await HapticHelper.error();
      AppLogger.error(_tag, 'Failed to submit report', e);

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit report: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Report User'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Please select a reason for reporting this user:',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),

            // Reason options
            ..._reasons.map((reason) {
              return RadioListTile<String>(
                title: Text(reason, style: AppTextStyles.bodyMedium),
                value: reason,
                // ignore: deprecated_member_use
                groupValue: _selectedReason,
                // ignore: deprecated_member_use
                onChanged: (value) {
                  HapticHelper.selectionClick();
                  setState(() => _selectedReason = value);
                },
                contentPadding: EdgeInsets.zero,
                dense: true,
              );
            }),

            const SizedBox(height: 16),

            // Additional details
            Text(
              'Additional details (optional):',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _detailsController,
              maxLines: 3,
              maxLength: 200,
              decoration: InputDecoration(
                hintText: 'Provide more information...',
                hintStyle: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
                filled: true,
                fillColor: AppColors.grey50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.black, width: 2),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting
              ? null
              : () {
                  HapticHelper.lightImpact();
                  Navigator.pop(context);
                },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitReport,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.grey300,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Submit Report'),
        ),
      ],
    );
  }
}

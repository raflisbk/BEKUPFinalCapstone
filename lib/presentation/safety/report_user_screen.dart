import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/logger.dart';
import '../../core/providers/auth_provider.dart';
import '../../services/user_safety_service.dart';

class ReportUserScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const ReportUserScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<ReportUserScreen> createState() => _ReportUserScreenState();
}

class _ReportUserScreenState extends State<ReportUserScreen> {
  static const String _tag = 'ReportUserScreen';

  final TextEditingController _detailsController = TextEditingController();
  
  String _selectedReason = '';
  bool _isSubmitting = false;

  final List<String> _reportReasons = [
    'Inappropriate Content',
    'Harassment or Bullying',
    'Spam or Scam',
    'Fake Profile',
    'Hate Speech',
    'Other',
  ];

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_selectedReason.isEmpty) {
      AppLogger.warning(_tag, 'No reason selected');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a reason')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUserId = authProvider.user?.uid;
      
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      AppLogger.debug(_tag, 'Submitting report', {
        'reportedUser': widget.userName,
        'reason': _selectedReason,
      });

      await UserSafetyService.reportUser(
        reportedUserId: widget.userId,
        reason: _selectedReason,
        description: _detailsController.text.trim().isNotEmpty 
            ? _detailsController.text.trim() 
            : null,
      );

      if (!mounted) return;

      AppLogger.success(_tag, 'Report submitted successfully');
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report submitted successfully')),
      );
    } catch (e) {
      AppLogger.error(_tag, 'Error submitting report: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit report: ${e.toString()}'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _handleBlock() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUserId = authProvider.user?.uid;
      
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      AppLogger.debug(_tag, 'Blocking user', {
        'blockedUser': widget.userName,
      });

      await UserSafetyService.blockUser(widget.userId);

      if (!mounted) return;

      AppLogger.success(_tag, 'User blocked successfully');
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User blocked successfully')),
      );
    } catch (e) {
      AppLogger.error(_tag, 'Error blocking user: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to block user: ${e.toString()}'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.black,
        title: const Text('Report User'),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: AppColors.divider,
            height: 1,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Report ${widget.userName}',
                style: AppTextStyles.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Please select a reason for reporting this user.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // Report reasons
              ...List.generate(_reportReasons.length, (index) {
                final reason = _reportReasons[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: RadioListTile(
                    value: reason,
                    // ignore: deprecated_member_use
                    groupValue: _selectedReason,
                    // ignore: deprecated_member_use
                    onChanged: (value) {
                      setState(() => _selectedReason = value.toString());
                    },
                    title: Text(reason),
                    activeColor: AppColors.primary,
                  ),
                );
              }),

              const SizedBox(height: 24),

              // Additional details
              TextField(
                controller: _detailsController,
                maxLines: 4,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: 'Additional Details (Optional)',
                  hintText: 'Please provide any additional details about your report...',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 32),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleSubmit,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Submit Report'),
                ),
              ),

              const SizedBox(height: 16),

              // Block user button
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _handleBlock,
                  child: const Text('Block User'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
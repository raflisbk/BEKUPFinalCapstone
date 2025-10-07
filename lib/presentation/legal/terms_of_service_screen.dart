import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/haptic_helper.dart';

/// Terms of Service screen
class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            HapticHelper.lightImpact();
            Navigator.pop(context);
          },
        ),
        title: const Text('Terms of Service'),
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
            Text(
              'Terms of Service',
              style: AppTextStyles.headlineMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Last updated: October 7, 2025',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),

            _buildSection(
              title: '1. Acceptance of Terms',
              content: 'By accessing and using ReLink ("the App"), you accept and agree to be bound by the terms and provision of this agreement. If you do not agree to these Terms of Service, please do not use the App.',
            ),

            _buildSection(
              title: '2. Description of Service',
              content: 'ReLink is a mobile application that connects travelers with local guides and fellow travelers. The App provides features including but not limited to: user profiles, trip planning, destination reviews, photo sharing, real-time chat, and social networking.',
            ),

            _buildSection(
              title: '3. User Accounts',
              content: 'You are responsible for maintaining the confidentiality of your account and password. You agree to accept responsibility for all activities that occur under your account. You must notify us immediately of any unauthorized use of your account.',
            ),

            _buildSection(
              title: '4. User Content',
              content: 'You retain all rights to any content you submit, post, or display on or through the App. By submitting content, you grant ReLink a worldwide, non-exclusive, royalty-free license to use, copy, reproduce, process, adapt, modify, publish, transmit, display and distribute such content.',
            ),

            _buildSection(
              title: '5. Prohibited Activities',
              content: 'You agree not to:\n• Violate any laws or regulations\n• Post offensive, harmful, or inappropriate content\n• Harass, abuse, or harm other users\n• Impersonate another person or entity\n• Interfere with the App\'s operation\n• Collect user information without consent\n• Use the App for commercial purposes without authorization',
            ),

            _buildSection(
              title: '6. Content Moderation',
              content: 'We reserve the right to remove any content that violates these Terms or is otherwise objectionable. We may suspend or terminate accounts that repeatedly violate these Terms.',
            ),

            _buildSection(
              title: '7. Privacy',
              content: 'Your use of the App is also governed by our Privacy Policy. Please review our Privacy Policy to understand how we collect, use, and protect your personal information.',
            ),

            _buildSection(
              title: '8. Intellectual Property',
              content: 'The App and its original content, features, and functionality are owned by ReLink and are protected by international copyright, trademark, patent, trade secret, and other intellectual property laws.',
            ),

            _buildSection(
              title: '9. Disclaimer of Warranties',
              content: 'The App is provided "as is" and "as available" without warranties of any kind, either express or implied. We do not warrant that the App will be uninterrupted, secure, or error-free.',
            ),

            _buildSection(
              title: '10. Limitation of Liability',
              content: 'To the maximum extent permitted by law, ReLink shall not be liable for any indirect, incidental, special, consequential, or punitive damages resulting from your use of the App.',
            ),

            _buildSection(
              title: '11. Indemnification',
              content: 'You agree to indemnify and hold harmless ReLink and its officers, directors, employees, and agents from any claims, damages, losses, liabilities, and expenses arising from your use of the App or violation of these Terms.',
            ),

            _buildSection(
              title: '12. Changes to Terms',
              content: 'We reserve the right to modify these Terms at any time. We will notify users of any material changes. Your continued use of the App after changes constitutes acceptance of the modified Terms.',
            ),

            _buildSection(
              title: '13. Termination',
              content: 'We may terminate or suspend your account and access to the App immediately, without prior notice, for conduct that we believe violates these Terms or is harmful to other users, us, or third parties.',
            ),

            _buildSection(
              title: '14. Governing Law',
              content: 'These Terms shall be governed by and construed in accordance with the laws of Indonesia, without regard to its conflict of law provisions.',
            ),

            _buildSection(
              title: '15. Contact Us',
              content: 'If you have any questions about these Terms of Service, please contact us through the App or via email.',
            ),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'By using ReLink, you acknowledge that you have read, understood, and agree to be bound by these Terms of Service.',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

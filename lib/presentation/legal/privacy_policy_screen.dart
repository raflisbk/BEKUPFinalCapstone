import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/haptic_helper.dart';

/// Privacy Policy screen
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
        title: const Text('Privacy Policy'),
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
              'Privacy Policy',
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
              title: '1. Information We Collect',
              content: 'We collect information you provide directly to us, including:\n\n• Account Information: Name, email address, password, profile photo\n• Profile Data: Bio, location, travel preferences\n• User Content: Photos, reviews, comments, trip plans, messages\n• Usage Data: How you interact with the App, features used, pages visited\n• Location Data: Your geographic location (with your permission)\n• Device Information: Device type, operating system, unique device identifiers',
            ),

            _buildSection(
              title: '2. How We Use Your Information',
              content: 'We use the information we collect to:\n\n• Provide, maintain, and improve our services\n• Create and manage your account\n• Enable you to connect with other users\n• Send you notifications and updates\n• Respond to your requests and provide customer support\n• Monitor and analyze trends and usage\n• Detect, prevent, and address security issues\n• Comply with legal obligations',
            ),

            _buildSection(
              title: '3. Information Sharing',
              content: 'We may share your information in the following circumstances:\n\n• With Other Users: Your profile information and content you share publicly\n• With Service Providers: Third-party vendors who assist in operating the App\n• For Legal Reasons: To comply with laws, regulations, or legal requests\n• Business Transfers: In connection with a merger, acquisition, or sale\n• With Your Consent: When you authorize us to share your information',
            ),

            _buildSection(
              title: '4. Your Choices and Controls',
              content: 'You have control over your information:\n\n• Account Settings: Update your profile and preferences\n• Location Sharing: Enable or disable location tracking\n• Privacy Settings: Control who can see your content\n• Data Access: Request a copy of your data\n• Account Deletion: Delete your account and associated data\n• Communication Preferences: Opt out of promotional communications',
            ),

            _buildSection(
              title: '5. Data Security',
              content: 'We implement security measures to protect your information, including:\n\n• Encryption of data in transit and at rest\n• Secure authentication methods\n• Regular security audits\n• Access controls and monitoring\n• Incident response procedures\n\nHowever, no method of transmission over the internet is 100% secure.',
            ),

            _buildSection(
              title: '6. Data Retention',
              content: 'We retain your information for as long as necessary to:\n\n• Provide you with our services\n• Comply with legal obligations\n• Resolve disputes and enforce our agreements\n• Improve and develop our services\n\nYou can request deletion of your data at any time by deleting your account.',
            ),

            _buildSection(
              title: '7. Children\'s Privacy',
              content: 'ReLink is not intended for users under the age of 13. We do not knowingly collect personal information from children under 13. If we become aware that a child under 13 has provided us with personal information, we will take steps to delete such information.',
            ),

            _buildSection(
              title: '8. International Data Transfers',
              content: 'Your information may be transferred to and maintained on servers located outside of your country. By using the App, you consent to the transfer of your information to countries that may have different data protection laws.',
            ),

            _buildSection(
              title: '9. Third-Party Services',
              content: 'The App may contain links to third-party websites or services. We are not responsible for the privacy practices of these third parties. We encourage you to review their privacy policies.',
            ),

            _buildSection(
              title: '10. Firebase Services',
              content: 'We use Firebase services provided by Google, including:\n\n• Firebase Authentication: For secure user authentication\n• Cloud Firestore: For data storage\n• Firebase Storage: For file storage\n• Firebase Cloud Messaging: For push notifications\n\nPlease review Google\'s Privacy Policy for information about how Firebase handles your data.',
            ),

            _buildSection(
              title: '11. Google Maps',
              content: 'We use Google Maps API to provide location-based services. Your use of Google Maps features is subject to Google\'s Terms of Service and Privacy Policy.',
            ),

            _buildSection(
              title: '12. Cookies and Tracking',
              content: 'We use cookies and similar tracking technologies to:\n\n• Remember your preferences\n• Understand how you use the App\n• Improve your experience\n• Analyze App performance\n\nYou can control cookies through your device settings.',
            ),

            _buildSection(
              title: '13. Changes to This Privacy Policy',
              content: 'We may update this Privacy Policy from time to time. We will notify you of any material changes by posting the new Privacy Policy in the App and updating the "Last updated" date.',
            ),

            _buildSection(
              title: '14. Your Rights',
              content: 'Depending on your location, you may have certain rights regarding your personal information, including:\n\n• Right to access your data\n• Right to correct inaccurate data\n• Right to delete your data\n• Right to data portability\n• Right to restrict processing\n• Right to object to processing\n• Right to withdraw consent',
            ),

            _buildSection(
              title: '15. Contact Us',
              content: 'If you have any questions, concerns, or requests regarding this Privacy Policy or our data practices, please contact us through the App or via email.\n\nEmail: privacy@relink.app\nAddress: Indonesia',
            ),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'By using ReLink, you acknowledge that you have read, understood, and agree to the collection, use, and disclosure of your information as described in this Privacy Policy.',
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

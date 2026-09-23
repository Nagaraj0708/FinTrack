import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Privacy Policy for FinTrack',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Last updated: September 2026',
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              '1. Data Collection',
              'FinTrack is designed with privacy in mind. Currently, all your financial data (transactions, goals, budgets) is stored locally on your device using a local SQLite database. We do not transmit your financial data to external servers without your explicit consent.',
            ),
            _buildSection(
              context,
              '2. Biometrics & Authentication',
              'If you enable Biometric Authentication (Face ID / Touch ID) or a PIN lock, these are handled entirely by your device\'s local secure enclave. FinTrack does not store or have access to your raw biometric data.',
            ),
            _buildSection(
              context,
              '3. Third-Party Services',
              'We may use third-party services (such as Supabase) for cloud syncing features if you choose to enable them in the future. These services have their own privacy policies and conform to industry-standard data protection regulations.',
            ),
            _buildSection(
              context,
              '4. Data Export and Deletion',
              'You have full control over your data. You can export your data to a CSV file or completely erase all data from the app at any time via the Profile settings page.',
            ),
            _buildSection(
              context,
              '5. Contact Us',
              'If you have any questions about this Privacy Policy, please contact us at privacy@fintrack.example.com.',
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/colors.dart';
import '../../../../core/providers/settings_provider.dart';
import 'pin_lock_screen.dart';
import 'two_factor_auth_page.dart';
import 'privacy_policy_page.dart';

class SecurityPrivacyPage extends ConsumerStatefulWidget {
  const SecurityPrivacyPage({super.key});

  @override
  ConsumerState<SecurityPrivacyPage> createState() =>
      _SecurityPrivacyPageState();
}

class _SecurityPrivacyPageState extends ConsumerState<SecurityPrivacyPage> {
  void _handleAppLockTap() {
    final settings = ref.read(settingsProvider);
    final hasPin = settings.appPin != null && settings.appPin!.isNotEmpty;

    if (hasPin) {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.password_rounded),
                title: const Text('Change App PIN'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToPinLock(PinLockMode.setup);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_rounded,
                  color: AppColors.error,
                ),
                title: const Text(
                  'Remove App PIN',
                  style: TextStyle(color: AppColors.error),
                ),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(settingsProvider.notifier).updateAppPin(null);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('App PIN removed')),
                  );
                },
              ),
            ],
          ),
        ),
      );
    } else {
      _navigateToPinLock(PinLockMode.setup);
    }
  }

  void _navigateToPinLock(PinLockMode mode) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PinLockScreen(
          mode: mode,
          onSuccess: () {
            Navigator.pop(context);
            if (mode == PinLockMode.setup) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('App PIN set successfully')),
              );
            }
          },
          onCancel: () => Navigator.pop(context),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final hasPin = settings.appPin != null && settings.appPin!.isNotEmpty;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Security & Privacy'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildSecurityOption(
            title: 'App Lock (PIN)',
            subtitle: hasPin ? 'PIN is set' : 'Set a PIN to lock the app',
            icon: Icons.password_rounded,
            onTap: _handleAppLockTap,
          ),
          const SizedBox(height: 16),
          _buildSecurityOption(
            title: 'Biometric Authentication',
            subtitle: 'Use Face ID or Fingerprint to unlock',
            icon: Icons.fingerprint_rounded,
            trailing: Switch(
              value: settings.isBiometricEnabled,
              onChanged: (val) {
                if (val && !hasPin) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Please set an App PIN first to enable Biometrics.',
                      ),
                    ),
                  );
                  return;
                }
                ref.read(settingsProvider.notifier).toggleBiometric(val);
              },
              activeThumbColor: Colors.white,
              activeTrackColor: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          _buildSecurityOption(
            title: 'Two-Factor Authentication',
            subtitle: settings.isTwoFactorEnabled
                ? 'Enabled'
                : 'Add an extra layer of security',
            icon: Icons.security_rounded,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TwoFactorAuthPage()),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildSecurityOption(
            title: 'Privacy Policy',
            subtitle: 'Read our data handling practices',
            icon: Icons.privacy_tip_rounded,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityOption({
    required String title,
    required String subtitle,
    required IconData icon,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        trailing:
            trailing ??
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
            ),
        onTap: onTap,
      ),
    );
  }
}

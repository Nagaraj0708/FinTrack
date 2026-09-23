import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/colors.dart';
import '../../../../core/providers/settings_provider.dart';

class TwoFactorAuthPage extends ConsumerStatefulWidget {
  const TwoFactorAuthPage({super.key});

  @override
  ConsumerState<TwoFactorAuthPage> createState() => _TwoFactorAuthPageState();
}

class _TwoFactorAuthPageState extends ConsumerState<TwoFactorAuthPage> {
  bool _isLoading = false;

  void _simulateSetup() async {
    setState(() => _isLoading = true);

    // Simulate API call to setup 2FA
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      ref.read(settingsProvider.notifier).toggleTwoFactor(true);
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Two-Factor Authentication successfully enabled.'),
        ),
      );
      Navigator.pop(context);
    }
  }

  void _simulateDisable() async {
    setState(() => _isLoading = true);

    // Simulate API call to disable 2FA
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      ref.read(settingsProvider.notifier).toggleTwoFactor(false);
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Two-Factor Authentication disabled.')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = ref.watch(settingsProvider).isTwoFactorEnabled;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Two-Factor Authentication'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isEnabled
                      ? Icons.verified_user_rounded
                      : Icons.security_rounded,
                  size: 64,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                isEnabled ? '2FA is Enabled' : 'Secure Your Account',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isEnabled
                    ? 'Your account is currently protected with an extra layer of security. You will need to provide a code from your authenticator app when logging in.'
                    : 'Two-factor authentication adds an extra layer of security to your account. In addition to your password, you\'ll need to provide a code to log in.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const Spacer(),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: isEnabled
                          ? AppColors.error
                          : AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: isEnabled ? _simulateDisable : _simulateSetup,
                    child: Text(
                      isEnabled ? 'Disable 2FA' : 'Set Up 2FA',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

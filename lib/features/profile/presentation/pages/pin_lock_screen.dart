import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import '../../../../app/theme/colors.dart';
import '../../../../core/providers/settings_provider.dart';

enum PinLockMode { setup, verify }

class PinLockScreen extends ConsumerStatefulWidget {
  final PinLockMode mode;
  final VoidCallback onSuccess;
  final VoidCallback? onCancel;

  const PinLockScreen({
    super.key,
    required this.mode,
    required this.onSuccess,
    this.onCancel,
  });

  @override
  ConsumerState<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends ConsumerState<PinLockScreen> {
  String _pin = '';
  String? _confirmPin;
  String _message = '';
  bool _isError = false;
  final LocalAuthentication auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _message = widget.mode == PinLockMode.setup
        ? 'Enter new App PIN'
        : 'Enter App PIN to unlock';

    if (widget.mode == PinLockMode.verify) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _attemptBiometric();
      });
    }
  }

  Future<void> _attemptBiometric() async {
    final settings = ref.read(settingsProvider);
    if (!settings.isBiometricEnabled) return;

    try {
      final isAvailable =
          await auth.canCheckBiometrics || await auth.isDeviceSupported();
      if (!isAvailable) return;

      final didAuthenticate = await auth.authenticate(
        localizedReason: 'Scan your fingerprint or use device unlock to access FinTrack',
      );

      if (didAuthenticate && mounted) {
        widget.onSuccess();
      }
    } catch (e) {
      // Fallback to PIN on error - do nothing, PIN pad is already visible
    }
  }

  void _onKeyPress(String key) {
    if (_pin.length < 4) {
      setState(() {
        _pin += key;
        _isError = false;
      });

      if (_pin.length == 4) {
        Future.delayed(const Duration(milliseconds: 500), _processPin);
      }
    }
  }

  void _onDelete() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
        _isError = false;
      });
    }
  }

  void _processPin() {
    if (widget.mode == PinLockMode.setup) {
      if (_confirmPin == null) {
        setState(() {
          _confirmPin = _pin;
          _pin = '';
          _message = 'Confirm your App PIN';
        });
      } else {
        if (_pin == _confirmPin) {
          ref.read(settingsProvider.notifier).updateAppPin(_pin);
          widget.onSuccess();
        } else {
          setState(() {
            _pin = '';
            _confirmPin = null;
            _message = 'PINs do not match. Try again.';
            _isError = true;
          });
        }
      }
    } else {
      final settings = ref.read(settingsProvider);
      if (_pin == settings.appPin) {
        widget.onSuccess();
      } else {
        setState(() {
          _pin = '';
          _message = 'Incorrect PIN';
          _isError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark, // Match brand dark background
      body: SafeArea(
        child: Column(
          children: [
            if (widget.onCancel != null)
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textPrimaryDark),
                  onPressed: widget.onCancel,
                ),
              ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Premium Lock Icon
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.3), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryLight.withValues(alpha: 0.1),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ],
                      gradient: RadialGradient(
                        colors: [
                          AppColors.primaryLight.withValues(alpha: 0.2),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: const Icon(
                      Icons.lock_outline_rounded,
                      size: 32,
                      color: AppColors.primaryLight,
                    ),
                  ),
                  const SizedBox(height: 24),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      _message.toUpperCase(),
                      key: ValueKey(_message),
                      style: TextStyle(
                        fontSize: 14,
                        letterSpacing: 2.0,
                        fontWeight: FontWeight.w600,
                        color: _isError ? AppColors.error : AppColors.textPrimaryDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) {
                      final isEntered = index < _pin.length;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        width: 52,
                        height: 64,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isEntered
                                ? AppColors.primaryLight
                                : AppColors.primaryLight.withValues(alpha: 0.15),
                            width: 1.5,
                          ),
                          color: isEntered
                              ? AppColors.primaryLight.withValues(alpha: 0.1)
                              : AppColors.surfaceDark.withValues(alpha: 0.6),
                          boxShadow: isEntered
                              ? [
                                  BoxShadow(
                                    color: AppColors.primaryLight.withValues(alpha: 0.2),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  )
                                ]
                              : [],
                        ),
                        child: Text(
                          isEntered 
                            ? (widget.mode == PinLockMode.setup ? _pin[index] : '•') 
                            : '',
                          style: TextStyle(
                            fontSize: widget.mode == PinLockMode.setup ? 24 : 32,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimaryDark,
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            _buildNumberPad(),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberPad() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['1', '2', '3'].map((k) => _buildKey(k)).toList(),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['4', '5', '6'].map((k) => _buildKey(k)).toList(),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['7', '8', '9'].map((k) => _buildKey(k)).toList(),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              widget.mode == PinLockMode.verify &&
                      ref.watch(settingsProvider).isBiometricEnabled
                  ? _buildBiometricKey()
                  : const SizedBox(width: 72),
              _buildKey('0'),
              _buildActionKey(Icons.backspace_rounded, _onDelete),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildKey(String text) {
    return GestureDetector(
      onTap: () => _onKeyPress(text),
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surfaceDark,
          border: Border.all(
            color: AppColors.primaryLight.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w400,
            color: AppColors.textPrimaryDark,
          ),
        ),
      ),
    );
  }

  Widget _buildActionKey(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        alignment: Alignment.center,
        child: Icon(icon, size: 26, color: AppColors.textSecondaryDark),
      ),
    );
  }

  Widget _buildBiometricKey() {
    return GestureDetector(
      onTap: _attemptBiometric,
      child: Container(
        width: 72,
        height: 72,
        alignment: Alignment.center,
        child: const Icon(
          Icons.fingerprint_rounded,
          size: 32,
          color: AppColors.primaryLight,
        ),
      ),
    );
  }
}

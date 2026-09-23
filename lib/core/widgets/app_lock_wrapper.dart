import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import '../../features/profile/presentation/pages/pin_lock_screen.dart';

class AppLockWrapper extends ConsumerStatefulWidget {
  final Widget child;
  const AppLockWrapper({super.key, required this.child});

  @override
  ConsumerState<AppLockWrapper> createState() => _AppLockWrapperState();
}

class _AppLockWrapperState extends ConsumerState<AppLockWrapper>
    with WidgetsBindingObserver {
  bool _isLocked = false;
  DateTime? _backgroundedAt;

  // Lock after 30 seconds in background
  static const _lockTimeout = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkLockStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _backgroundedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final bg = _backgroundedAt;
      if (bg != null) {
        final elapsed = DateTime.now().difference(bg);
        if (elapsed >= _lockTimeout) {
          _checkLockStatus();
        }
      }
      _backgroundedAt = null;
    }
  }

  void _checkLockStatus() {
    final settings = ref.read(settingsProvider);
    if (settings.appPin != null && settings.appPin!.isNotEmpty) {
      setState(() => _isLocked = true);
    }
  }

  void _unlock() {
    setState(() => _isLocked = false);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          widget.child,
          if (_isLocked)
            Positioned.fill(
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                themeMode: ThemeMode.dark,
                home: PinLockScreen(mode: PinLockMode.verify, onSuccess: _unlock),
              ),
            ),
        ],
      ),
    );
  }
}

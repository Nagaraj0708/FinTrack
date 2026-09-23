import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/colors.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../core/widgets/organic_clippers.dart';

class OnboardingSuccessPage extends ConsumerWidget {
  const OnboardingSuccessPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background organic shape (bottom left)
          Positioned(
            bottom: 0,
            left: 0,
            child: ClipPath(
              clipper: BottomLeftOrganicClipper(),
              child: Container(
                width: size.width * 0.7,
                height: size.height * 0.35,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                    colors: [
                      const Color(0xFFD8EBE2), // light mint
                      const Color(0xFFD8EBE2).withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(),
                  
                  // Success Illustration
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Sparkles
                      Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.transparent),
                        ),
                        child: Stack(
                          children: [
                            Positioned(top: 10, left: 70, child: _buildSparkle()),
                            Positioned(top: 40, right: 20, child: _buildSparkle(rotation: 0.8)),
                            Positioned(bottom: 50, right: 10, child: _buildSparkle(rotation: 1.5)),
                            Positioned(bottom: 20, left: 40, child: _buildSparkle(rotation: 2.2)),
                            Positioned(top: 60, left: 10, child: _buildSparkle(rotation: -0.5)),
                          ],
                        ),
                      ),
                      // Checkmark circle
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A382D),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1A382D).withValues(alpha: 0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.check_rounded, color: Colors.white, size: 48),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),

                  const Text(
                    'All Set!',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1A382D),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'You\'re ready to take control\nof your finances.',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const Spacer(),

                  // Go to Dashboard Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () async {
                        await ref.read(settingsProvider.notifier).setLoggedIn(true);
                        if (context.mounted) {
                          context.go('/dashboard');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A382D),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Go to Dashboard', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSparkle({double rotation = 0}) {
    return Transform.rotate(
      angle: rotation,
      child: Container(
        width: 6,
        height: 12,
        decoration: BoxDecoration(
          color: const Color(0xFF86998F),
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}

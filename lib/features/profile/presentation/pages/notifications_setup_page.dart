import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/colors.dart';
import '../../../../core/widgets/organic_clippers.dart';

class NotificationsSetupPage extends StatelessWidget {
  const NotificationsSetupPage({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    final size = MediaQuery.of(context).size;

    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.go('/profile-setup');
      },
      child: Scaffold(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                // Header (Back and Skip)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFF0F4F0), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1A382D), size: 22),
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go('/onboarding-success'),
                        child: const Text(
                          'Skip',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF7B827E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Stay on track',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1A382D),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Enable notifications to get timely\nupdates and reminders.',
                          style: TextStyle(
                            fontSize: 15,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 48),

                        // Notification Illustration
                        Center(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Phone frame placeholder
                              Container(
                                width: 140,
                                height: 160,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8ECEA),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(color: const Color(0xFF86998F), width: 4),
                                ),
                                child: Column(
                                  children: [
                                    const SizedBox(height: 8),
                                    Container(
                                      width: 40,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF86998F),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.1),
                                            blurRadius: 10,
                                          )
                                        ],
                                      ),
                                      child: const Icon(Icons.notifications_active_rounded, color: Color(0xFF1A382D), size: 28),
                                    ),
                                    const Spacer(),
                                  ],
                                ),
                              ),
                              // Floating Notification Card
                              Positioned(
                                bottom: -20,
                                child: Container(
                                  width: 220,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.08),
                                        blurRadius: 15,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFE8F3EF),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.bolt_rounded, color: Color(0xFF1A382D), size: 18),
                                      ),
                                      const SizedBox(width: 12),
                                      const Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Bill reminder',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF1A382D),
                                              ),
                                            ),
                                            SizedBox(height: 2),
                                            Text(
                                              'Your electricity bill\nis due in 3 days',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF7B827E),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 70), // Spacing for the overlapping card

                        // Features list
                        _buildFeatureRow(Icons.notifications_none_rounded, 'Bill reminders'),
                        const SizedBox(height: 16),
                        _buildFeatureRow(Icons.check_circle_outline_rounded, 'Goal updates'),
                        const SizedBox(height: 16),
                        _buildFeatureRow(Icons.notifications_active_rounded, 'Spending alerts'),
                        
                        const SizedBox(height: 48),

                        // Enable Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () => context.go('/onboarding-success'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A382D),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                              elevation: 0,
                            ),
                            child: const Text('Enable Notifications', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Maybe Later
                        Center(
                          child: TextButton(
                            onPressed: () => context.go('/onboarding-success'),
                            child: const Text(
                              'Maybe later',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A382D),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ));
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF1A382D), size: 24),
        const SizedBox(width: 16),
        Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A382D),
          ),
        ),
      ],
    );
  }
}

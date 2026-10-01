import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/colors.dart';
import '../../core/providers/settings_provider.dart';
import '../../features/authentication/presentation/pages/login_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/analytics/presentation/pages/analytics_page.dart';
import '../../features/goals/presentation/pages/goals_page.dart';
// import '../../features/payments/presentation/pages/pay_dashboard_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/transactions/presentation/pages/transactions_page.dart';
import '../../features/authentication/presentation/pages/otp_verification_page.dart';
import '../../features/profile/presentation/pages/profile_setup_page.dart';
import '../../features/profile/presentation/pages/notifications_setup_page.dart';
import '../../features/profile/presentation/pages/onboarding_success_page.dart';
import '../../features/authentication/presentation/pages/forgot_password_page.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>();

CustomTransitionPage _buildPageWithTransition(
  Widget child,
  GoRouterState state,
) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 280),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
        child: SlideTransition(
          position:
              Tween<Offset>(
                begin: const Offset(0.04, 0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
          child: child,
        ),
      );
    },
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  final settings = ref.read(settingsProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: settings.isLoggedIn ? '/dashboard' : '/login',
    redirect: (context, state) {
      final isLoggedIn = ref.read(settingsProvider).isLoggedIn;

      final publicRoutes = [
        '/login',
        '/forgot-password',
        '/otp-verification',
        '/profile-setup',
        '/notifications-setup',
        '/onboarding-success',
      ];

      final isPublicRoute = publicRoutes.contains(state.matchedLocation);

      if (!isLoggedIn && !isPublicRoute) return '/login';
      if (isLoggedIn && state.matchedLocation == '/login') return '/dashboard';
      return null;
    },
    routes: [
      // ── Login route (outside shell) ──────────────────────────────────
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) =>
            _buildPageWithTransition(const LoginPage(), state),
      ),
      GoRoute(
        path: '/forgot-password',
        pageBuilder: (context, state) =>
            _buildPageWithTransition(const ForgotPasswordPage(), state),
      ),
      GoRoute(
        path: '/otp-verification',
        pageBuilder: (context, state) {
          final mode = state.uri.queryParameters['mode'];
          return _buildPageWithTransition(
            OtpVerificationPage(mode: mode),
            state,
          );
        },
      ),
      GoRoute(
        path: '/profile-setup',
        pageBuilder: (context, state) =>
            _buildPageWithTransition(const ProfileSetupPage(), state),
      ),
      GoRoute(
        path: '/notifications-setup',
        pageBuilder: (context, state) =>
            _buildPageWithTransition(const NotificationsSetupPage(), state),
      ),
      GoRoute(
        path: '/onboarding-success',
        pageBuilder: (context, state) =>
            _buildPageWithTransition(const OnboardingSuccessPage(), state),
      ),
      // ── App shell with bottom nav ─────────────────────────────────────
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return _ScaffoldWithBottomNavBar(child: child);
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            pageBuilder: (context, state) =>
                _buildPageWithTransition(const DashboardPage(), state),
          ),
          // GoRoute(
          //   path: '/pay',
          //   pageBuilder: (context, state) =>
          //       _buildPageWithTransition(const PayDashboardPage(), state),
          // ),
          GoRoute(
            path: '/transactions',
            pageBuilder: (context, state) =>
                _buildPageWithTransition(const TransactionsPage(), state),
          ),
          GoRoute(
            path: '/analytics',
            pageBuilder: (context, state) =>
                _buildPageWithTransition(const AnalyticsPage(), state),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) =>
                _buildPageWithTransition(const ProfilePage(), state),
          ),
        ],
      ),
      GoRoute(
        path: '/goals',
        pageBuilder: (context, state) =>
            _buildPageWithTransition(const GoalsPage(), state),
      ),
    ],
  );
});

// Keep a simple global instance for backward compatibility (no redirect)
final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/dashboard',
  routes: [
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) =>
          _buildPageWithTransition(const LoginPage(), state),
    ),
    GoRoute(
      path: '/forgot-password',
      pageBuilder: (context, state) =>
          _buildPageWithTransition(const ForgotPasswordPage(), state),
    ),
    GoRoute(
      path: '/otp-verification',
      pageBuilder: (context, state) =>
          _buildPageWithTransition(const OtpVerificationPage(), state),
    ),
    GoRoute(
      path: '/profile-setup',
      pageBuilder: (context, state) =>
          _buildPageWithTransition(const ProfileSetupPage(), state),
    ),
    GoRoute(
      path: '/notifications-setup',
      pageBuilder: (context, state) =>
          _buildPageWithTransition(const NotificationsSetupPage(), state),
    ),
    GoRoute(
      path: '/onboarding-success',
      pageBuilder: (context, state) =>
          _buildPageWithTransition(const OnboardingSuccessPage(), state),
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return _ScaffoldWithBottomNavBar(child: child);
      },
      routes: [
        GoRoute(
          path: '/dashboard',
          pageBuilder: (context, state) =>
              _buildPageWithTransition(const DashboardPage(), state),
        ),
        // GoRoute(
        //   path: '/pay',
        //   pageBuilder: (context, state) =>
        //       _buildPageWithTransition(const PayDashboardPage(), state),
        // ),
        GoRoute(
          path: '/transactions',
          pageBuilder: (context, state) =>
              _buildPageWithTransition(const TransactionsPage(), state),
        ),
        GoRoute(
          path: '/analytics',
          pageBuilder: (context, state) =>
              _buildPageWithTransition(const AnalyticsPage(), state),
        ),
        GoRoute(
          path: '/profile',
          pageBuilder: (context, state) =>
              _buildPageWithTransition(const ProfilePage(), state),
        ),
      ],
    ),
    GoRoute(
      path: '/goals',
      pageBuilder: (context, state) =>
          _buildPageWithTransition(const GoalsPage(), state),
    ),
  ],
);

class _ScaffoldWithBottomNavBar extends StatefulWidget {
  const _ScaffoldWithBottomNavBar({required this.child});
  final Widget child;

  static const _navItems = [
    _NavItem(
      icon: Icons.home_rounded,
      activeIcon: Icons.home_rounded,
      label: 'Home',
      path: '/dashboard',
    ),
    // _NavItem(
    //   icon: Icons.account_balance_wallet_outlined,
    //   activeIcon: Icons.account_balance_wallet_rounded,
    //   label: 'Pay',
    //   path: '/pay',
    // ),
    _NavItem(
      icon: Icons.receipt_long_outlined,
      activeIcon: Icons.receipt_long_rounded,
      label: 'Transactions',
      path: '/transactions',
    ),
    _NavItem(
      icon: Icons.insights_outlined,
      activeIcon: Icons.insights_rounded,
      label: 'Analytics',
      path: '/analytics',
    ),
    _NavItem(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Profile',
      path: '/profile',
    ),
  ];

  @override
  State<_ScaffoldWithBottomNavBar> createState() =>
      _ScaffoldWithBottomNavBarState();
}

class _ScaffoldWithBottomNavBarState extends State<_ScaffoldWithBottomNavBar> {
  late PageController _pageController;
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    DashboardPage(),
    // PayDashboardPage(),
    TransactionsPage(),
    AnalyticsPage(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    int newIndex = 0;
    for (int i = 0; i < _ScaffoldWithBottomNavBar._navItems.length; i++) {
      if (location.startsWith(_ScaffoldWithBottomNavBar._navItems[i].path)) {
        newIndex = i;
        break;
      }
    }

    if (newIndex != _currentIndex) {
      _currentIndex = newIndex;
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        _pageController = PageController(initialPage: _currentIndex);
      }
    }

    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          if (index != _currentIndex) {
            _currentIndex = index;
            context.go(_ScaffoldWithBottomNavBar._navItems[index].path);
          }
        },
        children: _pages,
      ),
      bottomNavigationBar: _PremiumNavBar(
        currentIndex: _currentIndex,
        isDark: isDark,
        items: _ScaffoldWithBottomNavBar._navItems,
        onTap: (i) {
          if (i != _currentIndex) {
            context.go(_ScaffoldWithBottomNavBar._navItems[i].path);
          }
        },
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String path;
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.path,
  });
}

class _PremiumNavBar extends StatelessWidget {
  const _PremiumNavBar({
    required this.currentIndex,
    required this.isDark,
    required this.items,
    required this.onTap,
  });

  final int currentIndex;
  final bool isDark;
  final List<_NavItem> items;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.surfaceDark : AppColors.surface;
    final borderColor = isDark
        ? const Color(0xFF1E2922)
        : const Color(0xFFE8F0EC);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border(top: BorderSide(color: borderColor, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: List.generate(items.length, (i) {
              final isActive = i == currentIndex;
              final item = items[i];
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.primary.withValues(alpha: 0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Icon(
                            isActive ? item.activeIcon : item.icon,
                            size: 22,
                            color: isActive
                                ? AppColors.primary
                                : (isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondary),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isActive
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isActive
                                ? AppColors.primary
                                : (isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

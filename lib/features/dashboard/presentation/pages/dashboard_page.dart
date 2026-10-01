
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../app/theme/colors.dart';
import '../../../transactions/presentation/widgets/transaction_entry_sheet.dart';
import '../providers/dashboard_provider.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(dashboardMetricsProvider);
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: _PremiumFAB(onTap: () => TransactionEntrySheet.show(context)),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Header ────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _greetingText(),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Nagaraj',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.8,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _NotificationButton(),
                  ],
                ),
              ),
            ),
          ),

          // ── Metrics ──────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: metricsAsync.when(
              data: (metrics) {
                final netFlowStr  = currencyFormat.format(metrics.netCashFlow);
                final incomeStr   = currencyFormat.format(metrics.monthlyIncome);
                final expenseStr  = currencyFormat.format(metrics.monthlyExpenses);
                final trend = _calculateTrend(metrics.netCashFlow, metrics.prevNetCashFlow);
                final expenseRate = metrics.monthlyIncome > 0
                    ? ((metrics.monthlyExpenses / metrics.monthlyIncome) * 100)
                    : 0.0;
                final savingsRate = metrics.monthlyIncome > 0
                    ? ((metrics.netCashFlow / metrics.monthlyIncome) * 100)
                    : 0.0;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      // ── Hero Card ──────────────────────────────────────
                      _HeroCard(netFlowStr: netFlowStr, trendPercentage: trend),
                      const SizedBox(height: 16),

                      // ── Stat Row ───────────────────────────────────────
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: _StatCard(
                                label: 'Income',
                                value: incomeStr,
                                icon: Icons.arrow_downward_rounded,
                                iconColor: AppColors.success,
                                badge: metrics.monthlyIncome > 0 ? '100% total' : 'No income',
                                badgePositive: true,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                                child: _StatCard(
                                  label: 'Expenses',
                                  value: expenseStr,
                                  icon: Icons.arrow_upward_rounded,
                                  iconColor: AppColors.error,
                                  badge: '${expenseRate.toStringAsFixed(0)}% spent',
                                  badgePositive: expenseRate <= 50,
                                ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _StatCard(
                                label: 'Savings',
                                value: '${savingsRate.toStringAsFixed(1)}%',
                                icon: Icons.savings_rounded,
                                iconColor: AppColors.primary,
                                badge: savingsRate > 20 ? '🎯 Great' : 'Keep up',
                                badgePositive: savingsRate > 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── Spending Breakdown + Pulse ─────────────────────
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 10,
                            child: _SpendingBreakdown(metrics: metrics),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 11,
                            child: _FinancialPulse(metrics: metrics),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // ── Recent Transactions ────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent Transactions',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => context.go('/transactions'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: const Row(
                                children: [
                                  Text('See all', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                                  SizedBox(width: 2),
                                  Icon(Icons.arrow_forward_rounded, size: 13, color: AppColors.primary),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (metrics.categoryBreakdown.isEmpty)
                        _EmptyState()
                      else
                        _RecentTransactionsList(metrics: metrics, currencyFormat: currencyFormat),
                      const SizedBox(height: 120),
                    ],
                  ),
                );
              },
              loading: () => const SizedBox(
                height: 400,
                child: Center(
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                ),
              ),
              error: (err, stack) => Center(child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Error: $err'),
              )),
            ),
          ),
        ],
      ),
    );
  }

  String _greetingText() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning 👋';
    if (hour < 17) return 'Good afternoon 👋';
    return 'Good evening 👋';
  }

  double? _calculateTrend(int current, int previous) {
    if (previous == 0) {
      return null; // Cannot calculate meaningful trend without previous data
    }
    return ((current - previous) / previous) * 100;
  }
}

// ─── Premium Floating Action Button ──────────────────────────────────────────
class _PremiumFAB extends StatelessWidget {
  final VoidCallback onTap;
  const _PremiumFAB({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primaryMid, AppColors.primary],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
      ),
    );
  }
}

// ─── Notification Button ─────────────────────────────────────────────────────
class _NotificationButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (ctx) => _NotificationsSheet(),
        );
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE8F0EC), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.notifications_none_rounded, color: AppColors.primary, size: 20),
      ),
    );
  }
}

class _NotificationsSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_none_rounded, size: 40, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          Text('All caught up!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary)),
          const SizedBox(height: 8),
          Text(
            'No new notifications. We\'ll let you know\nwhen something needs your attention.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.6),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Hero Card ────────────────────────────────────────────────────────────────
class _HeroCard extends ConsumerWidget {
  final String netFlowStr;
  final double? trendPercentage;
  const _HeroCard({required this.netFlowStr, required this.trendPercentage});

  void _showMonthFilter(BuildContext context, WidgetRef ref, String currentTimeframe) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(height: 20),
                Text('Select Timeframe', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary)),
                const SizedBox(height: 16),
                _buildFilterOption(context, ref, 'This Month', currentTimeframe),
                _buildFilterOption(context, ref, 'Last Month', currentTimeframe),
                _buildFilterOption(context, ref, 'Last 3 Months', currentTimeframe),
                _buildFilterOption(context, ref, 'This Year', currentTimeframe),
                _buildFilterOption(context, ref, 'All Time', currentTimeframe),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterOption(BuildContext context, WidgetRef ref, String title, String currentTimeframe) {
    final isSelected = title == currentTimeframe;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? AppColors.primary : Theme.of(context).colorScheme.onSurface,
          fontSize: 15,
        ),
      ),
      trailing: isSelected
          ? Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 14),
            )
          : null,
      onTap: () {
        ref.read(dashboardTimeframeProvider.notifier).setTimeframe(title);
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPositive = (trendPercentage ?? 0) >= 0;
    final currentTimeframe = ref.watch(dashboardTimeframeProvider);

    return Container(
      width: double.infinity,
      height: 215, // Reduced height as requested
      decoration: BoxDecoration(
        color: const Color(0xFF1A382D),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF138A72).withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Background Image with Fade
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: MediaQuery.of(context).size.width * 0.65,
              child: ShaderMask(
                shaderCallback: (rect) {
                  return const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Colors.transparent, Colors.black],
                    stops: [0.0, 0.4],
                  ).createShader(rect);
                },
                blendMode: BlendMode.dstIn,
                child: Image.asset(
                  'assets/images/balance_card_bg.jpg',
                  fit: BoxFit.cover,
                  alignment: Alignment.centerRight,
                ),
              ),
            ),
            
            // Overlay Gradient
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      const Color(0xFF1A382D).withValues(alpha: 0.8),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.4],
                  ),
                ),
              ),
            ),

            // Top Header Section
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.bar_chart_rounded, color: Colors.white, size: 16),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            'Total Balance',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _showMonthFilter(context, ref, currentTimeframe),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Text(
                            currentTimeframe,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.filter_alt_outlined, color: Colors.white.withValues(alpha: 0.9), size: 14),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Balance and Trend
            Positioned(
              top: 66,
              left: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    netFlowStr,
                    style: const TextStyle(
                      fontSize: 34, // Slightly reduced to match new height
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.0,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (trendPercentage != null)
                    Row(
                      children: [
                        Icon(
                          isPositive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                          size: 16,
                          color: AppColors.primaryGlow,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${isPositive ? '+' : ''}${trendPercentage!.abs().toStringAsFixed(1)}% ',
                          style: const TextStyle(
                            color: AppColors.primaryGlow,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'vs last month',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w400,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            // Quote Text
            Positioned(
              right: 20,
              bottom: 74,
              width: 100,
              child: Text(
                'A better\ntomorrow\nstarts with\nsmall choices\ntoday.',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.4,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withValues(alpha: 0.8),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

            // Bottom Action Buttons
            Positioned(
              bottom: 16,
              left: 16,
              right: 80,
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => TransactionEntrySheet.show(context, initialType: 'income'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDF7EE),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_circle_outline_rounded, color: Color(0xFF1A382D), size: 18),
                            SizedBox(height: 2),
                            Text('Add Money', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1A382D))),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => TransactionEntrySheet.show(context, initialType: 'expense'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                        ),
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.send_rounded, color: Colors.white, size: 18),
                            SizedBox(height: 2),
                            Text('Send', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => context.go('/analytics'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                        ),
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.bar_chart_rounded, color: Colors.white, size: 18),
                            SizedBox(height: 2),
                            Text('Insights', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ─── Stat Card ────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final String badge;
  final bool badgePositive;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.badge,
    required this.badgePositive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8F0EC), width: 1),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 14, color: iconColor),
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: (badgePositive ? AppColors.success : AppColors.error).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Text(
              badge,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: badgePositive ? AppColors.success : AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Recent Transactions List ─────────────────────────────────────────────────
class _RecentTransactionsList extends StatelessWidget {
  final DashboardMetrics metrics;
  final NumberFormat currencyFormat;
  const _RecentTransactionsList({required this.metrics, required this.currencyFormat});

  IconData _getIconForCategory(String? category) {
    switch (category?.toLowerCase()) {
      case 'food': return Icons.restaurant_rounded;
      case 'transport': return Icons.directions_car_rounded;
      case 'shopping': return Icons.shopping_bag_rounded;
      case 'bills': return Icons.flash_on_rounded;
      case 'entertainment': return Icons.movie_creation_rounded;
      case 'salary': return Icons.work_rounded;
      default: return Icons.account_balance_wallet_rounded;
    }
  }

  Color _getColorForCategory(String? category) {
    switch (category?.toLowerCase()) {
      case 'food': return const Color(0xFFFF9800);
      case 'transport': return const Color(0xFF2196F3);
      case 'shopping': return const Color(0xFFE91E63);
      case 'bills': return const Color(0xFF00BCD4);
      case 'entertainment': return const Color(0xFF9C27B0);
      case 'salary': return AppColors.success;
      default: return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final recentTxs = metrics.recentTransactions;
    if (recentTxs.isEmpty) {
      return _EmptyState();
    }
    
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8F0EC), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: List.generate(recentTxs.length, (i) {
          final tx = recentTxs[i];
          final color = _getColorForCategory(tx.categoryId);
          final icon = _getIconForCategory(tx.categoryId);
          final isExpense = tx.type == 'expense';
          final dateFormat = DateFormat('MMM dd, yyyy');
          
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(icon, color: color, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tx.description ?? tx.categoryId ?? 'Transaction',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Theme.of(context).colorScheme.onSurface),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            dateFormat.format(tx.transactionDate),
                            style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${isExpense ? '-' : '+'} ${currencyFormat.format(tx.amount)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: isExpense ? AppColors.error : AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
              if (i < recentTxs.length - 1)
                Divider(height: 1, indent: 76, endIndent: 16, color: Colors.grey.withValues(alpha: 0.1)),
            ],
          );
        }),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE8F0EC), width: 1),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.account_balance_wallet_outlined, size: 44, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          Text('Start your journey', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 8),
          Text(
            'Add your first transaction\nto see insights here.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.6),
          ),
        ],
      ),
    );
  }
}

// ─── Spending Breakdown ───────────────────────────────────────────────────────
class _SpendingBreakdown extends StatelessWidget {
  final DashboardMetrics metrics;
  const _SpendingBreakdown({required this.metrics});

  static const _catColors = [
    Color(0xFFFF9800), Color(0xFF2196F3), Color(0xFFE91E63),
    Color(0xFFFFC107), Color(0xFF9C27B0),
  ];

  @override
  Widget build(BuildContext context) {
    final format = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8F0EC), width: 1),
        boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Spending', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Theme.of(context).colorScheme.onSurface)),
          Text('Breakdown', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 14),
          if (metrics.categoryBreakdown.isEmpty || metrics.monthlyExpenses == 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(child: Text('No data yet', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12))),
            )
          else ...[
            SizedBox(
              height: 110,
              child: Stack(
                children: [
                  PieChart(PieChartData(
                    sectionsSpace: 3,
                    centerSpaceRadius: 32,
                    sections: metrics.categoryBreakdown.entries.take(5).toList().asMap().entries.map((e) {
                      final pct = (e.value.value / metrics.monthlyExpenses) * 100;
                      return PieChartSectionData(
                        color: _catColors[e.key % _catColors.length],
                        value: pct, title: '', radius: 18,
                      );
                    }).toList(),
                  )),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(format.format(metrics.monthlyExpenses),
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Theme.of(context).colorScheme.onSurface)),
                        ),
                        Text('spent', style: TextStyle(fontSize: 9, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ...metrics.categoryBreakdown.entries.take(4).toList().asMap().entries.map((e) {
              final pct = (e.value.value / metrics.monthlyExpenses) * 100;
              return Padding(
                padding: const EdgeInsets.only(bottom: 5.0),
                child: Row(
                  children: [
                    Container(width: 7, height: 7, decoration: BoxDecoration(color: _catColors[e.key % _catColors.length], shape: BoxShape.circle)),
                    const SizedBox(width: 7),
                    Expanded(child: Text(e.value.key, style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant), overflow: TextOverflow.ellipsis)),
                    Text('${pct.toStringAsFixed(0)}%', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface)),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

// ─── Financial Pulse ──────────────────────────────────────────────────────────
class _FinancialPulse extends StatelessWidget {
  final DashboardMetrics metrics;
  const _FinancialPulse({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8F0EC), width: 1),
        boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.insights_rounded, size: 13, color: AppColors.primary),
              ),
              const SizedBox(width: 8),
              Text('Financial\nPulse', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Theme.of(context).colorScheme.onSurface)),
            ],
          ),
          const SizedBox(height: 16),
          ..._buildInsights(context),
        ],
      ),
    );
  }

  List<Widget> _buildInsights(BuildContext context) {
    if (metrics.categoryBreakdown.isEmpty) {
      return [_pulseItem(context, Icons.info_outline_rounded, Colors.grey, 'No data yet', 'Start spending to see insights')];
    }
    final insights = <Widget>[];
    final topCat = metrics.categoryBreakdown.entries.reduce((a, b) => a.value > b.value ? a : b);
    insights.add(_pulseItem(context, Icons.star_rounded, const Color(0xFFFF9800), '${topCat.key} leads', 'Top expense category'));

    if (metrics.monthlyIncome > 0) {
      final ratio = metrics.monthlyExpenses / metrics.monthlyIncome;
      if (ratio > 0.8) {
        insights.add(_pulseItem(context, Icons.warning_amber_rounded, AppColors.error, 'High Spend', 'Spent ${(ratio * 100).toInt()}% of income'));
      } else {
        insights.add(_pulseItem(context, Icons.check_circle_outline_rounded, AppColors.success, 'Healthy', 'Saved ${((1 - ratio) * 100).toInt()}%'));
      }
    }

    if (metrics.prevMonthlyExpenses > 0) {
      final diff = metrics.monthlyExpenses - metrics.prevMonthlyExpenses;
      final pct  = (diff / metrics.prevMonthlyExpenses).abs() * 100;
      if (diff > 0) {
        insights.add(_pulseItem(context, Icons.trending_up_rounded, AppColors.error, 'Up ${pct.toInt()}%', 'vs last month'));
      } else {
        insights.add(_pulseItem(context, Icons.trending_down_rounded, AppColors.success, 'Down ${pct.toInt()}%', 'vs last month'));
      }
    }
    return insights;
  }

  Widget _pulseItem(BuildContext ctx, IconData icon, Color color, String t1, String t2) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, size: 12, color: color),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t1, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Theme.of(ctx).colorScheme.onSurface)),
                Text(t2, style: TextStyle(fontSize: 10, color: Theme.of(ctx).colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

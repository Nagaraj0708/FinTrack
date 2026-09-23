import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/analytics/analytics_engine.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';
import '../../../transactions/domain/entities/transaction.dart';

class DashboardMetrics {
  final int monthlyIncome;
  final int monthlyExpenses;
  final int netCashFlow;
  final int prevMonthlyIncome;
  final int prevMonthlyExpenses;
  final int prevNetCashFlow;
  final Map<String, int> categoryBreakdown;
  final int transactionCount;
  final List<Transaction> recentTransactions;

  DashboardMetrics({
    required this.monthlyIncome,
    required this.monthlyExpenses,
    required this.netCashFlow,
    required this.prevMonthlyIncome,
    required this.prevMonthlyExpenses,
    required this.prevNetCashFlow,
    required this.categoryBreakdown,
    required this.transactionCount,
    required this.recentTransactions,
  });
}

class DashboardTimeframe extends Notifier<String> {
  @override
  String build() => 'This Month';

  void setTimeframe(String value) {
    state = value;
  }
}

final dashboardTimeframeProvider = NotifierProvider<DashboardTimeframe, String>(DashboardTimeframe.new);

final dashboardMetricsProvider = Provider<AsyncValue<DashboardMetrics>>((ref) {
  final transactionsAsync = ref.watch(transactionsStreamProvider);
  final timeframe = ref.watch(dashboardTimeframeProvider);

  return transactionsAsync.whenData((transactions) {
    final now = DateTime.now();
    List<Transaction> currentTxs;
    List<Transaction> prevTxs;

    if (timeframe == 'This Month') {
      currentTxs = transactions.where((t) => t.transactionDate.year == now.year && t.transactionDate.month == now.month).toList();
      final prevMonth = now.month == 1 ? DateTime(now.year - 1, 12, 1) : DateTime(now.year, now.month - 1, 1);
      prevTxs = transactions.where((t) => t.transactionDate.year == prevMonth.year && t.transactionDate.month == prevMonth.month).toList();
    } else if (timeframe == 'Last Month') {
      final lastMonth = now.month == 1 ? DateTime(now.year - 1, 12, 1) : DateTime(now.year, now.month - 1, 1);
      currentTxs = transactions.where((t) => t.transactionDate.year == lastMonth.year && t.transactionDate.month == lastMonth.month).toList();
      final prevMonth = lastMonth.month == 1 ? DateTime(lastMonth.year - 1, 12, 1) : DateTime(lastMonth.year, lastMonth.month - 1, 1);
      prevTxs = transactions.where((t) => t.transactionDate.year == prevMonth.year && t.transactionDate.month == prevMonth.month).toList();
    } else if (timeframe == 'Last 3 Months') {
      final threeMonthsAgo = DateTime(now.year, now.month - 2, 1);
      currentTxs = transactions.where((t) => t.transactionDate.isAfter(threeMonthsAgo.subtract(const Duration(days: 1)))).toList();
      final prevThreeMonthsAgo = DateTime(now.year, now.month - 5, 1);
      prevTxs = transactions.where((t) => t.transactionDate.isAfter(prevThreeMonthsAgo.subtract(const Duration(days: 1))) && t.transactionDate.isBefore(threeMonthsAgo)).toList();
    } else if (timeframe == 'This Year') {
      currentTxs = transactions.where((t) => t.transactionDate.year == now.year).toList();
      prevTxs = transactions.where((t) => t.transactionDate.year == now.year - 1).toList();
    } else {
      // All Time
      currentTxs = transactions.toList();
      prevTxs = [];
    }

    return DashboardMetrics(
      monthlyIncome: AnalyticsEngine.calculateTotalIncome(currentTxs),
      monthlyExpenses: AnalyticsEngine.calculateTotalExpenses(currentTxs),
      netCashFlow: AnalyticsEngine.calculateTotalNetCashFlow(currentTxs),
      prevMonthlyIncome: AnalyticsEngine.calculateTotalIncome(prevTxs),
      prevMonthlyExpenses: AnalyticsEngine.calculateTotalExpenses(prevTxs),
      prevNetCashFlow: AnalyticsEngine.calculateTotalNetCashFlow(prevTxs),
      categoryBreakdown: AnalyticsEngine.calculateTotalCategoryBreakdown(currentTxs),
      transactionCount: currentTxs.length,
      recentTransactions: (currentTxs.toList()..sort((a, b) => b.transactionDate.compareTo(a.transactionDate))).take(5).toList(),
    );
  });
});

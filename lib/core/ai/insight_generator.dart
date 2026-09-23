import '../../features/dashboard/presentation/providers/dashboard_provider.dart';

class InsightGenerator {
  static Future<String> generateFinancialSummary(
    DashboardMetrics metrics,
  ) async {
    // Simulated AI network delay / processing time
    await Future.delayed(const Duration(seconds: 1));

    final net = metrics.netCashFlow;
    final income = metrics.monthlyIncome;
    final expenses = metrics.monthlyExpenses;

    if (income == 0 && expenses == 0) {
      return "No financial activity recorded yet for this month. Start tracking your income and expenses to unlock insights.";
    }

    if (net > 0) {
      return "Fantastic! You've generated ₹$net in surplus this month. Your income (₹$income) is safely outpacing your expenses (₹$expenses). Consider allocating the surplus to your savings goals.";
    } else if (net < 0) {
      return "Attention needed. Your expenses (₹$expenses) have exceeded your income (₹$income) by ₹${net.abs()}. Review your Spending Breakdown to identify areas where you can cut back.";
    } else {
      return "You are perfectly breaking even. Income matches expenses at ₹$income. Keep a close watch to ensure you build a surplus next month.";
    }
  }
}

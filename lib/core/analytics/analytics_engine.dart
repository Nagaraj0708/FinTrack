import '../../features/transactions/domain/entities/transaction.dart';

class AnalyticsEngine {
  static int calculateMonthlyIncome(
    List<Transaction> transactions,
    DateTime month,
  ) {
    return transactions
        .where(
          (t) =>
              t.type == 'income' &&
              t.transactionDate.year == month.year &&
              t.transactionDate.month == month.month,
        )
        .fold(0, (sum, t) => sum + t.amount);
  }

  static int calculateMonthlyExpenses(
    List<Transaction> transactions,
    DateTime month,
  ) {
    return transactions
        .where(
          (t) =>
              t.type == 'expense' &&
              t.transactionDate.year == month.year &&
              t.transactionDate.month == month.month,
        )
        .fold(0, (sum, t) => sum + t.amount);
  }

  static int calculateNetCashFlow(
    List<Transaction> transactions,
    DateTime month,
  ) {
    return calculateMonthlyIncome(transactions, month) -
        calculateMonthlyExpenses(transactions, month);
  }

  static Map<String, int> calculateCategoryBreakdown(
    List<Transaction> transactions,
    DateTime month,
  ) {
    final breakdown = <String, int>{};
    final expenses = transactions.where(
      (t) =>
          t.type == 'expense' &&
          t.transactionDate.year == month.year &&
          t.transactionDate.month == month.month,
    );
    for (final t in expenses) {
      final category = t.categoryId ?? 'Uncategorized';
      breakdown[category] = (breakdown[category] ?? 0) + t.amount;
    }
    return breakdown;
  }

  static int calculateTotalIncome(List<Transaction> transactions) {
    return transactions.where((t) => t.type == 'income').fold(0, (sum, t) => sum + t.amount);
  }

  static int calculateTotalExpenses(List<Transaction> transactions) {
    return transactions.where((t) => t.type == 'expense').fold(0, (sum, t) => sum + t.amount);
  }

  static int calculateTotalNetCashFlow(List<Transaction> transactions) {
    return calculateTotalIncome(transactions) - calculateTotalExpenses(transactions);
  }

  static Map<String, int> calculateTotalCategoryBreakdown(List<Transaction> transactions) {
    final breakdown = <String, int>{};
    for (final t in transactions.where((t) => t.type == 'expense')) {
      final category = t.categoryId ?? 'Uncategorized';
      breakdown[category] = (breakdown[category] ?? 0) + t.amount;
    }
    return breakdown;
  }
}

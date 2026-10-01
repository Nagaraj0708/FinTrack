import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/colors.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';
import '../../../transactions/domain/entities/transaction.dart' as entity;
import '../../../../core/analytics/analytics_engine.dart';

class AnalyticsPage extends ConsumerStatefulWidget {
  const AnalyticsPage({super.key});

  @override
  ConsumerState<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends ConsumerState<AnalyticsPage> {
  DateTime _selectedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );

  void _pickMonth() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _MonthPickerSheet(
        selected: _selectedMonth,
        onSelected: (d) => setState(() => _selectedMonth = d),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionsStreamProvider);
    final currencyFormat = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );
    final monthFormat = DateFormat('MMMM yyyy');

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: Theme.of(context).brightness == Brightness.dark 
            ? const [Color(0xFF141A17), Color(0xFF0A0F0D), Color(0xFF0A0F0D)]
            : const [Color(0xFFE6F0EB), Colors.white, Color(0xFFF4F7F6)],
          stops: const [0.0, 0.3, 1.0],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Analytics',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                          letterSpacing: -0.8,
                        ),
                      ),
                      GestureDetector(
                        onTap: _pickMonth,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(50),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.15), width: 1),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_month_rounded, size: 14, color: AppColors.primary),
                              const SizedBox(width: 7),
                              Text(
                                monthFormat.format(_selectedMonth),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.primary),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Understand your spending. Build a better tomorrow.',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: transactionsAsync.when(
                data: (transactions) {
          final monthlyIncome = AnalyticsEngine.calculateMonthlyIncome(
            transactions,
            _selectedMonth,
          );
          final monthlyExpenses = AnalyticsEngine.calculateMonthlyExpenses(
            transactions,
            _selectedMonth,
          );
          final netSavings = monthlyIncome - monthlyExpenses;

          final prevMonth = DateTime(
            _selectedMonth.year,
            _selectedMonth.month - 1,
            1,
          );
          final prevMonthlyExpenses = AnalyticsEngine.calculateMonthlyExpenses(
            transactions,
            prevMonth,
          );
          final incomeRate = monthlyIncome > 0 ? '100% of total' : 'No income';
          final expensesRate = monthlyIncome > 0 ? '${((monthlyExpenses / monthlyIncome) * 100).toStringAsFixed(1)}% of income' : '0% of income';
          final savingsRate = monthlyIncome > 0 ? '${((netSavings / monthlyIncome) * 100).toStringAsFixed(1)}% of income' : '0% of income';

          final categoryBreakdown = AnalyticsEngine.calculateCategoryBreakdown(
            transactions,
            _selectedMonth,
          );
          final topMerchants = _calculateTopMerchants(
            transactions,
            _selectedMonth,
          );

          final monthTxs = transactions
              .where(
                (t) =>
                    t.transactionDate.year == _selectedMonth.year &&
                    t.transactionDate.month == _selectedMonth.month,
              )
              .toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Summary Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        'Total Income',
                        currencyFormat.format(monthlyIncome),
                        incomeRate,
                        true,
                        Icons.account_balance_wallet_rounded,
                        AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildSummaryCard(
                        'Total Expenses',
                        currencyFormat.format(monthlyExpenses),
                        expensesRate,
                        false, // Usually expenses are red
                        Icons.shopping_cart_rounded,
                        AppColors.error,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildSummaryCard(
                        'Net Savings',
                        currencyFormat.format(netSavings),
                        savingsRate,
                        netSavings >= 0,
                        Icons.savings_rounded,
                        AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Main Charts (Stacked for Mobile)
                _buildDoughnutChartCard(
                  categoryBreakdown,
                  monthlyExpenses,
                  currencyFormat,
                ),
                const SizedBox(height: 16),
                _buildBarChartCard('Income vs Expenses', transactions),
                const SizedBox(height: 16),
                _buildLineChartCard('Spending Trend', monthTxs),
                const SizedBox(height: 16),
                _buildTopMerchantsCard(topMerchants, currencyFormat),
                const SizedBox(height: 16),

                // Small Bar Charts Row (Horizontally Scrollable)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 220,
                        child: _buildSmallBarChart(
                          'Spending by Day of Week',
                          monthTxs,
                          isDayOfWeek: true,
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 220,
                        child: _buildSmallBarChart(
                          'Spending by Time of Day',
                          monthTxs,
                          isTime: true,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Key Insights
                Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Key Insights',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Column(
                  children: _buildInsights(
                    monthlyIncome,
                    monthlyExpenses,
                    prevMonthlyExpenses,
                    categoryBreakdown,
                  ),
                ),
                const SizedBox(height: 48),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
            ),
          ],
        ),
      ),
    ));
  }

  Map<String, List<entity.Transaction>> _calculateTopMerchants(
    List<entity.Transaction> txs,
    DateTime month,
  ) {
    final expenses = txs.where(
      (t) =>
          t.type == 'expense' &&
          t.transactionDate.year == month.year &&
          t.transactionDate.month == month.month,
    );
    final map = <String, List<entity.Transaction>>{};
    for (var tx in expenses) {
      final key = tx.description ?? tx.categoryId ?? 'Unknown';
      map.putIfAbsent(key, () => []).add(tx);
    }
    return map;
  }

  List<Widget> _buildInsights(
    int inc,
    int exp,
    int prevExp,
    Map<String, int> catBreakdown,
  ) {
    List<Widget> insights = [];

    if (exp == 0 && inc == 0) {
      insights.add(
        _buildInsightCard(
          Icons.info_outline_rounded,
          Colors.grey,
          'No data for this month to generate insights.',
        ),
      );
      return insights;
    }

    if (prevExp > 0) {
      final diff = exp - prevExp;
      final pct = (diff / prevExp).abs() * 100;
      if (diff > 0) {
        insights.add(
          _buildInsightCard(
            Icons.trending_up_rounded,
            AppColors.error,
            'Spending is up ${pct.toInt()}% compared to last month. Keep an eye on expenses.',
          ),
        );
      } else {
        insights.add(
          _buildInsightCard(
            Icons.trending_down_rounded,
            AppColors.success,
            'Great job! Spending is down ${pct.toInt()}% compared to last month.',
          ),
        );
      }
    }

    if (catBreakdown.isNotEmpty) {
      final topCat = catBreakdown.entries.reduce(
        (a, b) => a.value > b.value ? a : b,
      );
      insights.add(
        _buildInsightCard(
          Icons.pie_chart_rounded,
          const Color(0xFFFF9800),
          '${topCat.key} is your largest expense category this month.',
        ),
      );
    }

    if (inc > 0) {
      final ratio = exp / inc;
      if (ratio > 0.8) {
        insights.add(
          _buildInsightCard(
            Icons.warning_amber_rounded,
            AppColors.error,
            'You have spent ${(ratio * 100).toInt()}% of your income. Consider saving more.',
          ),
        );
      } else {
        insights.add(
          _buildInsightCard(
            Icons.savings_rounded,
            AppColors.success,
            'You saved ${((1 - ratio) * 100).toInt()}% of your income this month!',
          ),
        );
      }
    }

    if (insights.isEmpty) {
      insights.add(
        _buildInsightCard(
          Icons.lightbulb_outline_rounded,
          AppColors.primary,
          'Keep logging transactions to unlock more insights.',
        ),
      );
    }

    // Add spacing between insights
    return insights.expand((w) => [w, const SizedBox(height: 12)]).toList()
      ..removeLast();
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    String trend,
    bool isPositive,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 12, color: color),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                isPositive
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                size: 10,
                color: isPositive ? AppColors.success : AppColors.error,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    trend,
                    style: TextStyle(
                      color: isPositive ? AppColors.success : AppColors.error,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDoughnutChartCard(
    Map<String, int> breakdown,
    int totalExpenses,
    NumberFormat format,
  ) {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Spending by Category',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: SizedBox(
                  height: 180,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 50,
                          sections: _buildPieSections(breakdown, totalExpenses),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              format.format(totalExpenses),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Text(
                            'This Month',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _buildLegend(breakdown, totalExpenses, format),
                ),
              ),
            ],
          ),
          const Spacer(),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections(
    Map<String, int> breakdown,
    int total,
  ) {
    if (total == 0 || breakdown.isEmpty) {
      return [
        PieChartSectionData(
          value: 1,
          color: Colors.grey.shade200,
          radius: 24,
          showTitle: false,
        ),
      ];
    }
    final sorted = breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted
        .map(
          (e) => PieChartSectionData(
            color: _getCategoryColor(e.key),
            value: e.value.toDouble(),
            title: '',
            radius: 20,
          ),
        )
        .toList();
  }

  List<Widget> _buildLegend(
    Map<String, int> breakdown,
    int total,
    NumberFormat format,
  ) {
    if (total == 0 || breakdown.isEmpty) {
      return [
        Text(
          'No expenses',
          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
        ),
      ];
    }
    final sorted = breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(5).map((e) {
      final percentage = ((e.value / total) * 100).round();
      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getCategoryColor(e.key),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                e.key,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '$percentage%',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildBarChartCard(String title, List<entity.Transaction> txs) {
    final months = <DateTime>[];
    for (int i = 5; i >= 0; i--) {
      months.add(DateTime(_selectedMonth.year, _selectedMonth.month - i, 1));
    }

    final groups = <BarChartGroupData>[];
    double maxY = 1000;
    for (int i = 0; i < months.length; i++) {
      final inc = AnalyticsEngine.calculateMonthlyIncome(
        txs,
        months[i],
      ).toDouble();
      final exp = AnalyticsEngine.calculateMonthlyExpenses(
        txs,
        months[i],
      ).toDouble();
      if (inc > maxY) maxY = inc;
      if (exp > maxY) maxY = exp;
      groups.add(_buildGroup(i, inc, exp));
    }

    if (maxY == 0) maxY = 1000;

    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY * 1.2,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (val, meta) {
                        if (val.toInt() >= 0 && val.toInt() < months.length) {
                          return Text(
                            DateFormat('MMM').format(months[val.toInt()]),
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        }
                        return Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      interval: maxY > 0 ? maxY / 4 : 250,
                      getTitlesWidget: (val, meta) {
                        if (val == 0) return Text('');
                        return Text(
                          '${(val / 1000).toStringAsFixed(maxY < 10000 ? 1 : 0)}K',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY > 0 ? maxY / 4 : 250,
                  getDrawingHorizontalLine: (value) =>
                      FlLine(color: Colors.grey.shade100, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                barGroups: groups,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Income',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Expenses',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  BarChartGroupData _buildGroup(int x, double income, double expense) {
    return BarChartGroupData(
      x: x,
      barsSpace: 4,
      barRods: [
        BarChartRodData(
          toY: income,
          color: AppColors.success,
          width: 8,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
        BarChartRodData(
          toY: expense,
          color: AppColors.error,
          width: 8,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
      ],
    );
  }

  Widget _buildLineChartCard(String title, List<entity.Transaction> monthTxs) {
    final daysInMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + 1,
      0,
    ).day;
    final dailySpend = List<double>.filled(daysInMonth, 0);
    for (var tx in monthTxs.where((t) => t.type == 'expense')) {
      dailySpend[tx.transactionDate.day - 1] += tx.amount;
    }

    final spots = <FlSpot>[];
    double maxSpend = 1000;
    for (int i = 0; i < daysInMonth; i++) {
      if (dailySpend[i] > maxSpend) maxSpend = dailySpend[i];
      spots.add(FlSpot((i + 1).toDouble(), dailySpend[i]));
    }

    if (maxSpend == 0) maxSpend = 1000;

    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) =>
                      FlLine(color: Colors.grey.shade100, strokeWidth: 1),
                ),
                minY: -(maxSpend * 0.05), // Prevents line from touching the X-axis text
                maxY: maxSpend * 1.2,
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (val, meta) {
                        int day = val.toInt();
                        if (day == 1 ||
                            day == 10 ||
                            day == 20 ||
                            day == daysInMonth) {
                          return Text(
                            '$day ${DateFormat('MMM').format(_selectedMonth)}',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 10,
                            ),
                          );
                        }
                        return Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: (maxSpend > 0 ? maxSpend / 4 : 1000.0).clamp(1.0, double.infinity).toDouble(),
                      getTitlesWidget: (val, meta) {
                        if (val <= 0) return Text('');
                        // Only show non-duplicate integer K values
                        final kValue = (val / 1000).toStringAsFixed(1);
                        return Text(
                          kValue.endsWith('.0') ? '${(val / 1000).toInt()}K' : '${kValue}K',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    preventCurveOverShooting: true,
                    color: const Color(0xFF1B3B36),
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF1B3B36).withValues(alpha: 0.3),
                          const Color(0xFF1B3B36).withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopMerchantsCard(
    Map<String, List<entity.Transaction>> topMerchants,
    NumberFormat format,
  ) {
    final sortedList = topMerchants.entries.toList()
      ..sort((a, b) {
        final aSum = a.value.fold(0, (s, t) => s + t.amount);
        final bSum = b.value.fold(0, (s, t) => s + t.amount);
        return bSum.compareTo(aSum);
      });

    return Container(
      constraints: const BoxConstraints(minHeight: 150, maxHeight: 300),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Top Merchants / Spends',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 16),
          if (sortedList.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No expenses recorded',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ),
            )
          else
            Expanded(
              child: ListView(
                children: sortedList.take(5).map((e) {
                  final amount = e.value.fold(
                    0,
                    (s, t) => s + t.amount,
                  );
                  return _merchantItem(
                    e.key,
                    '${e.value.length} transaction(s)',
                    format.format(amount),
                    _getCategoryColor(e.value.first.categoryId),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _merchantItem(String name, String sub, String amt, Color c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: c,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.storefront_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  sub,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            amt,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallBarChart(
    String title,
    List<entity.Transaction> monthTxs, {
    bool isDayOfWeek = false,
    bool isTime = false,
  }) {
    List<BarChartGroupData> groups = [];
    List<String> labels = [];
    double maxY = 10;

    if (isDayOfWeek) {
      labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final spends = List<double>.filled(7, 0);
      for (var tx in monthTxs.where((t) => t.type == 'expense')) {
        spends[tx.transactionDate.weekday - 1] += tx.amount;
      }
      for (int i = 0; i < 7; i++) {
        if (spends[i] > maxY) maxY = spends[i];
        groups.add(
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: spends[i],
                color: const Color(0xFF1B3B36),
                width: 10,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        );
      }
    } else if (isTime) {
      labels = ['12A', '4A', '8A', '12P', '4P', '8P'];
      final spends = List<double>.filled(6, 0);
      for (var tx in monthTxs.where((t) => t.type == 'expense')) {
        int index = tx.transactionDate.hour ~/ 4;
        spends[index] += tx.amount;
      }
      for (int i = 0; i < 6; i++) {
        if (spends[i] > maxY) maxY = spends[i];
        groups.add(
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: spends[i],
                color: const Color(0xFF1B3B36),
                width: 10,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        );
      }
    }

    if (maxY == 0) maxY = 10;

    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          SizedBox(
            height: 120,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY * 1.2,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 20,
                      getTitlesWidget: (val, meta) {
                        int index = val.toInt();
                        if (index >= 0 && index < labels.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              labels[index],
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 9,
                              ),
                            ),
                          );
                        }
                        return Text('');
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: groups,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(IconData icon, Color color, String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: Text(
                text,
                style: TextStyle(
                  color: Colors.grey.shade800,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String? category) {
    switch (category) {
      case 'Food':
        return const Color(0xFFFF5722); // Deep Orange
      case 'Housing':
        return const Color(0xFF673AB7);
      case 'Transport':
        return const Color(0xFF212121);
      case 'Subscriptions':
        return const Color(0xFF4CAF50);
      case 'Groceries':
        return const Color(0xFFFFC107);
      case 'Income':
        return const Color(0xFF2196F3);
      case 'Salary':
        return const Color(0xFF2196F3);
      case 'Fuel':
        return const Color(0xFFE91E63);
      case 'Shopping':
        return const Color(0xFFE91E63);
      case 'Bills':
        return const Color(0xFF00BCD4);
      case 'Entertainment':
        return const Color(0xFF9C27B0);
      case 'Cricket':
        return const Color(0xFF8BC34A); // Light Green
      case 'Loan':
        return const Color(0xFFF44336); // Red
      default:
        return AppColors.primary;
    }
  }
}

// ─── Premium Month Picker Sheet ───────────────────────────────────────────────
class _MonthPickerSheet extends StatefulWidget {
  final DateTime selected;
  final ValueChanged<DateTime> onSelected;
  const _MonthPickerSheet({required this.selected, required this.onSelected});

  @override
  State<_MonthPickerSheet> createState() => _MonthPickerSheetState();
}

class _MonthPickerSheetState extends State<_MonthPickerSheet> {
  late int _year;
  late int _month;

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  void initState() {
    super.initState();
    _year = widget.selected.year;
    _month = widget.selected.month;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    
    // Generate a list of years (e.g., 5 years back, 1 year forward)
    final yearList = List.generate(7, (index) => now.year - 5 + index).reversed.toList();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Header with Year Dropdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Select Month', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary)),
              
              // Year Dropdown
              PopupMenuButton<int>(
                initialValue: _year,
                onSelected: (y) => setState(() => _year = y),
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                itemBuilder: (context) => yearList.map((y) => PopupMenuItem(
                  value: y,
                  child: Text(
                    y.toString(),
                    style: TextStyle(
                      fontWeight: y == _year ? FontWeight.w800 : FontWeight.w600,
                      color: y == _year ? AppColors.primary : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                )).toList(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$_year',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primary),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: AppColors.primary),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Month grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 2.0,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: 12,
            itemBuilder: (context, i) {
              final m = i + 1;
              final isSelected = m == _month && _year == widget.selected.year;
              final isCurrent = m == now.month && _year == now.year;
              final isFuture = DateTime(_year, m).isAfter(now);

              return GestureDetector(
                onTap: isFuture ? null : () {
                  setState(() => _month = m);
                  // Auto-confirm for better UX
                  widget.onSelected(DateTime(_year, _month, 1));
                  Navigator.pop(context);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : isCurrent
                            ? AppColors.primary.withValues(alpha: 0.08)
                            : Colors.grey.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: isCurrent && !isSelected
                        ? Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5)
                        : null,
                    boxShadow: isSelected
                        ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))]
                        : [],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _months[i],
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : isFuture
                              ? Colors.grey.shade300
                              : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

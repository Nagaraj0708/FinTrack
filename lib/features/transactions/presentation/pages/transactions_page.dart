import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/colors.dart';
import '../providers/transaction_provider.dart';
import '../widgets/transaction_entry_sheet.dart';

class TransactionsPage extends ConsumerStatefulWidget {
  const TransactionsPage({super.key});

  @override
  ConsumerState<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends ConsumerState<TransactionsPage> {
  int _selectedTabIndex = 0; // 0: All, 1: Expenses, 2: Income, 3: Transfers
  bool _isSearching = false;
  String _searchQuery = '';
  String _timeFilter = 'This Month';
  String _sortOrder = 'Date (Latest)';
  String _categoryFilter = 'All Categories';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionsStreamProvider);
    final currencyFormat = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );
    final timeFormat = DateFormat('h:mm a');

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE6F0EB), // Premium subtle mint glow
            Colors.white,
            Color(0xFFF4F7F6),
          ],
          stops: [0.0, 0.3, 1.0],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: _isSearching
                        ? TextField(
                            controller: _searchController,
                            autofocus: true,
                            decoration: InputDecoration(
                              hintText: 'Search transactions...',
                              hintStyle: TextStyle(color: Colors.grey.shade500),
                              border: InputBorder.none,
                            ),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                            onChanged: (val) =>
                                setState(() => _searchQuery = val),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Transactions',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              Text(
                                'All your income, expenses and transfers',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            if (_isSearching) {
                              _isSearching = false;
                              _searchQuery = '';
                              _searchController.clear();
                            } else {
                              _isSearching = true;
                            }
                          });
                        },
                        child: _buildIconButton(
                          _isSearching
                              ? Icons.close_rounded
                              : Icons.search_rounded,
                        ),
                      ),
                      SizedBox(width: 8),
                      _buildIconButton(Icons.tune_rounded),
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE8F0EC), width: 1),
                ),
                child: Row(
                  children: [
                    _buildTabPill('All', 0),
                    _buildTabPill('Expenses', 1),
                    _buildTabPill('Income', 2),
                    _buildTabPill('Transfers', 3),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // Filter Dropdowns
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildFilterDropdown(
                      Icons.calendar_today_rounded,
                      _timeFilter,
                      ['All Time', 'This Month', 'Last Month', 'This Year'],
                      (val) => setState(() => _timeFilter = val),
                    ),
                    SizedBox(width: 8),
                    _buildFilterDropdown(
                      Icons.swap_vert_rounded,
                      _sortOrder,
                      [
                        'Date (Latest)',
                        'Date (Oldest)',
                        'Amount (Highest)',
                        'Amount (Lowest)',
                      ],
                      (val) => setState(() => _sortOrder = val),
                    ),
                    SizedBox(width: 8),
                    _buildFilterDropdown(
                      Icons.list_rounded,
                      _categoryFilter,
                      [
                        'All Categories',
                        'Food',
                        'Housing',
                        'Transport',
                        'Shopping',
                        'Income',
                        'Salary',
                        'Cricket',
                        'Loan',
                      ],
                      (val) => setState(() => _categoryFilter = val),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 12),

            // Main Content Area
            Expanded(
              child: transactionsAsync.when(
                data: (transactions) {
                  List<dynamic> filteredTx = transactions;
                  if (_selectedTabIndex == 1) {
                    filteredTx = filteredTx
                        .where((tx) => tx.type == 'expense')
                        .toList();
                  } else if (_selectedTabIndex == 2) {
                    filteredTx = filteredTx
                        .where((tx) => tx.type == 'income')
                        .toList();
                  }

                  if (_searchQuery.isNotEmpty) {
                    final q = _searchQuery.toLowerCase();
                    filteredTx = filteredTx.where((tx) {
                      final desc = (tx.description ?? '').toLowerCase();
                      final cat = (tx.categoryId ?? '').toLowerCase();
                      return desc.contains(q) || cat.contains(q);
                    }).toList();
                  }

                  final now = DateTime.now();
                  if (_timeFilter == 'This Month') {
                    filteredTx = filteredTx
                        .where(
                          (tx) =>
                              tx.transactionDate.year == now.year &&
                              tx.transactionDate.month == now.month,
                        )
                        .toList();
                  } else if (_timeFilter == 'Last Month') {
                    final lastMonth = DateTime(now.year, now.month - 1);
                    filteredTx = filteredTx
                        .where(
                          (tx) =>
                              tx.transactionDate.year == lastMonth.year &&
                              tx.transactionDate.month == lastMonth.month,
                        )
                        .toList();
                  } else if (_timeFilter == 'This Year') {
                    filteredTx = filteredTx
                        .where((tx) => tx.transactionDate.year == now.year)
                        .toList();
                  }

                  if (_categoryFilter != 'All Categories') {
                    filteredTx = filteredTx
                        .where((tx) => tx.categoryId == _categoryFilter)
                        .toList();
                  }

                  int totalSpent = filteredTx
                      .where((tx) => tx.type == 'expense')
                      .fold(0, (sum, tx) => sum + (tx.amount as int));
                  int totalIncome = filteredTx
                      .where((tx) => tx.type == 'income')
                      .fold(0, (sum, tx) => sum + (tx.amount as int));

                  // Group by Date
                  Map<String, List<dynamic>> grouped = {};
                  for (var tx in filteredTx) {
                    final dateKey = DateFormat(
                      'yyyy-MM-dd',
                    ).format(tx.transactionDate);
                    grouped.putIfAbsent(dateKey, () => []).add(tx);
                  }

                  // Sort dates
                  final sortedDates = grouped.keys.toList();
                  if (_sortOrder == 'Date (Latest)') {
                    sortedDates.sort((a, b) => b.compareTo(a));
                  } else if (_sortOrder == 'Date (Oldest)') {
                    sortedDates.sort((a, b) => a.compareTo(b));
                  }

                  if (_sortOrder == 'Amount (Highest)') {
                    for (var date in sortedDates) {
                      grouped[date]!.sort(
                        (a, b) => (b.amount as int).compareTo(a.amount as int),
                      );
                    }
                  } else if (_sortOrder == 'Amount (Lowest)') {
                    for (var date in sortedDates) {
                      grouped[date]!.sort(
                        (a, b) => (a.amount as int).compareTo(b.amount as int),
                      );
                    }
                  } else {
                    // Default to latest time within the day
                    for (var date in sortedDates) {
                      grouped[date]!.sort(
                        (a, b) =>
                            b.transactionDate.compareTo(a.transactionDate),
                      );
                    }
                  }

                  return CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 0,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                Expanded(
                                  flex: 1,
                                  child: _buildSummaryCardWithIcon(
                                    'Total Transactions',
                                    filteredTx.length.toString(),
                                    '+12%',
                                    true,
                                    Icons.receipt_long_rounded,
                                    const Color(0xFF2196F3),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  flex: 1,
                                  child: _buildSummaryCardWithIcon(
                                    'Total Spent',
                                    currencyFormat.format(totalSpent),
                                    '- 6%',
                                    false,
                                    Icons.thumb_down_rounded,
                                    AppColors.error,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  flex: 1,
                                  child: _buildSummaryCardWithIcon(
                                    'Total Income',
                                    currencyFormat.format(totalIncome),
                                    '+ 4%',
                                    true,
                                    Icons.arrow_downward_rounded,
                                    AppColors.success,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      if (filteredTx.isEmpty)
                        SliverFillRemaining(
                          child: Center(
                            child: Text(
                              'No transactions found',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final dateStr = sortedDates[index];
                              final dailyTxs = grouped[dateStr]!;

                              // Format the date header
                              final dateObj = DateTime.parse(dateStr);
                              final now = DateTime.now();
                              String headerTitle = DateFormat(
                                'dd MMM yyyy, EEE',
                              ).format(dateObj);
                              if (dateObj.year == now.year &&
                                  dateObj.month == now.month &&
                                  dateObj.day == now.day) {
                                headerTitle =
                                    'Today, ${DateFormat('dd MMM yyyy').format(dateObj)}';
                              } else if (dateObj.year == now.year &&
                                  dateObj.month == now.month &&
                                  dateObj.day == now.day - 1) {
                                headerTitle =
                                    'Yesterday, ${DateFormat('dd MMM yyyy').format(dateObj)}';
                              }

                              final dailyTotal = dailyTxs.fold<int>(
                                0,
                                (sum, tx) =>
                                    sum +
                                            (tx.type == 'expense'
                                                ? -tx.amount
                                                : tx.amount)
                                        as int,
                              );

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          headerTitle,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withValues(alpha: 0.6),
                                            fontSize: 14,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            Text(
                                              currencyFormat.format(
                                                dailyTotal.abs(),
                                              ),
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onSurface,
                                                fontSize: 14,
                                              ),
                                            ),
                                            SizedBox(width: 4),
                                            Icon(
                                              Icons.expand_more_rounded,
                                              size: 16,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withValues(alpha: 0.6),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).cardColor,
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(color: const Color(0xFFE8F0EC), width: 1),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.04),
                                          blurRadius: 16,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: dailyTxs.asMap().entries.map((
                                        entry,
                                      ) {
                                        final tx = entry.value;
                                        final isIncome = tx.type == 'income';
                                         return Column(
                                            children: [
                                              GestureDetector(
                                                onTap: () => _showTransactionDetail(context, tx, currencyFormat),
                                                child: ListTile(
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 0,
                                                  ),
                                              leading: Container(
                                                width: 48,
                                                height: 48,
                                                decoration: BoxDecoration(
                                                  color: _getCategoryColor(
                                                    tx.categoryId,
                                                  ).withValues(alpha: 0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                ),
                                                child: Icon(
                                                  _getCategoryIcon(
                                                    tx.categoryId,
                                                  ),
                                                  color: _getCategoryColor(
                                                    tx.categoryId,
                                                  ),
                                                ),
                                              ),
                                              title: Text(
                                                tx.description ??
                                                    tx.categoryId ??
                                                    'General',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 15,
                                                  color: Theme.of(
                                                    context,
                                                  ).colorScheme.onSurface,
                                                ),
                                              ),
                                              subtitle: Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 4,
                                                ),
                                                child: Row(
                                                  children: [
                                                    Text(
                                                      tx.categoryId ??
                                                          'General',
                                                      style: TextStyle(
                                                        color: Colors
                                                            .grey
                                                            .shade500,
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 6,
                                                          ),
                                                      child: CircleAvatar(
                                                        radius: 2,
                                                        backgroundColor: Colors
                                                            .grey
                                                            .shade400,
                                                      ),
                                                    ),
                                                    Expanded(
                                                      child: Text(
                                                        tx.paymentMethod ??
                                                            'Cash',
                                                        style: TextStyle(
                                                          color: Colors
                                                              .grey
                                                              .shade500,
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              trailing: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.end,
                                                children: [
                                                  Text(
                                                    timeFormat.format(
                                                      tx.transactionDate,
                                                    ),
                                                    style: TextStyle(
                                                      color:
                                                          Colors.grey.shade400,
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                  SizedBox(height: 6),
                                                  Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        '${isIncome ? '+' : '-'} ${currencyFormat.format(tx.amount)}',
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.w800,
                                                          fontSize: 15,
                                                          color: isIncome
                                                              ? AppColors
                                                                    .success
                                                              : AppColors.error,
                                                        ),
                                                      ),
                                                      SizedBox(width: 8),
                                                      Icon(
                                                        Icons
                                                            .chevron_right_rounded,
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .onSurface
                                                            .withValues(
                                                              alpha: 0.6,
                                                            ),
                                                        size: 16,
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                              ),
                                              if (entry.key != dailyTxs.length - 1)
                                                Divider(
                                                  height: 1,
                                                  indent: 80,
                                                  endIndent: 16,
                                                  color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.05),
                                                ),
                                            ],
                                          );
                                        }).toList(),
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                ],
                              );
                            }, childCount: sortedDates.length),
                          ),
                        ),
                    ],
                  );
                },
                loading: () => Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                error: (err, stack) => Center(child: Text('Error: $err')),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: GestureDetector(
        onTap: () => TransactionEntrySheet.show(context),
        child: Container(
          width: 60, height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primaryMid, AppColors.primary],
            ),
            boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8))],
          ),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    ));
  }

  void _showTransactionDetail(BuildContext context, dynamic tx, NumberFormat currencyFormat) {
    final isIncome = tx.type == 'income';
    final color = isIncome ? AppColors.success : AppColors.error;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final bgColor = isDark ? AppColors.surfaceDark : Colors.white;
        final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
        final subColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
        return Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
              // Icon + Type pill
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(_getCategoryIcon(tx.categoryId), color: color, size: 32),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isIncome ? 'INCOME' : 'EXPENSE',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color, letterSpacing: 1),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${isIncome ? '+' : '-'} ${currencyFormat.format(tx.amount)}',
                style: TextStyle(fontSize: 40, fontWeight: FontWeight.w800, color: color, letterSpacing: -1),
              ),
              const SizedBox(height: 4),
              Text(
                tx.description ?? tx.categoryId ?? 'Transaction',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
              ),
              const SizedBox(height: 28),
              // Detail rows
              _detailRow(Icons.calendar_today_rounded, 'Date',
                DateFormat('dd MMMM yyyy, hh:mm a').format(tx.transactionDate), textColor, subColor, isDark),
              _detailRow(Icons.category_rounded, 'Category',
                tx.categoryId ?? 'General', textColor, subColor, isDark),
              _detailRow(Icons.account_balance_wallet_rounded, 'Payment Method',
                tx.paymentMethod ?? 'Cash', textColor, subColor, isDark),
              _detailRow(Icons.notes_rounded, 'Note',
                tx.description ?? 'No description', textColor, subColor, isDark),
              const SizedBox(height: 24),
              // Close button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(IconData icon, String label, String value, Color textColor, Color subColor, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: subColor, letterSpacing: 0.5)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFE8F0EC), width: 1.5),
        boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Icon(icon, color: AppColors.primary, size: 18),
    );
  }

  Widget _buildTabPill(String title, int index) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))] : [],
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 13,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterDropdown(
    IconData icon,
    String title,
    List<String> options,
    Function(String) onSelected,
  ) {
    return PopupMenuButton<String>(
      onSelected: onSelected,
      color: Theme.of(context).cardColor,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      itemBuilder: (context) => options
          .map(
            (opt) => PopupMenuItem(
              value: opt,
              child: Text(
                opt,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: opt == title ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          )
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: const Color(0xFFE8F0EC), width: 1.5),
          boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: AppColors.primary),
            SizedBox(width: 7),
            Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down_rounded, size: 15, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCardWithIcon(
    String title,
    String value,
    String trend,
    bool isPositive,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8F0EC), width: 1),
        boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
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

  IconData _getCategoryIcon(String? category) {
    switch (category) {
      case 'Food':
        return Icons.lunch_dining_rounded; // Changed logo
      case 'Housing':
        return Icons.home_rounded;
      case 'Transport':
        return Icons.directions_car_rounded;
      case 'Subscriptions':
        return Icons.music_note_rounded;
      case 'Groceries':
        return Icons.shopping_cart_rounded;
      case 'Income':
        return Icons.account_balance_rounded;
      case 'Salary':
        return Icons.attach_money_rounded;
      case 'Fuel':
        return Icons.local_gas_station_rounded;
      case 'Shopping':
        return Icons.shopping_bag_rounded;
      case 'Bills':
        return Icons.receipt_rounded;
      case 'Entertainment':
        return Icons.movie_rounded;
      case 'Cricket':
        return Icons.sports_cricket_rounded;
      case 'Loan':
        return Icons.account_balance_wallet_rounded;
      default:
        return Icons.category_rounded;
    }
  }
}

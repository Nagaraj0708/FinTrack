import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/services/notification_service.dart';
import '../../domain/entities/transaction.dart';
import '../../../../app/theme/colors.dart';

class TransactionEntrySheet extends ConsumerStatefulWidget {
  final String initialType;
  const TransactionEntrySheet({super.key, this.initialType = 'expense'});

  @override
  ConsumerState<TransactionEntrySheet> createState() =>
      _TransactionEntrySheetState();

  static void show(BuildContext context, {String initialType = 'expense'}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (context) => TransactionEntrySheet(initialType: initialType),
    );
  }
}

class _TransactionEntrySheetState extends ConsumerState<TransactionEntrySheet> {
  String _amountString = '';
  late String _transactionType;
  String _selectedCategory = 'General';
  String _selectedPaymentMethod = 'Cash';
  String _selectedIncomeSource = 'Salary'; // Only shown for income
  final TextEditingController _noteController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _transactionType = widget.initialType;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _showPicker(
    String title,
    List<String> options,
    String currentValue,
    Function(String) onSelected,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: options.length,
                  separatorBuilder: (context, index) => Divider(height: 1, indent: 24, endIndent: 24, color: Colors.grey.withValues(alpha: 0.08)),
                  itemBuilder: (context, index) {
                    final option = options[index];
                    final isSelected = option == currentValue;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                      title: Text(
                        option,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? AppColors.primary : AppColors.textPrimary,
                          fontSize: 15,
                        ),
                      ),
                      trailing: isSelected
                          ? Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppColors.primary, shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check_rounded, color: Colors.white, size: 14),
                            )
                          : null,
                      onTap: () { onSelected(option); Navigator.pop(context); },
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _onKeypadTap(String value) {
    HapticFeedback.lightImpact();
    setState(() {
      if (value == '⌫') {
        if (_amountString.isNotEmpty) {
          _amountString = _amountString.substring(0, _amountString.length - 1);
        }
      } else {
        if (value == '.' && _amountString.contains('.')) return;
        if (value == '.' && _amountString.isEmpty) {
          _amountString = '0.';
          return;
        }
        final parts = _amountString.split('.');
        if (parts.length == 2 && parts[1].length >= 2 && value != '⌫') return;
        if (_amountString == '0' && value != '.') {
          _amountString = value;
        } else {
          _amountString += value;
        }
      }
    });
  }

  Future<void> _saveTransaction() async {
    final amount = double.tryParse(_amountString) ?? 0;
    if (amount <= 0) return;

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    final repo = ref.read(transactionRepositoryProvider);
    final newTx = Transaction(
      id: const Uuid().v4(),
      userId: 'default_user',
      accountId: 'default_account',
      type: _transactionType,
      amount: amount.toInt(),
      categoryId: _transactionType == 'income' ? _selectedIncomeSource : _selectedCategory,
      paymentMethod: _selectedPaymentMethod,
      description: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      transactionDate: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await repo.addTransaction(newTx);
      ref.invalidate(transactionRepositoryProvider);
      // Fire push notification for large transactions
      unawaited(
        notificationService.notifyLargeTransaction(
          description: newTx.description ?? newTx.categoryId ?? 'Transaction',
          amount: newTx.amount,
          isExpense: _transactionType == 'expense',
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to save: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final keyboardOpen = mediaQuery.viewInsets.bottom > 50;
    final isExpense = _transactionType == 'expense';
    final accentColor = isExpense ? AppColors.error : AppColors.success;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: Container(
        margin: EdgeInsets.only(top: mediaQuery.padding.top + 40),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 40,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ─── Drag handle ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Container(
                  width: 48, height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),

            // ─── Scrollable content (hides when keyboard is open) ────────
            if (!keyboardOpen) ...[
              const SizedBox(height: 12),

              // Type toggle
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _TypeButton(
                      title: 'Expense',
                      isSelected: _transactionType == 'expense',
                      activeColor: AppColors.error,
                      onTap: () => setState(() => _transactionType = 'expense'),
                    ),
                    _TypeButton(
                      title: 'Income',
                      isSelected: _transactionType == 'income',
                      activeColor: AppColors.success,
                      onTap: () => setState(() => _transactionType = 'income'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ─── Amount display ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '₹',
                      style: theme.textTheme.displayLarge?.copyWith(
                        fontSize: 40,
                        fontWeight: FontWeight.w400,
                        color: accentColor.withValues(alpha: 0.55),
                      ),
                    ),
                    const SizedBox(width: 4),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 150),
                      child: Text(
                        _amountString.isEmpty ? '0' : _amountString,
                        key: ValueKey(_amountString),
                        style: theme.textTheme.displayLarge?.copyWith(
                          fontSize: 54,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -2,
                          color: accentColor,
                        ),
                      ),
                    ),
                    AnimatedOpacity(
                      opacity: _amountString.isEmpty ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 150),
                      child: Container(
                        width: 3, height: 52,
                        margin: const EdgeInsets.only(left: 2),
                        decoration: BoxDecoration(
                          color: accentColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ─── Category + Payment Row ───────────────────────────────────
            if (isExpense)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: _CategorySelector(
                        icon: Icons.category_rounded,
                        label: _selectedCategory,
                        onTap: () => _showPicker(
                          'Select Category',
                          ['Food', 'Transport', 'Shopping', 'Bills', 'Entertainment', 'Salary', 'General', 'Cricket', 'Loan'],
                          _selectedCategory,
                          (val) => setState(() => _selectedCategory = val),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _CategorySelector(
                        icon: Icons.account_balance_wallet_rounded,
                        label: _selectedPaymentMethod,
                        onTap: () => _showPicker(
                          'Payment Method',
                          ['Cash', 'UPI (GPay/PhonePe)', 'Credit Card', 'Bank Transfer'],
                          _selectedPaymentMethod,
                          (val) => setState(() => _selectedPaymentMethod = val),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // ─── Income Source Row (Income only) ──────────────────────────
            if (!isExpense)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _CategorySelector(
                  icon: Icons.trending_up_rounded,
                  label: _selectedIncomeSource,
                  onTap: () => _showPicker(
                    'Income Source',
                    ['Salary', 'Freelance', 'Business', 'Rent', 'Investment', 'Gift', 'Dividend', 'Other'],
                    _selectedIncomeSource,
                    (val) => setState(() => _selectedIncomeSource = val),
                  ),
                ),
              ),
            const SizedBox(height: 12),

            // ─── Note Field ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE8F0EC), width: 1.5),
                ),
                child: TextField(
                  controller: _noteController,
                  style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    icon: const Icon(Icons.notes_rounded, color: AppColors.primary, size: 18),
                    border: InputBorder.none,
                    hintText: 'Add a note (e.g. Petrol, Groceries)',
                    hintStyle: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.6), fontWeight: FontWeight.w400, fontSize: 14),
                  ),
                  onTapOutside: (_) => FocusScope.of(context).unfocus(),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // ─── Keypad (hidden when keyboard is visible) ────────────────
            if (!keyboardOpen) ...[
              _NumericKeypad(onTap: _onKeypadTap),
              const SizedBox(height: 10),
            ],

            // ─── Save Button ─────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(
                24, 4, 24,
                keyboardOpen
                    ? mediaQuery.viewInsets.bottom + 16
                    : mediaQuery.padding.bottom + 16,
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [accentColor.withValues(alpha: 0.85), accentColor],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 7),
                      ),
                    ],
                  ),
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    onPressed: _isSaving ? null : _saveTransaction,
                    child: _isSaving
                        ? const SizedBox(
                            height: 22, width: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isExpense ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                                color: Colors.white, size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Save Transaction',
                                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

// ─── Type toggle button ───────────────────────────────────────────────────────
class _TypeButton extends StatelessWidget {
  final String title;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;

  const _TypeButton({
    required this.title,
    required this.isSelected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 11),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2))]
              : [],
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? activeColor : Colors.grey.shade500,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

// ─── Category / Payment selector ─────────────────────────────────────────────
class _CategorySelector extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _CategorySelector({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8F0EC), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.expand_more_rounded, size: 16, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

// ─── Numeric keypad ───────────────────────────────────────────────────────────
class _NumericKeypad extends StatelessWidget {
  final Function(String) onTap;
  const _NumericKeypad({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildRow(context, ['1', '2', '3']),
          const SizedBox(height: 4),
          _buildRow(context, ['4', '5', '6']),
          const SizedBox(height: 4),
          _buildRow(context, ['7', '8', '9']),
          const SizedBox(height: 4),
          _buildRow(context, ['.', '0', '⌫']),
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, List<String> keys) {
    return Row(
      children: keys.map((key) {
        final isDelete = key == '⌫';
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onTap(key),
                borderRadius: BorderRadius.circular(14),
                splashColor: AppColors.primary.withValues(alpha: 0.08),
                highlightColor: AppColors.primary.withValues(alpha: 0.04),
                child: Container(
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isDelete
                        ? AppColors.error.withValues(alpha: 0.06)
                        : AppColors.primary.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: isDelete
                      ? Icon(Icons.backspace_outlined, size: 20, color: AppColors.error.withValues(alpha: 0.7))
                      : Text(
                          key,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

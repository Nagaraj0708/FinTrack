import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/colors.dart';
import '../../../../core/database/database.dart';
import '../../../../core/providers/settings_provider.dart';
import '../providers/payment_provider.dart';
import 'scan_pay_page.dart' show PaymentResultPage;

class SendMoneyPage extends ConsumerStatefulWidget {
  final String? prefillVpa;
  final String? prefillName;

  const SendMoneyPage({super.key, this.prefillVpa, this.prefillName});

  @override
  ConsumerState<SendMoneyPage> createState() => _SendMoneyPageState();
}

class _SendMoneyPageState extends ConsumerState<SendMoneyPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _upiCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();

  String? _selectedContactVpa;
  String? _selectedContactName;
  bool _isValidating = false;
  bool? _isVpaValid;
  final String _contactQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    if (widget.prefillVpa != null) {
      _upiCtrl.text = widget.prefillVpa!;
      _selectedContactVpa = widget.prefillVpa;
      _selectedContactName = widget.prefillName;
      _tabController.animateTo(0);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _upiCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    _mobileCtrl.dispose();
    super.dispose();
  }

  Future<void> _validateVpa(String vpa) async {
    if (!vpa.contains('@')) {
      setState(() { _isValidating = false; _isVpaValid = null; });
      return;
    }
    setState(() { _isValidating = true; _isVpaValid = null; });
    final provider = ref.read(paymentProviderInstanceProvider);
    final valid = await provider.validatePayee(vpa);
    if (mounted) setState(() { _isValidating = false; _isVpaValid = valid; });
  }

  void _selectContact(String name, String? vpa) {
    setState(() {
      _selectedContactName = name;
      _selectedContactVpa = vpa;
      _upiCtrl.text = vpa ?? '';
      _isVpaValid = vpa != null;
    });
    _tabController.animateTo(0);
  }

  Future<void> _proceedToReview() async {
    final vpa = _selectedContactVpa ?? _upiCtrl.text.trim();
    final amtStr = _amountCtrl.text.trim();
    if (vpa.isEmpty || !vpa.contains('@')) {
      _snack('Please enter a valid UPI ID');
      return;
    }
    final amt = int.tryParse(amtStr);
    if (amt == null || amt <= 0) {
      _snack('Please enter a valid amount');
      return;
    }
    _showReviewSheet(vpa: vpa, amount: amt);
  }

  void _showReviewSheet({required String vpa, required int amount}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ReviewSheet(
        recipientName: _selectedContactName ?? vpa.split('@').first,
        recipientVpa: vpa,
        amount: amount,
        note: _noteCtrl.text,
        onConfirm: () async {
          Navigator.pop(ctx);
          final userId = ref.read(settingsProvider).userEmail;
          await ref.read(paymentActionProvider.notifier).executePayment(
            userId: userId,
            payeeVpa: vpa,
            amount: amount,
            description: _noteCtrl.text.isEmpty ? null : _noteCtrl.text,
            merchantName: _selectedContactName,
          );
          if (mounted) {
            final state = ref.read(paymentActionProvider);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => PaymentResultPage(
                  isSuccess: state.status == PaymentActionStatus.success,
                  message: state.message ?? '',
                  transactionId: state.transactionId,
                ),
              ),
            );
          }
        },
      ),
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(settingsProvider).userEmail;
    final actionState = ref.watch(paymentActionProvider);
    final isLoading = actionState.status == PaymentActionStatus.loading;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Send Money', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20)),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF9AE6B4),
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [
            Tab(text: 'UPI ID'),
            Tab(text: 'Mobile'),
            Tab(text: 'Bank A/c'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildUpiTab(userId),
                _buildMobileTab(userId),
                _buildBankTab(),
              ],
            ),
          ),
          _buildPayButton(isLoading),
        ],
      ),
    );
  }

  Widget _buildUpiTab(String userId) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // UPI ID field
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Enter UPI ID', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textPrimary)),
              const SizedBox(height: 14),
              TextField(
                controller: _upiCtrl,
                onChanged: (v) {
                  setState(() { _selectedContactVpa = v; _isVpaValid = null; });
                  if (v.contains('@')) {
                    Future.delayed(const Duration(milliseconds: 600), () {
                      if (_upiCtrl.text == v) _validateVpa(v);
                    });
                  }
                },
                decoration: InputDecoration(
                  hintText: 'username@upi',
                  prefixIcon: const Icon(Icons.alternate_email_rounded, color: AppColors.primary),
                  suffixIcon: _isValidating
                      ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)))
                      : _isVpaValid == null
                          ? null
                          : Icon(
                              _isVpaValid! ? Icons.check_circle_rounded : Icons.cancel_rounded,
                              color: _isVpaValid! ? AppColors.success : AppColors.error,
                            ),
                  filled: true,
                  fillColor: const Color(0xFFF5F7F5),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                ),
              ),
              if (_isVpaValid == true) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.verified_user_rounded, color: AppColors.success, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      '${_selectedContactName ?? _upiCtrl.text.split('@').first} — Verified',
                      style: const TextStyle(color: AppColors.success, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
              if (_isVpaValid == false) ...[
                const SizedBox(height: 8),
                const Text('UPI ID not found. Check and retry.', style: TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Amount field
        _AmountField(controller: _amountCtrl, noteController: _noteCtrl),
        const SizedBox(height: 20),

        // Recent contacts
        _ContactsSection(userId: userId, onSelect: _selectContact, query: _contactQuery),
      ],
    );
  }

  Widget _buildMobileTab(String userId) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 16)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Mobile Number', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textPrimary)),
              const SizedBox(height: 14),
              TextField(
                controller: _mobileCtrl,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                onChanged: (v) {
                  if (v.length == 10) {
                    setState(() {
                      _selectedContactVpa = '$v@ybl';
                      _selectedContactName = v;
                    });
                  }
                },
                decoration: InputDecoration(
                  hintText: '10-digit mobile number',
                  prefixText: '+91  ',
                  prefixStyle: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  prefixIcon: const Icon(Icons.phone_rounded, color: AppColors.primary),
                  counterText: '',
                  filled: true,
                  fillColor: const Color(0xFFF5F7F5),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                ),
              ),
              if (_mobileCtrl.text.length == 10) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.account_circle_rounded, color: AppColors.success, size: 28),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('User Found', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w800, fontSize: 13)),
                          Text('UPI: ${_mobileCtrl.text}@ybl', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        _AmountField(controller: _amountCtrl, noteController: _noteCtrl),
      ],
    );
  }

  Widget _buildBankTab() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.account_balance_rounded, size: 64, color: AppColors.primary),
            SizedBox(height: 16),
            Text('Bank Transfer', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            SizedBox(height: 8),
            Text('Add a bank account from the Bank A/c section to enable NEFT/IMPS transfers.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildPayButton(bool isLoading) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: FilledButton(
          onPressed: isLoading ? null : _proceedToReview,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: isLoading
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
              : const Text('Review & Pay', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        ),
      ),
    );
  }
}

// ── Amount Field Widget ──────────────────────────────────────────────────

class _AmountField extends StatelessWidget {
  final TextEditingController controller;
  final TextEditingController noteController;

  const _AmountField({required this.controller, required this.noteController});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 16)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Amount', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textPrimary)),
          const SizedBox(height: 14),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
            decoration: const InputDecoration(
              hintText: '0',
              hintStyle: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Color(0xFFCBD5E1)),
              prefixText: '₹  ',
              prefixStyle: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
              border: InputBorder.none,
            ),
          ),
          const Divider(),
          const SizedBox(height: 8),
          TextField(
            controller: noteController,
            decoration: const InputDecoration(
              hintText: 'Add a remark (optional)',
              hintStyle: TextStyle(color: AppColors.textSecondary),
              prefixIcon: Icon(Icons.note_rounded, color: AppColors.textSecondary),
              border: InputBorder.none,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Contacts Section ─────────────────────────────────────────────────────

class _ContactsSection extends ConsumerStatefulWidget {
  final String userId;
  final void Function(String name, String? vpa) onSelect;
  final String query;

  const _ContactsSection({required this.userId, required this.onSelect, required this.query});

  @override
  ConsumerState<_ContactsSection> createState() => _ContactsSectionState();
}

class _ContactsSectionState extends ConsumerState<_ContactsSection> {
  final _searchCtrl = TextEditingController();
  String _q = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bensAsync = ref.watch(beneficiariesStreamProvider(widget.userId));
    final paymentsAsync = ref.watch(recentPaymentsStreamProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchCtrl,
          onChanged: (v) => setState(() => _q = v.toLowerCase()),
          decoration: InputDecoration(
            hintText: 'Search contacts...',
            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Recent Contacts', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
        const SizedBox(height: 10),
        bensAsync.when(
          data: (bens) {
            final filtered = _q.isEmpty ? bens : bens.where((b) => b.name.toLowerCase().contains(_q) || (b.vpa?.toLowerCase().contains(_q) ?? false)).toList();
            if (filtered.isEmpty) return const Text('No contacts found', style: TextStyle(color: AppColors.textSecondary));
            return Column(
              children: filtered.map((b) => _BeneficiaryRow(
                name: b.name,
                vpa: b.vpa ?? '',
                onTap: () => widget.onSelect(b.name, b.vpa),
              )).toList(),
            );
          },
          loading: () => const LinearProgressIndicator(color: AppColors.primary),
          error: (_, _) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 16),
        const Text('Recent Payments', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
        const SizedBox(height: 10),
        paymentsAsync.when(
          data: (payments) {
            final unique = <String, PaymentTransactionRecord>{};
            for (final p in payments) {
              final key = p.payeeVpa ?? '';
              if (key.isNotEmpty && !unique.containsKey(key)) unique[key] = p;
            }
            final filtered = unique.values.where((p) {
              if (_q.isEmpty) return true;
              final name = p.merchantName ?? p.payeeVpa ?? '';
              return name.toLowerCase().contains(_q) || (p.payeeVpa?.toLowerCase().contains(_q) ?? false);
            }).take(5).toList();
            if (filtered.isEmpty) return const Text('No recent payments', style: TextStyle(color: AppColors.textSecondary));
            return Column(
              children: filtered.map((p) {
                final name = p.merchantName ?? p.payeeVpa?.split('@').first ?? 'Unknown';
                return _BeneficiaryRow(
                  name: name,
                  vpa: p.payeeVpa ?? '',
                  trailing: '₹${NumberFormat.compact().format(p.amount)}',
                  onTap: () => widget.onSelect(name, p.payeeVpa),
                );
              }).toList(),
            );
          },
          loading: () => const LinearProgressIndicator(color: AppColors.primary),
          error: (_, _) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _BeneficiaryRow extends StatelessWidget {
  final String name;
  final String vpa;
  final String? trailing;
  final VoidCallback onTap;

  const _BeneficiaryRow({required this.name, required this.vpa, this.trailing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = [const Color(0xFF2196F3), const Color(0xFF9C27B0), const Color(0xFF00BCD4), const Color(0xFF4CAF50), const Color(0xFFFF7043)];
    final color = name.isNotEmpty ? colors[name.codeUnitAt(0) % colors.length] : colors[0];
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: color.withValues(alpha: 0.12),
              child: Text(initial, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 16)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary)),
                  if (vpa.isNotEmpty)
                    Text(vpa, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            if (trailing != null)
              Text(trailing!, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

// ── Review Sheet ─────────────────────────────────────────────────────────

class _ReviewSheet extends ConsumerWidget {
  final String recipientName;
  final String recipientVpa;
  final int amount;
  final String note;
  final VoidCallback onConfirm;

  const _ReviewSheet({
    required this.recipientName,
    required this.recipientVpa,
    required this.amount,
    required this.note,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final actionState = ref.watch(paymentActionProvider);
    final isLoading = actionState.status == PaymentActionStatus.loading;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 24),
          const Text('Confirm Payment', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7F5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                _ReviewRow(label: 'Paying to', value: recipientName),
                const Divider(height: 20),
                _ReviewRow(label: 'UPI ID', value: recipientVpa),
                const Divider(height: 20),
                _ReviewRow(
                  label: 'Amount',
                  value: fmt.format(amount),
                  valueStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.primary),
                ),
                if (note.isNotEmpty) ...[
                  const Divider(height: 20),
                  _ReviewRow(label: 'Note', value: note),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF9C4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, color: Color(0xFFBF9000), size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Sandbox mode: No real money will be transferred.',
                    style: TextStyle(color: Color(0xFF5D4037), fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton(
              onPressed: isLoading ? null : onConfirm,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: isLoading
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : Text('Pay ${fmt.format(amount)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? valueStyle;

  const _ReviewRow({required this.label, required this.value, this.valueStyle});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
        Flexible(
          child: Text(
            value,
            style: valueStyle ?? const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

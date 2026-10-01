import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/colors.dart';
import '../../../../core/database/database.dart';
import '../providers/payment_provider.dart';

class BankAccountsPage extends ConsumerWidget {
  final String userId;
  const BankAccountsPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(bankAccountsStreamProvider(userId));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Bank Accounts', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
            onPressed: () => _showAddAccountSheet(context, ref),
          ),
        ],
      ),
      body: accountsAsync.when(
        data: (accounts) {
          if (accounts.isEmpty) {
            return _buildEmptyState(context, ref);
          }
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildInfoBanner(),
              const SizedBox(height: 20),
              ...accounts.map((a) => _BankCard(
                account: a,
                onSetDefault: () {
                  ref.read(paymentRepositoryProvider).setDefaultBankAccount(userId, a.id);
                },
                onDelete: () => _confirmDelete(context, ref, a),
              )),
              const SizedBox(height: 20),
              _buildAddMoreButton(context, ref),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.security_rounded, color: AppColors.success, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your bank details are stored securely on-device. No passwords or PINs are stored.',
              style: TextStyle(color: Color(0xFF1B5E20), fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.07),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.account_balance_rounded, size: 64, color: AppColors.primary),
            ),
            const SizedBox(height: 24),
            const Text('No Bank Accounts', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(height: 10),
            const Text(
              'Add your bank account to enable payments and transfers.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: () => _showAddAccountSheet(context, ref),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Bank Account', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddMoreButton(BuildContext context, WidgetRef ref) {
    return OutlinedButton.icon(
      onPressed: () => _showAddAccountSheet(context, ref),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColors.primary, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      icon: const Icon(Icons.add_rounded, color: AppColors.primary),
      label: const Text('Add Another Account', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 15)),
    );
  }

  void _showAddAccountSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddAccountSheet(
        onAdd: (bankName, maskedNum, ifsc, setDefault) async {
          await ref.read(paymentRepositoryProvider).addBankAccount(
            userId: userId,
            bankName: bankName,
            maskedAccountNumber: maskedNum,
            ifsc: ifsc,
            setAsDefault: setDefault,
          );
          if (ctx.mounted) Navigator.pop(ctx);
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, BankAccountData account) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Remove Account', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text('Remove ${account.bankName} ending in ${account.maskedAccountNumber}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              await ref.read(paymentRepositoryProvider).removeBankAccount(account.id);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

// ── Bank Card ─────────────────────────────────────────────────────────────

class _BankCard extends StatelessWidget {
  final BankAccountData account;
  final VoidCallback onSetDefault;
  final VoidCallback onDelete;

  const _BankCard({required this.account, required this.onSetDefault, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final bankColors = _bankColor(account.bankName);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 6)),
        ],
        border: account.isDefault
            ? Border.all(color: AppColors.primary, width: 1.5)
            : Border.all(color: Colors.transparent),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: bankColors),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      account.bankName.isNotEmpty ? account.bankName[0].toUpperCase() : 'B',
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(account.bankName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                      Text(
                        '•••• •••• ${account.maskedAccountNumber}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, letterSpacing: 1.5),
                      ),
                    ],
                  ),
                ),
                if (account.isDefault)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('DEFAULT', style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                  ),
              ],
            ),
            if (account.ifsc != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.code_rounded, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text('IFSC: ${account.ifsc}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                if (!account.isDefault)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onSetDefault,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: const Text('Set Default', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                  ),
                if (!account.isDefault) const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDelete,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.error.withValues(alpha: 0.4)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 16),
                    label: const Text('Remove', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Color> _bankColor(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('hdfc')) return [const Color(0xFF1565C0), const Color(0xFF0D47A1)];
    if (lower.contains('sbi')) return [const Color(0xFF1B5E20), const Color(0xFF388E3C)];
    if (lower.contains('icici')) return [const Color(0xFFBF360C), const Color(0xFF6D4C41)];
    if (lower.contains('axis')) return [const Color(0xFF4A148C), const Color(0xFF7B1FA2)];
    if (lower.contains('kotak')) return [const Color(0xFFF57F17), const Color(0xFFE65100)];
    return [const Color(0xFF1C4532), const Color(0xFF2D6A4F)];
  }
}

// ── Add Account Sheet ────────────────────────────────────────────────────

class _AddAccountSheet extends StatefulWidget {
  final Future<void> Function(String bankName, String maskedNum, String? ifsc, bool setDefault) onAdd;

  const _AddAccountSheet({required this.onAdd});

  @override
  State<_AddAccountSheet> createState() => _AddAccountSheetState();
}

class _AddAccountSheetState extends State<_AddAccountSheet> {
  final _bankCtrl = TextEditingController();
  final _acnCtrl = TextEditingController();
  final _ifscCtrl = TextEditingController();
  bool _setDefault = true;
  bool _isAdding = false;

  final _banks = ['HDFC Bank', 'State Bank of India', 'ICICI Bank', 'Axis Bank', 'Kotak Mahindra Bank', 'Punjab National Bank', 'Bank of Baroda', 'Canara Bank', 'Union Bank of India', 'YES Bank', 'Other'];
  String? _selectedBank;

  @override
  void dispose() {
    _bankCtrl.dispose();
    _acnCtrl.dispose();
    _ifscCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            const Text('Add Bank Account', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            const Text(
              'Enter your account details. No passwords or PINs required.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              initialValue: _selectedBank,
              hint: const Text('Select Bank'),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.account_balance_rounded, color: AppColors.primary),
                filled: true,
                fillColor: const Color(0xFFF5F7F5),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
              items: _banks.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
              onChanged: (v) {
                setState(() {
                  _selectedBank = v;
                  if (v != 'Other') _bankCtrl.text = v ?? '';
                });
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _acnCtrl,
              keyboardType: TextInputType.number,
              maxLength: 18,
              decoration: InputDecoration(
                hintText: 'Last 4 digits of account number',
                prefixIcon: const Icon(Icons.credit_card_rounded, color: AppColors.primary),
                counterText: '',
                filled: true,
                fillColor: const Color(0xFFF5F7F5),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ifscCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: 'IFSC Code (optional)',
                prefixIcon: const Icon(Icons.tag_rounded, color: AppColors.primary),
                filled: true,
                fillColor: const Color(0xFFF5F7F5),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Set as default payment account', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary)),
                Switch(value: _setDefault, onChanged: (v) => setState(() => _setDefault = v), activeThumbColor: AppColors.primary),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton(
                onPressed: _isAdding
                    ? null
                    : () async {
                        final bank = _selectedBank ?? _bankCtrl.text.trim();
                        final acn = _acnCtrl.text.trim();
                        if (bank.isEmpty || acn.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please fill in required fields')),
                          );
                          return;
                        }
                        setState(() => _isAdding = true);
                        await widget.onAdd(bank, acn.length > 4 ? acn.substring(acn.length - 4) : acn, _ifscCtrl.text.isEmpty ? null : _ifscCtrl.text.trim(), _setDefault);
                      },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isAdding
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : const Text('Add Account', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

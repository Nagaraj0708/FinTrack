import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/colors.dart';
import '../../../../core/database/database.dart';
import '../../../../core/providers/settings_provider.dart';
import '../providers/payment_provider.dart';
import 'send_money_page.dart';
import 'bank_accounts_page.dart';
import 'scan_pay_page.dart';

class PayDashboardPage extends ConsumerStatefulWidget {
  const PayDashboardPage({super.key});

  @override
  ConsumerState<PayDashboardPage> createState() => _PayDashboardPageState();
}

class _PayDashboardPageState extends ConsumerState<PayDashboardPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _cardController;
  late Animation<double> _cardAnimation;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _cardAnimation = CurvedAnimation(
      parent: _cardController,
      curve: Curves.easeOutBack,
    );
    _cardController.forward();
  }

  @override
  void dispose() {
    _cardController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final userId = settings.userEmail;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.backgroundDark : const Color(0xFFF5F7F5);

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(context, isDark, userId),
          SliverToBoxAdapter(child: _buildBody(context, isDark, userId, settings)),
          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, bool isDark, String userId) {
    final upiAsync = ref.watch(upiProfileProvider(userId));
    return SliverAppBar(
      backgroundColor: AppColors.primary,
      expandedHeight: 0,
      floating: true,
      snap: true,
      pinned: true,
      elevation: 0,
      title: const Row(
        children: [
          Text(
            'Fin',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          Text(
            'Pay',
            style: TextStyle(
              color: Color(0xFF9AE6B4),
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search_rounded, color: Colors.white, size: 26),
          onPressed: () => _openSearchSheet(context, ref.read(settingsProvider).userEmail),
        ),
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 24),
          onPressed: () {},
        ),
        upiAsync.when(
          data: (profile) => GestureDetector(
            onTap: () => _showUpiDetails(context, profile),
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.qr_code_2_rounded, color: Colors.white, size: 22),
              ),
            ),
          ),
          loading: () => const Padding(
            padding: EdgeInsets.only(right: 12),
            child: SizedBox(width: 38, height: 38),
          ),
          error: (_, _) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, bool isDark, String userId, SettingsState settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PaymentAccountCard(animation: _cardAnimation, userId: userId),
        const SizedBox(height: 24),
        _QuickActionsRow(onScanTap: _onScanTap, onSendTap: _onSendTap, onRequestTap: _onRequestTap, onBankTap: _onBankTap),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _UpiIdCard(userId: userId),
        ),
        const SizedBox(height: 24),
        _RecentPaymentsSection(),
      ],
    );
  }

  void _onScanTap() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ScanPayPage()));
  }

  void _onSendTap() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SendMoneyPage()));
  }

  void _onRequestTap() {
    _showRequestSheet(context);
  }

  void _onBankTap() {
    final userId = ref.read(settingsProvider).userEmail;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => BankAccountsPage(userId: userId)));
  }

  void _openSearchSheet(BuildContext context, String userId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SearchSheet(userId: userId),
    );
  }

  void _showUpiDetails(BuildContext context, UpiProfileData? profile) {
    final vpa = profile?.vpa ?? 'demo@okfintrack';
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.qr_code_2_rounded, size: 64, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text(vpa, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            const Text('Your UPI ID (Sandbox)', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _ActionChip(
                    icon: Icons.copy_rounded,
                    label: 'Copy',
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: vpa));
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('UPI ID copied!')),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionChip(
                    icon: Icons.share_rounded,
                    label: 'Share',
                    onTap: () => Navigator.pop(ctx),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showRequestSheet(BuildContext context) {
    final upiCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              const Text('Request Money', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              const SizedBox(height: 20),
              TextField(
                controller: upiCtrl,
                decoration: _inputDecoration('UPI ID or Mobile Number', Icons.person_search_rounded),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration('Amount (₹)', Icons.currency_rupee_rounded),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Payment request sent (Sandbox)')),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Send Request', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.textSecondary),
      filled: true,
      fillColor: const Color(0xFFF5F7F5),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary)),
    );
  }
}

// ── Payment Account Card ─────────────────────────────────────────────────

class _PaymentAccountCard extends ConsumerWidget {
  final Animation<double> animation;
  final String userId;

  const _PaymentAccountCard({required this.animation, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bankAsync = ref.watch(defaultBankAccountProvider(userId));
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) => Transform.scale(
        scale: animation.value.clamp(0.0, 1.0),
        child: child,
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        height: 190,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A3A2A), Color(0xFF0F2419), Color(0xFF1C4532)],
            stops: [0.0, 0.5, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1C4532).withValues(alpha: 0.45),
              blurRadius: 32,
              offset: const Offset(0, 14),
              spreadRadius: -4,
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative orb top right
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.04),
                ),
              ),
            ),
            Positioned(
              bottom: -40,
              left: -20,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.03),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Payment Account',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF9AE6B4).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF9AE6B4).withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.circle, size: 7, color: Color(0xFF9AE6B4)),
                            SizedBox(width: 5),
                            Text(
                              'SANDBOX',
                              style: TextStyle(
                                color: Color(0xFF9AE6B4),
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  bankAsync.when(
                    data: (bank) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bank != null ? bank.bankName : 'No Bank Linked',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          bank != null ? '•••• •••• ${bank.maskedAccountNumber}' : 'Add a bank account to pay',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                    loading: () => const Text('Loading...', style: TextStyle(color: Colors.white)),
                    error: (_, _) => const Text('HDFC Bank', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      const Icon(Icons.verified_rounded, color: Color(0xFF9AE6B4), size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Verified & Secure',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.contactless_rounded, color: Colors.white54, size: 28),
                    ],
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

// ── Quick Actions Row ────────────────────────────────────────────────────

class _QuickActionsRow extends StatelessWidget {
  final VoidCallback onScanTap;
  final VoidCallback onSendTap;
  final VoidCallback onRequestTap;
  final VoidCallback onBankTap;

  const _QuickActionsRow({
    required this.onScanTap,
    required this.onSendTap,
    required this.onRequestTap,
    required this.onBankTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _QuickActionBtn(
              icon: Icons.qr_code_scanner_rounded,
              label: 'Scan & Pay',
              gradient: const LinearGradient(colors: [Color(0xFF2196F3), Color(0xFF1565C0)]),
              onTap: onScanTap,
            ),
            _QuickActionBtn(
              icon: Icons.send_rounded,
              label: 'Send',
              gradient: const LinearGradient(colors: [Color(0xFF00C896), Color(0xFF1C4532)]),
              onTap: onSendTap,
            ),
            _QuickActionBtn(
              icon: Icons.call_received_rounded,
              label: 'Request',
              gradient: const LinearGradient(colors: [Color(0xFF9C27B0), Color(0xFF6A0080)]),
              onTap: onRequestTap,
            ),
            _QuickActionBtn(
              icon: Icons.account_balance_rounded,
              label: 'Bank A/c',
              gradient: const LinearGradient(colors: [Color(0xFFFF7043), Color(0xFFBF360C)]),
              onTap: onBankTap,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Gradient gradient;
  final VoidCallback onTap;

  const _QuickActionBtn({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(gradient: gradient, shape: BoxShape.circle, boxShadow: [
              BoxShadow(
                color: (gradient as LinearGradient).colors.first.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ]),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

// ── UPI ID Card ─────────────────────────────────────────────────────────

class _UpiIdCard extends ConsumerWidget {
  final String userId;
  const _UpiIdCard({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upiAsync = ref.watch(upiProfileProvider(userId));
    final vpa = upiAsync.when(
      data: (profile) => profile?.vpa ?? _generateVpa(userId),
      loading: () => _generateVpa(userId),
      error: (_, _) => _generateVpa(userId),
    );

    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: vpa));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('UPI ID copied!'),
            ]),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1C4532), Color(0xFF2D6A4F)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.qr_code_2_rounded, color: Colors.white, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'My UPI ID',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    vpa,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w800),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.copy_rounded, color: AppColors.primary, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  String _generateVpa(String email) {
    if (email.isEmpty) return 'user@okfintrack';
    final username = email.split('@').first.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
    return '$username@okfintrack';
  }
}

// ── Recent Payments Section ──────────────────────────────────────────────

class _RecentPaymentsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(recentPaymentsStreamProvider);
    final currencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recent Payments', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
              TextButton(
                onPressed: () {},
                child: const Text('View All', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        paymentsAsync.when(
          data: (payments) {
            if (payments.isEmpty) {
              return _buildEmptyPayments();
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: payments.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final p = payments[i];
                return _PaymentTileCard(payment: p, currencyFmt: currencyFmt);
              },
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          ),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ],
    );
  }

  Widget _buildEmptyPayments() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 12)],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.07),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.payment_rounded, size: 48, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          const Text('No payments yet', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text(
            'Scan a QR or send money to\nstart your payment history',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _PaymentTileCard extends StatelessWidget {
  final PaymentTransactionRecord payment;
  final NumberFormat currencyFmt;

  const _PaymentTileCard({required this.payment, required this.currencyFmt});

  @override
  Widget build(BuildContext context) {
    final isCredit = payment.type == 'CREDIT';
    final isFailed = payment.status == 'failed';
    final isPending = payment.status == 'pending' || payment.status == 'processing';

    final statusColor = isFailed
        ? AppColors.error
        : isPending
            ? AppColors.warning
            : AppColors.success;
    final displayName = payment.merchantName ?? payment.payeeVpa ?? 'Unknown';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
    final avatarColor = _colorFromString(displayName);
    final date = DateFormat('d MMM, h:mm a').format(payment.createdAt);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(color: avatarColor.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Center(
              child: Text(initial, style: TextStyle(color: avatarColor, fontSize: 18, fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(displayName, style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(date, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        payment.status.toUpperCase(),
                        style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isCredit ? '+' : '-'}${currencyFmt.format(payment.amount)}',
                style: TextStyle(
                  color: isCredit ? AppColors.success : AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (payment.payeeVpa != null)
                Text(
                  payment.payeeVpa!,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _colorFromString(String s) {
    final colors = [
      const Color(0xFF2196F3), const Color(0xFF9C27B0),
      const Color(0xFFFF7043), const Color(0xFF00BCD4),
      const Color(0xFF4CAF50), const Color(0xFFF44336),
      const Color(0xFFFF9800), const Color(0xFF3F51B5),
    ];
    return colors[s.codeUnitAt(0) % colors.length];
  }
}

// ── Search Sheet ─────────────────────────────────────────────────────────

class _SearchSheet extends ConsumerStatefulWidget {
  final String userId;
  const _SearchSheet({required this.userId});

  @override
  ConsumerState<_SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends ConsumerState<_SearchSheet> {
  final _ctrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final beneficiariesAsync = ref.watch(beneficiariesStreamProvider(widget.userId));
    final paymentsAsync = ref.watch(recentPaymentsStreamProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.all(20),
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search name, UPI ID or mobile...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.close_rounded), onPressed: () { _ctrl.clear(); setState(() => _query = ''); })
                    : null,
                filled: true,
                fillColor: const Color(0xFFF5F7F5),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                if (_query.isEmpty) ...[
                  const _SectionLabel(label: 'Recent Contacts'),
                  beneficiariesAsync.when(
                    data: (bens) => bens.isEmpty
                        ? const Padding(padding: EdgeInsets.all(16), child: Text('No contacts yet', style: TextStyle(color: AppColors.textSecondary)))
                        : Column(
                            children: bens.map((b) => _ContactTileRow(
                              name: b.name,
                              subtitle: b.vpa ?? '',
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => SendMoneyPage(prefillVpa: b.vpa, prefillName: b.name),
                                ));
                              },
                            )).toList(),
                          ),
                    loading: () => const LinearProgressIndicator(),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 16),
                  const _SectionLabel(label: 'Recent Transactions'),
                  paymentsAsync.when(
                    data: (payments) => Column(
                      children: payments.take(5).map((p) {
                        final name = p.merchantName ?? p.payeeVpa ?? 'Unknown';
                        return _ContactTileRow(
                          name: name,
                          subtitle: p.payeeVpa ?? '',
                          trailing: '₹${p.amount}',
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => SendMoneyPage(prefillVpa: p.payeeVpa, prefillName: name),
                            ));
                          },
                        );
                      }).toList(),
                    ),
                    loading: () => const LinearProgressIndicator(),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                ] else ...[
                  const _SectionLabel(label: 'Results'),
                  beneficiariesAsync.when(
                    data: (bens) {
                      final filtered = bens.where((b) =>
                          b.name.toLowerCase().contains(_query) ||
                          (b.vpa?.toLowerCase().contains(_query) ?? false)).toList();
                      if (filtered.isEmpty) return _buildNoResults();
                      return Column(
                        children: filtered.map((b) => _ContactTileRow(
                          name: b.name,
                          subtitle: b.vpa ?? '',
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => SendMoneyPage(prefillVpa: b.vpa, prefillName: b.name),
                            ));
                          },
                        )).toList(),
                      );
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (_, _) => _buildNoResults(),
                  ),
                  // If looks like UPI ID, offer to pay directly
                  if (_query.contains('@') || RegExp(r'^\d{10}$').hasMatch(_query))
                    _DirectPayTile(target: _query, onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => SendMoneyPage(prefillVpa: _query.contains('@') ? _query : null, prefillName: _query),
                      ));
                    }),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return const Padding(
      padding: EdgeInsets.all(20),
      child: Text('No results found.\nTry entering a UPI ID like name@upi', style: TextStyle(color: AppColors.textSecondary)),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
    );
  }
}

class _ContactTileRow extends StatelessWidget {
  final String name;
  final String subtitle;
  final String? trailing;
  final VoidCallback onTap;

  const _ContactTileRow({required this.name, required this.subtitle, this.trailing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final colors = [const Color(0xFF2196F3), const Color(0xFF9C27B0), const Color(0xFF00BCD4), const Color(0xFF4CAF50)];
    final color = colors[name.codeUnitAt(0) % colors.length];

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.1),
        child: Text(initial, style: TextStyle(color: color, fontWeight: FontWeight.w800)),
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
      subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      trailing: trailing != null ? Text(trailing!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)) : const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSecondary),
      onTap: onTap,
    );
  }
}

class _DirectPayTile extends StatelessWidget {
  final String target;
  final VoidCallback onTap;

  const _DirectPayTile({required this.target, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: ListTile(
        leading: const Icon(Icons.send_rounded, color: AppColors.primary),
        title: const Text('Pay directly', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
        subtitle: Text(target, style: const TextStyle(fontSize: 13)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.primary),
        onTap: onTap,
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionChip({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 15)),
          ],
        ),
      ),
    );
  }
}

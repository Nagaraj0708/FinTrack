// ============================================================
// Payment Providers — Riverpod state management for payments
// ============================================================
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../data/repositories/payment_repository.dart';
import '../../../../core/database/database.dart';
import '../../../../core/payments/mock_payment_provider.dart';
import '../../../../core/payments/payment_provider.dart';

// ── Repository Provider ──────────────────────────────────────────────────

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return PaymentRepository(db);
});

// ── PaymentProvider (the PSP boundary) ──────────────────────────────────

final paymentProviderInstanceProvider = Provider<PaymentProvider>((ref) {
  return MockPaymentProvider();
});

// ── Real-time streams ────────────────────────────────────────────────────

final recentPaymentsStreamProvider = StreamProvider<List<PaymentTransactionRecord>>((ref) {
  final repo = ref.watch(paymentRepositoryProvider);
  return repo.watchPaymentTransactions(limit: 30);
});

final bankAccountsStreamProvider =
    StreamProvider.family<List<BankAccountData>, String>((ref, userId) {
  final repo = ref.watch(paymentRepositoryProvider);
  return repo.watchBankAccounts(userId);
});

final beneficiariesStreamProvider =
    StreamProvider.family<List<BeneficiaryData>, String>((ref, userId) {
  final repo = ref.watch(paymentRepositoryProvider);
  return repo.watchBeneficiaries(userId);
});

// ── UPI Profile ──────────────────────────────────────────────────────────

final upiProfileProvider = FutureProvider.family<UpiProfileData?, String>((ref, userId) {
  final repo = ref.watch(paymentRepositoryProvider);
  return repo.getUpiProfile(userId);
});

// ── Default Bank Account ─────────────────────────────────────────────────

final defaultBankAccountProvider =
    FutureProvider.family<BankAccountData?, String>((ref, userId) {
  final repo = ref.watch(paymentRepositoryProvider);
  return repo.getDefaultBankAccount(userId);
});

// ── Payment Action State ──────────────────────────────────────────────────

enum PaymentActionStatus { idle, loading, success, failed, pending }

class PaymentActionState {
  final PaymentActionStatus status;
  final String? message;
  final String? transactionId;

  const PaymentActionState({
    this.status = PaymentActionStatus.idle,
    this.message,
    this.transactionId,
  });

  PaymentActionState copyWith({
    PaymentActionStatus? status,
    String? message,
    String? transactionId,
  }) {
    return PaymentActionState(
      status: status ?? this.status,
      message: message ?? this.message,
      transactionId: transactionId ?? this.transactionId,
    );
  }
}

class PaymentActionNotifier extends Notifier<PaymentActionState> {
  @override
  PaymentActionState build() => const PaymentActionState();

  void reset() => state = const PaymentActionState();

  Future<void> executePayment({
    required String userId,
    required String payeeVpa,
    required int amount,
    String? description,
    String? merchantName,
  }) async {
    state = state.copyWith(status: PaymentActionStatus.loading, message: 'Initiating payment...');

    try {
      final provider = ref.read(paymentProviderInstanceProvider);
      await provider.initialize();

      state = state.copyWith(message: 'Validating payee...');
      final isValid = await provider.validatePayee(payeeVpa);
      if (!isValid) {
        state = state.copyWith(
          status: PaymentActionStatus.failed,
          message: 'Invalid UPI ID. Please check and try again.',
        );
        return;
      }

      state = state.copyWith(message: 'Creating payment intent...');
      final intent = await provider.createPaymentIntent(
        payeeVpa: payeeVpa,
        amount: amount,
        description: description,
      );

      state = state.copyWith(message: 'Processing payment...');
      final txn = await provider.authorizePayment(
        paymentIntentId: intent.id,
        sourceAccountId: 'default',
      );

      // Persist to local DB
      final repo = ref.read(paymentRepositoryProvider);
      final txnId = await repo.insertPaymentTransaction(
        userId: userId,
        paymentIntentId: intent.id,
        paymentProvider: provider.providerId,
        providerTransactionId: txn.providerTransactionId,
        amount: amount,
        type: 'P2P',
        status: txn.status,
        merchantName: merchantName,
        payeeVpa: payeeVpa,
        payerVpa: 'self@okfintrack',
        description: description,
        metadata: '{"isSandbox": true}',
      );

      // Also save as beneficiary for future use
      await repo.addBeneficiary(
        userId: userId,
        name: merchantName ?? payeeVpa.split('@').first,
        vpa: payeeVpa,
      );

      state = state.copyWith(
        status: PaymentActionStatus.success,
        message: 'Payment successful! (Sandbox)',
        transactionId: txnId,
      );
    } catch (e) {
      state = state.copyWith(
        status: PaymentActionStatus.failed,
        message: e.toString(),
      );
    }
  }
}

final paymentActionProvider =
    NotifierProvider<PaymentActionNotifier, PaymentActionState>(PaymentActionNotifier.new);

// ── QR Parse State ────────────────────────────────────────────────────────

class ScannedQrData {
  final String payeeVpa;
  final String merchantName;
  final String? amount;

  const ScannedQrData({
    required this.payeeVpa,
    required this.merchantName,
    this.amount,
  });
}

class QrScanState {
  final bool isScanning;
  final ScannedQrData? data;
  final String? error;

  const QrScanState({this.isScanning = true, this.data, this.error});
}

class QrScanNotifier extends Notifier<QrScanState> {
  @override
  QrScanState build() => const QrScanState();

  void reset() => state = const QrScanState();

  void setError(String error) {
    state = QrScanState(isScanning: false, error: error);
  }

  Future<void> parseQr(String raw) async {
    if (state.data != null) return; // Already parsed
    try {
      final provider = ref.read(paymentProviderInstanceProvider);
      final result = await provider.scanPaymentQr(raw);
      state = QrScanState(
        isScanning: false,
        data: ScannedQrData(
          payeeVpa: result['payeeVpa']!,
          merchantName: result['merchantName'] ?? '',
          amount: result['amount'],
        ),
      );
    } catch (_) {
      // Try plain-text UPI ID
      if (raw.contains('@')) {
        state = QrScanState(
          isScanning: false,
          data: ScannedQrData(
            payeeVpa: raw,
            merchantName: raw.split('@').first,
          ),
        );
      } else {
        state = QrScanState(isScanning: true);
      }
    }
  }
}

final qrScanProvider =
    NotifierProvider<QrScanNotifier, QrScanState>(QrScanNotifier.new);

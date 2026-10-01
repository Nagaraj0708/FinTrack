import 'dart:async';
import 'package:uuid/uuid.dart';
import 'payment_provider.dart';
import '../../features/payments/domain/models/payment_intent.dart';
import '../../features/payments/domain/models/payment_transaction.dart';
import '../../features/payments/domain/models/payment_state.dart';

class MockPaymentProvider implements PaymentProvider {
  final Uuid _uuid = const Uuid();
  final List<PaymentTransaction> _history = [];

  @override
  String get providerId => 'mock_provider_sandbox';

  @override
  Future<void> initialize() async {
    // Simulate initialization delay
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<List<String>> getPaymentCapabilities() async {
    return ['scan_qr', 'send_money', 'request_money', 'upi_autopay'];
  }

  @override
  Future<Map<String, String>> scanPaymentQr(String qrData) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Simulate parsing a UPI QR code string
    // e.g. upi://pay?pa=merchant@upi&pn=Merchant%20Name&am=500
    if (!qrData.startsWith('upi://pay')) {
      throw Exception('Invalid QR format');
    }
    
    final uri = Uri.parse(qrData);
    final pa = uri.queryParameters['pa'];
    final pn = uri.queryParameters['pn'];
    final am = uri.queryParameters['am'];
    
    if (pa == null) throw Exception('Missing payee address in QR');
    
    return {
      'payeeVpa': pa,
      'merchantName': pn ?? 'Unknown Merchant',
      'amount': am ?? '',
    };
  }

  @override
  Future<bool> validatePayee(String vpa) async {
    await Future.delayed(const Duration(milliseconds: 400));
    // Simulate validation - accept most for sandbox, reject if it starts with 'invalid'
    return !vpa.toLowerCase().startsWith('invalid');
  }

  @override
  Future<PaymentIntent> createPaymentIntent({
    required String payeeVpa,
    required int amount,
    String? description,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    final intent = PaymentIntent(
      id: _uuid.v4(),
      clientRequestId: _uuid.v4(),
      payeeVpa: payeeVpa,
      amount: amount,
      status: PaymentState.created,
      description: description,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    return intent;
  }

  @override
  Future<PaymentTransaction> authorizePayment({
    required String paymentIntentId,
    required String sourceAccountId,
  }) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network and bank processing
    
    final now = DateTime.now();
    final transactionId = _uuid.v4();
    
    // For sandbox purposes, randomly fail ~10% of transactions to test error states
    // but for predictable demo we'll just succeed.
    final status = PaymentState.success;
    
    final transaction = PaymentTransaction(
      id: transactionId,
      userId: 'mock_user_id', // In a real app, this comes from auth context
      paymentIntentId: paymentIntentId,
      paymentProvider: providerId,
      providerTransactionId: 'txn_$transactionId',
      sourceAccountId: sourceAccountId,
      amount: 0, // This would normally be linked back from the intent
      type: 'P2P',
      status: status,
      createdAt: now,
      updatedAt: now,
      completedAt: status == PaymentState.success ? now : null,
      metadata: {'isSandbox': true},
    );
    
    _history.add(transaction);
    return transaction;
  }

  @override
  Future<PaymentState> getPaymentStatus(String providerTransactionId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    final txn = _history.where((t) => t.providerTransactionId == providerTransactionId).firstOrNull;
    return txn?.status ?? PaymentState.failed;
  }

  @override
  Future<bool> cancelPayment(String providerTransactionId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return true;
  }

  @override
  Future<PaymentTransaction?> getTransaction(String providerTransactionId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _history.where((t) => t.providerTransactionId == providerTransactionId).firstOrNull;
  }

  @override
  Future<List<PaymentTransaction>> getPaymentHistory({int limit = 50, int offset = 0}) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _history.skip(offset).take(limit).toList();
  }
}

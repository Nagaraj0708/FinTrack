import 'payment_state.dart';

class PaymentTransaction {
  final String id;
  final String userId;
  final String? paymentIntentId;
  final String paymentProvider; // e.g. mock_provider
  final String? providerTransactionId;
  final String? sourceAccountId;
  final String? recipientId;
  final int amount;
  final String currency;
  final String type; // e.g. P2P, P2M
  final PaymentState status;
  final String? merchantName;
  final String? merchantVpa;
  final String? payerVpa;
  final String? payeeVpa;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final String? failureCode;
  final String? failureReason;
  final Map<String, dynamic>? metadata;

  const PaymentTransaction({
    required this.id,
    required this.userId,
    this.paymentIntentId,
    required this.paymentProvider,
    this.providerTransactionId,
    this.sourceAccountId,
    this.recipientId,
    required this.amount,
    this.currency = 'INR',
    required this.type,
    required this.status,
    this.merchantName,
    this.merchantVpa,
    this.payerVpa,
    this.payeeVpa,
    this.description,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    this.failureCode,
    this.failureReason,
    this.metadata,
  });
}

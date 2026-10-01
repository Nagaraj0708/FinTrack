import 'payment_state.dart';

class PaymentIntent {
  final String id;
  final String clientRequestId;
  final String? payeeId;
  final String? payeeVpa;
  final int amount;
  final String currency;
  final PaymentState status;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PaymentIntent({
    required this.id,
    required this.clientRequestId,
    this.payeeId,
    this.payeeVpa,
    required this.amount,
    this.currency = 'INR',
    required this.status,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });
}

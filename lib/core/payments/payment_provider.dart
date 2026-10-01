import '../../features/payments/domain/models/payment_intent.dart';
import '../../features/payments/domain/models/payment_transaction.dart';
import '../../features/payments/domain/models/payment_state.dart';

abstract class PaymentProvider {
  /// The unique identifier of the payment provider (e.g., 'mock_provider', 'upi_provider').
  String get providerId;

  /// Initializes the payment provider.
  Future<void> initialize();

  /// Gets a list of supported payment capabilities.
  Future<List<String>> getPaymentCapabilities();

  /// Simulates parsing a payment QR code.
  Future<Map<String, String>> scanPaymentQr(String qrData);

  /// Validates the payee details (e.g. UPI ID).
  Future<bool> validatePayee(String vpa);

  /// Creates a payment intent for a transaction.
  Future<PaymentIntent> createPaymentIntent({
    required String payeeVpa,
    required int amount,
    String? description,
  });

  /// Authorizes and executes the payment.
  Future<PaymentTransaction> authorizePayment({
    required String paymentIntentId,
    required String sourceAccountId,
  });

  /// Gets the current status of a payment.
  Future<PaymentState> getPaymentStatus(String providerTransactionId);

  /// Cancels a pending payment.
  Future<bool> cancelPayment(String providerTransactionId);

  /// Gets a specific transaction by ID.
  Future<PaymentTransaction?> getTransaction(String providerTransactionId);

  /// Gets payment history.
  Future<List<PaymentTransaction>> getPaymentHistory({int limit = 50, int offset = 0});
}

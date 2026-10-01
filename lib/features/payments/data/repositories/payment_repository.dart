// ============================================================
// Payment Repository — reads/writes payment data via Drift
// ============================================================
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/database.dart';
import '../../../payments/domain/models/payment_state.dart';

class PaymentRepository {
  final AppDatabase _db;
  final _uuid = const Uuid();

  PaymentRepository(this._db);

  // ── PaymentTransactions ──────────────────────────────────────────────────

  /// Streams all payment transactions ordered by newest first.
  Stream<List<PaymentTransactionRecord>> watchPaymentTransactions({int limit = 50}) {
    return (_db.select(_db.paymentTransactions)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(limit))
        .watch();
  }

  Future<List<PaymentTransactionRecord>> getRecentPayments({int limit = 20}) async {
    return (_db.select(_db.paymentTransactions)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(limit))
        .get();
  }

  Future<PaymentTransactionRecord?> getPaymentById(String id) async {
    return (_db.select(_db.paymentTransactions)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<String> insertPaymentTransaction({
    required String userId,
    required String? paymentIntentId,
    required String paymentProvider,
    String? providerTransactionId,
    String? sourceAccountId,
    String? recipientId,
    required int amount,
    String currency = 'INR',
    required String type,
    required PaymentState status,
    String? merchantName,
    String? merchantVpa,
    String? payerVpa,
    String? payeeVpa,
    String? description,
    String? failureCode,
    String? failureReason,
    String? metadata,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    await _db.into(_db.paymentTransactions).insert(
      PaymentTransactionsCompanion.insert(
        id: id,
        userId: userId,
        paymentIntentId: Value(paymentIntentId),
        paymentProvider: paymentProvider,
        providerTransactionId: Value(providerTransactionId),
        sourceAccountId: Value(sourceAccountId),
        recipientId: Value(recipientId),
        amount: amount,
        currency: Value(currency),
        type: type,
        status: status.name,
        merchantName: Value(merchantName),
        merchantVpa: Value(merchantVpa),
        payerVpa: Value(payerVpa),
        payeeVpa: Value(payeeVpa),
        description: Value(description),
        createdAt: now,
        updatedAt: now,
        completedAt: status == PaymentState.success ? Value(now) : const Value.absent(),
        failureCode: Value(failureCode),
        failureReason: Value(failureReason),
        metadata: Value(metadata),
      ),
    );
    return id;
  }

  Future<void> updatePaymentStatus(String id, PaymentState status) async {
    final now = DateTime.now();
    await (_db.update(_db.paymentTransactions)..where((t) => t.id.equals(id))).write(
      PaymentTransactionsCompanion(
        status: Value(status.name),
        updatedAt: Value(now),
        completedAt: status == PaymentState.success ? Value(now) : const Value.absent(),
      ),
    );
  }

  // ── BankAccounts ────────────────────────────────────────────────────────

  Stream<List<BankAccountData>> watchBankAccounts(String userId) {
    return (_db.select(_db.bankAccounts)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([(t) => OrderingTerm.desc(t.isDefault)]))
        .watch();
  }

  Future<List<BankAccountData>> getBankAccounts(String userId) async {
    return (_db.select(_db.bankAccounts)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([(t) => OrderingTerm.desc(t.isDefault)]))
        .get();
  }

  Future<BankAccountData?> getDefaultBankAccount(String userId) async {
    return (_db.select(_db.bankAccounts)
          ..where((t) => t.userId.equals(userId) & t.isDefault.equals(true)))
        .getSingleOrNull();
  }

  Future<String> addBankAccount({
    required String userId,
    required String bankName,
    required String maskedAccountNumber,
    String? ifsc,
    bool setAsDefault = false,
  }) async {
    final id = _uuid.v4();
    if (setAsDefault) {
      // Clear existing default
      await (_db.update(_db.bankAccounts)..where((t) => t.userId.equals(userId)))
          .write(const BankAccountsCompanion(isDefault: Value(false)));
    }
    await _db.into(_db.bankAccounts).insert(
      BankAccountsCompanion.insert(
        id: id,
        userId: userId,
        bankName: bankName,
        maskedAccountNumber: maskedAccountNumber,
        ifsc: Value(ifsc),
        isDefault: Value(setAsDefault),
        createdAt: DateTime.now(),
      ),
    );
    return id;
  }

  Future<void> setDefaultBankAccount(String userId, String accountId) async {
    await _db.transaction(() async {
      await (_db.update(_db.bankAccounts)..where((t) => t.userId.equals(userId)))
          .write(const BankAccountsCompanion(isDefault: Value(false)));
      await (_db.update(_db.bankAccounts)..where((t) => t.id.equals(accountId)))
          .write(const BankAccountsCompanion(isDefault: Value(true)));
    });
  }

  Future<void> removeBankAccount(String id) async {
    await (_db.delete(_db.bankAccounts)..where((t) => t.id.equals(id))).go();
  }

  // ── UpiProfiles ─────────────────────────────────────────────────────────

  Future<UpiProfileData?> getUpiProfile(String userId) async {
    return (_db.select(_db.upiProfiles)..where((t) => t.userId.equals(userId)))
        .getSingleOrNull();
  }

  Future<void> upsertUpiProfile({
    required String userId,
    required String vpa,
    required String qrCodeData,
  }) async {
    final existing = await getUpiProfile(userId);
    if (existing != null) {
      await (_db.update(_db.upiProfiles)..where((t) => t.userId.equals(userId))).write(
        UpiProfilesCompanion(
          vpa: Value(vpa),
          qrCodeData: Value(qrCodeData),
        ),
      );
    } else {
      await _db.into(_db.upiProfiles).insert(
        UpiProfilesCompanion.insert(
          id: _uuid.v4(),
          userId: userId,
          vpa: vpa,
          qrCodeData: qrCodeData,
          createdAt: DateTime.now(),
        ),
      );
    }
  }

  // ── Beneficiaries ────────────────────────────────────────────────────────

  Stream<List<BeneficiaryData>> watchBeneficiaries(String userId) {
    return (_db.select(_db.beneficiaries)..where((t) => t.userId.equals(userId))).watch();
  }

  Future<List<BeneficiaryData>> getBeneficiaries(String userId) async {
    return (_db.select(_db.beneficiaries)..where((t) => t.userId.equals(userId))).get();
  }

  Future<void> addBeneficiary({
    required String userId,
    required String name,
    String? vpa,
    String? bankAccountNumber,
    String? ifsc,
  }) async {
    await _db.into(_db.beneficiaries).insert(
      BeneficiariesCompanion.insert(
        id: _uuid.v4(),
        userId: userId,
        name: name,
        vpa: Value(vpa),
        bankAccountNumber: Value(bankAccountNumber),
        ifsc: Value(ifsc),
        createdAt: DateTime.now(),
      ),
    );
  }
}

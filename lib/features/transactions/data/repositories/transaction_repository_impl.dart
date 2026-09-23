import 'package:drift/drift.dart';
import '../../../../core/database/database.dart';
import '../../domain/entities/transaction.dart' as entity;
import '../../domain/repositories/transaction_repository.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final AppDatabase _db;

  TransactionRepositoryImpl(this._db);

  entity.Transaction _mapToDomain(TransactionData data) {
    return entity.Transaction(
      id: data.id,
      userId: data.userId,
      accountId: data.accountId,
      type: data.type,
      amount: data.amount,
      currency: data.currency,
      categoryId: data.categoryId,
      subcategoryId: data.subcategoryId,
      merchant: data.merchant,
      description: data.description,
      transactionDate: data.transactionDate,
      paymentMethod: data.paymentMethod,
      source: data.source,
      referenceId: data.referenceId,
      notes: data.notes,
      isRecurring: data.isRecurring,
      createdAt: data.createdAt,
      updatedAt: data.updatedAt,
      syncStatus: data.syncStatus,
    );
  }

  TransactionsCompanion _mapToDb(entity.Transaction transaction) {
    return TransactionsCompanion.insert(
      id: transaction.id,
      userId: transaction.userId,
      accountId: transaction.accountId,
      type: transaction.type,
      amount: transaction.amount,
      currency: Value(transaction.currency),
      categoryId: Value(transaction.categoryId),
      subcategoryId: Value(transaction.subcategoryId),
      merchant: Value(transaction.merchant),
      description: Value(transaction.description),
      transactionDate: transaction.transactionDate,
      paymentMethod: Value(transaction.paymentMethod),
      source: Value(transaction.source),
      referenceId: Value(transaction.referenceId),
      notes: Value(transaction.notes),
      isRecurring: Value(transaction.isRecurring),
      createdAt: transaction.createdAt,
      updatedAt: transaction.updatedAt,
      syncStatus: Value(transaction.syncStatus),
    );
  }

  @override
  Future<List<entity.Transaction>> getTransactions() async {
    final result = await _db.select(_db.transactions).get();
    return result.map(_mapToDomain).toList();
  }

  @override
  Future<List<entity.Transaction>> getTransactionsByAccountId(
    String accountId,
  ) async {
    final result = await (_db.select(
      _db.transactions,
    )..where((tbl) => tbl.accountId.equals(accountId))).get();
    return result.map(_mapToDomain).toList();
  }

  @override
  Future<entity.Transaction?> getTransactionById(String id) async {
    final result = await (_db.select(
      _db.transactions,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    return result != null ? _mapToDomain(result) : null;
  }

  @override
  Future<void> addTransaction(entity.Transaction transaction) async {
    await _db.into(_db.transactions).insert(_mapToDb(transaction));
  }

  @override
  Future<void> updateTransaction(entity.Transaction transaction) async {
    await _db.update(_db.transactions).replace(_mapToDb(transaction));
  }

  @override
  Future<void> deleteTransaction(String id) async {
    await (_db.delete(
      _db.transactions,
    )..where((tbl) => tbl.id.equals(id))).go();
  }

  @override
  Future<void> clearAllTransactions() async {
    await _db.delete(_db.transactions).go();
  }

  @override
  Stream<List<entity.Transaction>> watchTransactions() {
    return _db
        .select(_db.transactions)
        .watch()
        .map((rows) => rows.map(_mapToDomain).toList());
  }
}

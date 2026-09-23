import 'package:drift/drift.dart';
import '../../../../core/database/database.dart';
import '../../domain/entities/account.dart';
import '../../domain/repositories/account_repository.dart';

class AccountRepositoryImpl implements AccountRepository {
  final AppDatabase _db;

  AccountRepositoryImpl(this._db);

  Account _mapToDomain(AccountData data) {
    return Account(
      id: data.id,
      userId: data.userId,
      name: data.name,
      type: data.type,
      institution: data.institution,
      maskedIdentifier: data.maskedIdentifier,
      openingBalance: data.openingBalance,
      currentBalance: data.currentBalance,
      currency: data.currency,
      isActive: data.isActive,
      createdAt: data.createdAt,
      updatedAt: data.updatedAt,
    );
  }

  AccountsCompanion _mapToDb(Account account) {
    return AccountsCompanion.insert(
      id: account.id,
      userId: account.userId,
      name: account.name,
      type: account.type,
      institution: Value(account.institution),
      maskedIdentifier: Value(account.maskedIdentifier),
      openingBalance: Value(account.openingBalance),
      currentBalance: Value(account.currentBalance),
      currency: Value(account.currency),
      isActive: Value(account.isActive),
      createdAt: account.createdAt,
      updatedAt: account.updatedAt,
    );
  }

  @override
  Future<List<Account>> getAccounts() async {
    final result = await _db.select(_db.accounts).get();
    return result.map(_mapToDomain).toList();
  }

  @override
  Future<Account?> getAccountById(String id) async {
    final result = await (_db.select(
      _db.accounts,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    return result != null ? _mapToDomain(result) : null;
  }

  @override
  Future<void> addAccount(Account account) async {
    await _db.into(_db.accounts).insert(_mapToDb(account));
  }

  @override
  Future<void> updateAccount(Account account) async {
    await _db.update(_db.accounts).replace(_mapToDb(account));
  }

  @override
  Future<void> deleteAccount(String id) async {
    await (_db.delete(_db.accounts)..where((tbl) => tbl.id.equals(id))).go();
  }

  @override
  Stream<List<Account>> watchAccounts() {
    return _db
        .select(_db.accounts)
        .watch()
        .map((rows) => rows.map(_mapToDomain).toList());
  }
}

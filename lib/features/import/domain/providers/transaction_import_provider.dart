import '../../../transactions/domain/entities/transaction.dart';

abstract class TransactionImportProvider {
  Future<List<Transaction>> parseFile(
    String filePath,
    String accountId,
    String userId,
  );
}

import 'dart:io';
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:uuid/uuid.dart';
import '../domain/providers/transaction_import_provider.dart';
import '../../transactions/domain/entities/transaction.dart';

class CsvImporter implements TransactionImportProvider {
  @override
  Future<List<Transaction>> parseFile(
    String filePath,
    String accountId,
    String userId,
  ) async {
    final input = File(filePath).openRead();
    final fields = await input
        .transform(const Utf8Decoder())
        .transform(CsvDecoder())
        .toList();

    final transactions = <Transaction>[];
    final startIdx =
        fields.isNotEmpty &&
            fields[0][0].toString().toLowerCase().contains('date')
        ? 1
        : 0;
    const uuid = Uuid();

    for (int i = startIdx; i < fields.length; i++) {
      final row = fields[i];
      if (row.length >= 4) {
        final dateStr = row[0].toString();
        final description = row[1].toString();
        final amountStr = row[2].toString().replaceAll(',', '');
        final amountDouble = double.tryParse(amountStr) ?? 0;
        final amount = (amountDouble * 100).toInt();
        final type = row[3].toString().toLowerCase() == 'income'
            ? 'income'
            : 'expense';

        transactions.add(
          Transaction(
            id: uuid.v4(),
            userId: userId,
            accountId: accountId,
            type: type,
            amount: amount.abs(),
            currency: 'INR',
            description: description,
            transactionDate: DateTime.tryParse(dateStr) ?? DateTime.now(),
            paymentMethod: 'import',
            source: 'csv',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            syncStatus: 'pending',
          ),
        );
      }
    }

    return transactions;
  }
}

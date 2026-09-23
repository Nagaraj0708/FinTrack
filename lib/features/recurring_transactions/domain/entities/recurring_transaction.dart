import 'package:freezed_annotation/freezed_annotation.dart';

part 'recurring_transaction.freezed.dart';
part 'recurring_transaction.g.dart';

@freezed
abstract class RecurringTransaction with _$RecurringTransaction {
  const RecurringTransaction._();
  const factory RecurringTransaction({
    required String id,
    required String userId,
    required String accountId,
    String? categoryId,
    required String type,
    required int amount,
    required String frequency,
    required DateTime nextOccurrence,
    required DateTime createdAt,
  }) = _RecurringTransaction;

  factory RecurringTransaction.fromJson(Map<String, dynamic> json) =>
      _$RecurringTransactionFromJson(json);
}

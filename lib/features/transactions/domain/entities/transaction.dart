import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction.freezed.dart';
part 'transaction.g.dart';

@freezed
abstract class Transaction with _$Transaction {
  const Transaction._();
  const factory Transaction({
    required String id,
    required String userId,
    required String accountId,
    required String type,
    required int amount,
    @Default('INR') String currency,
    String? categoryId,
    String? subcategoryId,
    String? merchant,
    String? description,
    required DateTime transactionDate,
    String? paymentMethod,
    @Default('manual') String source,
    String? referenceId,
    String? notes,
    @Default(false) bool isRecurring,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default('pending') String syncStatus,
  }) = _Transaction;

  factory Transaction.fromJson(Map<String, dynamic> json) =>
      _$TransactionFromJson(json);
}

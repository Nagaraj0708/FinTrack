// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_transaction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RecurringTransaction _$RecurringTransactionFromJson(
  Map<String, dynamic> json,
) => _RecurringTransaction(
  id: json['id'] as String,
  userId: json['userId'] as String,
  accountId: json['accountId'] as String,
  categoryId: json['categoryId'] as String?,
  type: json['type'] as String,
  amount: (json['amount'] as num).toInt(),
  frequency: json['frequency'] as String,
  nextOccurrence: DateTime.parse(json['nextOccurrence'] as String),
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$RecurringTransactionToJson(
  _RecurringTransaction instance,
) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'accountId': instance.accountId,
  'categoryId': instance.categoryId,
  'type': instance.type,
  'amount': instance.amount,
  'frequency': instance.frequency,
  'nextOccurrence': instance.nextOccurrence.toIso8601String(),
  'createdAt': instance.createdAt.toIso8601String(),
};

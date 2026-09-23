// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Transaction _$TransactionFromJson(Map<String, dynamic> json) => _Transaction(
  id: json['id'] as String,
  userId: json['userId'] as String,
  accountId: json['accountId'] as String,
  type: json['type'] as String,
  amount: (json['amount'] as num).toInt(),
  currency: json['currency'] as String? ?? 'INR',
  categoryId: json['categoryId'] as String?,
  subcategoryId: json['subcategoryId'] as String?,
  merchant: json['merchant'] as String?,
  description: json['description'] as String?,
  transactionDate: DateTime.parse(json['transactionDate'] as String),
  paymentMethod: json['paymentMethod'] as String?,
  source: json['source'] as String? ?? 'manual',
  referenceId: json['referenceId'] as String?,
  notes: json['notes'] as String?,
  isRecurring: json['isRecurring'] as bool? ?? false,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  syncStatus: json['syncStatus'] as String? ?? 'pending',
);

Map<String, dynamic> _$TransactionToJson(_Transaction instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'accountId': instance.accountId,
      'type': instance.type,
      'amount': instance.amount,
      'currency': instance.currency,
      'categoryId': instance.categoryId,
      'subcategoryId': instance.subcategoryId,
      'merchant': instance.merchant,
      'description': instance.description,
      'transactionDate': instance.transactionDate.toIso8601String(),
      'paymentMethod': instance.paymentMethod,
      'source': instance.source,
      'referenceId': instance.referenceId,
      'notes': instance.notes,
      'isRecurring': instance.isRecurring,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'syncStatus': instance.syncStatus,
    };

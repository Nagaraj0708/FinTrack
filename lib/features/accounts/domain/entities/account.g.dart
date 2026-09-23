// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Account _$AccountFromJson(Map<String, dynamic> json) => _Account(
  id: json['id'] as String,
  userId: json['userId'] as String,
  name: json['name'] as String,
  type: json['type'] as String,
  institution: json['institution'] as String?,
  maskedIdentifier: json['maskedIdentifier'] as String?,
  openingBalance: (json['openingBalance'] as num?)?.toInt() ?? 0,
  currentBalance: (json['currentBalance'] as num?)?.toInt() ?? 0,
  currency: json['currency'] as String? ?? 'INR',
  isActive: json['isActive'] as bool? ?? true,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$AccountToJson(_Account instance) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'name': instance.name,
  'type': instance.type,
  'institution': instance.institution,
  'maskedIdentifier': instance.maskedIdentifier,
  'openingBalance': instance.openingBalance,
  'currentBalance': instance.currentBalance,
  'currency': instance.currency,
  'isActive': instance.isActive,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
};

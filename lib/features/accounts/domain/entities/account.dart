import 'package:freezed_annotation/freezed_annotation.dart';

part 'account.freezed.dart';
part 'account.g.dart';

@freezed
abstract class Account with _$Account {
  const Account._();
  const factory Account({
    required String id,
    required String userId,
    required String name,
    required String type,
    String? institution,
    String? maskedIdentifier,
    @Default(0) int openingBalance,
    @Default(0) int currentBalance,
    @Default('INR') String currency,
    @Default(true) bool isActive,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Account;

  factory Account.fromJson(Map<String, dynamic> json) =>
      _$AccountFromJson(json);
}

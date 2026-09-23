import 'package:freezed_annotation/freezed_annotation.dart';

part 'budget.freezed.dart';
part 'budget.g.dart';

@freezed
abstract class Budget with _$Budget {
  const Budget._();
  const factory Budget({
    required String id,
    required String userId,
    required String categoryId,
    required int amount,
    @Default('monthly') String period,
    required DateTime startDate,
    DateTime? endDate,
    required DateTime createdAt,
  }) = _Budget;

  factory Budget.fromJson(Map<String, dynamic> json) => _$BudgetFromJson(json);
}

import 'package:freezed_annotation/freezed_annotation.dart';

part 'goal.freezed.dart';
part 'goal.g.dart';

@freezed
abstract class Goal with _$Goal {
  const Goal._();
  const factory Goal({
    required String id,
    required String userId,
    required String name,
    required int targetAmount,
    @Default(0) int currentAmount,
    DateTime? deadline,
    required DateTime createdAt,
  }) = _Goal;

  factory Goal.fromJson(Map<String, dynamic> json) => _$GoalFromJson(json);
}

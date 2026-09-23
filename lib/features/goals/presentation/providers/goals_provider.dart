import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/goal.dart';

class GoalsNotifier extends Notifier<List<Goal>> {
  @override
  List<Goal> build() {
    return [];
  }

  void addGoal(String name, int targetAmount, int currentAmount) {
    final newGoal = Goal(
      id: const Uuid().v4(),
      userId: 'default_user',
      name: name,
      targetAmount: targetAmount,
      currentAmount: currentAmount,
      createdAt: DateTime.now(),
    );
    state = [...state, newGoal];
  }

  void addFunds(String goalId, int amountToAdd) {
    if (amountToAdd <= 0) return;
    state = state.map((goal) {
      if (goal.id == goalId) {
        return goal.copyWith(currentAmount: goal.currentAmount + amountToAdd);
      }
      return goal;
    }).toList();
  }

  void deleteGoal(String goalId) {
    state = state.where((g) => g.id != goalId).toList();
  }
}

final goalsProvider = NotifierProvider<GoalsNotifier, List<Goal>>(() {
  return GoalsNotifier();
});

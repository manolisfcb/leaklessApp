import 'dart:async';

import '../../../core/dev/demo_data.dart';
import '../../../domain/enums/finance_enums.dart';
import '../../../domain/models/goal.dart';

/// Reads savings goals and records contributions ("aporte express").
abstract interface class GoalsRepository {
  Stream<List<Goal>> watchForHousehold(String householdId);
  Future<List<Goal>> fetchForHousehold(String householdId);
  Future<void> contribute({
    required String goalId,
    required int amountMinorUnits,
  });
}

/// In-memory goals so the express-contribution button works end-to-end before
/// the backend exists; the new progress emits immediately to the UI.
class MockGoalsRepository implements GoalsRepository {
  MockGoalsRepository() : _items = DemoData.goals();

  final List<Goal> _items;
  final _controller = StreamController<List<Goal>>.broadcast();

  @override
  Stream<List<Goal>> watchForHousehold(String householdId) async* {
    yield List.unmodifiable(_items);
    yield* _controller.stream;
  }

  @override
  Future<List<Goal>> fetchForHousehold(String householdId) async =>
      List.unmodifiable(_items);

  @override
  Future<void> contribute({
    required String goalId,
    required int amountMinorUnits,
  }) async {
    final index = _items.indexWhere((g) => g.id == goalId);
    if (index == -1) return;
    final goal = _items[index];
    final newSaved = goal.saved.copyWith(
      minorUnits: goal.saved.minorUnits + amountMinorUnits,
    );
    final completed = newSaved.minorUnits >= goal.target.minorUnits;
    _items[index] = goal.copyWith(
      saved: newSaved,
      status: completed ? GoalStatus.completed : goal.status,
      updatedAt: DateTime.now(),
    );
    _controller.add(List.unmodifiable(_items));
  }

  void dispose() => unawaited(_controller.close());
}

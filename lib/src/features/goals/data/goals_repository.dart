import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/dev/demo_data.dart';
import '../../../core/errors/app_exception.dart';
import '../../../domain/enums/finance_enums.dart';
import '../../../domain/models/goal.dart';
import 'goal_mapper.dart';

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

/// Supabase-backed goals using realtime streams + the [GoalMapper].
///
/// RLS already restricts `goals` to the user's household; the explicit
/// `household_id` filter keeps this correct if a user ever belongs to more than
/// one, and mirrors the `transactions` pattern.
class SupabaseGoalsRepository implements GoalsRepository {
  SupabaseGoalsRepository(this._client);

  final SupabaseClient _client;

  SupabaseQueryBuilder get _table => _client.from('goals');

  @override
  Stream<List<Goal>> watchForHousehold(String householdId) => _table
      .stream(primaryKey: ['id'])
      .eq('household_id', householdId)
      .order('created_at')
      .map((rows) => rows.map(GoalMapper.fromRow).toList());

  @override
  Future<List<Goal>> fetchForHousehold(String householdId) async {
    try {
      final rows = await _table
          .select()
          .eq('household_id', householdId)
          .order('created_at');
      return rows.map(GoalMapper.fromRow).toList();
    } catch (e, s) {
      throw ServerException('Failed to load goals', cause: e, stackTrace: s);
    }
  }

  /// Read-modify-write of `saved_amount`: reads the current row, adds the
  /// contribution, and marks the goal completed once it reaches its target. The
  /// realtime stream then emits the new progress to both partners (the DB's
  /// `set_updated_at` trigger stamps `updated_at`).
  ///
  /// Note: this is not atomic — two simultaneous contributions can lose an
  /// update. A server-side atomic increment (RPC / trigger) is the proper
  /// hardening, tracked under roadmap §1.2 (reliable server-side calculation).
  @override
  Future<void> contribute({
    required String goalId,
    required int amountMinorUnits,
  }) async {
    try {
      final row = await _table.select().eq('id', goalId).single();
      final goal = GoalMapper.fromRow(row);
      final newSaved = goal.saved.copyWith(
        minorUnits: goal.saved.minorUnits + amountMinorUnits,
      );
      final completed = newSaved.minorUnits >= goal.target.minorUnits;
      await _table.update({
        'saved_amount': newSaved.major,
        if (completed) 'status': GoalStatus.completed.name,
      }).eq('id', goalId);
    } catch (e, s) {
      throw ServerException('Failed to contribute to goal', cause: e, stackTrace: s);
    }
  }
}

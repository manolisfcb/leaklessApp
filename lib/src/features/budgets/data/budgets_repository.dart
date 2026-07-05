import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/dev/demo_data.dart';
import '../../../core/errors/app_exception.dart';
import '../../../domain/models/budget.dart';
import 'budget_mapper.dart';

/// Reads the household's category budgets for the current period.
abstract interface class BudgetsRepository {
  Future<List<Budget>> fetchForHousehold(String householdId);
  Stream<List<Budget>> watchForHousehold(String householdId);
  Future<Budget> create(Budget budget);
  Future<Budget> update(Budget budget);
  Future<void> delete(String budgetId);
}

/// Stateful in-memory budgets with the same live-update behavior as Supabase.
class MockBudgetsRepository implements BudgetsRepository {
  MockBudgetsRepository() : _items = DemoData.budgets();

  final List<Budget> _items;
  final _controller = StreamController<List<Budget>>.broadcast();

  List<Budget> _forHousehold(String householdId) {
    final budgets = _items
        .where((budget) => budget.householdId == householdId)
        .toList();
    budgets.sort((a, b) => b.periodStart.compareTo(a.periodStart));
    return List.unmodifiable(budgets);
  }

  @override
  Future<List<Budget>> fetchForHousehold(String householdId) async =>
      _forHousehold(householdId);

  @override
  Stream<List<Budget>> watchForHousehold(String householdId) async* {
    yield _forHousehold(householdId);
    yield* _controller.stream.map((_) => _forHousehold(householdId));
  }

  @override
  Future<Budget> create(Budget budget) async {
    final now = DateTime.now();
    final saved = budget.copyWith(
      id: budget.id.isEmpty
          ? 'budget-${now.microsecondsSinceEpoch}'
          : budget.id,
      periodStart: DateTime(budget.periodStart.year, budget.periodStart.month),
      createdAt: budget.createdAt ?? now,
      updatedAt: now,
    );
    _items.add(saved);
    _emit();
    return saved;
  }

  @override
  Future<Budget> update(Budget budget) async {
    final index = _items.indexWhere((item) => item.id == budget.id);
    if (index == -1) {
      throw StateError('Budget ${budget.id} does not exist.');
    }
    final current = _items[index];
    final saved = budget.copyWith(
      spent: current.spent,
      periodStart: DateTime(budget.periodStart.year, budget.periodStart.month),
      createdAt: current.createdAt,
      updatedAt: DateTime.now(),
    );
    _items[index] = saved;
    _emit();
    return saved;
  }

  @override
  Future<void> delete(String budgetId) async {
    _items.removeWhere((budget) => budget.id == budgetId);
    _emit();
  }

  void _emit() => _controller.add(List.unmodifiable(_items));

  void dispose() => unawaited(_controller.close());
}

/// Supabase-backed budget reads, scoped to the active household.
///
/// RLS already restricts `budgets` to households the user belongs to; the
/// explicit `household_id` filter keeps this correct if a user ever belongs to
/// more than one, and mirrors the `transactions` pattern. `spent` is read as the
/// denormalized column for now — recomputing it server-side is a separate task.
class SupabaseBudgetsRepository implements BudgetsRepository {
  SupabaseBudgetsRepository(this._client);

  final SupabaseClient _client;

  SupabaseQueryBuilder get _table => _client.from('budgets');

  @override
  Future<List<Budget>> fetchForHousehold(String householdId) async {
    try {
      final rows = await _table
          .select()
          .eq('household_id', householdId)
          .order('period_start', ascending: false);
      return rows.map(BudgetMapper.fromRow).toList();
    } catch (e, s) {
      throw ServerException('Failed to load budgets', cause: e, stackTrace: s);
    }
  }

  @override
  Stream<List<Budget>> watchForHousehold(String householdId) => _table
      .stream(primaryKey: ['id'])
      .eq('household_id', householdId)
      .order('period_start', ascending: false)
      .map((rows) => rows.map(BudgetMapper.fromRow).toList());

  @override
  Future<Budget> create(Budget budget) async {
    try {
      final row = await _table
          .insert(BudgetMapper.toInsert(budget))
          .select()
          .single();
      return BudgetMapper.fromRow(row);
    } catch (e, s) {
      throw ServerException('Failed to create budget', cause: e, stackTrace: s);
    }
  }

  @override
  Future<Budget> update(Budget budget) async {
    try {
      final row = await _table
          .update(BudgetMapper.toUpdate(budget))
          .eq('id', budget.id)
          .select()
          .single();
      return BudgetMapper.fromRow(row);
    } catch (e, s) {
      throw ServerException('Failed to update budget', cause: e, stackTrace: s);
    }
  }

  @override
  Future<void> delete(String budgetId) async {
    try {
      await _table.delete().eq('id', budgetId);
    } catch (e, s) {
      throw ServerException('Failed to delete budget', cause: e, stackTrace: s);
    }
  }
}

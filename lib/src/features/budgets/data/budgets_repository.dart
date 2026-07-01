import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/dev/demo_data.dart';
import '../../../core/errors/app_exception.dart';
import '../../../domain/models/budget.dart';
import 'budget_mapper.dart';

/// Reads the household's category budgets for the current period.
abstract interface class BudgetsRepository {
  Future<List<Budget>> fetchForHousehold(String householdId);
}

/// Mock budgets from [DemoData]. Replace with a Supabase implementation
/// (querying `budgets`, joined with the period's spend) when wired.
class MockBudgetsRepository implements BudgetsRepository {
  const MockBudgetsRepository();

  @override
  Future<List<Budget>> fetchForHousehold(String householdId) async =>
      DemoData.budgets();
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

  @override
  Future<List<Budget>> fetchForHousehold(String householdId) async {
    try {
      final rows = await _client
          .from('budgets')
          .select()
          .eq('household_id', householdId)
          .order('period_start', ascending: false);
      return rows.map(BudgetMapper.fromRow).toList();
    } catch (e, s) {
      throw ServerException('Failed to load budgets', cause: e, stackTrace: s);
    }
  }
}

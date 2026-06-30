import '../../../core/dev/demo_data.dart';
import '../../../domain/models/budget.dart';

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

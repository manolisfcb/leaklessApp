import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../../domain/models/budget.dart';
import '../../../domain/models/money.dart';
import '../../household/application/household_providers.dart';
import '../data/budget_alerts_repository.dart';
import '../data/budgets_repository.dart';

/// Real (Supabase) or mock repository, chosen by config — same pattern as
/// [categoriesRepositoryProvider] / [transactionsRepositoryProvider].
final budgetsRepositoryProvider = Provider<BudgetsRepository>((ref) {
  if (ref.watch(supabaseEnabledProvider)) {
    return SupabaseBudgetsRepository(ref.watch(supabaseClientProvider));
  }
  final repo = MockBudgetsRepository();
  ref.onDispose(repo.dispose);
  return repo;
});

/// Dedupe ledger for fired budget alerts, real or in-memory by config.
final budgetAlertsRepositoryProvider = Provider<BudgetAlertsRepository>((ref) {
  if (ref.watch(supabaseEnabledProvider)) {
    return SupabaseBudgetAlertsRepository(ref.watch(supabaseClientProvider));
  }
  return MockBudgetAlertsRepository();
});

/// Live category budgets for the active household.
final budgetsProvider = StreamProvider<List<Budget>>((ref) async* {
  final household = await ref.watch(currentHouseholdProvider.future);
  if (household == null) {
    yield const [];
    return;
  }
  yield* ref.watch(budgetsRepositoryProvider).watchForHousehold(household.id);
});

/// Creates, edits, and deletes budgets while exposing failures to the UI.
class BudgetsController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<bool> save({
    String? budgetId,
    required String categoryId,
    required int amountMinorUnits,
    DateTime? periodStart,
    bool alertEnabled = true,
    int alertThresholdPct = 80,
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      final household = await ref.read(currentHouseholdProvider.future);
      if (household == null) {
        throw StateError('No active household to save a budget.');
      }
      final date = periodStart ?? DateTime.now();
      final budget = Budget(
        id: budgetId ?? '',
        householdId: household.id,
        categoryId: categoryId,
        limit: Money(
          minorUnits: amountMinorUnits,
          currency: household.currency,
        ),
        periodStart: DateTime(date.year, date.month),
        alertEnabled: alertEnabled,
        alertThresholdPct: alertThresholdPct,
      );
      final repository = ref.read(budgetsRepositoryProvider);
      if (budget.id.isEmpty) {
        await repository.create(budget);
      } else {
        await repository.update(budget);
      }
    });
    state = result;
    return !result.hasError;
  }

  Future<bool> delete(String budgetId) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(budgetsRepositoryProvider).delete(budgetId),
    );
    state = result;
    return !result.hasError;
  }
}

final budgetsControllerProvider =
    NotifierProvider<BudgetsController, AsyncValue<void>>(
      BudgetsController.new,
    );

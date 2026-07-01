import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../../domain/models/budget.dart';
import '../../household/application/household_providers.dart';
import '../data/budgets_repository.dart';

/// Real (Supabase) or mock repository, chosen by config — same pattern as
/// [categoriesRepositoryProvider] / [transactionsRepositoryProvider].
final budgetsRepositoryProvider = Provider<BudgetsRepository>((ref) {
  if (ref.watch(supabaseEnabledProvider)) {
    return SupabaseBudgetsRepository(ref.watch(supabaseClientProvider));
  }
  return const MockBudgetsRepository();
});

/// Category budgets for the active household.
final budgetsProvider = FutureProvider<List<Budget>>((ref) async {
  final household = await ref.watch(currentHouseholdProvider.future);
  if (household == null) return const [];
  return ref.watch(budgetsRepositoryProvider).fetchForHousehold(household.id);
});

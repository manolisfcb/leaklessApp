import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/core_providers.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../../domain/models/goal.dart';
import '../../../domain/models/money.dart';
import '../../household/application/household_providers.dart';
import '../data/goals_repository.dart';

/// Real (Supabase) or mock repository, chosen by config — same pattern as
/// [transactionsRepositoryProvider].
final goalsRepositoryProvider = Provider<GoalsRepository>((ref) {
  if (ref.watch(supabaseEnabledProvider)) {
    return SupabaseGoalsRepository(ref.watch(supabaseClientProvider));
  }
  final repo = MockGoalsRepository();
  ref.onDispose(repo.dispose);
  return repo;
});

/// Live savings goals for the active household.
final goalsStreamProvider = StreamProvider<List<Goal>>((ref) async* {
  final household = await ref.watch(currentHouseholdProvider.future);
  if (household == null) {
    yield const [];
    return;
  }
  yield* ref.watch(goalsRepositoryProvider).watchForHousehold(household.id);
});

/// Handles the "aporte express" action and exposes its async state.
class GoalsController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<bool> save({
    Goal? goal,
    required String name,
    required int targetAmountMinorUnits,
    DateTime? deadline,
  }) => _run(() async {
    if (goal == null) {
      final household = await ref.read(currentHouseholdProvider.future);
      if (household == null) throw StateError('No active household');
      await ref
          .read(goalsRepositoryProvider)
          .create(
            Goal(
              id: '',
              householdId: household.id,
              name: name.trim(),
              target: Money(
                minorUnits: targetAmountMinorUnits,
                currency: household.currency,
              ),
              deadline: deadline,
            ),
          );
      return;
    }

    await ref
        .read(goalsRepositoryProvider)
        .update(
          goal.copyWith(
            name: name.trim(),
            target: goal.target.copyWith(minorUnits: targetAmountMinorUnits),
            deadline: deadline,
          ),
        );
  });

  Future<bool> delete(String goalId) =>
      _run(() => ref.read(goalsRepositoryProvider).delete(goalId));

  Future<bool> contribute({
    required String goalId,
    required int amountMinorUnits,
  }) => _run(() async {
    await ref
        .read(goalsRepositoryProvider)
        .contribute(goalId: goalId, amountMinorUnits: amountMinorUnits);
    await ref.read(analyticsServiceProvider).goalContribution();
  });

  Future<bool> _run(Future<void> Function() action) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(action);
    return !state.hasError;
  }
}

final goalsControllerProvider =
    NotifierProvider<GoalsController, AsyncValue<void>>(GoalsController.new);

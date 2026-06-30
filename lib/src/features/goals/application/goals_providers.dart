import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/core_providers.dart';
import '../../../domain/models/goal.dart';
import '../../household/application/household_providers.dart';
import '../data/goals_repository.dart';

final goalsRepositoryProvider = Provider<GoalsRepository>((ref) {
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

  Future<void> contribute({
    required String goalId,
    required int amountMinorUnits,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(goalsRepositoryProvider)
          .contribute(goalId: goalId, amountMinorUnits: amountMinorUnits);
      await ref.read(analyticsServiceProvider).goalContribution();
    });
  }
}

final goalsControllerProvider =
    NotifierProvider<GoalsController, AsyncValue<void>>(GoalsController.new);

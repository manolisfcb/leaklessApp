import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../../domain/enums/finance_enums.dart';
import '../../../domain/models/money.dart';
import '../../../domain/models/subscription_item.dart';
import '../../household/application/household_providers.dart';
import '../data/subscriptions_repository.dart';

/// Real (Supabase) or mock repository, chosen by config — same pattern as
/// [budgetsRepositoryProvider] / [transactionsRepositoryProvider].
final subscriptionsRepositoryProvider = Provider<SubscriptionsRepository>((ref) {
  if (ref.watch(supabaseEnabledProvider)) {
    return SupabaseSubscriptionsRepository(ref.watch(supabaseClientProvider));
  }
  final repo = MockSubscriptionsRepository();
  ref.onDispose(repo.dispose);
  return repo;
});

/// Live recurring subscriptions for the active household.
final subscriptionsProvider = StreamProvider<List<SubscriptionItem>>((
  ref,
) async* {
  final household = await ref.watch(currentHouseholdProvider.future);
  if (household == null) {
    yield const [];
    return;
  }
  yield* ref
      .watch(subscriptionsRepositoryProvider)
      .watchForHousehold(household.id);
});

/// Creates, edits, and deletes subscriptions while exposing failures to the UI.
class SubscriptionsController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<bool> save({
    String? subscriptionId,
    required String name,
    required int amountMinorUnits,
    SubscriptionFrequency frequency = SubscriptionFrequency.monthly,
    DateTime? nextChargeAt,
    String? categoryId,
    SubscriptionStatus status = SubscriptionStatus.active,
    bool reminderEnabled = false,
    int reminderDaysBefore = 1,
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      final household = await ref.read(currentHouseholdProvider.future);
      if (household == null) {
        throw StateError('No active household to save a subscription.');
      }
      final item = SubscriptionItem(
        id: subscriptionId ?? '',
        householdId: household.id,
        name: name.trim(),
        amount: Money(
          minorUnits: amountMinorUnits,
          currency: household.currency,
        ),
        status: status,
        frequency: frequency,
        nextChargeAt: nextChargeAt,
        categoryId: categoryId,
        reminderEnabled: reminderEnabled,
        reminderDaysBefore: reminderDaysBefore,
      );
      final repository = ref.read(subscriptionsRepositoryProvider);
      if (item.id.isEmpty) {
        await repository.create(item);
      } else {
        await repository.update(item);
      }
    });
    state = result;
    return !result.hasError;
  }

  Future<bool> delete(String subscriptionId) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(subscriptionsRepositoryProvider).delete(subscriptionId),
    );
    state = result;
    return !result.hasError;
  }
}

final subscriptionsControllerProvider =
    NotifierProvider<SubscriptionsController, AsyncValue<void>>(
      SubscriptionsController.new,
    );

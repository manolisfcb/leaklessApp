import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../../domain/enums/finance_enums.dart';
import '../../../domain/models/money.dart';
import '../../../domain/models/subscription_item.dart';
import '../../accounts/application/accounts_providers.dart';
import '../../fx/application/exchange_rates_providers.dart';
import '../../household/application/household_providers.dart';
import '../data/subscriptions_repository.dart';

/// Real (Supabase) or mock repository, chosen by config — same pattern as
/// [budgetsRepositoryProvider] / [transactionsRepositoryProvider].
final subscriptionsRepositoryProvider = Provider<SubscriptionsRepository>((
  ref,
) {
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
    String? currency,
    String? accountId,
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
      final billingCurrency = currency ?? household.currency;
      final accounts =
          ref.read(activeAccountsProvider).asData?.value ?? const [];
      final householdCurrencyAccounts = accounts.where(
        (account) => account.currency == household.currency,
      );
      final resolvedAccountId =
          accountId ??
          householdCurrencyAccounts
              .where((account) => account.isDefault)
              .map((account) => account.id)
              .firstOrNull ??
          householdCurrencyAccounts.map((account) => account.id).firstOrNull ??
          accounts
              .where((account) => account.isDefault)
              .map((account) => account.id)
              .firstOrNull ??
          accounts.map((account) => account.id).firstOrNull;
      Money? reportingAmount;
      DateTime? rateDate;
      if (billingCurrency == household.currency) {
        reportingAmount = Money(
          minorUnits: amountMinorUnits,
          currency: household.currency,
        );
        rateDate = nextChargeAt ?? DateTime.now();
      } else {
        final date = nextChargeAt ?? DateTime.now();
        final rate = await ref
            .read(exchangeRatesRepositoryProvider)
            .resolve(
              foreignCurrency: 'USD',
              reportingCurrency: 'CAD',
              onOrBefore: date,
            );
        if (rate != null) {
          reportingAmount = ref
              .read(currencyConverterProvider)
              .convert(
                Money(minorUnits: amountMinorUnits, currency: billingCurrency),
                household.currency,
                rate: rate,
              );
          rateDate = rate.rateDate;
        }
      }
      final item = SubscriptionItem(
        id: subscriptionId ?? '',
        householdId: household.id,
        name: name.trim(),
        amount: Money(minorUnits: amountMinorUnits, currency: billingCurrency),
        status: status,
        frequency: frequency,
        nextChargeAt: nextChargeAt,
        categoryId: categoryId,
        accountId: resolvedAccountId,
        estimatedReportingAmount: reportingAmount,
        exchangeRateDate: rateDate,
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

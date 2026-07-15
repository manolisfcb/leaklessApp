import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/core_providers.dart';
import '../../../core/logging/app_logger.dart';
import '../../../domain/enums/transaction_enums.dart';
import '../../../domain/models/money.dart';
import '../../../domain/models/transaction.dart';
import '../../../domain/models/fx_rate.dart';
import '../../budgets/application/budget_alert_watcher.dart';
import '../../household/application/household_providers.dart';
import '../../fx/application/exchange_rates_providers.dart';
import '../../transactions/application/transactions_providers.dart';

/// Handles registering a quick expense/income.
///
/// The UI only collects inputs and calls [submit]; all the work (building the
/// domain object, persisting, analytics) lives here (quality rule #4/#6). Works
/// against the mock repository until Supabase is configured.
class QuickEntryController extends Notifier<AsyncValue<void>> {
  static final _log = AppLogger.of('QuickEntry');

  @override
  AsyncValue<void> build() => const AsyncData(null);

  /// Returns true on success so the sheet can close.
  Future<bool> submit({
    required int amountMinorUnits,
    required TransactionType type,
    required TransactionPriority priority,
    required ResponsibleType responsible,
    String? currency,
    String? accountId,
    String? incomeSourceId,
    String? categoryId,
    String? description,
    DateTime? occurredAt,
  }) async {
    state = const AsyncLoading();
    // A scanned receipt carries its own purchase date; manual entries fall
    // back to now.
    final when = occurredAt ?? DateTime.now();
    final result = await AsyncValue.guard(() async {
      final household = await ref.read(currentHouseholdProvider.future);
      if (household == null) {
        throw StateError('No active household to register a transaction.');
      }
      final originalCurrency = currency ?? household.currency;
      final snapshot = await _snapshot(
        amountMinorUnits: amountMinorUnits,
        originalCurrency: originalCurrency,
        reportingCurrency: household.currency,
        occurredAt: when,
      );
      final transaction = Transaction(
        id: '',
        householdId: household.id,
        amount: Money(minorUnits: amountMinorUnits, currency: originalCurrency),
        type: type,
        priority: priority,
        responsible: responsible,
        categoryId: categoryId,
        accountId: accountId,
        incomeSourceId: incomeSourceId,
        reportingAmount: snapshot.amount,
        exchangeRateScaled: snapshot.scaledRate,
        exchangeRateDate: snapshot.rateDate,
        exchangeRateSource: snapshot.source,
        exchangeRateEstimated: snapshot.estimated,
        occurredAt: when,
        description: description,
      );
      await ref.read(transactionsRepositoryProvider).add(transaction);
    });
    state = result;
    if (result.hasError) {
      _log.severe(
        'Failed to save quick-entry transaction',
        result.error,
        result.stackTrace,
      );
      return false;
    }

    // Do not rely solely on the Realtime event to refresh the UI. A delayed or
    // temporarily disconnected channel must not make a successful insert look
    // like it was lost.
    ref.invalidate(transactionsStreamProvider);

    // Analytics is observability, not part of the financial write. A Firebase
    // failure must never turn a persisted expense into an apparent save error.
    try {
      await ref.read(analyticsServiceProvider).transactionCreated();
    } catch (error, stackTrace) {
      _log.warning('Could not track transaction_created', error, stackTrace);
    }

    await _maybeAlertBudget(
      type: type,
      categoryId: categoryId,
      occurredAt: when,
    );
    return true;
  }

  Future<
    ({
      Money amount,
      int scaledRate,
      DateTime rateDate,
      String source,
      bool estimated,
    })
  >
  _snapshot({
    required int amountMinorUnits,
    required String originalCurrency,
    required String reportingCurrency,
    required DateTime occurredAt,
  }) async {
    final original = Money(
      minorUnits: amountMinorUnits,
      currency: originalCurrency,
    );
    if (originalCurrency == reportingCurrency) {
      return (
        amount: original.copyWith(currency: reportingCurrency),
        scaledRate: FxRate.scale,
        rateDate: occurredAt,
        source: 'identity',
        estimated: false,
      );
    }
    final repository = ref.read(exchangeRatesRepositoryProvider);
    FxRate? rate;
    if (originalCurrency == 'USD' && reportingCurrency == 'CAD') {
      rate = await repository.resolve(
        foreignCurrency: 'USD',
        reportingCurrency: 'CAD',
        onOrBefore: occurredAt,
      );
    } else if (originalCurrency == 'CAD' && reportingCurrency == 'USD') {
      rate = await repository.resolve(
        foreignCurrency: 'USD',
        reportingCurrency: 'CAD',
        onOrBefore: occurredAt,
      );
    }
    if (rate == null) throw StateError('fx_rate_unavailable');
    final amount = ref
        .read(currencyConverterProvider)
        .convert(original, reportingCurrency, rate: rate);
    final exactDay =
        rate.rateDate.year == occurredAt.year &&
        rate.rateDate.month == occurredAt.month &&
        rate.rateDate.day == occurredAt.day;
    return (
      amount: amount,
      scaledRate: rate.scaledRate,
      rateDate: rate.rateDate,
      source: exactDay ? rate.source : '${rate.source}_previous_day_fallback',
      estimated: !exactDay,
    );
  }

  /// Local half of the budget-alert pipeline: after a saved expense, record
  /// any threshold its category budget crossed and stash the in-app notice.
  ///
  /// Best effort by design — the expense is already persisted, so an alerting
  /// hiccup must never surface as a submit failure.
  Future<void> _maybeAlertBudget({
    required TransactionType type,
    required String? categoryId,
    required DateTime occurredAt,
  }) async {
    if (type != TransactionType.expense || categoryId == null) return;
    try {
      final household = await ref.read(currentHouseholdProvider.future);
      if (household == null) return;
      final trigger = await ref
          .read(budgetAlertWatcherProvider)
          .onExpenseRecorded(
            householdId: household.id,
            categoryId: categoryId,
            occurredAt: occurredAt,
          );
      if (trigger != null) {
        ref.read(budgetAlertNoticeProvider.notifier).show(trigger);
      }
    } catch (_) {
      // Swallowed on purpose; see doc comment.
    }
  }
}

final quickEntryControllerProvider =
    NotifierProvider<QuickEntryController, AsyncValue<void>>(
      QuickEntryController.new,
    );

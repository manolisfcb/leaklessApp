import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/core_providers.dart';
import '../../../domain/enums/transaction_enums.dart';
import '../../../domain/models/money.dart';
import '../../../domain/models/transaction.dart';
import '../../budgets/application/budget_alert_watcher.dart';
import '../../household/application/household_providers.dart';
import '../../transactions/application/transactions_providers.dart';

/// Handles registering a quick expense/income.
///
/// The UI only collects inputs and calls [submit]; all the work (building the
/// domain object, persisting, analytics) lives here (quality rule #4/#6). Works
/// against the mock repository until Supabase is configured.
class QuickEntryController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  /// Returns true on success so the sheet can close.
  Future<bool> submit({
    required int amountMinorUnits,
    required TransactionType type,
    required TransactionPriority priority,
    required ResponsibleType responsible,
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
      final transaction = Transaction(
        id: '',
        householdId: household.id,
        amount: Money(minorUnits: amountMinorUnits, currency: household.currency),
        type: type,
        priority: priority,
        responsible: responsible,
        categoryId: categoryId,
        occurredAt: when,
        description: description,
      );
      await ref.read(transactionsRepositoryProvider).add(transaction);
      await ref.read(analyticsServiceProvider).transactionCreated();
    });
    state = result;
    if (!result.hasError) {
      await _maybeAlertBudget(
        type: type,
        categoryId: categoryId,
        occurredAt: when,
      );
    }
    return !result.hasError;
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

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/budget.dart';
import '../data/budget_alerts_repository.dart';
import '../data/budgets_repository.dart';
import 'budgets_providers.dart';

/// A budget-alert threshold that just fired for the first time this month.
class BudgetAlertTrigger {
  const BudgetAlertTrigger({
    required this.budget,
    required this.thresholdPct,
    required this.pctSpent,
  });

  final Budget budget;

  /// The most severe threshold this expense newly crossed (80, 100, …).
  final int thresholdPct;

  /// Spent percentage of the budget after the expense, floored.
  final int pctSpent;

  bool get isLimitReached => thresholdPct >= 100;
}

/// Local half of the budget-alert pipeline (the device that records the
/// expense). The Edge Function covers the partner's devices via push; this
/// watcher surfaces the in-app banner right after a quick-entry save.
class BudgetAlertWatcher {
  BudgetAlertWatcher({
    required BudgetsRepository budgetsRepository,
    required BudgetAlertsRepository alertsRepository,
  }) : _budgets = budgetsRepository,
       _alerts = alertsRepository;

  final BudgetsRepository _budgets;
  final BudgetAlertsRepository _alerts;

  /// Checks the budget of [categoryId] for the month of [occurredAt] after an
  /// expense was persisted, and records every threshold it crossed.
  ///
  /// Returns the alert to surface in-app — the most severe threshold this
  /// device recorded first — or null when there is nothing (new) to say.
  Future<BudgetAlertTrigger?> onExpenseRecorded({
    required String householdId,
    required String? categoryId,
    required DateTime occurredAt,
  }) async {
    if (categoryId == null) return null;

    final budgets = await _budgets.fetchForHousehold(householdId);
    Budget? budget;
    for (final candidate in budgets) {
      if (candidate.categoryId == categoryId &&
          candidate.periodStart.year == occurredAt.year &&
          candidate.periodStart.month == occurredAt.month) {
        budget = candidate;
        break;
      }
    }
    if (budget == null || !budget.alertEnabled || budget.limit.minorUnits <= 0) {
      return null;
    }

    // In Supabase mode `spent` is already fresh: the recompute trigger ran in
    // the same statement as the insert the caller just awaited.
    final pctSpent =
        (budget.spent.minorUnits * 100) ~/ budget.limit.minorUnits;
    final crossed = {budget.alertThresholdPct, 100}
        .where((threshold) => pctSpent >= threshold)
        .toList()
      ..sort();

    int? fired;
    for (final threshold in crossed) {
      final recorded = await _alerts.tryRecordAlert(
        budget: budget,
        thresholdPct: threshold,
      );
      if (recorded) fired = threshold;
    }
    if (fired == null) return null;
    return BudgetAlertTrigger(
      budget: budget,
      thresholdPct: fired,
      pctSpent: pctSpent,
    );
  }
}

final budgetAlertWatcherProvider = Provider<BudgetAlertWatcher>(
  (ref) => BudgetAlertWatcher(
    budgetsRepository: ref.watch(budgetsRepositoryProvider),
    alertsRepository: ref.watch(budgetAlertsRepositoryProvider),
  ),
);

/// The latest fired alert waiting to be shown in-app. The quick-entry flow
/// sets it after a successful save and the sheet consumes it as a snackbar.
class BudgetAlertNotice extends Notifier<BudgetAlertTrigger?> {
  @override
  BudgetAlertTrigger? build() => null;

  void show(BudgetAlertTrigger trigger) => state = trigger;

  /// Returns the pending alert (if any) and clears it.
  BudgetAlertTrigger? consume() {
    final trigger = state;
    state = null;
    return trigger;
  }
}

final budgetAlertNoticeProvider =
    NotifierProvider<BudgetAlertNotice, BudgetAlertTrigger?>(
      BudgetAlertNotice.new,
    );

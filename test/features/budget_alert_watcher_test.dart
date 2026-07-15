import 'package:flutter_test/flutter_test.dart';
import 'package:leakless/src/domain/models/budget.dart';
import 'package:leakless/src/domain/models/money.dart';
import 'package:leakless/src/features/budgets/application/budget_alert_watcher.dart';
import 'package:leakless/src/features/budgets/data/budget_alerts_repository.dart';
import 'package:leakless/src/features/budgets/data/budgets_repository.dart';

Budget _budget({
  double spentMajor = 0,
  bool alertEnabled = true,
  int alertThresholdPct = 80,
}) => Budget(
  id: 'bud-1',
  householdId: 'hh-1',
  categoryId: 'cat-1',
  limit: Money.fromMajor(100, currency: 'USD'),
  spent: Money.fromMajor(spentMajor, currency: 'USD'),
  periodStart: DateTime(2026, 7),
  alertEnabled: alertEnabled,
  alertThresholdPct: alertThresholdPct,
);

BudgetAlertWatcher _watcher(
  List<Budget> budgets, {
  BudgetAlertsRepository? alerts,
}) => BudgetAlertWatcher(
  budgetsRepository: _FixedBudgetsRepository(budgets),
  alertsRepository: alerts ?? MockBudgetAlertsRepository(),
);

Future<BudgetAlertTrigger?> _record(
  BudgetAlertWatcher watcher, {
  String? categoryId = 'cat-1',
  DateTime? occurredAt,
}) => watcher.onExpenseRecorded(
  householdId: 'hh-1',
  categoryId: categoryId,
  occurredAt: occurredAt ?? DateTime(2026, 7, 15),
);

void main() {
  test('fires once per threshold and month', () async {
    final watcher = _watcher([_budget(spentMajor: 82)]);

    final first = await _record(watcher);
    expect(first, isNotNull);
    expect(first!.thresholdPct, 80);
    expect(first.pctSpent, 82);
    expect(first.isLimitReached, isFalse);

    // Same threshold, same month: the ledger already has the event.
    expect(await _record(watcher), isNull);
  });

  test('stays quiet below the threshold', () async {
    final watcher = _watcher([_budget(spentMajor: 79)]);
    expect(await _record(watcher), isNull);
  });

  test('respects alert_enabled', () async {
    final watcher = _watcher([_budget(spentMajor: 95, alertEnabled: false)]);
    expect(await _record(watcher), isNull);
  });

  test('reports the limit when spending crosses 100%', () async {
    final alerts = MockBudgetAlertsRepository();
    final watcher = _watcher([_budget(spentMajor: 120)], alerts: alerts);

    final trigger = await _record(watcher);
    expect(trigger!.thresholdPct, 100);
    expect(trigger.isLimitReached, isTrue);

    // Crossing 100% also recorded the 80% event, so a later fetch that sits
    // between both thresholds has nothing new to say.
    final again = _watcher([_budget(spentMajor: 82)], alerts: alerts);
    expect(await _record(again), isNull);
  });

  test(
    'ignores expenses without category or outside the budget month',
    () async {
      final watcher = _watcher([_budget(spentMajor: 95)]);
      expect(await _record(watcher, categoryId: null), isNull);
      expect(await _record(watcher, occurredAt: DateTime(2026, 8, 1)), isNull);
    },
  );

  test('a new month alerts again for the same threshold', () async {
    final alerts = MockBudgetAlertsRepository();
    final july = _watcher([_budget(spentMajor: 85)], alerts: alerts);
    expect(await _record(july), isNotNull);

    final august = _watcher([
      _budget(spentMajor: 85).copyWith(periodStart: DateTime(2026, 8)),
    ], alerts: alerts);
    expect(await _record(august, occurredAt: DateTime(2026, 8, 3)), isNotNull);
  });
}

class _FixedBudgetsRepository implements BudgetsRepository {
  _FixedBudgetsRepository(this.budgets);

  final List<Budget> budgets;

  @override
  Future<List<Budget>> fetchForHousehold(String householdId) async => budgets;

  @override
  Stream<List<Budget>> watchForHousehold(String householdId) =>
      Stream.value(budgets);

  @override
  Future<Budget> create(Budget budget) => throw UnimplementedError();

  @override
  Future<Budget> update(Budget budget) => throw UnimplementedError();

  @override
  Future<void> delete(String budgetId) => throw UnimplementedError();
}

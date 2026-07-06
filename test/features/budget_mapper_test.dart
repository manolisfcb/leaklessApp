import 'package:flutter_test/flutter_test.dart';
import 'package:leakless/src/domain/models/budget.dart';
import 'package:leakless/src/domain/models/money.dart';
import 'package:leakless/src/features/budgets/data/budget_mapper.dart';

void main() {
  test('toInsert writes the first local day of the budget month', () {
    final values = BudgetMapper.toInsert(
      Budget(
        id: '',
        householdId: 'hh-1',
        categoryId: 'cat-1',
        limit: Money.fromMajor(125.50, currency: 'CAD'),
        periodStart: DateTime(2026, 7, 31, 23, 45),
      ),
    );

    expect(values, {
      'household_id': 'hh-1',
      'category_id': 'cat-1',
      'amount_limit': 125.5,
      'currency': 'CAD',
      'period_start': '2026-07-01',
      'alert_enabled': true,
      'alert_threshold_pct': 80,
    });
  });

  test('toUpdate uses the same normalized month format', () {
    final values = BudgetMapper.toUpdate(
      Budget(
        id: 'budget-1',
        householdId: 'hh-1',
        categoryId: 'cat-2',
        limit: Money.fromMajor(80, currency: 'USD'),
        periodStart: DateTime(2027, 1, 15),
      ),
    );

    expect(values['category_id'], 'cat-2');
    expect(values['period_start'], '2027-01-01');
  });

  test('toUpdate writes the alert configuration', () {
    final values = BudgetMapper.toUpdate(
      Budget(
        id: 'budget-1',
        householdId: 'hh-1',
        categoryId: 'cat-2',
        limit: Money.fromMajor(80, currency: 'USD'),
        periodStart: DateTime(2027, 1, 15),
        alertEnabled: false,
        alertThresholdPct: 90,
      ),
    );

    expect(values['alert_enabled'], false);
    expect(values['alert_threshold_pct'], 90);
  });

  test('fromRow reads alert columns and defaults when they are missing', () {
    final row = {
      'id': 'budget-1',
      'household_id': 'hh-1',
      'category_id': 'cat-1',
      'amount_limit': 100,
      'currency': 'USD',
      'period_start': '2026-07-01',
    };

    final withDefaults = BudgetMapper.fromRow(row);
    expect(withDefaults.alertEnabled, isTrue);
    expect(withDefaults.alertThresholdPct, 80);

    final configured = BudgetMapper.fromRow({
      ...row,
      'alert_enabled': false,
      'alert_threshold_pct': 50,
    });
    expect(configured.alertEnabled, isFalse);
    expect(configured.alertThresholdPct, 50);
  });
}

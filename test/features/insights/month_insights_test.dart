import 'package:flutter_test/flutter_test.dart';
import 'package:leakless/src/domain/enums/transaction_enums.dart';
import 'package:leakless/src/domain/models/budget.dart';
import 'package:leakless/src/domain/models/money.dart';
import 'package:leakless/src/domain/models/transaction.dart';
import 'package:leakless/src/domain/models/transaction_category.dart';
import 'package:leakless/src/features/insights/domain/month_insights.dart';

/// July 2026 has 31 days.
final _now = DateTime(2026, 7, 15, 10);

Transaction _expense({
  required int minor,
  required DateTime on,
  String? categoryId,
  TransactionPriority priority = TransactionPriority.lifestyle,
}) => Transaction(
  id: 'tx-${on.microsecondsSinceEpoch}-$minor-$categoryId',
  householdId: 'hh',
  amount: Money(minorUnits: minor),
  type: TransactionType.expense,
  priority: priority,
  responsible: ResponsibleType.me,
  occurredAt: on,
  categoryId: categoryId,
);

Transaction _income({required int minor, required DateTime on}) => Transaction(
  id: 'in-${on.microsecondsSinceEpoch}-$minor',
  householdId: 'hh',
  amount: Money(minorUnits: minor),
  type: TransactionType.income,
  priority: TransactionPriority.necessity,
  responsible: ResponsibleType.me,
  occurredAt: on,
);

Budget _budget(String categoryId, int limitMinor) => Budget(
  id: 'b-$categoryId',
  householdId: 'hh',
  categoryId: categoryId,
  limit: Money(minorUnits: limitMinor),
  periodStart: DateTime(2026, 7),
);

TransactionCategory _cat(String id) =>
    TransactionCategory(id: id, name: id, iconName: 'tag');

MonthInsights _build({
  required List<Transaction> transactions,
  List<Budget> budgets = const [],
  List<TransactionCategory>? categories,
  DateTime? now,
}) {
  final at = now ?? _now;
  final ids = {
    for (final t in transactions)
      if (t.categoryId != null) t.categoryId!,
  };
  return MonthInsights.from(
    month: DateTime(at.year, at.month),
    now: at,
    transactions: transactions,
    budgets: budgets,
    categories: categories ?? [for (final id in ids) _cat(id)],
  );
}

void main() {
  group('month summary & totals', () {
    test('sums only the current month expenses, ignoring income', () {
      final insights = _build(
        transactions: [
          _expense(minor: 1000, on: DateTime(2026, 7, 2), categoryId: 'food'),
          _expense(minor: 2000, on: DateTime(2026, 7, 10), categoryId: 'fun'),
          _income(minor: 9999, on: DateTime(2026, 7, 5)),
          _expense(minor: 5000, on: DateTime(2026, 6, 20), categoryId: 'food'),
        ],
      );

      expect(insights.totalSpent.minorUnits, 3000);
      expect(insights.hasTransactions, isTrue);
      expect(insights.month, DateTime(2026, 7));
    });

    test('budget totals, difference and used pct', () {
      final insights = _build(
        transactions: [
          _expense(minor: 6000, on: DateTime(2026, 7, 3), categoryId: 'food'),
        ],
        budgets: [_budget('food', 10000)],
      );

      expect(insights.totalBudget.minorUnits, 10000);
      expect(insights.budgetDifference.minorUnits, 4000);
      expect(insights.budgetUsedPct, closeTo(0.6, 1e-9));
      expect(insights.hasBudget, isTrue);
    });

    test('no budget leaves used pct null and status onTrack', () {
      final insights = _build(
        transactions: [
          _expense(minor: 6000, on: DateTime(2026, 7, 3), categoryId: 'food'),
        ],
      );
      expect(insights.budgetUsedPct, isNull);
      expect(insights.status, SpendingStatus.onTrack);
    });
  });

  group('status vs month progress', () {
    // Day 15 of a 31-day month → ~48% elapsed.
    test('over when spent exceeds budget', () {
      final insights = _build(
        transactions: [
          _expense(minor: 12000, on: DateTime(2026, 7, 4), categoryId: 'food'),
        ],
        budgets: [_budget('food', 10000)],
      );
      expect(insights.status, SpendingStatus.over);
    });

    test('atRisk when consumed pct outruns the month', () {
      final insights = _build(
        transactions: [
          _expense(minor: 8000, on: DateTime(2026, 7, 4), categoryId: 'food'),
        ],
        budgets: [_budget('food', 10000)], // 80% used at ~48% of month
      );
      expect(insights.status, SpendingStatus.atRisk);
    });

    test('ahead when well under pace', () {
      final insights = _build(
        transactions: [
          _expense(minor: 1000, on: DateTime(2026, 7, 4), categoryId: 'food'),
        ],
        budgets: [_budget('food', 10000)], // 10% used at ~48% of month
      );
      expect(insights.status, SpendingStatus.ahead);
    });
  });

  group('projection', () {
    test('insufficient data early in the month (day 1)', () {
      final insights = _build(
        now: DateTime(2026, 7, 1, 12),
        transactions: [
          _expense(minor: 1000, on: DateTime(2026, 7, 1), categoryId: 'food'),
        ],
      );
      expect(insights.projection.confidence,
          ProjectionConfidence.insufficientData);
      expect(insights.projection.projectedTotal, isNull);
    });

    test('insufficient data with too few expenses even past day 5', () {
      final insights = _build(
        transactions: [
          _expense(minor: 1000, on: DateTime(2026, 7, 2), categoryId: 'food'),
          _expense(minor: 1000, on: DateTime(2026, 7, 8), categoryId: 'food'),
        ], // only 2 expenses < min 3
      );
      expect(insights.projection.confidence,
          ProjectionConfidence.insufficientData);
    });

    test('reliable projection extrapolates the run rate', () {
      // 3000 spent over 15 days → 3000/15*31 = 6200.
      final insights = _build(
        transactions: [
          _expense(minor: 1000, on: DateTime(2026, 7, 2), categoryId: 'food'),
          _expense(minor: 1000, on: DateTime(2026, 7, 8), categoryId: 'food'),
          _expense(minor: 1000, on: DateTime(2026, 7, 12), categoryId: 'food'),
        ],
        budgets: [_budget('food', 5000)],
      );
      expect(insights.projection.confidence, ProjectionConfidence.reliable);
      expect(insights.projection.projectedTotal!.minorUnits, 6200);
      expect(insights.projection.projectedOverBudget!.minorUnits, 1200);
      expect(insights.pace.amountToReduce!.minorUnits, 1200);
    });
  });

  group('spending pace', () {
    test('expected to date is linear across the budget', () {
      final insights = _build(
        transactions: [
          _expense(minor: 5000, on: DateTime(2026, 7, 3), categoryId: 'food'),
        ],
        budgets: [_budget('food', 31000)], // 1000/day → 15000 expected by day 15
      );
      expect(insights.pace.expectedToDate.minorUnits, 15000);
      expect(insights.pace.actualToDate.minorUnits, 5000);
      expect(insights.pace.difference.minorUnits, -10000);
    });
  });

  group('runaway categories', () {
    test('no history yields no runaways', () {
      final insights = _build(
        transactions: [
          _expense(minor: 50000, on: DateTime(2026, 7, 3), categoryId: 'food'),
        ],
      );
      expect(insights.runawayCategories, isEmpty);
    });

    test('flags a category well above its 3-month average', () {
      final insights = _build(
        transactions: [
          // history: 10000 in each of the two prior months → avg 10000.
          _expense(minor: 10000, on: DateTime(2026, 6, 5), categoryId: 'food'),
          _expense(minor: 10000, on: DateTime(2026, 5, 5), categoryId: 'food'),
          // current: 20000 → +100% over average.
          _expense(minor: 20000, on: DateTime(2026, 7, 5), categoryId: 'food'),
        ],
      );
      expect(insights.runawayCategories, hasLength(1));
      final r = insights.runawayCategories.first;
      expect(r.categoryId, 'food');
      expect(r.overshootPct, closeTo(1.0, 1e-9));
    });

    test('respects the floor amount to avoid tiny-base noise', () {
      final insights = _build(
        transactions: [
          _expense(minor: 100, on: DateTime(2026, 6, 5), categoryId: 'food'),
          _expense(minor: 100, on: DateTime(2026, 5, 5), categoryId: 'food'),
          // +300% but only $5 in minor units → below the floor.
          _expense(minor: 400, on: DateTime(2026, 7, 5), categoryId: 'food'),
        ],
      );
      expect(insights.runawayCategories, isEmpty);
    });

    test('needs at least two months of history', () {
      final insights = _build(
        transactions: [
          _expense(minor: 10000, on: DateTime(2026, 6, 5), categoryId: 'food'),
          _expense(minor: 30000, on: DateTime(2026, 7, 5), categoryId: 'food'),
        ], // only one prior month
      );
      expect(insights.runawayCategories, isEmpty);
    });
  });

  group('category breakdown', () {
    test('shares, limits and last activity, sorted by spend', () {
      final insights = _build(
        transactions: [
          _expense(minor: 3000, on: DateTime(2026, 7, 2), categoryId: 'food'),
          _expense(minor: 1000, on: DateTime(2026, 7, 9), categoryId: 'food'),
          _expense(minor: 6000, on: DateTime(2026, 7, 4), categoryId: 'fun'),
        ],
        budgets: [_budget('food', 8000)],
      );

      expect(insights.categories.map((c) => c.categoryId), ['fun', 'food']);
      final food = insights.categories.firstWhere((c) => c.categoryId == 'food');
      expect(food.spent.minorUnits, 4000);
      expect(food.shareOfTotal, closeTo(0.4, 1e-9));
      expect(food.limit!.minorUnits, 8000);
      expect(food.limitRatio, closeTo(0.5, 1e-9));
      expect(food.lastActivity, DateTime(2026, 7, 9));
      final fun = insights.categories.firstWhere((c) => c.categoryId == 'fun');
      expect(fun.limit, isNull);
    });

    test('drops spend for categories not in the catalog', () {
      final insights = MonthInsights.from(
        month: DateTime(2026, 7),
        now: _now,
        transactions: [
          _expense(minor: 3000, on: DateTime(2026, 7, 2), categoryId: 'orphan'),
        ],
        budgets: const [],
        categories: [_cat('food')],
      );
      expect(insights.categories, isEmpty);
      // Still counted in the total.
      expect(insights.totalSpent.minorUnits, 3000);
    });
  });

  group('historical comparison', () {
    test('no previous month leaves change null and stable', () {
      final insights = _build(
        transactions: [
          _expense(minor: 3000, on: DateTime(2026, 7, 2), categoryId: 'food'),
        ],
      );
      expect(insights.comparison.hasPreviousMonth, isFalse);
      expect(insights.comparison.changeVsPreviousPct, isNull);
      expect(insights.comparison.directionVsPrevious, TrendDirection.stable);
      expect(insights.comparison.changeVsAveragePct, isNull);
    });

    test('computes month-over-month change and direction', () {
      final insights = _build(
        transactions: [
          _expense(minor: 10000, on: DateTime(2026, 6, 3), categoryId: 'food'),
          _expense(minor: 15000, on: DateTime(2026, 7, 3), categoryId: 'food'),
        ],
      );
      expect(insights.comparison.hasPreviousMonth, isTrue);
      expect(insights.comparison.previousMonth.minorUnits, 10000);
      expect(insights.comparison.changeVsPreviousPct, closeTo(0.5, 1e-9));
      expect(insights.comparison.directionVsPrevious, TrendDirection.up);
    });

    test('recent totals are the last four months oldest to newest', () {
      final insights = _build(
        transactions: [
          _expense(minor: 100, on: DateTime(2026, 4, 3), categoryId: 'food'),
          _expense(minor: 200, on: DateTime(2026, 5, 3), categoryId: 'food'),
          _expense(minor: 300, on: DateTime(2026, 6, 3), categoryId: 'food'),
          _expense(minor: 400, on: DateTime(2026, 7, 3), categoryId: 'food'),
        ],
      );
      expect(
        insights.comparison.recentTotals.map((m) => m.month),
        [DateTime(2026, 4), DateTime(2026, 5), DateTime(2026, 6), DateTime(2026, 7)],
      );
      expect(
        insights.comparison.recentTotals.map((m) => m.total.minorUnits),
        [100, 200, 300, 400],
      );
    });
  });

  group('daily spending', () {
    test('by-day map, average, most expensive day and quiet days', () {
      final insights = _build(
        transactions: [
          _expense(minor: 1000, on: DateTime(2026, 7, 2), categoryId: 'food'),
          _expense(minor: 500, on: DateTime(2026, 7, 2), categoryId: 'food'),
          _expense(minor: 4000, on: DateTime(2026, 7, 10), categoryId: 'fun'),
        ],
      );
      expect(insights.daily.byDay[2]!.minorUnits, 1500);
      expect(insights.daily.byDay[10]!.minorUnits, 4000);
      expect(insights.daily.mostExpensiveDay, 10);
      expect(insights.daily.mostExpensiveDayAmount.minorUnits, 4000);
      // 15 days elapsed, spend on 2 of them.
      expect(insights.daily.daysWithoutSpend, 13);
    });
  });

  group('weekday pattern', () {
    test('averages per weekday and picks the priciest', () {
      // No history → window is the current month only.
      // July 6 2026 is a Monday, July 13 also Monday.
      final insights = _build(
        transactions: [
          _expense(minor: 2000, on: DateTime(2026, 7, 6), categoryId: 'food'),
          _expense(minor: 2000, on: DateTime(2026, 7, 13), categoryId: 'food'),
          _expense(minor: 100, on: DateTime(2026, 7, 7), categoryId: 'food'),
        ],
      );
      // Monday (weekday 1) has the most spend.
      expect(insights.weekday.mostExpensiveWeekday, DateTime.monday);
      expect(insights.weekday.averageByWeekday[DateTime.monday], isNotNull);
    });

    test('no expenses leaves most/least weekday null', () {
      final insights = _build(
        transactions: [_income(minor: 5000, on: DateTime(2026, 7, 3))],
      );
      expect(insights.weekday.mostExpensiveWeekday, isNull);
      expect(insights.weekday.leastExpensiveWeekday, isNull);
    });
  });

  group('uncategorized', () {
    test('counts and sums expenses without a category', () {
      final insights = _build(
        transactions: [
          _expense(minor: 1000, on: DateTime(2026, 7, 2)),
          _expense(minor: 2500, on: DateTime(2026, 7, 5)),
          _expense(minor: 999, on: DateTime(2026, 7, 6), categoryId: 'food'),
        ],
      );
      expect(insights.uncategorized.count, 2);
      expect(insights.uncategorized.amount.minorUnits, 3500);
      expect(insights.uncategorized.isEmpty, isFalse);
    });
  });

  group('recommendations', () {
    test('all on track when nothing is wrong', () {
      final insights = _build(
        transactions: [
          _expense(minor: 1000, on: DateTime(2026, 7, 2), categoryId: 'food'),
          _expense(minor: 1000, on: DateTime(2026, 7, 8), categoryId: 'food'),
          _expense(minor: 1000, on: DateTime(2026, 7, 12), categoryId: 'food'),
        ],
        budgets: [_budget('food', 50000)], // huge budget, no projection over
      );
      expect(insights.recommendations, hasLength(1));
      expect(insights.recommendations.first.kind,
          InsightRecommendationKind.allOnTrack);
    });

    test('suggests trimming the top category when projected over budget', () {
      final insights = _build(
        transactions: [
          _expense(minor: 4000, on: DateTime(2026, 7, 2), categoryId: 'fun'),
          _expense(minor: 4000, on: DateTime(2026, 7, 8), categoryId: 'fun'),
          _expense(minor: 4000, on: DateTime(2026, 7, 12), categoryId: 'food'),
        ],
        budgets: [_budget('fun', 5000), _budget('food', 5000)],
      );
      final top = insights.recommendations.first;
      expect(top.kind, InsightRecommendationKind.reduceCategory);
      expect(top.categoryId, 'fun'); // highest spend
      expect(top.amount, isNotNull);
    });
  });

  group('empty month', () {
    test('reports no transactions with zeroed metrics', () {
      final insights = _build(transactions: const []);
      expect(insights.hasTransactions, isFalse);
      expect(insights.totalSpent.minorUnits, 0);
      expect(insights.categories, isEmpty);
      expect(insights.runawayCategories, isEmpty);
      expect(insights.uncategorized.isEmpty, isTrue);
      expect(insights.projection.confidence,
          ProjectionConfidence.insufficientData);
      expect(insights.recommendations.first.kind,
          InsightRecommendationKind.allOnTrack);
    });
  });
}

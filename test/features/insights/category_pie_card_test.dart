import 'package:flutter_test/flutter_test.dart';
import 'package:leakless/src/domain/models/money.dart';
import 'package:leakless/src/features/insights/domain/month_insights.dart';
import 'package:leakless/src/features/insights/presentation/widgets/category_pie_card.dart';

MonthInsights _insightsWith(List<CategoryInsight> categories) => MonthInsights(
  month: DateTime(2026, 7),
  currency: 'USD',
  hasTransactions: true,
  totalSpent: categories.fold(Money.zero, (s, c) => s + c.spent),
  totalBudget: Money.zero,
  budgetDifference: Money.zero,
  status: SpendingStatus.onTrack,
  pace: const SpendingPace(
    expectedToDate: Money.zero,
    actualToDate: Money.zero,
    difference: Money.zero,
  ),
  projection: const SpendingProjection(
    confidence: ProjectionConfidence.insufficientData,
  ),
  categories: categories,
  runawayCategories: const [],
  comparison: const HistoricalComparison(
    currentMonth: Money.zero,
    previousMonth: Money.zero,
    hasPreviousMonth: false,
    directionVsPrevious: TrendDirection.stable,
    threeMonthAverage: Money.zero,
    directionVsAverage: TrendDirection.stable,
    recentTotals: [],
  ),
  daily: const DailySpending(
    byDay: {},
    dailyAverage: Money.zero,
    daysWithoutSpend: 0,
  ),
  weekday: const WeekdaySpending(averageByWeekday: {}),
  uncategorized: const UncategorizedSpending(count: 0, amount: Money.zero),
  recommendations: const [],
);

CategoryInsight _category(
  String id, {
  required int minor,
  required double share,
}) => CategoryInsight(
  categoryId: id,
  spent: Money(minorUnits: minor),
  shareOfTotal: share,
  lastActivity: DateTime(2026, 7, 1),
);

void main() {
  group('CategoryPieCard.topSlices', () {
    test('returns all categories with no Others bucket when <= 5', () {
      final categories = [
        _category('a', minor: 5000, share: 0.5),
        _category('b', minor: 3000, share: 0.3),
        _category('c', minor: 2000, share: 0.2),
      ];

      final slices = CategoryPieCard.topSlices(
        _insightsWith(categories),
        const {},
      );

      expect(slices, hasLength(3));
      expect(slices.map((s) => s.categoryId), ['a', 'b', 'c']);
    });

    test(
      'aggregates categories beyond the top 5 into a single Others bucket',
      () {
        final categories = [
          for (var i = 0; i < 7; i++)
            _category('cat$i', minor: (7 - i) * 1000, share: (7 - i) / 28),
        ];

        final slices = CategoryPieCard.topSlices(
          _insightsWith(categories),
          const {},
        );

        expect(slices, hasLength(6));
        expect(slices.take(5).map((s) => s.categoryId), [
          'cat0',
          'cat1',
          'cat2',
          'cat3',
          'cat4',
        ]);

        final others = slices.last;
        expect(others.categoryId, '_others');
        // cat5 (2000) + cat6 (1000) = 3000.
        expect(others.spent.minorUnits, 3000);
        expect(others.shareOfTotal, closeTo(2 / 28 + 1 / 28, 1e-9));
      },
    );

    test('exactly 5 categories has no Others bucket', () {
      final categories = [
        for (var i = 0; i < 5; i++) _category('cat$i', minor: 1000, share: 0.2),
      ];

      final slices = CategoryPieCard.topSlices(
        _insightsWith(categories),
        const {},
      );

      expect(slices, hasLength(5));
      expect(slices.any((s) => s.categoryId == '_others'), isFalse);
    });
  });
}

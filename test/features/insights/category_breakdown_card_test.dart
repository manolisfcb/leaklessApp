import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:leakless/src/core/l10n/app_localizations.dart';
import 'package:leakless/src/core/theme/app_colors.dart';
import 'package:leakless/src/domain/models/money.dart';
import 'package:leakless/src/features/insights/domain/month_insights.dart';
import 'package:leakless/src/features/insights/presentation/widgets/category_breakdown_card.dart';

MonthInsights _insightsWith(CategoryInsight category) => MonthInsights(
  month: DateTime(2026, 7),
  currency: 'USD',
  hasTransactions: true,
  totalSpent: category.spent,
  totalBudget: category.limit ?? Money.zero,
  budgetDifference: (category.limit ?? Money.zero) - category.spent,
  status: SpendingStatus.onTrack,
  pace: const SpendingPace(
    expectedToDate: Money.zero,
    actualToDate: Money.zero,
    difference: Money.zero,
  ),
  projection: const SpendingProjection(
    confidence: ProjectionConfidence.insufficientData,
  ),
  categories: [category],
  runawayCategories: const [],
  comparison: HistoricalComparison(
    currentMonth: category.spent,
    previousMonth: Money.zero,
    hasPreviousMonth: false,
    directionVsPrevious: TrendDirection.stable,
    threeMonthAverage: Money.zero,
    directionVsAverage: TrendDirection.stable,
    recentTotals: const [],
  ),
  daily: const DailySpending(byDay: {}, dailyAverage: Money.zero, daysWithoutSpend: 0),
  weekday: const WeekdaySpending(averageByWeekday: {}),
  uncategorized: const UncategorizedSpending(count: 0, amount: Money.zero),
  recommendations: const [],
);

Widget _wrap(Widget child) => MaterialApp(
  theme: ThemeData(extensions: const [AppColors.light]),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('es'),
  home: Scaffold(body: child),
);

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('CategoryBreakdownCard', () {
    testWidgets('shows remaining budget when under limit', (tester) async {
      final category = CategoryInsight(
        categoryId: 'food',
        spent: const Money(minorUnits: 6000),
        shareOfTotal: 0.6,
        lastActivity: DateTime(2026, 7, 1),
        limit: const Money(minorUnits: 10000),
        limitRatio: 0.6,
      );

      await tester.pumpWidget(
        _wrap(
          CategoryBreakdownCard(
            insights: _insightsWith(category),
            categories: const {},
            onCreateBudget: () {},
          ),
        ),
      );

      expect(find.text('Quedan \$40.00'), findsOneWidget);
    });

    testWidgets('shows over-budget amount when limit is exceeded', (tester) async {
      final category = CategoryInsight(
        categoryId: 'food',
        spent: const Money(minorUnits: 12000),
        shareOfTotal: 1.0,
        lastActivity: DateTime(2026, 7, 1),
        limit: const Money(minorUnits: 10000),
        limitRatio: 1.2,
      );

      await tester.pumpWidget(
        _wrap(
          CategoryBreakdownCard(
            insights: _insightsWith(category),
            categories: const {},
            onCreateBudget: () {},
          ),
        ),
      );

      expect(find.text('Excedido por \$20.00'), findsOneWidget);
    });
  });
}

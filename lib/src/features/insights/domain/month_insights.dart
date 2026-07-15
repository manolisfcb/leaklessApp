import '../../../domain/enums/transaction_enums.dart';
import '../../../domain/models/budget.dart';
import '../../../domain/models/money.dart';
import '../../../domain/models/transaction.dart';
import '../../../domain/models/transaction_category.dart';

/// How the month's spending is tracking against its budget, comparing the
/// percentage of budget consumed with the percentage of the month elapsed.
enum SpendingStatus { onTrack, ahead, atRisk, over }

/// Direction of a change, with a neutral band so tiny wobbles read as [stable].
enum TrendDirection { up, down, stable }

/// Whether the end-of-month projection has enough signal to be trustworthy.
enum ProjectionConfidence { reliable, insufficientData }

/// The kind of a recommendation. The domain stays UI-agnostic and returns
/// keys + structured args (never localized strings); presentation maps these to
/// `context.l10n` messages.
enum InsightRecommendationKind {
  /// Projected to overspend the total budget — trim the top category.
  reduceCategory,

  /// A category is spending far above its recent average.
  runawayCategory,

  /// Everything is within pace — positive reinforcement.
  allOnTrack,
}

/// A per-category slice of the month: what was spent, how it compares to its
/// recent average, and (if a budget exists) how close it is to the limit.
class CategoryInsight {
  const CategoryInsight({
    required this.categoryId,
    required this.spent,
    required this.shareOfTotal,
    required this.lastActivity,
    this.limit,
    this.limitRatio,
    this.threeMonthAverage,
    this.trend,
    this.trendPct,
  });

  final String categoryId;
  final Money spent;

  /// Fraction of the month's total spend, 0..1.
  final double shareOfTotal;

  /// Most recent transaction date for this category in the month.
  final DateTime lastActivity;

  final Money? limit;

  /// spent / limit when a limit exists.
  final double? limitRatio;

  /// Average monthly spend over the preceding months that have data.
  final Money? threeMonthAverage;

  /// Direction vs [threeMonthAverage] (null when there is no history).
  final TrendDirection? trend;

  /// Signed change vs [threeMonthAverage] (0.2 = +20%).
  final double? trendPct;
}

/// A category spending materially above its recent average — surfaced only with
/// enough history and above a floor amount so tiny bases don't produce noise.
class RunawayCategory {
  const RunawayCategory({
    required this.categoryId,
    required this.currentSpend,
    required this.averageSpend,
    required this.overshootPct,
  });

  final String categoryId;
  final Money currentSpend;
  final Money averageSpend;

  /// currentSpend / averageSpend − 1 (0.5 = 50% over average).
  final double overshootPct;
}

/// One month's total, used for the mini-trend series.
class MonthTotal {
  const MonthTotal({required this.month, required this.total});

  final DateTime month;
  final Money total;
}

/// Month-over-month and vs-3-month-average comparison plus a short series for
/// the mini-trend chart.
class HistoricalComparison {
  const HistoricalComparison({
    required this.currentMonth,
    required this.previousMonth,
    required this.hasPreviousMonth,
    required this.directionVsPrevious,
    required this.threeMonthAverage,
    required this.directionVsAverage,
    required this.recentTotals,
    this.changeVsPreviousPct,
    this.changeVsAveragePct,
  });

  final Money currentMonth;
  final Money previousMonth;
  final bool hasPreviousMonth;
  final double? changeVsPreviousPct;
  final TrendDirection directionVsPrevious;
  final Money threeMonthAverage;
  final double? changeVsAveragePct;
  final TrendDirection directionVsAverage;

  /// Last 4 months, oldest → newest (ends with the current month).
  final List<MonthTotal> recentTotals;
}

/// End-of-month spend projection extrapolated from the run rate so far.
class SpendingProjection {
  const SpendingProjection({
    required this.confidence,
    this.projectedTotal,
    this.projectedOverBudget,
  });

  final ProjectionConfidence confidence;

  /// null when [confidence] is [ProjectionConfidence.insufficientData].
  final Money? projectedTotal;

  /// projectedTotal − totalBudget when it overshoots a positive budget.
  final Money? projectedOverBudget;

  bool get isReliable => confidence == ProjectionConfidence.reliable;
}

/// Spend to date vs the linear budget pace, and the amount to trim to still
/// close the month on budget.
class SpendingPace {
  const SpendingPace({
    required this.expectedToDate,
    required this.actualToDate,
    required this.difference,
    this.amountToReduce,
  });

  /// totalBudget × (daysElapsed / daysInMonth).
  final Money expectedToDate;
  final Money actualToDate;

  /// actualToDate − expectedToDate (positive = spending ahead of pace).
  final Money difference;

  /// How much to cut to land on budget given the current projection.
  final Money? amountToReduce;
}

/// Day-of-month spending shape for the current month.
class DailySpending {
  const DailySpending({
    required this.byDay,
    required this.dailyAverage,
    required this.daysWithoutSpend,
    this.mostExpensiveDay,
    this.mostExpensiveDayAmount = Money.zero,
  });

  /// day-of-month (1..31) → amount spent.
  final Map<int, Money> byDay;
  final Money dailyAverage;
  final int daysWithoutSpend;
  final int? mostExpensiveDay;
  final Money mostExpensiveDayAmount;
}

/// Average spend per weekday (1 = Monday … 7 = Sunday, per [DateTime.weekday]).
class WeekdaySpending {
  const WeekdaySpending({
    required this.averageByWeekday,
    this.mostExpensiveWeekday,
    this.leastExpensiveWeekday,
  });

  final Map<int, Money> averageByWeekday;
  final int? mostExpensiveWeekday;
  final int? leastExpensiveWeekday;
}

/// Count and amount of the month's expenses with no category.
class UncategorizedSpending {
  const UncategorizedSpending({required this.count, required this.amount});

  final int count;
  final Money amount;

  bool get isEmpty => count == 0;
}

/// A single actionable nudge. Holds a [kind] plus optional structured args so
/// the presentation layer can localize it.
class InsightRecommendation {
  const InsightRecommendation({
    required this.kind,
    this.categoryId,
    this.amount,
  });

  final InsightRecommendationKind kind;
  final String? categoryId;
  final Money? amount;
}

/// Immutable read-model for the insights ("Dashboard") screen. All aggregation
/// lives in [MonthInsights.from]; widgets render fields only (quality rule #4).
class MonthInsights {
  const MonthInsights({
    required this.month,
    required this.currency,
    required this.hasTransactions,
    required this.totalSpent,
    required this.totalBudget,
    required this.budgetDifference,
    required this.status,
    required this.pace,
    required this.projection,
    required this.categories,
    required this.runawayCategories,
    required this.comparison,
    required this.daily,
    required this.weekday,
    required this.uncategorized,
    required this.recommendations,
    this.budgetUsedPct,
  });

  final DateTime month;
  final String currency;

  /// Whether the household has any expense in its whole history (drives the
  /// top-level empty state).
  final bool hasTransactions;

  final Money totalSpent;

  /// Σ of the month's category budget limits (0 when none are set).
  final Money totalBudget;

  /// totalBudget − totalSpent.
  final Money budgetDifference;

  /// totalSpent / totalBudget, null when there is no budget.
  final double? budgetUsedPct;

  final SpendingStatus status;
  final SpendingPace pace;
  final SpendingProjection projection;

  /// Categories with spend this month, sorted by spend descending.
  final List<CategoryInsight> categories;

  /// Categories spending well above their recent average, worst first.
  final List<RunawayCategory> runawayCategories;

  final HistoricalComparison comparison;
  final DailySpending daily;
  final WeekdaySpending weekday;
  final UncategorizedSpending uncategorized;

  /// Ordered by impact (highest-value nudge first).
  final List<InsightRecommendation> recommendations;

  bool get hasBudget => totalBudget.minorUnits > 0;

  // --- Tunables (exposed so tests can pin behavior). -----------------------

  /// Month spend below this floor never flags a runaway (avoids "+300% on $2").
  static const int runawayFloorMinorUnits = 2000;

  /// A category must exceed its average by this fraction to be a runaway.
  static const double runawayThreshold = 0.15;

  /// Neutral band for pace/trend direction (±5%).
  static const double neutralBand = 0.05;

  /// Days elapsed required before the projection is trusted.
  static const int minDaysForProjection = 5;

  /// Expenses this month required before the projection is trusted.
  static const int minExpensesForProjection = 3;

  static MonthInsights from({
    required DateTime month,
    required DateTime now,
    required List<Transaction> transactions,
    required List<Budget> budgets,
    required List<TransactionCategory> categories,
    String currency = 'USD',
  }) {
    Money money(int minor) => Money(minorUnits: minor, currency: currency);
    int reportingMinor(Transaction transaction) {
      final reporting = transaction.reportingAmount;
      if (reporting != null && reporting.currency == currency) {
        return reporting.absolute.minorUnits;
      }
      return transaction.amount.currency == currency
          ? transaction.amount.absolute.minorUnits
          : 0;
    }

    bool inMonth(DateTime d, DateTime m) =>
        d.year == m.year && d.month == m.month;

    final validCategoryIds = {for (final c in categories) c.id};
    final monthStart = DateTime(month.year, month.month);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final isCurrentMonth = now.year == month.year && now.month == month.month;
    final daysElapsed = isCurrentMonth ? now.day : daysInMonth;
    final monthProgress = daysInMonth > 0 ? daysElapsed / daysInMonth : 0.0;

    final expenses = [
      for (final t in transactions)
        if (t.isExpense && t.status == TransactionStatus.confirmed) t,
    ];
    final monthExpenses = [
      for (final t in expenses)
        if (inMonth(t.occurredAt, month)) t,
    ];

    int sumMinor(Iterable<Transaction> txs) =>
        txs.fold(0, (s, t) => s + reportingMinor(t));

    int monthTotalMinor(DateTime m) =>
        sumMinor(expenses.where((t) => inMonth(t.occurredAt, m)));

    Map<String, int> categorySpend(DateTime m) {
      final map = <String, int>{};
      for (final t in expenses) {
        if (!inMonth(t.occurredAt, m)) continue;
        final cid = t.categoryId;
        if (cid == null) continue;
        map[cid] = (map[cid] ?? 0) + reportingMinor(t);
      }
      return map;
    }

    final totalSpentMinor = sumMinor(monthExpenses);
    final preceding = [
      for (var i = 1; i <= 3; i++) DateTime(month.year, month.month - i),
    ];
    final currentSpend = categorySpend(month);
    final precedingSpend = preceding.map(categorySpend).toList();

    final budgetsByCat = {for (final b in budgets) b.categoryId: b};
    final totalBudgetMinor = budgets.fold(0, (s, b) => s + b.limit.minorUnits);

    // --- Per-category breakdown. ---------------------------------------------
    final categoryInsights = <CategoryInsight>[];
    final runaways = <RunawayCategory>[];
    for (final entry in currentSpend.entries) {
      final cid = entry.key;
      if (!validCategoryIds.contains(cid)) continue;
      final spent = entry.value;

      final history = [
        for (final m in precedingSpend)
          if (m[cid] != null) m[cid]!,
      ];
      Money? avg;
      TrendDirection? trend;
      double? trendPct;
      if (history.isNotEmpty) {
        final avgMinor = (history.reduce((a, b) => a + b) / history.length)
            .round();
        avg = money(avgMinor);
        if (avgMinor > 0) {
          trendPct = (spent - avgMinor) / avgMinor;
          trend = _direction(trendPct);
        } else {
          trend = TrendDirection.stable;
        }
      }

      final budget = budgetsByCat[cid];
      final lastActivity = monthExpenses
          .where((t) => t.categoryId == cid)
          .map((t) => t.occurredAt)
          .reduce((a, b) => a.isAfter(b) ? a : b);

      categoryInsights.add(
        CategoryInsight(
          categoryId: cid,
          spent: money(spent),
          shareOfTotal: totalSpentMinor > 0 ? spent / totalSpentMinor : 0,
          lastActivity: lastActivity,
          limit: budget?.limit,
          limitRatio: (budget != null && budget.limit.minorUnits > 0)
              ? spent / budget.limit.minorUnits
              : null,
          threeMonthAverage: avg,
          trend: trend,
          trendPct: trendPct,
        ),
      );

      // Runaway: enough history (>=2 months with data), above a floor, and
      // materially over the average.
      if (spent >= runawayFloorMinorUnits && history.length >= 2) {
        final avgMinor = (history.reduce((a, b) => a + b) / history.length)
            .round();
        if (avgMinor > 0) {
          final overshoot = spent / avgMinor - 1;
          if (overshoot >= runawayThreshold) {
            runaways.add(
              RunawayCategory(
                categoryId: cid,
                currentSpend: money(spent),
                averageSpend: money(avgMinor),
                overshootPct: overshoot,
              ),
            );
          }
        }
      }
    }
    categoryInsights.sort(
      (a, b) => b.spent.minorUnits.compareTo(a.spent.minorUnits),
    );
    runaways.sort((a, b) => b.overshootPct.compareTo(a.overshootPct));

    // --- Projection. ---------------------------------------------------------
    final reliable =
        daysElapsed >= minDaysForProjection &&
        monthExpenses.length >= minExpensesForProjection;
    int? projectedTotalMinor;
    int? projectedOverMinor;
    if (reliable && daysElapsed > 0) {
      projectedTotalMinor = (totalSpentMinor / daysElapsed * daysInMonth)
          .round();
      if (totalBudgetMinor > 0 && projectedTotalMinor > totalBudgetMinor) {
        projectedOverMinor = projectedTotalMinor - totalBudgetMinor;
      }
    }
    final projection = SpendingProjection(
      confidence: reliable
          ? ProjectionConfidence.reliable
          : ProjectionConfidence.insufficientData,
      projectedTotal: projectedTotalMinor == null
          ? null
          : money(projectedTotalMinor),
      projectedOverBudget: projectedOverMinor == null
          ? null
          : money(projectedOverMinor),
    );

    // --- Pace. ---------------------------------------------------------------
    final expectedMinor = (totalBudgetMinor * monthProgress).round();
    final pace = SpendingPace(
      expectedToDate: money(expectedMinor),
      actualToDate: money(totalSpentMinor),
      difference: money(totalSpentMinor - expectedMinor),
      amountToReduce: projectedOverMinor == null
          ? null
          : money(projectedOverMinor),
    );

    // --- Status. -------------------------------------------------------------
    final SpendingStatus status;
    if (totalBudgetMinor <= 0) {
      status = SpendingStatus.onTrack;
    } else {
      final ratio = totalSpentMinor / totalBudgetMinor;
      if (ratio >= 1.0) {
        status = SpendingStatus.over;
      } else {
        final delta = ratio - monthProgress;
        if (delta > neutralBand) {
          status = SpendingStatus.atRisk;
        } else if (delta < -neutralBand) {
          status = SpendingStatus.ahead;
        } else {
          status = SpendingStatus.onTrack;
        }
      }
    }

    // --- Historical comparison. ---------------------------------------------
    final prevMonthDate = preceding.first;
    final previousTotalMinor = monthTotalMinor(prevMonthDate);
    final hasPreviousMonth = expenses.any(
      (t) => inMonth(t.occurredAt, prevMonthDate),
    );
    final changeVsPrev = previousTotalMinor > 0
        ? (totalSpentMinor - previousTotalMinor) / previousTotalMinor
        : null;

    final monthsWithHistory = preceding.where(
      (m) => expenses.any((t) => inMonth(t.occurredAt, m)),
    );
    final avg3Minor = monthsWithHistory.isEmpty
        ? 0
        : (monthsWithHistory.fold(0, (s, m) => s + monthTotalMinor(m)) /
                  monthsWithHistory.length)
              .round();
    final changeVsAvg = avg3Minor > 0
        ? (totalSpentMinor - avg3Minor) / avg3Minor
        : null;

    final recentTotals = [
      for (final m in [preceding[2], preceding[1], preceding[0], month])
        MonthTotal(month: m, total: money(monthTotalMinor(m))),
    ];

    final comparison = HistoricalComparison(
      currentMonth: money(totalSpentMinor),
      previousMonth: money(previousTotalMinor),
      hasPreviousMonth: hasPreviousMonth,
      changeVsPreviousPct: changeVsPrev,
      directionVsPrevious: _direction(changeVsPrev),
      threeMonthAverage: money(avg3Minor),
      changeVsAveragePct: changeVsAvg,
      directionVsAverage: _direction(changeVsAvg),
      recentTotals: recentTotals,
    );

    // --- Daily. --------------------------------------------------------------
    final byDayMinor = <int, int>{};
    for (final t in monthExpenses) {
      final d = t.occurredAt.day;
      byDayMinor[d] = (byDayMinor[d] ?? 0) + reportingMinor(t);
    }
    int? mostExpensiveDay;
    var mostExpensiveDayMinor = 0;
    byDayMinor.forEach((day, minor) {
      if (minor > mostExpensiveDayMinor) {
        mostExpensiveDayMinor = minor;
        mostExpensiveDay = day;
      }
    });
    final daily = DailySpending(
      byDay: {for (final e in byDayMinor.entries) e.key: money(e.value)},
      dailyAverage: money(
        daysElapsed > 0 ? (totalSpentMinor / daysElapsed).round() : 0,
      ),
      daysWithoutSpend: (daysElapsed - byDayMinor.keys.length).clamp(
        0,
        daysInMonth,
      ),
      mostExpensiveDay: mostExpensiveDay,
      mostExpensiveDayAmount: money(mostExpensiveDayMinor),
    );

    // --- Weekday pattern. ----------------------------------------------------
    final hasHistory = expenses.any((t) => t.occurredAt.isBefore(monthStart));
    final windowStart = hasHistory
        ? DateTime(month.year, month.month - 2, 1)
        : monthStart;
    final windowEnd = isCurrentMonth
        ? DateTime(now.year, now.month, now.day)
        : DateTime(month.year, month.month, daysInMonth);
    final weekdaySpendMinor = <int, int>{};
    for (final t in expenses) {
      final d = t.occurredAt;
      if (d.isBefore(windowStart)) continue;
      if (d.isAfter(windowEnd)) continue;
      weekdaySpendMinor[d.weekday] =
          (weekdaySpendMinor[d.weekday] ?? 0) + reportingMinor(t);
    }
    final weekdayDayCount = <int, int>{};
    for (
      var d = windowStart;
      !d.isAfter(windowEnd);
      d = d.add(const Duration(days: 1))
    ) {
      weekdayDayCount[d.weekday] = (weekdayDayCount[d.weekday] ?? 0) + 1;
    }
    final weekdayAvg = <int, Money>{};
    for (final entry in weekdayDayCount.entries) {
      final spent = weekdaySpendMinor[entry.key] ?? 0;
      weekdayAvg[entry.key] = money((spent / entry.value).round());
    }
    int? mostWeekday;
    int? leastWeekday;
    if (weekdaySpendMinor.isNotEmpty) {
      var maxMinor = -1;
      var minMinor = 1 << 62;
      weekdayAvg.forEach((wd, m) {
        if (m.minorUnits > maxMinor) {
          maxMinor = m.minorUnits;
          mostWeekday = wd;
        }
        if (m.minorUnits < minMinor) {
          minMinor = m.minorUnits;
          leastWeekday = wd;
        }
      });
    }
    final weekday = WeekdaySpending(
      averageByWeekday: weekdayAvg,
      mostExpensiveWeekday: mostWeekday,
      leastExpensiveWeekday: leastWeekday,
    );

    // --- Uncategorized. ------------------------------------------------------
    final uncat = monthExpenses.where((t) => t.categoryId == null).toList();
    final uncategorized = UncategorizedSpending(
      count: uncat.length,
      amount: money(sumMinor(uncat)),
    );

    // --- Recommendations (ordered by impact). --------------------------------
    final recs = <InsightRecommendation>[];
    if (projectedOverMinor != null && categoryInsights.isNotEmpty) {
      recs.add(
        InsightRecommendation(
          kind: InsightRecommendationKind.reduceCategory,
          categoryId: categoryInsights.first.categoryId,
          amount: money(projectedOverMinor),
        ),
      );
    }
    for (final r in runaways) {
      recs.add(
        InsightRecommendation(
          kind: InsightRecommendationKind.runawayCategory,
          categoryId: r.categoryId,
          amount: money(r.currentSpend.minorUnits - r.averageSpend.minorUnits),
        ),
      );
    }
    recs.sort(
      (a, b) =>
          (b.amount?.minorUnits ?? 0).compareTo(a.amount?.minorUnits ?? 0),
    );
    if (recs.isEmpty) {
      recs.add(
        const InsightRecommendation(kind: InsightRecommendationKind.allOnTrack),
      );
    }

    return MonthInsights(
      month: monthStart,
      currency: currency,
      hasTransactions: expenses.isNotEmpty,
      totalSpent: money(totalSpentMinor),
      totalBudget: money(totalBudgetMinor),
      budgetDifference: money(totalBudgetMinor - totalSpentMinor),
      budgetUsedPct: totalBudgetMinor > 0
          ? totalSpentMinor / totalBudgetMinor
          : null,
      status: status,
      pace: pace,
      projection: projection,
      categories: categoryInsights,
      runawayCategories: runaways,
      comparison: comparison,
      daily: daily,
      weekday: weekday,
      uncategorized: uncategorized,
      recommendations: recs,
    );
  }

  /// Maps a signed change to a direction with a ±[neutralBand] dead zone.
  /// A null change (no baseline) reads as [TrendDirection.stable].
  static TrendDirection _direction(double? change) {
    if (change == null) return TrendDirection.stable;
    if (change > neutralBand) return TrendDirection.up;
    if (change < -neutralBand) return TrendDirection.down;
    return TrendDirection.stable;
  }
}

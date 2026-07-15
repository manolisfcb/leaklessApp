import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../budgets/application/budgets_providers.dart';
import '../../household/application/household_providers.dart';
import '../../income_sources/application/income_sources_providers.dart';
import '../../transactions/application/categories_providers.dart';
import '../../transactions/application/transactions_providers.dart';
import '../domain/income_insights.dart';
import '../domain/month_insights.dart';

/// Combines the existing feature streams into the [MonthInsights] read-model for
/// the current month. Mirrors `dashboardSummaryProvider`: propagates the first
/// error and stays loading until every source resolves, so the screen never
/// aggregates in `build()`. v1 fixes the current month (a month selector is a
/// future improvement — see docs/DASHBOARD.md).
final monthInsightsProvider = Provider<AsyncValue<MonthInsights>>((ref) {
  final transactions = ref.watch(transactionsStreamProvider);
  final budgets = ref.watch(budgetsProvider);
  final categories = ref.watch(categoriesProvider);
  final household = ref.watch(currentHouseholdProvider);

  // Propagate the first error, if any.
  final error = [
    transactions,
    budgets,
    categories,
    household,
  ].firstWhere((v) => v.hasError, orElse: () => const AsyncData(null));
  if (error.hasError) {
    return AsyncError(error.error!, error.stackTrace ?? StackTrace.current);
  }

  final txData = transactions.asData;
  final budgetData = budgets.asData;
  final categoryData = categories.asData;
  if (txData == null || budgetData == null || categoryData == null) {
    return const AsyncLoading();
  }

  final now = DateTime.now();
  return AsyncData(
    MonthInsights.from(
      month: DateTime(now.year, now.month),
      now: now,
      transactions: txData.value,
      budgets: budgetData.value,
      categories: categoryData.value,
      currency: household.asData?.value?.currency ?? 'USD',
    ),
  );
});

final incomeInsightsProvider = Provider<AsyncValue<IncomeInsights>>((ref) {
  final transactions = ref.watch(transactionsStreamProvider);
  final sources = ref.watch(incomeSourcesProvider);
  final household = ref.watch(currentHouseholdProvider);
  for (final value in [transactions, sources, household]) {
    if (value.hasError) {
      return AsyncError(value.error!, value.stackTrace ?? StackTrace.current);
    }
  }
  final tx = transactions.asData?.value;
  final sourceData = sources.asData?.value;
  final householdData = household.asData?.value;
  if (tx == null || sourceData == null || householdData == null) {
    return const AsyncLoading();
  }
  final now = DateTime.now();
  return AsyncData(
    IncomeInsights.from(
      month: DateTime(now.year, now.month),
      transactions: tx,
      sources: sourceData,
      reportingCurrency: householdData.currency,
    ),
  );
});

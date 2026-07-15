import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../accounts/application/accounts_providers.dart';
import '../../budgets/application/budgets_providers.dart';
import '../../fx/application/exchange_rates_providers.dart';
import '../../household/application/household_providers.dart';
import '../../subscriptions/application/subscriptions_providers.dart';
import '../../transactions/application/transactions_providers.dart';
import '../domain/dashboard_summary.dart';
import '../domain/financial_overview.dart';

/// The month shown on the dashboard (defaults to the current month).
class SelectedMonthController extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  void previous() => state = DateTime(state.year, state.month - 1);

  void next() {
    final now = DateTime.now();
    final candidate = DateTime(state.year, state.month + 1);
    // Don't navigate into the future.
    if (candidate.isAfter(DateTime(now.year, now.month))) return;
    state = candidate;
  }

  bool get isCurrentMonth {
    final now = DateTime.now();
    return state.year == now.year && state.month == now.month;
  }
}

final selectedMonthProvider =
    NotifierProvider<SelectedMonthController, DateTime>(
      SelectedMonthController.new,
    );

/// Combines the feature streams into a single [DashboardSummary]. Surfaces a
/// loading/error state until every source resolves.
final dashboardSummaryProvider = Provider<AsyncValue<DashboardSummary>>((ref) {
  final month = ref.watch(selectedMonthProvider);
  final transactions = ref.watch(transactionsStreamProvider);
  final budgets = ref.watch(budgetsProvider);
  final subscriptions = ref.watch(subscriptionsProvider);
  final members = ref.watch(householdMembersProvider);
  final household = ref.watch(currentHouseholdProvider);
  final accounts = ref.watch(accountsProvider);
  final latestRate = ref.watch(latestUsdCadRateProvider);

  // Propagate the first error, if any.
  final error = [
    transactions,
    budgets,
    subscriptions,
    members,
    household,
    accounts,
    latestRate,
  ].firstWhere((v) => v.hasError, orElse: () => const AsyncData(null));
  if (error.hasError) {
    return AsyncError(error.error!, error.stackTrace ?? StackTrace.current);
  }

  final txData = transactions.asData;
  final budgetData = budgets.asData;
  final subData = subscriptions.asData;
  final memberData = members.asData;
  final accountData = accounts.asData;
  final rateData = latestRate.asData;
  final householdData = household.asData?.value;
  if (txData == null ||
      budgetData == null ||
      subData == null ||
      memberData == null ||
      accountData == null ||
      rateData == null ||
      householdData == null) {
    return const AsyncLoading();
  }

  return AsyncData(
    DashboardSummary.from(
      month: month,
      transactions: txData.value,
      budgets: budgetData.value,
      subscriptions: subData.value,
      members: memberData.value,
      currency: householdData.currency,
      overview: FinancialOverview.calculate(
        accounts: accountData.value,
        transactions: txData.value,
        reportingCurrency: householdData.currency,
        latestRate: rateData.value,
      ),
    ),
  );
});

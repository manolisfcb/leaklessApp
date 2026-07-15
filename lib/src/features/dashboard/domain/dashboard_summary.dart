import '../../../domain/enums/finance_enums.dart';
import '../../../domain/enums/transaction_enums.dart';
import '../../../domain/models/budget.dart';
import '../../../domain/models/household_member.dart';
import '../../../domain/models/money.dart';
import '../../../domain/models/subscription_item.dart';
import '../../../domain/models/transaction.dart';
import 'financial_overview.dart';

/// A read-model for the dashboard — the numbers the "hydrometer" and summary
/// cards render. Computed in one place ([DashboardSummary.from]) so the screen
/// holds no aggregation logic (quality rule #4).
class DashboardSummary {
  const DashboardSummary({
    required this.month,
    required this.income,
    required this.expense,
    required this.balance,
    required this.savingsRate,
    required this.leak,
    required this.activeSubscriptions,
    required this.activeAlerts,
    required this.members,
    this.overview,
  });

  final DateTime month;
  final Money income;
  final Money expense;

  /// income − expense for the month.
  final Money balance;

  /// (income − expense) / income, clamped 0..1.
  final double savingsRate;

  /// Sum of "ant" (gasto hormiga) expenses — the visible leak.
  final Money leak;

  final int activeSubscriptions;
  final int activeAlerts;
  final List<HouseholdMember> members;
  final FinancialOverview? overview;

  Money get netFlow => balance;
  Money get totalBalance => overview?.total ?? balance;

  static DashboardSummary from({
    required DateTime month,
    required List<Transaction> transactions,
    required List<Budget> budgets,
    required List<SubscriptionItem> subscriptions,
    required List<HouseholdMember> members,
    String currency = 'USD',
    FinancialOverview? overview,
  }) {
    final monthTx = transactions.where(
      (t) =>
          t.occurredAt.year == month.year && t.occurredAt.month == month.month,
    );

    var incomeMinor = 0;
    var expenseMinor = 0;
    var leakMinor = 0;
    for (final t in monthTx) {
      if (t.status != TransactionStatus.confirmed) continue;
      final amount =
          t.reportingAmount ??
          (t.amount.currency == currency ? t.amount : null);
      if (amount == null || amount.currency != currency) continue;
      final minor = amount.absolute.minorUnits;
      switch (t.type) {
        case TransactionType.income:
          incomeMinor += minor;
        case TransactionType.expense:
          expenseMinor += minor;
          if (t.priority == TransactionPriority.ant) leakMinor += minor;
        case TransactionType.transfer:
          break;
      }
    }

    final savingsRate = incomeMinor > 0
        ? ((incomeMinor - expenseMinor) / incomeMinor).clamp(0.0, 1.0)
        : 0.0;

    return DashboardSummary(
      month: month,
      income: Money(minorUnits: incomeMinor, currency: currency),
      expense: Money(minorUnits: expenseMinor, currency: currency),
      balance: Money(
        minorUnits: incomeMinor - expenseMinor,
        currency: currency,
      ),
      savingsRate: savingsRate.toDouble(),
      leak: Money(minorUnits: leakMinor, currency: currency),
      activeSubscriptions: subscriptions
          .where((s) => s.status == SubscriptionStatus.active)
          .length,
      activeAlerts: budgets
          .where((b) => b.status != BudgetStatus.normal)
          .length,
      members: members,
      overview: overview,
    );
  }
}

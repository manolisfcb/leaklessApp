import 'package:flutter_test/flutter_test.dart';
import 'package:leakless/src/domain/enums/transaction_enums.dart';
import 'package:leakless/src/domain/models/money.dart';
import 'package:leakless/src/domain/models/transaction.dart';
import 'package:leakless/src/features/dashboard/domain/dashboard_summary.dart';

Transaction _transaction({
  required String id,
  required int minorUnits,
  required TransactionType type,
  required DateTime occurredAt,
}) => Transaction(
  id: id,
  householdId: 'household-1',
  amount: Money(minorUnits: minorUnits, currency: 'USD'),
  type: type,
  priority: TransactionPriority.necessity,
  responsible: ResponsibleType.me,
  occurredAt: occurredAt,
);

void main() {
  test('a newly recorded expense lowers the selected month balance', () {
    final month = DateTime(2026, 7);
    final income = _transaction(
      id: 'income',
      minorUnits: 2000,
      type: TransactionType.income,
      occurredAt: DateTime(2026, 7, 1),
    );
    final expense = _transaction(
      id: 'receipt-expense',
      minorUnits: 750,
      type: TransactionType.expense,
      occurredAt: DateTime(2026, 7, 15),
    );

    final before = DashboardSummary.from(
      month: month,
      transactions: [income],
      budgets: const [],
      subscriptions: const [],
      members: const [],
    );
    final after = DashboardSummary.from(
      month: month,
      transactions: [income, expense],
      budgets: const [],
      subscriptions: const [],
      members: const [],
    );

    expect(before.balance.minorUnits, 2000);
    expect(after.expense.minorUnits, 750);
    expect(after.balance.minorUnits, 1250);
  });

  test('an expense from another month does not alter the selected month', () {
    final summary = DashboardSummary.from(
      month: DateTime(2026, 7),
      transactions: [
        _transaction(
          id: 'old-receipt',
          minorUnits: 750,
          type: TransactionType.expense,
          occurredAt: DateTime(2026, 6, 30),
        ),
      ],
      budgets: const [],
      subscriptions: const [],
      members: const [],
    );

    expect(summary.balance.minorUnits, 0);
  });
}

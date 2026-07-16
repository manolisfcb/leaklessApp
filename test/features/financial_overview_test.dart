import 'package:flutter_test/flutter_test.dart';
import 'package:leakless/src/domain/domain.dart';
import 'package:leakless/src/features/dashboard/domain/financial_overview.dart';

void main() {
  test('one account reports mixed-currency movements in CAD', () {
    final accounts = [
      FinancialAccount(
        id: 'cad',
        householdId: 'h',
        name: 'Cuenta principal',
        currency: 'CAD',
        openingBalance: const Money(minorUnits: 0, currency: 'CAD'),
        openingBalanceAt: DateTime(2026),
      ),
    ];
    final transactions = [
      Transaction(
        id: 'usd-income',
        householdId: 'h',
        accountId: 'cad',
        amount: const Money(minorUnits: 10000, currency: 'USD'),
        reportingAmount: const Money(minorUnits: 13700, currency: 'CAD'),
        type: TransactionType.income,
        priority: TransactionPriority.future,
        responsible: ResponsibleType.shared,
        occurredAt: DateTime(2026, 7),
      ),
      Transaction(
        id: 'cad-expense',
        householdId: 'h',
        accountId: 'cad',
        amount: const Money(minorUnits: 2000, currency: 'CAD'),
        reportingAmount: const Money(minorUnits: 2000, currency: 'CAD'),
        type: TransactionType.expense,
        priority: TransactionPriority.necessity,
        responsible: ResponsibleType.shared,
        occurredAt: DateTime(2026, 7),
      ),
    ];
    final overview = FinancialOverview.calculate(
      accounts: accounts,
      transactions: transactions,
      reportingCurrency: 'CAD',
    );
    expect(overview.total, const Money(minorUnits: 11700, currency: 'CAD'));
    expect(
      overview.accounts.single.balance,
      const Money(minorUnits: 11700, currency: 'CAD'),
    );
    expect(overview.isPartial, isFalse);
  });
}

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

  test('includes confirmed movements that have no visible account', () {
    final transactions = [
      Transaction(
        id: 'usd-income',
        householdId: 'h',
        amount: const Money(minorUnits: 73400, currency: 'USD'),
        reportingAmount: const Money(minorUnits: 104492, currency: 'CAD'),
        type: TransactionType.income,
        priority: TransactionPriority.future,
        responsible: ResponsibleType.me,
        occurredAt: DateTime(2026, 7, 15),
      ),
      Transaction(
        id: 'cad-expense',
        householdId: 'h',
        amount: const Money(minorUnits: 135000, currency: 'CAD'),
        reportingAmount: const Money(minorUnits: 135000, currency: 'CAD'),
        type: TransactionType.expense,
        priority: TransactionPriority.necessity,
        responsible: ResponsibleType.me,
        occurredAt: DateTime(2026, 7, 15),
      ),
    ];

    final overview = FinancialOverview.calculate(
      accounts: const [],
      transactions: transactions,
      reportingCurrency: 'CAD',
    );

    expect(overview.total, const Money(minorUnits: -30508, currency: 'CAD'));
    expect(overview.isPartial, isFalse);
  });

  test('zero opening balance does not hide an earlier local-time movement', () {
    final account = FinancialAccount(
      id: 'main',
      householdId: 'h',
      name: 'Cuenta principal',
      currency: 'CAD',
      openingBalance: const Money(minorUnits: 0, currency: 'CAD'),
      openingBalanceAt: DateTime.utc(2026, 7, 16, 1, 21),
    );
    final expense = Transaction(
      id: 'expense',
      householdId: 'h',
      accountId: account.id,
      amount: const Money(minorUnits: 71792, currency: 'CAD'),
      reportingAmount: const Money(minorUnits: 71792, currency: 'CAD'),
      type: TransactionType.expense,
      priority: TransactionPriority.necessity,
      responsible: ResponsibleType.me,
      // Simulates a Toronto local time previously sent without its UTC offset.
      occurredAt: DateTime.utc(2026, 7, 15, 21, 28),
    );

    final overview = FinancialOverview.calculate(
      accounts: [account],
      transactions: [expense],
      reportingCurrency: 'CAD',
    );

    expect(overview.total, const Money(minorUnits: -71792, currency: 'CAD'));
  });
}

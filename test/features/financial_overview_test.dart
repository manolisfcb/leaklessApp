import 'package:flutter_test/flutter_test.dart';
import 'package:leakless/src/domain/domain.dart';
import 'package:leakless/src/features/dashboard/domain/financial_overview.dart';

void main() {
  test('values accounts in CAD and transfers do not create income', () {
    final rate = FxRate.fromDecimalString(
      rateDate: DateTime(2026, 7, 15),
      foreignCurrency: 'USD',
      reportingCurrency: 'CAD',
      rate: '1.37',
      source: 'bank_of_canada',
      retrievedAt: DateTime(2026, 7, 15),
    );
    final accounts = [
      FinancialAccount(
        id: 'cad',
        householdId: 'h',
        name: 'Banco CAD',
        currency: 'CAD',
        openingBalance: const Money(minorUnits: 1000000, currency: 'CAD'),
        openingBalanceAt: DateTime(2026),
      ),
      FinancialAccount(
        id: 'usd',
        householdId: 'h',
        name: 'Wise USD',
        currency: 'USD',
        openingBalance: const Money(minorUnits: 200000, currency: 'USD'),
        openingBalanceAt: DateTime(2026),
      ),
    ];
    final transactions = [
      Transaction(
        id: 'out',
        householdId: 'h',
        accountId: 'usd',
        amount: const Money(minorUnits: 10000, currency: 'USD'),
        type: TransactionType.transfer,
        priority: TransactionPriority.future,
        responsible: ResponsibleType.shared,
        occurredAt: DateTime(2026, 7),
        transferGroupId: 'g',
        transferDirection: TransferDirection.outgoing,
      ),
      Transaction(
        id: 'in',
        householdId: 'h',
        accountId: 'cad',
        amount: const Money(minorUnits: 13700, currency: 'CAD'),
        type: TransactionType.transfer,
        priority: TransactionPriority.future,
        responsible: ResponsibleType.shared,
        occurredAt: DateTime(2026, 7),
        transferGroupId: 'g',
        transferDirection: TransferDirection.incoming,
      ),
    ];
    final overview = FinancialOverview.calculate(
      accounts: accounts,
      transactions: transactions,
      reportingCurrency: 'CAD',
      latestRate: rate,
    );
    expect(overview.total, const Money(minorUnits: 1274000, currency: 'CAD'));
    expect(overview.isPartial, isFalse);
  });
}

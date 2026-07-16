import '../../../domain/enums/finance_enums.dart';
import '../../../domain/enums/transaction_enums.dart';
import '../../../domain/models/financial_account.dart';
import '../../../domain/models/fx_rate.dart';
import '../../../domain/models/money.dart';
import '../../../domain/models/transaction.dart';
import '../../../domain/services/currency_converter.dart';

class AccountValuation {
  const AccountValuation({
    required this.account,
    required this.balance,
    this.reportingValue,
  });
  final FinancialAccount account;
  final Money balance;
  final Money? reportingValue;
}

class FinancialOverview {
  const FinancialOverview({
    required this.total,
    required this.accounts,
    required this.isPartial,
    this.rate,
  });
  final Money total;
  final List<AccountValuation> accounts;
  final bool isPartial;
  final FxRate? rate;

  static FinancialOverview calculate({
    required List<FinancialAccount> accounts,
    required List<Transaction> transactions,
    required String reportingCurrency,
    FxRate? latestRate,
    CurrencyConverter converter = const CurrencyConverter(),
  }) {
    var totalMinor = 0;
    var partial = false;
    final valuations = <AccountValuation>[];
    for (final account in accounts.where((account) => !account.isArchived)) {
      var nativeMinor = account.openingBalance.minorUnits;
      Money? reportingOpening;
      if (account.currency == reportingCurrency) {
        reportingOpening = account.openingBalance.copyWith(
          currency: reportingCurrency,
        );
      } else if (latestRate != null) {
        reportingOpening = converter.convert(
          account.openingBalance,
          reportingCurrency,
          rate: latestRate,
        );
      }
      var reportingMinor = reportingOpening?.minorUnits ?? 0;
      if (reportingOpening == null) partial = true;
      for (final transaction in transactions) {
        if (transaction.accountId != account.id ||
            transaction.status != TransactionStatus.confirmed ||
            transaction.occurredAt.isBefore(account.openingBalanceAt)) {
          continue;
        }
        final amount = transaction.amount.absolute.minorUnits;
        final reportingAmount =
            transaction.reportingAmount ??
            (transaction.amount.currency == reportingCurrency
                ? transaction.amount.copyWith(currency: reportingCurrency)
                : null);
        if (reportingAmount == null ||
            reportingAmount.currency != reportingCurrency) {
          partial = true;
        }
        final reporting = reportingAmount?.absolute.minorUnits ?? 0;
        switch (transaction.type) {
          case TransactionType.income:
            if (transaction.amount.currency == account.currency) {
              nativeMinor += amount;
            }
            reportingMinor += reporting;
          case TransactionType.expense:
            if (transaction.amount.currency == account.currency) {
              nativeMinor -= amount;
            }
            reportingMinor -= reporting;
          case TransactionType.transfer:
            final direction = transaction.transferDirection;
            if (transaction.amount.currency == account.currency) {
              nativeMinor += direction == TransferDirection.incoming
                  ? amount
                  : -amount;
            }
            reportingMinor += direction == TransferDirection.incoming
                ? reporting
                : -reporting;
        }
      }
      final balance =
          account.currency == reportingCurrency && reportingOpening != null
          ? Money(minorUnits: reportingMinor, currency: account.currency)
          : Money(minorUnits: nativeMinor, currency: account.currency);
      Money? reportingValue;
      reportingValue = reportingOpening == null
          ? null
          : Money(minorUnits: reportingMinor, currency: reportingCurrency);
      if (reportingValue != null) {
        totalMinor += account.balanceNature == BalanceNature.liability
            ? -reportingValue.minorUnits
            : reportingValue.minorUnits;
      }
      valuations.add(
        AccountValuation(
          account: account,
          balance: balance,
          reportingValue: reportingValue,
        ),
      );
    }
    return FinancialOverview(
      total: Money(minorUnits: totalMinor, currency: reportingCurrency),
      accounts: List.unmodifiable(valuations),
      isPartial: partial,
      rate: latestRate,
    );
  }
}

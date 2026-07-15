import '../../../domain/enums/transaction_enums.dart';
import '../../../domain/models/income_source.dart';
import '../../../domain/models/money.dart';
import '../../../domain/models/transaction.dart';

class IncomeSourceSlice {
  const IncomeSourceSlice({
    required this.sourceId,
    required this.name,
    required this.total,
    required this.share,
  });
  final String? sourceId;
  final String name;
  final Money total;
  final double share;
}

class CurrencyIncomeSlice {
  const CurrencyIncomeSlice({
    required this.currency,
    required this.originalMinorUnits,
    required this.reportingTotal,
  });
  final String currency;
  final int originalMinorUnits;
  final Money reportingTotal;
}

class IncomeInsights {
  const IncomeInsights({
    required this.total,
    required this.bySource,
    required this.byCurrency,
  });
  final Money total;
  final List<IncomeSourceSlice> bySource;
  final List<CurrencyIncomeSlice> byCurrency;

  static IncomeInsights from({
    required DateTime month,
    required List<Transaction> transactions,
    required List<IncomeSource> sources,
    required String reportingCurrency,
  }) {
    final sourceNames = {for (final source in sources) source.id: source.name};
    final bySourceMinor = <String?, int>{};
    final byCurrencyOriginal = <String, int>{};
    final byCurrencyReporting = <String, int>{};
    for (final transaction in transactions) {
      if (transaction.type != TransactionType.income ||
          transaction.status != TransactionStatus.confirmed ||
          transaction.occurredAt.year != month.year ||
          transaction.occurredAt.month != month.month) {
        continue;
      }
      final reporting =
          transaction.reportingAmount ??
          (transaction.amount.currency == reportingCurrency
              ? transaction.amount
              : null);
      if (reporting == null || reporting.currency != reportingCurrency) {
        continue;
      }
      final minor = reporting.absolute.minorUnits;
      bySourceMinor[transaction.incomeSourceId] =
          (bySourceMinor[transaction.incomeSourceId] ?? 0) + minor;
      byCurrencyOriginal[transaction.amount.currency] =
          (byCurrencyOriginal[transaction.amount.currency] ?? 0) +
          transaction.amount.absolute.minorUnits;
      byCurrencyReporting[transaction.amount.currency] =
          (byCurrencyReporting[transaction.amount.currency] ?? 0) + minor;
    }
    final totalMinor = bySourceMinor.values.fold(
      0,
      (sum, value) => sum + value,
    );
    final sourceSlices = [
      for (final entry in bySourceMinor.entries)
        IncomeSourceSlice(
          sourceId: entry.key,
          name: entry.key == null ? '' : sourceNames[entry.key] ?? '',
          total: Money(minorUnits: entry.value, currency: reportingCurrency),
          share: totalMinor == 0 ? 0 : entry.value / totalMinor,
        ),
    ]..sort((a, b) => b.total.minorUnits.compareTo(a.total.minorUnits));
    return IncomeInsights(
      total: Money(minorUnits: totalMinor, currency: reportingCurrency),
      bySource: List.unmodifiable(sourceSlices),
      byCurrency: [
        for (final entry in byCurrencyOriginal.entries)
          CurrencyIncomeSlice(
            currency: entry.key,
            originalMinorUnits: entry.value,
            reportingTotal: Money(
              minorUnits: byCurrencyReporting[entry.key] ?? 0,
              currency: reportingCurrency,
            ),
          ),
      ],
    );
  }
}

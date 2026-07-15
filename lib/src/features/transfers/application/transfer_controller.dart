import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/enums/transaction_enums.dart';
import '../../../domain/models/financial_account.dart';
import '../../../domain/models/fx_rate.dart';
import '../../../domain/models/money.dart';
import '../../../domain/models/transaction.dart';
import '../../fx/application/exchange_rates_providers.dart';
import '../../household/application/household_providers.dart';
import '../../transactions/application/transactions_providers.dart';
import '../../transactions/data/transactions_repository.dart';

class TransferController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<bool> submit({
    required FinancialAccount from,
    required FinancialAccount to,
    required Money sent,
    required Money received,
    DateTime? occurredAt,
    String? description,
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      final household = await ref.read(currentHouseholdProvider.future);
      if (household == null) throw StateError('missing_household');
      final when = occurredAt ?? DateTime.now();
      final sentSnapshot = await _snapshot(sent, household.currency, when);
      final receivedSnapshot = await _snapshot(
        received,
        household.currency,
        when,
      );
      Transaction leg(
        FinancialAccount account,
        Money amount,
        _Snapshot snapshot,
      ) => Transaction(
        id: '',
        householdId: household.id,
        accountId: account.id,
        amount: amount,
        reportingAmount: snapshot.amount,
        exchangeRateScaled: snapshot.rate,
        exchangeRateDate: snapshot.date,
        exchangeRateSource: snapshot.source,
        type: TransactionType.transfer,
        priority: TransactionPriority.future,
        responsible: ResponsibleType.shared,
        occurredAt: when,
        description: description,
      );
      final repository = ref.read(transactionsRepositoryProvider);
      if (repository is! TransfersRepository) {
        throw StateError('transfers_not_supported');
      }
      await (repository as TransfersRepository).createTransfer(
        leg(from, sent, sentSnapshot),
        leg(to, received, receivedSnapshot),
      );
    });
    state = result;
    if (result.hasError) return false;
    ref.invalidate(transactionsStreamProvider);
    return true;
  }

  Future<_Snapshot> _snapshot(
    Money amount,
    String reporting,
    DateTime date,
  ) async {
    if (amount.currency == reporting) {
      return _Snapshot(
        amount.copyWith(currency: reporting),
        FxRate.scale,
        date,
        'identity',
      );
    }
    final rate = await ref
        .read(exchangeRatesRepositoryProvider)
        .resolve(
          foreignCurrency: 'USD',
          reportingCurrency: 'CAD',
          onOrBefore: date,
        );
    if (rate == null) throw StateError('fx_rate_unavailable');
    return _Snapshot(
      ref
          .read(currencyConverterProvider)
          .convert(amount, reporting, rate: rate),
      rate.scaledRate,
      rate.rateDate,
      rate.source,
    );
  }
}

class _Snapshot {
  const _Snapshot(this.amount, this.rate, this.date, this.source);
  final Money amount;
  final int rate;
  final DateTime date;
  final String source;
}

final transferControllerProvider =
    NotifierProvider<TransferController, AsyncValue<void>>(
      TransferController.new,
    );

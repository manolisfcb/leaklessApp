import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leakless/src/core/analytics/analytics_service.dart';
import 'package:leakless/src/core/core_providers.dart';
import 'package:leakless/src/domain/enums/transaction_enums.dart';
import 'package:leakless/src/domain/models/household.dart';
import 'package:leakless/src/domain/models/transaction.dart';
import 'package:leakless/src/features/household/application/household_providers.dart';
import 'package:leakless/src/features/quick_entry/application/quick_entry_controller.dart';
import 'package:leakless/src/features/transactions/application/transactions_providers.dart';
import 'package:leakless/src/features/transactions/data/transactions_repository.dart';

void main() {
  test('persists the expense and preserves scanned receipt fields', () async {
    final repository = _FakeTransactionsRepository();
    final container = _container(repository);
    addTearDown(container.dispose);
    final receiptDate = DateTime(2026, 7, 12);

    final saved = await container
        .read(quickEntryControllerProvider.notifier)
        .submit(
          amountMinorUnits: 1299,
          type: TransactionType.expense,
          priority: TransactionPriority.necessity,
          responsible: ResponsibleType.me,
          categoryId: 'category-1',
          description: 'Mercado Central',
          occurredAt: receiptDate,
        );

    expect(saved, isTrue);
    expect(repository.added?.amount.minorUnits, 1299);
    expect(repository.added?.amount.currency, 'CAD');
    expect(repository.added?.description, 'Mercado Central');
    expect(repository.added?.categoryId, 'category-1');
    expect(repository.added?.occurredAt, receiptDate);
    expect(container.read(quickEntryControllerProvider).hasError, isFalse);
  });

  test(
    'an analytics failure does not turn a persisted expense into a failure',
    () async {
      final repository = _FakeTransactionsRepository();
      final container = _container(
        repository,
        analytics: _FailingAnalyticsService(),
      );
      addTearDown(container.dispose);

      final saved = await container
          .read(quickEntryControllerProvider.notifier)
          .submit(
            amountMinorUnits: 500,
            type: TransactionType.expense,
            priority: TransactionPriority.ant,
            responsible: ResponsibleType.shared,
          );

      expect(saved, isTrue);
      expect(repository.added, isNotNull);
      expect(container.read(quickEntryControllerProvider).hasError, isFalse);
    },
  );

  test('exposes repository failures to the sheet', () async {
    final container = _container(_FakeTransactionsRepository(failAdd: true));
    addTearDown(container.dispose);

    final saved = await container
        .read(quickEntryControllerProvider.notifier)
        .submit(
          amountMinorUnits: 500,
          type: TransactionType.expense,
          priority: TransactionPriority.ant,
          responsible: ResponsibleType.me,
        );

    expect(saved, isFalse);
    expect(container.read(quickEntryControllerProvider).hasError, isTrue);
  });
}

ProviderContainer _container(
  _FakeTransactionsRepository repository, {
  AnalyticsService? analytics,
}) => ProviderContainer(
  overrides: [
    transactionsRepositoryProvider.overrideWithValue(repository),
    analyticsServiceProvider.overrideWithValue(analytics ?? AnalyticsService()),
    currentHouseholdProvider.overrideWith(
      (ref) async => const Household(
        id: 'household-1',
        name: 'Casa',
        ownerId: 'user-1',
        currency: 'CAD',
      ),
    ),
  ],
);

class _FailingAnalyticsService extends AnalyticsService {
  @override
  Future<void> transactionCreated() async {
    throw StateError('analytics unavailable');
  }
}

class _FakeTransactionsRepository implements TransactionsRepository {
  _FakeTransactionsRepository({this.failAdd = false});

  final bool failAdd;
  Transaction? added;

  @override
  Future<Transaction> add(Transaction transaction) async {
    if (failAdd) throw StateError('insert failed');
    added = transaction;
    return transaction.copyWith(id: 'transaction-1');
  }

  @override
  Future<void> delete(String transactionId) async {
    added = null;
  }

  @override
  Future<List<Transaction>> fetchForHousehold(String householdId) async =>
      added == null ? const [] : [added!];

  @override
  Stream<List<Transaction>> watchForHousehold(String householdId) =>
      Stream.value(added == null ? const [] : [added!]);
}

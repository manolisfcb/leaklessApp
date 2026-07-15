import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leakless/src/domain/models/transaction.dart';
import 'package:leakless/src/features/transactions/application/transactions_providers.dart';
import 'package:leakless/src/features/transactions/data/transactions_repository.dart';

void main() {
  test('deletes a transaction and reports success', () async {
    final repository = _FakeTransactionsRepository();
    final container = ProviderContainer(
      overrides: [transactionsRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final deleted = await container
        .read(transactionsControllerProvider.notifier)
        .delete('transaction-1');

    expect(deleted, isTrue);
    expect(repository.deletedId, 'transaction-1');
    expect(container.read(transactionsControllerProvider).hasError, isFalse);
  });

  test('keeps the error in state when deletion fails', () async {
    final container = ProviderContainer(
      overrides: [
        transactionsRepositoryProvider.overrideWithValue(
          _FakeTransactionsRepository(failDelete: true),
        ),
      ],
    );
    addTearDown(container.dispose);

    final deleted = await container
        .read(transactionsControllerProvider.notifier)
        .delete('transaction-1');

    expect(deleted, isFalse);
    expect(container.read(transactionsControllerProvider).hasError, isTrue);
  });
}

class _FakeTransactionsRepository implements TransactionsRepository {
  _FakeTransactionsRepository({this.failDelete = false});

  final bool failDelete;
  String? deletedId;

  @override
  Future<void> delete(String transactionId) async {
    if (failDelete) throw StateError('delete failed');
    deletedId = transactionId;
  }

  @override
  Future<Transaction> add(Transaction transaction) async => transaction;

  @override
  Future<List<Transaction>> fetchForHousehold(String householdId) async =>
      const [];

  @override
  Stream<List<Transaction>> watchForHousehold(String householdId) =>
      Stream.value(const []);
}

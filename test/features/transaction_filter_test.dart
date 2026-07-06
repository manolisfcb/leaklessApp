import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leakless/src/domain/enums/transaction_enums.dart';
import 'package:leakless/src/domain/models/money.dart';
import 'package:leakless/src/domain/models/transaction.dart';
import 'package:leakless/src/features/transactions/application/transactions_providers.dart';

Transaction _tx({String? categoryId}) => Transaction(
  id: 'tx-1',
  householdId: 'hh-1',
  amount: const Money(minorUnits: 1000, currency: 'USD'),
  type: TransactionType.expense,
  priority: TransactionPriority.ant,
  responsible: ResponsibleType.me,
  occurredAt: DateTime(2026, 7, 1),
  categoryId: categoryId,
);

void main() {
  group('TransactionFilter.matches', () {
    test('uncategorizedOnly matches only transactions with no category', () {
      const filter = TransactionFilter(uncategorizedOnly: true);
      expect(filter.matches(_tx()), isTrue);
      expect(filter.matches(_tx(categoryId: 'cat-1')), isFalse);
    });

    test('uncategorizedOnly ignores a stale categoryId', () {
      const filter = TransactionFilter(categoryId: 'cat-1', uncategorizedOnly: true);
      expect(filter.matches(_tx()), isTrue);
    });

    test('isActive is true when only uncategorizedOnly is set', () {
      const filter = TransactionFilter(uncategorizedOnly: true);
      expect(filter.isActive, isTrue);
    });
  });

  group('TransactionFilterController', () {
    late ProviderContainer container;

    setUp(() => container = ProviderContainer());
    tearDown(() => container.dispose());

    test('toggleUncategorized turns the filter on and off', () {
      final notifier = container.read(transactionFilterProvider.notifier);
      notifier.toggleUncategorized();
      expect(container.read(transactionFilterProvider).uncategorizedOnly, isTrue);
      notifier.toggleUncategorized();
      expect(container.read(transactionFilterProvider).uncategorizedOnly, isFalse);
    });

    test('toggleCategory clears uncategorizedOnly', () {
      final notifier = container.read(transactionFilterProvider.notifier);
      notifier.toggleUncategorized();
      notifier.toggleCategory('cat-1');
      final filter = container.read(transactionFilterProvider);
      expect(filter.uncategorizedOnly, isFalse);
      expect(filter.categoryId, 'cat-1');
    });

    test('showUncategorizedOnly always enables it and clears categoryId', () {
      final notifier = container.read(transactionFilterProvider.notifier);
      notifier.toggleCategory('cat-1');
      notifier.showUncategorizedOnly();
      final filter = container.read(transactionFilterProvider);
      expect(filter.uncategorizedOnly, isTrue);
      expect(filter.categoryId, isNull);
    });
  });
}

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leakless/src/domain/enums/transaction_enums.dart';
import 'package:leakless/src/domain/models/budget.dart';
import 'package:leakless/src/features/budgets/application/budgets_providers.dart';
import 'package:leakless/src/features/transactions/application/transactions_providers.dart';

void main() {
  test('transactionFilterProvider toggles are exclusive per facet', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final controller = container.read(transactionFilterProvider.notifier);
    expect(container.read(transactionFilterProvider).isActive, isFalse);

    controller.toggleResponsible(ResponsibleType.me);
    expect(
      container.read(transactionFilterProvider).responsible,
      ResponsibleType.me,
    );

    // Toggling the same value clears it.
    controller.toggleResponsible(ResponsibleType.me);
    expect(container.read(transactionFilterProvider).responsible, isNull);
  });

  test('budgetsProvider resolves the mock household budgets', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final firstBudgets = Completer<List<Budget>>();
    final subscription = container.listen(
      budgetsProvider,
      (_, value) => value.whenData((budgets) {
        if (!firstBudgets.isCompleted) firstBudgets.complete(budgets);
      }),
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    final budgets = await firstBudgets.future;
    expect(budgets, isNotEmpty);
    // Demo data ships one exceeded budget (transport) → status is derived.
    expect(budgets.any((b) => b.ratio > 1), isTrue);
  });
}

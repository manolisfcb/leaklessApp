import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leakless/src/domain/models/budget.dart';
import 'package:leakless/src/features/budgets/application/budgets_providers.dart';
import 'package:leakless/src/features/budgets/data/budgets_repository.dart';

void main() {
  test('save creates a normalized budget for the active household', () async {
    final repository = _FakeBudgetsRepository();
    final container = ProviderContainer(
      overrides: [budgetsRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final saved = await container
        .read(budgetsControllerProvider.notifier)
        .save(
          categoryId: 'cat-new',
          amountMinorUnits: 34567,
          periodStart: DateTime(2026, 7, 20),
          alertEnabled: false,
          alertThresholdPct: 90,
        );

    expect(saved, isTrue);
    expect(repository.created, isNotNull);
    expect(repository.created!.categoryId, 'cat-new');
    expect(repository.created!.limit.minorUnits, 34567);
    expect(repository.created!.periodStart, DateTime(2026, 7));
    expect(repository.created!.alertEnabled, isFalse);
    expect(repository.created!.alertThresholdPct, 90);
    expect(container.read(budgetsControllerProvider).hasError, isFalse);
  });

  test('save updates when a budget id is supplied', () async {
    final repository = _FakeBudgetsRepository();
    final container = ProviderContainer(
      overrides: [budgetsRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final saved = await container
        .read(budgetsControllerProvider.notifier)
        .save(
          budgetId: 'budget-existing',
          categoryId: 'cat-updated',
          amountMinorUnits: 9000,
        );

    expect(saved, isTrue);
    expect(repository.updated?.id, 'budget-existing');
    expect(repository.created, isNull);
  });

  test('delete returns false and exposes repository failures', () async {
    final repository = _FakeBudgetsRepository(failDelete: true);
    final container = ProviderContainer(
      overrides: [budgetsRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final deleted = await container
        .read(budgetsControllerProvider.notifier)
        .delete('budget-bad');

    expect(deleted, isFalse);
    expect(container.read(budgetsControllerProvider).hasError, isTrue);
  });

  test('mock repository emits create, update, and delete changes', () async {
    final repository = MockBudgetsRepository();
    addTearDown(repository.dispose);
    final initial = await repository.fetchForHousehold('demo-household');
    final events = <List<Budget>>[];
    final subscription = repository
        .watchForHousehold('demo-household')
        .listen(events.add);
    addTearDown(subscription.cancel);
    await Future<void>.delayed(Duration.zero);

    final created = await repository.create(
      initial.first.copyWith(id: '', categoryId: 'cat-new'),
    );
    await repository.update(
      created.copyWith(limit: created.limit.copyWith(minorUnits: 12300)),
    );
    await repository.delete(created.id);
    await Future<void>.delayed(Duration.zero);

    expect(events, hasLength(4));
    expect(events[1].any((budget) => budget.id == created.id), isTrue);
    expect(
      events[2]
          .singleWhere((budget) => budget.id == created.id)
          .limit
          .minorUnits,
      12300,
    );
    expect(events[3].any((budget) => budget.id == created.id), isFalse);
  });
}

class _FakeBudgetsRepository implements BudgetsRepository {
  _FakeBudgetsRepository({this.failDelete = false});

  final bool failDelete;
  Budget? created;
  Budget? updated;

  @override
  Future<Budget> create(Budget budget) async {
    created = budget;
    return budget.copyWith(id: 'created-budget');
  }

  @override
  Future<void> delete(String budgetId) async {
    if (failDelete) throw StateError('delete failed');
  }

  @override
  Future<List<Budget>> fetchForHousehold(String householdId) async => const [];

  @override
  Future<Budget> update(Budget budget) async {
    updated = budget;
    return budget;
  }

  @override
  Stream<List<Budget>> watchForHousehold(String householdId) =>
      const Stream.empty();
}

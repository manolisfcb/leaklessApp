import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leakless/src/domain/models/goal.dart';
import 'package:leakless/src/domain/models/household.dart';
import 'package:leakless/src/domain/models/money.dart';
import 'package:leakless/src/features/goals/application/goals_providers.dart';
import 'package:leakless/src/features/goals/data/goals_repository.dart';
import 'package:leakless/src/features/household/application/household_providers.dart';

void main() {
  test('save creates and updates goals', () async {
    final repository = _FakeGoalsRepository();
    final container = _container(repository);
    addTearDown(container.dispose);

    final created = await container
        .read(goalsControllerProvider.notifier)
        .save(
          name: '  Viaje  ',
          targetAmountMinorUnits: 250000,
          deadline: DateTime(2027, 6, 1),
        );

    expect(created, isTrue);
    expect(repository.created?.name, 'Viaje');
    expect(repository.created?.householdId, 'household-1');
    expect(
      repository.created?.target,
      const Money(minorUnits: 250000, currency: 'CAD'),
    );

    final updated = await container
        .read(goalsControllerProvider.notifier)
        .save(
          goal: repository.created,
          name: 'Viaje largo',
          targetAmountMinorUnits: 300000,
        );

    expect(updated, isTrue);
    expect(repository.updated?.name, 'Viaje largo');
    expect(repository.updated?.target.minorUnits, 300000);
  });

  test('save exposes repository errors', () async {
    final repository = _FakeGoalsRepository(failSave: true);
    final container = _container(repository);
    addTearDown(container.dispose);

    final saved = await container
        .read(goalsControllerProvider.notifier)
        .save(name: 'Casa', targetAmountMinorUnits: 100000);

    expect(saved, isFalse);
    expect(container.read(goalsControllerProvider).hasError, isTrue);
  });

  test('delete exposes repository errors', () async {
    final repository = _FakeGoalsRepository(failDelete: true);
    final container = _container(repository);
    addTearDown(container.dispose);

    final deleted = await container
        .read(goalsControllerProvider.notifier)
        .delete('goal-1');

    expect(deleted, isFalse);
    expect(container.read(goalsControllerProvider).hasError, isTrue);
  });

  test('contribute exposes repository errors', () async {
    final repository = _FakeGoalsRepository(failContribute: true);
    final container = _container(repository);
    addTearDown(container.dispose);

    final contributed = await container
        .read(goalsControllerProvider.notifier)
        .contribute(goalId: 'goal-1', amountMinorUnits: 5000);

    expect(contributed, isFalse);
    expect(container.read(goalsControllerProvider).hasError, isTrue);
  });
}

ProviderContainer _container(_FakeGoalsRepository repository) =>
    ProviderContainer(
      overrides: [
        goalsRepositoryProvider.overrideWithValue(repository),
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

class _FakeGoalsRepository implements GoalsRepository {
  _FakeGoalsRepository({
    this.failSave = false,
    this.failDelete = false,
    this.failContribute = false,
  });

  final bool failSave;
  final bool failDelete;
  final bool failContribute;
  Goal? created;
  Goal? updated;

  @override
  Future<Goal> create(Goal goal) async {
    if (failSave) throw StateError('save failed');
    return created = goal.copyWith(id: 'goal-created');
  }

  @override
  Future<Goal> update(Goal goal) async {
    if (failSave) throw StateError('save failed');
    return updated = goal;
  }

  @override
  Future<void> delete(String goalId) async {
    if (failDelete) throw StateError('delete failed');
  }

  @override
  Future<void> contribute({
    required String goalId,
    required int amountMinorUnits,
  }) async {
    if (failContribute) throw StateError('contribute failed');
  }

  @override
  Future<List<Goal>> fetchForHousehold(String householdId) async => const [];

  @override
  Stream<List<Goal>> watchForHousehold(String householdId) =>
      Stream.value(const []);
}

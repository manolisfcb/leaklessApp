import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leakless/src/domain/models/household.dart';
import 'package:leakless/src/domain/models/transaction_category.dart';
import 'package:leakless/src/features/household/application/household_providers.dart';
import 'package:leakless/src/features/transactions/application/categories_controller.dart';
import 'package:leakless/src/features/transactions/application/categories_providers.dart';
import 'package:leakless/src/features/transactions/data/categories_repository.dart';

void main() {
  test(
    'save creates a custom category and refreshes categoriesProvider',
    () async {
      final repository = _FakeCategoriesRepository();
      final container = _container(repository);
      addTearDown(container.dispose);

      await container.read(categoriesProvider.future);
      expect(repository.fetchCount, 1);

      final saved = await container
          .read(categoriesControllerProvider.notifier)
          .save(name: '  Mascotas  ', iconName: 'gift', colorHex: '#123456');

      expect(saved, isTrue);
      expect(repository.created?.householdId, 'household-1');
      expect(repository.created?.name, 'Mascotas');
      expect(repository.created?.slug, isNull);
      expect(repository.created?.isDefault, isFalse);
      await container.read(categoriesProvider.future);
      expect(repository.fetchCount, 2);
    },
  );

  test('save updates an existing category and delete removes it', () async {
    final repository = _FakeCategoriesRepository();
    final container = _container(repository);
    addTearDown(container.dispose);
    const category = TransactionCategory(
      id: 'category-1',
      householdId: 'household-1',
      name: 'Mascotas',
      iconName: 'gift',
    );

    final updated = await container
        .read(categoriesControllerProvider.notifier)
        .save(
          category: category,
          name: 'Veterinario',
          iconName: 'health',
          colorHex: '#654321',
        );
    final deleted = await container
        .read(categoriesControllerProvider.notifier)
        .delete('category-1');

    expect(updated, isTrue);
    expect(repository.updated?.name, 'Veterinario');
    expect(repository.updated?.iconName, 'health');
    expect(deleted, isTrue);
    expect(repository.deletedId, 'category-1');
  });

  test(
    'repository failures are exposed without refreshing categories',
    () async {
      final repository = _FakeCategoriesRepository(failSave: true);
      final container = _container(repository);
      addTearDown(container.dispose);
      await container.read(categoriesProvider.future);

      final saved = await container
          .read(categoriesControllerProvider.notifier)
          .save(name: 'Mascotas', iconName: 'gift');

      expect(saved, isFalse);
      expect(container.read(categoriesControllerProvider).hasError, isTrue);
      expect(repository.fetchCount, 1);
    },
  );

  test('mock repository keeps create, update, and delete changes', () async {
    final repository = MockCategoriesRepository();
    final initial = await repository.fetchCategories('demo-household');
    expect(initial, hasLength(10));

    final created = await repository.create(
      const TransactionCategory(
        id: '',
        householdId: 'demo-household',
        name: 'Mascotas',
        iconName: 'gift',
      ),
    );
    await repository.update(created.copyWith(name: 'Veterinario'));
    expect(
      (await repository.fetchCategories(
        'demo-household',
      )).singleWhere((category) => category.id == created.id).name,
      'Veterinario',
    );

    await repository.delete(created.id);
    expect(await repository.fetchCategories('demo-household'), hasLength(10));
  });
}

ProviderContainer _container(_FakeCategoriesRepository repository) =>
    ProviderContainer(
      overrides: [
        categoriesRepositoryProvider.overrideWithValue(repository),
        currentHouseholdProvider.overrideWith(
          (ref) async => const Household(
            id: 'household-1',
            name: 'Casa',
            ownerId: 'user-1',
          ),
        ),
      ],
    );

class _FakeCategoriesRepository implements CategoriesRepository {
  _FakeCategoriesRepository({this.failSave = false});

  final bool failSave;
  int fetchCount = 0;
  TransactionCategory? created;
  TransactionCategory? updated;
  String? deletedId;

  @override
  Future<List<TransactionCategory>> fetchCategories(String householdId) async {
    fetchCount += 1;
    return const [];
  }

  @override
  Future<TransactionCategory> create(TransactionCategory category) async {
    if (failSave) throw StateError('save failed');
    return created = category.copyWith(id: 'category-created');
  }

  @override
  Future<TransactionCategory> update(TransactionCategory category) async {
    if (failSave) throw StateError('save failed');
    return updated = category;
  }

  @override
  Future<void> delete(String categoryId) async {
    deletedId = categoryId;
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/transaction_category.dart';
import '../../household/application/household_providers.dart';
import 'categories_providers.dart';

/// Creates, edits, and deletes custom categories, exposing failures to the UI.
class CategoriesController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<bool> save({
    TransactionCategory? category,
    required String name,
    required String iconName,
    String? colorHex,
  }) => _run(() async {
    final repository = ref.read(categoriesRepositoryProvider);
    if (category == null) {
      final household = await ref.read(currentHouseholdProvider.future);
      if (household == null) throw StateError('No active household');
      await repository.create(
        TransactionCategory(
          id: '',
          householdId: household.id,
          name: name.trim(),
          iconName: iconName,
          colorHex: colorHex,
        ),
      );
    } else {
      await repository.update(
        category.copyWith(
          name: name.trim(),
          iconName: iconName,
          colorHex: colorHex,
        ),
      );
    }
  });

  Future<bool> delete(String categoryId) =>
      _run(() => ref.read(categoriesRepositoryProvider).delete(categoryId));

  Future<bool> _run(Future<void> Function() action) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(action);
    if (!state.hasError) ref.invalidate(categoriesProvider);
    return !state.hasError;
  }
}

final categoriesControllerProvider =
    NotifierProvider<CategoriesController, AsyncValue<void>>(
      CategoriesController.new,
    );

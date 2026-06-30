import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/transaction_category.dart';
import '../data/categories_repository.dart';

final categoriesRepositoryProvider = Provider<CategoriesRepository>(
  (ref) => const MockCategoriesRepository(),
);

/// All categories for the household.
final categoriesProvider = FutureProvider<List<TransactionCategory>>(
  (ref) => ref.watch(categoriesRepositoryProvider).fetchCategories(),
);

/// Fast id → category lookup for rendering names/icons in lists.
final categoriesByIdProvider = Provider<Map<String, TransactionCategory>>((ref) {
  final categories = ref.watch(categoriesProvider).asData?.value ?? const [];
  return {for (final c in categories) c.id: c};
});

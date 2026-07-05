import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../../domain/models/transaction_category.dart';
import '../../household/application/household_providers.dart';
import '../data/categories_repository.dart';

/// Real (Supabase) or mock repository, chosen by config — same pattern as
/// [transactionsRepositoryProvider].
final categoriesRepositoryProvider = Provider<CategoriesRepository>((ref) {
  if (ref.watch(supabaseEnabledProvider)) {
    return SupabaseCategoriesRepository(ref.watch(supabaseClientProvider));
  }
  return MockCategoriesRepository();
});

/// All categories for the active household.
final categoriesProvider = FutureProvider<List<TransactionCategory>>((
  ref,
) async {
  final household = await ref.watch(currentHouseholdProvider.future);
  if (household == null) return const [];
  return ref.watch(categoriesRepositoryProvider).fetchCategories(household.id);
});

/// Fast id → category lookup for rendering names/icons in lists.
final categoriesByIdProvider = Provider<Map<String, TransactionCategory>>((
  ref,
) {
  final categories = ref.watch(categoriesProvider).asData?.value ?? const [];
  return {for (final c in categories) c.id: c};
});

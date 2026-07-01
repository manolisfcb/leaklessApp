import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/dev/demo_data.dart';
import '../../../core/errors/app_exception.dart';
import '../../../domain/models/transaction_category.dart';
import 'category_mapper.dart';

/// Reads the household's transaction categories.
abstract interface class CategoriesRepository {
  Future<List<TransactionCategory>> fetchCategories(String householdId);
}

/// Mock categories from [DemoData]. Replace with a Supabase implementation
/// (querying `categories`) when the backend is wired.
class MockCategoriesRepository implements CategoriesRepository {
  const MockCategoriesRepository();

  @override
  Future<List<TransactionCategory>> fetchCategories(String householdId) async =>
      DemoData.categories;
}

/// Supabase-backed category reads, scoped to the active household.
///
/// RLS already restricts `categories` to households the user belongs to; the
/// explicit `household_id` filter keeps this correct if a user ever belongs to
/// more than one, and mirrors the `transactions` pattern.
class SupabaseCategoriesRepository implements CategoriesRepository {
  SupabaseCategoriesRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<TransactionCategory>> fetchCategories(String householdId) async {
    try {
      final rows = await _client
          .from('categories')
          .select()
          .eq('household_id', householdId)
          .order('created_at');
      return rows.map(CategoryMapper.fromRow).toList();
    } catch (e, s) {
      throw ServerException('Failed to load categories', cause: e, stackTrace: s);
    }
  }
}

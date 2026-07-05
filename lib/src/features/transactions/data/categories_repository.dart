import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/dev/demo_data.dart';
import '../../../core/errors/app_exception.dart';
import '../../../domain/models/transaction_category.dart';
import 'category_mapper.dart';

/// Reads the household's transaction categories.
abstract interface class CategoriesRepository {
  Future<List<TransactionCategory>> fetchCategories(String householdId);
  Future<TransactionCategory> create(TransactionCategory category);
  Future<TransactionCategory> update(TransactionCategory category);
  Future<void> delete(String categoryId);
}

/// Stateful in-memory categories used when Supabase is disabled.
class MockCategoriesRepository implements CategoriesRepository {
  MockCategoriesRepository() : _items = List.of(DemoData.categories);

  final List<TransactionCategory> _items;

  @override
  Future<List<TransactionCategory>> fetchCategories(String householdId) async =>
      List.unmodifiable(
        _items.where((category) => category.householdId == householdId),
      );

  @override
  Future<TransactionCategory> create(TransactionCategory category) async {
    final now = DateTime.now();
    final saved = category.copyWith(
      id: category.id.isEmpty
          ? 'mock-category-${now.microsecondsSinceEpoch}'
          : category.id,
      createdAt: category.createdAt ?? now,
    );
    _items.add(saved);
    return saved;
  }

  @override
  Future<TransactionCategory> update(TransactionCategory category) async {
    final index = _items.indexWhere((item) => item.id == category.id);
    if (index == -1) {
      throw StateError('Category not found: ${category.id}');
    }
    final saved = category.copyWith(createdAt: _items[index].createdAt);
    _items[index] = saved;
    return saved;
  }

  @override
  Future<void> delete(String categoryId) async {
    final index = _items.indexWhere((category) => category.id == categoryId);
    if (index == -1) throw StateError('Category not found: $categoryId');
    _items.removeAt(index);
  }
}

/// Supabase-backed category reads, scoped to the active household.
///
/// RLS already restricts `categories` to households the user belongs to; the
/// explicit `household_id` filter keeps this correct if a user ever belongs to
/// more than one, and mirrors the `transactions` pattern.
class SupabaseCategoriesRepository implements CategoriesRepository {
  SupabaseCategoriesRepository(this._client);

  final SupabaseClient _client;

  SupabaseQueryBuilder get _table => _client.from('categories');

  @override
  Future<List<TransactionCategory>> fetchCategories(String householdId) async {
    try {
      final rows = await _table
          .select()
          .eq('household_id', householdId)
          .order('created_at');
      return rows.map(CategoryMapper.fromRow).toList();
    } catch (e, s) {
      throw ServerException(
        'Failed to load categories',
        cause: e,
        stackTrace: s,
      );
    }
  }

  @override
  Future<TransactionCategory> create(TransactionCategory category) async {
    try {
      final row = await _table
          .insert(CategoryMapper.toInsert(category))
          .select()
          .single();
      return CategoryMapper.fromRow(row);
    } catch (e, s) {
      throw ServerException(
        'Failed to create category',
        cause: e,
        stackTrace: s,
      );
    }
  }

  @override
  Future<TransactionCategory> update(TransactionCategory category) async {
    try {
      final row = await _table
          .update(CategoryMapper.toUpdate(category))
          .eq('id', category.id)
          .select()
          .single();
      return CategoryMapper.fromRow(row);
    } catch (e, s) {
      throw ServerException(
        'Failed to update category',
        cause: e,
        stackTrace: s,
      );
    }
  }

  @override
  Future<void> delete(String categoryId) async {
    try {
      await _table.delete().eq('id', categoryId);
    } catch (e, s) {
      throw ServerException(
        'Failed to delete category',
        cause: e,
        stackTrace: s,
      );
    }
  }
}

import '../../../domain/models/transaction_category.dart';

/// Translates the Supabase `categories` row shape (snake_case) into the domain
/// [TransactionCategory].
///
/// This is the only place that knows the table's column names, keeping the
/// domain backend-agnostic (quality rule #7).
abstract final class CategoryMapper {
  CategoryMapper._();

  static TransactionCategory fromRow(Map<String, dynamic> row) =>
      TransactionCategory(
        id: row['id'] as String,
        name: row['name'] as String,
        iconName: (row['icon_name'] as String?) ?? 'cart',
        slug: row['slug'] as String?,
        householdId: row['household_id'] as String?,
        colorHex: row['color_hex'] as String?,
        isDefault: (row['is_default'] as bool?) ?? false,
        createdAt: _parseDate(row['created_at']),
      );

  static Map<String, dynamic> toInsert(TransactionCategory category) => {
    'household_id': category.householdId,
    'name': category.name,
    'slug': category.slug,
    'icon_name': category.iconName,
    'color_hex': category.colorHex,
    'is_default': category.isDefault,
  };

  static Map<String, dynamic> toUpdate(TransactionCategory category) => {
    'name': category.name,
    'icon_name': category.iconName,
    'color_hex': category.colorHex,
  };

  static DateTime? _parseDate(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;
}
